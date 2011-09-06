
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDial.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a circular dial. Used to show health, armor, progress, etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIDial' (GUIScript)

// Extra height buffer just to make sure everything is covered.
GUIDial.kMaskHeightBuffer = 5

function GUIDial:Initialize(settingsTable)

    self.percentage = 1
    
    // Background.
    self.dialBackground = GUIManager:CreateGraphicItem()
    self.dialBackground:SetSize(Vector(settingsTable.BackgroundWidth, settingsTable.BackgroundHeight, 0))
    self.dialBackground:SetAnchor(settingsTable.BackgroundAnchorX, settingsTable.BackgroundAnchorY)
    self.dialBackground:SetPosition(Vector(0, -settingsTable.BackgroundHeight, 0) + settingsTable.BackgroundOffset)
    if settingsTable.BackgroundTextureName ~= nil then
        self.dialBackground:SetTexture(settingsTable.BackgroundTextureName)
    else
        self.dialBackground:SetColor(Color(1, 1, 1, 0))
    end
    self.dialBackground:SetTexturePixelCoordinates(settingsTable.BackgroundTextureX1, settingsTable.BackgroundTextureY1,
                                                   settingsTable.BackgroundTextureX2, settingsTable.BackgroundTextureY2)
    
    // Left side.
    self.leftSide = GUIManager:CreateGraphicItem()
    self.leftSide:SetUseStencil(true)
    self.leftSide:SetSize(Vector(settingsTable.BackgroundWidth / 2, settingsTable.BackgroundHeight, 0))
    self.leftSide:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.leftSide:SetPosition(Vector(-settingsTable.BackgroundWidth / 2, -(settingsTable.BackgroundHeight + GUIDial.kMaskHeightBuffer), 0))
    self.leftSide:SetTexture(settingsTable.ForegroundTextureName)
    self.leftSide:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    // Cut off so only the left side of the texture is displayed on the self.leftSide.
    local x2 = settingsTable.ForegroundTextureX2 - settingsTable.ForegroundTextureWidth / 2
    self.leftSide:SetTexturePixelCoordinates(settingsTable.ForegroundTextureX1, settingsTable.ForegroundTextureY1,
                                             x2, settingsTable.ForegroundTextureY2)

    self.leftSideMask = GUIManager:CreateGraphicItem()
    self.leftSideMask:SetIsStencil(true)
    self.leftSideMask:SetSize(Vector(settingsTable.BackgroundWidth / 2, settingsTable.BackgroundHeight + GUIDial.kMaskHeightBuffer, 0))
    self.leftSideMask:SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.leftSideMask:SetPosition(Vector(0, -(settingsTable.BackgroundHeight / 2), 0))
    self.leftSideMask:SetRotationOffset(Vector(-settingsTable.BackgroundWidth / 2, 0, 0))
    self.leftSideMask:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    
    self.leftSideMask:AddChild(self.leftSide)
    self.dialBackground:AddChild(self.leftSideMask)
    
    // Right side.
    self.rightSide = GUIManager:CreateGraphicItem()
    self.rightSide:SetUseStencil(true)
    self.rightSide:SetSize(Vector(settingsTable.BackgroundWidth / 2, settingsTable.BackgroundHeight, 0))
    self.rightSide:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.rightSide:SetPosition(Vector(0, -(settingsTable.BackgroundHeight + GUIDial.kMaskHeightBuffer), 0))
    self.rightSide:SetTexture(settingsTable.ForegroundTextureName)
    self.rightSide:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    // Cut off so only the right side of the texture is displayed on the self.rightSide.
    local x1 = settingsTable.ForegroundTextureX1 + settingsTable.ForegroundTextureWidth / 2
    self.rightSide:SetTexturePixelCoordinates(x1, settingsTable.ForegroundTextureY1,
                                              settingsTable.ForegroundTextureX2, settingsTable.ForegroundTextureY2)

    self.rightSideMask = GUIManager:CreateGraphicItem()
    self.rightSideMask:SetIsStencil(true)
    self.rightSideMask:SetSize(Vector(settingsTable.BackgroundWidth / 2, settingsTable.BackgroundHeight + GUIDial.kMaskHeightBuffer, 0))
    self.rightSideMask:SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.rightSideMask:SetPosition(Vector(-settingsTable.BackgroundWidth / 2, -(settingsTable.BackgroundHeight / 2), 0))
    self.rightSideMask:SetRotationOffset(Vector(settingsTable.BackgroundWidth / 2, 0, 0))
    self.rightSideMask:SetInheritsParentAlpha(settingsTable.InheritParentAlpha)
    
    self.rightSideMask:AddChild(self.rightSide)
    self.dialBackground:AddChild(self.rightSideMask)
    
end

function GUIDial:Uninitialize()

    GUI.DestroyItem(self.dialBackground)
    self.dialBackground = nil
    
end

function GUIDial:Update(deltaTime)

    PROFILE("GUIDial:Update")

    local leftPercentage = math.max(0, (self.percentage - 0.5) / 0.5)
    self.leftSideMask:SetRotation(Vector(0, 0, math.pi * (1 - leftPercentage)))
    
    local rightPercentage = math.max(0, math.min(0.5, self.percentage) / 0.5)
    self.rightSideMask:SetRotation(Vector(0, 0, math.pi * (1 - rightPercentage)))
    
end

function GUIDial:SetPercentage(setPercentage)

    self.percentage = setPercentage

end

function GUIDial:GetBackground()

    return self.dialBackground

end

function GUIDial:GetLeftSide()

    return self.leftSide
    
end

function GUIDial:GetRightSide()

    return self.rightSide
    
end
