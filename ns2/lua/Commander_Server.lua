// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Commander:OnDestroy()
    
    Player.OnDestroy(self)
    self:SetEntitiesSelectionState(false)
    
end

function Commander:CopyPlayerDataFrom(player)

    Player.CopyPlayerDataFrom(self, player)
    self:SetIsAlive(player:GetIsAlive())
    
    self.health = player.health
    self.maxHealth = player.maxHealth

    local commanderStartOrigin = Vector(player:GetOrigin())
    commanderStartOrigin.y = commanderStartOrigin.y + 5    
    self:SetOrigin(commanderStartOrigin)
    
    self:SetVelocity(Vector(0, 0, 0))

    // For knowing how to create the player class when leaving commander mode
    self.previousMapName = player:GetMapName()
    
    // Save previous weapon name so we can switch back to it when we logout
    self.previousWeaponMapName = ""
    local activeWeapon = player:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        self.previousWeaponMapName = activeWeapon:GetMapName()
    end        
    
    self.previousHealth = player:GetHealth()
    self.previousArmor = player:GetArmor()
    
    self.previousAngles = Angles(player:GetAngles())
    
    // Save off alien values
    if player.GetEnergy then
        self.previousAlienEnergy = player:GetEnergy()
    end
    self.timeStartedCommanderMode = Shared.GetTime()
    
end

// Returns nearest unattached entity of specified classtype within radius of position (nil otherwise)
function GetUnattachedEntityWithinRadius(attachclass, position, radius)

    local nearestDistance = 0
    local nearestEntity = nil
    
    for index, current in ientitylist(Shared.GetEntitiesWithClassname(attachclass)) do
    
        local currentOrigin = Vector(current:GetOrigin())
        
        if(current:GetAttached() == nil) then
            
            local distance = (position - currentOrigin):GetLength()
            
            if ( (distance <= radius) and ( (nearestEntity == nil) or ( distance < nearestDistance) ) ) then
                
                nearestEntity = current
                nearestDistance = distance
                
            end
        
        end
    
    end
    
    return nearestEntity
    
end

/**
 * Commanders cannot take damage.
 */
function Commander:GetCanTakeDamageOverride()
    return false
end

function Commander:AttemptToResearchOrUpgrade(techNode)

    // Make sure we have a valid and available structure selected
    if (table.maxn(self.selectedSubGroupEntityIds) == 1) then
    
        local entity = Shared.GetEntity( self.selectedSubGroupEntityIds[1] )
        
        // Don't allow it to be researched while researching
        if( entity ~= nil and entity:isa("Structure") ) then
        
            // $AS FIXME: We need a better way to do recycling 
            if (techNode:GetCanResearch() and (techNode:GetTechId() == kTechId.Recycle or entity:GetCanResearch())) or 
            
                // Allow manufacture nodes happen at multiple facilities at the same time
                (techNode:GetIsManufacture() and not entity:GetIsResearching())  then
        
                entity:SetResearching(techNode, self)
                entity:OnResearch(techNode:GetTechId())
                
                if not techNode:GetIsUpgrade() and not techNode:GetIsEnergyManufacture() and not techNode:GetIsPlasmaManufacture() then
                    techNode:SetResearching()
                end
                
                self:GetTechTree():SetTechNodeChanged(techNode)
                
                return true
                
            end 
       
        end
        
    end    

    return false
    
end



// TODO: Add parameters for energy or resources
function Commander:TriggerNotEnoughResourcesAlert()

    local team = self:GetTeam()
    local alertType = ConditionalValue(team:GetTeamType() == kMarineTeamType, kTechId.MarineAlertNotEnoughResources, kTechId.AlienAlertNotEnoughResources)
    local commandStructure = Shared.GetEntity(self.commandStationId)
    team:TriggerAlert(alertType, commandStructure)

end

// Can't kill commander, kill selection instead
function Commander:KillSelection()

    // Give order to selection
    for tableIndex, entityPair in ipairs(self.selectedEntities) do

        local entityIndex = entityPair[1]
        local selectedEntity = Shared.GetEntity(entityIndex)
        selectedEntity:TakeDamage(20000, self, self, nil, nil)
        
    end

end

