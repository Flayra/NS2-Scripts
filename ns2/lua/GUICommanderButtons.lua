// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderButtons.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the right commander panel used to display buttons for commander actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIBorderBackground.lua")
Script.Load("lua/GUICommanderTooltip.lua")

class 'GUICommanderButtons' (GUIScript)

GUICommanderButtons.kButtonStatusDisabled = { Id = 0, Color = Color(0, 0, 0, 0), Visible = false }
GUICommanderButtons.kButtonStatusEnabled = { Id = 1, Color = Color(1, 1, 1, 1), Visible = true }
GUICommanderButtons.kButtonStatusRed = { Id = 2, Color = Color(1, 0, 0, 1), Visible = true }
GUICommanderButtons.kButtonStatusOff = { Id = 3, Color = Color(0.3, 0.3, 0.3, 1), Visible = true }
GUICommanderButtons.kButtonStatusData = { }
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusDisabled.Id] = GUICommanderButtons.kButtonStatusDisabled
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusEnabled.Id] = GUICommanderButtons.kButtonStatusEnabled
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusRed.Id] = GUICommanderButtons.kButtonStatusRed
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusOff.Id] = GUICommanderButtons.kButtonStatusOff

GUICommanderButtons.kBackgroundTexturePartWidth = 60
GUICommanderButtons.kBackgroundTexturePartHeight = 46
GUICommanderButtons.kBackgroundWidth = 464 * kCommanderGUIsGlobalScale
GUICommanderButtons.kBackgroundHeight = 334 * kCommanderGUIsGlobalScale
GUICommanderButtons.kBackgroundTextureCoords = { X1 = 0, Y1 = 0, X2 = 464, Y2 = 334 }
// The background is offset from the edge of the screen.
GUICommanderButtons.kBackgroundOffset = 10

// Used just for testing.
GUICommanderButtons.kExtraYOffset = 0

GUICommanderButtons.kButtonWidth = (CommanderUI_MenuButtonWidth() + 10) * kCommanderGUIsGlobalScale
GUICommanderButtons.kButtonHeight = (CommanderUI_MenuButtonHeight() + 10) * kCommanderGUIsGlobalScale
GUICommanderButtons.kButtonXOffset = 50
GUICommanderButtons.kButtonYOffset = 30

GUICommanderButtons.kMarineTabTextureCoords = { }
GUICommanderButtons.kMarineTabTextureCoords.TopNormal = { X1 = 7, Y1 = 340, X2 = 106, Y2 = 381 }
GUICommanderButtons.kMarineTabTextureCoords.BottomNormal = { X1 = 7, Y1 = 391, X2 = 106, Y2 = 400 }
GUICommanderButtons.kMarineTabTextureCoords.TopRollover = { X1 = 117, Y1 = 340, X2 = 216, Y2 = 381 }
GUICommanderButtons.kMarineTabTextureCoords.BottomRollover = { X1 = 117, Y1 = 391, X2 = 216, Y2 = 400 }
GUICommanderButtons.kMarineTabTextureCoords.TopSelected = { X1 = 226, Y1 = 340, X2 = 325, Y2 = 381 }
GUICommanderButtons.kMarineTabTextureCoords.BottomSelected = { X1 = 226, Y1 = 391, X2 = 325, Y2 = 400 }
GUICommanderButtons.kMarineTabTextureCoords.ConnectorMiddle = { X1 = 338, Y1 = 345, X2 = 447, Y2 = 360 }
GUICommanderButtons.kMarineTabTextureCoords.ConnectorSide = { X1 = 338, Y1 = 370, X2 = 447, Y2 = 385 }

GUICommanderButtons.kTabFontSize = 18
GUICommanderButtons.kTabAlpha = 0.75

GUICommanderButtons.kBuildMenuTextureWidth = 80
GUICommanderButtons.kBuildMenuTextureHeight = 80

// Also used for player alerts icon
GUICommanderButtons.kIdleWorkersSize = 48
GUICommanderButtons.kIdleWorkersXOffset = 5
GUICommanderButtons.kIdleWorkersFontSize = 20

GUICommanderButtons.kPlayerAlertX = -2 * (GUICommanderButtons.kIdleWorkersXOffset + GUICommanderButtons.kIdleWorkersSize)

