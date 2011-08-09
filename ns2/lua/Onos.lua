// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Hold shift to start galloping and have view model shake and him breathe heavily. If he hits
// any players, they fly back a bit and don't stop him from moving. If he hits players during
// this time, they take damage.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/Gore.lua")
Script.Load("lua/Weapons/Alien/BoneShield.lua")
Script.Load("lua/Weapons/Alien/Stomp.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

class 'Onos' (Alien)

Onos.kMapName = "onos"
Onos.kModelName = PrecacheAsset("models/alien/onos/onos.model")
Onos.kViewModelName = PrecacheAsset("models/alien/onos/onos_view.model")

Onos.kFootstepSound = PrecacheAsset("sound/ns2.fev/alien/onos/onos_step")
Onos.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/onos/wound")
Onos.kGoreSound = PrecacheAsset("sound/ns2.fev/alien/onos/gore")

Onos.kChargeEffect = PrecacheAsset("cinematics/alien/onos/charge.cinematic")
Onos.kChargeHitEffect = PrecacheAsset("cinematics/alien/onos/charge_hit.cinematic")
Onos.kJumpForce = 20
Onos.kJumpVerticalVelocity = 8

Onos.kJumpRepeatTime = .25
Onos.kViewOffsetHeight = 2.2
Onos.XExtents = 1
Onos.YExtents = 1.3
Onos.ZExtents = .4
Onos.kFov = 95
Onos.kMass = 453 // Half a ton
Onos.kJumpHeight = 1.5
Onos.kMinChargeDamage = kChargeMinDamage
Onos.kMaxChargeDamage = kChargeMaxDamage
Onos.kChargeKnockbackForce = 4

Onos.kStartChargeMaxSpeed = 5.5
Onos.kChargeMaxSpeed = 9
Onos.kMaxWalkSpeed = 5
Onos.kLeapMaxSpeed = 25

Onos.kHealth = kOnosHealth
Onos.kArmor = kOnosArmor
Onos.kChargeEnergyCost = .1

Onos.kChargeTime = 2
Onos.kUnchargeTime = .5

if(Server) then
    Script.Load("lua/Onos_Server.lua")
else
    Script.Load("lua/Onos_Client.lua")
end

Onos.networkVars = 
{
    charging                        = "boolean",
    desiredCharging                 = "boolean",
    chargingScalar                  = "float",  
    timeOfChargeChange              = "float",  
    justJumped                      = "boolean"    
}

PrepareClassForMixin(Onos, GroundMoveMixin)
PrepareClassForMixin(Onos, CameraHolderMixin)

function Onos:OnInit()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Onos.kFov })
    
    Alien.OnInit(self)
    
    self.charging = false
    self.desiredCharging = false
    self.chargingScalar = 0
    self.timeOfChargeChange = 0
    self.justJumped = false
    
end

function Onos:GetBaseArmor()
    return Onos.kArmor
end

function Onos:GetArmorFullyUpgradedAmount()
    return kOnosArmorFullyUpgradedAmount
end

function Onos:GetViewModelName()
    return Onos.kViewModelName
end

function Onos:GetMaxViewOffsetHeight()
    return Onos.kViewOffsetHeight
end

function Onos:GetHasSpecialAbility()
    return true
end

function Onos:GetFrictionForce(input, velocity)

    local scalar = 1.5
    
    if self.mode == kPlayerMode.OnosStartJump then
        scalar = 12
    end
    
    return Vector(-velocity.x, 0, -velocity.z) * scalar       
    
end

function Onos:GetIsCharging()
    return self.charging and self.chargingScalar > .5
end

function Onos:GetMovePhysicsMask()
    return ConditionalValue(self:GetIsCharging(), PhysicsMask.Charge, Alien.GetMovePhysicsMask(self))
end

// Called from Onos:PerformMovement(), but also if other players run into us while we're charging.
function Onos:OnCapsuleTraceHit(entity)

    // Players will generally be hit more than once when charged through (easier than tracking last time hit)
    if self:GetIsCharging() and entity ~= nil and entity:isa("Player") then
    
        local flyDirection = GetNormalizedVector(entity:GetModelOrigin() - self:GetModelOrigin())
        local flyVelocity = flyDirection * self:GetVelocity():GetLength() * (.5 + self.chargingScalar*.5)
        entity:SetVelocity(entity:GetVelocity() + flyVelocity)
        
        // Play particle effect showing that player was charged
        Shared.CreateEffect(nil, Onos.kChargeHitEffect, entity) 

        // If enemy, do damage as well each (will happen more than once)
        if Server and GetEnemyTeamNumber(self:GetTeamNumber()) == entity:GetTeamNumber() then
        
            local damage = Onos.kMinChargeDamage + (Onos.kMaxChargeDamage - Onos.kMinChargeDamage) * self.chargingScalar
            entity:TakeDamage(damage, self, self, entity:GetModelOrigin(), flyDirection)
            
            // Send player flying back
            local velocity = GetNormalizedVector(entity:GetEyePos() - self:GetOrigin()) * Onos.kChargeKnockbackForce
            
            entity:Knockback(velocity)
                    
        end
            
    end
    
end

/**
 * Allows Onos to charge through players, but still detecting collisions with them.
 */
function Onos:PerformMovement(offset, maxTraces, velocity)

    // If we're charging, we pass through players in Player:PerformMovement(), so perform collision trace check first 
    // so we can hit them and do damage. Only hits the first player for simplicity.
    if self:GetIsCharging() and self.controller then

        self:UpdateControllerFromEntity()

        local trace = self.controller:Trace(offset, PhysicsMask.Movement)

        if (trace.fraction < 1) and trace.entity ~= nil and trace.entity:isa("Player") then
    
            trace.entity:OnCapsuleTraceHit(self)
            self:OnCapsuleTraceHit(trace.entity)

        end
            
    end
    
    // Now perform actual movement normally
    return Alien.PerformMovement(self, offset, maxTraces, velocity)
    