// Return whether action should continue to be processed for the next selected unit. Position will be nil
// for non-targeted actions and will be the world position target for the action for targeted actions.
function Commander:ProcessTechTreeActionForEntity(techNode, position, normal, pickVec, orientation, entity, trace)

    local success = false
    local keepProcessing = true

    // First make sure tech is allowed for entity
    local techId = techNode:GetTechId()
    local techButtons = self:GetCurrentTechButtons(self.currentMenu, entity)
    
    if(techButtons == nil or table.find(techButtons, techId) == nil) then
        return success, keepProcessing
    end
    
    // Cost is in team resources, energy or individual resources, depending on tech node type        
    local cost = GetCostForTech(techId)
    local team = self:GetTeam()
    
    // Let entities override actions themselves (eg, so buildbots can execute a move-build order instead of building structure immediately)
    success, keepProcessing = entity:OverrideTechTreeAction(techNode, position, orientation, self, trace)
    if(success) then
        return success, keepProcessing
    end        
    
    // Handle tech tree actions that cost team resources    
    if(techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsBuild() or techNode:GetIsEnergyBuild() or techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture()) then

        local costsEnergy = techNode:GetIsEnergyBuild() or techNode:GetIsEnergyManufacture()

        local teamResources = team:GetTeamResources()
        local energy = 0
        if HasMixin(entity, "Energy") then
            energy = entity:GetEnergy()
        end
        
        if (not costsEnergy and cost <= teamResources) or (costsEnergy and cost <= energy) then
        
            if(techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture()) then
            
                success = self:AttemptToResearchOrUpgrade(techNode)
                if success then 
                    keepProcessing = false
                end
                                
            elseif techNode:GetIsBuild() or techNode:GetIsEnergyBuild() then
            
                success = self:AttemptToBuild(techId, position, normal, orientation, pickVec, false)
                if success then 
                    keepProcessing = false
                end
                
            end

            if success then 
            
                if costsEnergy then            
                    entity:SetEnergy(entity:GetEnergy() - cost)                
                else                
                    team:AddTeamResources(-cost)                    
                end
                
                Shared.PlayPrivateSound(self, Commander.kSpendTeamResourcesSoundName, nil, 1.0, self:GetOrigin())
                
            end
            
        else
        
            self:TriggerNotEnoughResourcesAlert()
            
        end
                        
    // Handle resources-based abilities
    elseif(techNode:GetIsAction() or techNode:GetIsBuy() or techNode:GetIsPlasmaManufacture()) then

        local playerResources = self:GetResources()
        if(cost == nil or cost <= playerResources) then
        
            if(techNode:GetIsAction()) then            
                success = entity:PerformAction(techNode, position)
            elseif(techNode:GetIsBuy()) then
                success = self:AttemptToBuild(techId, position, normal, orientation, pickVec, false)
            elseif(techNode:GetIsPlasmaManufacture()) then
                success = self:AttemptToResearchOrUpgrade(techNode)
            end
            
            if(success and cost ~= nil) then
            
                self:AddResources(-cost)
                Shared.PlayPrivateSound(self, Commander.kSpendResourcesSoundName, nil, 1.0, self:GetOrigin())
                
            end
            
        else
            self:TriggerNotEnoughResourcesAlert()
        end
    
    // Energy-based and misc. abilities        
    elseif(techNode:GetIsActivation()) then

        // Deduct energy cost if any 
        if(cost == 0 or cost <= entity:GetEnergy()) then
                    
            success = entity:PerformActivation(techId, position, normal, self)
            
            if success and HasMixin(entity, "Energy") and cost ~= 0 then
            
                entity:AddEnergy(-cost)
                
            end
            
        else
        
            self:TriggerNotEnoughResourcesAlert()
            
        end
        
    end
    
    return success, keepProcessing
    
end

function Commander:PerformCommanderTrace(normPickVec)

    local startPoint = self:GetOrigin()
    local trace = Shared.TraceRay(startPoint, startPoint + normPickVec * 1000, PhysicsMask.AllButPCs, EntityFilterOne(self))
    return trace
    
end

