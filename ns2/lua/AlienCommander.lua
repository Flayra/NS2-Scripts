// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienCommander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handled Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Commander.lua")
class 'AlienCommander' (Commander)
AlienCommander.kMapName = "alien_commander"

AlienCommander.kOrderClickedEffect = PrecacheAsset("cinematics/alien/order.cinematic")
AlienCommander.kSelectSound = PrecacheAsset("sound/ns2.fev/alien/commander/select")
AlienCommander.kChatSound = PrecacheAsset("sound/ns2.fev/alien/common/chat")
AlienCommander.kUpgradeCompleteSoundName = PrecacheAsset("sound/ns2.fev/alien/voiceovers/upgrade_complete")
AlienCommander.kResearchCompleteSoundName = PrecacheAsset("sound/ns2.fev/alien/voiceovers/research_complete")
AlienCommander.kStructureUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/structure_under_attack")
AlienCommander.kHarvesterUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/harvester_under_attack")
AlienCommander.kLifeformUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/lifeform_under_attack")
AlienCommander.kCommanderEjectedSoundName = PrecacheAsset("sound/ns2.fev/alien/voiceovers/commander_ejected")

function AlienCommander:GetSelectionSound()
    return AlienCommander.kSelectSound
end

function AlienCommander:GetTeamType()
    return kAlienTeamType
end

function AlienCommander:GetOrderConfirmedEffect()
    return AlienCommander.kOrderClickedEffect
end

if Client then

    function AlienCommander:SetupHud()

        Commander.SetupHud(self)
        
    end

    function AlienCommander:OnInitLocalClient()

        Commander.OnInitLocalClient(self)
        
        if self.hiveBlips == nil then
            self.hiveBlips = GetGUIManager():CreateGUIScript("GUIHiveBlips")
        end

    end

end

function AlienCommander:OnDestroy()
    
    if Client and self.hiveBlips then
    
        GetGUIManager():DestroyGUIScript(self.hiveBlips)
        self.hiveBlips = nil
        
    end
    
    Commander.OnDestroy(self)

end

function AlienCommander:SetSelectionCircleMaterial(entity)
 
    if(entity:isa("Structure") and not entity:GetIsBuilt()) then
    
        SetMaterialFrame("alienBuild", entity.buildFraction)

    else

        // Allow entities without health to be selected (infest nodes)
        local healthPercent = 1
        if(entity.health ~= nil and entity.maxHealth ~= nil) then
            healthPercent = entity.health / entity.maxHealth
        end
        
        SetMaterialFrame("alienHealth", healthPercent)
        
    end
   
end

function AlienCommander:GetChatSound()
    return AlienCommander.kChatSound
end

function AlienCommander:GetPlayerStatusDesc()
    return "Commander"
end

Shared.LinkClassToMap( "AlienCommander", AlienCommander.kMapName, {} )