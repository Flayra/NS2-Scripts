// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\ClipWeapon.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Basic bullet-based weapon. Handles primary firing only, as child classes have quite different
// secondary attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")

class 'ClipWeapon' (Weapon)

ClipWeapon.kMapName = "clipweapon"

local networkVars =
{
    ammo = "integer (0 to 255)",
    clip = "integer (0 to 200)",
    
    reloadTime = "float",
    
    // 1 is most accurate, 0 is least accurate
    accuracy = "float"
}

ClipWeapon.kAnimSwingUp = "swing_up"
ClipWeapon.kAnimSwingDown = "swing_down"

// Weapon spread - from NS1/Half-life
ClipWeapon.kCone0Degrees  = Math.Radians(0)
ClipWeapon.kCone1Degrees  = Math.Radians(1)
ClipWeapon.kCone2Degrees  = Math.Radians(2)
ClipWeapon.kCone3Degrees  = Math.Radians(3)
ClipWeapon.kCone4Degrees  = Math.Radians(4)
ClipWeapon.kCone5Degrees  = Math.Radians(5)
ClipWeapon.kCone6Degrees  = Math.Radians(6)
ClipWeapon.kCone7Degrees  = Math.Radians(7)
ClipWeapon.kCone8Degrees  = Math.Radians(8)
ClipWeapon.kCone9Degrees  = Math.Radians(9)
ClipWeapon.kCone10Degrees = Math.Radians(10)
ClipWeapon.kCone15Degrees = Math.Radians(15)
ClipWeapon.kCone20Degrees = Math.Radians(20)
                        
function ClipWeapon:GetBulletsPerShot()
    return 1
end

function ClipWeapon:GetNumStartClips()
    return 4
end

function ClipWeapon:GetClipSize()
    return 10
end

function ClipWeapon:GetAccuracyRecoveryRate(player)
    local velocityScalar = player:GetVelocity():GetLength()/player:GetMaxSpeed()
    return 1.4 - .8*velocityScalar
end

function ClipWeapon:GetAccuracyLossPerShot(player)
    local scalar = ConditionalValue(player:GetCrouching(), .5, 1)
    return scalar*.2
end

// Used to affect spread and change the crosshair
function ClipWeapon:GetInaccuracyScalar()
    return 1
end

function ClipWeapon:UpdateAccuracy(player, input)
    self.accuracy = self.accuracy + input.time*self:GetAccuracyRecoveryRate(player)
    self.accuracy = math.max(math.min(1, self.accuracy), 0)
end

// Return one of the ClipWeapon.kCone constants above
function ClipWeapon:GetSpread()
    return ClipWeapon.kCone0Degrees
end

function ClipWeapon:GetRange()
    return 8012
end

function ClipWeapon:GetPrimaryAttackDelay()
    return .5
end

function ClipWeapon:GetAmmo()
    return self.ammo
end

function ClipWeapon:GetClip()
    return self.clip
end

function ClipWeapon:SetClip(clip)
    self.clip = clip
end

function ClipWeapon:GetAuxClip()
    return 0
end

function ClipWeapon:GetMaxAmmo()
    return 4 * self:GetClipSize()
end

// Return world position of gun barrel, used for weapon effects.
function ClipWeapon:GetBarrelPoint()

    // TODO: Get this from the model and artwork.
    local player = self:GetParent()
    if player then
        return player:GetOrigin() + Vector(0, 2 * player:GetExtents().y * 0.8, 0) + player:GetCoords().zAxis * 0.5
    end
    
    return self:GetOrigin()
    
end

// Add energy back over time, called from Player:OnProcessMove
function ClipWeapon:OnProcessMove(player, input)

    if self.reloadTime ~= 0 and Shared.GetTime() >= self.reloadTime then
    
        self:FillClip()
        self.reloadTime = 0
       
    end

    self:UpdateAccuracy(player, input)
    
    Weapon.OnProcessMove(self, player, input)
    
end

function ClipWeapon:OnHolster(player)

    Weapon.OnHolster(self, player)
    
    self:CancelReload(player)
    
end

function ClipWeapon:OnInit()

    // Set model to be rendered in 3rd-person
    local worldModel = LookupTechData(self:GetTechId(), kTechDataModel)
    if worldModel ~= nil then
        self:SetModel(worldModel)
    end
    
    self:SetMoveWithView(true)
    
    self.ammo = self:GetNumStartClips() * self:GetClipSize()
    self.clip = 0
    self.reloadTime = 0
    self.accuracy = 1

    self:FillClip()

    Weapon.OnInit(self)