// Send techId of action and normalized pick vector. Issues order to selected units to the world position represented by
// the pick vector, or to the entity that it hits.
function Commander:OrderEntities(orderTechId, trace, orientation)

    local invalid = false
    
    local targetId = Entity.invalidId
    if(trace.entity ~= nil) then
        targetId = trace.entity:GetId()
    end
    
    if (trace.fraction < 1) then

        // Give order to selection
        local orderEntities = {}
        for tableIndex, entityPair in ipairs(self.selectedEntities) do
    
            local entityIndex = entityPair[1]
            local entity = Shared.GetEntity(entityIndex)
            table.insert(orderEntities, entity)
            
        end
        
        // Give order to ourselves for testing
        if GetGamerules():GetOrderSelf() then
            table.insert(orderEntities, self)
        end
        
        local orderTechIdGiven = orderTechId
        
        for tableIndex, entity in ipairs(orderEntities) do

            local type = entity:GiveOrder(orderTechId, targetId, trace.endPoint, orientation, not self.queuingOrders, false)                            
            
            if(type == kTechId.None) then            
                invalid = true    
            end
                
        end
        
        self:OnOrderEntities(orderTechIdGiven, orderEntities)
        
    end

    if(invalid) then    
    
        // Play invalid sound once
        Shared.PlayPrivateSound(self, Player.kInvalidSound, nil, 1.0, self:GetOrigin())     
        
    end
    
end

function Commander:OnOrderEntities(orderTechId, orderEntities)

    // Get sound and play it locally for commander and every target player
    local soundName = LookupTechData(orderTechId, kTechDataOrderSound, nil)
    
    if soundName then

        // Play order sounds if we're ordering players only
        local playSound = false
        
        for index, entity in ipairs(orderEntities) do
        
            if entity:isa("Player") then
            
                playSound = true
                break
                
            end
            
        end
    
        if playSound then
        
            Server.PlayPrivateSound(self, soundName, self, 1.0, Vector(0, 0, 0))
            
            for index, player in ipairs(orderEntities) do
                Server.PlayPrivateSound(player, soundName, player, 1.0, Vector(0, 0, 0))
            end
            
        end
        
    end
    
end

// Takes a techId as the action type and normalized screen coords for the position. normPickVec will be nil
// for non-targeted actions. 
function Commander:ProcessTechTreeAction(techId, pickVec, orientation, worldCoordsSpecified)

    local success = false
    
    // Make sure tech is available
    local techNode = self:GetTechTree():GetTechNode(techId)
    if(techNode ~= nil and techNode.available) then

        // Trace along pick vector to find world position of action
        local targetPosition = Vector(0, 0, 0)
        local targetNormal = Vector(0, 1, 0)
        local trace = nil
        if pickVec ~= nil then
        
            trace = GetCommanderPickTarget(self, pickVec, worldCoordsSpecified, techNode:GetIsBuild())
            
            if(trace ~= nil) then
                VectorCopy(trace.endPoint, targetPosition)
                VectorCopy(trace.normal, targetNormal)
            end
                
        end
    
        // If techNode is a menu, remember it so we can validate actions
        if(techNode:GetIsMenu()) then
        
            self.currentMenu = techId
            
        elseif(techNode:GetIsOrder()) then
    
            self:OrderEntities(techId, trace, orientation)
            
        else        
           
            // For every selected entity, process this desired action. For some actions (research), only
            // process once, not on every entity.
            for index, selectedEntityId in ipairs(self.selectedSubGroupEntityIds) do
            
                local selectedEntity = Shared.GetEntity(selectedEntityId)
                local actionSuccess = false
                local keepProcessing = false
                actionSuccess, keepProcessing = self:ProcessTechTreeActionForEntity(techNode, targetPosition, targetNormal, pickVec, orientation, selectedEntity, trace)
                
                // Successful if just one of our entities handled action
                if(actionSuccess) then
                    success = true
                end
                
                if(not keepProcessing) then
                
                    break
                    
                end
                    
            end
            
        end
        
    end

    return success
    
end

function Commander:GetIsEntityHotgrouped(entity)

    local entityId = entity:GetId()
    
    // Loop through hotgroups, looking for entity
    for i = 1, Player.kMaxHotkeyGroups do
    
        for j = 1, table.count(self.hotkeyGroups[i]) do
        
            if(self.hotkeyGroups[i][j] == entityId) then
            
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function Commander:GetSelectionHasOrder(orderEntity)

    for tableIndex, entityPair in ipairs(self.selectedEntities) do
    
        local entityIndex = entityPair[1]
        local entity = Shared.GetEntity(entityIndex)
        
        if entity and entity.GetHasSpecifiedOrder and entity:GetHasSpecifiedOrder(orderEntity) then
            return true
        end
        
    end
    
    return false
    
end

function Commander:GiveOrderToSelection(orderType, targetId)

end


