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
GrenadeLauncher.kGrenadesPerAmmoClip = 4
GrenadeLauncher.kGrenadeDamage = kGrenadeLauncherGrenadeDamage

GrenadeLauncher.networkVars =
{
    auxAmmo = string.format("integer (0 to %d)", kGrenadeLauncherClipSize),
    auxClipFull = "boolean",
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
    return Rifle.GetNeedsAmmo(self) or (not self.auxClipFull) or (self.auxAmmo < kGrenadeLauncherClipSize)
end

function GrenadeLauncher:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function GrenadeLauncher:GiveAmmo(clips)
    
    // Give all to GL and any not used, give to rifle. Put in reserves before clip.
    local success = false
    local grenadesToGive = clips * GrenadeLauncher.kGrenadesPerAmmoClip 

    local grenadesForAuxAmmo = math.min(grenadesToGive, math.min(kGrenadeLauncherClipSize - self.auxAmmo))
    if grenadesForAuxAmmo > 0 then
    
        self.auxAmmo = self.auxAmmo + grenadesForAuxAmmo
        grenadesToGive = grenadesToGive - grenadesForAuxAmmo
        success = true
        
    end
    
    if not self.auxClipFull and (grenadesToGive > 0) then
    
        grenadesToGive = grenadesToGive - 1
        self.auxClipFull = true        
        success = true
        
    end

    // Convert back into clips and give the rest to the rifle ammo    
    clips = grenadesToGive / GrenadeLauncher.kGrenadesPerAmmoClip
    
    if clips > 0 and Rifle.GiveAmmo(self, clips) then
        success = true        
    end
    
    return success
    
end

function GrenadeLauncher:GetAuxClip()
    // Return how many grenades we have left. Naming seems strange but the 
    // "clip" for the GL is how many grenades we have total.
    return self.auxAmmo + ConditionalValue(self.auxClipFull, 1, 0)
end

function GrenadeLauncher:GetSecondaryAttackDelay()
    return GrenadeLauncher.kLauncherFireDelay
end

// Fire grenade with secondary attack
function GrenadeLauncher:OnSecondaryAttack(player)

    if self.auxClipFull then
    
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())

        player:DeactivateWeaponLift()
        
        // Fire grenade projectile
        if Server then
        
            local viewAngles = player:GetViewAngles()
            local viewCoords = viewAngles:GetCoords()
            
            // Make sure start point isn't on the other side of a wall or object
            local startPoint =  player:GetEyePos() + 
                                viewCoords.zAxis * .5 - viewCoords.xAxis * .3 - viewCoords.yAxis * .25
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

        self.auxClipFull = false
        self.justShotGrenade = true
        
    elseif (not self:ReloadGrenade(player)) then

        player:DeactivateWeaponLift()
        
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())
        
    end
    
end

function GrenadeLauncher:CanReload()
    return ClipWeapon.CanReload(self) or (not self.auxClipFull and self.auxAmmo > 0)
end

function GrenadeLauncher:OnInit()

    Rifle.OnInit(self)
    
    self.auxAmmo = (kGrenadeLauncherClipSize / 2)
    
    // Start empty to show player initial reload - ie, to draw their attention to them having a GL
    self.auxClipFull = false
    self.justShotGrenade = false
    
end

function GrenadeLauncher:ReloadGrenade(player)
    
    local success = false
    
    // Automatically reload if we're out of ammo - don't have to hit a key
    if player:GetCanNewActivityStart() then
    
        self.justShotGrenade = false
        
        if not self.auxClipFull and (self.auxAmmo > 0) then
            
            self:TriggerEffects("grenadelauncher_reload")
            
            // Play the reload sequence and don't let it be interrupted until it finishes playing.
            player:SetActivityEnd(player:GetViewAnimationLength())
            
            self.auxClipFull = true
            
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
    local glEmpty = ConditionalValue(self.auxClipFull, 0, 1)
    // Do not show as empty until the shooting animation is done.
    if self.justShotGrenade then
        glEmpty = 0
    end
    viewModel:SetPoseParam("gl_empty", glEmpty)
    
end

function GrenadeLauncher:GetEffectParams(tableParams)

    Rifle.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterEmpty] = not self.auxClipFull
    
end

Shared.LinkClassToMap("GrenadeLauncher", GrenadeLauncher.kMapName, GrenadeLauncher.networkVars)