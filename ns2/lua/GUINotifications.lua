
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUINotifications.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the displaying any text notifications on the screen.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUINotifications' (GUIScript)

// Tooltip constants.
GUINotifications.kTooltipXOffset = 50
GUINotifications.kTooltipYOffset = -300
GUINotifications.kTooltipBackgroundHeight = 28
// The number of pixels that buffer the text on the left and right.
GUINotifications.kTooltipBackgroundWidthBuffer = 5
GUINotifications.kTooltipBackgroundColor = Color(0.4, 0.4, 0.4, 0.5)
GUINotifications.kTooltipBackgroundVisibleTimer = 5
// Defines at which point in the kTooltipBackgroundVisibleTimer does it start to fade out.
GUINotifications.kTooltipBackgroundFadeoutTimer = 0.5
GUINotifications.kTooltipFontSize = 20
GUINotifications.kTooltipTextColor = Color(1, 1, 1, 1)

// Score popup constants.
GUINotifications.kScoreDisplayFontName = "Calibri"
GUINotifications.kScoreDisplayTextColor = Color(0.75, 0.75, 0.1, 1)
GUINotifications.kScoreDisplayFontHeight = 64
GUINotifications.kScoreDisplayMinFontHeight = 20
GUINotifications.kScoreDisplayYOffset = -96
GUINotifications.kScoreDisplayPopTimer = 0.15
GUINotifications.kScoreDisplayFadeoutTimer = 2

function GUINotifications:Initialize()
    
    self.locationText = GUIManager:CreateTextItem()
    self.locationText:SetFontSize(20)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Min)
    self.locationText:SetPosition(Vector(20, 20, 0))
    self.locationText:SetColor(Color(1, 1, 1, 1))
    self.locationText:SetText(PlayerUI_GetLocationName())
    self.locationText:SetLayer(kGUILayerLocationText)
    
    self:InitializeTooltip()
    
    self:InitializeScoreDisplay()

end

function GUINotifications:Uninitialize()

    GUI.DestroyItem(self.locationText)
    self.locationText = nil
    
    self:UninitializeTooltip()
    
    self:UninitializeScoreDisplay()
    
end

function GUINotifications:InitializeTooltip()

    self.tooltipBackground = GUIManager:CreateGraphicItem()
    self.tooltipBackground:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.tooltipBackground:SetSize(Vector(0, GUINotifications.kTooltipBackgroundHeight, 0))
    self.tooltipBackground:SetPosition(Vector(GUINotifications.kTooltipXOffset, GUINotifications.kTooltipYOffset, 0))
    self.tooltipBackground:SetColor(GUINotifications.kTooltipBackgroundColor)
    self.tooltipBackground:SetIsVisible(false)
    
    self.tooltipText = GUIManager:CreateTextItem()
    self.tooltipText:SetFontSize(GUINotifications.kTooltipFontSize)
    self.tooltipText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.tooltipText:SetPosition(Vector(GUINotifications.kTooltipBackgroundWidthBuffer, 0, 0))
    self.tooltipText:SetTextAlignmentX(GUIItem.Align_Min)
    self.tooltipText:SetTextAlignmentY(GUIItem.Align_Center)
    self.tooltipText:SetColor(GUINotifications.kTooltipTextColor)
    self.tooltipText:SetText(PlayerUI_GetLocationName())
    
    self.tooltipBackground:AddChild(self.tooltipText)
    
    self.tooltipBackgroundVisibleTime = 0

end

function GUINotifications:UninitializeTooltip()

    GUI.DestroyItem(self.tooltipBackground)
    self.tooltipBackground = nil
    self.tooltipText = nil
    
end

function GUINotifications:InitializeScoreDisplay()

    self.scoreDisplay = GUIManager:CreateTextItem()
    self.scoreDisplay:SetFontName(GUINotifications.kScoreDisplayFontName)
    self.scoreDisplay:SetFontSize(GUINotifications.kScoreDisplayFontHeight)
    self.scoreDisplay:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.scoreDisplay:SetPosition(Vector(0, GUINotifications.kScoreDisplayYOffset, 0))
    self.scoreDisplay:SetTextAlignmentX(GUIItem.Align_Center)
    self.scoreDisplay:SetTextAlignmentY(GUIItem.Align_Center)
    self.scoreDisplay:SetColor(GUINotifications.kScoreDisplayTextColor)
    self.scoreDisplay:SetIsVisible(false)
    
    self.scoreDisplayPopupTime = 0
    self.scoreDisplayPopdownTime = 0
    self.scoreDisplayFadeoutTime = 0

end

function GUINotifications:UninitializeScoreDisplay()

    GUI.DestroyItem(self.scoreDisplay)
    self.scoreDisplay = nil
    
end

function GUINotifications:Update(deltaTime)

    PROFILE("GUINotifications:Update")

    if PlayerUI_IsACommander() then
        // The commander has their own location text.
        self.locationText:SetIsVisible(false)
    else
        self.locationText:SetIsVisible(true)
        self.locationText:SetText(PlayerUI_GetLocationName())
    end
    
    self:UpdateTooltip(deltaTime)
    
    self:UpdateScoreDisplay(deltaTime)
    
