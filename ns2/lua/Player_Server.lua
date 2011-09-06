// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Gamerules.lua")

// Called when player first connects to server
// TODO: Move this into NS specific player class
function Player:OnClientConnect(client)
    self:SetRequestsScores(true)   
    self.clientIndex = client:GetId()
end

function Player:GetClient()
    return self.client
end

function Player:SetEthereal(ethereal)
end

// Returns true if this player is a bot
function Player:GetIsVirtual()

    local isVirtual = false
    
    if self.client then
        isVirtual = self.client:GetIsVirtual()
    end
    
    return isVirtual
    
end

function Player:Reset()

    LiveScriptActor.Reset(self)
    
    self.score = 0
    self.kills = 0
    self.deaths = 0

end

/**
 * Called when the player entity is destroyed.
 */
function Player:OnDestroy()

    LiveScriptActor.OnDestroy(self)
   
    self:RemoveChildren()
        
end

function Player:ClearEffects()
end

// ESC was hit on client or menu closed
function Player:CloseMenu()
end

function Player:GetName()
    return self.name
end

function Player:SetName(name)

    // If player is just changing the case on their own name, allow it.
    // Otherwise, make sure it's a unique name on the server.
    
    // Strip out surrounding "s
    local newName = string.gsub(name, "\"(.*)\"", "%1")
    
    // Make sure it's not too long
    newName = string.sub(newName, 0, kMaxNameLength)
    
    local currentName = self:GetName()
    if(currentName ~= newName or string.lower(newName) ~= string.lower(currentName)) then
        newName = GetUniqueNameForPlayer(newName)        
    end
    
    if(newName ~= self.name) then
    
        self.name = newName
        
        self:SetScoreboardChanged(true)
            
    end
    
end

/**
 * Used to add the passed in client index to this player's mute list.
 * This player will either hear or not hear the passed in client's
 * voice chat based on the second parameter.
 */
function Player:SetClientMuted(muteClientIndex, setMuted)

    if not self.mutedClients then self.mutedClients = { } end
    self.mutedClients[muteClientIndex] = setMuted

end
AddFunctionContract(Player.SetClientMuted, { Arguments = { "Player", "number", "boolean" }, Returns = { } })

/**
 * Returns true if the passed in client is muted by this Player.
 */
function Player:GetClientMuted(checkClientIndex)

    if not self.mutedClients then self.mutedClients = { } end
    return self.mutedClients[checkClientIndex] == true

end
AddFunctionContract(Player.GetClientMuted, { Arguments = { "Player", "number" }, Returns = { "boolean" } })

// Changes the visual appearance of the player to the special edition version.
function Player:MakeSpecialEdition()
    self:SetModel(Player.kSpecialModelName)
end

// Not authoritative, only visual and information. TeamResources is stored in the team.
function Player:SetTeamResources(teamResources)
    self.teamResources = math.max(math.min(teamResources, kMaxResources), 0)
end

function Player:GetSendTechTreeBase()
    return self.sendTechTreeBase
end

function Player:ClearSendTechTreeBase()
    self.sendTechTreeBase = false
end

function Player:GetRequestsScores()
    return self.requestsScores
end

function Player:SetRequestsScores(state)
    self.requestsScores = state
end

// Call to give player default weapons, abilities, equipment, etc. Usually called after CreateEntity() and OnInit()
function Player:InitWeapons()
    self:ClearActivity()
    self.activeWeaponIndex = 0
    self.hudOrderedWeaponList = nil
end

function Player:OnTakeDamage(damage, attacker, doer, point)

    LiveScriptActor.OnTakeDamage(self, damage, attacker, doer, point)
    
    if self:GetTeamType() == kAlienTeamType then
        self:GetTeam():TriggerAlert(kTechId.AlienAlertLifeformUnderAttack, self)
    end
    
    // Play damage indicator for player
    if point ~= nil then
        local damageOrigin = doer:GetOrigin()
        local doerParent = doer:GetParent()
        if doerParent then
            damageOrigin = doerParent:GetOrigin()
        end
        Server.SendNetworkMessage(self, "TakeDamageIndicator", BuildTakeDamageIndicatorMessage(damageOrigin, damage), true)
    end
    
