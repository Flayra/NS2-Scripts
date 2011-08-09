//=============================================================================
//
// lua/AlienUpgrades_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// Number if icons in each row of Alien.kUpgradeIconsTexture
local kUpgradeIconRowSize = 6

// The order of icons in Alien.kUpgradeIconsTexture
local kIconIndexToUpgradeId = {
    kTechId.AlienArmor1Tech, kTechId.AlienArmor2Tech, kTechId.AlienArmor3Tech, kTechId.Melee1Tech, kTechId.Melee2Tech, kTechId.Melee3Tech, 
    kTechId.DrifterFlareTech, kTechId.DrifterParasiteTech, kTechId.Swarm, kTechId.Frenzy, kTechId.Carapace, kTechId.Regeneration,
    kTechId.HydraAbility, kTechId.None, kTechId.Adrenaline, kTechId.Piercing, kTechId.Feint, kTechId.Sap, 
    kTechId.Stomp, kTechId.BoneShield, kTechId.Leap, kTechId.None, kTechId.None, kTechId.None, 
}

function GetAlienUpgradeIconXY(techId)

    for index, id in ipairs(kIconIndexToUpgradeId) do
    
        if id == techId then
        
            return true, (index - 1) % kUpgradeIconRowSize, math.floor((index - 1)/ kUpgradeIconRowSize)
            
        end    
        
    end
    
    Print("GetUpgradeIconXY(%s): Invalid techId passed.", EnumToString(kTechId, techId))
    return false, 0, 0
    
end

