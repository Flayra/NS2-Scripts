// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Rifle.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")

class 'Rifle' (ClipWeapon)

Rifle.kMapName = "rifle"

Rifle.kModelName = PrecacheAsset("models/marine/rifle/rifle.model")
Rifle.kViewModelName = PrecacheAsset("models/marine/rifle/rifle_view.model")

Rifle.kClipSize = kRifleClipSize
Rifle.kRange = 250
Rifle.kFireDelay = kRifleFireDelay
Rifle.kSpread = ClipWeapon.kCone3Degrees    // 4 degrees in NS1
Rifle.kDamage = kRifleDamage

Rifle.kButtDelay = kRifleMeleeFireDelay
Rifle.kButtDamage = kRifleMeleeDamage
Rifle.kButtRange = 1.5

Rifle.kViewAnimationStates = enum( { 'None', 'AttackIn', 'Attack', 'AttackOut' } )

Rifle.kNumberOfVariants = 3

Rifle.kSingleShotSounds = { "sound/ns2.fev/marine/rifle/fire_single", "sound/ns2.fev/marine/rifle/fire_single_2", "sound/ns2.fev/marine/rifle/fire_single_3" }
for k, v in ipairs(Rifle.kSingleShotSounds) do PrecacheAsset(v) end

Rifle.kLoopingSounds = { "sound/ns2.fev/marine/rifle/fire_14_sec_loop", "sound/ns2.fev/marine/rifle/fire_loop_2", "sound/ns2.fev/marine/rifle/fire_loop_3" }
for k, v in ipairs(Rifle.kLoopingSounds) do PrecacheAsset(v) end

Rifle.kRifleEndSound = PrecacheAsset("sound/ns2.fev/marine/rifle/end")

Rifle.kAttackInViewModelAnimation =     "attack_in"
Rifle.kAttackViewModelAnimation =       "attack"
Rifle.kAttackOutViewModelAnimation =    "attack_out"

local networkVars =
{
    timeOfLastPrimaryAttack     = "float",
    timeStartedAttack           = "float",
    soundType                   = "integer (1 to 3)",
    playingLoopingOnEntityId    = "entityid",
    viewAnimationState          = "enum Rifle.kViewAnimationStates",
    animationStateDoneTime      = "float"
}

function Rifle:OnInit()

    ClipWeapon.OnInit(self)
    
    self.timeStartedAttack = 0
    self.soundType = Shared.GetRandomInt(1, Rifle.kNumberOfVariants)
    
    self.playingLoopingOnEntityId = Entity.invalidId
    
    self.viewAnimationState = Rifle.kViewAnimationStates.None
    
    if Client then
        self:SetUpdates(true)
    end
    
end

function Rifle:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    self:StopLoopingEffects()

end

function Rifle:GetViewModelName()
    return Rifle.kViewModelName
end

function Rifle:GetDeathIconIndex()
    return ConditionalValue(self.lastAttackSecondary, kDeathMessageIcon.RifleButt, kDeathMessageIcon.Rifle)
end

function Rifle:GetRunIdleAnimation()
    // No run idle animation yet
    return self:GetBaseIdleAnimation()
end

function Rifle:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Rifle:GetClipSize()
    return Rifle.kClipSize
end

function Rifle:GetReloadTime()
    return kRifleReloadTime
end

function Rifle:GetSpread()
    return Rifle.kSpread
end

function Rifle:GetBulletDamage(target, endPoint)
    return Rifle.kDamage
end

function Rifle:GetRange()
    return Rifle.kRange
end

function Rifle:GetPrimaryAttackDelay()
    return Rifle.kFireDelay
end

function Rifle:GetWeight()
    // From NS1 
    return .08 + ((self:GetAmmo() + self:GetClip()) / self:GetClipSize()) * 0.01
end

// Don't punish too badly for walking and moving
function Rifle:GetAccuracyRecoveryRate(player)
    local velocityScalar = player:GetVelocity():GetLength()/player:GetMaxSpeed()
    return 1.4 - .3*velocityScalar
end

function Rifle:GetSecondaryAttackDelay()
    return Rifle.kButtDelay
end

function Rifle:GetBarrelSmokeEffect()
    return Rifle.kBarrelSmokeEffect
end

function Rifle:GetShellEffect()
    return chooseWeightedEntry ( Rifle.kShellEffectTable )
end

function Rifle:GetTracerPercentage()
    return .2
end

function Rifle:CreatePrimaryAttackEffect(player)

    // Remember this so we can update gun_loop pose param
    self.timeOfLastPrimaryAttack = Shared.GetTime()
    
    self.lastAttackSecondary = false

