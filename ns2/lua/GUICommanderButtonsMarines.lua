// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderButtonsMarines.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages marine specific layout and updating for commander buttons.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUICommanderButtons.lua")

class 'GUICommanderButtonsMarines' (GUICommanderButtons)

GUICommanderButtonsMarines.kBackgroundTexture = "ui/marine_commander_background.dds"

GUICommanderButtonsMarines.kNumberMarineButtonRows = 2
GUICommanderButtonsMarines.kNumberMarineButtonColumns = 4
// One row of special buttons on top.
GUICommanderButtonsMarines.kNumberMarineTopTabs = GUICommanderButtonsMarines.kNumberMarineButtonColumns
// With the normal buttons below.
GUICommanderButtonsMarines.kNumberMarineButtons = GUICommanderButtonsMarines.kNumberMarineButtonRows * GUICommanderButtonsMarines.kNumberMarineButtonColumns

GUICommanderButtonsMarines.kButtonYOffset = 20 * kCommanderGUIsGlobalScale

GUICommanderButtonsMarines.kMarineTabXOffset = 37 * kCommanderGUIsGlobalScale
GUICommanderButtonsMarines.kMarineTabYOffset = 30 * kCommanderGUIsGlobalScale

GUICommanderButtonsMarines.kMarineTabWidth = 99 * kCommanderGUIsGlobalScale
// Determines how much space is between each tab.
GUICommanderButtonsMarines.kMarineTabSpacing = 4 * kCommanderGUIsGlobalScale
GUICommanderButtonsMarines.kMarineTabTopHeight = 40 * kCommanderGUIsGlobalScale
GUICommanderButtonsMarines.kMarineTabBottomHeight = 8 * kCommanderGUIsGlobalScale
GUICommanderButtonsMarines.kMarineTabBottomOffset = 0 * kCommanderGUIsGlobalScale
GUICommanderButtonsMarines.kMarineTabConnectorWidth = 109 * kCommanderGUIsGlobalScale
GUICommanderButtonsMarines.kMarineTabConnectorHeight = 15 * kCommanderGUIsGlobalScale

function GUICommanderButtonsMarines:GetBackgroundTextureName()

    return GUICommanderButtonsMarines.kBackgroundTexture

end

function GUICommanderButtonsMarines:InitializeButtons()

    self:InitializeHighlighter()
    
    local settingsTable = { }
    settingsTable.NumberOfTabs = GUICommanderButtonsMarines.kNumberMarineTopTabs
    settingsTable.TabXOffset = GUICommanderButtonsMarines.kMarineTabXOffset
    settingsTable.TabYOffset = GUICommanderButtonsMarines.kMarineTabYOffset
    settingsTable.TabWidth = GUICommanderButtonsMarines.kMarineTabWidth
    settingsTable.TabSpacing = GUICommanderButtonsMarines.kMarineTabSpacing
    settingsTable.TabTopHeight = GUICommanderButtonsMarines.kMarineTabTopHeight
    settingsTable.TabBottomHeight = GUICommanderButtonsMarines.kMarineTabBottomHeight
    settingsTable.TabBottomOffset = GUICommanderButtonsMarines.kMarineTabBottomOffset
    settingsTable.TabConnectorWidth = GUICommanderButtonsMarines.kMarineTabConnectorWidth
    settingsTable.TabConnectorHeight = GUICommanderButtonsMarines.kMarineTabConnectorHeight
    settingsTable.NumberOfColumns = GUICommanderButtonsMarines.kNumberMarineButtonColumns
    settingsTable.NumberOfButtons = GUICommanderButtonsMarines.kNumberMarineButtons
    settingsTable.ButtonYOffset = GUICommanderButtonsMarines.kButtonYOffset
    self:SharedInitializeButtons(settingsTable)

end