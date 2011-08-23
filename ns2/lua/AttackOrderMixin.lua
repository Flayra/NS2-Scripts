// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\AttackOrderMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * AttackOrderMixin handles processing attack orders.
 */
AttackOrderMixin = { }
AttackOrderMixin.type = "AttackOrder"

AttackOrderMixin.expectedMixins =
{
    Orders = "Needed for calls to GetCurrentOrder().",
    Pathing = "Needed for calls to MoveToTarget().",
    GameEffects = "Needed for calls to AdjustAttackDelay()."
}

AttackOrderMixin.expectedCallbacks =
{
    GetMeleeAttackDamage = "Returns the amount of damage each melee hit does.",
    GetMeleeAttackInterval = "Returns how often this Entity melee attacks.",
    GetMeleeAttackOrigin = "Returns where the melee attack originates from.",
    TriggerEffects = "The melee_attack effect will be triggered through this callback.",
    GetOwner = "Returns the owner, if any, of this Entity."
}

AttackOrderMixin.expectedConstants =
{
    kMoveToDistance = "The distance at which the move part of the Attack order is complete."
}

function AttackOrderMixin:__initmixin()

    self.timeOfLastAttackOrder = 0
    
end

// This is an "attack-move" from RTS. Attack the entity specified in our current attack order, if any. 
// Otherwise, move to the location specified in the attack order and attack anything along the way.
function AttackOrderMixin:ProcessAttackOrder(targetSearchDistance, moveSpeed, time)

    // If we have a target, attack it.
    local currentOrder = self:GetCurrentOrder()
    if currentOrder ~= nil then
    
        local target = Shared.GetEntity(currentOrder:GetParam())
        
        if target then
        
            // How do you kill that which has no life?
            if not HasMixin(target, "Live") or not target:GetIsAlive() then
                self:CompletedCurrentOrder()
            else
            
                local targetLocation = target:GetEngagementPoint()
                if self:GetIsFlying() then
                    targetLocation = GetHoverAt(self, targetLocation)
                end
                
                self:MoveToTarget(PhysicsMask.AIMovement, targetLocation, moveSpeed, time)
                
            end
                
        else
        
            // Check for a nearby target. If not found, move towards destination.
            target = self:_FindTarget(targetSearchDistance)
 
        end
        
        if target and HasMixin(target, "Live") then
        
            // If we are close enough to target, attack it    
            local targetPosition = Vector(target:GetOrigin())
            if self.GetHoverHeight then
                targetPosition.y = targetPosition.y + self:GetHoverHeight()
            end
            
            // Different targets can be attacked from different ranges, depending on size
            local attackDistance = GetEngagementDistance(currentOrder:GetParam())
            
            local distanceToTarget = (targetPosition - self:GetOrigin()):GetLength()
            if (distanceToTarget <= attackDistance) and target:GetIsAlive() then
                self:_OrderMeleeAttack(target)
            end
            
        else
        
            // otherwise move towards attack location and end order when we get there
            local targetLocation = currentOrder:GetLocation()
            if self:GetIsFlying() then
                targetLocation = GetHoverAt(self, targetLocation)
            end
            
            self:MoveToTarget(PhysicsMask.AIMovement, targetLocation, moveSpeed, time)
            
            local distanceToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLength()
            if distanceToTarget < self:GetMixinConstants().kMoveToDistance then
                self:CompletedCurrentOrder()
            end
 
        end
        
    end
    
end
AddFunctionContract(AttackOrderMixin.ProcessAttackOrder, { Arguments = { "Entity", "number", "number", "number" }, Returns = { } })

function AttackOrderMixin:_GetIsTargetValid(target)
    return target ~= self and target ~= nil
end

/**
 * Returns valid taret within attack distance, if any.
 */
function AttackOrderMixin:_FindTarget(attackDistance)

    // Find enemy in range
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    local potentialTargets = GetEntitiesWithMixinForTeamWithinRange("Live", enemyTeamNumber, self:GetOrigin(), attackDistance)
    
    local nearestTarget = nil
    local nearestTargetDistance = 0
    
    // Get closest target
    for index, currentTarget in ipairs(potentialTargets) do
    
        if self:_GetIsTargetValid(currentTarget) then
        
            local distance = self:GetDistance(currentTarget)
            if nearestTarget == nil or distance < nearestTargetDistance then
            
                nearestTarget = currentTarget
                nearestTargetDistance = distance
                
            end    
            
        end
        
    end

    return nearestTarget    
    
end

function AttackOrderMixin:_OrderMeleeAttack(target)

    local meleeAttackInterval = self:AdjustAttackDelay(self:GetMeleeAttackInterval())
    
    if Shared.GetTime() > (self.timeOfLastAttackOrder + meleeAttackInterval) then
    
        self:TriggerEffects(string.format("%s_melee_attack", string.lower(self:GetClassName())))

        // Traceline from us to them
        local trace = Shared.TraceRay(self:GetMeleeAttackOrigin(), target:GetOrigin(), PhysicsMask.AllButPCs, EntityFilterTwo(self, target))

        local direction = target:GetOrigin() - self:GetOrigin()
        direction:Normalize()
        
        // Use player or owner (in the case of MACs, Drifters, etc.)
        local attacker = self:GetOwner()
        if self:isa("Player") then
            attacker = self
        end
        
        target:TakeDamage(self:GetMeleeAttackDamage(), attacker, self, trace.endPoint, direction)

        // Play hit effects - doer, target, origin, surface
        TriggerHitEffects(self, target, trace.endPoint, trace.surface, true)
        
        self.timeOfLastAttackOrder = Shared.GetTime()
        
    end

end