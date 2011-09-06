// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUISelectionPanel.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the middle commander panel used to display info related to what is currently selected.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIIncrementBar.lua")

class 'GUISelectionPanel' (GUIScript)

GUISelectionPanel.kFontName = "MicrogrammaDMedExt"
GUISelectionPanel.kFontColor = Color(0.8, 0.8, 1)
GUISelectionPanel.kStatusFontColor = Color(0.9, 1, 0)

GUISelectionPanel.kSelectionTextureMarines = "ui/marine_commander_background.dds"
GUISelectionPanel.kSelectionTextureAliens = "ui/alien_commander_background.dds"

GUISelectionPanel.kSelectionTextureCoordinates = { X1 = 464, Y1 = 338, X2 = 741, Y2 = 578 }
GUISelectionPanel.kHealthIconCoordinates = { X1 = 764, Y1 = 546, X2 = 795, Y2 = 577 }
GUISelectionPanel.kArmorIconCoordinates = { X1 = 796, Y1 = 546, X2 = 827, Y2 = 577 }
GUISelectionPanel.kEnergyIconCoordinates = { X1 = 828, Y1 = 546, X2 = 859, Y2 = 577 }

// The panel will scale with the screen resolution. It is based on
// this screen width.
GUISelectionPanel.kPanelWidth = 277 * kCommanderGUIsGlobalScale
GUISelectionPanel.kPanelHeight = 240 * kCommanderGUIsGlobalScale

GUISelectionPanel.kSelectedIconXOffset = 25 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedIconYOffset = 45 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedIconSize = 80 * kCommanderGUIsGlobalScale
GUISelectionPanel.kMultiSelectedIconSize = GUISelectionPanel.kSelectedIconSize * 0.75
GUISelectionPanel.kSelectedIconTextureWidth = 80
GUISelectionPanel.kSelectedIconTextureHeight = 80

GUISelectionPanel.kSelectedNameFontSize = 16 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedNameYOffset = 25

GUISelectionPanel.kSelectedLocationTextFontSize = 16 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectionLocationNameYOffset = -30

GUISelectionPanel.kSelectionStatusTextYOffset = -44

GUISelectionPanel.kSelectionStatusBarYOffset = -20

GUISelectionPanel.kSelectedSquadTextFontSize = 16 * kCommanderGUIsGlobalScale

GUISelectionPanel.kResourceIconSize = 25 * kCommanderGUIsGlobalScale
GUISelectionPanel.kResourceIconXOffset = 2
GUISelectionPanel.kResourceIconYOffset = 2

GUISelectionPanel.kResourceTextXOffset = 2

GUISelectionPanel.kSelectedHealthTextFontSize = 15 * kCommanderGUIsGlobalScale

GUISelectionPanel.kSelectedCustomTextFontSize = 16 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedCustomTextXOffset = -183 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedCustomTextYOffset = 125 * kCommanderGUIsGlobalScale

GUISelectionPanel.kStatusBarWidth = 200 * kCommanderGUIsGlobalScale
GUISelectionPanel.kStatusBarHeight = 6 * kCommanderGUIsGlobalScale

function GUISelectionPanel:Initialize()

    self.textureName = GUISelectionPanel.kSelectionTextureMarines
    if CommanderUI_IsAlienCommander() then
        self.textureName = GUISelectionPanel.kSelectionTextureAliens
    end
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.background:SetTexture(self.textureName)
    self.background:SetSize(Vector(GUISelectionPanel.kPanelWidth, GUISelectionPanel.kPanelHeight, 0))
    self.background:SetPosition(Vector(-GUISelectionPanel.kPanelWidth, -GUISelectionPanel.kPanelHeight, 0))
    GUISetTextureCoordinatesTable(self.background, GUISelectionPanel.kSelectionTextureCoordinates)
    
    self:InitializeScanlines()
    
    self:InitializeSingleSelectionItems()
    self:InitializeMultiSelectionItems()
    
    self.highlightedMultiItem = 1
    self:InitializeHighlighter()

end

function GUISelectionPanel:InitializeScanlines()

    local settingsTable = { }
    settingsTable.Width = GUISelectionPanel.kPanelWidth
    settingsTable.Height = GUISelectionPanel.kPanelHeight
    // The amount of extra scanline space that should be above the panel.
    settingsTable.ExtraHeight = 20
    self.scanlines = GUIScanlines()
    self.scanlines:Initialize(settingsTable)
    self.scanlines:GetBackground():SetInheritsParentAlpha(true)
    self.background:AddChild(self.scanlines:GetBackground())
    
