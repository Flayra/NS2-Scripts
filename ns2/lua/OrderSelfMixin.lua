// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\OrderSelfMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

OrderSelfMixin = { }
OrderSelfMixin.type = "OrderSelf"

local kFindStructureRange = 20
local kFindFriendlyPlayersRange = 15
local kTimeToDefendSinceTakingDamage = 5
// What percent of health an enemy structure is below when it is considered a priority for attacking.
local kPriorityAttackHealthScalar = 0.6

OrderSelfMixin.expectedCallbacks = {
    GetTeamNumber = "Returns the team number this Entity is on." }

OrderSelfMixin.expectedConstants = {
    kPriorityAttackTargets = "Which target types to prioritize for attack orders after the low health priority has been considered." }

// How often to look for orders.
local kOrderSelfUpdateRate = 2

function OrderSelfMixin:__initmixin()

    assert(HasMixin(self, "TimedCallback"))
    assert(HasMixin(self, "Orders"))
    
    self:AddTimedCallback(OrderSelfMixin._UpdateOrderSelf, kOrderSelfUpdateRate)
    
end

function OrderSelfMixin:_FindConstructOrder(structuresNearby)

    local closestStructure = nil
    local closestStructureDist = Math.infinity
    for i, structure in ipairs(structuresNearby) do
        local structureDist = (structure:GetOrigin() - self:GetOrigin()):GetLengthSquared()
        if not structure:GetIsBuilt() and structureDist < closestStructureDist then
            closestStructure = structure
            closestStructureDist = structureDist
        end
    end
    
    if closestStructure then
        return kTechId.None ~= self:GiveOrder(kTechId.Construct, closestStructure:GetId(), closestStructure:GetOrigin(), nil, false, false)
    end
    
    return false

end
AddFunctionContract(OrderSelfMixin._FindConstructOrder, { Arguments = { "Entity", "table" }, Returns = { "boolean" } })

function OrderSelfMixin:_FindDefendOrder(structuresNearby)

    local closestStructure = nil
    local closestStructureDist = Math.infinity
    for i, structure in ipairs(structuresNearby) do
        local structureDist = (structure:GetOrigin() - self:GetOrigin()):GetLengthSquared()
        local lastTimeDamageTaken = structure:GetTimeOfLastDamage()
        if lastTimeDamageTaken and lastTimeDamageTaken > 0 and ((Shared.GetTime() - lastTimeDamageTaken) < kTimeToDefendSinceTakingDamage) and (structureDist < closestStructureDist) then
            closestStructure = structure
            closestStructureDist = structureDist
        end
    end
    
    if closestStructure then
        return kTechId.None ~= self:GiveOrder(kTechId.SquadDefend, closestStructure:GetId(), closestStructure:GetOrigin(), nil, false, false)
    end
    
    return false

end
AddFunctionContract(OrderSelfMixin._FindDefendOrder, { Arguments = { "Entity", "table" }, Returns = { "boolean" } })

function OrderSelfMixin:_FindPlayerOrdersToCopy(friendlyPlayersNearby)

    local closestPlayer = nil
    local closestPlayerDist = Math.infinity
    for i, player in ipairs(friendlyPlayersNearby) do
        if player:GetHasOrder() then
            local playerDist = (player:GetOrigin() - self:GetOrigin()):GetLengthSquared()
            if playerDist < closestPlayerDist then
                closestPlayer = player
                closestPlayerDist = playerDist
            end
        end
    end
    
    if closestPlayer then
        local playerOrder = closestPlayer:GetCurrentOrder()
        return kTechId.None ~= self:GiveOrder(playerOrder:GetType(), playerOrder:GetParam(), playerOrder:GetLocation(), playerOrder:GetOrientation())
    end
    
    return false

end
AddFunctionContract(OrderSelfMixin._FindPlayerOrdersToCopy, { Arguments = { "Entity", "table" }, Returns = { "boolean" } })

/**
 * Find closest structure with health less than the kPriorityAttackHealthScalar, otherwise just closest matching kPriorityAttackTargets, otherwise closest structure.
 */
function OrderSelfMixin:_FindAttackOrder(structuresNearby)

    local closestStructure = nil
    local closestStructureDist = Math.infinity
    local closestStructureHealthScalar = 1
    local closestStructureIsPriorityTarget = false
    for i, structure in ipairs(structuresNearby) do
    
        if structure:GetIsSighted() then
        
            local structureDist = (structure:GetOrigin() - self:GetOrigin()):GetLengthSquared()
            local closerThanClosest = structureDist < closestStructureDist
            
            local structureHealthScalar = structure:GetHealthScalar()
            local healthBelowThreshold = structureHealthScalar <= kPriorityAttackHealthScalar
            local closestHealthBelowThreshold = closestStructureHealthScalar <= kPriorityAttackHealthScalar
            local isMoreImportantThanClosest = healthBelowThreshold and structureHealthScalar < closestStructureHealthScalar
            
            local isAPriorityAttackTarget = false
            for i, targetType in ipairs(self:GetMixinConstants().kPriorityAttackTargets) do
            
                if structure:isa(targetType) then
                    isAPriorityAttackTarget = true
                    break
                end
                
            end
            
            if (isMoreImportantThanClosest) or
               (isAPriorityAttackTarget and (not closestStructureIsPriorityTarget or closerThanClosest) and not closestHealthBelowThreshold) or
               (closerThanClosest and not closestStructureIsPriorityTarget and not closestHealthBelowThreshold) then
               
                closestStructure = structure
                closestStructureDist = structureDist
                closestStructureHealthScalar = structureHealthScalar
                closestStructureIsPriorityTarget = isAPriorityAttackTarget
                
            end
            
        end
        
    end
    
    if closestStructure then
        return kTechId.None ~= self:GiveOrder(kTechId.Attack, closestStructure:GetId(), closestStructure:GetOrigin(), nil, false, false)
    end
    
    return false

end
AddFunctionContract(OrderSelfMixin._FindAttackOrder, { Arguments = { "Entity", "table" }, Returns = { "boolean" } })

function OrderSelfMixin:_UpdateOrderSelf()

    if not self:GetHasOrder() then
    
        local friendlyStructuresNearby = GetEntitiesForTeamWithinRange("Structure", self:GetTeamNumber(), self:GetOrigin(), kFindStructureRange)
        local enemyStructuresNearby = GetEntitiesForTeamWithinRange("Structure", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kFindStructureRange)
        local friendlyPlayersNearby = GetEntitiesForTeamWithinRange("Player", self:GetTeamNumber(), self:GetOrigin(), kFindFriendlyPlayersRange)
        
        // First priority is construct nearby structures.
        local hasOrderNow = self:_FindConstructOrder(friendlyStructuresNearby)
        // Second priority is defend nearby structures under attack.
        if not hasOrderNow then
            hasOrderNow = self:_FindDefendOrder(friendlyStructuresNearby)
        end
        // Third priority is copy orders of nearby players that have orders.
        if not hasOrderNow then
            hasOrderNow = self:_FindPlayerOrdersToCopy(friendlyPlayersNearby)
        end
        // Fourth priority is attack close, sighted enemy structures.
        if not hasOrderNow then
            hasOrderNow = self:_FindAttackOrder(enemyStructuresNearby)
        end
        
    end
    
    // Continue forever.
    return true

end
AddFunctionContract(OrderSelfMixin._UpdateOrderSelf, { Arguments = { "Entity" }, Returns = { "boolean" } })