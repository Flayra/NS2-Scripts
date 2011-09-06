// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIVoiceChat.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying names of players using voice chat.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIVoiceChat' (GUIScript)

GUIVoiceChat.kBackgroundSize = Vector(GUIScale(250), GUIScale(28), 0)
GUIVoiceChat.kBackgroundOffset = Vector(-GUIVoiceChat.kBackgroundSize.x - 5, GUIScale(0), 0)
GUIVoiceChat.kBackgroundYSpace = GUIScale(4)
GUIVoiceChat.kBackgroundAlpha = 0.8

GUIVoiceChat.kVoiceChatIconSize = GUIVoiceChat.kBackgroundSize.y
GUIVoiceChat.kVoiceChatIconOffset = Vector(GUIScale(5), -GUIVoiceChat.kVoiceChatIconSize / 2, 0)

GUIVoiceChat.kNameFontSize = GUIScale(22)
GUIVoiceChat.kNameOffsetFromChatIcon = GUIScale(4)

function GUIVoiceChat:Initialize()

    self.chatBars = { }

end

function GUIVoiceChat:Uninitialize()

    for i, bar in ipairs(self.chatBars) do
        self:_DestroyChatBar(bar)
    end
    self.chatBars = { }
    
end

function GUIVoiceChat:_CreateChatBar()

    local background = GUIManager:CreateGraphicItem()
    background:SetSize(GUIVoiceChat.kBackgroundSize)
    background:SetAnchor(GUIItem.Right, GUIItem.Center)
    background:SetPosition(GUIVoiceChat.kBackgroundOffset)
    background:SetIsVisible(false)
    
    local chatIcon = GUIManager:CreateGraphicItem()
    chatIcon:SetSize(Vector(GUIVoiceChat.kVoiceChatIconSize, GUIVoiceChat.kVoiceChatIconSize, 0))
    chatIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    chatIcon:SetPosition(GUIVoiceChat.kVoiceChatIconOffset)
    chatIcon:SetTexture("ui/speaker.dds")
    chatIcon:SetColor(Color(0, 0, 0, 1))
    background:AddChild(chatIcon)
    
    local nameText = GUIManager:CreateTextItem()
    nameText:SetFontSize(GUIVoiceChat.kNameFontSize)
    nameText:SetAnchor(GUIItem.Right, GUIItem.Center)
    nameText:SetTextAlignmentX(GUIItem.Align_Min)
    nameText:SetTextAlignmentY(GUIItem.Align_Center)
    nameText:SetPosition(Vector(GUIVoiceChat.kNameOffsetFromChatIcon, 0, 0))
    nameText:SetColor(Color(0, 0, 0, 1))
    chatIcon:AddChild(nameText)
    
    return { Background = background, Icon = chatIcon, Name = nameText }
    
end

function GUIVoiceChat:_DestroyChatBar(destroyBar)

    GUI.DestroyItem(destroyBar.Name)
    destroyBar.Name = nil
    
    GUI.DestroyItem(destroyBar.Icon)
    destroyBar.Icon = nil
    
    GUI.DestroyItem(destroyBar.Background)
    destroyBar.Background = nil

end

function GUIVoiceChat:Update(deltaTime)

    PROFILE("GUIVoiceChat:Update")

    self:_ClearAllBars()
    
    local allPlayers = ScoreboardUI_GetAllScores()
    // How many items per player.
    local numPlayers = table.count(allPlayers)
    local currentBar = 0
    for i = 1, numPlayers do
    
        local playerName = allPlayers[i].Name
        local clientIndex = allPlayers[i].ClientIndex
        local clientTeam = allPlayers[i].EntityTeamNumber
        
        if clientIndex and ChatUI_GetIsClientSpeaking(clientIndex) then
            local chatBar = self:_GetFreeBar()
            chatBar.Background:SetIsVisible(true)
            local backgroundColor = PlayerUI_GetTeamColor(clientTeam)
            backgroundColor.a = GUIVoiceChat.kBackgroundAlpha
            chatBar.Background:SetColor(backgroundColor)
            chatBar.Name:SetText(playerName)
            local currentBarPosition = Vector(0, (GUIVoiceChat.kBackgroundSize.y + GUIVoiceChat.kBackgroundYSpace) * currentBar, 0)
            chatBar.Background:SetPosition(GUIVoiceChat.kBackgroundOffset + currentBarPosition)
            currentBar = currentBar + 1
        end

    end

end

function GUIVoiceChat:_ClearAllBars()

    for i, bar in ipairs(self.chatBars) do
        bar.Background:SetIsVisible(false)
    end

end

function GUIVoiceChat:_GetFreeBar()

    for i, bar in ipairs(self.chatBars) do
        if not bar.Background:GetIsVisible() then
            return bar
        end
    end
    
    local newBar = self:_CreateChatBar()
    table.insert(self.chatBars, newBar)
    return newBar

end