end

function GUISelectionPanel:InitializeHighlighter()

    self.highlightItem = GUIManager:CreateGraphicItem()
    self.highlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.highlightItem:SetSize(Vector(GUISelectionPanel.kMultiSelectedIconSize, GUISelectionPanel.kMultiSelectedIconSize, 0))
    self.highlightItem:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    local textureWidth, textureHeight = CommanderUI_MenuImageSize()
    local buttonWidth = CommanderUI_MenuButtonWidth()
    local buttonHeight = CommanderUI_MenuButtonHeight()
    self.highlightItem:SetTexturePixelCoordinates(textureWidth - buttonWidth, textureHeight - buttonHeight, textureWidth, textureHeight)
    self.highlightItem:SetIsVisible(false)

end

function GUISelectionPanel:InitializeSingleSelectionItems()

    self.singleSelectionItems = { }
    
    self.selectedIcon = GUIManager:CreateGraphicItem()
    self.selectedIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.selectedIcon:SetSize(Vector(GUISelectionPanel.kSelectedIconSize, GUISelectionPanel.kSelectedIconSize, 0))
    self.selectedIcon:SetPosition(Vector(GUISelectionPanel.kSelectedIconXOffset, GUISelectionPanel.kSelectedIconYOffset, 0))
    self.selectedIcon:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    self.selectedIcon:SetIsVisible(false)
    table.insert(self.singleSelectionItems, self.selectedIcon)
    self.background:AddChild(self.selectedIcon)
    
    self.selectedName = GUIManager:CreateTextItem()
    self.selectedName:SetFontSize(GUISelectionPanel.kSelectedNameFontSize)
    self.selectedName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedName:SetFontIsBold(true)
    self.selectedName:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.selectedName:SetPosition(Vector(0, GUISelectionPanel.kSelectedNameYOffset, 0))
    self.selectedName:SetTextAlignmentX(GUIItem.Align_Center)
    self.selectedName:SetTextAlignmentY(GUIItem.Align_Center)
    self.selectedName:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.selectedName)
    self.background:AddChild(self.selectedName)
    
    self.selectedLocationName = GUIManager:CreateTextItem()
    self.selectedLocationName:SetFontSize(GUISelectionPanel.kSelectedLocationTextFontSize)
    self.selectedLocationName:SetFontIsBold(true)
    self.selectedLocationName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedLocationName:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.selectedLocationName:SetPosition(Vector(0, GUISelectionPanel.kSelectionLocationNameYOffset, 0))
    self.selectedLocationName:SetTextAlignmentX(GUIItem.Align_Center)
    self.selectedLocationName:SetTextAlignmentY(GUIItem.Align_Center)
    self.selectedLocationName:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.selectedLocationName)
    self.background:AddChild(self.selectedLocationName)
    
    self.statusText = GUIManager:CreateTextItem()
    self.statusText:SetFontSize(GUISelectionPanel.kSelectedLocationTextFontSize)
    self.statusText:SetFontIsBold(true)
    self.statusText:SetFontName(GUISelectionPanel.kFontName)
    self.statusText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.statusText:SetPosition(Vector(0, GUISelectionPanel.kSelectionStatusTextYOffset, 0))
    self.statusText:SetTextAlignmentX(GUIItem.Align_Center)
    self.statusText:SetTextAlignmentY(GUIItem.Align_Center)
    self.statusText:SetColor(GUISelectionPanel.kStatusFontColor)
    table.insert(self.singleSelectionItems, self.statusText)
    self.background:AddChild(self.statusText)
    
    self.selectedSquadName = GUIManager:CreateTextItem()
    self.selectedSquadName:SetFontSize(GUISelectionPanel.kSelectedSquadTextFontSize)
    self.selectedSquadName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedSquadName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.selectedSquadName:SetPosition(Vector(0, GUISelectionPanel.kSelectedLocationTextFontSize, 0))
    self.selectedSquadName:SetTextAlignmentX(GUIItem.Align_Min)
    self.selectedSquadName:SetTextAlignmentY(GUIItem.Align_Min)
    self.selectedSquadName:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.selectedSquadName)
    self.background:AddChild(self.selectedSquadName)
    
    self.healthIcon = GUIManager:CreateGraphicItem()
    self.healthIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.healthIcon:SetSize(Vector(GUISelectionPanel.kResourceIconSize, GUISelectionPanel.kResourceIconSize, 0))
    self.healthIcon:SetPosition(Vector(GUISelectionPanel.kResourceIconXOffset, GUISelectionPanel.kResourceIconYOffset, 0))
    self.healthIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.healthIcon, GUISelectionPanel.kHealthIconCoordinates)
    self.selectedIcon:AddChild(self.healthIcon)
    
    self.healthText = GUIManager:CreateTextItem()
    self.healthText:SetFontSize(GUISelectionPanel.kSelectedHealthTextFontSize)
    self.healthText:SetFontName(GUISelectionPanel.kFontName)
    self.healthText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.healthText:SetPosition(Vector(GUISelectionPanel.kResourceTextXOffset, 0, 0))
    self.healthText:SetTextAlignmentX(GUIItem.Align_Min)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.healthText)
    self.healthIcon:AddChild(self.healthText)
    
    self.armorIcon = GUIManager:CreateGraphicItem()
    self.armorIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.armorIcon:SetSize(Vector(GUISelectionPanel.kResourceIconSize, GUISelectionPanel.kResourceIconSize, 0))
    self.armorIcon:SetPosition(Vector(GUISelectionPanel.kResourceIconXOffset, GUISelectionPanel.kResourceIconSize + GUISelectionPanel.kResourceIconYOffset, 0))
    self.armorIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.armorIcon, GUISelectionPanel.kArmorIconCoordinates)
    self.selectedIcon:AddChild(self.armorIcon)
    
    self.armorText = GUIManager:CreateTextItem()
    self.armorText:SetFontSize(GUISelectionPanel.kSelectedHealthTextFontSize)
    self.armorText:SetFontName(GUISelectionPanel.kFontName)
    self.armorText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.armorText:SetPosition(Vector(GUISelectionPanel.kResourceTextXOffset, 0, 0))
    self.armorText:SetTextAlignmentX(GUIItem.Align_Min)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.armorText)
    self.armorIcon:AddChild(self.armorText)
    
    self.energyIcon = GUIManager:CreateGraphicItem()
    self.energyIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.energyIcon:SetSize(Vector(GUISelectionPanel.kResourceIconSize, GUISelectionPanel.kResourceIconSize, 0))
    self.energyIcon:SetPosition(Vector(GUISelectionPanel.kResourceIconXOffset, GUISelectionPanel.kResourceIconSize * 2 + GUISelectionPanel.kResourceIconYOffset, 0))
    self.energyIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.energyIcon, GUISelectionPanel.kEnergyIconCoordinates)
    self.selectedIcon:AddChild(self.energyIcon)
    
    self.energyText = GUIManager:CreateTextItem()
    self.energyText:SetFontSize(GUISelectionPanel.kSelectedHealthTextFontSize)
    self.energyText:SetFontName(GUISelectionPanel.kFontName)
    self.energyText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.energyText:SetPosition(Vector(GUISelectionPanel.kResourceTextXOffset, 0, 0))
    self.energyText:SetTextAlignmentX(GUIItem.Align_Min)
    self.energyText:SetTextAlignmentY(GUIItem.Align_Center)
    self.energyText:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.energyText)
    self.energyIcon:AddChild(self.energyText)
    
    self.statusBar = GUIManager:CreateGraphicItem()
    self.statusBar:SetAnchor(GUIItem.Center, GUIItem.Bottom)
    self.statusBar:SetPosition(Vector(-GUISelectionPanel.kStatusBarWidth / 2, GUISelectionPanel.kSelectionStatusBarYOffset, 0))
    self.statusBar:SetSize(Vector(GUISelectionPanel.kStatusBarWidth, GUISelectionPanel.kStatusBarHeight, 0))
    self.statusBar:SetColor(PlayerUI_GetTeamColor())
    table.insert(self.singleSelectionItems, self.statusBar)
    self.background:AddChild(self.statusBar)
    
    self.customText = GUIManager:CreateTextItem()
    self.customText:SetFontSize(GUISelectionPanel.kSelectedCustomTextFontSize)
    self.customText:SetFontName(GUISelectionPanel.kFontName)
    self.customText:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.customText:SetPosition(Vector(GUISelectionPanel.kSelectedCustomTextXOffset, GUISelectionPanel.kSelectedCustomTextYOffset, 0))
    self.customText:SetTextAlignmentX(GUIItem.Align_Max)
    self.customText:SetTextAlignmentY(GUIItem.Align_Min)
    self.customText:SetColor(GUISelectionPanel.kFontColor)
    table.insert(self.singleSelectionItems, self.customText)
    self.background:AddChild(self.customText)

