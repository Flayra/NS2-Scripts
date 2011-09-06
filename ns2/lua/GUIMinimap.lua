// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMinimap.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the minimap and icons on the minimap.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScanlines.lua")
Script.Load("lua/FunctionContracts.lua")

class 'GUIMinimap' (GUIScript)

GUIMinimap.kModeMini = 0
GUIMinimap.kModeBig = 1

GUIMinimap.kMapBackgroundXOffset = 10
GUIMinimap.kMapBackgroundYOffset = 10

GUIMinimap.kBackgroundTextureAlien = "ui/alien_commander_background.dds"
GUIMinimap.kBackgroundTextureMarine = "ui/marine_commander_background.dds"
GUIMinimap.kBackgroundTextureCoords = { X1 = 473, Y1 = 0, X2 = 793, Y2 = 333 }

GUIMinimap.kBigSizeScale = 2
GUIMinimap.kBackgroundSize = GUIScale(300)
GUIMinimap.kBackgroundWidth = GUIMinimap.kBackgroundSize
GUIMinimap.kBackgroundHeight = GUIMinimap.kBackgroundSize

GUIMinimap.kMapMinMax	= 55
GUIMinimap.kMapRatio = function() return ConditionalValue(Client.minimapExtentScale.z > Client.minimapExtentScale.x, Client.minimapExtentScale.z / Client.minimapExtentScale.x, Client.minimapExtentScale.x / Client.minimapExtentScale.z) end

GUIMinimap.kMinimapSmallSize = Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0)
GUIMinimap.kMinimapBigSize = Vector(GUIMinimap.kBackgroundWidth * GUIMinimap.kBigSizeScale, GUIMinimap.kBackgroundHeight * GUIMinimap.kBigSizeScale, 0)

GUIMinimap.kBlipSize = GUIScale(30)
GUIMinimap.kUnpoweredNodeBlipSize = GUIScale(32)

GUIMinimap.kTeamColors = { }
GUIMinimap.kTeamColors[kMinimapBlipTeam.Friendly] = Color(0.5, 0.5, 0.5, 1)
GUIMinimap.kTeamColors[kMinimapBlipTeam.Enemy] = Color(1, 0, 0, 1)
GUIMinimap.kTeamColors[kMinimapBlipTeam.Neutral] = Color(0.5, 0.5, 0.5, 1)

GUIMinimap.kUnpoweredNodeColor = Color(1, 0, 0)

GUIMinimap.kIconFileName = "ui/minimap_blip.dds"
GUIMinimap.kIconWidth = 32
GUIMinimap.kIconHeight = 32

GUIMinimap.kUnpoweredNodeFileName = "ui/power_node_off.dds"
GUIMinimap.kUnpoweredNodeIconWidth = 32
GUIMinimap.kUnpoweredNodeIconHeight = 32

GUIMinimap.kStaticBlipsLayer = 0
GUIMinimap.kPlayerIconLayer = 1
GUIMinimap.kDynamicBlipsLayer = 2

GUIMinimap.kBlipTexture = "ui/blip.dds"

GUIMinimap.kBlipTextureCoordinates = { }
GUIMinimap.kBlipTextureCoordinates[kAlertType.Attack] = { X1 = 0, Y1 = 0, X2 = 64, Y2 = 64 }

GUIMinimap.kAttackBlipMinSize = Vector(GUIScale(25), GUIScale(25), 0)
GUIMinimap.kAttackBlipMaxSize = Vector(GUIScale(100), GUIScale(100), 0)
GUIMinimap.kAttackBlipPulseSpeed = 6
GUIMinimap.kAttackBlipTime = 5
GUIMinimap.kAttackBlipFadeInTime = 4.5
GUIMinimap.kAttackBlipFadeOutTime = 1

GUIMinimap.kLocationFontSize = 12

local ClassToGrid = { }

ClassToGrid["TechPoint"] = { 1, 1 }
ClassToGrid["ResourcePoint"] = { 2, 1 }
ClassToGrid["Door"] = { 3, 1 }
ClassToGrid["DoorLocked"] = { 4, 1 }
ClassToGrid["DoorWelded"] = { 5, 1 }
ClassToGrid["Grenade"] = { 6, 1 }
ClassToGrid["PowerPoint"] = { 7, 1 }

