
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

GUIWaypoints.kTextureCoords = { 199, 71, 255, 127 }

GUIWaypoints.kDefaultSize = 128

local kFontSize = 18

// Width of line on ground in meters.
local kLineWidth = 0.885
// How often to regenerate and animation the path.
local kRegeneratePathTime = 2
local kPathAnimationSpeed = 100
local kMinDistancePathIsVisible = 14 * 14

function GUIWaypoints:Initialize()

    self.finalWaypoint = GUIManager:CreateGraphicItem()
    self.finalWaypoint:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.finalWaypoint:SetTexture(GUIWaypoints.kTextureName)
    self.finalWaypoint:SetTexturePixelCoordinates(unpack(GUIWaypoints.kTextureCoords))
    self.finalWaypoint:SetColor(Color(1, 1, 1, 0.5))
    self.finalWaypoint:SetRotation(Vector(0, 0, math.pi))
    self.finalWaypoint:SetIsVisible(false)
    
    self.finalDistanceText = GUIManager:CreateTextItem()
    self.finalDistanceText:SetFontName(GUIWaypoints.kTextFontName)
    self.finalDistanceText:SetFontSize(kFontSize)
    self.finalDistanceText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.finalDistanceText:SetTextAlignmentX(GUIItem.Align_Center)
    self.finalDistanceText:SetTextAlignmentY(GUIItem.Align_Min)
    self.finalWaypoint:AddChild(self.finalDistanceText)
    
    self.finalNameText = GUIManager:CreateTextItem()
    self.finalNameText:SetFontName(GUIWaypoints.kTextFontName)
    self.finalNameText:SetFontSize(kFontSize)
    self.finalNameText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.finalNameText:SetTextAlignmentX(GUIItem.Align_Center)
    self.finalNameText:SetTextAlignmentY(GUIItem.Align_Min)
    self.finalNameText:SetPosition(Vector(0, kFontSize, 0))
    self.finalWaypoint:AddChild(self.finalNameText)
    
    self.dynamicMesh = Client.CreateRenderDynamicMesh()
    self.dynamicMesh:SetIsVisible(false)
    self.dynamicMesh:SetCoords(Coords.GetIdentity())
    self.dynamicMesh:SetMaterial("ui/WaypointPath.material")
    
end

function GUIWaypoints:Uninitialize()
    
    Client.DestroyRenderDynamicMesh(self.dynamicMesh)
    self.dynamicMesh = nil
    
    if self.finalWaypoint then
    
        GUI.DestroyItem(self.finalWaypoint)
        self.finalWaypoint = nil
        
    end
    
end

