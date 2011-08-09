// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\GrenadeLauncher.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Marine/Rifle.lua")
Script.Load("lua/Weapons/Marine/Grenade.lua")

class 'GrenadeLauncher' (Rifle)

GrenadeLauncher.kMapName              = "grenadelauncher"

GrenadeLauncher.kModelName = PrecacheAsset("models/marine/rifle/rifle.model")

GrenadeLauncher.kLauncherFireDelay = kGrenadeLauncherFireDelay
GrenadeLauncher.kAuxClipSize = 1
GrenadeLauncher.kLauncherStartingAmmo = 2 * kGrenadeLauncherClipSize
GrenadeLauncher.kGrenadesPerAmmoClip = kGrenadeLauncherClipSize
GrenadeLauncher.kGrenadeDamage = kGrenadeLauncherGrenadeDamage

local networkVars =
    {
        auxAmmo = string.format("integer (0 to %d)", GrenadeLauncher.kLauncherStartingAmmo),
        auxClip = string.format("integer (0 to %d)", GrenadeLauncher.kAuxClipSize),
        justShotGrenade = "boolean",
    }
 
// Use rifle attack effect block for primary fire
function GrenadeLauncher:GetPrimaryAttackPrefix()
    return "rifle"
end

function GrenadeLauncher:GetViewModelName()
    return Rifle.kViewModelName
end

function GrenadeLauncher:GetWeight()
    // A bit lighter then NS1
    return Rifle.GetWeight(self) + ((self:GetAmmo() + self:GetClip()) / self:GetClipSize()) * 0.01
end

function GrenadeLauncher:GetNeedsAmmo()
    return Rifle.GetNeedsAmmo(self) or self.auxClip < GrenadeLauncher.kAuxClipSize or self.auxAmmo < GrenadeLauncher.kLauncherStartingAmmo
end

function GrenadeLauncher:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function GrenadeLauncher:GiveAmmo(clips)
    
    // Give half to GL and any not used, give to rifle
    local glClips = clips/2
    local grenades = glClips * GrenadeLauncher.kGrenadesPerAmmoClip 
    
    local grenadesUsed = math.min(GrenadeLauncher.kLauncherStartingAmmo - self.auxAmmo - 1, grenades)
    self.auxAmmo = self.auxAmmo + grenadesUsed
    
    local clipsLeft = (clips - glClips) + (grenades - grenadesUsed) * GrenadeLauncher.kGrenadesPerAmmoClip 
    
    if clipsLeft > 0 then
        Rifle.GiveAmmo(self, clipsLeft)
    end
    
end

function GrenadeLauncher:GetAuxClip()
    // Return how many grenades we have left. Naming seems strange but the 
    // "clip" for the GL is how many grenades we have total.
    return self.auxAmmo
end

function GrenadeLauncher:GetSecondaryAttackDelay()
    return GrenadeLauncher.kLauncherFireDelay
end

// Fire grenade with secondary attack
function GrenadeLauncher:OnSecondaryAttack(player)

    if (self.auxClip > 0) then
    
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())

        player:DeactivateWeaponLift()
        
        // Fire grenade projectile
        if Server then
        
            local viewAngles = player:GetViewAngles()
            local viewCoords = viewAngles:GetCoords()
            
            // Make sure start point isn't on the other side of a wall or object
            local startPoint = player:GetEyePos() + viewCoords.zAxis * .5 - viewCoords.xAxis * .3 - viewCoords.yAxis * .25
            local trace = Shared.TraceRay(player:GetEyePos(), startPoint, PhysicsMask.Bullets, EntityFilterOne(player))
            
            if trace.fraction ~= 1 then
            
                // The eye position just barely sticks out past some walls so we
                // need to move the emit point back a tiny bit to compensate.
                VectorCopy(player:GetEyePos() - (viewCoords.zAxis * 0.2), startPoint)
                
            end
            
            local grenade = CreateEntity(Grenade.kMapName, startPoint, player:GetTeamNumber())
            SetAnglesFromVector(grenade, viewCoords.zAxis)
            
            // Inherit player velocity?
            local startVelocity = viewCoords.zAxis * 15
            startVelocity.y = startVelocity.y + 3
            grenade:SetVelocity(startVelocity)
            
            // Set grenade owner to player so we don't collide with ourselves and so we
            // can attribute a kill to us
            grenade:SetOwner(player)
            
        end
        
        // We need to do this on the Client and Server for proper prediction.
        ClipWeapon.OnSecondaryAttack(self, player)

        self.auxClip = self.auxClip - 1
        self.justShotGrenade = true
        
    elseif (not self:ReloadGrenade(player)) then

        player:DeactivateWeaponLift()
        
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())
        
    end
    
end

function GrenadeLauncher:CanReload()
    return ClipWeapon.CanReload(self) or (self.auxClip == 0 and self.auxAmmo > 0)
end

function GrenadeLauncher:OnInit()

    Rifle.OnInit(self)
    
    self.auxAmmo = GrenadeLauncher.kLauncherStartingAmmo
    self.auxClip = 0
    self.justShotGrenade = false
    
end

function GrenadeLauncher:ReloadGrenade(player)
    
    local success = false
    
    // Automatically reload if we're out of ammo - don't have to hit a key
    if player:GetCanNewActivityStart() then
    
        self.justShotGrenade = false
        
        if (self.auxClip < GrenadeLauncher.kAuxClipSize) and (self.auxAmmo > 0) then
            
            self:TriggerEffects("grenadelauncher_reload")
            
            // Play the reload sequence and don't let it be interrupted until it finishes playing.
            player:SetActivityEnd(player:GetViewAnimationLength())
            
            self.auxClip = self.auxClip + 1
            
            self.auxAmmo = self.auxAmmo - 1
            
            success = true
            
        end
        
    end
    
    return success
    
end

function GrenadeLauncher:OnProcessMove(player, input)

    Rifle.OnProcessMove(self, player, input)
    
    self:ReloadGrenade(player)
    
end

function GrenadeLauncher:UpdateViewModelPoseParameters(viewModel, input)
    
    // Needs to be called before we set the grenade parameters.
    Rifle.UpdateViewModelPoseParameters(self, viewModel, input)
    
    viewModel:SetPoseParam("hide_gl", 0)
    local glEmpty = ConditionalValue(self.auxClip == 0, 1, 0)
    // Do not show as empty until the shooting animation is done.
    if self.justShotGrenade then
        glEmpty = 0
    end
    viewModel:SetPoseParam("gl_empty", glEmpty)
    
end

function GrenadeLauncher:GetEffectParams(tableParams)

    Rifle.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterEmpty] = ConditionalValue(self.auxClip == 0, true, false)
    
end

Shared.LinkClassToMap("GrenadeLauncher", GrenadeLauncher.kMapName, networkVars)