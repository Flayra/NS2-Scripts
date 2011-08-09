// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\BoneShield.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
//  
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'BoneShield' (Ability)

BoneShield.kMapName = "boneshield"

// View model animations
BoneShield.kAnimAttackTable = {{1, "attack"}/*, {1, "attack2"}, {1, "attack3"}, {1, "attack4"}*/}

// Player animations
BoneShield.kAnimPlayerAttack = "shield"

// Balance

// Primary
BoneShield.kPrimaryEnergyCost = 10
BoneShield.kPrimaryAttackDelay = .7

// Secondary
BoneShield.kSecondaryEnergyCost = 20
BoneShield.kSecondaryAttackDelay = 3         

function BoneShield:GetPrimaryEnergyCost(player)
    return BoneShield.kPrimaryEnergyCost
end

function BoneShield:GetSecondaryEnergyCost(player)
    return BoneShield.kSecondaryEnergyCost
end

function BoneShield:GetPrimaryAttackDelay()
    return BoneShield.kPrimaryAttackDelay
end

function BoneShield:GetSecondaryAttackDelay()
    return BoneShield.kSecondaryAttackDelay
end

function BoneShield:GetIconOffsetY(secondary)
    return kAbilityOffset.BoneShield
end

function BoneShield:GetHUDSlot()
    return 2
end

function BoneShield:PerformPrimaryAttack(player)
    
    // Play random animation
    player:SetViewAnimation( BoneShield.kAnimAttackTable )
    player:SetActivityEnd(self:GetPrimaryAttackDelay())
    
    player:SetOverlayAnimation(BoneShield.kAnimPlayerAttack)
    
    return true
end

function BoneShield:PerformSecondaryAttack(player)
    
    // Play random animation
    player:SetViewAnimation(BoneShield.kAnimStabTable)
    player:SetActivityEnd(self:GetSecondaryAttackDelay())

    // Play the attack animation on the character.
    player:SetOverlayAnimation( chooseWeightedEntry(Fade.kAnimStabTable) )

    Shared.PlaySound(player, BoneShield.kStabSound)
    
    return true
    
end

Shared.LinkClassToMap("BoneShield", BoneShield.kMapName, {} )