ClassToGrid["ReadyRoomPlayer"] = { 1, 2 }
ClassToGrid["Marine"] = { 1, 2 }
ClassToGrid["Heavy"] = { 2, 2 }
ClassToGrid["Jetpack"] = { 3, 2 }
ClassToGrid["MAC"] = { 4, 2 }
ClassToGrid["CommandStationOccupied"] = { 5, 2 }
ClassToGrid["CommandStationL2Occupied"] = { 6, 2 }
ClassToGrid["CommandStationL3Occupied"] = { 7, 2 }
ClassToGrid["Death"] = { 8, 2 }

ClassToGrid["Skulk"] = { 1, 3 }
ClassToGrid["Gorge"] = { 2, 3 }
ClassToGrid["Lerk"] = { 3, 3 }
ClassToGrid["Fade"] = { 4, 3 }
ClassToGrid["Onos"] = { 5, 3 }
ClassToGrid["Drifter"] = { 6, 3 }
ClassToGrid["HiveOccupied"] = { 7, 3 }
ClassToGrid["Kill"] = { 8, 3 }

ClassToGrid["CommandStation"] = { 1, 4 }
ClassToGrid["CommandStationL2"] = { 2, 4 }
ClassToGrid["CommandStationL3"] = { 3, 4 }
ClassToGrid["Extractor"] = { 4, 4 }
ClassToGrid["Sentry"] = { 5, 4 }
ClassToGrid["ARC"] = { 6, 4 }
ClassToGrid["ARCDeployed"] = { 7, 4 }

ClassToGrid["InfantryPortal"] = { 1, 5 }
ClassToGrid["Armory"] = { 2, 5 }
ClassToGrid["AdvancedArmory"] = { 3, 5 }
ClassToGrid["AdvancedArmoryModule"] = { 4, 5 }
ClassToGrid["Observatory"] = { 6, 5 }

ClassToGrid["HiveBuilding"] = { 1, 6 }
ClassToGrid["Hive"] = { 2, 6 }
ClassToGrid["Harvester"] = { 5, 6 }
ClassToGrid["Hydra"] = { 6, 6 }
ClassToGrid["Egg"] = { 7, 6 }

ClassToGrid["Crag"] = { 1, 7 }
ClassToGrid["MatureCrag"] = { 2, 7 }
ClassToGrid["Whip"] = { 3, 7 }
ClassToGrid["MatureWhip"] = { 4, 7 }

ClassToGrid["WaypointMove"] = { 1, 8 }
ClassToGrid["WaypointDefend"] = { 2, 8 }
ClassToGrid["PlayerFOV"] = { 4, 8 }

/**
 * Returns Column and Row to find the minimap icon for the passed in class.
 */
local function GetSpriteGridByClass(class)

    // This really shouldn't happen but lets return something just in case.
    if not ClassToGrid[class] then
        return 8, 1
    end
    
    return unpack(ClassToGrid[class])
    
end
AddFunctionContract(GetSpriteGridByClass, { Arguments = { "string" }, Returns = { "number", "number" } })

local function PlotToMap(posX, posZ, comMode)

    local adjustedX = posX - Client.minimapExtentOrigin.x
    local adjustedZ = posZ - Client.minimapExtentOrigin.z
    
    local xFactor = 4
    local zFactor = xFactor / GUIMinimap.kMapRatio()

    local plottedX = (adjustedX / (Client.minimapExtentScale.x / xFactor)) * GUIMinimap.kBackgroundSize
    local plottedY = (adjustedZ / (Client.minimapExtentScale.z / zFactor)) * GUIMinimap.kBackgroundSize
    
    if comMode == GUIMinimap.kModeMini then

        plottedX = plottedX / GUIMinimap.kBigSizeScale
        plottedY = plottedY / GUIMinimap.kBigSizeScale

    end
    
    // The world space is oriented differently from the GUI space, adjust for that here.
    // Return 0 as the third parameter so the results can easily be added to a Vector.
    return plottedY, -plottedX, 0

end
AddFunctionContract(PlotToMap, { Arguments = { "number", "number", "number" }, Returns = { "number", "number", "number" } })

