// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sentry_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Sentry:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetDesiredMode(Sentry.kMode.PoweringUp)
        
end

function Sentry:OnDestroy()
    
    if self:GetSentryMode() == Sentry.kMode.Attacking then
        self:SetFiringSoundState(false)
    end
    
    Structure.OnDestroy(self)
    
end

function Sentry:OnKill(damage, attacker, doer, point, direction)

    self:SetFiringSoundState(false)
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)
    
end

function Sentry:OnOverrideOrder(order)
    
    local orderTarget = nil
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to enemies => attack
    if order:GetType() == kTechId.Default and orderTarget and HasMixin(orderTarget, "Live") and GetEnemyTeamNumber(orderTarget:GetTeamNumber()) == self:GetTeamNumber() then
    
        order:SetType(kTechId.Attack)
        
    end
    
end

function Sentry:OnTakeDamage(damage, attacker, doer, point)
    
    self:GetTeam():TriggerAlert(kTechId.MarineAlertSentryUnderAttack, self)
    
    Structure.OnTakeDamage(self, damage, attacker, doer, point)
    
    // Start attacking whatever attacks us, if we can hit it. Don't reacquire constantly though.
    if attacker and (Shared.GetTime() > self.timeOfLastTargetAcquisition + 1) then
    
        self:SetTarget(attacker)
    
    end
    
end

// Returns entity 
function Sentry:SetTarget(newTarget)

    // check if we are targeting the same unit so we don't generate 10 orders/sec attacking the same target
    local currentTarget = self:GetTarget()
    if not currentTarget or (newTarget and currentTarget:GetId() ~= newTarget:GetId()) then
    
        if self.targetSelector:ValidateTarget(newTarget) then
        
            self:GiveOrder(kTechId.Attack, newTarget:GetId(), nil)
            self.timeOfLastTargetAcquisition = Shared.GetTime()
            return newTarget
            
        end
    
    end
    
    return nil
    
end

// Control looping centrally to make sure fire sound doesn't stop or start unnecessarily
function Sentry:SetFiringSoundState(state)

    if state ~= self.playingAttackSound then
    
        if state then
            self:PlaySound(Sentry.kAttackSoundName)
        else
            self:StopSound(Sentry.kAttackSoundName)
        end
        
        self.playingAttackSound = state
        
    end
    
end

function Sentry:SetMode(mode)
    
    // Change animations
    if self.mode ~= mode then
    
        local firingSoundState = false
        local hasAmmo = (self:GetAmmo() > 0)
           
        // Don't play power up if we're deploying
        if mode == Sentry.kMode.PoweringUp and self.mode ~= Sentry.kMode.Unbuilt and hasAmmo then        
        
            // Start scanning for targets once built
            local animName = Structure.kAnimPowerUp
            self:SetAnimation(animName)
            
            self:GetAnimationLength(animName)
            
            self:TriggerEffects("power_up")
        
        elseif mode == Sentry.kMode.PoweringDown then
        
            local powerDownAnim = self:GetPowerDownAnimation()
            self:SetAnimation(powerDownAnim)
            
            modeTime = self:GetAnimationLength(powerDownAnim)
            
            self:TriggerEffects("power_down")
        
        elseif mode == Sentry.kMode.Scanning and hasAmmo then
        
            local v = Shared.GetRandomInt(1,3)
            local animName = "idle" .. ((v == 1 and "") or v)
            
            self:SetAnimation(animName)
      
        elseif mode == Sentry.kMode.SpinningUp and hasAmmo then
        
            local anim = Sentry.kAttackStartAnim
            
            // Spin up faster!
            self:SetAnimation(anim, true, 3)
            modeTime = self:GetAnimationLength(anim)
            
            self:PlaySound(Sentry.kSpinUpSoundName)
        
        elseif mode == Sentry.kMode.Attacking and hasAmmo then
        
            self:SetAnimation(Sentry.kAttackAnim)
            firingSoundState = true            
        
        elseif mode == Sentry.kMode.SpinningDown then
        
            self:SetAnimation(Sentry.kAttackEndAnim)
            self:PlaySound(Sentry.kSpinDownSoundName)

        end
        
        self.mode = mode
        
        self:SetFiringSoundState(firingSoundState)
        
    end
    
