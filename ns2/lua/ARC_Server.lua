// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ARC_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Finite state machine for moving ARC towards desired mode. The last entry in each
// table is the desired mode and the previous entries represent the path to get there.
local desiredModeTransitions =
{
    {ARC.kMode.Firing, ARC.kMode.Undeploying, ARC.kMode.UndeployedStationary},
    {ARC.kMode.FireCooldown, ARC.kMode.Undeploying, ARC.kMode.UndeployedStationary},
    {ARC.kMode.Deployed, ARC.kMode.Undeploying, ARC.kMode.UndeployedStationary},
    {ARC.kMode.Targeting, ARC.kMode.Undeploying, ARC.kMode.UndeployedStationary},
    {ARC.kMode.UndeployedStationary, ARC.kMode.Deploying, ARC.kMode.Deployed},
    {ARC.kMode.Moving, ARC.kMode.Deploying, ARC.kMode.Deployed},
    {ARC.kMode.UndeployedStationary, ARC.kMode.Moving},
    {ARC.kMode.Moving, ARC.kMode.UndeployedStationary},
    {ARC.kMode.Deployed, ARC.kMode.Targeting, ARC.kMode.Firing},
    {ARC.kMode.FireCooldown, ARC.kMode.Targeting, ARC.kMode.Firing},
}

function ARC:UpdateMoveOrder(deltaTime)

    local currentOrder = self:GetCurrentOrder()
    ASSERT(currentOrder)
    
    self:SetDesiredMode(ARC.kMode.Moving)
    
    self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), ARC.kMoveSpeed, deltaTime)
    if(self:IsTargetReached(currentOrder:GetLocation(), 0.5)) then
    
        self:CompletedCurrentOrder()
        self:SetPoseParam(ARC.kMoveParam, 0)
        
        // If no more orders, we're done
        if self:GetCurrentOrder() == nil then
            self:SetDesiredMode(ARC.kMode.UndeployedStationary)
        end
        
    else    
        // Repeatedly trigger movement effect 
        self:TriggerEffects("arc_moving")
        
        self:SetPoseParam(ARC.kMoveParam, .5)
    end
    
end

function ARC:SetTargetDirection (target)    
    self.targetDirection = GetNormalizedVector(target:GetEngagementPoint() - self:GetAttachPointOrigin(ARC.kMuzzleNode))
end

function ARC:ClearTargetDirection ()
    self.targetDirection = nil
end

function ARC:UpdateOrders(deltaTime)

    // If deployed, check for targets
    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        // Move ARC if it has an order and it can be moved
        if currentOrder:GetType() == kTechId.Move and (self.mode == ARC.kMode.Moving or self.mode == ARC.kMode.UndeployedStationary) then
        
            self:UpdateMoveOrder(deltaTime)

        elseif currentOrder:GetType() == kTechId.Attack and (self.mode == ARC.kMode.Deployed or self.mode == ARC.kMode.FireCooldown) then
            
            local target = self:GetTarget()            
            if target ~= nil and self:GetCanFireAtTarget(target, nil) then                            
                self:SetTargetDirection(target)
                
                // Try to attack it
                self:SetDesiredMode(ARC.kMode.Firing)                
            else
                self:ClearTargetDirection()
                self:ClearCurrentOrder()
                self:GotoIdle()                
            end
            
        end

    elseif self:GetInAttackMode() then
    
        // Check for new target every so often, but not every frame
        local time = Shared.GetTime()
        if self.timeOfLastAcquire == nil or (time > self.timeOfLastAcquire + 1.5) then
        
            self:AcquireTarget()
            
            self.timeOfLastAcquire = time
            
        end

    end

end

function ARC:AcquireTarget()
    
    local finalTarget = nil
            
    finalTarget = self.targetSelector:AcquireTarget()

    if finalTarget ~= nil then    
      self:GiveOrder(kTechId.Attack, finalTarget:GetId(), nil)        
    else           
      self:ClearOrders()            
    end                    
end

function ARC:GotoIdle()
   if (self:GetInAttackMode()) then
        self:SetDesiredMode(ARC.kMode.Deployed)
        self:SetMode(ARC.kMode.Deployed)
   elseif (self.mode == ARC.kMode.UndeployedStationary) then
        self:SetDesiredMode(ARC.kMode.UndeployedStationary)
        self:SetMode(ARC.kMode.UndeployedStationary)
   end