end

function GUINotifications:UpdateTooltip(deltaTime)

    if self.tooltipBackgroundVisibleTime > 0 then
        self.tooltipBackgroundVisibleTime = math.max(0, self.tooltipBackgroundVisibleTime - deltaTime)
        if self.tooltipBackgroundVisibleTime <= GUINotifications.kTooltipBackgroundFadeoutTimer then
            local fadeRate = 1 - (self.tooltipBackgroundVisibleTime / GUINotifications.kTooltipBackgroundFadeoutTimer)
            local fadeColor = Color(GUINotifications.kTooltipBackgroundColor)
            fadeColor.a = fadeColor.a - (fadeColor.a * fadeRate)
            self.tooltipBackground:SetColor(fadeColor)
            local textFadeColor = Color(GUINotifications.kTooltipTextColor)
            textFadeColor.a = textFadeColor.a - (textFadeColor.a * fadeRate)
            self.tooltipText:SetColor(textFadeColor)
        end
        
        if self.tooltipBackgroundVisibleTime == 0 then
            self.tooltipBackground:SetIsVisible(false)
        end
    end
    
    local newMessage = HudTooltipUI_GetMessage()
    if string.len(newMessage) > 0 then
        self.tooltipBackgroundVisibleTime = GUINotifications.kTooltipBackgroundVisibleTimer
        self.tooltipBackground:SetIsVisible(true)
        local tooltipWidth = self.tooltipText:GetTextWidth(newMessage)
        tooltipWidth = tooltipWidth + (GUINotifications.kTooltipBackgroundWidthBuffer * 2)
        self.tooltipBackground:SetSize(Vector(tooltipWidth, GUINotifications.kTooltipBackgroundHeight, 0))
        self.tooltipBackground:SetColor(GUINotifications.kTooltipBackgroundColor)
        self.tooltipText:SetText(newMessage)
        self.tooltipText:SetColor(GUINotifications.kTooltipTextColor)
    end
    
end

function GUINotifications:UpdateScoreDisplay(deltaTime)

    if self.scoreDisplayFadeoutTime > 0 then
        self.scoreDisplayFadeoutTime = math.max(0, self.scoreDisplayFadeoutTime - deltaTime)
        local fadeRate = 1 - (self.scoreDisplayFadeoutTime / GUINotifications.kScoreDisplayFadeoutTimer)
        local fadeColor = Color(GUINotifications.kScoreDisplayTextColor)
        fadeColor.a = fadeColor.a - (fadeColor.a * fadeRate)
        self.scoreDisplay:SetColor(fadeColor)
        if self.scoreDisplayFadeoutTime == 0 then
            self.scoreDisplay:SetIsVisible(false)
        end
    end
    
    if self.scoreDisplayPopdownTime > 0 then
        self.scoreDisplayPopdownTime = math.max(0, self.scoreDisplayPopdownTime - deltaTime)
        local popRate = self.scoreDisplayPopdownTime / GUINotifications.kScoreDisplayPopTimer
        local fontSize = GUINotifications.kScoreDisplayMinFontHeight + ((GUINotifications.kScoreDisplayFontHeight - GUINotifications.kScoreDisplayMinFontHeight) * popRate)
        self.scoreDisplay:SetFontSize(fontSize)
        if self.scoreDisplayPopdownTime == 0 then
            self.scoreDisplayFadeoutTime = GUINotifications.kScoreDisplayFadeoutTimer
        end
    end
    
    if self.scoreDisplayPopupTime > 0 then
        self.scoreDisplayPopupTime = math.max(0, self.scoreDisplayPopupTime - deltaTime)
        local popRate = 1 - (self.scoreDisplayPopupTime / GUINotifications.kScoreDisplayPopTimer)
        local fontSize = GUINotifications.kScoreDisplayMinFontHeight + ((GUINotifications.kScoreDisplayFontHeight - GUINotifications.kScoreDisplayMinFontHeight) * popRate)
        self.scoreDisplay:SetFontSize(fontSize)
        if self.scoreDisplayPopupTime == 0 then
            self.scoreDisplayPopdownTime = GUINotifications.kScoreDisplayPopTimer
        end
    end
    
    local newScore, resAwarded = ScoreDisplayUI_GetNewScore()
    if newScore > 0 then
        // Restart the animation sequence.
        self.scoreDisplayPopupTime = GUINotifications.kScoreDisplayPopTimer
        self.scoreDisplayPopdownTime = 0
        self.scoreDisplayFadeoutTime = 0
        
        local resAwardedString = ""
        if resAwarded > 0 then
            resAwardedString = string.format(" (+%d res)", resAwarded)
        end
        
        self.scoreDisplay:SetText(string.format("+%s%s", tostring(newScore), resAwardedString))
        self.scoreDisplay:SetFontSize(GUINotifications.kScoreDisplayMinFontHeight)
        self.scoreDisplay:SetColor(GUINotifications.kScoreDisplayTextColor)
        self.scoreDisplay:SetIsVisible(true)
    end

end
