// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shift.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that allows commander to outmaneuver and redeploy forces. 
//
// Recall - Ability that lets players jump to nearest structure (or hive) under attack (cooldown 
// of a few seconds)
// Energize - Triggered ability that gives energy to nearby players and structures
// Echo - Targeted ability that lets Commander move a structure or drifter elsewhere on the map
// (even a hive or harvester!). 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'Shift' (Structure)

Shift.kMapName = "shift"

Shift.kModelName = PrecacheAsset("models/alien/shift/shift.model")

Shift.kEchoSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/echo")
Shift.kEnergizeSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/energize")
Shift.kEnergizeTargetSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/energize_player")
//Shift.kRecallSoundEffect = PrecacheAsset("sound/ns2.fev/alien/structures/shift/recall")

Shift.kEchoEffect = PrecacheAsset("cinematics/alien/shift/echo.cinematic")
Shift.kEnergizeEffect = PrecacheAsset("cinematics/alien/shift/energize.cinematic")
Shift.kEnergizeSmallTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_small.cinematic")
Shift.kEnergizeLargeTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_large.cinematic")

function Shift:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function Shift:GetIsAlienStructure()
    return true
end

function Shift:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.UpgradesMenu, kTechId.ShiftRecall, kTechId.ShiftEnergize, kTechId.Attack }
        
        // Allow structure to be upgraded to mature version
        local upgradeIndex = table.maxn(techButtons) + 1
        
        if(self:GetTechId() == kTechId.Shift) then
            techButtons[upgradeIndex] = kTechId.UpgradeShift
        else
            techButtons[upgradeIndex] = kTechId.ShiftEcho
        end
       
    elseif(techId == kTechId.UpgradesMenu) then 
        techButtons = {kTechId.AdrenalineTech, kTechId.StompTech, kTechId.None, kTechId.None}        
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
    end
    
    return techButtons
    
end

function Shift:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success then
    
        // Transform into mature shift
        if structure and (structure:GetId() == self:GetId()) and (researchId == kTechId.UpgradeShift) then
        
            success = self:UpgradeToTechId(kTechId.MatureShift)
            
        end
        
    end
    
    return success
    
end

function Shift:TriggerEcho(position)
    return false
end

function Shift:TriggerEnergize()

    Shared.CreateEffect(nil, Shift.kEnergizeEffect, self)
    self:PlaySound(Shift.kEnergizeSoundEffect)

    local ents = GetEntitiesWithMixinForTeamWithinRange("GameEffects", self:GetTeamNumber(), self:GetOrigin(), kEnergizeRange)
    table.removevalue(ents, self)
    
    for index, ent in ipairs(ents) do
    
        local effectName = ConditionalValue(ent:isa("Hive") or ent:isa("Onos"), Shift.kEnergizeLargeTargetEffect, Shift.kEnergizeSmallTargetEffect)
        Shared.CreateEffect(nil, effectName, ent)
        
        ent:PlaySound(Shift.kEnergizeTargetSoundEffect)
        
        ent:AddStackableGameEffect(kEnergizeGameEffect, kEnergizeDuration, self)
        
    end
    
    return true
    
end

function Shift:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.ShiftEcho then
        success = self:TriggerEcho(position)
    elseif techId == kTechId.ShiftEnergize then
        success = self:TriggerEnergize()
    end
    
    return success
    
end

Shared.LinkClassToMap("Shift", Shift.kMapName, {})

class 'MatureShift' (Shift)

MatureShift.kMapName = "matureshift"

Shared.LinkClassToMap("MatureShift", MatureShift.kMapName, {})