end

function Rifle:GetReloadCancellable()
    return true
end

function Rifle:GetCanIdle()

    return (ClipWeapon.GetCanIdle(self)) and (not self:GetIsShooting())

end

function Rifle:OnEntityChange(oldId, newId)

    ClipWeapon.OnEntityChange(self, oldId, newId)
    
    // In case the parent is destroyed.
    if oldId == self.playingLoopingOnEntityId then
        self:StopLoopingEffects()
        self:CancelReload()
    end

end

function Rifle:GetIsShooting()

    local hasParent = self:GetParent() ~= nil
    local isNotHolstered = not self:GetIsHolstered()
    local startedAttack = self.timeStartedAttack ~= 0
    local notReloading = not self:GetIsReloading()
    local hasAmmo = self:GetClip() > 0
    local visible = self:GetIsVisible()
    return hasParent and isNotHolstered and startedAttack and notReloading and hasAmmo and visible
    
end

function Rifle:PlayLoopingEffects()

    local parent = self:GetParent()
    if parent then
    
        if self.viewAnimationState == Rifle.kViewAnimationStates.None then
        
            // Fire off a single shot on the first shot. Pew.
            Shared.PlaySound(parent, Rifle.kSingleShotSounds[self.soundType])
            // Start the looping sound for the rest of the shooting. Pew pew pew...
            Shared.PlaySound(parent, Rifle.kLoopingSounds[self.soundType])
            
            // Store enough information for us to stop the sound in the case where
            // the player dies.
            if Client then
                self.clientSoundType = self.soundType
                self.clientParentId  = parent:GetId()
            end
            
            local animationLength = parent:SetViewAnimation(Rifle.kAttackInViewModelAnimation, true, true)
            self.playingLoopingOnEntityId = parent:GetId()
            self.animationStateDoneTime = Shared.GetTime() + animationLength
            self.viewAnimationState = Rifle.kViewAnimationStates.AttackIn
            
        elseif self.viewAnimationState == Rifle.kViewAnimationStates.AttackIn and Shared.GetTime() >= self.animationStateDoneTime then
        
            parent:SetViewAnimation(Rifle.kAttackViewModelAnimation, true, true)
            self.playingLoopingOnEntityId = parent:GetId()
            // Looping animation has no predefined done time.
            self.animationStateDoneTime = 0
            self.viewAnimationState = Rifle.kViewAnimationStates.Attack
            
        end
        
    end

end

function Rifle:StopLoopingEffects()

    local parent = Shared.GetEntity(self.playingLoopingOnEntityId)
    if parent then
    
        if (self.viewAnimationState == Rifle.kViewAnimationStates.AttackIn and Shared.GetTime() >= self.animationStateDoneTime) or
           (self.viewAnimationState == Rifle.kViewAnimationStates.Attack) then
           
            // Just assume the looping sound is playing.
            Shared.StopSound(parent, Rifle.kLoopingSounds[self.soundType])
            Shared.PlaySound(parent, Rifle.kRifleEndSound)
            // If reloading, do not trigger the attack out view animation since the
            // reload animation is already triggered.
            // If holstered, do not trigger the attach out view animation since another
            // weapon is active and probably wants to control the view model.
            if (not self:GetIsReloading()) and (not self:GetIsHolstered()) then
                local animationLength = parent:SetViewAnimation(Rifle.kAttackOutViewModelAnimation, true, true)
                self.animationStateDoneTime = Shared.GetTime() + animationLength
                self.viewAnimationState = Rifle.kViewAnimationStates.AttackOut
            else
                self.viewAnimationState = Rifle.kViewAnimationStates.None
                self.animationStateDoneTime = 0
            end
            self.playingLoopingOnEntityId = Entity.invalidId
            
        end

    elseif Client and self.clientSoundType then
    
        // This case happens when the sound effect has been stopped by StopLoopingEffects on
        // the server, but was not predicted on the client (when a player dies for example).
    
        // In the case where the parent no longer exists, the engine will have automatically
        // stopped the looping sound effect.
        local parent = Shared.GetEntity(self.clientParentId)
        if parent then
            Shared.StopSound(parent, Rifle.kLoopingSounds[self.clientSoundType])
        end
        
        self.clientSoundType = nil
        self.clientParentId  = nil
        
    end

end

function Rifle:UpdateStateTransitions()

    if self.viewAnimationState == Rifle.kViewAnimationStates.AttackOut then
    
        if Shared.GetTime() >= self.animationStateDoneTime then
            self.viewAnimationState = Rifle.kViewAnimationStates.None
            self.animationStateDoneTime = 0
        end
        
    end

