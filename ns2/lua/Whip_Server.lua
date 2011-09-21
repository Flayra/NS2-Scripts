// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Whip_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


function Whip:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetNextThink(1.0)
    
end

function Whip:AcquireTarget()

    local finalTarget = nil
    
    if(self.timeOfLastTargetAcquisition == nil or (Shared.GetTime() > self.timeOfLastTargetAcquisition + Whip.kTargetCheckTime)) then
    
        finalTarget = self.targetSelector:AcquireTarget();

        if finalTarget ~= nil then
    
            self:GiveOrder(kTechId.Attack, finalTarget:GetId(), nil)
        
        else
        
            self:ClearOrders()
            
        end
        
        self.timeOfLastTargetAcquisition = Shared.GetTime()

    end
    
end


function Whip:AttackTarget()

    local target = self:GetTarget()
    
    if(target ~= nil) then
    
        self:TriggerUncloak()
    
        self:TriggerEffects("whip_attack")
   
        // When attack animation finishes, attack again
        self.attackAnimation = self:GetAnimation()
    
        self.timeOfLastStrikeStart = Shared.GetTime()
        
        self.timeOfNextStrikeHit = Shared.GetTime() + self:AdjustAttackDelay(.5)
                
    end

end

function Whip:GetClosestAttackPoint(target)

    ASSERT(target)
    local attackPoint = target:GetEngagementPoint()
    local inRange = false

    local toAttack = target:GetEngagementPoint() - self:GetModelOrigin()
    local length = toAttack:GetLength()
    
    if length <= Whip.kRange then
        inRange = true
    else
        toAttack:Normalize()    
        attackPoint = self:GetModelOrigin() + toAttack * Whip.kRange
    end
    
    return attackPoint, inRange
    
end

function Whip:StrikeTarget(target)

    // Hit main target
    self:DamageTarget(target)
    
    // Try to hit other targets close by
    local closestAttackPoint = self:GetClosestAttackPoint(target)
    local nearbyEnts = self.targetSelector:AcquireTargets(1000, Whip.kAreaEffectRadius, closestAttackPoint)
    for index, ent in ipairs(nearbyEnts) do
    
        if ent ~= target then
        
            local direction = ent:GetModelOrigin() - closestAttackPoint
            direction:Normalize()
            
            ent:TakeDamage(Whip.kDamage, self, self, closestAttackPoint, direction)
            
        end
        
    end
    
    self.timeOfNextStrikeHit = nil
    
end

function Whip:DamageTarget(target)

    // Do damage to target if still within range
    local attackPoint, inRange = self:GetClosestAttackPoint(target)
    if inRange then
    
        local direction = attackPoint - self:GetOrigin()
        direction:Normalize()
        
        target:TakeDamage(Whip.kDamage, self, self, attackPoint, direction)
        
    end
    
end

function Whip:SetDesiredMode(mode)
    if self.desiredMode ~= mode then
        self.desiredMode = mode
    end
end

function Whip:UpdateMode(deltaTime)

    if self.desiredMode ~= self.mode then
    
        if (self.desiredMode == Whip.kMode.UnrootedStationary) and (self.mode == Whip.kMode.Rooted) then
        
            self:SetMode(Whip.kMode.Unrooting)
            // when we move, our static targets becomes invalid. As we can't attack until we are rooted again,
            // we don't need to do anything further
            self.targetSelector:AttackerMoved()
            
            // If we are moving we need to remove out current location from the Pathing mesh
            self:RemoveFromMesh()
            
        elseif self.desiredMode == Whip.kMode.Moving and (self.mode == Whip.kMode.UnrootedStationary) then
        
            self:SetMode(Whip.kMode.StartMoving)
            
        elseif (self.desiredMode == Whip.kMode.Rooted) and (self.mode == Whip.kMode.UnrootedStationary or self.mode == Whip.kMode.StartMoving or self.mode == Whip.kMode.Moving or self.mode == Whip.kMode.EndMoving) then
        
            self:SetMode(Whip.kMode.Rooting)
            // We are being set back to a stationry position and so we need to add ourselves back to the mesh
            self:AddToMesh()
        end
        
    end
    
end

function Whip:OnDestroyCurrentOrder(currentOrder)

    // Order was stopped or canceled
    if(currentOrder:GetType() == kTechId.Move and self.mode == Whip.kMode.UnrootedStationary) then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)        
    end
    
end

function Whip:OnOrderComplete(currentOrder)

    if(currentOrder:GetType() == kTechId.Move) then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)        
    end

end

function Whip:UpdateOrders(deltaTime)

    // If we're moving
    local currentOrder = self:GetCurrentOrder()
    if currentOrder and currentOrder:GetType() == kTechId.Move then
    
        self:SetDesiredMode(Whip.kMode.Moving)
        
        if self.mode == Whip.kMode.Moving then

            // Repeatedly trigger movement effect 
            self:TriggerEffects("whip_moving")
    
            self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), Whip.kMoveSpeed, deltaTime)
            if(self:IsTargetReached(currentOrder:GetLocation(), kEpsilon)) then
                self:CompletedCurrentOrder()
            end
            
        end
        
    end

    // Attack on our own
    if self.mode == Whip.kMode.Rooted then
            
        self:UpdateAttack(deltaTime)
            
    end
    
end