GUICommanderButtons.kSelectAllPlayersX = 10
GUICommanderButtons.kSelectAllPlayersY = 90
GUICommanderButtons.kSelectAllPlayersSize = 48

function GUICommanderButtons:Initialize()

    self.backgroundTextureName = self:GetBackgroundTextureName()
    
    // The Marine buttons have tabs at the top for the first row of buttons.
    self.tabs = { }
    // The rest of the non-tab buttons are stored here.
    self.bottomButtons = { }
    // All buttons are always stored here for Marine and Aliens.
    self.buttons = { }
    
    if CommanderUI_IsAlienCommander() then
        self:InitializeAlienBackground()
    else
        self:InitializeMarineBackground()
    end
    
    self:InitializeScanlines()
    
    self:InitializeButtons()
    
    self:InitializeTooltip()
    
    self:InitializeIdleWorkersIcon()
    
    self:InitializePlayerAlertIcon()
    
    self:InitializeSelectAllPlayersIcon()
    
    self.mousePressed = { LMB = { Down = nil, X = 0, Y = 0 }, RMB = { Down = nil, X = 0, Y = 0 } }
    
    self.lastPressedTab = nil
    
end

function GUICommanderButtons:InitializeAlienBackground()

    // Same as marine for now.
    self:InitializeMarineBackground()
    
end

function GUICommanderButtons:InitializeMarineBackground()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetLayer(kGUILayerCommanderHUD)
    self.background:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.background:SetSize(Vector(GUICommanderButtons.kBackgroundWidth, GUICommanderButtons.kBackgroundHeight, 0))
    local posX = -GUICommanderButtons.kBackgroundWidth - GUICommanderButtons.kBackgroundOffset
    local posY = -GUICommanderButtons.kBackgroundHeight - GUICommanderButtons.kBackgroundOffset - GUICommanderButtons.kExtraYOffset
    self.background:SetPosition(Vector(posX, posY, 0))
    self.background:SetTexture(self.backgroundTextureName)
    GUISetTextureCoordinatesTable(self.background, GUICommanderButtons.kBackgroundTextureCoords)

end

function GUICommanderButtons:InitializeScanlines()

    local settingsTable = { }
    settingsTable.Width = GUICommanderButtons.kBackgroundWidth
    settingsTable.Height = GUICommanderButtons.kBackgroundHeight
    // The amount of extra scanline space that should be above the minimap.
    settingsTable.ExtraHeight = 20
    self.scanlines = GUIScanlines()
    self.scanlines:Initialize(settingsTable)
    self.scanlines:GetBackground():SetInheritsParentAlpha(true)
    self.background:AddChild(self.scanlines:GetBackground())
    
end

function GUICommanderButtons:InitializeHighlighter()

    self.highlightItem = GUIManager:CreateGraphicItem()
    self.highlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.highlightItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
    self.highlightItem:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    local textureWidth, textureHeight = CommanderUI_MenuImageSize()
    local buttonWidth = CommanderUI_MenuButtonWidth()
    local buttonHeight = CommanderUI_MenuButtonHeight()
    self.highlightItem:SetTexturePixelCoordinates(textureWidth - buttonWidth, textureHeight - buttonHeight, textureWidth, textureHeight)
    self.highlightItem:SetIsVisible(false)

end

