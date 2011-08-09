//=============================================================================
//
// lua/Commander_PlayerAlertPanel.lua
// 
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Return the number of idle workers
 */
function CommanderUI_GetPlayerAlertCount()

    local player = Client.GetLocalPlayer()
    if player and player.GetNumPlayerAlerts then
        return player:GetNumPlayerAlerts()
    end
    return 0
    
end

/**
 * Get player alert icon (x,y) in linear array.
 * These coords are multiplied by 80. Also used
 * for "select all" players.
 */
function CommanderUI_GetPlayerAlertOffset()
    
    if Client.GetLocalPlayer():isa("AlienCommander") then
        return {0, 2}
    end
    
    return {0, 5}
    
end

/**
 * Indicates that user clicked on the idle worker
 */
function CommanderUI_ClickedPlayerAlert()
    
    Client.ConsoleCommand("gotoplayeralert")
    
end