function Commander:SetEntitiesHotkeyState(group, state)
        
    if Server then
        
        for index, entityIndex in ipairs(group) do
            
            local entity = Shared.GetEntity(entityIndex)        
            
            if entity ~= nil then
                entity:SetIsHotgrouped(state)
            end
            
        end
    
    end 
    
end

// Creates hotkey for number out of current selection. Returns true on success.
// Replaces existing hotkey on this number if it exists.
function Commander:CreateHotkeyGroup(number)

    if(number >= 1 and number <= Player.kMaxHotkeyGroups) then
    
        local selection = self:GetSelection()
        if(selection ~= nil and table.count(selection) > 0) then
        
            // Don't update hotkeys if they are the same (also happens when key is held down)
            if (not table.getIsEquivalent(selection, self.hotkeyGroups[number])) then
        
                self:SetEntitiesHotkeyState(self.hotkeyGroups[number], false)
                table.copy(selection, self.hotkeyGroups[number])
                self:SetEntitiesHotkeyState(self.hotkeyGroups[number], true)
                
                self:SendHotkeyGroup(number)
                
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

// Deletes hotkey for number. Returns true if it exists and was deleted.
function Commander:DeleteHotkeyGroup(number)

    if (number >= 1 and number <= Player.kMaxHotkeyGroups) then
    
        if (table.count(self.hotkeyGroups[number]) > 0) then
        
            self:SetEntitiesHotkeyState(self.hotkeyGroups[number], false)
            self.hotkeyGroups[number] = {}
            
            self:SendHotkeyGroup(number)
            
            return true
            
        end
        
    end
    
    return false
    
end

// Send data to client because it changed
function Commander:SendHotkeyGroup(number)

    local hotgroupCommand = string.format("hotgroup %d ", number)
    
    for j = 1, table.count(self.hotkeyGroups[number]) do
    
        // Need underscore between numbers so all ids are sent in one string
        hotgroupCommand = hotgroupCommand .. self.hotkeyGroups[number][j] .. "_"
        
    end
    
    Server.SendCommand(self, hotgroupCommand)
    
    return hotgroupCommand
    
end

// Send alert to player unless we recently sent the exact same alert. Returns true if it was sent.
function Commander:TriggerAlert(techId, entity)

    ASSERT(entity ~= nil)
    
    local entityId = entity:GetId()
    local time = Shared.GetTime()
    
    for index, alert in ipairs(self.alerts) do
    
        if (alert[1] == techId) and (alert[2] == entityId) and (alert[3] > (time - PlayingTeam.kRepeatAlertInterval)) then
        
            return false
            
        end
        
    end
    
    local location = entity:GetOrigin()
    if entity:GetTechId() == nil then
        Print( "Triggering an alert for an entity with no tech ID (entity is class %s)", entity:GetClassName() )
    end
    assert( entity:GetTechId() ~= nil )
    
    local message =
        {
            techId = techId,
            worldX = location.x,
            worldZ = location.z,
            entityId = entity:GetId(),
            entityTechId = entity:GetTechId() 
        }
        
    Server.SendNetworkMessage(self, "MinimapAlert", message, true)        

    // Insert new generic alert triple: techid/entityid/timesent
    table.insert(self.alerts, {techId, entityId, time})
    
    return true
    
end

// After logging in to the command station, send all hotkey groups. After that, only
// send them when they change. We must wait a short time after after logging in before
// sending them, to be sure the client version of the player is a Commander (and not
// a marine or alien).
function Commander:UpdateHotkeyGroups()

    if (self.timeToSendHotkeyGroups ~= nil) then
    
        if (Shared.GetTime() > self.timeToSendHotkeyGroups) then
        
            for i = 1, Player.kMaxHotkeyGroups do
    
                self:SendHotkeyGroup(i)
                
            end
            
            self.timeToSendHotkeyGroups = nil
            
        end
        
    end
    
end

function Commander:GetIsEntityIdleWorker(entity)
    local className = ConditionalValue(self:isa("AlienCommander"), "Drifter", "MAC")
    return entity:isa(className) and not entity:GetHasOrder()
end

function Commander:GetIdleWorkers()

    local className = ConditionalValue(self:isa("AlienCommander"), "Drifter", "MAC")
    
    local workers = GetEntitiesForTeam(className, self:GetTeamNumber())
    
    local idleWorkers = {}
    
    for index, worker in ipairs(workers) do

        if not worker:GetHasOrder() then
        
            table.insert(idleWorkers, worker)
            
        end
        
    end    
    
    return idleWorkers