end

// Look at desired mode and current state and call SetMode() accordingly.
function Sentry:UpdateMode(deltaTime)

    if self.desiredMode ~= self.mode then
    
        if self.desiredMode == Sentry.kMode.Attacking then
        
            if self.mode == Sentry.kMode.Scanning or self.mode == Sentry.kMode.SpinningDown then
                self:SetMode(Sentry.kMode.SpinningUp)
            end
            
        elseif self.desiredMode == Sentry.kMode.Scanning then
        
            if self.mode == Sentry.kMode.Attacking or self.mode == Sentry.kMode.SpinningUp then
                self:SetMode(Sentry.kMode.SpinningDown)
            end

        elseif self.desiredMode == Sentry.kMode.SettingTarget then
            
            // If we're attacking or spinning up, spin down
            if self.mode == Sentry.kMode.Attacking or self.mode == Sentry.kMode.SpinningUp then            
                self:SetMode(Sentry.kMode.SpinningDown)                
            // If we're scanning, power down
            elseif self.mode == Sentry.kMode.Scanning then
                self:SetMode(Sentry.kMode.PoweringDown)
            end
            
        end
        
    end

end

function Sentry:SetDesiredMode(mode)
    self.desiredMode = mode
end

function Sentry:OnAnimationComplete(animName)

    Structure.OnAnimationComplete(self, animName)
    
    if animName == self:GetDeployAnimation() then
    
        self:SetMode(Sentry.kMode.Scanning)
    
    elseif animName == Sentry.kAttackStartAnim then
    
        self:SetMode(Sentry.kMode.Attacking)

    elseif animName == Sentry.kAttackEndAnim then

        if self.desiredMode == Sentry.kMode.SettingTarget then    
            self:SetMode(Sentry.kMode.PoweringDown)
        else
            self:SetMode(Sentry.kMode.Scanning)
        end

    elseif animName == self:GetPowerUpAnimation() then
    
        self:SetMode(Sentry.kMode.Scanning)
        
    elseif animName == self:GetPowerDownAnimation() then
    
        if self.desiredMode == Sentry.kMode.SettingTarget then    
            self:SetMode(Sentry.kMode.SettingTarget)
        else
            self:SetMode(Sentry.kMode.PoweredDown)
        end
    end
        
end

function Sentry:OnPoweredChange(newPoweredState)

    Structure.OnPoweredChange(self, newPoweredState)
    
    if not newPoweredState then
        self:SetMode(Sentry.kMode.PoweringDown)    
    else
        self:SetMode(Sentry.kMode.PoweringUp)
    end
    
end

function Sentry:GetDamagedAlertId()
    return kTechId.MarineAlertSentryUnderAttack
end

function Sentry:UpdateAcquireTarget(deltaTime)

    local targetAcquired = nil
    local currentTime = self.timeOfLastUpdate + deltaTime

    // Don't look for new target if we have one (allows teams to gang up on sentries)
    local currentTarget = self:GetTarget() 
    if not currentTarget and (currentTime > (self.timeOfLastTargetAcquisition + Sentry.kTargetCheckTime)) then
    
        targetAcquired = self:SetTarget(self.targetSelector:AcquireTarget())
        self.timeOfLastTargetAcquisition = currentTime
            
    end
    
    return targetAcquired
    
end

function Sentry:UpdateAttackTarget(deltaTime)

    local orderLocation = nil
    local order = self:GetCurrentOrder()
    if order then
        
        orderLocation = order:GetLocation()
    
        local target = self:GetTarget()    
        local attackEntValid = self.targetSelector:ValidateTarget(target)
        local attackLocationValid = (order:GetType() == kTechId.Attack and orderLocation ~= nil)
        attackLocationValid = false
        local currentTime = self.timeOfLastUpdate + deltaTime
   
        if (attackEntValid or attackLocationValid) and (self.timeNextAttack == nil or (currentTime > self.timeNextAttack)) then
        
            local currentAnim = self:GetAnimation()
            local mode = self:GetSentryMode()
            
            if mode == Sentry.kMode.Attacking then
       
                self:FireBullets()
                
                // Random rate of fire so it can't be gamed         
                self.timeNextAttack = currentTime + Sentry.kBaseROF + NetworkRandom() * Sentry.kRandROF
                            
            else
                self.timeNextAttack = currentTime + .1
            end        

        end    
        
    end
   
