//=============================================================================
//
// lua/MainMenu.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2011, Unknown Worlds Entertainment
//
// This script is loaded when the game first starts. It handles creation of
// the main menu.
//=============================================================================

Script.Load("lua/InterfaceSounds_Client.lua")
Script.Load("lua/ServerBrowser.lua")
Script.Load("lua/CreateServer.lua")
Script.Load("lua/OptionsDialog.lua")
Script.Load("lua/BindingsDialog.lua")
Script.Load("lua/Update.lua")

local mainMenuMusic = "Main Menu"

local mainMenuAlertMessage  = nil

function LeaveMenu()

    MenuManager.SetMenu(nil)
    MenuManager.SetMenuCinematic(nil)
    MenuManager.StopMusic(mainMenuMusic)
    
    local localPlayer = Client.GetLocalPlayer()
    // Only make the mouse invisible if there is no local player
    // or that local player isn't a commander.
    if not localPlayer or not localPlayer:GetIsCommander() then
        Client.SetMouseVisible(false)
        Client.SetMouseCaptured(true)
    end
    
end

/**
 * Called when the user selects the "Host Game" button in the main menu.
 */
function MainMenu_HostGame(mapFileName, modName)
        
    local port       = 27015
    local maxPlayers = 16
    local password   = ""
    
    if (Client.StartServer( mapFileName, password, port, maxPlayers )) then
        LeaveMenu()
    end

end

function GetModName(mapFileName)

    for index, mapEntry in ipairs(maps) do
        if(mapEntry.fileName == mapFileName) then
            return mapEntry.modName
        end
    end
    
    return nil
    
end

/**
 * Returns true if we hit ESC while playing to display menu, false otherwise. 
 * Indicates to display the "Back to game" button.
 */
function MainMenu_IsInGame()
    return Client.GetIsConnected()    
end

/**
 * Called when button clicked to return to game.
 */
function MainMenu_ReturnToGame()
    LeaveMenu()
end

function MainMenu_Loaded()

    // Don't load anything unnecessary during development
    if(not MainMenu_IsInGame()) then
    
        MenuManager.SetMenuCinematic("cinematics/main_menu.cinematic")
        MenuManager.PlayMusic(mainMenuMusic)
        
    end
    
end

/**
 * Set a message that will be displayed in window in the main menu the next time
 * it's updated.
 */
function MainMenu_SetAlertMessage(alertMessage)
    mainMenuAlertMessage = alertMessage
end

/**
 * Called every frame to see if a dialog should be popped up.
 * Return string to show (one time, message should not continually be returned!)
 * Return "" or nil for no message to pop up
 */
function MainMenu_GetAlertMessage()

    local alertMessage = mainMenuAlertMessage
    mainMenuAlertMessage = nil
    
    return alertMessage
    
end

/**
 * Called when the user selects the "Quit" button in the main menu.
 */
function MainMenu_Quit()
    Client.Exit()
end