function GUIMinimap:Initialize()

    self:InitializeBackground()
    self:InitializeScanlines()
    
    self.minimap = GUIManager:CreateGraphicItem()
    
    self:InitializeLocationNames()
    
    self.comMode = nil
    self:SetBackgroundMode(GUIMinimap.kModeMini)
    self.minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
    self.minimap:SetColor(PlayerUI_GetTeamColor())
    
    self.background:AddChild(self.minimap)
    
    // Used for commander.
    self:InitializeCameraLines()
    // Used for normal players.
    self:InitializePlayerIcon()
    
    self.staticBlips = { }
    
    self.reuseDynamicBlips = { }
    self.inuseDynamicBlips = { }
    
    self.mousePressed = { LMB = { Down = nil, X = 0, Y = 0 }, RMB = { Down = nil, X = 0, Y = 0 } }
    
end

function GUIMinimap:InitializeBackground()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))
    self.background:SetPosition(Vector(0, -GUIMinimap.kBackgroundHeight, 0))
    GUISetTextureCoordinatesTable(self.background, GUIMinimap.kBackgroundTextureCoords)

    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetLayer(kGUILayerMinimap)
    
    // Non-commander players assume the map isn't visible by default.
    if not PlayerUI_IsACommander() then
        self.background:SetIsVisible(false)
    end

end

function GUIMinimap:InitializeScanlines()

    local settingsTable = { }
    settingsTable.Width = GUIMinimap.kBackgroundWidth
    settingsTable.Height = GUIMinimap.kBackgroundHeight
    // The amount of extra scanline space that should be above the minimap.
    settingsTable.ExtraHeight = 0
    self.scanlines = GUIScanlines()
    self.scanlines:Initialize(settingsTable)
    self.scanlines:GetBackground():SetInheritsParentAlpha(true)
    self.background:AddChild(self.scanlines:GetBackground())
    
end

function GUIMinimap:InitializeCameraLines()

    self.cameraLines = GUIManager:CreateLinesItem()
    self.cameraLines:SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.cameraLines:SetLayer(GUIMinimap.kPlayerIconLayer)
    self.minimap:AddChild(self.cameraLines)
    
end

function GUIMinimap:InitializePlayerIcon()
	
    self.playerIcon = GUIManager:CreateGraphicItem()
    self.playerIcon:SetSize(Vector(GUIMinimap.kBlipSize, GUIMinimap.kBlipSize, 0))
	self.playerIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.playerIcon:SetTexture(GUIMinimap.kIconFileName)
	iconCol, iconRow = GetSpriteGridByClass(PlayerUI_GetPlayerClass())
    self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, GUIMinimap.kIconWidth, GUIMinimap.kIconHeight))
    self.playerIcon:SetIsVisible(false)
    self.playerIcon:SetLayer(GUIMinimap.kPlayerIconLayer)
	self.playerIcon:SetColor(Color(0, 1, 0, 1))
    self.minimap:AddChild(self.playerIcon)
    
    self.playerIconFov = GUIManager:CreateGraphicItem()
	self.playerIconFov:SetSize(Vector(GUIMinimap.kBlipSize*2, GUIMinimap.kBlipSize, 0))
	self.playerIconFov:SetAnchor(GUIItem.Middle, GUIItem.Top)
	self.playerIconFov:SetPosition(Vector(-GUIMinimap.kBlipSize, -GUIMinimap.kBlipSize, 0))
	self.playerIconFov:SetTexture(GUIMinimap.kIconFileName)
	local iconCol, iconRow = GetSpriteGridByClass('PlayerFOV')
	local gridPosX, gridPosY, gridWidth, gridHeight = GUIGetSprite(iconCol, iconRow, GUIMinimap.kIconWidth, GUIMinimap.kIconHeight)
	self.playerIconFov:SetTexturePixelCoordinates(gridPosX-GUIMinimap.kIconWidth, gridPosY, gridWidth, gridHeight)
	self.playerIconFov:SetIsVisible(false)
	self.playerIconFov:SetLayer(GUIMinimap.kPlayerIconLayer)
	self.playerIcon:AddChild(self.playerIconFov)

end

