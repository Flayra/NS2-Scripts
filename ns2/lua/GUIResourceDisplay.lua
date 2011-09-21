
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIResourceDisplay.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying resources and number of resource towers.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIResourceDisplay' (GUIScript)

GUIResourceDisplay.kBackgroundTextureAlien = "ui/alien_commander_background.dds"
GUIResourceDisplay.kBackgroundTextureMarine = "ui/marine_commander_background.dds"
GUIResourceDisplay.kBackgroundTextureCoords = { X1 = 755, Y1 = 342, X2 = 990, Y2 = 405 }
GUIResourceDisplay.kBackgroundWidth = GUIResourceDisplay.kBackgroundTextureCoords.X2 - GUIResourceDisplay.kBackgroundTextureCoords.X1
GUIResourceDisplay.kBackgroundHeight = GUIResourceDisplay.kBackgroundTextureCoords.Y2 - GUIResourceDisplay.kBackgroundTextureCoords.Y1
GUIResourceDisplay.kBackgroundYOffset = 10

GUIResourceDisplay.kPersonalResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 774, Y1 = 417, X2 = 804, Y2 = 446 } }
GUIResourceDisplay.kPersonalResourceIcon.Width = GUIResourceDisplay.kPersonalResourceIcon.Coords.X2 - GUIResourceDisplay.kPersonalResourceIcon.Coords.X1
GUIResourceDisplay.kPersonalResourceIcon.Height = GUIResourceDisplay.kPersonalResourceIcon.Coords.Y2 - GUIResourceDisplay.kPersonalResourceIcon.Coords.Y1

GUIResourceDisplay.kTeamResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 844, Y1 = 412, X2 = 882, Y2 = 450 } }
GUIResourceDisplay.kTeamResourceIcon.Width = GUIResourceDisplay.kTeamResourceIcon.Coords.X2 - GUIResourceDisplay.kTeamResourceIcon.Coords.X1
GUIResourceDisplay.kTeamResourceIcon.Height = GUIResourceDisplay.kTeamResourceIcon.Coords.Y2 - GUIResourceDisplay.kTeamResourceIcon.Coords.Y1
GUIResourceDisplay.kTeamResourceIcon.X = -5
GUIResourceDisplay.kTeamResourceIcon.Y = -4

GUIResourceDisplay.kResourceTowerIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 918, Y1 = 418, X2 = 945, Y2 = 444 } }
GUIResourceDisplay.kResourceTowerIcon.Width = GUIResourceDisplay.kResourceTowerIcon.Coords.X2 - GUIResourceDisplay.kResourceTowerIcon.Coords.X1
GUIResourceDisplay.kResourceTowerIcon.Height = GUIResourceDisplay.kResourceTowerIcon.Coords.Y2 - GUIResourceDisplay.kResourceTowerIcon.Coords.Y1
GUIResourceDisplay.kResourceTowerIcon.X = -GUIResourceDisplay.kResourceTowerIcon.Width / 2

GUIResourceDisplay.kFontSize = 16
GUIResourceDisplay.kIconTextXOffset = 5
GUIResourceDisplay.kIconXOffset = 30