end

function Rifle:UpdateShootingEffects()

    self:UpdateStateTransitions()
    
    if self:GetIsShooting() then
        self:PlayLoopingEffects()
    else
        self:StopLoopingEffects()
    end

end

function Rifle:OnProcessMove(player, input)

    ClipWeapon.OnProcessMove(self, player, input)
    self:UpdateShootingEffects()

end

function Rifle:OnUpdate()

    ClipWeapon.OnUpdate(self)
    
    // When the weapon is being held, it will be updated by OnProcessMove
    if self:GetParentId() == Entity.invalidId then
        self:UpdateShootingEffects()
    end

end

function Rifle:OnHolster(player)
    
    ClipWeapon.OnHolster(self, player)
    
    self.timeStartedAttack = 0
    
end

function Rifle:OnPrimaryAttack(player)
	
    if not self:GetIsReloading() then

        if self.timeStartedAttack == 0 and self:GetClip() > 0 then
            self.timeStartedAttack = Shared.GetTime()
        end
    
        ClipWeapon.OnPrimaryAttack(self, player)
     
    end
end

function Rifle:OnPrimaryAttackEnd(player)

    ClipWeapon.OnPrimaryAttackEnd(self, player)
    
    self.timeStartedAttack = 0
    
end

function Rifle:PerformMeleeAttack(player)

    self.lastAttackSecondary = true
    
    // Perform melee attack
    local didHit, trace = self:AttackMeleeCapsule(player, Rifle.kButtDamage, Rifle.kButtRange)
    
    if didHit then
    
        local hitClassname = nil
        local isAlien = false
        
        if trace.entity then
            
            local hitObject = trace.entity
        
            hitClassname = hitObject:GetClassName()
            isAlien = (hitObject:GetTeamType() == kAlienTeamType)

            // Rifle melee attack will cause the target to be knocked back in some cases.
            self:KnockbackTarget(player, hitObject, trace.endPoint)
            
        end
        
    end
    
end

// Perform melee attack with rifle butt
function Rifle:OnSecondaryAttack(player)

    if ( player:GetCanNewActivityStart() ) then
    
        // Play view model effect
        player:SetActivityEnd(self:GetSecondaryAttackDelay() * player:GetCatalystFireModifier())

        player:DeactivateWeaponLift()
        
        self:CancelReload()
        
        ClipWeapon.OnSecondaryAttack(self, player)
        
    end

end

function Rifle:OnTag(tagName)

    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "hit" then
        local player = self:GetParent()
        if player then
            self:PerformMeleeAttack(player)
        end
    end

end

function Rifle:ApplyMeleeHitEffects(player, damage, target, endPoint, direction)

    if target then
    
        if HasMixin(target, "Live") then
            target:TakeDamage(damage, player, self, endPoint, direction)
        end
        
        // Throw back target a bit.
        target:AddImpulse(endPoint, direction)
        
    end
    
end

// Pass a time interval greater and get back 0-1. From last attack to interval is 0 to 1 0 means 2 x interval or more time has passed since
// our last attack and 1 is that we just attacked this frame.
function Rifle:GetGunLoopParam(interval)

    local desiredGunLoop = 0
    
    if self.timeOfLastPrimaryAttack ~= nil then
    
        local time = Shared.GetTime()
        if time - self.timeOfLastPrimaryAttack < interval then
            desiredGunLoop = (time - self.timeOfLastPrimaryAttack)/interval
        end
        
    end

    return desiredGunLoop
    
end

function Rifle:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    // 0.5 instead of 1 as full arm_loop is intense.
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function Rifle:UpdateViewModelPoseParameters(viewModel, input)

    viewModel:SetPoseParam("hide_gl", 1)
    viewModel:SetPoseParam("gl_empty", 1)

    local justAttacked = self.timeOfLastPrimaryAttack ~= nil and ((Shared.GetTime() - self.timeOfLastPrimaryAttack) < .2)
    local sign = ConditionalValue(justAttacked, 1, -1)

    self:SetGunLoopParam(viewModel, "arm_loop", sign * input.time)
    
end

function Rifle:GetEffectParams(tableParams)

    ClipWeapon.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterVariant] = self.soundType
    
end

function Rifle:Dropped(prevOwner)

    ClipWeapon.Dropped(self, prevOwner)
    self:UpdateShootingEffects()
    
end

Shared.LinkClassToMap("Rifle", Rifle.kMapName, networkVars)