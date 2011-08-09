// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderAlerts.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages alert messages displayed to the commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICommanderAlerts' (GUIScript)

GUICommanderAlerts.kAlertBadgeTextureName = "ui/commander_alert_badge.dds"
GUICommanderAlerts.kAlertBadgeTextureNameAlien = "ui/alien_commander_alert_badge.dds"
GUICommanderAlerts.kIconWidth = 80
GUICommanderAlerts.kIconHeight = 80
GUICommanderAlerts.kIconSizeScalar = 0.5
// Must be wide enough for the biggest message text.
GUICommanderAlerts.kBadgeWidth = 300
GUICommanderAlerts.kBadgeHeight = 50
// How much space between the edge of the badge and the text/icon.
GUICommanderAlerts.kBadgeWidthBuffer = 5

GUICommanderAlerts.kMessageFontSize = 18

// This is how high up the screen the messages should be offset from.
// This avoids them clipping over the tooltips.
GUICommanderAlerts.kMessageScreenYOffset = 200

GUICommanderAlerts.kTimeStartFade = 4
GUICommanderAlerts.kTimeEndFade = 6

function GUICommanderAlerts:Initialize()

    self.messages = { }
    self.reuseMessages = { }
    
end

function GUICommanderAlerts:Uninitialize()
    
    for i, message in ipairs(self.messages) do
        GUI.DestroyItem(message["Background"])
    end
    self.messages = { }
    
    for i, message in ipairs(self.reuseMessages) do
        GUI.DestroyItem(message["Background"])
    end
    self.reuseMessages = { }
    
end

function GUICommanderAlerts:SendKeyEvent(key, down)

    local numberMessages = table.count(self.messages)
    if down and numberMessages > 0 then
        if key == InputKey.Space then
            local latestMessage = self.messages[numberMessages]
            self:AlertClicked(latestMessage)
            return true
        elseif key == InputKey.MouseButton0 then
            local mouseX, mouseY = Client.GetCursorPosScreen()
            for i, message in ipairs(self.messages) do
                if GUIItemContainsPoint(message["Background"], mouseX, mouseY) then
                    self:AlertClicked(message)
                    return true
                end
            end
        end
    end
    return false

end

function GUICommanderAlerts:AlertClicked(alertMessage)

    local entityIsRelevant = Shared.GetEntity(alertMessage["EntityId"])
    if entityIsRelevant then
        CommanderUI_ClickedEntityAlert(alertMessage["EntityId"])
    else
        CommanderUI_ClickedLocationAlert(alertMessage["MapX"], alertMessage["MapZ"])
    end

end

function GUICommanderAlerts:Update(deltaTime)

    // Format is:
    // Location -> text, icon x offset, icon y offset, map x, map y
    // Entity -> text, icon x offset, icon y offset, -1, entity id

    local addAlertMessages = CommanderUI_GetAlertMessages()
    local numberElementsPerMessage = 6
    local numberMessages = table.count(addAlertMessages) / numberElementsPerMessage
    local currentIndex = 1
    while numberMessages > 0 do
        local text = addAlertMessages[currentIndex]
        local iconXOffset = addAlertMessages[currentIndex + 1]
        local iconYOffset = addAlertMessages[currentIndex + 2]
        local entityId = addAlertMessages[currentIndex + 3]
        local mapX = addAlertMessages[currentIndex + 4]
        local mapZ = addAlertMessages[currentIndex + 5]
        self:AddMessage(text, iconXOffset, iconYOffset, entityId, mapX, mapZ)
        currentIndex = currentIndex + numberElementsPerMessage
        numberMessages = numberMessages - 1
    end
    
    local removeMessages = { }
    // Update existing messages.
    local numberMessages = table.count(self.messages)
    for i, message in ipairs(self.messages) do
        local currentPosition = Vector(message["Background"]:GetPosition())
        currentPosition.y = GUICommanderAlerts.kBadgeHeight * (numberMessages - i) - GUICommanderAlerts.kMessageScreenYOffset
        message["Background"]:SetPosition(currentPosition)
        message["Time"] = message["Time"] + deltaTime
        if message["Time"] >= GUICommanderAlerts.kTimeStartFade then
            local fadeAmount = ((GUICommanderAlerts.kTimeEndFade - message["Time"]) / (GUICommanderAlerts.kTimeEndFade - GUICommanderAlerts.kTimeStartFade))
            local currentColor = message["Background"]:GetColor()
            currentColor.a = fadeAmount
            message["Background"]:SetColor(currentColor)
            if message["Time"] >= GUICommanderAlerts.kTimeEndFade then
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
 
