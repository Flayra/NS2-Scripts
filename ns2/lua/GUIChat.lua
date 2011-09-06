// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIChat.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages chat messages that players send to each other.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIChat' (GUIScript)

GUIChat.kOffset = Vector(GUIScale(100), GUIScale(-400), 0)
GUIChat.kInputModeOffset = Vector(-5, 0, 0)
GUIChat.kInputOffset = Vector(0, GUIScale(-50), 0)
GUIChat.kBackgroundColor = Color(0.4, 0.4, 0.4, 0.0)
// This is the buffer x space between a player name and their chat message.
GUIChat.kChatTextBuffer = 5
GUIChat.kFontSize = GUIScale(18)
GUIChat.kTimeStartFade = 6
GUIChat.kTimeEndFade = 7

function GUIChat:Initialize()

    self.messages = { }
    self.reuseMessages = { }
    
    // Input mode (Team/All) indicator text.
    self.inputModeItem = GUIManager:CreateTextItem()
    self.inputModeItem:SetFontSize(GUIChat.kFontSize)
    self.inputModeItem:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.inputModeItem:SetTextAlignmentX(GUIItem.Align_Max)
    self.inputModeItem:SetTextAlignmentY(GUIItem.Align_Center)
    self.inputModeItem:SetIsVisible(false)
    
    // Input text item.
    self.inputItem = GUIManager:CreateTextItem()
    self.inputItem:SetFontSize(GUIChat.kFontSize)
    self.inputItem:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.inputItem:SetPosition(GUIChat.kOffset + GUIChat.kInputOffset)
    self.inputItem:SetTextAlignmentX(GUIItem.Align_Min)
    self.inputItem:SetTextAlignmentY(GUIItem.Align_Center)
    self.inputItem:SetIsVisible(false)
    
end

function GUIChat:Uninitialize()

    GUI.DestroyItem(self.inputModeItem)
    self.inputModeItem = nil
    
    GUI.DestroyItem(self.inputItem)
    self.inputItem = nil
    
    for index, message in ipairs(self.messages) do
        GUI.DestroyItem(message["Background"])
    end
    self.messages = nil
    
    for index, message in ipairs(self.reuseMessages) do
        GUI.DestroyItem(message["Background"])
    end
    self.reuseMessages = nil
    
end

function GUIChat:Update(deltaTime)

    PROFILE("GUIChat:Update")
    
    local addChatMessages = ChatUI_GetMessages()
    local numberElementsPerMessage = 8
    local numberMessages = table.count(addChatMessages) / numberElementsPerMessage
    local currentIndex = 1
    while numberMessages > 0 do
        local playerColor = addChatMessages[currentIndex]
        local playerName = addChatMessages[currentIndex + 1]
        local messageColor = addChatMessages[currentIndex + 2]
        local messageText = addChatMessages[currentIndex + 3]
        self:AddMessage(playerColor, playerName, messageColor, messageText)
        currentIndex = currentIndex + numberElementsPerMessage
        numberMessages = numberMessages - 1
    end
    
    local removeMessages = { }
    // Update existing messages.
    for i, message in ipairs(self.messages) do
        local currentPosition = Vector(message["Background"]:GetPosition())
        currentPosition.y = GUIChat.kOffset.y + (GUIChat.kFontSize * (i - 1))
        message["Background"]:SetPosition(currentPosition)
        message["Time"] = message["Time"] + deltaTime
        if message["Time"] >= GUIChat.kTimeStartFade then
            local fadeAmount = ((GUIChat.kTimeEndFade - message["Time"]) / (GUIChat.kTimeEndFade - GUIChat.kTimeStartFade))
            local currentColor = message["Player"]:GetColor()
            currentColor.a = fadeAmount
            message["Player"]:SetColor(currentColor)
            currentColor = message["Message"]:GetColor()
            currentColor.a = fadeAmount
            message["Message"]:SetColor(currentColor)
            if message["Time"] >= GUIChat.kTimeEndFade then
                table.insert(removeMessages, message)
            end
        end
    end
    
    // Remove faded out messages.
    for i, removeMessage in ipairs(removeMessages) do
        removeMessage["Background"]:SetIsVisible(false)
        table.insert(self.reuseMessages, removeMessage)
        table.removevalue(self.messages, removeMessage)
    end
    
    // Handle showing/hiding the input item.
    if ChatUI_EnteringChatMessage() then
        if not self.inputItem:GetIsVisible() then
            local textWidth = self.inputModeItem:GetTextWidth(ChatUI_GetChatMessageType())
            self.inputModeItem:SetText(ChatUI_GetChatMessageType())
            self.inputModeItem:SetPosition(GUIChat.kOffset + GUIChat.kInputOffset + GUIChat.kInputModeOffset)
            self.inputModeItem:SetIsVisible(true)
            self.inputItem:SetIsVisible(true)
        end
    else
        if self.inputItem:GetIsVisible() then
            self.inputModeItem:SetIsVisible(false)
            self.inputItem:SetIsVisible(false)
        end
    end
 