function GUIMinimap:InitializeLocationNames()

    self.locationItems = { }
    local locationData = PlayerUI_GetLocationData()
    
    // Average the position of same named locations so they don't display
    // multiple times.
    local multipleLocationsData = { }
    for i, location in ipairs(locationData) do
    
        // Filter out the ready room.
        if location.Name ~= "Ready Room" then
        
            local locationTable = multipleLocationsData[location.Name]
            if locationTable == nil then
            
                locationTable = { }
                multipleLocationsData[location.Name] = locationTable
                
            end
            table.insert(locationTable, location.Origin)
            
        end
        
    end
    
    local uniqueLocationsData = { }
    for name, origins in pairs(multipleLocationsData) do
    
        local averageOrigin = Vector(0, 0, 0)
        table.foreachfunctor(origins, function (origin) averageOrigin = averageOrigin + origin end)
        table.insert(uniqueLocationsData, { Name = name, Origin = averageOrigin / table.count(origins) })
        
    end
    
    for i, location in ipairs(uniqueLocationsData) do
    
        local locationItem = GUIManager:CreateTextItem()
        locationItem:SetFontSize(GUIMinimap.kLocationFontSize)
        locationItem:SetFontIsBold(true)
        locationItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
        locationItem:SetTextAlignmentX(GUIItem.Align_Center)
        locationItem:SetTextAlignmentY(GUIItem.Align_Center)

	    local posX, posY = PlotToMap(location.Origin.x, location.Origin.z, self.comMode)

        // Locations only supported on the big mode.
        locationItem:SetPosition(Vector(posX, posY, 0))
        locationItem:SetColor(Color(1, 1, 1, 1))
        locationItem:SetText(location.Name)
        self.minimap:AddChild(locationItem)
        table.insert(self.locationItems, locationItem)
        
    end

end

function GUIMinimap:Uninitialize()

    // The ItemMask is the parent of the Item so this will destroy both.
    for i, blip in ipairs(self.reuseDynamicBlips) do
        GUI.DestroyItem(blip["ItemMask"])
    end
    self.reuseDynamicBlips = { }
    for i, blip in ipairs(self.inuseDynamicBlips) do
        GUI.DestroyItem(blip["ItemMask"])
    end
    self.inuseDynamicBlips = { }
    
    if self.scanlines then
        self.scanlines:Uninitialize()
        self.scanlines = nil
    end
    
    if self.minimap then
        GUI.DestroyItem(self.minimap)
    end
    self.minimap = nil
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
    
    // The staticBlips are children of the background so will be cleaned up with it.
    self.staticBlips = { }
    
end

function GUIMinimap:SetButtonsScript(setButtonsScript)

    self.buttonsScript = setButtonsScript

end

function GUIMinimap:Update(deltaTime)

    PROFILE("GUIMinimap:Update")
 
    // Commander always sees the minimap.
    if PlayerUI_IsACommander() then
        self.background:SetIsVisible(true)
        if CommanderUI_IsAlienCommander() then
            self.background:SetTexture(GUIMinimap.kBackgroundTextureAlien)
        else
            self.background:SetTexture(GUIMinimap.kBackgroundTextureMarine)
        end
    elseif self.comMode == GUIMinimap.kModeMini then
        // No minimap for non-commaders
        self.background:SetIsVisible(false)
    end
    
    self:UpdateIcon()
    
    self:UpdateStaticBlips(deltaTime)
    
    self:UpdateDynamicBlips(deltaTime)
    
    self:UpdateInput()
    
    if self.minimap:GetIsVisible() then
        // The color cannot be attained right away in some cases so
        // we need to make sure it is the correct color.
        self.minimap:SetColor(PlayerUI_GetTeamColor())
    end
    
    if self.scanlines then
        self.scanlines:Update(deltaTime)
    end
    
end

