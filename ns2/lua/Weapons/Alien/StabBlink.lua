// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\StabBlink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Left-click to stab (with both claws), right-click to do the massive rising up and 
// downward attack, with both claws. Insta-kill.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'StabBlink' (Blink)

StabBlink.kMapName = "stab"

StabBlink.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/fade/stab_marine")
StabBlink.kImpaleSound = PrecacheAsset("sound/ns2.fev/alien/fade/impale")
StabBlink.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"
PrecacheMultipleAssets(StabBlink.kScrapeMaterialSound, kSurfaceList)

// Balance
StabBlink.kDamage = kStabDamage
StabBlink.kPrimaryAttackDelay = kStabFireDelay
StabBlink.kPrimaryEnergyCost = kStabEnergyCost
StabBlink.kDamageType = kStabDamageType
StabBlink.kRange = 1
StabBlink.kStabDuration = 1

function StabBlink:GetPrimaryEnergyCost(player)
    return StabBlink.kPrimaryEnergyCost
end

function StabBlink:GetHUDSlot()
    return 2
end

function StabBlink:GetDeathIconIndex()
    return kDeathMessageIcon.SwipeBlink
end

function StabBlink:GetPrimaryAttackDelay()
    return StabBlink.kPrimaryAttackDelay
end

function StabBlink:GetIconOffsetY(secondary)
    return kAbilityOffset.StabBlink
end

function StabBlink:GetPrimaryAttackRequiresPress()
    return false
end

function StabBlink:PerformPrimaryAttack(player)
    
    Blink.PerformPrimaryAttack(self, player)
    
    // Play random animation
    player:SetActivityEnd(player:AdjustAttackDelay(self:GetPrimaryAttackDelay()))

    player:SetAnimAndMode(chooseWeightedEntry(Fade.kAnimStabTable), kPlayerMode.FadeStab)
    return true
end

function StabBlink:OnTag(tagName)

    Blink.OnTag(self, tagName)
    
    if tagName == "hit" then
        self:PerformMeleeAttack()
    end

end

function StabBlink:PerformMeleeAttack()

    local player = self:GetParent()
    if player then
    
        // Trace melee attack
        local didHit, trace = self:AttackMeleeCapsule(player, StabBlink.kDamage, StabBlink.kRange)
        if didHit then

            local hitObject = trace.entity
            
            if hitObject ~= nil then
            
                if hitObject:isa("Marine") then
                
                    if hitObject:GetIsAlive() then
                        Shared.PlaySound(player, StabBlink.kHitMarineSound)
                    else
                        Shared.PlaySound(player, StabBlink.kImpaleSound)
                    end
                    
                else
                
                    // Play special stab hit sound depending on material
                    local surface = trace.surface
                    if(surface ~= "") then
                        Shared.PlayWorldSound(nil, string.format(StabBlink.kScrapeMaterialSound, surface), nil, trace.endPoint)
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

Shared.LinkClassToMap("StabBlink", StabBlink.kMapName, {} )
