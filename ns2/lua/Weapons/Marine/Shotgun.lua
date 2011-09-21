// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Shotgun.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Balance.lua")
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'Shotgun' (ClipWeapon)

Shotgun.kMapName = "shotgun"

local kReloadPhase = enum( {'None', 'Start', 'LoadShell', 'End'} )

Shotgun.networkVars =
{
    reloadPhase         = string.format("integer (1 to %d)", kReloadPhase.End),
    reloadPhaseEnd      = "float",
    emptyPoseParam      = "compensated float"
}

Shotgun.kModelName = PrecacheAsset("models/marine/shotgun/shotgun.model")
Shotgun.kViewModelName = PrecacheAsset("models/marine/shotgun/shotgun_view.model")

Shotgun.kClipSize = kShotgunClipSize
// Do max damage when within max damage range
Shotgun.kMaxDamage = kShotgunMaxDamage
Shotgun.kMinDamage = kShotgunMinDamage
Shotgun.kPrimaryRange = kShotgunMinDamageRange
Shotgun.kPrimaryMaxDamageRange = kShotgunMaxDamageRange
Shotgun.kSecondaryRange = 10
Shotgun.kFireDelay = kShotgunFireDelay
Shotgun.kSecondaryFireDelay = 0.5

function Shotgun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)

end

function Shotgun:GetViewModelName()
    return Shotgun.kViewModelName
end

function Shotgun:GetDeathIconIndex()
    return kDeathMessageIcon.Shotgun
end

function Shotgun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Shotgun:GetClipSize()
    return Shotgun.kClipSize
end

function Shotgun:GetBulletsPerShot()
    return kShotgunBulletsPerShot
end

function Shotgun:GetSpread()

    // NS1 was 20 degrees for half the shots and 20 degrees plus 7 degrees for half the shots
    if NetworkRandom(string.format("%s:GetSpread():", self:GetClassName())) < .5 then
        return ClipWeapon.kCone20Degrees     
    else
        return ClipWeapon.kCone20Degrees + ClipWeapon.kCone7Degrees
    end
    
end

function Shotgun:GetRange()
    return Shotgun.kPrimaryRange
end

function Shotgun:GetBulletDamageForRange(distance)

    local damage = Shotgun.kMaxDamage
    if distance > Shotgun.kPrimaryMaxDamageRange then
    
        local distanceFactor = (distance - Shotgun.kPrimaryMaxDamageRange) / (Shotgun.kPrimaryRange - Shotgun.kPrimaryMaxDamageRange)
        local dmgScalar = 1 - Clamp(distanceFactor, 0, 1) 
        damage = Shotgun.kMinDamage + dmgScalar * (Shotgun.kMaxDamage - Shotgun.kMinDamage)
        
    end
    
    return damage

end

// Only play weapon effects every other bullet to avoid sonic overload
function Shotgun:GetRicochetEffectFrequency()
    return 2
end

function Shotgun:GetBulletDamage(target, endPoint)

    if target ~= nil then
    
        local distance = (endPoint - self:GetParent():GetOrigin()):GetLength()
        return self:GetBulletDamageForRange(distance)
        
    else
        Print("Shotgun:GetBulletDamage(target): target is nil, returning max damage.")
    end
    
    return Shotgun.kMaxDamage
    
end

function Shotgun:GetPrimaryAttackDelay()
    return Shotgun.kFireDelay
end

function Shotgun:GetSecondaryAttackDelay()
    return Shotgun.kSecondaryFireDelay
end

function Shotgun:GetWeight()
    // From NS1 
    return .08 + ((self:GetAmmo() + self:GetClip()) / self:GetClipSize()) * 0.03
end

