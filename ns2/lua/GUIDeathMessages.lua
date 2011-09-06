// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDeathMessages.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages messages displayed when something kills something else.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIDeathMessages' (GUIScript)

GUIDeathMessages.kBackgroundHeight = 32
GUIDeathMessages.kBackgroundColor = Color(0, 0, 0, 0)
GUIDeathMessages.kNameFontSize = 12
GUIDeathMessages.kScreenOffset = 16
GUIDeathMessages.kWeaponTextureName = "ui/messages_icons.dds"
GUIDeathMessages.kTimeStartFade = 3
GUIDeathMessages.kTimeEndFade = 4

function GUIDeathMessages:Initialize()

    self.messages = { }
    self.reuseMessages = { }
    
end

function GUIDeathMessages:Uninitialize()

    for i, message in ipairs(self.messages) do
        GUI.DestroyItem(message["Background"])
    end
    self.messages = nil
    
    for i, message in ipairs(self.reuseMessages) do
        GUI.DestroyItem(message["Background"])
    end
    self.reuseMessages = nil
    
end

function GUIDeathMessages:Update(deltaTime)

    PROFILE("GUIDeathMessages:Update")

    local addDeathMessages = DeathMsgUI_GetMessages()
    local numberElementsPerMessage = 5
    local numberMessages = table.count(addDeathMessages) / numberElementsPerMessage
    local currentIndex = 1
    while numberMessages > 0 do
        local killerColor = addDeathMessages[currentIndex]
        local killerName = addDeathMessages[currentIndex + 1]
        local targetColor = addDeathMessages[currentIndex + 2]
        local targetName = addDeathMessages[currentIndex + 3]
        local iconIndex = addDeathMessages[currentIndex + 4]
        self:AddMessage(killerColor, killerName, targetColor, targetName, iconIndex)
        currentIndex = currentIndex + numberElementsPerMessage
        numberMessages = numberMessages - 1
    end
    
    local removeMessages = { }
    // Update existing messages.
    for i, message in ipairs(self.messages) do
        local currentPosition = Vector(message["Background"]:GetPosition())
        currentPosition.y = GUIDeathMessages.kScreenOffset + (GUIDeathMessages.kBackgroundHeight * (i - 1))
        local playerIsCommander = CommanderUI_IsLocalPlayerCommander()
        currentPosition.x = message["BackgroundXOffset"] - ((playerIsCommander and message["BackgroundWidth"]) or 0)
        message["Background"]:SetPosition(currentPosition)
        message["Time"] = message["Time"] + deltaTime
        if message["Time"] >= GUIDeathMessages.kTimeStartFade then
            local fadeAmount = ((GUIDeathMessages.kTimeEndFade - message["Time"]) / (GUIDeathMessages.kTimeEndFade - GUIDeathMessages.kTimeStartFade))
            local currentColor = message["Killer"]:GetColor()
            currentColor.a = fadeAmount
            message["Killer"]:SetColor(currentColor)
            currentColor = message["Weapon"]:GetColor()
            currentColor.a = fadeAmount
            message["Weapon"]:SetColor(currentColor)
            currentColor = message["Target"]:GetColor()
            currentColor.a = fadeAmount
            message["Target"]:SetColor(currentColor)
            if message["Time"] >= GUIDeathMessages.kTimeEndFade then
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

function GUIDeathMessages:AddMessage(killerColor, killerName, targetColor, targetName, iconIndex)

    local xOffset = DeathMsgUI_GetTechOffsetX(0)
    local yOffset = DeathMsgUI_GetTechOffsetY(iconIndex)
    local iconWidth = DeathMsgUI_GetTechWidth(0)
    local iconHeight = DeathMsgUI_GetTechHeight(0)
    
    local insertMessage = { Background = nil, Killer = nil, Weapon = nil, Target = nil, Time = 0 }
    
    // Check if we can reuse an existing message.
    if table.count(self.reuseMessages) > 0 then
        insertMessage = self.reuseMessages[1]
        insertMessage["Time"] = 0
        insertMessage["Background"]:SetIsVisible(true)
        table.remove(self.reuseMessages, 1)
    end
    
    if insertMessage["Killer"] == nil then
        insertMessage["Killer"] = GUIManager:CreateTextItem()
    end
    insertMessage["Killer"]:SetFontSize(GUIDeathMessages.kNameFontSize)
    insertMessage["Killer"]:SetAnchor(GUIItem.Left, GUIItem.Center)
    insertMessage["Killer"]:SetTextAlignmentX(GUIItem.Align_Min)
    insertMessage["Killer"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Killer"]:SetColor(ColorIntToColor(killerColor))
    insertMessage["Killer"]:SetText(killerName)
    
    if insertMessage["Weapon"] == nil then
        insertMessage["Weapon"] = GUIManager:CreateGraphicItem()
    end
    insertMessage["Weapon"]:SetSize(Vector(iconWidth, iconHeight, 0))
    insertMessage["Weapon"]:SetAnchor(GUIItem.Middle, GUIItem.Center)
    insertMessage["Weapon"]:SetPosition(Vector(-iconWidth / 2, -iconHeight / 2, 0))
    insertMessage["Weapon"]:SetTexture(GUIDeathMessages.kWeaponTextureName)
    insertMessage["Weapon"]:SetTexturePixelCoordinates(xOffset, yOffset, xOffset + iconWidth, yOffset + iconHeight)
    insertMessage["Weapon"]:SetColor(Color(1, 1, 1, 1))
    
    if insertMessage["Target"] == nil then
        insertMessage["Target"] = GUIManager:CreateTextItem()
    end
    insertMessage["Target"]:SetFontSize(GUIDeathMessages.kNameFontSize)
    insertMessage["Target"]:SetAnchor(GUIItem.Right, GUIItem.Center)
    insertMessage["Target"]:SetTextAlignmentX(GUIItem.Align_Max)
    insertMessage["Target"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Target"]:SetColor(ColorIntToColor(targetColor))
    insertMessage["Target"]:SetText(targetName)
    
    local killerTextWidth = insertMessage["Killer"]:GetTextWidth(killerName)
    local targetTextWidth = insertMessage["Target"]:GetTextWidth(targetName)
    local textWidth = killerTextWidth + targetTextWidth
    
    if insertMessage["Background"] == nil then
        insertMessage["Background"] = GUIManager:CreateGraphicItem()
        insertMessage["Background"]:AddChild(insertMessage["Killer"])
        insertMessage["Background"]:AddChild(insertMessage["Weapon"])
        insertMessage["Background"]:AddChild(insertMessage["Target"])
    end
    insertMessage["BackgroundWidth"] = textWidth + iconWidth
    insertMessage["Background"]:SetSize(Vector(insertMessage["BackgroundWidth"], GUIDeathMessages.kBackgroundHeight, 0))
    insertMessage["Background"]:SetAnchor(GUIItem.Right, GUIItem.Top)
    insertMessage["BackgroundXOffset"] = -textWidth - iconWidth - GUIDeathMessages.kScreenOffset
    insertMessage["Background"]:SetPosition(Vector(insertMessage["BackgroundXOffset"], 0, 0))
    insertMessage["Background"]:SetColor(GUIDeathMessages.kBackgroundColor)

    table.insert(self.messages, insertMessage)
    
end