function GUIMinimap:UpdateIcon()

    PROFILE("GUIMinimap:UpdateIcon")

    if PlayerUI_IsACommander() then

        self.playerIcon:SetIsVisible(false)
        self.playerIconFov:SetIsVisible(false)
        self.cameraLines:SetIsVisible(true)
        
        local topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint = CommanderUI_ViewFarPlanePoints()
        if topLeftPoint == nil then
            return
        end
        
        topLeftPoint = Vector(PlotToMap(topLeftPoint.x, topLeftPoint.z, self.comMode))
        topRightPoint = Vector(PlotToMap(topRightPoint.x, topRightPoint.z, self.comMode))
        bottomLeftPoint = Vector(PlotToMap(bottomLeftPoint.x, bottomLeftPoint.z, self.comMode))
        bottomRightPoint = Vector(PlotToMap(bottomRightPoint.x, bottomRightPoint.z, self.comMode))
        
        self.cameraLines:ClearLines()
        local lineColor = Color(1, 1, 1, 1)
        self.cameraLines:AddLine(topLeftPoint, topRightPoint, lineColor)
        self.cameraLines:AddLine(topRightPoint, bottomRightPoint, lineColor)
        self.cameraLines:AddLine(bottomRightPoint, bottomLeftPoint, lineColor)
        self.cameraLines:AddLine(bottomLeftPoint, topLeftPoint, lineColor)

    elseif PlayerUI_IsAReadyRoomPlayer() then
    
        // No icons for ready room players.
        self.cameraLines:SetIsVisible(false)
        self.playerIcon:SetIsVisible(false)
		self.playerIconFov:SetIsVisible(false)

    else
    
        // Draw a player icon representing this player's position.
		local playerOrigin = PlayerUI_GetOrigin()
		local playerRotation = PlayerUI_GetMinimapPlayerDirection()

		local posX, posY = PlotToMap(playerOrigin.x, playerOrigin.z, self.comMode)

        self.cameraLines:SetIsVisible(false)
        self.playerIcon:SetIsVisible(true)
        // Disabled until rotation is correct.
		//self.playerIconFov:SetIsVisible(true)

		posX = posX - (GUIMinimap.kIconWidth / 2)
		posY = posY - (GUIMinimap.kIconHeight / 2)

        self.playerIcon:SetPosition(Vector(posX, posY, 0))
		self.playerIcon:SetRotation(Vector(0, 0, playerRotation))

		local playerClass = PlayerUI_GetPlayerClass()
		if GUIMinimap.playerClass ~= playerClass then

			local iconCol, iconRow = GetSpriteGridByClass(playerClass)
			self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, GUIMinimap.kIconWidth, GUIMinimap.kIconHeight))

			GUIMinimap.playerClass = playerClass

		end

    end
    
end

function GUIMinimap:UpdateStaticBlips(deltaTime)

    PROFILE("GUIMinimap:UpdateStaticBlips")

    // First hide all previous static blips.
    for index, oldBlip in ipairs(self.staticBlips) do
        oldBlip:SetIsVisible(false)
    end

    
    local staticBlips = PlayerUI_GetStaticMapBlips()
    local blipItemCount = 7
    local numBlips = table.count(staticBlips) / blipItemCount
    local currentIndex = 1
    local freeBlip = 1
    
    // Create all of the blips we'll need.
    for i=#self.staticBlips,numBlips do
        self:AddStaticBlip()
    end    
    
    while numBlips > 0 do
		local xPos, yPos = PlotToMap(staticBlips[currentIndex], staticBlips[currentIndex + 1], self.comMode)
		local rotation = staticBlips[currentIndex + 2]
        local xTexture = staticBlips[currentIndex + 3]
        local yTexture = staticBlips[currentIndex + 4]
        local blipType = staticBlips[currentIndex + 5]
        local blipTeam = staticBlips[currentIndex + 6]
        
        local blip = self.staticBlips[freeBlip]
        freeBlip = freeBlip + 1
        
        self:SetStaticBlip(blip, xPos, yPos, rotation, xTexture, yTexture, blipType, blipTeam)
        currentIndex = currentIndex + blipItemCount
        numBlips = numBlips - 1
        
    end
    
end

function GUIMinimap:SetStaticBlip(foundBlip, xPos, yPos, rotation, xTexture, yTexture, blipType, blipTeam)
    
    PROFILE("GUIMinimap:SetStaticBlip")
    
    local textureName = GUIMinimap.kIconFileName
    local iconWidth = GUIMinimap.kIconWidth
    local iconHeight = GUIMinimap.kIconHeight
	local iconCol = 0
	local iconRow = 0
    local blipColor = GUIMinimap.kTeamColors[blipTeam]
    local blendTechnique = GUIItem.Default
    local blipSize = GUIMinimap.kBlipSize

    // Special case for PowerPoint.
    if blipType == kMinimapBlipType.PowerPoint then

        // Only unpowered node blips are sent.
        blipColor = GUIMinimap.kUnpoweredNodeColor
        local pulseAmount = (math.sin(Shared.GetTime()) + 1) / 2
        blipColor.a = 0.5 + (pulseAmount * 0.5)
    
		iconCol, iconRow = GetSpriteGridByClass('PowerPoint')

    // Everything else is handled here.
    elseif table.contains(kMinimapBlipType, blipType) ~= nil then
    
        iconCol, iconRow = GetSpriteGridByClass(EnumToString(kMinimapBlipType, blipType))

    end
    
	if self.comMode == GUIMinimap.kModeMini then
		
		blipSize = blipSize / 2
		
	end

	foundBlip:SetTexture(textureName)
	foundBlip:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, iconWidth, iconHeight))
    foundBlip:SetIsVisible(true)
    foundBlip:SetSize(Vector(blipSize, blipSize, 0))
	foundBlip:SetPosition(Vector(xPos - (blipSize / 2), yPos - (blipSize / 2), 0))
	foundBlip:SetRotation(Vector(0, 0, rotation))
    foundBlip:SetColor(blipColor)
    foundBlip:SetBlendTechnique(blendTechnique)
    
