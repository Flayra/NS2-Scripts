
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIBorderBackground.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a background that can scale to any size while maintaining the same border size.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIBorderBackground' (GUIScript)

function GUIBorderBackground:Initialize(settingsTable)

    self.width = settingsTable.Width
    self.height = settingsTable.Height
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(self.width, self.height, 0))
    self.background:SetPosition(Vector(settingsTable.X, settingsTable.Y, 0))
    // The background is an invisible container only.
    self.background:SetColor(Color(0, 0, 0, 0))
    
    self.partTextureWidth = settingsTable.TexturePartWidth
    self.partTextureHeight = settingsTable.TexturePartHeight
    
    self.parts = { }
    
    local textureName = settingsTable.TextureName
    
    // Corner parts.
    self.topLeftBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.topLeftBackground:SetTexture(textureName)
    else
        self.topLeftBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.topLeftBackground, settingsTable.TextureCoordinates[1])
    self.background:AddChild(self.topLeftBackground)
    table.insert(self.parts, self.topLeftBackground)
    
    self.topRightBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.topRightBackground:SetTexture(textureName)
    else
        self.topRightBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.topRightBackground, settingsTable.TextureCoordinates[3])
    self.background:AddChild(self.topRightBackground)
    table.insert(self.parts, self.topRightBackground)
    
    self.bottomLeftBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.bottomLeftBackground:SetTexture(textureName)
    else
        self.bottomLeftBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.bottomLeftBackground, settingsTable.TextureCoordinates[7])
    self.background:AddChild(self.bottomLeftBackground)
    table.insert(self.parts, self.bottomLeftBackground)
    
    self.bottomRightBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.bottomRightBackground:SetTexture(textureName)
    else
        self.bottomRightBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.bottomRightBackground, settingsTable.TextureCoordinates[9])
    self.background:AddChild(self.bottomRightBackground)
    table.insert(self.parts, self.bottomRightBackground)
    
    // Scaled middle parts.
    self.topMiddleBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.topMiddleBackground:SetTexture(textureName)
    else
        self.topMiddleBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.topMiddleBackground, settingsTable.TextureCoordinates[2])
    self.background:AddChild(self.topMiddleBackground)
    table.insert(self.parts, self.topMiddleBackground)
    
    self.bottomMiddleBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.bottomMiddleBackground:SetTexture(textureName)
    else
        self.bottomMiddleBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.bottomMiddleBackground, settingsTable.TextureCoordinates[8])
    self.background:AddChild(self.bottomMiddleBackground)
    table.insert(self.parts, self.bottomMiddleBackground)
    
    self.leftCenterBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.leftCenterBackground:SetTexture(textureName)
    else
        self.leftCenterBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.leftCenterBackground, settingsTable.TextureCoordinates[4])
    self.background:AddChild(self.leftCenterBackground)
    table.insert(self.parts, self.leftCenterBackground)
    
    self.rightCenterBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.rightCenterBackground:SetTexture(textureName)
    else
        self.rightCenterBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.rightCenterBackground, settingsTable.TextureCoordinates[6])
    self.background:AddChild(self.rightCenterBackground)
    table.insert(self.parts, self.rightCenterBackground)
    
    // Middle part.
    self.middleBackground = GUIManager:CreateGraphicItem()
    if textureName and string.len(textureName) > 0 then
        self.middleBackground:SetTexture(textureName)
    else
        self.middleBackground:SetColor(Color(0, 0, 0, 0))
    end
    GUISetTextureCoordinatesTable(self.middleBackground, settingsTable.TextureCoordinates[5])
    self.background:AddChild(self.middleBackground)
    table.insert(self.parts, self.middleBackground)
    
    // Now that they are all created, set their initial sizes.
    self:SetSize(Vector(self.width, self.height, 0))
    
end

