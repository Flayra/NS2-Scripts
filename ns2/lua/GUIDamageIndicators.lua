
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDamageIndicators.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the damage arrows pointing to the source of damage.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIDamageIndicators' (GUIScript)

GUIDamageIndicators.kIndicatorSize = 64
GUIDamageIndicators.kArrowCenterOffset = 200
GUIDamageIndicators.kDefaultIndicatorPosition = Vector(-GUIDamageIndicators.kIndicatorSize / 2, -GUIDamageIndicators.kIndicatorSize / 2, 0)

function GUIDamageIndicators:Initialize()

    self.indicatorItems = { }
    self.reuseItems = { }

end

function GUIDamageIndicators:Uninitialize()

    for i, indicatorItem in ipairs(self.indicatorItems) do
        GUI.DestroyItem(indicatorItem)
    end
    self.indicatorItems = { }
    
    for i, indicatorItem in ipairs(self.reuseItems) do
        GUI.DestroyItem(indicatorItem)
    end
    self.reuseItems = { }
    
end

function GUIDamageIndicators:Update(deltaTime)

    PROFILE("GUIDamageIndicators:Update")
    
    local damageIndicators = PlayerUI_GetDamageIndicators()
    
    local numDamageIndicators = table.count(damageIndicators) / 2
    
    if numDamageIndicators ~= table.count(self.indicatorItems) then
        self:ResizeIndicatorList(numDamageIndicators)
    end
    
    local currentIndex = 1
    for i, indicatorItem in ipairs(self.indicatorItems) do
        local currentAlpha = damageIndicators[currentIndex]
        local currentAngle = damageIndicators[currentIndex + 1]
        indicatorItem:SetColor(Color(1, 1, 1, currentAlpha))
        indicatorItem:SetRotation(Vector(0, 0, currentAngle + math.pi))
        local direction = Vector(math.sin(currentAngle), math.cos(currentAngle), 0)
        direction:Normalize()
        local rotatedPosition = GUIDamageIndicators.kDefaultIndicatorPosition + (direction * GUIDamageIndicators.kArrowCenterOffset)
        indicatorItem:SetPosition(rotatedPosition)
        currentIndex = currentIndex + 2
    end
    
end

function GUIDamageIndicators:ResizeIndicatorList(numIndicators)
    
    while numIndicators > table.count(self.indicatorItems) do
        local newIndicatorItem = self:CreateIndicatorItem()
        table.insert(self.indicatorItems, newIndicatorItem)
        newIndicatorItem:SetIsVisible(true)
    end
    
    while numIndicators < table.count(self.indicatorItems) do
        self.indicatorItems[1]:SetIsVisible(false)
        table.insert(self.reuseItems, self.indicatorItems[1])
        table.remove(self.indicatorItems, 1)
    end

end

function GUIDamageIndicators:CreateIndicatorItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reuseItems) > 0 then
        local returnIndicatorItem = self.reuseItems[1]
        table.remove(self.reuseItems, 1)
        return returnIndicatorItem
    end

    local newIndicator = GUIManager:CreateGraphicItem()
    newIndicator:SetSize(Vector(GUIDamageIndicators.kIndicatorSize, GUIDamageIndicators.kIndicatorSize, 0))
    newIndicator:SetAnchor(GUIItem.Middle, GUIItem.Center)
    newIndicator:SetPosition(GUIDamageIndicators.kDefaultIndicatorPosition)
    newIndicator:SetTexture("ui/hud_elements.dds")
    newIndicator:SetTextureCoordinates(0.001, 0.535, 0.117, 0.993)
    newIndicator:SetIsVisible(false)
    return newIndicator
    
end