end

function GUIMinimap:AddStaticBlip()

    addedBlip = GUIManager:CreateGraphicItem()
	addedBlip:SetAnchor(GUIItem.Center, GUIItem.Middle)
    addedBlip:SetLayer(GUIMinimap.kStaticBlipsLayer)
    self.minimap:AddChild(addedBlip)
    table.insert(self.staticBlips, addedBlip)
    return addedBlip

end

function GUIMinimap:UpdateDynamicBlips(deltaTime)

    PROFILE("GUIMinimap:UpdateDynamicBlips")

    if PlayerUI_IsACommander() then
        local newDynamicBlips = CommanderUI_GetDynamicMapBlips()
        local blipItemCount = 3
        local numBlips = table.count(newDynamicBlips) / blipItemCount
        local currentIndex = 1
        while numBlips > 0 do
            local blipType = newDynamicBlips[currentIndex + 2]
            self:AddDynamicBlip(newDynamicBlips[currentIndex], newDynamicBlips[currentIndex + 1], blipType)
            currentIndex = currentIndex + blipItemCount
            numBlips = numBlips - 1
        end
    end
    
    local removeBlips = { }
    for i, blip in ipairs(self.inuseDynamicBlips) do
        if blip["Type"] == kAlertType.Attack then
            if self:UpdateAttackBlip(blip, deltaTime) then
                table.insert(removeBlips, blip)
            end
        end
    end
    for i, blip in ipairs(removeBlips) do
        self:RemoveDynamicBlip(blip)
    end

end

function GUIMinimap:UpdateAttackBlip(blip, deltaTime)

    blip["Time"] = blip["Time"] - deltaTime
    
    // Fade in.
    if blip["Time"] >= GUIMinimap.kAttackBlipFadeInTime then
        local fadeInAmount = ((GUIMinimap.kAttackBlipTime - blip["Time"]) / (GUIMinimap.kAttackBlipTime - GUIMinimap.kAttackBlipFadeInTime))
        blip["Item"]:SetColor(Color(1, 1, 1, fadeInAmount))
    else
        blip["Item"]:SetColor(Color(1, 1, 1, 1))
    end
    
    // Fade out.
    if blip["Time"] <= GUIMinimap.kAttackBlipFadeOutTime then
        if blip["Time"] <= 0 then
            // Done animating.
            return true
        end
        blip["Item"]:SetColor(Color(1, 1, 1, blip["Time"] / GUIMinimap.kAttackBlipFadeOutTime))
    end
    
    local timeLeft = GUIMinimap.kAttackBlipTime - blip["Time"]
    local pulseAmount = (math.sin(timeLeft * GUIMinimap.kAttackBlipPulseSpeed) + 1) / 2
    local blipSize = LerpGeneric(GUIMinimap.kAttackBlipMinSize, GUIMinimap.kAttackBlipMaxSize / 2, pulseAmount)
    
    blip["Item"]:SetSize(blipSize)
    // Make sure it is always centered.
    local sizeDifference = GUIMinimap.kAttackBlipMaxSize - blipSize
    local minimapSize = self:GetMinimapSize()
    local xOffset = (sizeDifference.x / 2) - GUIMinimap.kAttackBlipMaxSize.x / 2
    local yOffset = (sizeDifference.y / 2) - GUIMinimap.kAttackBlipMaxSize.y / 2
    local plotX, plotY = PlotToMap(blip["X"], blip["Y"], self.comMode)
    blip["Item"]:SetPosition(Vector(plotX + xOffset, plotY + yOffset, 0))
    
    // Not done yet.
    return false

