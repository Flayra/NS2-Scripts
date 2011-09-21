// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScriptActor_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/**
 * Sets whether or not the actor is marked as selected. The actual selection state is stored
 * with the commander, this is used to make the actor always propagated to commanders.
 */
function ScriptActor:SetIsSelected(selected)

    if selected then
        self.selectedCount = self.selectedCount + 1
    else
        self.selectedCount = self.selectedCount - 1
        ASSERT(self.selectedCount >= 0)
    end
    
    self:UpdateIncludeRelevancyMask()

end

/**
 * Sets whether or not the actor is marked as hotgrouped. The actual hotgroup state is stored
 * with the commander, this is used to make the actor always propagated to commanders.
 */
function ScriptActor:SetIsHotgrouped(hotgrouped)

    if hotgrouped then
        self.hotgroupedCount = self.hotgroupedCount + 1
    else
        self.hotgroupedCount = self.hotgroupedCount - 1
        ASSERT(self.hotgroupedCount >= 0)
    end
    
    self:UpdateIncludeRelevancyMask()

end

function ScriptActor:UpdateIncludeRelevancyMask()

    // Make entities which are active for a commander relevant to all commanders
    // on the same team.
    self:SetAlwaysRelevantToCommander( self.selectedCount > 0 or self.hotgroupedCount > 0 )
    
end

/**
 * Marks the actor as being always relevant to the commanders on the same team.
 */
function ScriptActor:SetAlwaysRelevantToCommander(relevant)
    
    local includeMask = 0
    
    if relevant then
        if self:GetTeamNumber() == 1 then
            includeMask = kRelevantToTeam1Commander
        elseif self:GetTeamNumber() == 2 then
            includeMask = kRelevantToTeam2Commander
        end
    end
    
    self:SetIncludeRelevancyMask( includeMask )

end

function ScriptActor:SetOwner(player)

    local success = false
    
    if player ~= nil and self.ownerPlayerId ~= Entity.invalidId then
        Shared.Message("Warning: A ScriptActor cannot have more than one owner! Player: " .. player:GetName() .. " ScriptActor: " .. self:GetName())
        ASSERT(false)
        return false
    end
    
    local ownerPlayerEntity = Shared.GetEntity(self.ownerPlayerId)
    
    if player == nil then
        if ownerPlayerEntity then
            ownerPlayerEntity:SetIsOwner(self, false)
        end
        self.ownerPlayerId = Entity.invalidId
        success = true
    elseif player:isa("Player") then
        self.ownerPlayerId = player:GetId()
        player:SetIsOwner(self, true)
        success = true
    else
        Print("%s:SetOwner(): Must be called with a Player (not a %s)", self:GetClassName(), player:GetClassName())
    end
    
    return success
    
end

function ScriptActor:GetOwner()

    // Shared.GetEntity() will return nil if the ownerPlayerId is invalid.
    return Shared.GetEntity(self.ownerPlayerId)
    
end

/**
 * Sets whether the ScriptActor is or isn't the owner of the passed in entity.
 * This is needed for proper destruction.
 */
function ScriptActor:SetIsOwner(ofEntity, isOwner)

    if isOwner then
        table.insertunique(self.ownedEntities, ofEntity)
    else
        table.removevalue(self.ownedEntities, ofEntity)
    end

end

function ScriptActor:AddScoreForOwner(score)

    local owner = self:GetOwner()
    if owner and (self:GetTeamNumber() == owner:GetTeamNumber()) and owner:isa("Player") and score > 0 then
        owner:AddScore(score)
    end

end

// Pass newId of object is turning into or 0/nil if it's being deleted. Called
// by Actor:OnDestroy() and Player:Replace(). 
function ScriptActor:SendEntityChanged(newId)

    // This happens during the game shutdown process, so don't force a new game
    // rules to be created if one doesn't already exist.
    if GetHasGameRules() then
        // Process entity change server-side
        GetGamerules():OnEntityChange(self:GetId(), newId)
    end

    // Send message to everyone that the player changed ids
    Server.SendNetworkMessage("EntityChanged", BuildEntityChangedMessage(self:GetId(), ConditionalValue(newId ~= nil, newId, -1)), true)
    
