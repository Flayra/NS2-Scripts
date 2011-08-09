// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDebugText.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the crosshairs for aliens and marines.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIDebugText' (GUIScript)

GUIDebugText.kLifetime = 3
GUIDebugText.kWorldVerticalRiseAmount = 1

function GUIDebugText:Initialize()

    self.debugText = GUIManager:CreateTextItem()
    self.debugText:SetLayer(kGUILayerDebugText)
    self.debugText:SetFontSize(20)
    self.debugText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.debugText:SetTextAlignmentX(GUIItem.Align_Center)
    self.debugText:SetTextAlignmentY(GUIItem.Align_Center)
    self.debugText:SetColor(Color(1, 1, 1, 1))
    self.debugText:SetText("(call GUIDebugText:SetDebugInfo)")
    
end

function GUIDebugText:Uninitialize()

    GUI.DestroyItem(self.debugText)
    self.debugText = nil
    
end

function GUIDebugText:SetDebugInfo(debugString, worldOrigin, messageOffset)

    if debugString then
        self.debugText:SetText(debugString)
    end
    
    self.worldPosition = Vector()
    VectorCopy(worldOrigin, self.worldPosition)
    
    self.messageOffset = ConditionalValue(messageOffset, messageOffset, 0)
    
    self.createTime = Shared.GetTime()
    
end

function GUIDebugText:Update(deltaTime)

    // Set position according to position/orientation of local player
    local lifetimeScalar = ((Shared.GetTime() - self.createTime)/GUIDebugText.kLifetime)
    local riseAmount = math.sin(lifetimeScalar * math.pi / 2) * GUIDebugText.kWorldVerticalRiseAmount
    local screenPos = Client.WorldToScreen(Vector(self.worldPosition.x, self.worldPosition.y + riseAmount, self.worldPosition.z))
    
    // Offset message in pixels so they don't overlap
    screenPos.y = screenPos.y - self.messageOffset * self.debugText:GetTextHeight(" ")
    
    self.debugText:SetPosition(screenPos)
    
    local visible = true
    
    if  (screenPos.x < 0 or screenPos.x > Client.GetScreenWidth() or
        screenPos.y < 0 or screenPos.y > Client.GetScreenHeight()) then
        visible = false
    end
    
    self.debugText:SetIsVisible(visible)
    
end

function GUIDebugText:GetExpired()
    return self.createTime and (Shared.GetTime() > (self.createTime + GUIDebugText.kLifetime))
end