function GUICommanderButtons:SharedInitializeButtons(settingsTable)

    self.numberOfTabs = settingsTable.NumberOfTabs
    // Tab row.
    for t = 1, self.numberOfTabs do

        // Top tab item first.
        local topItem = GUIManager:CreateGraphicItem()
        topItem:SetAnchor(GUIItem.Left, GUIItem.Top)
        topItem:SetSize(Vector(settingsTable.TabWidth, settingsTable.TabTopHeight, 0))
        local xPos = settingsTable.TabXOffset + (((t - 1) % settingsTable.NumberOfColumns) * (settingsTable.TabWidth + settingsTable.TabSpacing))
        local yPos = settingsTable.TabYOffset
        topItem:SetPosition(Vector(xPos, yPos, 0))
        topItem:SetTexture(self.backgroundTextureName)
        topItem:SetColor(Color(1, 1, 1, GUICommanderButtons.kTabAlpha))
        self.background:AddChild(topItem)
        
        // Bottom tab item next.
        local bottomItem = GUIManager:CreateGraphicItem()
        bottomItem:SetAnchor(GUIItem.Left, GUIItem.Bottom)
        bottomItem:SetSize(Vector(settingsTable.TabWidth, settingsTable.TabBottomHeight, 0))
        bottomItem:SetPosition(Vector(0, settingsTable.TabBottomOffset, 0))
        bottomItem:SetTexture(self.backgroundTextureName)
        bottomItem:SetInheritsParentAlpha(true)
        topItem:AddChild(bottomItem)
        
        // Tab text.
        local textItem = GUIManager:CreateTextItem()
        textItem:SetFontSize(GUICommanderButtons.kTabFontSize)
        textItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
        textItem:SetTextAlignmentX(GUIItem.Align_Center)
        textItem:SetTextAlignmentY(GUIItem.Align_Center)
        textItem:SetColor(Color(1, 1, 1, 1))
        textItem:SetFontIsBold(true)
        topItem:AddChild(textItem)
        
        // Connector item.
        local connectorItem = GUIManager:CreateGraphicItem()
        connectorItem:SetAnchor(GUIItem.Left, GUIItem.Bottom)
        connectorItem:SetSize(Vector(settingsTable.TabConnectorWidth, settingsTable.TabConnectorHeight, 0))
        connectorItem:SetTexture(self.backgroundTextureName)
        local coords = GUICommanderButtons.kMarineTabTextureCoords.ConnectorMiddle
        // Use the special side connector texture for the edges.
        if t == 1 or t == self.numberOfTabs then
            coords = GUICommanderButtons.kMarineTabTextureCoords.ConnectorSide
        end
        // Mirror if this tab is on the right edge.
        if t == self.numberOfTabs then
            // The right one needs to be moved a bit to the left to match up with the bottom item.
            connectorItem:SetPosition(Vector(settingsTable.TabWidth - settingsTable.TabConnectorWidth, 0, 0))
            connectorItem:SetScale(Vector(-1, 1, 1))
        end
        GUISetTextureCoordinatesTable(connectorItem, coords)
        connectorItem:SetIsVisible(false)
        bottomItem:AddChild(connectorItem)
        
        local tabItem = { TopItem = topItem, BottomItem = bottomItem, TextItem = textItem, ConnectorItem = connectorItem }
        table.insert(self.buttons, topItem)
        table.insert(self.tabs, tabItem)

    end
    
    // Button rows.
    for i = 1, settingsTable.NumberOfButtons do
    
        local buttonItem = GUIManager:CreateGraphicItem()
        buttonItem:SetAnchor(GUIItem.Left, GUIItem.Top)
        buttonItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
        local xPos = ((i - 1) % settingsTable.NumberOfColumns) * GUICommanderButtons.kButtonWidth
        local yPos = math.floor(((i - 1) / settingsTable.NumberOfColumns)) * GUICommanderButtons.kButtonHeight
        yPos = yPos + settingsTable.ButtonYOffset + settingsTable.TabTopHeight + settingsTable.TabBottomHeight
        buttonItem:SetPosition(Vector(xPos + GUICommanderButtons.kButtonXOffset, yPos + GUICommanderButtons.kButtonYOffset, 0))
        buttonItem:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
        self.background:AddChild(buttonItem)
        table.insert(self.buttons, buttonItem)
        table.insert(self.bottomButtons, buttonItem)
        self:UpdateButtonStatus(i + self.numberOfTabs)
        
    end

end

function GUICommanderButtons:InitializeTooltip()

    local settingsTable = { }
    settingsTable.Width = GUICommanderButtons.kBackgroundWidth
    settingsTable.Height = 40
    settingsTable.X = 0
    settingsTable.Y = -40
    settingsTable.TexturePartWidth = GUICommanderButtons.kBackgroundTexturePartWidth
    settingsTable.TexturePartHeight = GUICommanderButtons.kBackgroundTexturePartHeight

    self.tooltip = GUICommanderTooltip()
    self.tooltip:Initialize(settingsTable)
    self.background:AddChild(self.tooltip:GetBackground())

end

