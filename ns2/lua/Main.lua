// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/Main.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
//
// This script is loaded when the game first starts. It handles creation of
// the main menu.
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Globals.lua")
Script.Load("lua/MainMenu.lua")
Script.Load("lua/MenuManager.lua")

mods = { "ns2" }

maps = { }

local matchingFiles = { }
Shared.GetMatchingFileNames("maps/*.level", false, matchingFiles)

for _, mapFile in pairs(matchingFiles) do
    local _, _, filename = string.find(mapFile, "maps/(.*).level")
    local mapname = string.gsub(filename, 'ns2_', '', 1):gsub("^%l", string.upper)
    local tagged,_ = string.match(filename, "ns2_", 1)
    if tagged ~= nil then
        table.insert(maps, {["name"] = mapname, ["fileName"] = filename})
    end
end

/**
 * Called when the user types the "map" command at the console.
 */
function OnCommandMap(mapFileName)    
    MainMenu_HostGame(mapFileName)
end

/**
 * Called when the user types the "connect" command at the console.
 */
function OnCommandConnect(address, password)
    MainMenu_SBJoinServer(address, password)
end

/**
 * Called when the user types the "exit" command at the console or clicks the exit button.
 */
function OnCommandExit()
    Client.Exit()
end

function OnClientConnected()
end

/**
 * Called when the client is disconnected from the server.
 */
function OnClientDisconnected(reason)

    // Clean up the render objects we created during the level load.
    DestroyLevelObjects()
    
    // Destroy all game-level flash players
    RemoveFlashPlayers(true)
    
    // Destroy all shared GUIs
    GetGUIManager():DestroyGUIScriptSingle("GUICrosshair")
    GetGUIManager():DestroyGUIScriptSingle("GUIScoreboard")
    GetGUIManager():DestroyGUIScriptSingle("GUINotifications")
    GetGUIManager():DestroyGUIScriptSingle("GUIRequests")
    GetGUIManager():DestroyGUIScriptSingle("GUIDamageIndicators")
    GetGUIManager():DestroyGUIScriptSingle("GUIDeathMessages")
    GetGUIManager():DestroyGUIScriptSingle("GUIChat")
    GetGUIManager():DestroyGUIScriptSingle("GUIVoiceChat")
    GetGUIManager():DestroyGUIScriptSingle("GUIMinimap")
    GetGUIManager():DestroyGUIScriptSingle("GUIMapAnnotations")
    // Marine GUIs
    GetGUIManager():DestroyGUIScriptSingle("GUIMarineHUD")
    GetGUIManager():DestroyGUIScriptSingle("GUIWaypoints")
    GetGUIManager():DestroyGUIScriptSingle("GUIPickups")
    GetGUIManager():DestroyGUIScriptSingle("GUISquad")
    // Alien GUIs
    GetGUIManager():DestroyGUIScriptSingle("GUIAlienHUD")
    GetGUIManager():DestroyGUIScriptSingle("GUIHiveBlips")
    
    // Destroy graphical debug text items
    for index, item in ipairs(gDebugTextList) do
        GetGUIManager():DestroyGUIScript(item)
    end
    
    // Some items and scripts expected at the main menu.
    // Disabled the warnings until the missing GUIItem is accounted for.
    local expectedItems = 2
    if GUI.GetNumItems() ~= expectedItems then
        //Shared.Message("Warning: " .. GUI.GetNumItems() .. " active GUIItems detected at the main menu! " .. expectedItems .. " are expected.")
    end
    local expectedScripts = 1
    // At this point there should be no GUIScripts active.
    if GetGUIManager():GetNumberScripts() ~= expectedScripts then
        //Shared.Message("Warning: " .. GetGUIManager():GetNumberScripts() .. " active GUIScripts detected at the main menu! " .. expectedScripts .. " are expected.")
    end
    
    // Restore the main menu.
    Client.SetCursor("ui/Cursor_MenuDefault.dds")
    Client.SetMouseVisible(true)
    Client.SetMouseCaptured(false)
    
    MenuManager.SetMenu( kMainMenuFlash )
    MainMenu_SetAlertMessage(reason)
    
end

/**
 * This is called if the user tries to join a server through the
 * Steam UI.
 */
function OnConnectRequested(address, password)
    MainMenu_SBJoinServer(address, password)
end

Event.Hook("ConnectRequested", OnConnectRequested)
Event.Hook("Console_connect",  OnCommandConnect)
Event.Hook("Console_map",  OnCommandMap)
Event.Hook("Console_exit", OnCommandExit)
Event.Hook("Console_quit", OnCommandExit)
Event.Hook("ClientDisconnected", OnClientDisconnected)
Event.Hook("ClientConnected", OnClientConnected)

Client.SetCursor("ui/Cursor_MenuDefault.dds")
MenuManager.SetMenu( kMainMenuFlash )