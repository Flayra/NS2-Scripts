// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Parasite.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
// 
// Parasite attack to mark enemies on hive sight
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Parasite' (Ability)

Parasite.kMapName = "parasite"

Parasite.kDelay = kParasiteFireDelay
Parasite.kDamage = kParasiteDamage
Parasite.kRange = 1000

function Parasite:GetEnergyCost(player)
    return kParasiteEnergyCost
end

function Parasite:GetHasSecondary(player)
    return false
end

function Parasite:GetHUDSlot()
    return 2
end

function Parasite:GetIconOffsetY(secondary)
    return kAbilityOffset.Parasite
end

function Parasite:GetPrimaryAttackRequiresPress()
    return true
end

function Parasite:PerformPrimaryAttack(player)
    
    player:SetActivityEnd(player:AdjustAttackDelay(Parasite.kDelay))

    // Trace ahead to see if hit enemy player or structure
    if Server then
    
        local viewCoords = player:GetViewAngles():GetCoords()
        local startPoint = player:GetEyePos()
    
        local trace = Shared.TraceRay(startPoint, startPoint + viewCoords.zAxis * Parasite.kRange, PhysicsMask.AllButPCs, EntityFilterTwo(self, player))
        
        if (trace.fraction < 1 and trace.entity ~= nil) then
        
            local hitObject = trace.entity
            
            if hitObject:isa("ScriptActor") and GetGamerules():CanEntityDoDamageTo(player, hitObject) then

                local direction = GetNormalizedVector(trace.endPoint - startPoint)
                hitObject:TakeDamage(Parasite.kDamage, player, self, trace.endPoint, direction)
                
                hitObject:TriggerEffects("parasite_hit")
                
                // Mark player or structure 
                if not hitObject:GetGameEffectMask(kGameEffect.Parasite) then
                
                    hitObject:SetGameEffectMask(kGameEffect.Parasite, true)
                    
                    // Reward player
                    if player:GetTeamNumber() == GetEnemyTeamNumber(hitObject:GetTeamNumber()) then
                        player:AddScore(1)
                    end
                    
                end
                
            end
            
        end
        
    end
    
    return true
end

Shared.LinkClassToMap("Parasite", Parasite.kMapName, {} )