function GUICommanderButtons:InitializeIdleWorkersIcon()

    self.idleWorkers = GUIManager:CreateGraphicItem()
    self.idleWorkers:SetSize(Vector(GUICommanderButtons.kIdleWorkersSize, GUICommanderButtons.kIdleWorkersSize, 0))
    self.idleWorkers:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.idleWorkers:SetPosition(Vector(-GUICommanderButtons.kIdleWorkersSize - GUICommanderButtons.kIdleWorkersXOffset, 0, 0))
    self.idleWorkers:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    local coordinates = CommanderUI_GetIdleWorkerOffset()
    local x1 = GUICommanderButtons.kBuildMenuTextureWidth * coordinates[1]
    local x2 = x1 + GUICommanderButtons.kBuildMenuTextureWidth
    local y1 = GUICommanderButtons.kBuildMenuTextureHeight * coordinates[2]
    local y2 = y1 + GUICommanderButtons.kBuildMenuTextureHeight
    self.idleWorkers:SetTexturePixelCoordinates(x1, y1, x2, y2)
    self.idleWorkers:SetIsVisible(false)
    self.background:AddChild(self.idleWorkers)
    
    self.idleWorkersText = GUIManager:CreateTextItem()
    self.idleWorkersText:SetFontSize(GUICommanderButtons.kIdleWorkersFontSize)
    self.idleWorkersText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.idleWorkersText:SetTextAlignmentX(GUIItem.Align_Center)
    self.idleWorkersText:SetTextAlignmentY(GUIItem.Align_Min)
    self.idleWorkersText:SetColor(Color(1, 1, 1, 1))
    self.idleWorkers:AddChild(self.idleWorkersText)

end

function GUICommanderButtons:InitializePlayerAlertIcon()

    self.playerAlerts = GUIManager:CreateGraphicItem()
    self.playerAlerts:SetSize(Vector(GUICommanderButtons.kIdleWorkersSize, GUICommanderButtons.kIdleWorkersSize, 0))
    self.playerAlerts:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.playerAlerts:SetPosition(Vector(GUICommanderButtons.kPlayerAlertX, 0, 0))
    self.playerAlerts:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    
    local coordinates = CommanderUI_GetPlayerAlertOffset()
    local x1 = GUICommanderButtons.kBuildMenuTextureWidth * coordinates[1]
    local x2 = x1 + GUICommanderButtons.kBuildMenuTextureWidth
    local y1 = GUICommanderButtons.kBuildMenuTextureHeight * coordinates[2]
    local y2 = y1 + GUICommanderButtons.kBuildMenuTextureHeight
    self.playerAlerts:SetTexturePixelCoordinates(x1, y1, x2, y2)
    self.playerAlerts:SetIsVisible(false)
    self.background:AddChild(self.playerAlerts)
    
    self.playerAlertsText = GUIManager:CreateTextItem()
    self.playerAlertsText:SetFontSize(GUICommanderButtons.kIdleWorkersFontSize)
    self.playerAlertsText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.playerAlertsText:SetTextAlignmentX(GUIItem.Align_Center)
    self.playerAlertsText:SetTextAlignmentY(GUIItem.Align_Min)
    self.playerAlertsText:SetColor(Color(1, 1, 1, 1))
    self.playerAlertsText:SetText("0")
    self.playerAlerts:AddChild(self.playerAlertsText)

end

function GUICommanderButtons:InitializeSelectAllPlayersIcon()

    self.selectAllPlayers = GUIManager:CreateGraphicItem()
    self.selectAllPlayers:SetSize(Vector(GUICommanderButtons.kSelectAllPlayersSize, GUICommanderButtons.kSelectAllPlayersSize, 0))
    self.selectAllPlayers:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.selectAllPlayers:SetPosition(Vector(GUICommanderButtons.kSelectAllPlayersX, GUICommanderButtons.kSelectAllPlayersY, 0))
    self.selectAllPlayers:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    
    local coordinates = CommanderUI_GetPlayerAlertOffset()
    local x1 = GUICommanderButtons.kBuildMenuTextureWidth * coordinates[1]
    local x2 = x1 + GUICommanderButtons.kBuildMenuTextureWidth
    local y1 = GUICommanderButtons.kBuildMenuTextureHeight * coordinates[2]
    local y2 = y1 + GUICommanderButtons.kBuildMenuTextureHeight
    self.selectAllPlayers:SetTexturePixelCoordinates(x1, y1, x2, y2)
    self.selectAllPlayers:SetIsVisible(false)
    
