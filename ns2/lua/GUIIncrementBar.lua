
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIIncrementBar.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a progress bar that has fading in increments.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIIncrementBar' (GUIScript)

function GUIIncrementBar:Initialize(settingsTable)

    self.percentage = 1
    
    self.numberOfIncrements = settingsTable.NumberOfIncrements
    self.incrementWidth = settingsTable.IncrementWidth
    self.incrementHeight = settingsTable.IncrementHeight
    self.incrementSpacing = settingsTable.IncrementSpacing
    self.incrementColor = settingsTable.IncrementColor
    self.lowPercentage = settingsTable.LowPercentage
    self.lowPercentageIncrementColor = settingsTable.LowPercentageIncrementColor
    self.incrementItems = { }
    
    self.background = GUIManager:CreateGraphicItem()
    // The background is a completely invisible container only.
    self.background:SetColor(Color(0, 0, 0, 0))
    for i = 1, self.numberOfIncrements do
        table.insert(self.incrementItems, GUIManager:CreateGraphicItem())
        self.incrementItems[i]:SetSize(Vector(self.incrementWidth, self.incrementHeight, 0))
        local incrementX = (i - 1) * (self.incrementWidth + self.incrementSpacing)
        self.incrementItems[i]:SetPosition(Vector(incrementX, 0, 0))
        self.incrementItems[i]:SetTexture(settingsTable.TextureName)
        local coordX1 = settingsTable.TextureCoordinates.X
        local coordY1 = settingsTable.TextureCoordinates.Y
        local coordX2 = settingsTable.TextureCoordinates.X + settingsTable.TextureCoordinates.Width
        local coordY2 = settingsTable.TextureCoordinates.Y + settingsTable.TextureCoordinates.Height
        self.incrementItems[i]:SetTexturePixelCoordinates(coordX1, coordY1, coordX2, coordY2)
        self.incrementItems[i]:SetColor(self.incrementColor)
        self.background:AddChild(self.incrementItems[i])
    end
    
end

function GUIIncrementBar:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    self.incrementItems = { }
    
end

function GUIIncrementBar:SetPercentage(setPercentage)

    self.percentage = setPercentage
    for i, item in ipairs(self.incrementItems) do
        local currentIncrementPercent = i / self.numberOfIncrements
        local percentDifference = currentIncrementPercent - self.percentage
        local incrementPercent = percentDifference / (1 / self.numberOfIncrements)
        local lerpAmount = Clamp(incrementPercent, 0, 1)
        // If the bar percentage is below the 
        local useIncrementColor = ConditionalValue(self.percentage < self.lowPercentage, self.lowPercentageIncrementColor, self.incrementColor)
        item:SetColor(ColorLerp(useIncrementColor, Color(1, 1, 1, 1), lerpAmount))
    end

end

function GUIIncrementBar:SetIsVisible(setIsVisible)

    self.background:SetIsVisible(setIsVisible)

end

function GUIIncrementBar:GetWidth()

    return self.numberOfIncrements * (self.incrementWidth + self.incrementSpacing)

end

function GUIIncrementBar:GetHeight()

    return self.incrementHeight

end

function GUIIncrementBar:GetBackground()

    return self.background

end