end

// Add resources for kills and play sound
function Player:AwardResForKill(target)

    local resAwarded = 0
    
    if target and target:isa("Player") then
    
        // Give random amount of res
        resAwarded = math.random(kKillRewardMin, kKillRewardMax) 
        self:SetResources( self:GetResources() + resAwarded ) 
        
        //self:GetTeam():SetTeamResources(self:GetTeam():GetTeamResources() + kKillTeamReward)
        
        // Play sound for player and also our commanders
        self:GetTeam():TriggerEffects("res_received")
        
    end
    
    return resAwarded
    
end

/**
 * Called when the player is killed. Point and direction specify the world
 * space location and direction of the damage that killed the player. These
 * may be nil if the damage wasn't directional.
 */
function Player:OnKill(damage, killer, doer, point, direction)

    local killerName = nil
    
    local pointOwner = killer
    // If the pointOwner is not a player, award it's points to it's owner.
    if pointOwner ~= nil and not pointOwner:isa("Player") then
        pointOwner = pointOwner:GetOwner()
    end
    if(pointOwner and pointOwner:isa("Player") and pointOwner ~= self and pointOwner:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber())) then
   
        killerName = pointOwner:GetName()
        pointOwner:AddKill()        
        
        local resAwarded = pointOwner:AwardResForKill(self)        
        pointOwner:AddScore(self:GetPointValue(), resAwarded)
        
    end        

    // Save death to server log
    if(killer == self) then        
        PrintToLog("%s committed suicide", self:GetName())
    elseif(killerName ~= nil) then
        PrintToLog("%s was killed by %s", self:GetName(), killerName)
    else
        PrintToLog("%s died", self:GetName())
    end

    // Go to third person so we can see ragdoll and avoid HUD effects (but keep short so it's personal)
    self:SetIsThirdPerson(4)
    
    local angles = self:GetAngles()
    angles.roll = 0
    self:SetAngles(angles)
    
    self.baseRoll  = 0
    self.baseYaw   = 0
    self.basePitch = 0
    
    self:AddDeaths()
    
    // Don't allow us to do anything
    self:SetIsAlive(false)
    
    self:ResetUpgrades()

    // On fire, in umbra, etc.
    self:ClearGameEffects()
    
    // Fade out screen
    self.timeOfDeath = Shared.GetTime()
    
    // So we aren't moving in spectator mode
    self:SetVelocity(Vector(0, 0, 0))
    
    // Remove our weapons and viewmodel
    self:RemoveChildren()

    // Create a rag doll
    self:SetPhysicsType(Actor.PhysicsType.Dynamic)
    self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
    
    // Set next think to 0 to disable
    self:SetNextThink(0)
        
end

function Player:SetControllingPlayer(client)

    // Entity passed to SetControllingPlayer must be an Actor
    if (client ~= nil) then
        client:SetControllingPlayer(self)
    end
    
    // Save client for later
    self.client = client
    self:UpdateClientRelevancyMask()
    
end

function Player:UpdateClientRelevancyMask()

    local mask = 0xFFFFFFFF
    
    if self:GetTeamNumber() == 1 then
        if self:GetIsCommander() then
            mask = kRelevantToTeam1Commander
         else
            mask = kRelevantToTeam1Unit
         end
    elseif self:GetTeamNumber() == 2 then
        if self:GetIsCommander() then
            mask = kRelevantToTeam2Commander
         else
            mask = kRelevantToTeam2Unit
         end
    // Spectators should see all map blips.
    elseif self:GetTeamNumber() == kSpectatorIndex then
        mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
    // ReadyRoomPlayers should not see any blips.
    elseif self:GetTeamNumber() == kTeamReadyRoom then
        mask = kRelevantToReadyRoom
    end
    
    self.client:SetRelevancyMask(mask)

end

function Player:SetTeamNumber(teamNumber)
    LiveScriptActor.SetTeamNumber(self, teamNumber)
    self:UpdateIncludeRelevancyMask()
end

