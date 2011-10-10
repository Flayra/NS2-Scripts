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

// Balance
Gore.kRange = 2.2           // From NS1
Gore.kKnockbackForce = 8

function Gore:GetEnergyCost(player)
    return kGoreEnergyCost
end

function Gore:GetPrimaryAttackDelay()
    return kGoreFireDelay
end

function Gore:GetHUDSlot()
    return 1
end

function Gore:GetIconOffsetY(secondary)
    return kAbilityOffset.Gore
end

function Gore:PerformPrimaryAttack(player)
    
    player:SetActivityEnd( player:AdjustAttackDelay(self:GetPrimaryAttackDelay()) )
    
    // Trace melee attack
    local didHit, trace = self:AttackMeleeCapsule(player, kGoreDamage, Gore.kRange)
    if didHit and Server then

        if trace.entity and trace.entity:isa("Door") then
        
            self:TriggerEffects("onos_door_hit")
        
        // Send marine flying back    
        elseif trace.entity and trace.entity:isa("Player") then
        
            local player = trace.entity
            local onosToPlayer = player:GetEyePos() - self:GetParent():GetOrigin()
            local velocity = GetNormalizedVector(onosToPlayer) * Gore.kKnockbackForce
            
            player:Knockback(velocity)
            
        end
        
    end
    
    return true
    
end

Shared.LinkClassToMap("Gore", Gore.kMapName, {} )
