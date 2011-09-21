// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIHealthCircle.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays the health for structures.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIDial.lua")

healthCircle = nil

// Global state that can be externally set to adjust the circle.
healthPercentage = 0
buildPercentage = 0

kHealthCircleWidth = 256
kHealthCircleHeight = 256

kHealthCircleTextureWidth = 512
kHealthCircleTextureHeight = 256

kHealthTextureName = "ui/health_circle.dds"

kBuildColor = Color(1, 0, 1)
// Colors to interpolate between starting from no health to full health.
kHealthColors = { Color(0.8, 0, 0), Color(0.5, 0, 0.5), Color(0, 0, 0.7) }
kNumberHealthColors = table.maxn(kHealthColors)

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    healthCircle:Update(deltaTime)
    
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( kHealthCircleWidth, kHealthCircleHeight )

    healthCircle = GUIHealthCircle()
    healthCircle:Initialize()

end

class 'GUIHealthCircle'

function GUIHealthCircle:Initialize()
    
    local healthCircleSettings = { }
    healthCircleSettings.BackgroundWidth = kHealthCircleWidth
    healthCircleSettings.BackgroundHeight = kHealthCircleHeight
    healthCircleSettings.BackgroundAnchorX = GUIItem.Left
    healthCircleSettings.BackgroundAnchorY = GUIItem.Bottom
    healthCircleSettings.BackgroundOffset = Vector(0, 0, 0)
    healthCircleSettings.BackgroundTextureName = kHealthTextureName
    healthCircleSettings.BackgroundTextureX1 = 0
    healthCircleSettings.BackgroundTextureY1 = 0
    healthCircleSettings.BackgroundTextureX2 = kHealthCircleTextureWidth / 2
    healthCircleSettings.BackgroundTextureY2 = kHealthCircleTextureHeight
    healthCircleSettings.ForegroundTextureName = kHealthTextureName
    healthCircleSettings.ForegroundTextureWidth = kHealthCircleWidth
    healthCircleSettings.ForegroundTextureHeight = kHealthCircleHeight
    healthCircleSettings.ForegroundTextureX1 = kHealthCircleTextureWidth / 2
    healthCircleSettings.ForegroundTextureY1 = 0
    healthCircleSettings.ForegroundTextureX2 = kHealthCircleTextureWidth
    healthCircleSettings.ForegroundTextureY2 = kHealthCircleTextureHeight
    healthCircleSettings.InheritParentAlpha = true
    self.healthCircle = GUIDial()
    self.healthCircle:Initialize(healthCircleSettings)
    
end

function GUIHealthCircle:Uninitialize()

    if self.healthCircle then
        self.healthCircle:Uninitialize()
        self.healthCircle = nil
    end
    
end

function GUIHealthCircle:Update(deltaTime)

    PROFILE("GUIHealthCircle:Update")

    healthPercentage = math.min(math.max(healthPercentage, 0), 100)
    buildPercentage = math.min(math.max(buildPercentage, 0), 100)
    
    local useColor = kBuildColor
    local usePercentage = buildPercentage / 100
    if buildPercentage == 100 then
        usePercentage = healthPercentage / 100
        local colorIndex = math.max(math.ceil(kNumberHealthColors * usePercentage), 1)
        // Still need to lerp between the colors
        //ColorLerp(c1, c2, dt)
        useColor = kHealthColors[colorIndex]
    end
    
    self.healthCircle:SetPercentage(usePercentage)
    self.healthCircle:Update(deltaTime)
    self.healthCircle:GetLeftSide():SetColor(useColor)
    self.healthCircle:GetRightSide():SetColor(useColor)
    
end

Initialize()