end

function GUISelectionPanel:InitializeMultiSelectionItems()

    self.multiSelectionIcons = { }
    
end

function GUISelectionPanel:Uninitialize()

    if self.scanlines then
        self.scanlines:Uninitialize()
        self.scanlines = nil
    end
    
    // Everything is attached to the background so destroying it will
    // destroy everything else.
    GUI.DestroyItem(self.background)
    self.background = nil
    self.selectedIcon = nil
    self.selectedName = nil
    self.selectedLocationName = nil
    self.multiSelectionIcons = { }
    
end

function GUISelectionPanel:Update(deltaTime)

    PROFILE("GUISelectionPanel:Update")
    
    self:UpdateSelected()
    
    if self.scanlines then
        self.scanlines:Update(deltaTime)
    end
    
end

function GUISelectionPanel:SetIsVisible(state)
    self.background:SetIsVisible(state)
    self.selectedIcon:SetIsVisible(state)
    self.healthIcon:SetIsVisible(state)
    self.armorIcon:SetIsVisible(state)
    self.energyIcon:SetIsVisible(state)
    self.statusBar:SetIsVisible(state)
    self.selectedName:SetIsVisible(state)
    self.selectedLocationName:SetIsVisible(state)
    self.statusText:SetIsVisible(state)
    self.selectedSquadName:SetIsVisible(state)
    self.armorText:SetIsVisible(state)
    self.energyText:SetIsVisible(state)
    self.customText:SetIsVisible(state)