end

function ScriptActor:OnKill(damage, attacker, doer, point, direction)

    // Remove links between objects on death
    self:ClearAttached()

end

function ScriptActor:ClearAttached()

    // Call attached entity's ClearAttached function
    local entity = Shared.GetEntity(self.attachedId)
    if entity ~= nil then

        // Set first so we don't call infinitely
        self.attachedId = Entity.invalidId    
        
        if entity:isa("ScriptActor") then
            entity:ClearAttached()
        end
        
    end
    
end

function ScriptActor:SetTeamNumber(teamNumber)

    self.teamNumber = teamNumber    
    
    // Update team type
    self.teamType = kNeutralTeamType
    
    if(teamNumber == 1) then
        self.teamType = kTeam1Type
    elseif(teamNumber == 2) then
        self.teamType = kTeam2Type
    end
    
end

function ScriptActor:OnDestroy()
    
    // Remove all owned entities.
    function RemoveOwnedEntityFunctor(entity)
        entity:SetOwner(nil)
    end
    table.foreachfunctor(self.ownedEntities, RemoveOwnedEntityFunctor)
    table.clear(self.ownedEntities)
    
    // Notify the owner of this ScriptActor it is no longer the owner.
    if self:GetOwner() then
        self:GetOwner():SetIsOwner(self, false)
    end
    
    // Notify others of the change 
    self:SendEntityChanged(nil)
    
    Actor.OnDestroy(self)
    
end

function ScriptActor:GetTeam()
    return GetGamerules():GetTeam(self:GetTeamNumber())    
end

function ScriptActor:GetIsTargetValid(target)
    return target ~= self and target ~= nil
end

// Return valid taret within attack distance, if any
function ScriptActor:FindTarget(attackDistance)

    // Find enemy in range
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    local potentialTargets = GetEntitiesWithMixinForTeamWithinRange("Live", enemyTeamNumber, self:GetOrigin(), attackDistance)
    
    local nearestTarget = nil
    local nearestTargetDistance = 0
    
    // Get closest target
    for index, currentTarget in ipairs(potentialTargets) do
    
        if(self:GetIsTargetValid(currentTarget)) then
        
            local distance = self:GetDistance(currentTarget)
            if(nearestTarget == nil or distance < nearestTargetDistance) then
            
                nearestTarget = currentTarget
                nearestTargetDistance = distance
                
            end    
            
        end
        
    end

    return nearestTarget    
    
end

// Called when tech tree activation performed on entity. Return true if legal and action handled.
function ScriptActor:PerformActivation(techId, position, normal, commander)
    return false
end

// Called when tech tree action performed on entity. Return true if legal and action handled. Position passed if applicable.
function ScriptActor:PerformAction(techNode, position)
    return false
end

// Return true for first param if entity handles this action. Only technodes that specified by
// the entities techbuttons will be allowed to call this function. Orientation is in radians and is
// specified by commander when giving order.
function ScriptActor:OverrideTechTreeAction(techNode, position, orientation, commander)
    return false, true
end

// A structure can be attached to another structure (ie, resource tower to resource nozzle)
function ScriptActor:SetAttached(structure)
    
    if(structure ~= nil) then
    
        // Because they'll call SetAttached back on us
        if structure:GetId() ~= self.attachedId then
        
            self:ClearAttached()
            self.attachedId = structure:GetId()            
            structure:SetAttached(self)
            
        end
        
    else
    
        self.attachedId = Entity.invalidId
        
    end

end

function ScriptActor:OnResearchComplete(structure, researchId)
end

function ScriptActor:SetLocationName(locationName, silent)

    local success = false
    
    self.locationId = Shared.GetStringIndex(locationName)
    
    if self.locationId ~= 0 then
        success = true
    elseif not silent then
        Print("%s:SetLocationName(%s): String not precached.", self:GetClassName(), ToString(locationName))
    end
    
    return success
    
end

// Called after all entities are loaded. Put code in here that depends on other entities being loaded.
function ScriptActor:OnMapPostLoad()
    self:ComputeLocation()
end
