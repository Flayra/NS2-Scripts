// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Pistol.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/TracerMixin.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'Pistol' (ClipWeapon)

Pistol.kMapName = "pistol"

Pistol.kModelName = PrecacheAsset("models/marine/pistol/pistol.model")
Pistol.kViewModelName = PrecacheAsset("models/marine/pistol/pistol_view.model")

Pistol.kMuzzleFlashEffect = PrecacheAsset("cinematics/marine/pistol/muzzle_flash.cinematic")
Pistol.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/pistol/barrel_smoke.cinematic")
Pistol.kShellEffect = PrecacheAsset("cinematics/marine/pistol/shell.cinematic")

Pistol.kMuzzleNode = "fxnode_pistolmuzzle"
Pistol.kCasingNode = "fxnode_pistolcasing"

Pistol.kAnimRunIdleTable = {{1, "run"}, {.5, "run2"}}

Pistol.kClipSize = 10
Pistol.kDamage = kPistolDamage
Pistol.kAltDamage = kPistolAltDamage
Pistol.kRange = 200
Pistol.kFireDelay = kPistolFireDelay
Pistol.kAltFireDelay = kPistolAltFireDelay
Pistol.kSpread = ClipWeapon.kCone1Degrees
Pistol.kAltSpread = ClipWeapon.kCone0Degrees    // From NS1

Pistol.networkVars =
{
    altMode             = "boolean",
    emptyPoseParam      = "compensated float"
}

PrepareClassForMixin(Pistol, TracerMixin)

function Pistol:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, TracerMixin, { kTracerPercentage = 0.3 })
    InitMixin(self, PickupableWeaponMixin)

end

function Pistol:OnInit()

    ClipWeapon.OnInit(self)
    self.altMode = false
    self.emptyPoseParam = 0
    
end

function Pistol:GetRange()
    return Pistol.kRange
end

function Pistol:GetDeathIconIndex()
    return kDeathMessageIcon.Pistol
end

function Pistol:GetViewModelName()
    return Pistol.kViewModelName
end

// When in alt-fire mode, keep very accurate
function Pistol:GetInaccuracyScalar()
    return ConditionalValue(self.altMode, .5, 1)
end

function Pistol:GetHUDSlot()
    return kSecondaryWeaponSlot
end

function Pistol:GetPrimaryAttackRequiresPress()
    return true
end

function Pistol:CreatePrimaryAttackEffect(player)
end

function Pistol:GetWeight()
    // From NS1 
    return .04 + ((self:GetAmmo() + self:GetClip()) / self:GetClipSize()) * 0.01
end

function Pistol:GetClipSize()
    return Pistol.kClipSize
end

function Pistol:GetSpread()
    return ConditionalValue(self.altMode, Pistol.kAltSpread, Pistol.kSpread)
end

function Pistol:GetBulletDamage(target, endPoint)
    return ConditionalValue(self.altMode, Pistol.kAltDamage, Pistol.kDamage)
end

function Pistol:GetPrimaryAttackDelay()
    return ConditionalValue(self.altMode, Pistol.kAltFireDelay, Pistol.kFireDelay)
end

function Pistol:OnSecondaryAttack(player)

    ClipWeapon.OnSecondaryAttack(self, player)
    
    self:CancelReload(player)
    
    player:SetActivityEnd(player:GetViewAnimationLength())
    
    self.altMode = not self.altMode
    
end

function Pistol:GetBlendTime()
    return 0
end

function Pistol:GetSwingAmount()
    return 15
end

function Pistol:UpdateViewModelPoseParameters(viewModel, input)
    
    if self.clip ~= 0 then
        self.emptyPoseParam = 0
    else
        self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, 1, input.time*5), 0, 1)
    end
    viewModel:SetPoseParam("empty", self.emptyPoseParam)
    
end

function Pistol:GetEffectParams(tableParams)

    ClipWeapon.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterInAltMode] = self.altMode
    
end

Shared.LinkClassToMap("Pistol", Pistol.kMapName, Pistol.networkVars)