function Whip:UpdateAttack(deltaTime)

    // Check if alive because map-placed structures don't die when killed

    if self:GetIsBuilt() and self:GetIsAlive() then
        // Check to see if it's time to fire again
        local time = Shared.GetTime()
        if not self.timeOfLastWhipAttack or (time > (self.timeOfLastWhipAttack + Whip.kScanThinkInterval)) then        
            local target = self:GetTarget()
            local targetValid = self.targetSelector:ValidateTarget(target)
            if targetValid then
                local delay = self:AdjustAttackDelay(Whip.kROF)
                if(self.timeOfLastStrikeStart == nil or (time > self.timeOfLastStrikeStart + delay)) then                
                    self:AttackTarget()
                end
                
                // Update our attackYaw to aim at our current target
                local attackDir = GetNormalizedVector(self:GetClosestAttackPoint(target) - self:GetModelOrigin())
                
                // This is negative because of how model is set up (spins clockwise)
                local attackYawRadians = -math.atan2(attackDir.x, attackDir.z)
                
                // Factor in the orientation of the whip.
                attackYawRadians = attackYawRadians + self:GetAngles().yaw
                
                self.attackYaw = DegreesTo360(math.deg(attackYawRadians))
                
                if self.attackYaw < 0 then
                    self.attackYaw = self.attackYaw + 360
                end
                
                self.timeOfLastWhipAttack = time
                
            else
                self:AcquireTarget()            
            end

            
        end
        
        if self.timeOfNextStrikeHit ~= nil then
        
            local target = self:GetTarget()
            
            if Shared.GetTime() > self.timeOfNextStrikeHit then
            
                if self.targetSelector:ValidateTarget(target) then
                
                    self:StrikeTarget(target)
                    
                else
                
                    self:AcquireTarget()
                    
                    self.timeOfNextStrikeHit = nil
                    
                end
                
            end
               
        end
        
    end
    
end

function Whip:SetMode(mode)

    if self.mode ~= mode then

        self.modeAnimation = ""
        
        local triggerEffectName = "whip_" .. string.lower(EnumToString(Whip.kMode, mode))
        self:TriggerEffects(triggerEffectName)

        self.mode = mode
        self.modeAnimation = self:GetAnimation()
        
    end
    
end

function Whip:UpdateRootState()

    // Unroot whips if infestation recedes
    if (self.mode == Whip.kMode.Rooted) and not self:GetGameEffectMask(kGameEffect.OnInfestation) then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)
    end
    
end

function Whip:OnUpdate(deltaTime)

    PROFILE("Whip:OnUpdate")

    Structure.OnUpdate(self, deltaTime)
    
    self:UpdateRootState()
    
    // Handle sentry state changes
    self:UpdateMode(deltaTime)
    
    self:UpdateOrders(deltaTime)

end

function Whip:OnAnimationComplete(animName)

    Structure.OnAnimationComplete(self, animName)
    
    if animName == self.attackAnimation then
    
        local target = self:GetTarget()
        
        if not self.targetSelector:ValidateTarget(target) then
        
            self:CompletedCurrentOrder()
            
            self:OnIdle()

        end
        
    end

    // Handle whip movement transitions        
    if self.modeAnimation == animName then
        
        if self.mode == Whip.kMode.Unrooting then
        
            self:SetMode(Whip.kMode.UnrootedStationary)        
    
        elseif self.mode == Whip.kMode.Rooting then
        
            self:SetMode(Whip.kMode.Rooted)

        elseif self.mode == Whip.kMode.StartMoving then
        
            self:SetMode(Whip.kMode.Moving)

        elseif self.mode == Whip.kMode.EndMoving then
        
            self:SetMode(Whip.kMode.UnrootedStationary)
            
        end
        
    end
    
end

function Whip:GetCanIdle()

    local target = self:GetTarget()
    local stationary = self.mode == Whip.kMode.Rooted or (self.mode == Whip.kMode.UnrootedStationary and not self:GetCurrentOrder())
    return Structure.GetCanIdle(self) and not target and stationary
    
end

function Whip:GetIsFuryActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfLastFury ~= nil) and (Shared.GetTime() < (self.timeOfLastFury + Whip.kFuryDuration))
end

function Whip:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)

    if success then
    
        // Transform into mature whip
        if structure and (structure:GetId() == self:GetId()) and (researchId == kTechId.UpgradeWhip) then
        
            success = self:UpgradeToTechId(kTechId.MatureWhip)
            
        end
        
    end
    
    return success    
    
end

function Whip:TriggerFury()

    self:TriggerEffects("whip_trigger_fury")
    
    // Increase damage for players, whips (including self!), etc. in range
    self.timeOfLastFury = Shared.GetTime()
    
    return true
    
end

function Whip:TargetBombard(position)
    return true
end

function Whip:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.WhipFury then
        success = self:TriggerFury()
    elseif techId == kTechId.WhipBombard then
        success = self:TargetBombard(position)
    elseif techId == kTechId.WhipUnroot then
        self:SetDesiredMode(Whip.kMode.UnrootedStationary)
    elseif techId == kTechId.WhipRoot then
        self:SetDesiredMode(Whip.kMode.Rooted)
    end
    
    return success
    
end

function Whip:OnDestroy()
    Structure.OnDestroy(self)    
    self:ClearInfestation()    
end