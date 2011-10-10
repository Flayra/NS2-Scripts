// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Gore attack should send players flying (doesn't have to be ragdoll). Stomp will disrupt
// structures in range. 
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
Onos.kLocalIdleSound = PrecacheAsset("sound/ns2.fev/alien/onos/idle")

Onos.kJumpForce = 20
Onos.kJumpVerticalVelocity = 8

Onos.kJumpRepeatTime = .25
Onos.kViewOffsetHeight = 2.5
Onos.XExtents = 1
Onos.YExtents = 1.3
Onos.ZExtents = .4
Onos.kFov = 95
Onos.kMass = 453 // Half a ton
Onos.kJumpHeight = 1.5
Onos.kMinChargeDamage = kChargeMinDamage
Onos.kMaxChargeDamage = kChargeMaxDamage
Onos.kChargeKnockbackForce = 4

Onos.kMaxWalkSpeed = 5

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

Onos.networkVars = {}

PrepareClassForMixin(Onos, GroundMoveMixin)
PrepareClassForMixin(Onos, CameraHolderMixin)

function Onos:OnInit()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Onos.kFov })
    
    Alien.OnInit(self)
    
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

function Onos:GetSpecialAbilityInterfaceData()

    local vis = self:GetInactiveVisible() or (self:GetEnergy() ~= Ability.kMaxEnergy)

    return { self:GetEnergy()/Ability.kMaxEnergy, Onos.kChargeEnergyCost/Ability.kMaxEnergy, 0, kAbilityOffset.Charge, vis, GetDescForMove(Move.MovementModifier) }
    
end

function Onos:GetMaxSpeed()

    local success, speed = self:GetCamouflageMaxSpeed(self.movementModiferState)
    if success then
        return speed
    end

    // Take into account crouching
    return ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar ) * Onos.kMaxWalkSpeed * self:GetSlowSpeedModifier()

end

// Half a ton
function Onos:GetMass()
    return Onos.kMass
end

function Onos:GetJumpHeight()
    return Onos.kJumpHeight
end

function Onos:OnTag(tagName)

    // Play footstep when foot hits the ground
    if Client and (string.lower(tagName) == "step" and self:GetPlayFootsteps()) then
    
        Print("Footstep tag hit on onos client")
        self:PlayFootstepShake()
        
    end
    
    Alien.OnTag(self, tagName)
    
end

Shared.LinkClassToMap( "Onos", Onos.kMapName, Onos.networkVars )
