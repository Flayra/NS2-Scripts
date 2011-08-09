// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Stomp.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Stomp' (Ability)

Stomp.kMapName = "stomp"

Stomp.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/onos/stomp")

// View model animations
Stomp.kAnimAttackTable = {{1, "attack"}/*, {1, "attack2"}, {1, "attack3"}, {1, "attack4"}*/}

// Player animations
Stomp.kAnimPlayerAttack = "stomp"

// Balance

// Primary
Stomp.kPrimaryEnergyCost = 10
Stomp.kPrimaryAttackDelay = .7

// Secondary
Stomp.kSecondaryEnergyCost = 20
Stomp.kSecondaryAttackDelay = 3         

function Stomp:GetPrimaryEnergyCost(player)
    return Stomp.kPrimaryEnergyCost
end

function Stomp:GetSecondaryEnergyCost(player)
    return Stomp.kSecondaryEnergyCost
end

function Stomp:GetPrimaryAttackDelay()
    return Stomp.kPrimaryAttackDelay
end

function Stomp:GetSecondaryAttackDelay()
    return Stomp.kSecondaryAttackDelay
end

function Stomp:GetHUDSlot()
    return 3
end

function Stomp:GetIconOffsetY(secondary)
    return kAbilityOffset.Stomp
end

function Stomp:PerformPrimaryAttack(player)
    
    // Play random animation
    player:SetViewAnimation( Stomp.kAnimAttackTable )
    player:SetActivityEnd(self:GetPrimaryAttackDelay())

    player:SetOverlayAnimation(Stomp.kAnimPlayerAttack)

    Shared.PlaySound(player, Stomp.kAttackSound)
    
    return true
end

function Stomp:PerformSecondaryAttack(player)
    
    // Play random animation
    player:SetViewAnimation(Stomp.kAnimStabTable)
    player:SetActivityEnd(self:GetSecondaryAttackDelay())

    // Play the attack animation on the character.
    player:SetOverlayAnimation( chooseWeightedEntry(Fade.kAnimStabTable) )

    Shared.PlaySound(player, Stomp.kStabSound)

    return true
    
end

Shared.LinkClassToMap("Stomp", Stomp.kMapName, {} )