function Shotgun:EnterReloadPhase(player, phase)

    local blockActivity = true

    if phase == kReloadPhase.None then
        blockActivity = false
    elseif phase == kReloadPhase.Start then
        self:TriggerEffects("shotgun_reload_start")
        blockActivity = false
    elseif phase == kReloadPhase.LoadShell then

        self:TriggerEffects("shotgun_reload_shell")
    
        // We can cancel reloading of every bullet past the first            
        blockActivity = false
        
    elseif phase == kReloadPhase.End then
        self:TriggerEffects("shotgun_reload_end")
    end
    
    self.reloadPhase = phase
    
    local viewAnimationLength = player:GetViewAnimationLength()
    self.reloadPhaseEnd = Shared.GetTime() + viewAnimationLength
    
    if blockActivity then
        player:SetActivityEnd(viewAnimationLength)
    end

end

function Shotgun:GetCanIdle()

    // Allow idling when not reloading or when finishing reloading if the reload is done.
    return ((self.reloadPhase == kReloadPhase.None) or
            (self.reloadPhase == kReloadPhase.End and
             (self.reloadPhaseEnd == nil or Shared.GetTime() >= self.reloadPhaseEnd)))
           and ClipWeapon.GetCanIdle(self)

end

function Shotgun:OnPrimaryAttack(player)
    
    // Only allow changing reload phase if we aren't reloading or are loading a shell. The other phases block.
    if self.reloadPhase == kReloadPhase.None or self.reloadPhase == kReloadPhase.LoadShell then
        self:EnterReloadPhase(player, kReloadPhase.None)
    end
    
    ClipWeapon.OnPrimaryAttack(self, player)
    
end

// Load bullet if we can. Returns true if there are still more to reload.
function Shotgun:LoadBullet(player)

    if(self.ammo > 0) and (self.clip < self:GetClipSize()) then
    
        self.clip = self.clip + 1
        self.ammo = self.ammo - 1
                        
    end
    
    return (self.ammo > 0) and (self.clip < self:GetClipSize())
    
end

function Shotgun:OnProcessMove(player, input)
    
    // We're ending a phase
    if (self.reloadPhase ~= kReloadPhase.None and Shared.GetTime() >= self.reloadPhaseEnd) then
    
        // We just finished the start bullet load phase (also gives one shell), or the continues bullet load
        if (self.reloadPhase == kReloadPhase.Start or self.reloadPhase == kReloadPhase.LoadShell) then
        
            // Give back one bullet because that's part of the anim
            if self:LoadBullet(player) then
            
                // Load another
                self:EnterReloadPhase(player, kReloadPhase.LoadShell)
                
            else
            
                // Out of ammo or clip full
                self:EnterReloadPhase(player, kReloadPhase.End)
                
            end
            
        else
        
            self:EnterReloadPhase(player, kReloadPhase.None)
            
        end

    end
    
    self:UpdateAccuracy(player, input)
    
    // Don't call into ClipWeapon because we're overriding reload
    Weapon.OnProcessMove(self, player, input)

end

function Shotgun:OnReload(player)

    if (self.ammo > 0 and self.clip < self:GetClipSize() and self.reloadPhase == kReloadPhase.None) then
        
        // Play the reload sequence and don't let it be interrupted until it finishes playing.
        self:EnterReloadPhase(player, kReloadPhase.Start)
        
    end
    
end

function Shotgun:CancelReload(player)

    self:EnterReloadPhase(player, kReloadPhase.None)
    self.reloadPhaseEnd = 0
    
end

function Shotgun:OnHolster(player)

    self:EnterReloadPhase(player, kReloadPhase.None)
    self.reloadPhaseEnd = 0
    ClipWeapon.OnHolster(self, player)
    
end

function Shotgun:OnInit()

    self.reloadPhase = kReloadPhase.None
    self.reloadPhaseEnd = 0
    self.emptyPoseParam = 0
    
    ClipWeapon.OnInit(self)
    
end

function Shotgun:UpdateViewModelPoseParameters(viewModel, input)
    self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, ConditionalValue(self.clip == 0, 1, 0), input.time*1), 0, 1)
    viewModel:SetPoseParam("empty", self.emptyPoseParam)
end

Shared.LinkClassToMap("Shotgun", Shotgun.kMapName, Shotgun.networkVars)