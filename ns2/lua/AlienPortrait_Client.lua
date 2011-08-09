//=============================================================================
//
// lua/AlienPortrait_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================
local kPortraitIconIndices = {
    {0, 0}, {1, 0}, {2, 0}, {3, 0}, {4, 0}, {5, 0},
    {0, 1}, {1, 1}, {2, 1}, {3, 1}, {4, 1},
    {0, 2}, {1, 2}, {2, 2}, {3, 2}, {4, 2} 
}
    
// From alien portrait icons
local kIconIndexToTechId = {
    kTechId.Hive, kTechId.None, kTechId.None, kTechId.Harvester, kTechId.Drifter, kTechId.Egg,
    kTechId.Crag, kTechId.Whip, kTechId.Shift, kTechId.Shade, kTechId.Hydra,
    kTechId.Skulk, kTechId.Gorge, kTechId.Lerk, kTechId.Fade, kTechId.Onos
}

function GetPortraitIconOffsetsFromTechId(techId)

    for index, id in ipairs(kIconIndexToTechId) do
    
        if techId == id then

            local pair = kPortraitIconIndices[index]
            return true, pair[1], pair[2]        
            
        end
        
    end
    
    //Print("GetPortraitIconOffsetsFromTechId(%d) - Couldn't find icon (%s).", techId, LookupTechData(techId, kTechDataDisplayName))
    
    return false, nil, nil
    
end
