// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderButtonsAliens.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages alien specific layout and updating for commander buttons.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUICommanderButtons.lua")

class 'GUICommanderButtonsAliens' (GUICommanderButtons)

GUICommanderButtonsAliens.kBackgroundTexture = "ui/alien_commander_background.dds"

GUICommanderButtonsAliens.kNumberAlienButtonRows = 3
GUICommanderButtonsAliens.kNumberAlienButtonColumns = 4
GUICommanderButtonsAliens.kNumberAlienButtons = GUICommanderButtonsAliens.kNumberAlienButtonRows * GUICommanderButtonsAliens.kNumberAlienButtonColumns

function GUICommanderButtonsAliens:GetBackgroundTextureName()

    return GUICommanderButtonsAliens.kBackgroundTexture

end

function GUICommanderButtonsAliens:InitializeButtons()

    self:InitializeHighlighter()
    
    local settingsTable = { }
    settingsTable.NumberOfTabs = 0
    settingsTable.TabXOffset = 0
    settingsTable.TabYOffset = 0
    settingsTable.TabWidth = 0
    settingsTable.TabSpacing = 0
    settingsTable.TabTopHeight = 0
    settingsTable.TabBottomHeight = 0
    settingsTable.TabBottomOffset = 0
    settingsTable.TabConnectorWidth = 0
    settingsTable.TabConnectorHeight = 0
    settingsTable.NumberOfColumns = GUICommanderButtonsAliens.kNumberAlienButtonColumns
    settingsTable.NumberOfButtons = GUICommanderButtonsAliens.kNumberAlienButtons
    settingsTable.ButtonYOffset = 0
    self:SharedInitializeButtons(settingsTable)
    
end