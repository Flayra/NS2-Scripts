//=============================================================================
//
// lua/Commander_SquadsPanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Return the number of squads
 */
function CommanderUI_GetTotalSquads()

    local numSquads = 0
    local squadList = Client.GetLocalPlayer():GetSortedSquadList()
    
    if squadList ~= nil then
        numSquads = table.count(squadList)
    end
    
    return numSquads
    
end

/**
 * Return name for squad at index
 */
function CommanderUI_GetSquadName(idx)
    return GetNameForSquad(idx)
end

/**
 * Return color for squad at index (RRGGBBAA)
 */
function CommanderUI_GetSquadColor(idx)

    return ColorArrayToInt(GetColorForSquad(idx))
    
end

/**
 * Called if user has clicked on the icon for one of the squads.
 */
function CommanderUI_SelectSquad(idx)
    Client.GetLocalPlayer():ClientSelectSquad(idx)    
end