end

function ARC:PerformAttack()

    local target = self:GetTarget()
    if target then
    
        // Play big hit sound at origin
        target:TriggerEffects("arc_hit_primary")

        // Do damage to everything in radius. Use upgraded splash radius if researched.
        local damageRadius = ConditionalValue(GetTechSupported(self, kTechId.ARCSplashTech), ARC.kUpgradedSplashRadius, ARC.kSplashRadius)
        local hitEntities = self.targetSelector:AcquireTargets(1000, damageRadius, target:GetOrigin())

        // Do damage to every target in range
        RadiusDamage(hitEntities, target:GetOrigin(), damageRadius, ARC.kAttackDamage, self, true)

        // Play hit effect on each
        for index, target in ipairs(hitEntities) do
        
            target:TriggerEffects("arc_hit_secondary")
            
        end
        
    else
        self:GotoIdle()
    end
    
end

function ARC:SetMode(mode)

    if self.mode ~= mode then
    
        local currentAnimation = self:GetAnimation()
        local currentAnimationLength = self:GetAnimationLength()
        local prevAnimationComplete = self.animationComplete

        local triggerEffectName = "arc_" .. string.lower(EnumToString(ARC.kMode, mode))        
        //Print("SetMode(%s) - Triggering %s", EnumToString(ARC.kMode, mode), triggerEffectName)
        self:TriggerEffects(triggerEffectName)
        
        self.mode = mode
        
        // If animation was triggered, store it so we don't transition until it's complete
        if self:GetAnimation() ~= currentAnimation or self.animationComplete ~= prevAnimationComplete then
            self.modeBlockTime = Shared.GetTime() + self:GetAnimationLength()
        else
            self.modeBlockTime = nil    
        end
        
        // Now process actions per mode
        if self.mode == ARC.kMode.Deployed then
        
            self:AcquireTarget()

        elseif self.mode == ARC.kMode.Firing then
        
            self:PerformAttack()
            
            self:SetMode(ARC.kMode.FireCooldown)            
                        
        elseif self.mode == ARC.kMode.FireCooldown then  
        
            // Cooldown time is length attack rate minus fire animation length. 
            self.modeBlockTime = Shared.GetTime() + ARC.kAttackInterval/*(ARC.kAttackInterval - currentAnimationLength)*/
                        
        elseif self.mode == ARC.kMode.Targeting then
        
            // Slightly randomize fire to hit time so ARCs don't all fire at the same time (+/1 1 sec)
            self.modeBlockTime = Shared.GetTime() + math.random(ARC.kFireToHitInterval - 1, ARC.kFireToHitInterval + 1)

        end
        
        if self.modeBlockTime then
           // Print("Set mode block time delay %.2f (currentTime is %.2f)", self.modeBlockTime - Shared.GetTime(), Shared.GetTime())
        end
        
    end
    
end

function ARC:SetDesiredMode(mode)
    if self.desiredMode ~= mode then
      //  Print("Setting desired mode to %s", EnumToString(ARC.kMode, mode))
        self.desiredMode = mode
    end
end

function ARC:UpdateMode()

    if self.desiredMode ~= self.mode then

        if (self.desiredMode ==  ARC.kMode.UndeployedStationary) and (self.mode == ARC.kMode.Deployed) then
            self.targetSelector:AttackerMoved()
        end
    
        // Look at desired state transitions with a target of this desired mode and move us toward it
        if not self.modeBlockTime or Shared.GetTime() >= self.modeBlockTime then
                    
            for index, path in ipairs(desiredModeTransitions) do
            
                local numPathEntries = table.count(path)
                local target = path[numPathEntries]
                
                if target == self.desiredMode then
                
                    for pathIndex = 1, numPathEntries - 1 do
                    
                        if path[pathIndex] == self.mode then
                        
                            local newMode = path[pathIndex + 1]
                            
                            //Print("Found path transition (%s) => %s", ToString(path), EnumToString(ARC.kMode, newMode))
                            
                            self:SetMode(newMode)
                            
                            return
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