end

function Onos:UpdateChargingState(input)

    local velocity = self:GetVelocity()
    local speed = velocity:GetLength()
    
    // Allow small little falls to not break our charge (stairs)    
    self.desiredCharging = (bit.band(input.commands, Move.MovementModifier) ~= 0) and (speed > 1) and not self.crouching and (self.timeLastOnGround ~= nil and Shared.GetTime() < self.timeLastOnGround + .4)
    
    if input.move.z < -kEpsilon then
    
        self.desiredCharging = false
        
    else
    
        // Only allow charging if we're pressing forward and moving in that direction
        local normMoveDirection = GetNormalizedVectorXZ(self:GetViewCoords():TransformVector( input.move ) )
        local normVelocity = GetNormalizedVectorXZ( velocity )
        local viewFacing = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)

        if normVelocity:DotProduct(normMoveDirection) < .6 or normMoveDirection:DotProduct(viewFacing) < .5 then
            self.desiredCharging = false
        end
        
    end
    
    if(self.desiredCharging ~= self.charging and self:GetCanNewActivityStart()) then

        local weapon = self:GetActiveWeapon()
        
        if(weapon ~= nil) then       
 
            self.timeOfChargeChange = Shared.GetTime()
            
            self.charging = self.desiredCharging
            
        end
    
    end
    
    // Update charging scalar
    if self.timeOfChargeChange ~= nil then
    
        if self.desiredCharging then
            self.chargingScalar = Clamp((Shared.GetTime() - self.timeOfChargeChange)/Onos.kChargeTime, 0, 1)
        else
            self.chargingScalar = 1 - Clamp((Shared.GetTime() - self.timeOfChargeChange)/Onos.kUnchargeTime, 0, 1)
        end
        
    else
        self.chargingScalar = 0
    end

end

function Onos:HandleButtons(input)

    PROFILE("Onos:HandleButtons")
    
    // They let go of jump while charging it up
    if(bit.band(input.commands, Move.Jump) == 0) and self.jumpHandled and self:GetCanJump() then
    
        self.justJumped = true
        
    end

    if(not self.charging) then
    
        Alien.HandleButtons(self, input)
        
    end
    
    self:UpdateChargingState(input)
    
end

// For special ability, return an array of energy, energy cost, tex x offset, tex y offset, 
// visibility (boolean), command name
function Onos:GetSpecialAbilityInterfaceData()

    local vis = self:GetInactiveVisible() or (self:GetEnergy() ~= Ability.kMaxEnergy)

    return { self:GetEnergy()/Ability.kMaxEnergy, Onos.kChargeEnergyCost/Ability.kMaxEnergy, 0, kAbilityOffset.Charge, vis, GetDescForMove(Move.MovementModifier) }
    
end

function Onos:SetCrouchState(newCrouchState)
    self.crouching = newCrouchState
end

function Onos:GetMaxSpeed()

    local success, speed = self:GetCamouflageMaxSpeed(self.movementModiferState)
    if success then
        return speed
    end

    if self:GetIsOnGround() then
    
        local maxSpeed = ConditionalValue(self.charging, Onos.kStartChargeMaxSpeed + (Onos.kChargeMaxSpeed - Onos.kStartChargeMaxSpeed)*self.chargingScalar, Onos.kMaxWalkSpeed)

        // Take into account crouching
        return ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar ) * maxSpeed * self:GetSlowSpeedModifier()
        
    end
    
    return Onos.kLeapMaxSpeed * self:GetSlowSpeedModifier()
    
end

// Half a ton
function Onos:GetMass()
    return Onos.kMass
end

function Onos:GetLeftFootstepSound(surface)
    return Onos.kFootstepSound
end

function Onos:GetRightFootstepSound(surface)
    return Onos.kFootstepSound
end

function Onos:GetJumpHeight()
    return Onos.kJumpHeight
end

// If we jump, make sure to set self.timeOfLastJump to the current time
function Onos:HandleJump(input, velocity)

    if self:GetCanJump() then
    
        self:SetAnimAndMode("stomp", kPlayerMode.OnosStartJump)
        
        self:PlaySound("onos_step")
        
        self.timeOfLastJump = Shared.GetTime()
        
    end

end

function Onos:ProcessEndMode()

    if self.mode ~= kPlayerMode.OnosStartJump then
        return Alien.ProcessEndMode(self)
    end
    
    return true
    
end

function Onos:ModifyVelocity(input, velocity)

    Alien.ModifyVelocity(self, input, velocity)

    if self.justJumped then
           
        local viewDir = self:GetViewAngles():GetCoords().zAxis
        local newVelocity = velocity + /*Vector(0, 1, 0) * Onos.kJumpVerticalVelocity +*/ viewDir * Onos.kJumpForce
        
        //Print("viewDir: %s, newVelocity: %s", viewDir:tostring(), newVelocity:tostring())
        
        VectorCopy(newVelocity, velocity)
        
        self.justJumped = false
        
        // Play roar
        self:PlaySound("wound_serious")
        
        self:SetOverlayAnimation(self:GetCustomAnimationName(Player.kAnimStartJump))
        
        self.mode = kPlayerMode.Default
        
        self.modeTime = -1
        
    end
    
end

function Onos:GetBreathingHeight()
    return .05
end

Shared.LinkClassToMap( "Onos", Onos.kMapName, Onos.networkVars )