end

function Sentry:UpdateAttack(deltaTime)

    // If alive and built (map-placed structures don't die when killed)
    local mode = self:GetSentryMode()
    local currentTime = self.timeOfLastUpdate + deltaTime
    
    if self:GetIsFunctioning() then

        // If we have order
        local order = self:GetCurrentOrder()
        if order ~= nil and (order:GetType() == kTechId.SetTarget) then
        
            self:UpdateSetTarget()
                
        else
        
            // Get new attack order if any enemies nearby
            self:UpdateAcquireTarget(deltaTime)
            
            // Maybe fire another bullet at target
            self:UpdateAttackTarget(deltaTime)

            // We may have gotten a new order in acquire target, but ping if not        
            if((self:GetSentryMode() == Sentry.kMode.Scanning) and (self.timeLastScanSound == 0 or (currentTime > self.timeLastScanSound + Sentry.kPingInterval))) then
        
                Shared.PlayWorldSound(nil, Sentry.kSentryScanSoundName, nil, self:GetModelOrigin())
                self.timeLastScanSound = currentTime
            
            end

        end

        self:UpdateTargetState()
  
    end

end

function Sentry:OnResearchComplete(structure, researchId)

    local researchNode = self:GetTeam():GetTechTree():GetTechNode(researchId)
    if structure and (structure:GetId() == self:GetId()) and researchId == kTechId.SentryRefill then
    
        self.ammo = Clamp(self.ammo + Sentry.kAmmoPerRefill, 0, Sentry.kMaxAmmo)
        self:ClearResearch()
        
        return true
        
    else
        Structure.OnResearchComplete(self, structure, researchId)
    end
    
end

function Sentry:FireBullets()

    // Use x-axis of muzzle node, so when the model flinches, it becomes less accurate
    local fireCoords = self:GetAttachPointCoords(Sentry.kMuzzleNode)
    // Need to swap the x and z axis.
    local tempZAxis = fireCoords.zAxis
    fireCoords.zAxis = fireCoords.xAxis
    fireCoords.xAxis = tempZAxis
    
    local startPoint = self:GetAttackOrigin()
    local alertToTrigger = kTechId.None
    
    for bullet = 1, Sentry.kBulletsPerSalvo do

        if self:GetAmmo() > 0 then
        
            // Add some spread to bullets.
            local spreadDirection = CalculateSpread(fireCoords, Sentry.kSpread, math.random)
            
            local endPoint = startPoint + spreadDirection * Sentry.kRange
            
            local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.Bullets, EntityFilterOne(self))
            
            if Server then
                Server.dbgTracer:TraceBullet(self, startPoint, trace)
            end
            
            if (trace.fraction < 1) then
            
                if not GetBlockedByUmbra(trace.entity) then
                
                    if trace.entity and HasMixin(trace.entity, "Live") then
                    
                        local direction = (trace.endPoint - startPoint):GetUnit()
                        
                        trace.entity:TakeDamage(Sentry.kDamagePerBullet, self, self, endPoint, direction)
                    
                    else
                        TriggerHitEffects(self, trace.entity, trace.endPoint, trace.surface)    
                    end
                    
                end
                
            end
            
            self.ammo = Clamp(self.ammo - 1, 0, Sentry.kMaxAmmo)
            alertToTrigger = kTechId.MarineAlertSentryFiring
            
            if self.ammo <= 25 then
                alertToTrigger = kTechId.MarineAlertSentryLowAmmo
            end
            
            bulletsFired = true
        
        end
        
    end
    
    if self:GetAmmo() == 0 then
        // Spin down when we're out of ammo
        self:SetMode(Sentry.kMode.SpinningDown)
        alertToTrigger = kTechId.MarineAlertSentryNoAmmo        
    end

    if bulletsFired then    
        self:CreateAttachedEffect(Sentry.kFireEffect, Sentry.kMuzzleNode)
        self:CreateAttachedEffect(Sentry.kBarrelSmokeEffect, Sentry.kMuzzleNode)
    end
    
    if Server and alertToTrigger ~= kTechId.None then
        self:GetTeam():TriggerAlert(alertToTrigger, self)    
    end
    
