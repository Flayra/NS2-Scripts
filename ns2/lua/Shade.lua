// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shade.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides cloaking abilities and confuse and deceive capabilities.
//
// Disorient (Passive) - Enemy structures and players flicker in and out when in range of Shade, 
// making it hard for Commander and team-mates to be able to support each other. Extreme reverb 
// sounds for enemies (and slight reverb sounds for friendlies) enhance the effect.
//
// Cloak (Triggered) - Instantly cloaks self and all enemy structures and aliens in range
// for a short time. Mutes or changes sounds too? Cleverly used, this would ideally allow a 
// team to get a stealth hive built. Allow players to stay cloaked for awhile, until they attack
// (even if they move out of range - great for getting by sentries).
//
// Phantasm (Targeted) - Allow Commander to create fake Fade, Onos, Hive (and possibly 
// ammo/medpacks). They can be pathed around and used to create tactical distractions or divert 
// forces elsewhere.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Shade' (Structure)

Shade.kMapName = "shade"

Shade.kModelName = PrecacheAsset("models/alien/shade/shade.model")

Shade.kCloakDuration = 45
Shade.kCloakRadius = 15

// when cloak is triggered, we cloak everything around us at this interval
Shade.kActiveThinkInterval = 3


function Shade:GetIsAlienStructure()
    return true
end

function Shade:GetTechButtons(techId)

    local techButtons = nil
    
    if techId == kTechId.RootMenu then 
    
        techButtons = { kTechId.UpgradesMenu, kTechId.ShadeDisorient, kTechId.ShadeCloak, kTechId.ShadePhantasmMenu }
        
        // Allow structure to be upgraded to mature version
        local upgradeIndex = table.maxn(techButtons) + 1
        
        if(self:GetTechId() == kTechId.Shade) then
            techButtons[upgradeIndex] = kTechId.MatureShade
        end
       
    elseif techId == kTechId.UpgradesMenu then 
    
        techButtons = {kTechId.CamouflageTech, kTechId.FeintTech, kTechId.None}
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
        
    elseif techId == kTechId.ShadePhantasmMenu then        
    
        techButtons = {kTechId.ShadePhantasmFade, kTechId.ShadePhantasmOnos, kTechId.ShadePhantasmHive}
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu

    end
    
    return techButtons
    
end

function Shade:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)

    if success then
    
        // Transform into mature shade
        if structure and (structure:GetId() == self:GetId()) and (researchId == kTechId.UpgradeShade) then
        
            success = self:Upgrade(kTechId.MatureShade)
            
        end
    
    end
    
    return success
    
end

function Shade:GetTimeLeft()
    return self.cloakTriggerTime and self.cloakTriggerTime + Shade.kCloakDuration - Shared.GetTime() or -1
end

function Shade:OnThink()

    Structure.OnThink(self)
    
    local timeLeft = self:GetTimeLeft()

    if timeLeft > 0 then
    
        self:TriggerEffects("shade_cloak_start")
    
        for index, entity in ipairs(GetEntitiesForTeamWithinRange("LiveScriptActor", self:GetTeamNumber(), self:GetOrigin(), Shade.kCloakRadius)) do
        
            if HasMixin(entity, "Cloakable") and entity:GetIsCloakable() then

                entity:SetIsCloaked(true, timeLeft, true)
                    
            end
            
        end

        // when we have no time left, we stop thinking
        self:SetNextThink(Shade.kActiveThinkInterval)
        
    end
    
end

function Shade:TriggerCloak()
    
    // don't allow triggering while already cloaking

    if self:GetTimeLeft() <= 0 then

        self.cloakTriggerTime = Shared.GetTime()

        self:SetNextThink(0.01)
    
        return true
        
    end
    
    return false
    
end

function Shade:GetActivationTechAllowed(techId)
    // Passive ability, just here for the tooltip
    if techId == kTechId.ShadeDisorient then
        return false
    end

    return true
end

function Shade:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.ShadeCloak then
    
        success = self:TriggerCloak()    
    
    end
    
    return success
    
end

// Don't check in, just for testing
/*
function Shade:OnUse(player, elapsedTime, useAttachPoint, usePoint)
    if Server and Shared.GetDevMode() then
        self:TriggerCloak()
    end
    Structure.OnUse(self, player, elapsedTime, useAttachPoint, usePoint)
end
*/

Shared.LinkClassToMap("Shade", Shade.kMapName,  {} )

class 'MatureShade' (Shade)

MatureShade.kMapName = "matureshade"

Shared.LinkClassToMap("MatureShade", MatureShade.kMapName, {})

if Server then


    function OnConsoleCloak()
    
        if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
            local shades = EntityListToTable(Shared.GetEntitiesWithClassname("Shade"))
            if #shades > 0 then
                shades[1]:TriggerCloak()
            end
        end
        
    end
    
    Event.Hook("Console_cloak", OnConsoleCloak)
    
end