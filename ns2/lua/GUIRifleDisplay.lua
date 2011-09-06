// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIRifleDisplay.lua
//
// Created by: Max McGuire (max@unknownworlds.com)
//
// Displays the ammo and grenade counter for the rifle.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIBulletDisplay.lua")
Script.Load("lua/GUIGrenadeDisplay.lua")

// Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0

bulletDisplay  = nil
grenadeDisplay = nil

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    PROFILE("GUIRifleDisplay Update")

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
    bulletDisplay:Update(deltaTime)
    
    grenadeDisplay:SetNumGrenades(weaponAuxClip)
    grenadeDisplay:Update(deltaTime)
    
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( 256, 417 )

    bulletDisplay = GUIBulletDisplay()
    bulletDisplay:Initialize()
    bulletDisplay:SetClipSize(50)

    grenadeDisplay = GUIGrenadeDisplay()
    grenadeDisplay:Initialize()

end

Initialize()