end

function GUIMinimap:AddDynamicBlip(xPos, yPos, blipType)

    /**
     * Blip types - kAlertType
     * 
     * 0 - Attack
     * Attention-getting spinning squares that start outside the minimap and spin down to converge to point 
     * on map, continuing to draw at point for a few seconds).
     * 
     * 1 - Info
     * Research complete, area blocked, structure couldn't be built, etc. White effect, not as important to
     * grab your attention right away).
     * 
     * 2 - Request
     * Soldier needs ammo, asking for order, etc. Should be yellow or green effect that isn't as 
     * attention-getting as the under attack. Should draw for a couple seconds.)
     */

    if blipType == kAlertType.Attack then
        if self.scanlines then
            // Disrupt should probably be a global function that disrupts all scanlines at the same time.
            self.scanlines:Disrupt()
        end
        addedBlip = self:GetFreeDynamicBlip(xPos, yPos, blipType)
        addedBlip["Item"]:SetSize(Vector(0, 0, 0))
        addedBlip["Time"] = GUIMinimap.kAttackBlipTime
    end
    
end

function GUIMinimap:RemoveDynamicBlip(blip)

    blip["Item"]:SetIsVisible(false)
    table.removevalue(self.inuseDynamicBlips, blip)
    table.insert(self.reuseDynamicBlips, blip)
    
end

function GUIMinimap:GetFreeDynamicBlip(xPos, yPos, blipType)

    local returnBlip = nil
    if table.count(self.reuseDynamicBlips) > 0 then
    
        returnBlip = self.reuseDynamicBlips[1]
        table.removevalue(self.reuseDynamicBlips, returnBlip)
        table.insert(self.inuseDynamicBlips, returnBlip)
        
    else
    
        returnBlip = { }
        returnBlip["Item"] = GUIManager:CreateGraphicItem()
        // Make sure these draw a layer above the minimap so they are on top.
        returnBlip["Item"]:SetLayer(GUIMinimap.kDynamicBlipsLayer)
        returnBlip["Item"]:SetTexture(GUIMinimap.kBlipTexture)
        returnBlip["Item"]:SetBlendTechnique(GUIItem.Add)
		returnBlip["Item"]:SetAnchor(GUIItem.Center, GUIItem.Middle)
        self.minimap:AddChild(returnBlip["Item"])
        table.insert(self.inuseDynamicBlips, returnBlip)
        
    end
    
    returnBlip["X"] = xPos
    returnBlip["Y"] = yPos
    
    returnBlip["Type"] = blipType
    returnBlip["Item"]:SetIsVisible(true)
    returnBlip["Item"]:SetColor(Color(1, 1, 1, 1))
    local minimapSize = self:GetMinimapSize()
    local plotX, plotY = PlotToMap(xPos, yPos, self.comMode)
	returnBlip["Item"]:SetPosition(Vector(plotX, plotY, 0))
    GUISetTextureCoordinatesTable(returnBlip["Item"], GUIMinimap.kBlipTextureCoordinates[blipType])
    return returnBlip
    
end

function GUIMinimap:UpdateInput()

    if PlayerUI_IsACommander() then
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if self.mousePressed["LMB"]["Down"] then
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if containsPoint then
                local minimapSize = self:GetMinimapSize()
                local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                
                local cameraPosition = Vector(mouseX, mouseY, 0)
                
                cameraPosition.x = cameraPosition.x - backgroundScreenPosition.x
                cameraPosition.y = cameraPosition.y - backgroundScreenPosition.y

                local horizontalScale = CommanderUI_MapLayoutHorizontalScale()
                local verticalScale = CommanderUI_MapLayoutVerticalScale()

                local moveX = (cameraPosition.x / minimapSize.x) * horizontalScale
                local moveY = (cameraPosition.y / minimapSize.y) * verticalScale

                CommanderUI_MapMoveView(moveX, moveY)
            end
        end
    end

end