end

function GUICommanderButtons:Uninitialize()

    if self.highlightItem then
        GUI.DestroyItem(self.highlightItem)
        self.highlightItem = nil
    end
    
    if self.tooltip then
        self.tooltip:Uninitialize()
        self.tooltip = nil    
    end
    
    if self.idleWorkers then
        GUI.DestroyItem(self.idleWorkers)
        self.idleWorkers = nil
    end

    if self.playerAlerts then
        GUI.DestroyItem(self.playerAlerts)
        self.playerAlerts = nil
    end

    if self.selectAllPlayers then
        GUI.DestroyItem(self.selectAllPlayers)
        self.selectAllPlayers = nil
    end
    
    if self.scanlines then
        self.scanlines:Uninitialize()
        self.scanlines = nil
    end
    
    // Everything is attached to the background so destroying it will
    // destroy everything else.
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
        self.tabs = { }
        self.bottomButtons = { }
        self.buttons = { }
    end
    
end

// Returns the main button list, does not include tabs.
function GUICommanderButtons:GetButtonList()

    local buttonList = self.buttons
    local indexOffset = 0
    if not CommanderUI_IsAlienCommander() then
        buttonList = self.bottomButtons
        indexOffset = self.numberOfTabs
    end
    
    return buttonList, indexOffset

end

function GUICommanderButtons:Update(deltaTime)

    PROFILE("GUICommanderButtons:Update")

    self:UpdateTabs()
    
    local tooltipButtonIndex = self:UpdateInput()
    
    self:UpdateTooltip(tooltipButtonIndex)
    
    self:UpdateIdleWorkersIcon()
    
    self:UpdateAlertIcon()
    
    self:UpdateSelectAllPlayersIcon()
    
    local buttonList, indexOffset = self:GetButtonList()
    
    for i, buttonItem in ipairs(buttonList) do
        self:UpdateButtonStatus(i + indexOffset)
    end
    
    self:UpdateButtonHotkeys()
    
    if self.scanlines then
        self.scanlines:Update(deltaTime)
    end
    
end

function ResetTabHighlight(tabTable)

    GUISetTextureCoordinatesTable(tabTable.TopItem, GUICommanderButtons.kMarineTabTextureCoords.TopNormal)
    GUISetTextureCoordinatesTable(tabTable.BottomItem, GUICommanderButtons.kMarineTabTextureCoords.BottomNormal)

end

function GUICommanderButtons:UpdateTabs()

    // Assume no tabs are pressed or highlighted.
    for i, tabTable in ipairs(self.tabs) do
        if self.lastPressedTab ~= tabTable then
            ResetTabHighlight(tabTable)
        end
        local tooltipData = CommanderUI_MenuButtonTooltip(i)
        if tooltipData[1] then
            tabTable.TextItem:SetText(tooltipData[1])
        end
    end

end

function GUICommanderButtons:UpdateInput()
    
    local tooltipButtonIndex = nil
    
    if self.highlightItem then
        self.highlightItem:SetIsVisible(false)
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if GUIItemContainsPoint(self.background, mouseX, mouseY) then
            for i, buttonItem in ipairs(self.buttons) do
                local buttonStatus = CommanderUI_MenuButtonStatus(i)
                if GUIItemContainsPoint(buttonItem, mouseX, mouseY) then
                    if (buttonItem:GetIsVisible() and buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id) and
                       (self.targetedButton == nil or self.targetedButton == i) then
                        self:HighlightButton(buttonItem)
                        tooltipButtonIndex = i
                        break
                    // Off or red buttons can still have a tooltip.
                    elseif buttonStatus == GUICommanderButtons.kButtonStatusOff.Id or buttonStatus == GUICommanderButtons.kButtonStatusRed.Id then
                        tooltipButtonIndex = i
                        break
                    end
                end
            end
        end
    end
    
    return tooltipButtonIndex

end

