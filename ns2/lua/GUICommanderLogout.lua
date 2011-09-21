// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderLogout.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying and animating the commander logout button in addition to logging the
// commander out when pressed.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICommanderLogout' (GUIScript)

GUICommanderLogout.kBackgroundWidth = 146 * kCommanderGUIsGlobalScale
GUICommanderLogout.kBackgroundHeight = 92 * kCommanderGUIsGlobalScale
GUICommanderLogout.kBackgroundScaleDefault = Vector(1, 1, 1)
GUICommanderLogout.kBackgroundScalePressed = Vector(0.9, 0.9, 0.9)

GUICommanderLogout.kMouseOverColor = Color(0.8, 0.8, 1, 1)
GUICommanderLogout.kDefaultColor = Color(1, 1, 1, 1)

GUICommanderLogout.kLogoutOffset = 5
GUICommanderLogout.kLogoutMarineTextureName = "ui/marine_commander_background.dds"
GUICommanderLogout.kLogoutAlienTextureName = "ui/alien_commander_background.dds"

GUICommanderLogout.kArrowWidth = 37 * kCommanderGUIsGlobalScale
GUICommanderLogout.kArrowHeight = 45 * kCommanderGUIsGlobalScale

// Texture coordinate data.
GUICommanderLogout.kArrowBaseX = { 806, 848, 894 }
GUICommanderLogout.kArrowTextureWidth = 37
GUICommanderLogout.kArrowBaseY = 103
GUICommanderLogout.kArrowTextureHeight = 45

GUICommanderLogout.kArrowXOffset = 20 * kCommanderGUIsGlobalScale
GUICommanderLogout.kArrowBaseXOffset = (GUICommanderLogout.kArrowXOffset * 3) / 2

GUICommanderLogout.kArrowAnimateSpeed = 0.15

GUICommanderLogout.kTooltipFontSize = 16

function GUICommanderLogout:Initialize()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUICommanderLogout.kBackgroundWidth, GUICommanderLogout.kBackgroundHeight, 0))
    self.background:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.background:SetPosition(Vector(-GUICommanderLogout.kBackgroundWidth - GUICommanderLogout.kLogoutOffset, GUICommanderLogout.kLogoutOffset, 0))
    
    if CommanderUI_IsAlienCommander() then
        self.background:SetTexture(GUICommanderLogout.kLogoutAlienTextureName)
        self.background:SetTexturePixelCoordinates(800, 4, 946, 96)
    else
        self.background:SetTexture(GUICommanderLogout.kLogoutMarineTextureName)
        self.background:SetTexturePixelCoordinates(800, 4, 946, 96)
    end
    
    self:InitializeArrows()
    
    self:InitializeScanlines()
    
    self:InitializeTooltip()
    
end

function GUICommanderLogout:InitializeArrows()

    self.arrows = { }
    self.arrowAnimateTime = 0
    self.startArrow = 1
    
    for i = 1, 3 do
        local arrowItem = GUIManager:CreateGraphicItem()
        arrowItem:SetSize(Vector(GUICommanderLogout.kArrowWidth, GUICommanderLogout.kArrowHeight, 0))
        if CommanderUI_IsAlienCommander() then
            arrowItem:SetTexture(GUICommanderLogout.kLogoutAlienTextureName)
        else
            arrowItem:SetTexture(GUICommanderLogout.kLogoutMarineTextureName)
        end
        local baseX = GUICommanderLogout.kArrowBaseX[i]
        local baseY = GUICommanderLogout.kArrowBaseY
        arrowItem:SetTexturePixelCoordinates(baseX, baseY, baseX + GUICommanderLogout.kArrowTextureWidth, baseY + GUICommanderLogout.kArrowTextureHeight)
        arrowItem:SetAnchor(GUIItem.Left, GUIItem.Center)
        local xOffset = GUICommanderLogout.kArrowBaseXOffset + ((i - 1) * GUICommanderLogout.kArrowXOffset)
        arrowItem:SetPosition(Vector(xOffset, -GUICommanderLogout.kArrowHeight / 2, 0))
        self.background:AddChild(arrowItem)
        table.insert(self.arrows, arrowItem)
    end