function GUIResourceDisplay:Initialize(settingsTable)

    self.textureName = ConditionalValue(CommanderUI_IsAlienCommander(), GUIResourceDisplay.kBackgroundTextureAlien, GUIResourceDisplay.kBackgroundTextureMarine)
    
    // Background.
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIResourceDisplay.kBackgroundWidth, GUIResourceDisplay.kBackgroundHeight, 0))
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.background:SetPosition(Vector(-GUIResourceDisplay.kBackgroundWidth / 2, GUIResourceDisplay.kBackgroundYOffset, 0))
    self.background:SetTexture(self.textureName)
    self.background:SetColor(Color(1, 1, 1, 0.75))
    GUISetTextureCoordinatesTable(self.background, GUIResourceDisplay.kBackgroundTextureCoords)
    
    // Personal display.
    self.personalIcon = GUIManager:CreateGraphicItem()
    self.personalIcon:SetSize(Vector(GUIResourceDisplay.kPersonalResourceIcon.Width, GUIResourceDisplay.kPersonalResourceIcon.Height, 0))
    self.personalIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    local personalIconX = GUIResourceDisplay.kPersonalResourceIcon.X + GUIResourceDisplay.kIconXOffset
    local personalIconY = GUIResourceDisplay.kPersonalResourceIcon.Y + -GUIResourceDisplay.kPersonalResourceIcon.Height / 2
    self.personalIcon:SetPosition(Vector(personalIconX, personalIconY, 0))
    self.personalIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.personalIcon, GUIResourceDisplay.kPersonalResourceIcon.Coords)
    self.background:AddChild(self.personalIcon)

    self.personalText = GUIManager:CreateTextItem()
    self.personalText:SetFontSize(GUIResourceDisplay.kFontSize)
    self.personalText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.personalText:SetTextAlignmentX(GUIItem.Align_Min)
    self.personalText:SetTextAlignmentY(GUIItem.Align_Center)
    self.personalText:SetPosition(Vector(GUIResourceDisplay.kIconTextXOffset, 0, 0))
    self.personalText:SetColor(Color(1, 1, 1, 1))
    self.personalText:SetFontIsBold(true)
    self.personalIcon:AddChild(self.personalText)
    
    // Team display.
    self.teamIcon = GUIManager:CreateGraphicItem()
    self.teamIcon:SetSize(Vector(GUIResourceDisplay.kTeamResourceIcon.Width, GUIResourceDisplay.kTeamResourceIcon.Height, 0))
    self.teamIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    local teamIconX = GUIResourceDisplay.kTeamResourceIcon.X + -GUIResourceDisplay.kTeamResourceIcon.Width / 2
    local teamIconY = GUIResourceDisplay.kTeamResourceIcon.Y + -GUIResourceDisplay.kPersonalResourceIcon.Height / 2
    self.teamIcon:SetPosition(Vector(teamIconX, teamIconY, 0))
    self.teamIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.teamIcon, GUIResourceDisplay.kTeamResourceIcon.Coords)
    self.background:AddChild(self.teamIcon)

    self.teamText = GUIManager:CreateTextItem()
    self.teamText:SetFontSize(GUIResourceDisplay.kFontSize)
    self.teamText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.teamText:SetTextAlignmentX(GUIItem.Align_Min)
    self.teamText:SetTextAlignmentY(GUIItem.Align_Center)
    self.teamText:SetPosition(Vector(GUIResourceDisplay.kIconTextXOffset, 0, 0))
    self.teamText:SetColor(Color(1, 1, 1, 1))
    self.teamText:SetFontIsBold(true)
    self.teamIcon:AddChild(self.teamText)
    
    // Tower display.
    self.towerIcon = GUIManager:CreateGraphicItem()
    self.towerIcon:SetSize(Vector(GUIResourceDisplay.kResourceTowerIcon.Width, GUIResourceDisplay.kResourceTowerIcon.Height, 0))
    self.towerIcon:SetAnchor(GUIItem.Right, GUIItem.Center)
    local towerIconX = GUIResourceDisplay.kResourceTowerIcon.X + -GUIResourceDisplay.kResourceTowerIcon.Width - GUIResourceDisplay.kIconXOffset
    local towerIconY = GUIResourceDisplay.kResourceTowerIcon.Y + -GUIResourceDisplay.kResourceTowerIcon.Height / 2
    self.towerIcon:SetPosition(Vector(towerIconX, towerIconY, 0))
    self.towerIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.towerIcon, GUIResourceDisplay.kResourceTowerIcon.Coords)
    self.background:AddChild(self.towerIcon)

    self.towerText = GUIManager:CreateTextItem()
    self.towerText:SetFontSize(GUIResourceDisplay.kFontSize)
    self.towerText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.towerText:SetTextAlignmentX(GUIItem.Align_Min)
    self.towerText:SetTextAlignmentY(GUIItem.Align_Center)
    self.towerText:SetPosition(Vector(GUIResourceDisplay.kIconTextXOffset, 0, 0))
    self.towerText:SetColor(Color(1, 1, 1, 1))
    self.towerText:SetFontIsBold(true)
    self.towerIcon:AddChild(self.towerText)
    
end

function GUIResourceDisplay:Uninitialize()
    
    GUI.DestroyItem(self.background)
    self.background = nil
    
end

function GUIResourceDisplay:Update(deltaTime)

    PROFILE("GUIResourceDisplay:Update")
    
    self.personalText:SetText(ToString(PlayerUI_GetPlayerResources()))
    
    self.teamText:SetText(ToString(PlayerUI_GetTeamResources()))
    
    self.towerText:SetText(ToString(CommanderUI_GetTeamHarvesterCount()))
    
end
