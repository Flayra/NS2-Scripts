// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function LiveScriptActor:CopyDataFrom(player)

    self.gameEffectsFlags = player.gameEffectsFlags
    
    table.copy(player.gameEffects, self.gameEffects)
    
    self.timeOfLastDamage = player.timeOfLastDamage
    
    self.furyLevel = player.furyLevel
    
    self.activityEnd = player.activityEnd
    
    self.pathingEnabled = player.pathingEnabled
    
end

function LiveScriptActor:SetPathingEnabled(state)
    self.pathingEnabled = state
end

function LiveScriptActor:Upgrade(newTechId)

    if self:GetTechId() ~= newTechId then

        // Preserve health and armor scalars but potentially change maxHealth and maxArmor
        local healthScalar = self:GetHealthScalar()
        local armorScalar = self:GetArmorScalar()
        
        self:SetTechId(newTechId)
        
        self:SetMaxHealth(LookupTechData(newTechId, kTechDataMaxHealth, self:GetMaxHealth()))
        self:SetMaxArmor(LookupTechData(newTechId, kTechDataMaxArmor, self:GetMaxArmor()))
        
        self:SetHealth(healthScalar * self:GetMaxHealth())
        self:SetArmor(armorScalar * self:GetMaxArmor())
        
        return true
        
    end
    
    return false
    
end

function LiveScriptActor:UpdateJustKilled()

    if self.justKilled then
    
        // Clear current animation so we know if it was set in TriggerEffects
        self:SetAnimation("", true)
        
        self:TriggerEffects("death")
        
        // Destroy immediately if death animation or ragdoll wasn't triggered (used queued because we're in OnProcessMove)
        local anim = self:GetAnimation()
        if (self:GetPhysicsGroup() == PhysicsGroup.RagdollGroup) or (anim ~= nil and anim ~= "") then
        
            // Set default time to destroy so it's impossible to have things lying around 
            self.timeToDestroy = Shared.GetTime() + 4
            self:SetNextThink(.1)
            
        else
            self:SafeDestroy()                    
        end
        
        self.justKilled = nil

    end
    
end

function LiveScriptActor:GetDamageImpulse(damage, doer, point)
    if damage and doer and point then
        return GetNormalizedVector(doer:GetOrigin() - point) * (damage / 40) * .01
    end
    return nil
end

function LiveScriptActor:OnTakeDamage(damage, attacker, doer, point)

    // Play audio/visual effects when taking damage    
    local damageType = kDamageType.Normal
    if doer then
        damageType = doer:GetDamageType()
    end
    
    // Apply directed impulse to physically simulated objects, according to amount of damage
    if (self.physicsModel ~= nil and self.physicsType == Actor.PhysicsType.Dynamic) then    
        local damageImpulse = self:GetDamageImpulse(damage, doer, point)
        if damageImpulse then
            self.physicsModel:AddImpulse(point, damageImpulse)
        end
    end
    
end

function LiveScriptActor:GetTimeOfLastDamage()
    return self.timeOfLastDamage
end

function LiveScriptActor:SetFuryLevel(level)
    self.furyLevel = level
end

function LiveScriptActor:Reset()

    ScriptActor.Reset(self)
    self:ResetUpgrades()
    self:ClearOrders()
    
end

function LiveScriptActor:OnKill(damage, attacker, doer, point, direction)

    // Give points to killer
    local pointOwner = attacker
    
    // If the pointOwner is not a player, award it's points to it's owner.
    if pointOwner ~= nil and not pointOwner:isa("Player") then
        pointOwner = pointOwner:GetOwner()
    end
    if(pointOwner ~= nil and pointOwner:isa("Player") and pointOwner:GetTeamNumber() ~= self:GetTeamNumber()) then
        pointOwner:AddScore(self:GetPointValue())
    end

    self:SetIsAlive(false)
    
    if point then
        self.deathImpulse = self:GetDamageImpulse(damage, doer, point)
        self.deathPoint = Vector(point)
    end

    self:ResetUpgrades()
    self:ClearOrders()

    ScriptActor.OnKill(self, damage, attacker, doer, point, direction)

end

function LiveScriptActor:ResetUpgrades()
    self.upgrade1 = kTechId.None
    self.upgrade2 = kTechId.None
    self.upgrade3 = kTechId.None
    self.upgrade4 = kTechId.None
end

function LiveScriptActor:SetRagdoll(deathTime)

    if self:GetPhysicsGroup() ~= PhysicsGroup.RagdollGroup then

        self:SetPhysicsType(Actor.PhysicsType.Dynamic)
        
        self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
        
        // Apply landing blow death impulse to ragdoll (but only if we didn't play death animation)
        if self.deathImpulse and self.deathPoint and self.physicsModel and self.physicsType == Actor.PhysicsType.Dynamic then
        
            self.physicsModel:AddImpulse(self.deathPoint, self.deathImpulse)
            self.deathImpulse = nil
            
        end
        
        if deathTime then

            self.timeToDestroy = Shared.GetTime() + deathTime
            
            self:SetNextThink(.1)    
            
        end
        
    end
    
end

function LiveScriptActor:OnThink()

    ScriptActor.OnThink(self)
    
    if self.timeToDestroy and (Shared.GetTime() > self.timeToDestroy) then
    
        self:SafeDestroy()

    else
        self:SetNextThink(.1)
    end
    