end

function GUISelectionPanel:UpdateSelected()

    local selectedEntities = CommanderUI_GetSelectedEntities()
    local numberSelectedEntities = table.count(selectedEntities)
    self.selectedIcon:SetIsVisible(false)
    
    // Hide selection panel with nothing selected
    self:SetIsVisible(numberSelectedEntities > 0)
    
    
    if numberSelectedEntities > 0 then
    
        if numberSelectedEntities == 1 then
            self:UpdateSingleSelection(selectedEntities[1])
        else
        
            // Highlight first unit in subgroup
            for index = 1, numberSelectedEntities do
            
                local entId = selectedEntities[index]
                local status = CommanderUI_GetPortraitStatus(entId)
                if status[2] then
                    self.highlightedMultiItem = index
                    break
                end
                
            end
            
            self:UpdateSingleSelection(selectedEntities[self.highlightedMultiItem])
            self:UpdateMultiSelection(selectedEntities)
            
        end
    end
    
end

function GUISelectionPanel:UpdateSingleSelection(entityId)

    // Make all multiselection icons invisible.
    function SetItemInvisible(item) item:SetIsVisible(false) end
    table.foreachfunctor(self.multiSelectionIcons, SetItemInvisible)
    self.highlightItem:SetIsVisible(false)
    
    self.selectedIcon:SetIsVisible(true)
    self:SetIconTextureCoordinates(self.selectedIcon, entityId)
    if not self.selectedIcon:GetIsVisible() then
        return
    end
    
    local selectedDescription = CommanderUI_GetSelectedDescriptor(entityId)
    self.selectedName:SetIsVisible(true)
    self.selectedName:SetText(string.upper(selectedDescription))
    local selectedLocationText = CommanderUI_GetSelectedLocation(entityId)
    self.selectedLocationName:SetIsVisible(true)
    self.selectedLocationName:SetText(string.upper(selectedLocationText))
    
    local selectedBargraphs = CommanderUI_GetSelectedBargraphs(entityId)
    local healthText = CommanderUI_GetSelectedHealth(entityId)
    self.healthText:SetText(healthText)
    self.healthText:SetIsVisible(true)
    
    local armorText = CommanderUI_GetSelectedArmor(entityId)
    self.armorText:SetText(armorText)
    self.armorText:SetIsVisible(true)
    
    local healthPercentage = selectedBargraphs[2]
    self.statusText:SetIsVisible(false)
    self.statusBar:SetIsVisible(false)
    if table.count(selectedBargraphs) > 2 and selectedBargraphs[4] then
        local statusText = selectedBargraphs[3]
        self.statusText:SetIsVisible(true)
        local pulseColor = Color(GUISelectionPanel.kStatusFontColor)
        pulseColor.a = 0.5 + (((math.sin(Shared.GetTime() * 10) + 1) / 2) * 0.5)
        self.statusText:SetColor(pulseColor)
        self.statusText:SetText(string.upper(statusText))
        local statusPercentage = selectedBargraphs[4]
        self.statusBar:SetIsVisible(true)
        self.statusBar:SetSize(Vector(GUISelectionPanel.kStatusBarWidth * statusPercentage, GUISelectionPanel.kStatusBarHeight, 0))
    end
    
    self.energyText:SetIsVisible(true)
    self.energyText:SetText(CommanderUI_GetSelectedEnergy(entityId))
    
    local selectedSquadName = CommanderUI_GetSelectedSquad(entityId)
    self.selectedSquadName:SetIsVisible(false)
    if string.len(selectedSquadName) > 0 then
        self.selectedSquadName:SetIsVisible(true)
        self.selectedSquadName:SetText(selectedSquadName)
        local selectedSquadColor = CommanderUI_GetSelectedSquadColor(entityId)
        self.selectedSquadName:SetColor(ColorIntToColor(selectedSquadColor))
    end
    
    local singleSelectionCustomText = CommanderUI_GetSingleSelectionCustomText(entityId)
    if singleSelectionCustomText and string.len(singleSelectionCustomText) > 0 then
        self.customText:SetIsVisible(true)
        self.customText:SetText(singleSelectionCustomText)
    else
        self.customText:SetIsVisible(false)
    end