function GUICommanderButtons:HighlightButton(buttonItem)

    local foundTabTable = nil
    table.foreachfunctor(self.tabs, function (tabTable) if tabTable.TopItem == buttonItem then foundTabTable = tabTable end end)
    if foundTabTable ~= nil then
        if self.lastPressedTab ~= foundTabTable then
            GUISetTextureCoordinatesTable(foundTabTable.TopItem, GUICommanderButtons.kMarineTabTextureCoords.TopRollover)
            GUISetTextureCoordinatesTable(foundTabTable.BottomItem, GUICommanderButtons.kMarineTabTextureCoords.BottomRollover)
        end
    else
        if self.highlightItem:GetParent() then
            self.highlightItem:GetParent():RemoveChild(self.highlightItem)
        end
        buttonItem:AddChild(self.highlightItem)
        self.highlightItem:SetIsVisible(true)
    end

end

function GUICommanderButtons:UpdateTooltip(tooltipButtonIndex)

    local visible = tooltipButtonIndex ~= nil
    self.tooltip:SetIsVisible(visible)
    if visible then
        local tooltipData = CommanderUI_MenuButtonTooltip(tooltipButtonIndex)
        local text = tooltipData[1]
        local hotKey = tooltipData[2]
        local costNumber = tooltipData[3]
        local requires = tooltipData[4]
        local enabled = tooltipData[5]
        local info = tooltipData[6]
        local typeNumber = tooltipData[7]
        self.tooltip:UpdateData(text, hotKey, costNumber, requires, enabled, info, typeNumber)
    end

end

function GUICommanderButtons:UpdateIdleWorkersIcon()

    local numIdleWorkers = CommanderUI_GetIdleWorkerCount()
    if numIdleWorkers > 0 then
        self.idleWorkers:SetIsVisible(true)
        self.idleWorkersText:SetText(ToString(numIdleWorkers))
    else
        self.idleWorkers:SetIsVisible(false)
    end

end

function ScalePlayerAlertOperator(item, scalar)

    local newScalar = math.cos(scalar * math.sin(scalar * math.pi))
    local sizeVector = Vector(newScalar * GUICommanderButtons.kIdleWorkersSize, newScalar * GUICommanderButtons.kIdleWorkersSize, 0)
    item:SetSize(sizeVector)
    
    local sizeDifferenceX = GUICommanderButtons.kIdleWorkersSize - sizeVector.x
    local sizeDifferenceY = GUICommanderButtons.kIdleWorkersSize - sizeVector.y
    
    // Make sure it is always centered.
    item:SetPosition(Vector(GUICommanderButtons.kPlayerAlertX + sizeDifferenceX / 2, sizeDifferenceY / 2, 0))
    
end

// Shake item back and forth a bit
function ShakePlayerAlertOperator(item, scalar)

    local amount = math.floor((1 - scalar) * 5)
    scalar = math.cos(scalar * math.pi * 10)    
    local currentPosition = item:GetPosition()
    item:SetPosition(Vector(currentPosition.x + scalar * amount, currentPosition.y, 0))
    
end

function GUICommanderButtons:UpdateAlertIcon()
    
    local numAlerts = CommanderUI_GetPlayerAlertCount()
    
    if numAlerts > 0 then
    
        // Animate when new player alert received    
        local text = self.playerAlertsText:GetText()
        if text and (numAlerts > tonumber(text)) then
            GetGUIManager():StartAnimation(self.playerAlerts, ScalePlayerAlertOperator, 0, 1, .4)
            GetGUIManager():StartAnimation(self.playerAlerts, ShakePlayerAlertOperator, 0, 1, .8)
        end
        
        self.playerAlerts:SetIsVisible(true)
        self.playerAlertsText:SetText(ToString(numAlerts))            
        self.playerAlertsText:SetIsVisible(true)            
    
    else
        self.playerAlerts:SetIsVisible(false)
        self.playerAlertsText:SetIsVisible(false)
    end
    
end