function Player:UpdateIncludeRelevancyMask()

    // Players are always relevant to their commanders.
    
    local includeMask = 0
    
    if self:GetTeamNumber() == 1 then
        includeMask = kRelevantToTeam1Commander
    elseif self:GetTeamNumber() == 2 then
        includeMask = kRelevantToTeam2Commander
    end
    
    self:SetIncludeRelevancyMask( includeMask )
     
end

function Player:SetResources(amount)
    self.resources = math.max(math.min(amount, kMaxResources), 0)    
end

function Player:GetDeathMapName()
    return Spectator.kMapName
end

function Player:OnUpdate(deltaTime)

    PROFILE("Player_Server:OnUpdate")
    
    LiveScriptActor.OnUpdate(self, deltaTime)

    self:UpdateOrder()
    
    self:UpdateOrderWaypoint()
    
    if (not self:GetIsAlive() and not self:isa("Spectator")) then
    
        local time = Shared.GetTime()
        
        if ((self.timeOfDeath ~= nil) and (time - self.timeOfDeath > kFadeToBlackTime)) then
        
            // Destroy the existing player and create a spectator in their place.
            local spectator = self:Replace(self:GetDeathMapName())
            
            // Queue up the spectator for respawn.
            spectator:GetTeam():PutPlayerInRespawnQueue(spectator, Shared.GetTime())             
            
        end

    end 

    /*local viewModel = self:GetViewModelEntity()
    if viewModel ~= nil then
        viewModel:SetIsVisible(not self:GetWeaponHolstered())
    end*/

    local gamerules = GetGamerules()
    self.gameStarted = gamerules:GetGameStarted()
    // TODO: Change this after making NS2Player
    self.countingDown = false //gamerules:GetCountingDown()
    self.teamLastThink = self:GetTeam()  

end

// Remember game time player enters queue so they can be spawned in FIFO order
function Player:SetRespawnQueueEntryTime(time)

    self.respawnQueueEntryTime = time
    
end

function Player:ReplaceRespawn()
    return self:GetTeam():ReplaceRespawnPlayer(self, nil, nil)
end

function Player:GetRespawnQueueEntryTime()

    return self.respawnQueueEntryTime
    
end

function Player:CanDoDamageTo(entity)

    return CanEntityDoDamageTo(self, entity)
    
end

// For children classes to override if they need to adjust data
// before the copy happens.
function Player:PreCopyPlayerData()

end

function Player:CopyPlayerDataFrom(player)

    LiveScriptActor.CopyDataFrom(self, player)

    // ScriptActor and Actor fields
    self:SetAngles(player:GetAngles())
    self:SetOrigin(Vector(player:GetOrigin()))
    self:SetViewAngles(player:GetViewAngles())
    
    self.baseYaw = player.baseYaw
    self.basePitch = player.basePitch
    self.baseRoll = player.baseRoll

    // MoveMixin fields.
    self:SetVelocity(player:GetVelocity())
    self:SetGravityEnabled(player:GetGravityEnabled())
    
    // Player fields   
    //self:SetFov(player:GetFov())
    
    // Don't copy over fields that are class-specific. We give new weapons to players
    // when they change class.
    //self.activeWeaponIndex = player.activeWeaponIndex
    //self.activeWeaponHolstered = player.activeWeaponHolstered
    //self.viewModelId = player.viewModelId
    
    self.name = player.name
    self.clientIndex = player.clientIndex
    
    // Preserve hotkeys when logging in/out of command structures
    table.copy(player.hotkeyGroups, self.hotkeyGroups)
    
    // Copy network data over because it won't be necessarily be resent
    self.resources = player.resources
    self.teamResources = player.teamResources
    self.gameStarted = player.gameStarted
    self.countingDown = player.countingDown
    self.frozen = player.frozen
    // .displayedTooltips is stored in TooltipMixin.
    table.copy(player.displayedTooltips, self.displayedTooltips)
    
    // Don't copy alive, health, maxhealth, armor, maxArmor - they are set in Spawn()
    
    self.showScoreboard = player.showScoreboard
    self.score = player.score
    self.kills = player.kills
    self.deaths = player.deaths
    
    self.timeOfDeath = player.timeOfDeath
    self.timeOfLastUse = player.timeOfLastUse
    self.timeOfLastWeaponSwitch = player.timeOfLastWeaponSwitch
    self.crouching = player.crouching
    self.timeOfCrouchChange = player.timeOfCrouchChange   
    self.timeOfLastPoseUpdate = player.timeOfLastPoseUpdate

    self.timeLastBuyMenu = player.timeLastBuyMenu
    
    // Include here so it propagates through Spectator
    self.lastSquad = player.lastSquad
    
    self.sighted = player.sighted
    self.jumpHandled = player.jumpHandled
    self.timeOfLastJump = player.timeOfLastJump

    self.mode = player.mode
    self.modeTime = player.modeTime
    self.outOfBreath = player.outOfBreath
    
    self.requestsScores = player.requestsScores
    
    // Don't lose purchased upgrades when becoming commander
    self.upgrade1 = player.upgrade1
    self.upgrade2 = player.upgrade2
    self.upgrade3 = player.upgrade3
    self.upgrade4 = player.upgrade4
    
    // Copy waypoint
    if player.nextOrderWaypoint and self.nextOrderWaypoint then
        self.nextOrderWaypoint = player.nextOrderWaypoint
    end
    
    if player.finalWaypoint and self.finalWaypoint then
        self.finalWaypoint = player.finalWaypoint
    end
    
    self.nextOrderWaypointActive = player.nextOrderWaypointActive
    
    self.waypointType = player.waypointType
    
    player:TransferOrders(self)
    
    // Remember this player's muted clients.
    self.mutedClients = player.mutedClients
        
