// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIHotkeyIcons.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the displaying the hotkey icons and registering mouse presses on them.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIHotkeyIcons' (GUIScript)

GUIHotkeyIcons.kMaxHotkeys = Player.kMaxHotkeyGroups

GUIHotkeyIcons.kHotkeyIconSize = 20
// The buffer between icons.
GUIHotkeyIcons.kHotkeyIconXOffset = 2

GUIHotkeyIcons.kBackgroundWidth = (GUIHotkeyIcons.kHotkeyIconSize + GUIHotkeyIcons.kHotkeyIconXOffset) * GUIHotkeyIcons.kMaxHotkeys
GUIHotkeyIcons.kBackgroundHeight = GUIHotkeyIcons.kHotkeyIconSize

GUIHotkeyIcons.kHoykeyFontSize = 16

GUIHotkeyIcons.kHotkeyTextureWidth = 80
GUIHotkeyIcons.kHotkeyTextureHeight = 80

function GUIHotkeyIcons:Initialize()

    self.mousePressed = nil
    
    self.hotkeys = { }
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIHotkeyIcons.kBackgroundWidth, GUIHotkeyIcons.kBackgroundHeight, 0))
    // The background is an invisible container only.
    self.background:SetColor(Color(0, 0, 0, 0))
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetPosition(Vector(0, -GUIHotkeyIcons.kBackgroundHeight, 0))
    
    local currentHotkey = 0
    while currentHotkey < GUIHotkeyIcons.kMaxHotkeys do
        local hotkeyIcon = GUIManager:CreateGraphicItem()
        hotkeyIcon:SetSize(Vector(GUIHotkeyIcons.kHotkeyIconSize, GUIHotkeyIcons.kHotkeyIconSize, 0))
        hotkeyIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
        hotkeyIcon:SetPosition(Vector(currentHotkey * (GUIHotkeyIcons.kHotkeyIconSize + GUIHotkeyIcons.kHotkeyIconXOffset), 0, 0))
        hotkeyIcon:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
        hotkeyIcon:SetIsVisible(false)
        self.background:AddChild(hotkeyIcon)
        
        local hotkeyText = GUIManager:CreateTextItem()
        hotkeyText:SetFontSize(GUIHotkeyIcons.kHoykeyFontSize)
        hotkeyText:SetAnchor(GUIItem.Middle, GUIItem.Top)
        hotkeyText:SetTextAlignmentX(GUIItem.Align_Center)
        hotkeyText:SetTextAlignmentY(GUIItem.Align_Max)
        hotkeyText:SetColor(Color(1, 1, 1, 1))
        hotkeyText:SetText(ToString(currentHotkey + 1))
        hotkeyIcon:AddChild(hotkeyText)
        
        table.insert(self.hotkeys, { Icon = hotkeyIcon, Text = hotkeyText })
        
        currentHotkey = currentHotkey + 1
    end

end

function GUIHotkeyIcons:Uninitialize()
    
    // Everything is attached to the background so destroying it will destroy everything else.
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
        self.hotkeys = { }
    end
    
end

function GUIHotkeyIcons:Update(deltaTime)
    
    PROFILE("GUIHotkeyIcons:Update")
    
    local numHotkeys = CommanderUI_GetTotalHotkeys()
    if numHotkeys > 0 then
        self.background:SetIsVisible(true)
        local currentHotkey = 0
        while currentHotkey < GUIHotkeyIcons.kMaxHotkeys do
            local hotkeyTable = self.hotkeys[currentHotkey + 1]
            local coordinates = CommanderUI_GetHotkeyIconOffset(currentHotkey + 1)
            if coordinates then
                hotkeyTable.Icon:SetIsVisible(true)
                hotkeyTable.Text:SetText(CommanderUI_GetHotkeyName(currentHotkey + 1))
                local x1 = GUIHotkeyIcons.kHotkeyTextureWidth * coordinates[1]
                local x2 = x1 + GUIHotkeyIcons.kHotkeyTextureWidth
                local y1 = GUIHotkeyIcons.kHotkeyTextureHeight * coordinates[2]
                local y2 = y1 + GUIHotkeyIcons.kHotkeyTextureHeight
                hotkeyTable.Icon:SetTexturePixelCoordinates(x1, y1, x2, y2)
            else
                // No coordinates, this hotkey is not valid (has no entities in the group).
                hotkeyTable.Icon:SetIsVisible(false)
            end
            currentHotkey = currentHotkey + 1
        end
    else
        self.background:SetIsVisible(false)
    end
    
end

function GUIHotkeyIcons:SendKeyEvent(key, down)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    if key == InputKey.MouseButton0 and self.mousePressed ~= down then
        self.mousePressed = down
        if down then
            self:MousePressed(key, mouseX, mouseY)
        end
    end
    
end

function GUIHotkeyIcons:MousePressed(key, mouseX, mouseY)

    if key == InputKey.MouseButton0 then
        local currentHotkey = 0
        while currentHotkey < GUIHotkeyIcons.kMaxHotkeys do
            local hotkeyTable = self.hotkeys[currentHotkey + 1]
            if hotkeyTable.Icon:GetIsVisible() and GUIItemContainsPoint(hotkeyTable.Icon, mouseX, mouseY) then
                CommanderUI_SelectHotkey(currentHotkey + 1)
                break
            end
            currentHotkey = currentHotkey + 1
        end
    end

end

function GUIHotkeyIcons:GetBackground()

    return self.background

end

function GUIHotkeyIcons:ContainsPoint(pointX, pointY)

    return GUIItemContainsPoint(self:GetBackground(), pointX, pointY)

end
