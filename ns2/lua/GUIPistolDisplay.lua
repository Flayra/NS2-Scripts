// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIPistolDisplay.lua
//
// Created by: Max McGuire (max@unknownworlds.com)
//
// Displays the ammo and grenade counter for the rifle.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIBulletDisplay.lua")

// Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0

bulletDisplay  = nil

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
    bulletDisplay:Update(deltaTime)
    
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( 256, 256 )

    bulletDisplay = GUIBulletDisplay()
    bulletDisplay:Initialize()
    bulletDisplay:SetClipSize(10)

end

Initialize()