end

/**
 * Replaces the existing player with a new player of the specified map name.
 * Removes old player off its team and adds new player to newTeamNumber parameter
 * if specified. Note this destroys self, so it should be called carefully. Returns 
 * the new player. If preserve children is true, then InitWeapons() isn't called
 * and old ones are kept (including view model).
 */
function Player:Replace(mapName, newTeamNumber, preserveChildren)

    local team = self:GetTeam()
    if(team == nil) then
        return self
    end
    
    local teamNumber = team:GetTeamNumber()    
    local owner  = Server.GetOwner(self)
    local teamChanged = (newTeamNumber ~= nil and newTeamNumber ~= self:GetTeamNumber())
    
    // Add new player to new team if specified
    // Both nil and -1 are possible invalid team numbers.
    if(newTeamNumber ~= nil and newTeamNumber ~= -1) then
        teamNumber = newTeamNumber
    end
    
    local player = CreateEntity(mapName, Vector(self:GetOrigin()), teamNumber)

    // Save last player map name so we can show player of appropriate form in the ready room if the game ends while spectating
    player.previousMapName = self:GetMapName()
    
    // The class may need to adjust values before copying to the new player (such as gravity).
    self:PreCopyPlayerData()
    
    // Copy over the relevant fields to the new player, before we delete it
    player:CopyPlayerDataFrom(self)
    
    if not player:GetTeam():GetSupportsOrders() then
        player:ClearOrders()
    end
    
    // Keep existing resources if on the same team, clear them out if we leave
    // so resources can't be transferred
    if teamChanged then
        player:SetResources( 0 )
    end
    
    // Remove newly spawned weapons and reparent originals
    if preserveChildren then

        player:RemoveChildren()
        
        local childEntities = GetChildEntities(self)
        for index, entity in ipairs(childEntities) do

            entity:SetParent(player)

        end
        
    end
    
    // Notify others of the change     
    self:SendEntityChanged(player:GetId())
    
    // Update scoreboard because of new entity and potentially new team
    player:SetScoreboardChanged(true)
    
    // Now destroy old player (and child entities too)
    // This will remove player from old team
    // This called EntityChange as well.
    DestroyEntity(self)
     
    player:SetControllingPlayer(owner)
    
    // Set up special armor marines if player owns special edition 
    if Server.GetIsDlcAuthorized(owner, kSpecialEditionProductId) then
        player:MakeSpecialEdition()
    end

    return player

end

/**
 * A table of tech Ids is passed in.
 */
