// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SwipeBlink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Swipe/blink - Left-click to attack, right click to show ghost. When ghost is showing,
// right click again to go there. Left-click to cancel. Attacking many times in a row will create
// a cool visual "chain" of attacks, showing the more flavorful animations in sequence.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'SwipeBlink' (Blink)
SwipeBlink.kMapName = "swipe"

local networkVars =
{
    lastSwipedEntityId = "entityid"
}

// TODO: Hold shift for "rebound" type ability. Shift while looking at enemy lets you blink above, behind or off of a wall.

SwipeBlink.kHitMarineSound = PrecacheAsset("sound/ns2.fev/alien/fade/swipe_hit_marine")
SwipeBlink.kScrapeMaterialSound = "sound/ns2.fev/materials/%s/scrape"
PrecacheMultipleAssets(SwipeBlink.kScrapeMaterialSound, kSurfaceList)

// Make sure to keep damage vs. structures less then Skulk
SwipeBlink.kSwipeEnergyCost = kSwipeEnergyCost
SwipeBlink.kPrimaryAttackDelay = kSwipeFireDelay
SwipeBlink.kDamage = kSwipeDamage
SwipeBlink.kRange = 1.5

function SwipeBlink:OnInit()

    Blink.OnInit(self)
    
    self.lastSwipedEntityId = Entity.invalidId

end

function SwipeBlink:GetEnergyCost(player)
    return SwipeBlink.kSwipeEnergyCost
end

function SwipeBlink:GetHasSecondary(player)
    return true
end

function SwipeBlink:GetPrimaryAttackDelay()
    return SwipeBlink.kPrimaryAttackDelay
end

function SwipeBlink:GetHUDSlot()
    return 1
end

function SwipeBlink:GetIconOffsetY(secondary)
    return kAbilityOffset.SwipeBlink
end

function SwipeBlink:GetPrimaryAttackRequiresPress()
    return false
end

function SwipeBlink:GetDeathIconIndex()
    return kDeathMessageIcon.SwipeBlink
end

// Claw attack, or blink if we're in that mode
function SwipeBlink:PerformPrimaryAttack(player)
    
    // Delete ghost
    Blink.PerformPrimaryAttack(self, player)

    // Play random animation
    player:SetActivityEnd( player:AdjustAttackDelay(self:GetPrimaryAttackDelay() ))
    
    // Check if the swipe may hit an entity. Don't actually do any damage yet.
    local didHit, trace = self:CheckMeleeCapsule(player, SwipeBlink.kDamage, SwipeBlink.kRange)
    self.lastSwipedEntityId = Entity.invalidId
    if didHit and trace and trace.entity then
        self.lastSwipedEntityId = trace.entity:GetId()
    end
    
    return true
    
end

function SwipeBlink:OnTag(tagName)

    Blink.OnTag(self, tagName)
    
    if tagName == "hit" then
        self:PerformMeleeAttack()
    end

end

function SwipeBlink:PerformMeleeAttack()

    local player = self:GetParent()
    if player then
    
        // Trace melee attack
        local didHit, trace = self:AttackMeleeCapsule(player, SwipeBlink.kDamage, SwipeBlink.kRange)
        if didHit then

            local hitObject = trace.entity
            local materialName = trace.surface
            
            if hitObject ~= nil then
            
                if hitObject:isa("Marine") then
                    Shared.PlaySound(player, SwipeBlink.kHitMarineSound)
                else
                
                    // Play special bite hit sound depending on material
                    local surface = trace.surface
                    if(surface ~= "") then
                        Shared.PlayWorldSound(nil, string.format(SwipeBlink.kScrapeMaterialSound, surface), nil, trace.endPoint)
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

function SwipeBlink:GetEffectParams(tableParams)

    Blink.GetEffectParams(self, tableParams)
    
    // There is a special case for biting structures.
    if self.lastSwipedEntityId ~= Entity.invalidId then
        local lastSwipedEntity = Shared.GetEntity(self.lastSwipedEntityId)
        if lastSwipedEntity and lastSwipedEntity:isa("Structure") then
            tableParams[kEffectFilterHitSurface] = "structure"
        end
    end
    
end

Shared.LinkClassToMap("SwipeBlink", SwipeBlink.kMapName, networkVars )
