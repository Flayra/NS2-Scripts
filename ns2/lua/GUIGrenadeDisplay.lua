// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIGrenadeDisplay.lua
//
// Created by: Max McGuire (max@unknownworlds.com)
//
// Displays the current number of grenades for the grenade launcher
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")

class 'GUIGrenadeDisplay'

GUIGrenadeDisplay.kIndicatorWidth = 58
GUIGrenadeDisplay.kIndicatorHeight = 15

GUIGrenadeDisplay.kIndicatorXOffset = 6
GUIGrenadeDisplay.kIndicatorYBaseOffset = 267
GUIGrenadeDisplay.kIndicatorYExtraOffset = 18

// Should be the same value as GrenadeLauncher.kLauncherStartingAmmo.
GUIGrenadeDisplay.kMaxGrenades = 8

GUIGrenadeDisplay.kFullGrenadeCoords = { X1 = 77, Y1 = 266, X2 = 135, Y2 = 286 }
GUIGrenadeDisplay.kEmptyGrenadeCoords = { X1 = 77, Y1 = 287, X2 = 135, Y2 = 307 }

function GUIGrenadeDisplay:Initialize()
    
    self.numGrenades = 0
    
    self.grenade = { }

    // Create the grenade indicators.
    for i = 1, GUIGrenadeDisplay.kMaxGrenades do
        self.grenade[i] = GUIManager:CreateGraphicItem()
        self.grenade[i]:SetTexture("ui/RifleDisplay.dds")
        self.grenade[i]:SetSize( Vector(GUIGrenadeDisplay.kIndicatorWidth, GUIGrenadeDisplay.kIndicatorHeight, 0) )
        self.grenade[i]:SetPosition( Vector(GUIGrenadeDisplay.kIndicatorXOffset, GUIGrenadeDisplay.kIndicatorYBaseOffset + (GUIGrenadeDisplay.kIndicatorYExtraOffset * (i - 1)), 0 ) )
        GUISetTextureCoordinatesTable(self.grenade[i], GUIGrenadeDisplay.kFullGrenadeCoords)
    end
 
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUIGrenadeDisplay:Update(deltaTime)

    PROFILE("GUIGrenadeDisplay:Update")
    
    for i = 1, GUIGrenadeDisplay.kMaxGrenades do
        // We subtract one from the aux weapon clip, because one grenade is
        // in the chamber.
        local coords = GUIGrenadeDisplay.kEmptyGrenadeCoords
        if self.numGrenades >= GUIGrenadeDisplay.kMaxGrenades - i + 1 then
            coords = GUIGrenadeDisplay.kFullGrenadeCoords
        end
        GUISetTextureCoordinatesTable(self.grenade[i], coords)
    end

end

function GUIGrenadeDisplay:SetNumGrenades(numGrenades)
    self.numGrenades = numGrenades
end