function GUICommanderButtons:UpdateSelectAllPlayersIcon()

    if (self.timeOfLastUpdateSelectAll == nil) or (Shared.GetTime() > self.timeOfLastUpdateSelectAll + 1) then
    
        local player = Client.GetLocalPlayer()
        
        local friendlyPlayers = GetEntitiesForTeam("Marine", player:GetTeamNumber())
        
        local visState = false
        
        for index, marine in ipairs(friendlyPlayers) do
            if marine:GetIsAlive() then
                visState = true
                break
            end
        end
        
        self.selectAllPlayers:SetIsVisible(visState)
        
        self.timeOfLastUpdateSelectAll = Shared.GetTime()
        
    end
    
end

function GUICommanderButtons:UpdateButtonStatus(buttonIndex)

    local buttonStatus = CommanderUI_MenuButtonStatus(buttonIndex)
    local buttonItem = self.buttons[buttonIndex]
    
    buttonItem:SetIsVisible(GUICommanderButtons.kButtonStatusData[buttonStatus].Visible)
    buttonItem:SetColor(GUICommanderButtons.kButtonStatusData[buttonStatus].Color)
    
    if buttonItem:GetIsVisible() then
        local buttonWidth = CommanderUI_MenuButtonWidth()
        local buttonHeight = CommanderUI_MenuButtonHeight()
        local buttonXOffset = CommanderUI_MenuButtonXOffset(buttonIndex)
        local buttonYOffset = CommanderUI_MenuButtonYOffset(buttonIndex)

        if buttonXOffset and buttonYOffset then
            local textureXOffset = buttonXOffset * buttonWidth
            local textureYOffset = buttonYOffset * buttonHeight
            buttonItem:SetTexturePixelCoordinates(textureXOffset, textureYOffset, textureXOffset + buttonWidth, textureYOffset + buttonHeight)
        else
            // Display the whole texture if the offsets were not found.
            buttonItem:SetTextureCoordinates(0, 0, 1, 1)
        end
    end
    
    if self.targetedButton ~= nil then
        if self.targetedButton == buttonIndex then
            buttonItem:SetColor(GUICommanderButtons.kButtonStatusEnabled.Color)
        else
            buttonItem:SetColor(GUICommanderButtons.kButtonStatusOff.Color)
        end
    end

end

function GUICommanderButtons:UpdateButtonHotkeys()

    local triggeredButton = CommanderUI_HotkeyTriggeredButton()
    if triggeredButton ~= nil then
    
        local buttonStatus = CommanderUI_MenuButtonStatus(triggeredButton)
        
        // Only allow hotkeys on enabled buttons.
        if buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id then
        
            local player = Client.GetLocalPlayer()
            player:TriggerButtonIndex(triggeredButton, false)
            
        end
    end

end

function GUICommanderButtons:SetTargetedButton(setButton)

    self.targetedButton = setButton
    local buttonList, indexOffset = self:GetButtonList()
    for i, buttonItem in ipairs(buttonList) do
        self:UpdateButtonStatus(i + indexOffset)
    end

end

function GUICommanderButtons:GetTargetedButton()

    return self.targetedButton

end

function GUICommanderButtons:SendKeyEvent(key, down)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
        self.mousePressed["LMB"]["Down"] = down
        if down then
            self:MousePressed(key, mouseX, mouseY)
        end
    elseif key == InputKey.MouseButton1 and self.mousePressed["RMB"]["Down"] ~= down then
        self.mousePressed["RMB"]["Down"] = down
        if down then
            self:MousePressed(key, mouseX, mouseY)
        end
    end
    
end

function GUICommanderButtons:MousePressed(key, mouseX, mouseY)

    if key == InputKey.MouseButton1 then
        // Cancel targeted button upon right mouse press.
        if self.targetedButton ~= nil then
            self:SetTargetedButton(nil)
        end
    elseif key == InputKey.MouseButton0 then
        if self.idleWorkers:GetIsVisible() and GUIItemContainsPoint(self.idleWorkers, mouseX, mouseY) then
            CommanderUI_ClickedIdleWorker()
        elseif self.playerAlerts:GetIsVisible() and GUIItemContainsPoint(self.playerAlerts, mouseX, mouseY) then
            CommanderUI_ClickedPlayerAlert()           
        elseif self.selectAllPlayers:GetIsVisible() and GUIItemContainsPoint(self.selectAllPlayers, mouseX, mouseY) then
            CommanderUI_ClickedSelectAllPlayers()
        elseif self.targetedButton ~= nil then
            if CommanderUI_IsValid(self.targetedButton, mouseX, mouseY) then
                CommanderUI_TargetedAction(self.targetedButton, mouseX, mouseY, 1)
                self:SetTargetedButton(nil)
            end            
        else
            for i, buttonItem in ipairs(self.buttons) do
                local buttonStatus = CommanderUI_MenuButtonStatus(i)
                if buttonItem:GetIsVisible() and buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id and
                   GUIItemContainsPoint(buttonItem, mouseX, mouseY) then
                    self:ButtonPressed(i, mouseX, mouseY)
                    break
                end
            end
        end
    end