end

function Commander:UpdateNumIdleWorkers()
    
    if self.lastTimeUpdatedIdleWorkers == nil or (Shared.GetTime() > self.lastTimeUpdatedIdleWorkers + 1) then
    
        self.numIdleWorkers = Clamp(table.count(self:GetIdleWorkers()), 0, kMaxIdleWorkers)
        
        self.lastTimeUpdatedIdleWorkers = Shared.GetTime()
        
    end
    
end

function Commander:UpdateAlerts()
    
    if self.lastTimeUpdatedPlayerAlerts == nil or (Shared.GetTime() > self.lastTimeUpdatedPlayerAlerts + .25) then
    
        // Expire old alerts so they don't stack up
        function expireOldAlert(triple)
            return Shared.GetTime() > (triple[3] + kAlertExpireTime)
        end
        
        table.removeConditional(self.alerts, expireOldAlert)
    
        // Count number of player request alerts to draw on Commander HUD
        local numPlayerAlerts = 0        
        for index, triple in ipairs(self.alerts) do
        
            local alertType = LookupTechData(triple[1], kTechDataAlertType, nil)
            
            if alertType == kAlertType.Request then
                numPlayerAlerts = numPlayerAlerts + 1
            end
            
        end
        
        self.numPlayerAlerts = Clamp(numPlayerAlerts, 0, kMaxPlayerAlerts)
        
        self.lastTimeUpdatedPlayerAlerts = Shared.GetTime()
        
    end
    
end

function Commander:GotoIdleWorker()
    
    local success = false
    
    local workers = self:GetIdleWorkers()
    local numWorkers = table.count(workers)
    
    if numWorkers > 0 then
    
        if numWorkers == 1 or self.lastGotoIdleWorker == nil then
        
            self.lastGotoIdleWorker = workers[1]
                    
            success = true
        
        else
        
            local index = table.find(workers, self.lastGotoIdleWorker)
            
            if index ~= nil then
            
                local newIndex = ConditionalValue(index == table.count(workers), 1, index + 1)

                if newIndex ~= index then
                
                    self.lastGotoIdleWorker = workers[newIndex]
                    
                    //Print("index = %d, newIndex = %d, entityId = %d", index, newIndex, SafeId(self.lastGotoIdleWorker, -1))
                    
                    success = true
                    
                end
            
            end
        
        end
    
    end
    
    if success then
    
        // Select and goto self.lastGotoIdleWorker
        local entityId = self.lastGotoIdleWorker:GetId()
        
        self:SetSelection( {entityId} )
        
        Server.SendNetworkMessage(self, "SelectAndGoto", BuildSelectAndGotoMessage(entityId), true)
        
    end
            
end

function Commander:GotoPlayerAlert()

    for index, triple in ipairs(self.alerts) do
        
        local alertType = LookupTechData(triple[1], kTechDataAlertType, nil)
            
        if alertType == kAlertType.Request then
        
            self.lastTimeUpdatedPlayerAlerts = nil
            
            local playerAlertId = triple[2]
            local player = Shared.GetEntity(playerAlertId)
            
            if player then
            
                table.remove(self.alerts, index)
                
                self:SetSelection( { playerAlertId } )
                
                Server.SendNetworkMessage(self, "SelectAndGoto", BuildSelectAndGotoMessage(playerAlertId), true)
                
                return true
                
            end
            
        end
            
    end
    
    return false
    
end

function Commander:Logout()

    local commandStructure = Shared.GetEntity(self.commandStationId)
    commandStructure:Logout()
        
end

// Force player out of command station or hive
function Commander:Eject()

    // Get data before we create new player
    local teamNumber = self:GetTeamNumber()
    local userId = Server.GetOwner(self):GetUserId()
    
    self:AddTooltip("You have been voted out of a Commander role.")
    self:Logout()

    // Tell all players on team about this
    local team = GetGamerules():GetTeam(teamNumber)
    if team:GetTeamType() == kMarineTeamType then
        team:TriggerAlert(kTechId.MarineCommanderEjected, self)
    else
        team:TriggerAlert(kTechId.AlienCommanderEjected, self)
    end
        
    // Add player to list of players that can no longer command on this server (until brought down)    
    GetGamerules():BanPlayerFromCommand(userId)

    
end


function Commander:SetCommandStructure(commandStructure)
    self.commandStationId = commandStructure:GetId()
end