function Player:ProcessBuyAction(techIds)

    ASSERT(type(techIds) == "table")
    ASSERT(table.count(techIds) > 0)
    
    local techTree = self:GetTechTree()
    local buyAllowed = true
    local totalCost = 0
    local validBuyIds = { }
    
    for i, techId in ipairs(techIds) do
    
        local techNode = techTree:GetTechNode(techId)
        if(techNode ~= nil and techNode.available) then
        
            local cost = GetCostForTech(techId)
            if cost ~= nil then
                totalCost = totalCost + cost
                table.insert(validBuyIds, techId)
            end
        
        else
        
            buyAllowed = false
            break
        
        end
        
    end
    
    if totalCost <= self:GetResources() then
    
        if self:AttemptToBuy(validBuyIds) then
            self:AddResources(-totalCost)
            return true
        end
        
    else
        Server.PlayPrivateSound(self, self:GetNotEnoughResourcesSound(), self, 1.0, Vector(0, 0, 0))        
    end

    return false
    
end

// Creates an item by mapname and spawns it at our feet.
function Player:GiveItem(itemMapName)

    local newItem = nil

    if itemMapName then
    
        newItem = CreateEntity(itemMapName, self:GetEyePos(), self:GetTeamNumber())
        if newItem then

            // If we already have an item which would occupy the same HUD slot, drop it
            if (self.Drop and self.GetWeaponInHUDSlot and newItem.GetHUDSlot) then

                local hudSlot = newItem:GetHUDSlot()
                local weapon  = self:GetWeaponInHUDSlot(hudSlot)

                if (weapon ~= nil) then
                    self:Drop( weapon )
                end
                
            end

            if newItem.OnCollision then
                self:ClearActivity()
                newItem:OnCollision(self)
            end
            
        else
            Print("Couldn't create entity named %s.", itemMapName)            
        end
        
    end
    
    return newItem
    
end

function Player:AddWeapon(weapon, setActive)
    
    local activeWeapon = self:GetActiveWeapon()
    
    weapon:SetParent(self)
    
    // The active weapon could have been reindexed, so make sure
    // we're storing the correct index
    
    if self.activeWeaponIndex ~= 0 then
        
        local weaponList = self:GetHUDOrderedWeaponList()
    
        for index, weapon in ipairs(weaponList) do
            if (weapon == activeWeapon) then
                self.activeWeaponIndex = index
                break
            end
        end
    
    end   
 
    if setActive then
        self:SetActiveWeapon(weapon:GetMapName())
    end
    
    return true
    
end

function Player:RemoveWeapon(weapon)

    // Switch weapons if we're dropping our current weapon
    local activeWeapon = self:GetActiveWeapon()    
    
    if activeWeapon ~= nil and weapon == activeWeapon then
        self.activeWeaponIndex = 0
        self:SetViewModel(nil, nil)
    end
    
    // Delete weapon 
    weapon:SetParent(nil)
    
    // The active weapon could have been reindexed, so make sure
    // we're storing the correct index
    
    if self.activeWeaponIndex ~= 0 then
        
        local weaponList = self:GetHUDOrderedWeaponList()
    
        for index, weapon in ipairs(weaponList) do
            if (weapon == activeWeapon) then
                self.activeWeaponIndex = index
                break
            end
        end
    
    end
    
end

function Player:RemoveWeapons()

    self.activeWeaponIndex = 0
    
    // Loop through all child weapons and delete them 
    local childEntities = GetChildEntities(self, "Weapon")
    for index, entity in ipairs(childEntities) do
        DestroyEntity(entity)
    end

end

// Removes all child weapons and view model
function Player:RemoveChildren()

    self.activeWeaponIndex = 0
    
    // Loop through all children and delete them.
    local childEntities = GetChildEntities(self, "Actor")
    for index, entity in ipairs(childEntities) do
        entity:SetParent(nil)
        DestroyEntity(entity)
    end
    
    self.viewModelId = Entity.invalidId

end

function Player:InitViewModel()

    if(self.viewModelId == Entity.invalidId) then
    
        local viewModel = CreateEntity(ViewModel.mapName)
        viewModel:SetOrigin(self:GetOrigin())
        viewModel:OnInit()
        viewModel:SetParent(self)
        self.viewModelId = viewModel:GetId()
        
        // Set default blend length for all the player's view model animations
        viewModel:SetBlendTime( self:GetViewModelBlendTime() )
        
    end
    