function GUIMinimap:SetBackgroundMode(setMode)

    if self.comMode ~= setMode then
    
        self.comMode = setMode
        local modeIsMini = self.comMode == GUIMinimap.kModeMini
        
        // Locations only visible in the big mode
        table.foreachfunctor(self.locationItems, function (item) item:SetIsVisible(not modeIsMini) end)
        
        local modeSize = self:GetMinimapSize()
        
        if self.background then
            if modeIsMini then
                self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
                self.background:SetPosition(Vector(GUIMinimap.kMapBackgroundXOffset, -GUIMinimap.kBackgroundHeight - GUIMinimap.kMapBackgroundYOffset, 0))
                self.background:SetColor(Color(1, 1, 1, 1))
            else
                self.background:SetAnchor(GUIItem.Center, GUIItem.Middle)
                self.background:SetPosition(Vector(-modeSize.x / 2, -modeSize.y / 2, 0))
                self.background:SetColor(Color(1, 1, 1, 0))
            end
        end
        self.minimap:SetSize(modeSize)
        
        // We want the background to sit "inside" the border so move it up and to the right a bit.
        local borderExtraWidth = ConditionalValue(self.background, GUIMinimap.kBackgroundWidth - self:GetMinimapSize().x, 0)
        local borderExtraHeight = ConditionalValue(self.background, GUIMinimap.kBackgroundHeight - self:GetMinimapSize().y, 0)
        local defaultPosition = Vector(borderExtraWidth / 2, borderExtraHeight / 2, 0)
        local modePosition = ConditionalValue(modeIsMini, defaultPosition, Vector(0, 0, 0))
        self.minimap:SetPosition(modePosition)
        
    end
    
end

function GUIMinimap:GetMinimapSize()

    return ConditionalValue(self.comMode == GUIMinimap.kModeMini, GUIMinimap.kMinimapSmallSize, GUIMinimap.kMinimapBigSize)
    
end

function GUIMinimap:GetPositionOnBackground(xPos, yPos, currentSize)

    local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
    local inBackgroundPosition = Vector((xPos * self:GetMinimapSize().x) - (currentSize.x / 2), (yPos * self:GetMinimapSize().y) - (currentSize.y / 2), 0)
    return backgroundScreenPosition + inBackgroundPosition

end

// Shows or hides the big map.
function GUIMinimap:ShowMap(showMap)
    
    // Non-commander players only see the map when the key is held down.
    if not PlayerUI_IsACommander() then
        self.background:SetIsVisible(showMap)
    end
    
    local previousComMode = self.comMode
    
    self:SetBackgroundMode(ConditionalValue(showMap, GUIMinimap.kModeBig, GUIMinimap.kModeMini))

    // Only call Update when the state changes 
    if previousComMode ~= self.comMode then
        // Make sure everything is in sync in case this function is called after GUIMinimap:Update() is called.
        self:Update(0)
    end

end

function GUIMinimap:SendKeyEvent(key, down)
    
    if PlayerUI_IsACommander() then
        if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
            
            self.mousePressed["LMB"]["Down"] = down
            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if down and containsPoint then
                local buttonIndex = nil
                // $AS Left click now just moves the mini map the old behavior was confusing and not consistent              
               /* if self.buttonsScript then
                    buttonIndex = self.buttonsScript:GetTargetedButton()
                    Print("index = %s", ToString(buttonIndex))
                end
                if buttonIndex == nil then
                    CommanderUI_ActionCancelled()
                    self.buttonsScript:SetTargetedButton(nil)
                    CommanderUI_MapClicked(withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y, 0, buttonIndex)
                    // The down event is considered "captured" at this point and shouldn't be processed in UpdateInput().
                    self.mousePressed["LMB"]["Down"] = false
                    result = true
                end */
                return false
            end
        elseif key == InputKey.MouseButton1 and self.mousePressed["RMB"]["Down"] ~= down then
            self.mousePressed["RMB"]["Down"] = down
            local mouseX, mouseY = Client.GetCursorPosScreen()
            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if down and containsPoint then
                if self.buttonsScript then
                    // Cancel just in case the user had a targeted action selected before this press.
                    CommanderUI_ActionCancelled()
                    self.buttonsScript:SetTargetedButton(nil)
                end
                CommanderUI_MapClicked(withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y, 1, nil)
                return true
            end
        end
    end
    
    return false

end

function GUIMinimap:GetBackground()

    return self.background

end

function GUIMinimap:ContainsPoint(pointX, pointY)

    return GUIItemContainsPoint(self:GetBackground(), pointX, pointY) or GUIItemContainsPoint(self.minimap, pointX, pointY)

end