local function GeneratePathMesh(pathMesh, pathPoints)

    local indices = { }
    local indexArrayIndex = 1
    local currentIndex = 0
    local texCoords = { }
    local texIndex = 1
    local vertices = { }
    local vertIndex = 1
    local colors = { }
    local colorIndex = 1
    local previousPoint = nil
    local rightPrevPoint = nil
    local leftPrevPoint = nil
    local totalPathDistance = 0
    
    for i, point in ipairs(pathPoints) do
        
        local sideVector = Vector(0, 0, 0)
        if previousPoint then
        
            local pathPartVector = previousPoint - point
            sideVector = pathPartVector:CrossProduct(Vector(0, 1, 0)) * kLineWidth
            totalPathDistance = totalPathDistance + pathPartVector:GetLength()
            
        end
        local leftPoint = point - sideVector + Vector(0, -0.75, 0)
        local rightPoint = point + sideVector + Vector(0, -0.75, 0)
        
        if rightPrevPoint and leftPrevPoint then
            
            local rightPrevPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = rightPrevPoint.x
            vertices[vertIndex + 1] = rightPrevPoint.y
            vertices[vertIndex + 2] = rightPrevPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 1
            texCoords[texIndex + 1] = 1
            texIndex = texIndex + 2
            
            colors[colorIndex] = 1
            colors[colorIndex + 1] = 1
            colors[colorIndex + 2] = 1
            colors[colorIndex + 3] = 0
            colorIndex = colorIndex + 4
            
            local leftPrevPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = leftPrevPoint.x
            vertices[vertIndex + 1] = leftPrevPoint.y
            vertices[vertIndex + 2] = leftPrevPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 0
            texCoords[texIndex + 1] = 1
            texIndex = texIndex + 2
            
            colors[colorIndex] = 1
            colors[colorIndex + 1] = 1
            colors[colorIndex + 2] = 1
            colors[colorIndex + 3] = 0
            colorIndex = colorIndex + 4
            
            local leftPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = leftPoint.x
            vertices[vertIndex + 1] = leftPoint.y
            vertices[vertIndex + 2] = leftPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 0
            texCoords[texIndex + 1] = 0
            texIndex = texIndex + 2
            
            colors[colorIndex] = 1
            colors[colorIndex + 1] = 1
            colors[colorIndex + 2] = 1
            colors[colorIndex + 3] = 0
            colorIndex = colorIndex + 4
            
            local rightPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = rightPoint.x
            vertices[vertIndex + 1] = rightPoint.y
            vertices[vertIndex + 2] = rightPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 1
            texCoords[texIndex + 1] = 0
            texIndex = texIndex + 2
            
            colors[colorIndex] = 1
            colors[colorIndex + 1] = 1
            colors[colorIndex + 2] = 1
            colors[colorIndex + 3] = 0
            colorIndex = colorIndex + 4
            
            indices[indexArrayIndex] = rightPointIndex
            indices[indexArrayIndex + 1] = rightPrevPointIndex
            indices[indexArrayIndex + 2] = leftPrevPointIndex
            
            indices[indexArrayIndex + 3] = leftPrevPointIndex
            indices[indexArrayIndex + 4] = leftPointIndex
            indices[indexArrayIndex + 5] = rightPointIndex
            indexArrayIndex = indexArrayIndex + 6
            
        end
        
        previousPoint = point
        rightPrevPoint = rightPoint
        leftPrevPoint = leftPoint
        
    end
    
    pathMesh:SetIndices(indices, #indices)
    pathMesh:SetTexCoords(texCoords, #texCoords)
    pathMesh:SetVertices(vertices, #vertices)
    pathMesh:SetColors(colors, #colors)
    
    return indices, texCoords, vertices, colors, totalPathDistance

end

function GUIWaypoints:_RegeneratePath()

    local currentTime = Shared.GetTime()
    
    if self.timeLastGeneratedPathMesh == nil or currentTime - self.timeLastGeneratedPathMesh > kRegeneratePathTime then
    
        self.pathPoints = PlayerUI_GetOrderPath()
        
        local visible = self.pathPoints ~= nil and #self.pathPoints > 1
        self.dynamicMesh:SetIsVisible(visible)
        
        if visible then
            self.indices, self.texCoords, self.vertices, self.colors, self.totalPathDistance = GeneratePathMesh(self.dynamicMesh, self.pathPoints)
        end
        
        self.timeLastGeneratedPathMesh = currentTime
        
    end
    
    // Check if it should be hidden if the player is too close.
    if self.dynamicMesh:GetIsVisible() then
    
        local orderInfo = PlayerUI_GetOrderInfo()
        if orderInfo and orderInfo[3] then
        
            local orderLocation = orderInfo[3]
            local playerToOrderDistance = (orderLocation - PlayerUI_GetOrigin()):GetLengthSquared()
            self.dynamicMesh:SetIsVisible(playerToOrderDistance > kMinDistancePathIsVisible)
            
        end
        
    end
    
end

function GUIWaypoints:_AnimatePath()

    if self.dynamicMesh:GetIsVisible() then
        
        local currentTime = Shared.GetTime()
        local pathDistanceTakenSoFar = 0
        local lastPoint = nil
        local percentAlongPath = ((currentTime - self.timeLastGeneratedPathMesh) * kPathAnimationSpeed) / self.totalPathDistance - 0.5
        for p = 1, #self.pathPoints do
        
            local pathPoint = self.pathPoints[p]
            local pointPercentOnPath = 0
            if lastPoint then
            
                local distanceBetweenPoints = (pathPoint - lastPoint):GetLength()
                pathDistanceTakenSoFar = pathDistanceTakenSoFar + distanceBetweenPoints
                pointPercentOnPath = pathDistanceTakenSoFar / self.totalPathDistance
                
            end
            lastPoint = pathPoint
            
            // Intensity moves along the path over time. The color intensity of these vertices will be
            // based on how far the vertex is from the moving point on the path.
            local intensity = 1 - math.abs(percentAlongPath - pointPercentOnPath) * 2
            
            // * 2 for 2 vertices per point, * 4 for 4 colors per vertex, + 4 for indexing into the alpha component (rgbA).
            local vertex1Alpha = (p - 1) * 2 * 4 + 4
            self.colors[vertex1Alpha] = intensity
            
            local vertex2Alpha = (p - 1) * 2 * 4 + 8
            self.colors[vertex2Alpha] = intensity
        
        end
        
        self.dynamicMesh:SetColors(self.colors, #self.colors)
    
    end

end

function GUIWaypoints:_AnimateFinalWaypoint()

    local finalWaypointData = PlayerUI_GetFinalWaypointInScreenspace()
    self.finalWaypoint:SetIsVisible(finalWaypointData ~= nil)
    
    if finalWaypointData then
    
        local x = finalWaypointData[1]
        local y = finalWaypointData[2]
        local scale = finalWaypointData[3] * GUIWaypoints.kDefaultSize
        local name = finalWaypointData[4]
        local distance = finalWaypointData[5]
        self.finalWaypoint:SetPosition(Vector(x - scale / 2, y - scale / 2, 0))
        self.finalWaypoint:SetSize(Vector(scale, scale, 1))
        self.finalDistanceText:SetText(tostring(math.floor(distance)))
        self.finalNameText:SetText(name)
        
    end

end

function GUIWaypoints:Update(deltaTime)

    PROFILE("GUIWaypoints:Update")
    
    self:_RegeneratePath()
    
    self:_AnimatePath()
    
    self:_AnimateFinalWaypoint()
    
end