end

function Player:GetViewModelBlendTime()
    return .1
end

function Player:GetScore()
    return self.score
end

function Player:AddScore(points, res)
    
    // Tell client to display cool effect
    if(points ~= nil and points ~= 0) then
        local displayRes = ConditionalValue(type(res) == "number", res, 0)
        Server.SendCommand(self, string.format("points %s %s", tostring(points), tostring(displayRes)))
        self.score = Clamp(self.score + points, 0, kMaxScore)
        self:SetScoreboardChanged(true)        
    end
    
end

function Player:GetKills()
    return self.kills
end

function Player:AddKill()
    self.kills = Clamp(self.kills + 1, 0, kMaxKills)
    self:SetScoreboardChanged(true)
end

function Player:GetDeaths()
    return self.deaths
end

function Player:AddDeaths()
    self.deaths = Clamp(self.deaths + 1, 0, kMaxDeaths)
    self:SetScoreboardChanged(true)
end

function Player:GetPing()
    
    local client = Server.GetOwner(self)
    
    if (client ~= nil) then
        return client:GetPing()
    else
        return 0
    end
    
end

// To be overridden by children
function Player:AttemptToBuy(techIds)
    return false
end

function Player:OnResearchComplete(structure, researchId)
    self:AddLocalizedTooltip(string.format("%s %d", "RESEARCH_COMPLETE_TOOLTIP", researchId), false, true)    
    return true
end

function Player:UpdateMisc(input)

    // Update target under reticle (put back in when we're using it)
    /*
    local enemyUnderReticle = false
    local activeWeapon = self:GetActiveWeapon()    

    if(activeWeapon ~= nil) then
    
        local viewCoords = self:GetViewAngles():GetCoords()
        local trace = Shared.TraceRay(self:GetEyePos(), self:GetEyePos() + viewCoords.zAxis*100, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))            
        if(trace.entity ~= nil and trace.fraction ~= 1) then
        
            enemyUnderReticle = GetGamerules():CanEntityDoDamageTo(self, trace.entity)
            
        end
        
    end*/
    
    // Set near death mask so we can add sound/visual effects
    self:SetGameEffectMask(kGameEffect.NearDeath, self:GetHealth() < .2*self:GetMaxHealth())
    
    // TODO: Put this back in once colors look right
    //self:SetReticleTarget(enemyUnderReticle)
    self:SetReticleTarget(true)
    
    // Flare updating
    if(self.flareStartTime > 0) then
        if(Shared.GetTime() > self.flareStopTime) then
            self.flareStartTime = 0
            self.flareStopTime = 0
        end
    end
    
end

function Player:SetFlare(startTime, endTime, scalar)
    self.flareStartTime = startTime
    self.flareStopTime = endTime
    self.flareScalar = Clamp(scalar, 0, 1)
end

// For signaling reticle hit feedback on client
function Player:SetTimeTargetHit()
    self.timeTargetHit = Shared.GetTime()
end

function Player:SetReticleTarget(state)
    self.reticleTarget = state
end

function Player:GetTechTree()

    local techTree = nil
    
    local team = self:GetTeam()
    if team ~= nil and team:isa("PlayingTeam") then
        techTree = team:GetTechTree()
    end
    
    return techTree

end

function Player:UpdateOrderWaypoint()

    local currentOrder = self:GetCurrentOrder()
    
    if(currentOrder ~= nil) then
    
        local targetLoc = Vector(currentOrder:GetLocation())
        self.nextOrderWaypoint = Server.GetNextWaypoint(PhysicsMask.AIMovement, self, self:GetWaypointGroupName(), targetLoc)
        self.finalWaypoint = Vector(targetLoc)
        self.nextOrderWaypointActive = true
        self.waypointType = currentOrder:GetType()
        
    else
    
        self.nextOrderWaypoint = nil
        self.finalWaypoint = nil
        self.nextOrderWaypointActive = false
        self.waypointType = kTechId.None
        
    end

end

function Player:GetPreviousMapName()
    return self.previousMapName
end