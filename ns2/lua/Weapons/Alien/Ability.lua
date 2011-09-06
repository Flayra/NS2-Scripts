// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Ability.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Weapon.lua")

class 'Ability' (Weapon)

Ability.kMapName = "alienability"

Ability.kAttackDelay = .5
Ability.kEnergyCost = 20
Ability.kMaxEnergy = 100

// The order of icons in kHUDAbilitiesTexture, used by GetIconOffsetY.
// These are just the rows, the colum is determined by primary or secondary
// The 0th row is the unknown (?) icon
kAbilityOffset = enum( {'Bite', 'Parasite', 'Spit', 'Infestation', 'Spikes', 'Sniper', 'Spores', 'SwipeBlink', 'StabBlink', 'Blink', 'Hydra', 'Gore', 'BoneShield', 'Stomp', 'Charge', 'BileBomb'} )

// Override these
function Ability:GetPrimaryAttackDelay()
    return Ability.kAttackDelay
end

// Return 0-100 energy cost (where 100 is full energy bar)
function Ability:GetEnergyCost(player)
    return Ability.kEnergyCost
end

function Ability:GetHasSecondary(player)
    return false
end

function Ability:GetSecondaryEnergyCost(player)
    return self:GetEnergyCost(player)
end

function Ability:GetIconOffsetX(secondary)
    return ConditionalValue(secondary, 1, 0)
end

function Ability:GetIconOffsetY(secondary)
    return 0
end

// return array of player energy (0-1), ability energy cost (0-1), x offset, y offset, visibility and hud slot
function Ability:GetInterfaceData(secondary, inactive)

    local parent = self:GetParent()
    // It is possible there will be a time when there isn't a parent due to how Entities are destroyed and unparented.
    if parent then
        local vis = (inactive and parent:GetInactiveVisible()) or (not inactive) //(parent:GetEnergy() ~= Ability.kMaxEnergy)
        local hudSlot = 0
        if self.GetHUDSlot then
            hudSlot = self:GetHUDSlot()
        end
        
        // Inactive abilities return only xoff, yoff, hud slot
        if inactive then
            return {self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), hudSlot}
        else
        
            if secondary then
                return {parent:GetEnergy()/Ability.kMaxEnergy, self:GetSecondaryEnergyCost()/Ability.kMaxEnergy, self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), vis, hudSlot}
            else
                return {parent:GetEnergy()/Ability.kMaxEnergy, self:GetEnergyCost()/Ability.kMaxEnergy, self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), vis, hudSlot}
            end
            
        end
    end
    
    return { }
    
end

// Abilities don't have world models, they are part of the creature
function Ability:GetWorldModelName()
    return ""
end

// All alien abilities use the view model designated by the alien
function Ability:GetViewModelName()

    local viewModel = ""
    local parent = self:GetParent()
    
    if (parent ~= nil and parent:isa("Alien")) then
        viewModel = parent:GetViewModelName()        
    end
    
    return viewModel
    
end

function Ability:PerformPrimaryAttack(player)
    return false
end

function Ability:PerformSecondaryAttack(player)
    return false
end

function Ability:OnInit()
            
    self:SetMoveWithView(false)
    
    Weapon.OnInit(self)
    
end

// Child class should override if preventing the primary attack is needed.
function Ability:GetPrimaryAttackAllowed()
    return true
end

// Child class can override
function Ability:OnPrimaryAttack(player)

    if self:GetPrimaryAttackAllowed() and (not self:GetPrimaryAttackRequiresPress() or not player:GetPrimaryAttackLastFrame()) then
    
        // Check energy cost
        local energyCost = self:GetEnergyCost(player)
        
        // No energy cost in Darwin mode
        if(player and player:GetDarwinMode()) then
            energyCost = 0
        end
        
        if(player:GetEnergy() >= energyCost) then            
                
            if self:PerformPrimaryAttack(player) then            
            
                player:DeductAbilityEnergy(energyCost)
                
                Weapon.OnPrimaryAttack(self, player)
            end

        end
        
    end
    
end

function Ability:OnSecondaryAttack(player)

    if(not self:GetSecondaryAttackRequiresPress() or not player:GetSecondaryAttackLastFrame()) then

        // Check energy cost
        local energyCost = self:GetSecondaryEnergyCost(player)
        
        // No energy cost in Darwin mode
        if(player and player:GetDarwinMode()) then
            energyCost = 0
        end

        if(player:GetEnergy() >= energyCost) then

            if self:PerformSecondaryAttack(player) then
            
                player:DeductAbilityEnergy(energyCost)
                
                Weapon.OnSecondaryAttack(self, player)
                
            end

        end

    end
    
end

// TODO: Do something for reloading? Give alien some quick energy for a long-term cost (a little health, or slower energy gaining for a while?)
function Ability:OnReload()
end
function Ability:Reload()
end

function Ability:GetEffectParams(tableParams)

    Weapon.GetEffectParams(self, tableParams)
    
    local player = self:GetParent()
    if player then
    
        tableParams[kEffectParamAnimationSpeed] = 1 / player:AdjustAttackDelay(1)
        
    end
    
end

Shared.LinkClassToMap("Ability", "alienability", {})
