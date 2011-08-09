//=============================================================================
//
// lua/MenuManager.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

MenuManager = { }
MenuManager.menuFlashPlayer = nil
MenuManager.menuCinematic   = nil

MenuManager.ScreenScaleAspect = 1280
function MenuManager.ScreenSmallAspect()

	local screenWidth = Client.GetScreenWidth()
	local screenHeight = Client.GetScreenHeight()
	return ConditionalValue(screenWidth > screenHeight, screenHeight, screenWidth)

end

/**
 * Sets a Flash movie as the main menu.
 */
function MenuManager.SetMenu(fileName)

    if (MenuManager.menuFlashPlayer ~= nil) then
        Client.RemoveFlashPlayerFromDisplay(MenuManager.menuFlashPlayer)
        Client.DestroyFlashPlayer(MenuManager.menuFlashPlayer)
        MenuManager.menuFlashPlayer = nil
    end
    
    if (fileName ~= nil) then
        MenuManager.menuFlashPlayer = Client.CreateFlashPlayer()
        MenuManager.menuFlashPlayer:Load(fileName)
        Client.AddFlashPlayerToDisplay(MenuManager.menuFlashPlayer)
    end
    
end

/**
 * Returns the menu currently being displayed.
 */
function MenuManager.GetMenu()

    return MenuManager.menuFlashPlayer

end

/**
 * Sets the cinematic that's displayed behind the main menu.
 */
function MenuManager.SetMenuCinematic(fileName)

    if (MenuManager.menuCinematic ~= nil) then
        Client.DestroyCinematic(MenuManager.menuCinematic)
        MenuManager.menuCinematic = nil
    end

    if (fileName ~= nil) then
        MenuManager.menuCinematic = Client.CreateCinematic()
        MenuManager.menuCinematic:SetRepeatStyle(Cinematic.Repeat_Loop)
        MenuManager.menuCinematic:SetCinematic(fileName)
    end

end

function MenuManager.GetCinematicCamera()
    // Try to get the camera from the cinematic.
    if (MenuManager.menuCinematic ~= nil) then
        return MenuManager.menuCinematic:GetCamera()
    else
        return false
    end
end


function MenuManager.PlayMusic(fileName)

    Client.PlayMusic(fileName)
    
end

function MenuManager.StopMusic(fileName)

    Client.StopMusic(fileName)
    
end

function MenuManager.PlaySound(fileName)

    Shared.PlaySound(nil, fileName)
    
end

function MenuManager.StopSound(fileName)   

    Shared.StopSound(nil, fileName)
    
end
