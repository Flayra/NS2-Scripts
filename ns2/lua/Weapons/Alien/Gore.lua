// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Gore.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Basic goring attack. Can also be used to smash down locked or welded doors.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Gore' (Ability)

Gore.kMapName = "gore"

Gore.kAttackSound = PrecacheAsset("sound/ns2.fev/alien/onos/gore")
Gore.kHitMaterialSoundSpec = "sound/ns2.fev/alien/onos/gore_hit_%s"

Gore.kDoorHitEffect = PrecacheAsset("cinematics/alien/onos/door_hit.cinematic")

// View model animations
Gore.kAnimAttackTable = {{1, "attack"}/*, {1, "attack2"}, {1, "attack3"}, {1, "attack4"}*/}

// Player animations
Gore.kAnimPlayerAttack = "gore"

// Balance
Gore.kDamage = kGoreDamage
Gore.kRange = 2.2           // From NS1
Gore.kStunTime = 2.5        
Gore.kKnockbackForce = 8

// Primary
Gore.kPrimaryEnergyCost = kGoreEnergyCost
Gore.kPrimaryAttackDelay = kGoreFireDelay

// Secondary
Gore.kSecondaryEnergyCost = 10
Gore.kSecondaryAttackDelay = 3         

function Gore:GetPrimaryEnergyCost(player)
    return Gore.kPrimaryEnergyCost
end

function Gore:GetSecondaryEnergyCost(player)
    return Gore.kSecondaryEnergyCost
end

function Gore:GetPrimaryAttackDelay()
    return Gore.kPrimaryAttackDelay
end

function Gore:GetSecondaryAttackDelay()
    return Gore.kSecondaryAttackDelay
end

function Gore:GetHUDSlot()
    return 1
end

function Gore:GetIconOffsetY(secondary)
    return kAbilityOffset.Gore
end

function Gore:PerformPrimaryAttack(player)
    
    // Play random animation
    player:SetViewAnimation( Gore.kAnimAttackTable, nil, nil, 1 / player:AdjustAttackDelay(1) )
    player:SetActivityEnd(player:AdjustAttackDelay(self:GetPrimaryAttackDelay()))
    
    player:SetOverlayAnimation(Gore.kAnimPlayerAttack)

    Shared.PlaySound(player, Gore.kAttackSound)
    
    // Trace melee attack
    local didHit, trace = self:AttackMeleeCapsule(player, Gore.kDamage, Gore.kRange)
    if didHit then

        local hitObject = trace.entity
        local materialName = trace.surface
        
        // Play special hit sound depending on material
        local surface = trace.surface
        if(surface ~= "") then
            Shared.PlayWorldSound(nil, string.format(Gore.kHitMaterialSoundSpec, surface), nil, trace.endPoint)
        end
        
        if hitObject and hitObject:isa("Door") then
            Shared.CreateEffect(nil, Gore.kDoorHitEffect, nil, Coords.GetTranslation(trace.endPoint))
        end
        
        // Send marine flying back
        if Server and trace.entity and trace.entity:isa("Player") then
        
            local player = trace.entity
            
            local velocity = GetNormalizedVector(player:GetEyePos() - self:GetParent():GetOrigin()) * Gore.kKnockbackForce
            
            player:Knockback(velocity)
            
        end
        
    end
    
    return true
    
end

function Gore:PerformSecondaryAttack(player)
    
    // Play random animation
    player:SetViewAnimation(Gore.kAnimAttackTable, nil, nil, 1 / player:AdjustAttackDelay(1))
    player:SetActivityEnd(self:GetSecondaryAttackDelay())

    // Play the attack animation on the character.
    player:SetOverlayAnimation( chooseWeightedEntry(Onos.kAnimPlayerAttack) )

    Shared.PlaySound(player, Gore.kStabSound)
    
    return true
    
end

Shared.LinkClassToMap("Gore", Gore.kMapName, {} )