end

// Update rotation state when setting target
function Sentry:UpdateSetTarget()

    if self:GetSentryMode() == Sentry.kMode.SettingTarget then
    
        local currentOrder = self:GetCurrentOrder()
        if currentOrder ~= nil then
        
            local target = self:GetTarget()
            
            local vecToTarget = nil
            if currentOrder:GetLocation() ~= nil then
                vecToTarget = currentOrder:GetLocation() - self:GetModelOrigin()
            elseif target ~= nil then
                vecToTarget =  target:GetModelOrigin() - self:GetModelOrigin()
            else
                Print("Sentry:UpdateSetTarget(): sentry has attack order without valid entity id or location.")
                self:CompletedCurrentOrder()
                return 
            end            
            
            // Move sentry to face target point
            local currentYaw = self:GetAngles().yaw
            local desiredYaw = GetYawFromVector(vecToTarget)
            local newYaw = InterpolateAngle(currentYaw, desiredYaw, Sentry.kReorientSpeed)

            local angles = Angles(self:GetAngles())
            angles.yaw = newYaw
            self:SetAngles(angles)
                        
            // Check if we're close enough to final orientation
            if(math.abs(newYaw - desiredYaw) == 0) then

                self:CompletedCurrentOrder()
                
                // So barrel doesn't "snap" after power-up
                self.barrelYawDegrees = 0
                
                self:SetMode(Sentry.kMode.PoweringUp)
                
            end
            
        else
        
            // Deleted order while setting target
            self:SetDesiredMode(Sentry.kMode.PoweringUp)
            
        end 
       
    end
    
end

function Sentry:OnOrderChanged()

    if not self:GetHasOrder() then
        self:SetDesiredMode(Sentry.kMode.Scanning)
    else
    
        local orderType = self:GetCurrentOrder():GetType()
        if orderType == kTechId.Attack then
            self:SetDesiredMode(Sentry.kMode.Attacking)
        elseif orderType == kTechId.Stop then
            self:SetDesiredMode(Sentry.kMode.Scanning)
        elseif orderType == kTechId.SetTarget then
            self:SetDesiredMode(Sentry.kMode.SettingTarget)
        end
        
    end
    
end

function Sentry:UpdateTargetState()

    local order = self:GetCurrentOrder()

    // Update hasTarget so model swings towards target entity or location
    local hasTarget = false
    
    if order ~= nil then
    
        // We have a target if we attacking an entity that's still valid or attacking ground
        local orderParam = order:GetParam()
        hasTarget = (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) and 
                    ((orderParam ~= Entity.invalidId and self.targetSelector:ValidateTarget(Shared.GetEntity(orderParam)) or (orderParam == Entity.invalidId)) )
    end
    
    if hasTarget then

        local target = self:GetTarget()
        if target ~= nil then
            self.targetDirection = GetNormalizedVector(target:GetEngagementPoint() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
        else
            self.targetDirection = GetNormalizedVector(self:GetCurrentOrder():GetLocation() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
        end

    else
    
        if (self:GetSentryMode() == Sentry.kMode.Attacking) then
        
            self:CompletedCurrentOrder()

            // Don't choose new target right away, to make sure multiple attacks can overwhelm sentry
            self.timeOfLastTargetAcquisition = Shared.GetTime() + Sentry.kTargetReacquireTime
            
        end
        
        self.targetDirection = nil
        
    end
    
end

function Sentry:GetDamagedAlertId()
    return kTechId.MarineAlertSentryUnderAttack
end