end

function ClipWeapon:GetSwingUpAnimation()
    return ClipWeapon.kAnimSwingUp
end

function ClipWeapon:GetSwingDownAnimation()
    return ClipWeapon.kAnimSwingDown
end

function ClipWeapon:GetBulletDamage(target, endPoint)
    Print("%s:GetBulletDamage() - Need to override GetBulletDamage()", self:GetClassName())
    return 0
end

function ClipWeapon:GetIsReloading()
    return self.reloadTime > Shared.GetTime()
end

function ClipWeapon:GetCanIdle()
    return Weapon.GetCanIdle(self) and not self:GetIsReloading()
end

function ClipWeapon:GiveAmmo(numClips)

    // Fill reserves, then clip. NS1 just filled reserves but I like the implications of filling the clip too.
    // But don't do it until reserves full.
    local success = false
    local bulletsToGive = numClips * self:GetClipSize()
    
    local bulletsToAmmo = math.min(bulletsToGive, self:GetMaxAmmo() - self:GetAmmo())        
    if bulletsToAmmo > 0 then

        self.ammo = self.ammo + bulletsToAmmo

        bulletsToGive = bulletsToGive - bulletsToAmmo        
        
        success = true
        
    end
    
    if bulletsToGive > 0 and (self:GetClip() < self:GetClipSize()) then
        
        self.clip = self.clip + math.min(bulletsToGive, self:GetClipSize() - self:GetClip())
        success = true        
        
    end

    return success
    
end

function ClipWeapon:GetNeedsAmmo()
    return (self:GetClip() < self:GetClipSize()) or (self:GetAmmo() < self:GetMaxAmmo())
end

function ClipWeapon:GetWarmupTime()
    return 0
end

function ClipWeapon:GetPrimaryAttackRequiresPress()
    return false
end

function ClipWeapon:GetForcePrimaryAttackAnimation()
    return true
end

function ClipWeapon:OnPrimaryAttack(player)
   
    if not self:GetPrimaryAttackRequiresPress() or not player:GetPrimaryAttackLastFrame() then
    
        if self.clip > 0 then
        
            self:CancelReload(player)
            
            // Allow the weapon to be fired again before the activity animation ends.
            // This allows us to have a fast rate of fire and still have nice animation
            // effects in the case of the final shot
            //player:SetViewAnimation( self:GetPrimaryAttackAnimation(), not self:GetForcePrimaryAttackAnimation() )

            // Some weapons don't start firing right away
            local warmupTime = self:GetWarmupTime()
            
            if not player:GetPrimaryAttackLastFrame() and warmupTime > 0 then
            
                player:SetActivityEnd(warmupTime)
                
            else
        
                self:FirePrimary(player)
                
                // Play the end effect now before the clip runs out in case there are effects that
                // don't trigger when empty.
                if self.clip == 1 then
                    Weapon.OnPrimaryAttackEnd(self, player)
                end
                // Don't decrement ammo in Darwin mode
                if(not player or not player:GetDarwinMode()) then
                    self.clip = self.clip - 1
                end
                            
                player:SetActivityEnd( self:GetPrimaryAttackDelay() * player:GetCatalystFireModifier() )
                
            end
            
            // Play the fire animation on the character.
            player:SetOverlayAnimation(Marine.kAnimOverlayFire)
            
            player:DeactivateWeaponLift()

            self:CreatePrimaryAttackEffect(player)
            
            Weapon.OnPrimaryAttack(self, player)
                    
        elseif self.ammo > 0 then

            Weapon.OnPrimaryAttackEnd(self, player)
            
            // Automatically reload if we're out of ammo
            player:Reload()
        
        else
        
            if not self.nextClipWeaponEmptyTriggerTime or self.nextClipWeaponEmptyTriggerTime <= Shared.GetTime() then
                self:TriggerEffects("clipweapon_empty")
                self.nextClipWeaponEmptyTriggerTime = Shared.GetTime() + player:GetViewAnimationLength()
            end
            
            Weapon.OnPrimaryAttackEnd(self, player)
            
        end
        
    end
    
end

function ClipWeapon:CreatePrimaryAttackEffect(player)
end

function ClipWeapon:OnSecondaryAttack(player)

    self.nextClipWeaponEmptyTriggerTime = 0
    Weapon.OnSecondaryAttack(self, player)
    player:DeactivateWeaponLift()
    