end

function GUIChat:SendKeyEvent(key, down)

    if ChatUI_EnteringChatMessage() then
        if down and key == InputKey.Return then
            ChatUI_SubmitChatMessageBody(self.inputItem:GetText())
            self.inputItem:SetText("")
        elseif down and key == InputKey.Back then
            // Only remove text if there is more to remove.
            local currentText = self.inputItem:GetWideText()
            local currentTextLength = currentText:length()
            if currentTextLength > 0 then
                currentText = currentText:sub(1, currentTextLength - 1)
                self.inputItem:SetWideText(currentText)
            end
        elseif down and key == InputKey.Escape then
            ChatUI_SubmitChatMessageBody("")
            self.inputItem:SetText("")
        end
        return true
    end
    return false

end

function GUIChat:SendCharacterEvent(character)

    if ChatUI_EnteringChatMessage() then
        local currentText = self.inputItem:GetWideText()
        self.inputItem:SetWideText(currentText .. character)
        return true
    end
    return false

end

function GUIChat:AddMessage(playerColor, playerName, messageColor, messageText)
    
    local insertMessage = { Background = nil, Player = nil, Message = nil, Time = 0 }
    messageText = ChatUI_Decode(messageText)
    
    // Check if we can reuse an existing message.
    if table.count(self.reuseMessages) > 0 then
        insertMessage = self.reuseMessages[1]
        insertMessage["Time"] = 0
        insertMessage["Background"]:SetIsVisible(true)
        table.remove(self.reuseMessages, 1)
    end
    
    if insertMessage["Player"] == nil then
        insertMessage["Player"] = GUIManager:CreateTextItem()
    end
    insertMessage["Player"]:SetFontSize(GUIChat.kFontSize)
    insertMessage["Player"]:SetAnchor(GUIItem.Left, GUIItem.Center)
    insertMessage["Player"]:SetTextAlignmentX(GUIItem.Align_Min)
    insertMessage["Player"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Player"]:SetColor(ColorIntToColor(playerColor))
    insertMessage["Player"]:SetText(playerName)
    
    if insertMessage["Message"] == nil then
        insertMessage["Message"] = GUIManager:CreateTextItem()
    end
    insertMessage["Message"]:SetFontSize(GUIChat.kFontSize)
    insertMessage["Message"]:SetAnchor(GUIItem.Right, GUIItem.Center)
    insertMessage["Message"]:SetTextAlignmentX(GUIItem.Align_Max)
    insertMessage["Message"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Message"]:SetColor(ColorIntToColor(messageColor))
    insertMessage["Message"]:SetText(messageText)
    
    local playerTextWidth = insertMessage["Player"]:GetTextWidth(playerName)
    local messageTextWidth = insertMessage["Message"]:GetTextWidth(messageText)
    local textWidth = playerTextWidth + messageTextWidth
    
    if insertMessage["Background"] == nil then
        insertMessage["Background"] = GUIManager:CreateGraphicItem()
        insertMessage["Background"]:AddChild(insertMessage["Player"])
        insertMessage["Background"]:AddChild(insertMessage["Message"])
    end
    insertMessage["Background"]:SetSize(Vector(textWidth + GUIChat.kChatTextBuffer, GUIChat.kFontSize, 0))
    insertMessage["Background"]:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    insertMessage["Background"]:SetPosition(GUIChat.kOffset)
    insertMessage["Background"]:SetColor(GUIChat.kBackgroundColor)

    table.insert(self.messages, insertMessage)
    
end
