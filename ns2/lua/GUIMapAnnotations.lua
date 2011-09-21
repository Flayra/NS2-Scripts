// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMapAnnotations.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages text that is drawn in the world to annotate maps.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/dkjson.lua")

class 'GUIMapAnnotations' (GUIScript)

GUIMapAnnotations.kMaxDisplayDistance = 30

GUIMapAnnotations.kNumberOfDataFields = 6

GUIMapAnnotations.kAfterPostGetAnnotationsTime = 0.5

function GUIMapAnnotations:Initialize()

    self.visible = false
    self.annotations = { }
    self.getLatestAnnotationsTime = 0

end

function GUIMapAnnotations:Uninitialize()

    self:ClearAnnotations()
    
end

function GUIMapAnnotations:ClearAnnotations()

    for i, annotation in ipairs(self.annotations) do
        GUI.DestroyItem(annotation.Item)
    end
    self.annotations = { }

end

function GUIMapAnnotations:SetIsVisible(setVisible)

    self.visible = setVisible
    
end

function GUIMapAnnotations:AddAnnotation(text, worldOrigin)
    
    local annotationItem = { Item = GUIManager:CreateTextItem(), Origin = Vector(worldOrigin) }
    annotationItem.Item:SetLayer(kGUILayerDebugText)
    annotationItem.Item:SetFontSize(20)
    annotationItem.Item:SetAnchor(GUIItem.Left, GUIItem.Top)
    annotationItem.Item:SetTextAlignmentX(GUIItem.Align_Center)
    annotationItem.Item:SetTextAlignmentY(GUIItem.Align_Center)
    annotationItem.Item:SetColor(Color(1, 1, 1, 1))
    annotationItem.Item:SetText(text)
    annotationItem.Item:SetIsVisible(false)
    table.insert(self.annotations, annotationItem)
    
end

function GUIMapAnnotations:Update(deltaTime)

    PROFILE("GUIMapAnnotations:Update")

    for i, annotation in ipairs(self.annotations) do
        if not self.visible then
            annotation.Item:SetIsVisible(false)
        else
            // Set position according to position/orientation of local player.
            local screenPos = Client.WorldToScreen(Vector(annotation.Origin.x, annotation.Origin.y, annotation.Origin.z))
            
            local playerOrigin = PlayerUI_GetEyePos()
            local direction = annotation.Origin - playerOrigin
            local normToAnnotationVec = GetNormalizedVector(direction)
            local normViewVec = PlayerUI_GetForwardNormal()
            local dotProduct = normToAnnotationVec:DotProduct(normViewVec)
            
            local visible = true
            
            if (screenPos.x < 0 or screenPos.x > Client.GetScreenWidth() or
                screenPos.y < 0 or screenPos.y > Client.GetScreenHeight()) or
                dotProduct < 0 then
                visible = false
            else
                annotation.Item:SetPosition(screenPos)
            end
            
            // Fade based on distance.
            
            local fadeAmount = (direction:GetLengthSquared()) / (GUIMapAnnotations.kMaxDisplayDistance * GUIMapAnnotations.kMaxDisplayDistance)
            if fadeAmount < 1 then
                annotation.Item:SetColor(Color(1, 1, 1, 1 - fadeAmount))
            else
                visible = false
            end
            
            annotation.Item:SetIsVisible(visible)
        end
    end
    
    if self.getLatestAnnotationsTime > 0 and Shared.GetTime() >= self.getLatestAnnotationsTime then
        self:GetLatestAnnotations()
        self.getLatestAnnotationsTime = 0
    end
    
end

function GUIMapAnnotations:GetLatestAnnotations()

    self:ClearAnnotations()
    local urlString = "http://unknownworldsstats.appspot.com/statlocationdata?version=" .. ToString(Shared.GetBuildNumber()) .. "&map=" .. Shared.GetMapName() .. "&output=json"
    Shared.GetWebpage(urlString, ParseAnnotations)
    
end

function GUIMapAnnotations:GetLatestAnnotationsLater(laterTime)

    ASSERT(laterTime >=0)
    
    self.getLatestAnnotationsTime = Shared.GetTime() + laterTime

end

function OnCommandAnnotate(...)

    local info = nil
    local args = {...}
    local currentArg = 1
    for i, v in ipairs(args) do
        if currentArg == 1 then
            info = v
        else
            info = info .. " " .. v
        end
        currentArg = currentArg + 1
    end
    
    if info == nil then
        Print("Please provide in some text to annotate")
        return
    end
    
    local origin = PlayerUI_GetEyePos()

    // Remove undesirable characters.
    info = info:gsub(",", "")
    info = info:gsub("?", "")
    local urlString = "http://unknownworldsstats.appspot.com/statlocation?version=" .. ToString(Shared.GetBuildNumber()) .. "&name=user&info=" .. info ..
                      "&value=0&map=" .. Shared.GetMapName() .. "&mapx=" .. string.format("%.2f", origin.x) .. "&mapy=" .. string.format("%.2f", origin.y)..
                      "&mapz=" .. string.format("%.2f", origin.z)
    Shared.GetWebpage(urlString, function (data) end)
    
    // Automatically update the annotations in a little bit so the user sees this new one.
    GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):GetLatestAnnotationsLater(GUIMapAnnotations.kAfterPostGetAnnotationsTime)

end

function OnCommandDisplayAnnotations(display)

    if display == "true" then
        GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):GetLatestAnnotations()
        GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):SetIsVisible(true)
    else
        GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):SetIsVisible(false)
    end

end

function ParseAnnotations(data)

    local obj, pos, err = json.decode(data, 1, nil)
    if err then
        Shared.Message("Error in parsing annotations: " .. ToString(err))
    else
        for k, v in pairs(obj) do
            GetGUIManager():GetGUIScriptSingle("GUIMapAnnotations"):AddAnnotation(v.info, Vector(v.mapx, v.mapy, v.mapz))
        end
    end

end

Event.Hook("Console_annotate",              OnCommandAnnotate)
Event.Hook("Console_displayannotations",    OnCommandDisplayAnnotations)
