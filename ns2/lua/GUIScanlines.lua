
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIScanlines.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying animating scan lines used on the Marine commander UI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIScanlines' (GUIScript)

// Settings:
// settingsTable.Width
// settingsTable.Height
// The amount of extra space that will extend above the minimap.
// settingsTable.ExtraHeight

GUIScanlines.kScanlineTexture = "ui/marine_commander_scanlines.dds"
GUIScanlines.kTextureWidth = 468
GUIScanlines.kTextureHeight = 346

GUIScanlines.kDefaultColor = Color(1, 1, 1, 0.2)
GUIScanlines.kDisruptColor = Color(1, 1, 1, 1)

function GUIScanlines:Initialize(settingsTable)
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetSize(Vector(settingsTable.Width, settingsTable.Height + settingsTable.ExtraHeight, 0))
    self.background:SetPosition(Vector(0, -settingsTable.ExtraHeight, 0))
    self.background:SetTexture(GUIScanlines.kScanlineTexture)
    local textureHeight = GUIScanlines.kTextureHeight
    if settingsTable.Height < GUIScanlines.kTextureHeight then
        textureHeight = settingsTable.Height
    end
    self.background:SetColor(GUIScanlines.kDefaultColor)
    self.background:SetTexturePixelCoordinates(0, 0, GUIScanlines.kTextureWidth, textureHeight)

end

function GUIScanlines:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIScanlines:Disrupt()

    local animationPhase1 = GetGUIManager():StartAnimation(self.background, GUISetColor, GUIScanlines.kDefaultColor, GUIScanlines.kDisruptColor, .4)
    GetGUIManager():ChainAnimation(animationPhase1, .4, self.background, GUISetColor, GUIScanlines.kDisruptColor, GUIScanlines.kDefaultColor, .4)

end

function GUIScanlines:Update(deltaTime)

    PROFILE("GUIScanlines:Update")

    // Only marine commanders can see the scan lines.
    self.background:SetIsVisible(not CommanderUI_IsAlienCommander())

end

function GUIScanlines:GetBackground()

    return self.background

end
