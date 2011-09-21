// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Blink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Blink - Attacking many times in a row will create a cool visual "chain" of attacks, 
// showing the more flavorful animations in sequence. Base class for swipe and stab.
//
// TODO: Hold shift for "rebound" type ability. Shift while looking at enemy lets you blink above, behind or off of a wall.
//
// 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Blink' (Ability)
Blink.kMapName = "blink"

Blink.kBlinkSound = PrecacheAsset("sound/ns2.fev/alien/fade/blink")

// Blink
Blink.kSecondaryAttackDelay = 0
Blink.kStartEtherealForce = 15
Blink.kStartBlinkEnergyCost = .1    // Separate out initial blink cost from continous cost to promote fewer, more significant blinks

// The amount of time that must pass before the player can enter the ether again.
Blink.kMinEnterEtherealTime = 0.5

Blink.networkVars =
{
    // True when we're moving quickly "through the ether"
    ethereal           = "boolean",
    
    etherealStartTime = "float",
    
    // True when blink started and button not yet released
    blinkButtonDown    = "boolean",
}

function Blink:OnInit()

    Ability.OnInit(self)
    
    self.ethereal = false
    self.blinkButtonDown = false
    
end

function Blink:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:SetEthereal(player, false)
    
end

function Blink:GetHasSecondary(player)
    return true
end

function Blink:GetSecondaryAttackDelay()
    return Blink.kSecondaryAttackDelay
end

function Blink:GetSecondaryAttackRequiresPress()
    return true
end

function Blink:TriggerBlinkOutEffects(player)

    // Play particle effect at vanishing position
    if not Shared.GetIsRunningPrediction() then
    
        self:TriggerEffects("blink_out", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        if Client and Client.GetLocalPlayer():GetId() == player:GetId() then
            self:TriggerEffects("blink_out_local", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        end
        
    end
    
    player:SetAnimAndMode(Fade.kBlinkOutAnim, kPlayerMode.FadeBlinkOut)

end

function Blink:TriggerBlinkInEffects(player)

    if not Shared.GetIsRunningPrediction() then
        self:TriggerEffects("blink_in", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
    end
    
    player:SetAnimAndMode(Fade.kBlinkInAnim, kPlayerMode.FadeBlinkIn)
    
end

function Blink:GetIsBlinking()
    return self:GetEthereal()
end

// Cannot attack while blinking.
function Blink:GetPrimaryAttackAllowed()
    return not self:GetIsBlinking()
end

function Blink:PerformPrimaryAttack(player)
    return true
end

function Blink:OnSecondaryAttack(player)

    if not self.etherealStartTime or Shared.GetTime() - self.etherealStartTime >= Blink.kMinEnterEtherealTime then
    
        // Enter "ether" fast movement mode, but don't keep going ethereal when button still held down after
        // running out of energy
        if not self.blinkButtonDown then
            self:SetEthereal(player, true)
            self.blinkButtonDown = true
        end
        
    end
    
    Ability.OnSecondaryAttack(self, player)
    
end

function Blink:OnSecondaryAttackEnd(player)

    if self.ethereal then
        self:SetEthereal(player, false)
    end
    
    Ability.OnSecondaryAttackEnd(self, player)
    
    self.blinkButtonDown = false
    
end

function Blink:GetEthereal()
    return self.ethereal
end

function Blink:SetEthereal(player, state)

    // Enter or leave invulnerable invisible fast-moving mode
    if self.ethereal ~= state then
    
        if state then
            self.etherealStartTime = Shared.GetTime()
            self:TriggerBlinkOutEffects(player)
        else
            self:TriggerBlinkInEffects(player)            
        end
        
        self.ethereal = state
        
        // Set player visibility state
        player:SetIsVisible(not self.ethereal)
        player:SetGravityEnabled(not self.ethereal)
        
        player:SetEthereal(state)
        
        // Give player initial velocity in direction we're pressing, or forward if not pressing anything.
        if self.ethereal then
        
            local initialBoostDirection = player:GetViewAngles():GetCoords().zAxis
            if player.desiredMove and player.desiredMove:GetLength() > .01 then
            
                // Transform desired move into direction.
                local initialDirection = player:GetViewAngles():GetCoords():TransformVector( player.desiredMove )
                VectorCopy(initialDirection, initialBoostDirection)
                initialBoostDirection:Normalize()
                
            end
        
            // If desired velocity is quite opposite of our current velocity, don't
            local velocity = player:GetVelocity() 
            local newVelocity = initialBoostDirection * Blink.kStartEtherealForce            
            player:SetVelocity(newVelocity)
            
            // Deduct blink start energy amount.
            player:DeductAbilityEnergy(Blink.kStartBlinkEnergyCost)

        else
        
            // Mute current velocity when coming out of blink
            player:SetVelocity( player:GetVelocity() * .3 )
            
        end
        
    end
    
end

function Blink:OnProcessMove(player, input)

    if self:GetIsActive() and self.ethereal then
    
        // Decrease energy while in blink mode
        local energyCost = input.time * kBlinkEnergyCost
        
        // No energy cost in Darwin mode
        if player and player:GetDarwinMode() then
            energyCost = 0
        end

        player:DeductAbilityEnergy(energyCost)
        
    end
    
    // End blink mode if out of energy
    if player:GetEnergy() == 0 and self.ethereal then
        self:SetEthereal(player, false)
    end
        
    Ability.OnProcessMove(self, player, input)
    
end

Shared.LinkClassToMap("Blink", Blink.kMapName, Blink.networkVars)