end

function GUICommanderAlerts:AddMessage(text, iconXOffset, iconYOffset, entityId, mapX, mapZ)
    
    ASSERT(type(text) == "string")
    ASSERT(type(iconXOffset) == "number")
    ASSERT(type(iconYOffset) == "number")
    ASSERT(mapX ~= nil, "mapX passed in is nil")
    ASSERT(mapZ ~= nil, "mapZ passed in is nil")
    
    local insertMessage = { Background = nil, Message = nil, Icon = nil, Time = 0, EntityId = entityId, MapX = mapX, MapZ = mapZ }
    
    // Check if we can reuse an existing message.
    if table.count(self.reuseMessages) > 0 then
        insertMessage = self.reuseMessages[1]
        insertMessage["Time"] = 0
        insertMessage["Background"]:SetIsVisible(true)
        local currentColor = insertMessage["Background"]:GetColor()
        currentColor.a = 1
        insertMessage["Background"]:SetColor(currentColor)
        insertMessage["EntityId"] = entityId
        insertMessage["MapX"] = mapX
        insertMessage["MapZ"] = mapZ
        table.remove(self.reuseMessages, 1)
    end
    
    if insertMessage["Icon"] == nil then
        insertMessage["Icon"] = GUIManager:CreateGraphicItem()
    end
    local iconScaledWidth = GUICommanderAlerts.kIconWidth * GUICommanderAlerts.kIconSizeScalar
    local iconScaledHeight = GUICommanderAlerts.kIconHeight * GUICommanderAlerts.kIconSizeScalar
    insertMessage["Icon"]:SetSize(Vector(iconScaledWidth, iconScaledHeight, 0))
    insertMessage["Icon"]:SetAnchor(GUIItem.Left, GUIItem.Center)
    insertMessage["Icon"]:SetPosition(Vector(GUICommanderAlerts.kBadgeWidthBuffer, -iconScaledHeight / 2, 0))
    insertMessage["Icon"]:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    
    local pixelXOffset = iconXOffset * GUICommanderAlerts.kIconWidth
    local pixelYOffset = iconYOffset * GUICommanderAlerts.kIconHeight
    insertMessage["Icon"]:SetTexturePixelCoordinates(pixelXOffset, pixelYOffset, pixelXOffset + GUICommanderAlerts.kIconWidth, pixelYOffset + GUICommanderAlerts.kIconHeight)
    insertMessage["Icon"]:SetInheritsParentAlpha(true)
    
    if insertMessage["Message"] == nil then
        insertMessage["Message"] = GUIManager:CreateTextItem()
    end
    insertMessage["Message"]:SetFontSize(GUICommanderAlerts.kMessageFontSize)
    insertMessage["Message"]:SetAnchor(GUIItem.Right, GUIItem.Center)
    insertMessage["Message"]:SetTextAlignmentX(GUIItem.Align_Min)
    insertMessage["Message"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Message"]:SetText(text)
    insertMessage["Message"]:SetInheritsParentAlpha(true)
    insertMessage["Message"]:SetPosition(Vector(GUICommanderAlerts.kBadgeWidthBuffer, 0, 0))
    
    // Only set children the first time this message is created.
    if insertMessage["Background"] == nil then
        insertMessage["Background"] = GUIManager:CreateGraphicItem()
        insertMessage["Background"]:SetLayer(kGUILayerCommanderAlerts)
        insertMessage["Background"]:AddChild(insertMessage["Icon"])
        insertMessage["Icon"]:AddChild(insertMessage["Message"])
    end
    insertMessage["Background"]:SetSize(Vector(GUICommanderAlerts.kBadgeWidth, GUICommanderAlerts.kBadgeHeight, 0))
    insertMessage["Background"]:SetAnchor(GUIItem.Right, GUIItem.Center)
    insertMessage["Background"]:SetPosition(Vector(-GUICommanderAlerts.kBadgeWidth, 0, 0))
    local badgeTextureName = GUICommanderAlerts.kAlertBadgeTextureName
    if CommanderUI_IsAlienCommander() then
        badgeTextureName = GUICommanderAlerts.kAlertBadgeTextureNameAlien
    end
    insertMessage["Background"]:SetTexture(badgeTextureName)

    table.insert(self.messages, insertMessage)
    
end

function GUICommanderAlerts:ContainsPoint(pointX, pointY)

    for i, message in ipairs(self.messages) do
        if GUIItemContainsPoint(message["Background"], pointX, pointY) then
            return true
        end
    end
    return false

end
