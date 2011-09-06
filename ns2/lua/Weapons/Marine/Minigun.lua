// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Minigun.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")

class 'Minigun' (ClipWeapon)

Minigun.kMapName = "minigun"

Minigun.kModelName = PrecacheAsset("models/marine/minigun/minigun.model")
Minigun.kViewModelName = PrecacheAsset("models/marine/minigun/minigun_view.model")

//Minigun.kFireSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/fire")
Minigun.kSpinUpSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/spin_up")
Minigun.kSpinDownSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/spin_down")
Minigun.kSpinSoundName = PrecacheAsset("sound/ns2.fev/marine/minigun/spin")

kMinigunClipSize = kMinigunClipSize
kMinigunRange = 400
kMinigunDamage = kMinigunDamage
kMinigunFireDelay = kMinigunFireDelay
kMinigunSpread = ClipWeapon.kCone8Degrees   // From NS1
kMinigunSpinUpTime = .995

local networkVars =
{
    // -1 if not spinning up
    timeSpinUpComplete = "float",        
    spunUp = "boolean",
    
    // Used to remember which buttons are down so we don't spin
    // down prematurely (when both are held down)
    primaryAttack   = "boolean",
    secondaryAttack   = "boolean",
}

function Minigun:GetViewModelName()
    return Minigun.kViewModelName
end

function Minigun:GetWorldModelName()
    return Minigun.kModelName
end

function Minigun:GetFireSoundName()
    return Minigun.kFireSoundName
end

function Minigun:GetTracerPercentage()
    return .05
end

function Minigun:GetBaseIdleAnimation()

    if(NetworkRandom() < .45) then
        return "idle"
    end
    
    return "idle3"
    
end

function Minigun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Minigun:GetClipSize()
    return kMinigunClipSize
end

function Minigun:GetSpread()
    return kMinigunSpread   
end

function Minigun:GetBulletDamage(target, endPoint)
    return kMinigunDamage
end

function Minigun:GetRange()
    return kMinigunRange
end

function Minigun:GetPrimaryAttackDelay()
    return kMinigunFireDelay
end

function Minigun:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player)
    
    self.spunUp = false
    self.timeSpinUpComplete = -1
    self.primaryAttack = false
    self.secondaryAttack = false
    
end

function Minigun:OnHolster(player)

    self:SetSpinSoundPlaying(false)
    Shared.StopSound(player, Minigun.kSpinDownSoundName)
    Shared.StopSound(player, self:GetFireSoundName())
    
    ClipWeapon.OnHolster(self, player)
    
end

function Minigun:ConstrainMoveVelocity(moveVelocity)

    if(self.primaryAttack or self.secondaryAttack) then
    
        moveVelocity.x = moveVelocity.x / 3
        moveVelocity.z = moveVelocity.z / 3
        
    end
    
    return moveVelocity
    
end

function Minigun:OnPrimaryAttack(player)

    // If we're not warmed up, start warming up
    if(self.spunUp) then
    
        ClipWeapon.OnPrimaryAttack(self, player)
        
    else
    
        self:SpinUp(player)
    
    end
    
    self.primaryAttack = true

end

// Allow player to spin up barrel manually
function Minigun:OnSecondaryAttack(player)

    self:SpinUp(player)
    
    self.secondaryAttack = true
    
end

function Minigun:OnPrimaryAttackEnd(player)

    ClipWeapon.OnPrimaryAttackEnd(self, player)
    
    if(not self.secondaryAttack) then
        self:SpinDown()
    end
    
    self.primaryAttack = false
    
end

function Minigun:OnSecondaryAttackEnd(player)

    ClipWeapon.OnSecondaryAttackEnd(self, player)

    if(not self.primaryAttack) then
        self:SpinDown()
    end
    
    self.secondaryAttack = false
    
end

function Minigun:SpinUp(player)

    if(self.timeSpinUpComplete == -1) then

        Shared.StopSound(player, Minigun.kSpinDownSoundName)
        Shared.PlaySound(player, Minigun.kSpinUpSoundName)
        
        self.timeSpinUpComplete = Shared.GetTime() + kMinigunSpinUpTime
        
    end
        
end

function Minigun:SpinDown()

    self:SetSpinSoundPlaying(false)
    Shared.StopSound(player, self:GetFireSoundName())
    Shared.PlaySound(player, Minigun.kSpinDownSoundName)

    self.spunUp = false
    self.timeSpinUpComplete = -1
        
end

function Minigun:OnUpdate(deltaTime)

    ClipWeapon.OnUpdate(self, deltaTime)

    if(self:GetIsActive()) then
    
        self:UpdateAnimation( 0 )
        
        if(not self.spunUp and (self.timeSpinUpComplete ~= -1) and (Shared.GetTime() > self.timeSpinUpComplete)) then
            
            self.timeSpinUpComplete = -1
            self.spunUp = true
            
            Shared.PlaySound(player, Minigun.kSpinUpSoundName)
            self:SetSpinSoundPlaying(true)
                    
        end
        
    end       
end

function Minigun:SetSpinSoundPlaying(playing)

    if(playing) then
    
        if(not self.playingSpinSound) then
            //Shared.PlaySound(self:GetParent(), Minigun.kSpinSoundName)
        end
        
    else
    
        Shared.StopSound(self:GetParent(), Minigun.kSpinSoundName)
        
    end
    
    self.playingSpinSound = playing
    
end

function Minigun:ApplyBulletGameplayEffects(player, target, endPoint, direction)

    ClipWeapon.ApplyBulletGameplayEffects(self, player, target, endPoint, direction)
    
    // When bullets hit targets, apply force to send them backwards
    if(target:isa("Player")) then
    
        // Take player mass into account 
        local targetVelocity = target:GetVelocity() + direction * (200 / target:GetMass())
        target:SetVelocity(targetVelocity)
        
    end
    
end

Shared.LinkClassToMap("Minigun", Minigun.kMapName, networkVars)