end

function GUISelectionPanel:UpdateMultiSelection(selectedEntityIds)

    function SetItemInvisible(item) item:SetIsVisible(false) end
    // Make all previous selection icons invisible.
    table.foreachfunctor(self.multiSelectionIcons, SetItemInvisible)
    
    self.highlightItem:SetIsVisible(false)
    
    local currentIconIndex = 1
    for i, selectedEntityId in ipairs(selectedEntityIds) do
        local selectedIcon = nil
        if table.count(self.multiSelectionIcons) >= currentIconIndex then
            selectedIcon = self.multiSelectionIcons[currentIconIndex]
        else
            selectedIcon = self:CreateMultiSelectionIcon()
        end
        selectedIcon:SetIsVisible(true)
        self:SetIconTextureCoordinates(selectedIcon, selectedEntityId)
        
        local xOffset = -(GUISelectionPanel.kMultiSelectedIconSize * currentIconIndex)
        selectedIcon:SetPosition(Vector(xOffset, -GUISelectionPanel.kMultiSelectedIconSize, 0))
        
        if currentIconIndex == self.highlightedMultiItem then
            if self.highlightItem:GetParent() then
                self.highlightItem:GetParent():RemoveChild(self.highlightItem)
            end
            selectedIcon:AddChild(self.highlightItem)
            self.highlightItem:SetIsVisible(true)
        end
        
        currentIconIndex = currentIconIndex + 1
    end

end

function GUISelectionPanel:CreateMultiSelectionIcon()

    local createdIcon = GUI.CreateItem()
    createdIcon:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    createdIcon:SetSize(Vector(GUISelectionPanel.kMultiSelectedIconSize, GUISelectionPanel.kMultiSelectedIconSize, 0))
    createdIcon:SetTexture("ui/" .. CommanderUI_MenuImage() .. ".dds")
    self.background:AddChild(createdIcon)
    table.insert(self.multiSelectionIcons, createdIcon)
    return createdIcon

end

function GUISelectionPanel:SendKeyEvent(key, down)

    if key == InputKey.LeftShift then
        if self.tabPressed ~= down then
            self.tabPressed = down
            if down then
                self.highlightedMultiItem = self.highlightedMultiItem + 1
                return true
            end
        end
    end
    
    return false

end

function GUISelectionPanel:SetIconTextureCoordinates(selectedIcon, entityId)

    local textureOffsets = CommanderUI_GetSelectedIconOffset(entityId)
    if textureOffsets and textureOffsets[1] and textureOffsets[2] then
        local pixelXOffset = textureOffsets[1] * GUISelectionPanel.kSelectedIconTextureWidth
        local pixelYOffset = textureOffsets[2] * GUISelectionPanel.kSelectedIconTextureHeight
        selectedIcon:SetTexturePixelCoordinates(pixelXOffset, pixelYOffset, pixelXOffset + GUISelectionPanel.kSelectedIconTextureWidth, pixelYOffset + GUISelectionPanel.kSelectedIconTextureHeight)
    else
        Shared.Message("Warning: Missing texture coordinates for selection panel icon")
        selectedIcon:SetIsVisible(false)
    end
    
end

function GUISelectionPanel:GetBackground()

    return self.background

end

function GUISelectionPanel:ContainsPoint(pointX, pointY)

    return GUIItemContainsPoint(self.background, pointX, pointY)

end
