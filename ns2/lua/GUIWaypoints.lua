
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIWaypoints.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages waypoints displayed on the HUD to show the player where to go.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIWaypoints' (GUIScript)

GUIWaypoints.kTextureName = "ui/marine_health_bg.dds"
GUIWaypoints.kTextFontName = "MicrogrammaDMedExt"

GUIWaypoints.kDistanceFontSize = 20

GUIWaypoints.kTextureCoordX1 = 199
GUIWaypoints.kTextureCoordY1 = 71
GUIWaypoints.kTextureCoordX2 = 255
GUIWaypoints.kTextureCoordY2 = 127

GUIWaypoints.kDefaultSize = 128

function GUIWaypoints:Initialize()

    self.finalWaypoint = GUIManager:CreateGraphicItem()
    self.finalWaypoint:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.finalWaypoint:SetTexture(GUIWaypoints.kTextureName)
    self.finalWaypoint:SetTexturePixelCoordinates(GUIWaypoints.kTextureCoordX1, GUIWaypoints.kTextureCoordY1, GUIWaypoints.kTextureCoordX2, GUIWaypoints.kTextureCoordY2)
    self.finalWaypoint:SetColor(Color(1, 1, 1, 0.5))
    self.finalWaypoint:SetIsVisible(false)
    
    self.finalDistanceText = GUIManager:CreateTextItem()
    self.finalDistanceText:SetFontName(GUIWaypoints.kTextFontName)
    self.finalDistanceText:SetFontSize(GUIWaypoints.kDistanceFontSize)
    self.finalDistanceText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.finalDistanceText:SetTextAlignmentX(GUIItem.Align_Center)
    self.finalDistanceText:SetTextAlignmentY(GUIItem.Align_Min)
    self.finalWaypoint:AddChild(self.finalDistanceText)
    
    self.finalNameText = GUIManager:CreateTextItem()
    self.finalNameText:SetFontName(GUIWaypoints.kTextFontName)
    self.finalNameText:SetFontSize(GUIWaypoints.kDistanceFontSize)
    self.finalNameText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.finalNameText:SetTextAlignmentX(GUIItem.Align_Center)
    self.finalNameText:SetTextAlignmentY(GUIItem.Align_Min)
    self.finalNameText:SetPosition(Vector(0, GUIWaypoints.kDistanceFontSize, 0))
    self.finalWaypoint:AddChild(self.finalNameText)
    
    self.nextWaypoint = GUIManager:CreateGraphicItem()
    self.nextWaypoint:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.nextWaypoint:SetTexture(GUIWaypoints.kTextureName)
    self.nextWaypoint:SetTexturePixelCoordinates(GUIWaypoints.kTextureCoordX1, GUIWaypoints.kTextureCoordY1, GUIWaypoints.kTextureCoordX2, GUIWaypoints.kTextureCoordY2)
    self.nextWaypoint:SetColor(Color(1, 1, 1, 0.5))
    self.nextWaypoint:SetIsVisible(false)
    
    self.nextDistanceText = GUIManager:CreateTextItem()
    self.nextDistanceText:SetFontName(GUIWaypoints.kTextFontName)
    self.nextDistanceText:SetFontSize(GUIWaypoints.kDistanceFontSize)
    self.nextDistanceText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.nextDistanceText:SetTextAlignmentX(GUIItem.Align_Center)
    self.nextDistanceText:SetTextAlignmentY(GUIItem.Align_Min)
    self.nextWaypoint:AddChild(self.nextDistanceText)
    
end

function GUIWaypoints:Uninitialize()
    
    if self.nextWaypoint then
        GUI.DestroyItem(self.nextWaypoint)
        self.nextWaypoint = nil
    end
    
    if self.finalWaypoint then
        GUI.DestroyItem(self.finalWaypoint)
        self.finalWaypoint = nil
    end
    
end

function GUIWaypoints:Update(deltaTime)

    PROFILE("GUIWaypoints:Update")
    
    local nextWaypointActive = PlayerUI_GetNextWaypointActive()
    
    self.nextWaypoint:SetIsVisible(nextWaypointActive)
    self.finalWaypoint:SetIsVisible(nextWaypointActive)
    
    if nextWaypointActive then
        local nextWaypointData = PlayerUI_GetNextWaypointInScreenspace()
        local x = nextWaypointData[1]
        local y = nextWaypointData[2]
        local rotation = nextWaypointData[3]
        local scale = nextWaypointData[4] * GUIWaypoints.kDefaultSize
        local distance = nextWaypointData[5]
        if distance < 0 then
            self.nextWaypoint:SetIsVisible(false)
        else
            self.nextWaypoint:SetPosition(Vector(x - scale / 2, y - scale / 2, 0))
            self.nextWaypoint:SetRotation(Vector(0, 0, rotation))
            self.nextWaypoint:SetSize(Vector(scale, scale, 1))
            self.nextDistanceText:SetText(tostring(math.floor(distance)))
        end
        
        local finalWaypointData = PlayerUI_GetFinalWaypointInScreenspace()
        local visible = finalWaypointData[1]
        self.finalWaypoint:SetIsVisible(visible)
        if visible then
            x = finalWaypointData[2]
            y = finalWaypointData[3]
            scale = finalWaypointData[4] * GUIWaypoints.kDefaultSize
            local name = finalWaypointData[5]
            distance = finalWaypointData[6]
            self.finalWaypoint:SetPosition(Vector(x - scale / 2, y - scale / 2, 0))
            self.finalWaypoint:SetSize(Vector(scale, scale, 1))
            self.finalDistanceText:SetText(tostring(math.floor(distance)))
            self.finalNameText:SetText(name)
        end
    end
    
end