end

function LiveScriptActor:SafeDestroy()

    if bit.bor(self.gameEffectsFlags, kGameEffect.OnFire) then
        self:TriggerEffects("fire_stop")
    end

    if(self:GetIsMapEntity()) then
    
        self:SetIsAlive(false)
        self:SetIsVisible(false)
        self:SetNextThink(-1)
        self:SetPhysicsType(Actor.PhysicsType.None)
        
    else
    
        DestroyEntity(self)
        
    end

end

function LiveScriptActor:Kill(attacker, doer, point, direction)
    self:TakeDamage(1000, attacker, doer, nil, nil)
end

// If false, then MoveToTarget() projects entity down to floor
function LiveScriptActor:GetIsFlying()
    return false
end

/**
 * Return the passed in position casted down to the ground.
 */
function LiveScriptActor:GetGroundAt(position, physicsGroupMask)

    local topOffset      = self:GetExtents().y
    local startPosition = position + Vector(0, topOffset, 0)
    local endPosition   = position - Vector(0, 1000, 0)
    
    local trace = Shared.TraceRay(startPosition, endPosition, physicsGroupMask, EntityFilterOne(self))
    
    // If we didn't hit anything, then use our existing position. This
    // prevents objects from constantly moving downward if they get outside
    // of the bounds of the map.
    if trace.fraction ~= 1 then
        return trace.endPoint
    else
        return position
    end

end

function LiveScriptActor:GetHoverAt(position)

    local ground = self:GetGroundAt(position, PhysicsMask.AIMovement)
    local resultY = position.y
    // if we have a hover height, use it to find our minimum height above ground, otherwise use zero
    
    local minHeightAboveGround = 0
    if self.GetHoverHeight then      
      minHeightAboveGround = self:GetHoverHeight()
    end

    local heightAboveGround = resultY  - ground.y
    
    // always snap "up", snap "down" only if not flying
    if heightAboveGround <= minHeightAboveGround or not self:GetIsFlying() then
        resultY = resultY + minHeightAboveGround - heightAboveGround              
    end        

    if resultY ~= position.y then
        return Vector(position.x, resultY, position.z)
    end

    return position

end

function LiveScriptActor:GetWaypointGroupName()
    return ConditionalValue(self:GetIsFlying(), kAirWaypointsGroup, kDefaultWaypointGroup)
end

function LiveScriptActor:MoveToTarget(physicsGroupMask, location, movespeed, time)
    PROFILE("LiveScriptActor:MoveToTarget")
    
    local movement = nil
    local newLocation = self:GetOrigin()
    local now = Shared.GetTime()    
    local hasReachedLocation = false//self:IsTargetReached(location, 0.01, true)
    
    local direction = (location - self:GetOrigin()):GetUnit();            
    if self.pathingEnabled then
        if not (hasReachedLocation) then            
            if not self:IsPathValid(self:GetOrigin(), location) then                
                if not (self:BuildPath(self:GetOrigin(), location)) then                
                  return
                end
            end
            
            if (self:GetCurrentPathPoint() ~= nil and self:GetNumPoints() >= 1) then                 
                self:RestartPathing(now)
                local point = self:GetNextPoint(time, movespeed)
                if (point ~= nil) then
                    newLocation = point
                    direction = self:GetPathDirection()
                    SetAnglesFromVector(self, direction)
                end                
            end                                
        end
    end
            
    if self:GetIsFlying() then
      newLocation = self:GetHoverAt(newLocation)
    end
    
    self:SetOrigin(newLocation)
    if (self.controller and not self:GetIsFlying()) then
      self:UpdateControllerFromEntity()
      self:PerformMovement(Vector(0, -1000, 0), 1)      
    end
    
end

function LiveScriptActor:PerformAction(techNode, position)

    if(techNode:GetTechId() == kTechId.Stop) then
        self:ClearOrders()
        return true
    end
    
    return ScriptActor.PerformAction(self, techNode, position)
    
end

function LiveScriptActor:OnWeld(entity, elapsedTime)
end

// Overrideable by children. Called on server only.
function LiveScriptActor:OnGameEffectMaskChanged(effect, state)
    
    if effect == kGameEffect.OnFire and state then
        self:TriggerEffects("fire_start")
    elseif effect == kGameEffect.OnFire and not state then
        self:TriggerEffects("fire_stop")
    end
    
end

function LiveScriptActor:GetMeleeAttackDamage()
    return 5
end

function LiveScriptActor:GetMeleeAttackInterval()
    return .6
end

function LiveScriptActor:GetMeleeAttackOrigin()
    return self:GetOrigin()
end

function LiveScriptActor:MeleeAttack(target, time)

    local meleeAttackInterval = self:AdjustFuryFireDelay(self:GetMeleeAttackInterval())
   
    if(Shared.GetTime() > (self.timeOfLastAttack + meleeAttackInterval)) then
    
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
            
        self.timeOfLastAttack = Shared.GetTime()
        
    end
        
end

// Get target of attack order, if any
function LiveScriptActor:GetTarget()
    local target = nil

    local order = self:GetCurrentOrder()
    if order ~= nil and (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) then
        target = Shared.GetEntity(order:GetParam())
    end    
    
    return target
end