end

function DeselectTab(tabTable)

    GUISetTextureCoordinatesTable(tabTable.TopItem, GUICommanderButtons.kMarineTabTextureCoords.TopNormal)
    GUISetTextureCoordinatesTable(tabTable.BottomItem, GUICommanderButtons.kMarineTabTextureCoords.BottomNormal)
    tabTable.ConnectorItem:SetIsVisible(false)
    
end

function GUICommanderButtons:DeselectTab()

    table.foreachfunctor(self.tabs, DeselectTab)
    self.lastPressedTab = nil

end

function GUICommanderButtons:ButtonPressed(index, mouseX, mouseY)

    if CommanderUI_MenuButtonRequiresTarget(index) then
        self:SetTargetedButton(index)
    end
    
    CommanderUI_MenuButtonAction(index)
    
    self:SelectTab(index)    

end

function GUICommanderButtons:SelectTab(index)

    // If this button is a tab, change it to the selected state.
    local buttonItem = self.buttons[index]
    local foundTabTable = nil
    table.foreachfunctor(self.tabs, function (tabTable) if tabTable.TopItem == buttonItem then foundTabTable = tabTable end end)
    if foundTabTable then
    
        // Unselect all tabs and hide tab connectors first.
        table.foreachfunctor(self.tabs, DeselectTab)
        
        GUISetTextureCoordinatesTable(foundTabTable.TopItem, GUICommanderButtons.kMarineTabTextureCoords.TopSelected)
        GUISetTextureCoordinatesTable(foundTabTable.BottomItem, GUICommanderButtons.kMarineTabTextureCoords.BottomSelected)
        foundTabTable.ConnectorItem:SetIsVisible(true)
        self.lastPressedTab = foundTabTable

    else
        // This is a bit of a hack for now.
        local tooltipData = CommanderUI_MenuButtonTooltip(index)
        local isBackButton = tooltipData[1] == "Back"
        // Only the back button should unselect tabs and hide tab connectors.
        if isBackButton then
            table.foreachfunctor(self.tabs, DeselectTab)
            self.lastPressedTab = nil
        end
        
    end
    
end

function GUICommanderButtons:GetSelectedTab ()
    return self.lastPressedTab
end

function GUICommanderButtons:IsTabSelected (techId) 
    local techTree = GetTechTree()                
    local techText = techTree:GetDescriptionText(techId)
    
    if (self.lastPressedTab) then
        local tabText = self.lastPressedTab.TextItem:GetText()
        if (tabText == nil) then
            return false
        end
        
        if (tabText == techText) then
            return true
        end
    end
    
    return false
end

function GUICommanderButtons:IsTab(techId)
    local techTree = GetTechTree()                
    local techText = techTree:GetDescriptionText(techId)
    
    
    for i, tabTable in ipairs(self.tabs) do        
        local tabText = tabTable.TextItem:GetText()
        if (tabText == nil) then
            return false
        end
        
        if (tabText == techText) then
            return true
        end
    end    
end

function GUICommanderButtons:GetBackground()

    return self.background

end

function GUICommanderButtons:ContainsPoint(pointX, pointY)

    // Check if the point is over any of the UI managed by the GUICommanderButtons.
    local containsPoint = GUIItemContainsPoint(self.idleWorkers, pointX, pointY)
    containsPoint = containsPoint or GUIItemContainsPoint(self.playerAlerts, pointX, pointY)
    containsPoint = containsPoint or GUIItemContainsPoint(self.selectAllPlayers, pointX, pointY)
    return containsPoint or GUIItemContainsPoint(self.background, pointX, pointY)

end