end

function ClipWeapon:FirePrimary(player)
    self:FireBullets(player)
end

// Play ricochet sound/effect every %d bullets
function ClipWeapon:GetRicochetEffectFrequency()
    return 1
end

function ClipWeapon:GetIsDroppable()
    return true
end

/**
 * Fires the specified number of bullets in a cone from the player's current view.
 */
function ClipWeapon:FireBullets(player)

    local viewAngles = player:GetViewAngles()
    local shootCoords = viewAngles:GetCoords()
    
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local range = self:GetRange()
    local numberBullets = self:GetBulletsPerShot()
    local startPoint = player:GetEyePos()
    
    if Client then
        DbgTracer.MarkClientFire(player, startPoint)
    end
    
    for bullet = 1, numberBullets do
    
        local spreadDirection = CalculateSpread(shootCoords, self:GetSpread() * self:GetInaccuracyScalar(), NetworkRandom)
        
        local endPoint = startPoint + spreadDirection * range
        
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.Bullets, filter)
        
        if Server then
            Server.dbgTracer:TraceBullet(player, startPoint, trace)
        end
        
        if Server and HasMixin(self, "Tracer") then
            self:TriggerTracer(trace.endPoint)
        end
        
        if trace.fraction < 1 then

            local blockedByUmbra = GetBlockedByUmbra(trace.entity)
            if not blockedByUmbra then
            
                if trace.entity then
                
                    local direction = (trace.endPoint - startPoint):GetUnit()
                    self:ApplyBulletGameplayEffects(player, trace.entity, trace.endPoint, direction)

                end
                
                // Play ricochet sound for player locally for feedback, but not necessarily for every bullet
                local effectFrequency = self:GetRicochetEffectFrequency()
                if bullet % effectFrequency == 0 then
            
                    local impactPoint = trace.endPoint - GetNormalizedVector(endPoint - startPoint) * Weapon.kHitEffectOffset
                    local surfaceName = trace.surface
                    TriggerHitEffects(self, trace.entity, impactPoint, surfaceName, false)
                    
                    // If we are far away from our target, trigger a private sound so we can hear we hit something
                    if surfaceName and string.len(surfaceName) > 0 and (trace.endPoint - player:GetOrigin()):GetLength() > 5 then
                        
                        player:TriggerEffects("hit_effect_local", {surface = surfaceName})
                        
                    end
                    
                end
                
            end
            
            // Update accuracy
            self.accuracy = math.max(math.min(1, self.accuracy - self:GetAccuracyLossPerShot(player)), 0)

        end

    end

end

function ClipWeapon:ApplyBulletGameplayEffects(player, target, endPoint, direction)

    if Server then
    
        if HasMixin(target, "Live") then
        
            target:TakeDamage(self:GetBulletDamage(target, endPoint), player, self, endPoint, direction)
            
        end
    
        self:GetParent():SetTimeTargetHit()
        
    end
    
end

function ClipWeapon:CanReload()
    return (self.ammo > 0) and (self.clip < self:GetClipSize()) and (self.reloadTime == 0)
end

function ClipWeapon:CancelReload(player)

    if self:GetIsReloading() then
    
        self.reloadTime = 0
        self:TriggerEffects("reload_cancel")
        if self.OnCancelReload then
            self:OnCancelReload(player)
        end
        
    end
    
end

function ClipWeapon:OnReload(player)

    if self:CanReload() then
    
        // Assumes view model animation WILL be set or reload time might be the idle or something else
        self:TriggerEffects("reload")
        
        // Play the reload sequence and optionally let it be interrupted before it finishes
        local length = player:GetViewAnimationLength()
        self.reloadTime = Shared.GetTime() + length
        
    end
    
end

function ClipWeapon:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
end

function ClipWeapon:FillClip()

    // Stick the bullets in the clip back into our pool so that we don't lose
    // bullets. Not realistic, but more enjoyable
    self.ammo = self.ammo + self.clip

    // Transfer bullets from our ammo pool to the weapon's clip
    self.clip = math.min(self.ammo, self:GetClipSize())
    self.ammo = self.ammo - self.clip

end

function ClipWeapon:GetEffectParams(tableParams)

    Weapon.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterEmpty] = (self.clip == 0)
    
end

Shared.LinkClassToMap("ClipWeapon", ClipWeapon.kMapName, networkVars)