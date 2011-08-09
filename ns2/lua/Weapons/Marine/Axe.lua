// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Axe.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Weapon.lua")

class 'Axe' (Weapon)

Axe.kMapName = "axe"

Axe.kModelName = PrecacheAsset("models/marine/axe/axe.model")
Axe.kViewModelName = PrecacheAsset("models/marine/axe/axe_view.model")

// Use only single attack until we have shared random numbers

Axe.kDamage = kAxeDamage
Axe.kFireDelay = kAxeFireDelay
Axe.kRange = 1.0

local networkVars = { }

function Axe:GetViewModelName()
    return Axe.kViewModelName
end

function Axe:GetHUDSlot()
    return kTertiaryWeaponSlot
end

function Axe:GetRange()
    return Axe.kRange
end

function Axe:GetPrimaryAttackDelay()
    return Axe.kFireDelay
end

function Axe:OnReload(player)
end

function Axe:GetDeathIconIndex()
    return kDeathMessageIcon.Axe
end

function Axe:OnInit()
    
    // Set model to be rendered in 3rd-person
    self:SetModel(Axe.kModelName)

    self:SetMoveWithView(true)
    
    // Set invisible so view model doesn't draw in world. We draw view model manually for local player
    self:SetIsVisible(false)

    Weapon.OnInit(self)

end

function Axe:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
end

function Axe:OnPrimaryAttack(player)

    Weapon.OnPrimaryAttack(self, player)

    // Allow the weapon to be fired again before the activity animation ends.
    // This allows us to have a fast rate of fire and still have a nice animation
    // when not interrupted
    player:SetActivityEnd(self:GetPrimaryAttackDelay() * player:GetCatalystFireModifier())
    
end

function Axe:OnTag(tagName)

    Weapon.OnTag(self, tagName)

    if(tagName == "hit") then
    
        local player = self:GetParent()
        if player then
            self:AttackMeleeCapsule(player, Axe.kDamage, self:GetRange())
        end
        
    end
    
end

// Max degrees that weapon can swing left or right
function Axe:GetSwingAmount()
    return 10
end

Shared.LinkClassToMap("Axe", Axe.kMapName, networkVars)