end

function GUICommanderLogout:InitializeScanlines()

    local settingsTable = { }
    settingsTable.Width = GUICommanderLogout.kBackgroundWidth
    settingsTable.Height = GUICommanderLogout.kBackgroundHeight
    settingsTable.ExtraHeight = 0
    self.scanlines = GUIScanlines()
    self.scanlines:Initialize(settingsTable)
    self.scanlines:GetBackground():SetInheritsParentAlpha(true)
    self.background:AddChild(self.scanlines:GetBackground())
    
end

function GUICommanderLogout:InitializeTooltip()

    self.tooltip = GUIManager:CreateTextItem()
    self.tooltip:SetFontSize(GUICommanderLogout.kTooltipFontSize)
    self.tooltip:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.tooltip:SetTextAlignmentX(GUIItem.Align_Min)
    self.tooltip:SetTextAlignmentY(GUIItem.Align_Max)
    self.tooltip:SetIsVisible(false)
    self.tooltip:SetFontIsBold(true)
    self.tooltip:SetText("Logout")
    self.background:AddChild(self.tooltip)

end

function GUICommanderLogout:Uninitialize()

    if self.scanlines then
        self.scanlines:Uninitialize()
        self.scanlines = nil
    end
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
    
    self.arrows = { }
    
end
    
function GUICommanderLogout:SendKeyEvent(key, down)

    if key == InputKey.MouseButton0 and self.mousePressed ~= down then
        self.mousePressed = down
        // Check if the button was pressed.
        if not self.mousePressed then
            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.background, mouseX, mouseY)
            if containsPoint then
                CommanderUI_Logout()
                return true
            end
        end
    end
    
    return false
    
end

function GUICommanderLogout:Update(deltaTime)

    PROFILE("GUICommanderLogout:Update")

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    local animateArrows = false
    
    self.background:SetScale(GUICommanderLogout.kBackgroundScaleDefault)
    
    // Animate arrows when the mouse is hovering over.
    local containsPoint, withinX, withinY = GUIItemContainsPoint(self.background, mouseX, mouseY)
    if containsPoint then
        self.background:SetColor(GUICommanderLogout.kMouseOverColor)
        animateArrows = true
        if self.mousePressed then
            self.background:SetScale(GUICommanderLogout.kBackgroundScalePressed)
        end
        self.tooltip:SetIsVisible(true)
        self.tooltip:SetPosition(Vector(withinX, withinY, 0))
    else
        self.background:SetColor(GUICommanderLogout.kDefaultColor)
        self.tooltip:SetIsVisible(false)
    end
    
    // When done animating, we want it to always go back to the initial state.
    if not animateArrows and self.startArrow ~= 1 then
        animateArrows = true
    end
    
    if animateArrows then
        self.arrowAnimateTime = self.arrowAnimateTime + deltaTime
        if self.arrowAnimateTime >= GUICommanderLogout.kArrowAnimateSpeed then
            self.arrowAnimateTime = 0
            self.startArrow = self.startArrow + 1
            if self.startArrow > table.count(self.arrows) then
                self.startArrow = 1
            end
            local currentArrow = self.startArrow
            for i = 1, table.count(self.arrows) do
                local xOffset = GUICommanderLogout.kArrowBaseXOffset + ((currentArrow - 1) * GUICommanderLogout.kArrowXOffset)
                self.arrows[i]:SetPosition(Vector(xOffset, -GUICommanderLogout.kArrowHeight / 2, 0))
                currentArrow = currentArrow + 1
                if currentArrow > table.count(self.arrows) then
                    currentArrow = 1
                end
            end
        end
    end
    
    if self.scanlines then
        self.scanlines:Update(deltaTime)
    end

end

function GUICommanderLogout:ContainsPoint(pointX, pointY)

    return GUIItemContainsPoint(self.background, pointX, pointY)

end