function GUIBorderBackground:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIBorderBackground:SetSize(sizeVector)

    self.width = sizeVector.x
    self.height = sizeVector.y
    
    self.background:SetSize(Vector(self.width, self.height, 0))
    
    // Corner parts.
    self.topLeftBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.topLeftBackground:SetPosition(Vector(0, 0, 0))
    
    self.topRightBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.topRightBackground:SetPosition(Vector(self.width - self.partTextureWidth, 0, 0))
    
    self.bottomLeftBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.bottomLeftBackground:SetPosition(Vector(0, self.height - self.partTextureHeight, 0))
    
    self.bottomRightBackground:SetSize(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    self.bottomRightBackground:SetPosition(Vector(self.width - self.partTextureWidth, self.height - self.partTextureHeight, 0))
    
    // Scaled middle parts.
    local topMiddleWidth = self.width - self.partTextureWidth * 2
    // Only bother with this part if it is needed.
    self.topMiddleBackground:SetIsVisible(false)
    if topMiddleWidth > 0 then
        self.topMiddleBackground:SetIsVisible(true)
        self.topMiddleBackground:SetSize(Vector(topMiddleWidth, self.partTextureHeight, 0))
        self.topMiddleBackground:SetPosition(Vector(self.partTextureWidth, 0, 0))
    end
    
    local bottomMiddleWidth = self.width - self.partTextureWidth * 2
    self.bottomMiddleBackground:SetIsVisible(false)
    if bottomMiddleWidth > 0 then
        self.bottomMiddleBackground:SetIsVisible(true)
        self.bottomMiddleBackground:SetSize(Vector(bottomMiddleWidth, self.partTextureHeight, 0))
        self.bottomMiddleBackground:SetPosition(Vector(self.partTextureWidth, self.height - self.partTextureHeight, 0))
    end
    
    local leftCenterHeight = self.height - self.partTextureHeight * 2
    self.leftCenterBackground:SetIsVisible(false)
    if leftCenterHeight > 0 then
        self.leftCenterBackground:SetIsVisible(true)
        self.leftCenterBackground:SetSize(Vector(self.partTextureWidth, leftCenterHeight, 0))
        self.leftCenterBackground:SetPosition(Vector(0, self.partTextureHeight, 0))
    end
    
    local rightCenterHeight = self.height - self.partTextureHeight * 2
    self.rightCenterBackground:SetIsVisible(false)
    if rightCenterHeight > 0 then
        self.rightCenterBackground:SetIsVisible(true)
        self.rightCenterBackground:SetSize(Vector(self.partTextureWidth, rightCenterHeight, 0))
        self.rightCenterBackground:SetPosition(Vector(self.width - self.partTextureWidth, self.partTextureHeight, 0))
    end
    
    // Middle part.
    local middleWidth = self.width - self.partTextureWidth * 2
    local middleHeight = self.height - self.partTextureHeight * 2
    self.middleBackground:SetIsVisible(false)
    if middleWidth > 0 and middleHeight > 0 then
        self.middleBackground:SetIsVisible(true)
        self.middleBackground:SetSize(Vector(middleWidth, middleHeight, 0))
        self.middleBackground:SetPosition(Vector(self.partTextureWidth, self.partTextureHeight, 0))
    end

end

function GUIBorderBackground:SetLayer(setLayer)

    self.background:SetLayer(setLayer)

end

function GUIBorderBackground:SetPosition(setPosition)

    self.background:SetPosition(setPosition)

end

function GUIBorderBackground:SetAnchor(horzAnchor, vertAnchor)

    self.background:SetAnchor(horzAnchor, vertAnchor)

end

function GUIBorderBackground:SetIsVisible(setIsVisible)

    self.background:SetIsVisible(setIsVisible)

end

function GUIBorderBackground:SetColor(setColor)

    for i, item in ipairs(self.parts) do
        item:SetColor(setColor)
    end

end

function GUIBorderBackground:AddChild(childItem)

    self.background:AddChild(childItem)

end

function GUIBorderBackground:GetBackground()

    return self.background

end
