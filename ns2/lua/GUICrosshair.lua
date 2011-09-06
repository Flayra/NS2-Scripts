
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICrosshair.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the crosshairs for aliens and marines.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICrosshair' (GUIScript)

GUICrosshair.kFontSize = 20
GUICrosshair.kTextFadeTime = 0.25
GUICrosshair.kCrosshairSize = 64
GUICrosshair.kTextYOffset = -40
GUICrosshair.kTextureWidth = 64
GUICrosshair.kTextureHeight = 1024

GUICrosshair.kInvisibleColor = Color(0, 0, 0, 0)
GUICrosshair.kVisibleColor = Color(1, 1, 1, 1)

function GUICrosshair:Initialize()

    self.crosshairs = GUIManager:CreateGraphicItem()
    self.crosshairs:SetSize(Vector(GUICrosshair.kCrosshairSize, GUICrosshair.kCrosshairSize, 0))
    self.crosshairs:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.crosshairs:SetPosition(Vector(-GUICrosshair.kCrosshairSize / 2, -GUICrosshair.kCrosshairSize / 2, 0))
    self.crosshairs:SetTexture("ui/crosshairs.dds")
    self.crosshairs:SetIsVisible(false)
    
    self.damageIndicator = GUIManager:CreateGraphicItem()
    self.damageIndicator:SetSize(Vector(GUICrosshair.kCrosshairSize, GUICrosshair.kCrosshairSize, 0))
    self.damageIndicator:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.damageIndicator:SetPosition(Vector(0, 0, 0))
    self.damageIndicator:SetTexture("ui/crosshairs.dds")
    local yCoord = PlayerUI_GetCrosshairDamageIndicatorY()
    self.damageIndicator:SetTexturePixelCoordinates(0, yCoord,
                                                    64, yCoord + 64)
    self.damageIndicator:SetIsVisible(false)
    self.crosshairs:AddChild(self.damageIndicator)

    self.crosshairsText = GUIManager:CreateTextItem()
    self.crosshairsText:SetFontSize(GUICrosshair.kFontSize)
    self.crosshairsText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.crosshairsText:SetTextAlignmentX(GUIItem.Align_Center)
    self.crosshairsText:SetTextAlignmentY(GUIItem.Align_Center)
    self.crosshairsText:SetPosition(Vector(0, GUICrosshair.kTextYOffset, 0))
    self.crosshairsText:SetColor(Color(1, 1, 1, 1))
    self.crosshairsText:SetText("")
    self.crosshairs:AddChild(self.crosshairsText)
    
    self.currAlpha = 0

end

function GUICrosshair:Uninitialize()

    // Destroying the crosshair will destroy all it's children too.
    GUI.DestroyItem(self.crosshairs)
    self.crosshairs = nil
    self.crosshairsText = nil
    
end

function GUICrosshair:Update(deltaTime)

    PROFILE("GUICrosshair:Update")

    // Update crosshair image.
    local xCoord = PlayerUI_GetCrosshairX()
    local yCoord = PlayerUI_GetCrosshairY()
    self.crosshairs:SetIsVisible(true)
    self.crosshairs:SetColor(GUICrosshair.kInvisibleColor)
    if PlayerUI_GetCrosshairWidth() == 0 then
        self.crosshairs:SetColor(GUICrosshair.kInvisibleColor)
    elseif xCoord and yCoord then
        self.crosshairs:SetColor(GUICrosshair.kVisibleColor)
        self.crosshairs:SetTexturePixelCoordinates(xCoord, yCoord,
                                                   xCoord + PlayerUI_GetCrosshairWidth(), yCoord + PlayerUI_GetCrosshairHeight())
    end
    
    // Update crosshair text.
    local currentColor = ColorIntToColor(PlayerUI_GetCrosshairTextColor())
    local setText = PlayerUI_GetCrosshairText()
    local fadingIn = string.len(setText) > 0
    if fadingIn then
        self.crosshairsText:SetText(setText)
        self.currAlpha = math.min(1, self.currAlpha + deltaTime * (1 / GUICrosshair.kTextFadeTime))
    else
        self.currAlpha = math.max(0, self.currAlpha - deltaTime * (1 / GUICrosshair.kTextFadeTime))
    end
    currentColor.a = self.currAlpha
    self.crosshairsText:SetColor(currentColor)
    
    // Update give damage indicator.
    local indicatorVisible, timePassedPercent = PlayerUI_GetShowGiveDamageIndicator()
    self.damageIndicator:SetIsVisible(indicatorVisible)
    self.damageIndicator:SetColor(Color(1, 1, 1, 1 - timePassedPercent))
    
end
