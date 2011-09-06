
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIRequests.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the text request menu.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIRequests' (GUIScript)

// Background constants.
GUIRequests.kBackgroundXOffset = 0
GUIRequests.kBackgroundYOffset = 200
GUIRequests.kBackgroundWidth = 200
GUIRequests.kBackgroundColor = Color(0.1, 0.1, 0.1, 0.5)
// How many seconds for the background to fade in.
GUIRequests.kBackgroundFadeRate = 0.25

// Text constants.
GUIRequests.kTextFontSize = 18
GUIRequests.kTextSayingColor = Color(1, 1, 1, 1)
// This is how much of a buffer around the text the background extends.
GUIRequests.kTextBackgroundWidthBuffer = 4
GUIRequests.kTextBackgroundHeightBuffer = 2
// This is the amount of space between text background items.
GUIRequests.kTextBackgroundItemBuffer = 2
GUIRequests.kTextBackgroundColor = Color(0.4, 0.4, 0.4, 1)

function GUIRequests:Initialize()
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    // Start off-screen.
    self.background:SetPosition(Vector(GUIRequests.kBackgroundXOffset, GUIRequests.kBackgroundYOffset, 0))
    self.background:SetSize(Vector(GUIRequests.kBackgroundWidth, 0, 0))
    self.background:SetColor(GUIRequests.kBackgroundColor)
    self.background:SetIsVisible(false)
    
    self.textSayings = { }
    self.reuseSayingItems = { }

end

function GUIRequests:Uninitialize()

    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIRequests:Update(deltaTime)

    PROFILE("GUIRequests:Update")
    
    local visible = PlayerUI_ShowSayings()
    if visible then
        local sayings = PlayerUI_GetSayings()
        self:UpdateSayings(sayings)
    end
    
    self:UpdateFading(deltaTime, visible)
    
end

function GUIRequests:UpdateFading(deltaTime, visible)
    
    if visible then
        self.background:SetIsVisible(true)
        self.background:SetColor(GUIRequests.kBackgroundColor)
    end
    
    local fadeAmt = deltaTime * (1 / GUIRequests.kBackgroundFadeRate)
    local currentColor = self.background:GetColor()
    if not visible and currentColor.a ~= 0 then
        currentColor.a = Slerp(currentColor.a, 0, fadeAmt)
        self.background:SetColor(currentColor)
        if currentColor.a == 0 then
            self.background:SetIsVisible(false)
        end
    end
    
end

function GUIRequests:UpdateSayings(sayings)

    if sayings ~= nil then
        if table.count(self.textSayings) ~= table.count(sayings) then
            self:ResizeSayingsList(sayings)
        end

        local currentYPos = 0
        for i, textSaying in ipairs(self.textSayings) do
            textSaying["Text"]:SetText(sayings[i])
            
            currentYPos = currentYPos + GUIRequests.kTextBackgroundItemBuffer + GUIRequests.kTextBackgroundHeightBuffer
            textSaying["Background"]:SetPosition(Vector(0, currentYPos, 0))
            currentYPos = currentYPos + GUIRequests.kTextFontSize + GUIRequests.kTextBackgroundItemBuffer + GUIRequests.kTextBackgroundHeightBuffer
            
            local totalWidth = GUIRequests.kBackgroundWidth - (GUIRequests.kTextBackgroundWidthBuffer * 2)
            local totalHeight = GUIRequests.kTextFontSize + (GUIRequests.kTextBackgroundHeightBuffer * 2)
            textSaying["Background"]:SetSize(Vector(totalWidth, totalHeight, 0))
        end
        
        local totalBackgroundHeight = GUIRequests.kTextFontSize + (GUIRequests.kTextBackgroundItemBuffer * 2) + (GUIRequests.kTextBackgroundHeightBuffer * 2)
        totalBackgroundHeight = (table.count(self.textSayings) * totalBackgroundHeight) + (GUIRequests.kTextBackgroundItemBuffer * 2)
        self.background:SetSize(Vector(GUIRequests.kBackgroundWidth, totalBackgroundHeight, 0))
    end

end

function GUIRequests:ResizeSayingsList(sayings)
    
    while table.count(sayings) > table.count(self.textSayings) do
        local newSayingItem = self:CreateSayingItem()
        table.insert(self.textSayings, newSayingItem)
        self.background:AddChild(newSayingItem["Background"])
        newSayingItem["Background"]:SetIsVisible(true)
    end
    
    while table.count(sayings) < table.count(self.textSayings) do
        self.background:RemoveChild(self.textSayings[1]["Background"])
        self.textSayings[1]["Background"]:SetIsVisible(false)
        table.insert(self.reuseSayingItems, self.textSayings[1])
        table.remove(self.textSayings, 1)
    end

end

function GUIRequests:CreateSayingItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reuseSayingItems) > 0 then
        local returnSayingItem = self.reuseSayingItems[1]
        table.remove(self.reuseSayingItems, 1)
        return returnSayingItem
    end
    
    local textBackground = GUIManager:CreateGraphicItem()
    textBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    textBackground:SetColor(GUIRequests.kTextBackgroundColor)
    textBackground:SetInheritsParentAlpha(true)
    
    local newSayingItem = GUIManager:CreateTextItem()
    newSayingItem:SetFontSize(GUIRequests.kTextFontSize)
    newSayingItem:SetAnchor(GUIItem.Left, GUIItem.Center)
    newSayingItem:SetPosition(Vector(GUIRequests.kTextBackgroundWidthBuffer, 0, 0))
    newSayingItem:SetTextAlignmentX(GUIItem.Align_Min)
    newSayingItem:SetTextAlignmentY(GUIItem.Align_Center)
    newSayingItem:SetColor(GUIRequests.kTextSayingColor)
    newSayingItem:SetInheritsParentAlpha(true)
    textBackground:AddChild(newSayingItem)
    
    return { Background = textBackground, Text = newSayingItem }
    
end
