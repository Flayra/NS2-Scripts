// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Commander_Alerts.lua")
Script.Load("lua/Commander_Buttons.lua")
Script.Load("lua/Commander_FocusPanel.lua")
Script.Load("lua/Commander_HotkeyPanel.lua")
Script.Load("lua/Commander_IdleWorkerPanel.lua")
Script.Load("lua/Commander_PlayerAlertPanel.lua")
Script.Load("lua/Commander_ResourcePanel.lua")
Script.Load("lua/Commander_SelectionPanel.lua")
Script.Load("lua/Commander_SquadsPanel.lua")

function CommanderUI_UpdateMouseOverUIState(overUI)

    local player = Client.GetLocalPlayer()
    player.cursorOverUI = overUI

end

function CommanderUI_IsLocalPlayerCommander()

    local player = Client.GetLocalPlayer()
    if player and player:isa("Commander") then
        return true
    end
    
    return false

end

function CommanderUI_IsAlienCommander()

    local player = Client.GetLocalPlayer()
    if player and player:isa("AlienCommander") then
        return true
    end
    
    return false
    
end

function CommanderUI_MapImage()
    return "map"
end

/**
 * Return width of view in geometry space.
 */
function CommanderUI_MapViewWidth()
    return 1
end

/**
 * Return height of view in geometry space.
 */
function CommanderUI_MapViewHeight()
    return 1
end

/**
 * Return x center of view in geometry coordinate space.
 */
function CommanderUI_MapViewCenterX()
    local player = Client.GetLocalPlayer()
    return player:GetScrollPositionX()
end

/**
 * Return y center of view in geometry coordinate space
 */
function CommanderUI_MapViewCenterY()
    local player = Client.GetLocalPlayer()
    return player:GetScrollPositionY()
end

/**
 * Returns the commander view far frustum plane points in world space.
 */
function CommanderUI_ViewFarPlanePoints()

    local player = Client.GetLocalPlayer()
    
    local camera = Camera()
    camera:SetType(Camera.Perspective)
    local cameraCoords = player:GetCameraViewCoords()
    camera:SetCoords(cameraCoords)
    camera:SetFov(player:GetRenderFov())
    
    // Find the ground elevation.
    local groundConstant = 11.5
    local elevation = player.heightmap:GetElevation(cameraCoords.origin.x, cameraCoords.origin.z) - groundConstant
    local planePoint = Vector(cameraCoords.origin.x, elevation, cameraCoords.origin.z)
    local planeNormal = GetNormalizedVector(cameraCoords.origin - planePoint)
    
    local frustum = camera:GetFrustum()
    
    local topLeftLine = frustum:GetPoint(4) - frustum:GetPoint(0)
    local topLeftPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(0), GetNormalizedVector(topLeftLine))
    
    local topRightLine = frustum:GetPoint(7) - frustum:GetPoint(3)
    local topRightPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(3), GetNormalizedVector(topRightLine))
    
    local bottomLeftLine = frustum:GetPoint(5) - frustum:GetPoint(1)
    local bottomLeftPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(1), GetNormalizedVector(bottomLeftLine))
    
    local bottomRightLine = frustum:GetPoint(6) - frustum:GetPoint(2)
    local bottomRightPoint = GetLinePlaneIntersection(planePoint, planeNormal, frustum:GetPoint(2), GetNormalizedVector(bottomRightLine))
    
    if topLeftPoint == nil or topRightPoint == nil or bottomLeftPoint == nil or bottomRightPoint == nil then
        return
    end
    
    ASSERT(topLeftPoint.z < topRightPoint.z)
    ASSERT(bottomLeftPoint.z < bottomRightPoint.z)
    ASSERT(topLeftPoint.x > bottomLeftPoint.x)
    ASSERT(topRightPoint.x > bottomRightPoint.x)
    
    return topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint
    
end

/**
 * Return horizontal scale (geometry/pixel)       
 */
function CommanderUI_MapLayoutHorizontalScale()
    return GetMinimapHorizontalScale(Client.GetLocalPlayer():GetHeightmap())
end

/**
 * Return vertical scale (geometry/pixel).
 */
function CommanderUI_MapLayoutVerticalScale()
    return GetMinimapVerticalScale(Client.GetLocalPlayer():GetHeightmap())
end

/**
 * Returns 0-1 scalar indicating the playable (non black border) width of the minimap.
 */
function CommanderUI_MapLayoutPlayableWidth()
    return GetMinimapPlayableWidth(Client.GetLocalPlayer():GetHeightmap())
end

/**
 * Returns 0-1 scalar indicating the playable (non black border) width of the minimap.
 */
function CommanderUI_MapLayoutPlayableHeight()
    return GetMinimapPlayableHeight(Client.GetLocalPlayer():GetHeightmap())
end

// Coords coming in are in terms of playable width and height
// Ie, not 0,0 to 1,1 most of the time, but for a vertical map, perhaps 0 to .4 for xc
// and 0 to 1 for yc.
function CommanderUI_MapMoveView(xc, yc)

    // Scroll map with left-click
    local player = Client.GetLocalPlayer()        
    local normX, normY = GetMinimapNormCoordsFromPlayable(player:GetHeightmap(), xc, yc)
    
    player:SetScrollPosition(normX, normY)

end

// x and y are the normalized map coords just like CommanderUI_MapMoveView(xc, yc).
// button is 0 for LMB, 1 for RMB
// Index is the button index whose targeting mode we're in (only if button == 0, nil otherwise)
function CommanderUI_MapClicked(x, y, button, index)

    // Translate minimap coords to world position
    local player = Client.GetLocalPlayer()
    local worldCoords = MinimapToWorld(player, x, y)
    
    if button == 0 then
    
        if index ~= nil then

            player:SendTargetedActionWorld(GetTechIdFromButtonIndex(index), worldCoords)
            
        else
            Print("CommanderUI_MapClicked(x, y, button, index) called with button 0 and no button index.")
        end        
        
    // Give default order with right-click
    elseif button == 1 then
    
        player:SendTargetedActionWorld(kTechId.Default, worldCoords)
        player.timeMinimapRightClicked = Shared.GetTime()
            
    end
    
end

function CommanderUI_OnMousePress(mouseButton, x, y)

    local player = Client.GetLocalPlayer()
    player:ClientOnMousePress(mouseButton, x, y)
    
end

function CommanderUI_OnMouseRelease(mouseButton, x, y)

    local player = Client.GetLocalPlayer()
    
    // The .swf gives us both minimap and mouse release events, so don't process this one again
    if mouseButton ~= 1 or (player.timeMinimapRightClicked == nil or (Shared.GetTime() > (player.timeMinimapRightClicked + .2))) then
        player:ClientOnMouseRelease(mouseButton, x, y)
    end
    
end

/** 
 * Called from flash to determine if a tech on the button triggers instantly
 * or if it will look for a second mouse click afterwards.
 */
function CommanderUI_MenuButtonRequiresTarget(index)

    local techId = GetTechIdFromButtonIndex(index)
    local techTree = GetTechTree()
    local requiresTarget = false
    
    if(tech ~= 0 and techTree) then
    
        local techNode = techTree:GetTechNode(techId)
        
        if(techNode ~= nil) then
        
            // Buy nodes require a target for the commander
            requiresTarget = techNode:GetRequiresTarget() or techNode:GetIsBuy() or techNode:GetIsEnergyBuild()
            
        end
        
    end
        
    return requiresTarget
    
end

// Returns nil or the index into the menu button array if the player
// just pressed a hotkey. The hotkey hit will always be set to nil after
// this function is called to make sure it's only triggered once.
function CommanderUI_HotkeyTriggeredButton()

    local hotkeyHit = nil
    local player = Client.GetLocalPlayer()
    
    if player.hotkeyIndexHit ~= nil then
    
        hotkeyHit = player.hotkeyIndexHit
        player.hotkeyIndexHit = nil
        
    end
    
    return hotkeyHit
    
end

function Commander:SetHotkeyHit(index)
    self.hotkeyIndexHit = index
end

function Commander:HandleCommanderESC(input)

    // Handle ESC
    if input.hotkey == Move.ESC then
        Print("ESC hit")
        //self.commanderCancel = true
        //self.currentTechId = kTechId.None
        //self.specifyingOrientation = false
        //self:SetCurrentTech(kTechId.None)

    end

end

function Commander:OnDestroy()

    Player.OnDestroy(self)

    local player = Client.GetLocalPlayer()
    
    if self.hudSetup == true then
    
        GetGUIManager():DestroyGUIScriptSingle("GUICommanderAlerts")
        GetGUIManager():DestroyGUIScriptSingle("GUISelectionPanel")
        
        GetGUIManager():DestroyGUIScript(self.buttonsScript)
        self.buttonsScript = nil
        
        GetGUIManager():DestroyGUIScriptSingle("GUIHotkeyIcons")
        GetGUIManager():DestroyGUIScriptSingle("GUICommanderLogout")
        GetGUIManager():DestroyGUIScriptSingle("GUIResourceDisplay")
        GetGUIManager():DestroyGUIScriptSingle("GUICommanderManager")
        
        GetGUIManager():DestroyGUIScriptSingle("GUIPlayerNames")
        self.guiPlayerNames = nil
        
        GetGUIManager():DestroyGUIScriptSingle("GUIOrders")
        self.guiOrders = nil        
        
        self:DestroyGhostStructure()
        self:DestroySelectionCircles()
        self:DestroyGhostGuides()
        
        Client.DestroyRenderModel(self.unitUnderCursorRenderModel)
        
        Client.DestroyRenderModel(self.orientationRenderModel)
        
        Client.DestroyRenderModel(self.sentryRangeRenderModel)
        
        self.hudSetup = false
        
    end
    
end

function Commander:DestroySelectionCircles()
    
    // Delete old circles, if any
    if self.selectionCircles ~= nil then
    
        for index, circlePair in ipairs(self.selectionCircles) do
            Client.DestroyRenderModel(circlePair[2])
        end
        
    end
    
    self.selectionCircles = {}
    
    // Delete old circles, if any
    if self.sentryArcs ~= nil then
    
        for index, sentryPair in ipairs(self.sentryArcs) do
            Client.DestroyRenderModel(sentryPair[2])
            Client.DestroyRenderModel(sentryPair[3])
        end
        
    end
    
    self.sentryArcs = {}

end

// Creates ghost structure that is positioned where building would go
function Commander:CreateGhostStructure(techId)

    local techNode = GetTechNode(techId)
    
    if(techNode ~= nil and (techNode:GetIsBuild() or techNode:GetIsBuy() or techNode:GetIsEnergyBuild())) then
    
        self:DestroyGhostStructure()
        
        ASSERT(self.ghostStructure == nil)
        
        local modelName = LookupTechData(techId, kTechDataModel)
        
        if modelName then
        
            local modelIndex = Shared.GetModelIndex(modelName)
            self.ghostStructure = Client.CreateRenderModel(RenderScene.Zone_Default)
            
            self.ghostStructure:SetModel(modelIndex)
            self.ghostStructureValid = false
                            
        end
            
    else
        self:DestroyGhostStructure()
    end
    
end

function Commander:AddGhostGuide(origin, radius)

    // Insert point, circle
    local guide = Client.CreateRenderModel(RenderScene.Zone_Default)
    local modelName = ConditionalValue(self:GetTeamType() == kAlienTeamType, Commander.kAlienCircleModelName, Commander.kMarineCircleModelName)
    guide:SetModel(modelName)
    guide:SetCoords(BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), origin + Vector(0, kZFightingConstant, 0), radius * 2))
    guide:SetIsVisible(true)
    
    table.insert(self.ghostGuides, {origin, guide})

end

// Check tech id and create guides showing where extractors, harvesters, infantry portals, etc. go. Also draw
// visual range for selected units if they are specified.
function Commander:UpdateGhostGuides()

    local kGhostGuideUpdateTime = .3

    // Only update every so often (update immediately after minimap click?)
    if self.timeOfLastGhostGuideUpdate == nil or Shared.GetTime() > self.timeOfLastGhostGuideUpdate + kGhostGuideUpdateTime then

        self:DestroyGhostGuides()
    
        local techId = self.currentTechId
        if techId ~= nil and techId ~= kTechId.None then
            
            // check if entity has a special ghost guide method
            local method = LookupTechData(techId, kTechDataGhostGuidesMethod, nil)
            
            if method then
                local guides = method(self)
                for entity, radius in pairs(guides) do
                    self:AddGhostGuide(Vector(entity:GetOrigin()), radius)
                end
            end
            
            // If entity can only be placed within range of attach structures, get all the ents that
            // count for this and draw circles around them
            local ghostRadius = LookupTechData(techId, kStructureAttachRange, 0)
            
            if ghostRadius ~= 0 then
            
                // Lookup attach entity 
                local attachId = LookupTechData(techId, kStructureAttachId)
                
                // Handle table of attach ids
                local supportingTechIds = {}
                if type(attachId) == "table" then
                    for index, currentAttachId in ipairs(attachId) do
                        table.insert(supportingTechIds, GetTechTree():ComputeUpgradedTechIdsSupportingId(currentAttachId))
                    end
                else
                    table.insert(supportingTechIds, GetTechTree():ComputeUpgradedTechIdsSupportingId(attachId))
                end                
                
                for index, ent in ipairs(GetEntsWithTechId(supportingTechIds)) do                
                    self:AddGhostGuide(Vector(ent:GetOrigin()), ghostRadius)                
                end
   
            else
 
                // Otherwise, draw only the free attach entities for this build tech (this is the common case)
                for index, ent in ipairs(GetFreeAttachEntsForTechId(techId)) do
                
                    self:AddGhostGuide(Vector(ent:GetOrigin()), Commander.kStructureSnapRadius)
                    
                end

            end
            
            // If attach range specified, then structures don't go on this attach point, but within this range of it            
            self.attachRange = LookupTechData(techId, kStructureAttachRange, nil)
            
        end
        
        // Now draw visual ranges for selected units
        for index, entityEntry in pairs(self.selectedEntities) do    
        
            // Draw visual range on structures that specify it (no building effects)
            local entity = Shared.GetEntity(entityEntry[1])
            if entity ~= nil then
            
                local visualRadius = entity:GetVisualRadius()
                
                if visualRadius ~= nil then
                    self:AddGhostGuide(Vector(entity:GetOrigin()), visualRadius)
                end
                
            end
            
        end
       
        self.timeOfLastGhostGuideUpdate = Shared.GetTime()
 
    end
    
end

function Commander:GetCystParentFromCursor()

    PROFILE("Commander:GetCystParentFromCursor")

    local x, y = Client.GetCursorPosScreen()           
    local trace = GetCommanderPickTarget(self, CreatePickRay(self, x, y), false, true)
    local endPoint = trace.endPoint
    
    if trace.fraction == 1 then
    
        // the pointer is not on the map. set the pointer to where it intersects y==0, so we can get a reasonable range to it
        local dy = trace.endPoint.y - self:GetOrigin().y
        local frac = self:GetOrigin().y / math.abs(dy)
        endPoint = self:GetOrigin() + (trace.endPoint - self:GetOrigin()) * frac          
        
    end
    
    return GetCystParentFromPoint(endPoint, trace.normal)

end

function Commander:DestroyGhostGuides()

    if self.ghostGuides then
    
        for index, guide in ipairs(self.ghostGuides) do
        
            Client.DestroyRenderModel(guide[2])
            
        end
        
    end
        
    self.ghostGuides = {}
    
end

function Commander:DestroyGhostStructure()

    if(self.ghostStructure ~= nil) then
    
        Client.DestroyRenderModel(self.ghostStructure)
        self.ghostStructure = nil
        self.ghostStructureValid = false
        
    end
    
end

// Update ghost structure position to show where building would go
function Commander:UpdateGhostStructureVisuals()

    if self.ghostStructure then

        local x, y = Client.GetCursorPosScreen()           
        
        local trace = GetCommanderPickTarget(self, CreatePickRay(self, x, y), false, true)
        
        local valid, position, attachEntity = GetIsBuildLegal(self.currentTechId, trace.endPoint, Commander.kStructureSnapRadius, self)

        local item = GUI.GetCursorFocus(x, y, Client.GetScreenWidth(), Client.GetScreenHeight())
        if (item ~= nil) then
          valid = false
        end
        
        local coords = Coords.GetIdentity()        

        if self.specifyingOrientation then
        
            // Preserve position, but update angle from mouse (pass pitch yaw roll to Angles)
            local angles = Angles(0, self.orientationAngle, 0)
            coords = BuildCoordsFromDirection(angles:GetCoords().zAxis, self.ghostStructure:GetCoords().origin)
            
        elseif attachEntity then        
         
            coords = attachEntity:GetAngles():GetCoords()
            coords.origin = position
            
        else
            coords.origin = position
        end
        
        self.ghostStructure:SetCoords(coords)    

        if not self.specifyingOrientation then

            // TODO: Update color of ghost structure depending on valid
            self.ghostStructureValid = valid
            self.ghostStructure:SetIsVisible(valid)
            
        end
        
    end

end

/** 
 * Flash should call this whenever we're in a mode like waiting for a target. If this returns true,
 * the action should be cancelled and the mode should be exited. For instance, if selecting a target
 * for an ability and CommanderUI_ActionCancelled() returns true, the menu should no longer highlight
 * that ability's button and mouse input should return to normal. This returns true when a player
 * triggers the CommCancel command.
 */
function CommanderUI_ActionCancelled()

    local player = Client.GetLocalPlayer()
    local cancelled = (player.commanderCancel ~= nil) and (player.commanderCancel == true)
    
    // Clear cancel after we trigger it
    player.commanderCancel = false
    
    player:DestroyGhostStructure()
    
    return cancelled
    
end

/**
 * Called when the user drags out a selection box. The coordinates are in
 * pixel space.
 */
function CommanderUI_SelectMarquee(selectStartX, selectStartY, selectEndX, selectEndY)
   
    local player = Client.GetLocalPlayer()        
    player:SelectMarquee(selectStartX, selectStartY, selectEndX, selectEndY)

end

/**
 * Called by Flash when the mouse is at the edge of the screen.
 */
function CommanderUI_ScrollView(deltaX, deltaY) 
   
    local player = Client.GetLocalPlayer()        
    player.scrollX = deltaX
    player.scrollY = deltaY

end

function GetTechIdFromButtonIndex(index)

    local techId = kTechId.None
    local player = Client.GetLocalPlayer()
    
    if(index <= table.count(player.menuTechButtons)) then
        techId = player.menuTechButtons[index]
    end
       
    return techId
    
end

function Commander:CloseMenu()

    if self.ghostStructure ~= nil then
        return self:DestroyGhostStructure()
    end
    
    return Player.CloseMenu(self)
    
end

// var mouseButton:Number = (_lbutton?1:0) + (_mbutton?4:0) + (_rbutton?2:0);
function CommanderUI_TargetedAction(index, x, y, button)

    local techId = GetTechIdFromButtonIndex(index)   
    local player = Client.GetLocalPlayer()
    local normalizedPickRay = CreatePickRay(player, x, y)
    
    if button == 1 then
    
        // Send order target to where ghost structure is, in case it was snapped to an attach point
        if player.ghostStructureValid then

            local ghostOrigin = player.ghostStructure:GetCoords().origin
            local ghostScreenPos = Client.WorldToScreen(ghostOrigin)
            
            local pickRay = CreatePickRay(player, ghostScreenPos.x, ghostScreenPos.y)
            VectorCopy(pickRay, normalizedPickRay)
            
        end

        // Don't destroy ghost when they first place the sentry - allow commander to specify orientation
        if not LookupTechData(techId, kTechDataSpecifyOrientation, false) or player.specifyingOrientation then

            player:SendTargetedAction(techId, normalizedPickRay)
            player:SetCurrentTech(kTechId.None)
            
        end
        
        // Don't allow selection until next mouse up
        player.mouseButtonUpSinceAction[button] = false
        
    end
    
end

/**
 * Called to determine if target is valid for a targeted tech id. For example, this function
 * could return false when trying to place a medpack on an alien. 
 */
function CommanderUI_IsValid(button, x, y)

    // Check for valid structure placement
    local valid = false
    
    local player = Client.GetLocalPlayer()
    if player.currentTechId ~= nil and player.currentTechId ~= kTechId.None then

        // To allow canceling structures, esp. ones with attach points (this button index seems off by 1)
        if button == 2 then
            valid = true
        else
        
            local techNode = GetTechNode(player.currentTechId)
            if techNode ~= nil and (techNode:GetIsBuild() or techNode:GetIsBuy() or techNode:GetIsEnergyBuild()) then
            
                local trace = GetCommanderPickTarget(player, CreatePickRay(player, x, y), false, true)        
                valid = GetIsBuildLegal(player.currentTechId, trace.endPoint, Commander.kStructureSnapRadius, player)
                
                if (techNode:GetIsBuild() or techNode:GetIsEnergyBuild()) then
                    local item = GUI.GetCursorFocus(x, y, Client.GetScreenWidth(), Client.GetScreenHeight())
                    if (item ~= nil) then
                        valid = false
                    end
                end
                
            else
                valid = true
            end
            
        end
        
    else
        // Needed to make sure we can leave targeting mode
        valid = true        
    end
    
    return valid
    
end

/**
 * Returns a linear array of dynamic blip data
 * These are ONE-SHOT, i.e. once a blip is requested 
 * from this function, it should be removed from the 
 * list of blips returned
 * from this function
 *
 * Data is formatted as:
 * X position, Y position, blip type
 *
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
 *
 * Eg {0.5, 0.5, 2} generates a request in the middle of the map
 */
function CommanderUI_GetDynamicMapBlips()

    return Client.GetLocalPlayer():GetAndClearAlertBlips()

end

function Commander:AddAlert(techId, worldX, worldZ, entityId, entityTechId)
    
    assert(worldX)
    assert(worldZ)
    
    // Create alert blip
    local alertType = LookupTechData(techId, kTechDataAlertType, kAlertType.Info)

    table.insert(self.alertBlips, worldX)
    table.insert(self.alertBlips, worldZ)
    table.insert(self.alertBlips, alertType - 1)
    
    // Create alert message => {text, icon x offset, icon y offset, -1, entity id}
    local alertText = GetDisplayNameForAlert(techId, "")
    
    local xOffset, yOffset = GetMaterialXYOffset(entityTechId, self:isa("MarineCommander"))
    if not xOffset or not yOffset then
        Shared.Message("Warning: Missing texture offsets for alert: " .. alertText)
        xOffset = 0
        yOffset = 0
    end
    
    table.insert(self.alertMessages, alertText)
    table.insert(self.alertMessages, xOffset)
    table.insert(self.alertMessages, yOffset)
    table.insert(self.alertMessages, entityId)
    table.insert(self.alertMessages, worldX)
    table.insert(self.alertMessages, worldZ)
    
end

function Commander:GetAndClearAlertBlips()

    local alertBlips = {}
    table.copy(self.alertBlips, alertBlips)
    table.clear(self.alertBlips)
    return alertBlips
    
end

function Commander:GetAndClearAlertMessages()

    local alertMessages = {}
    table.copy(self.alertMessages, alertMessages)
    table.clear(self.alertMessages)
    return alertMessages

end

function Commander:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    self:SetupHud()
    
    // Turn off skybox rendering when commanding
    SetSkyboxDrawState(false)
    
    // Set props invisible for Comm      
    SetCommanderPropState(true)
    
    // Turn off sound occlusion for Comm
    Client.SetSoundGeometryEnabled(false)
    
    // Set commander geometry invisible
    Client.SetGroupIsVisible(kCommanderInvisibleGroupName, false)
    
    // Turn off fog to improve look
    Client.SetEnableFog(false)
    
    // Set our location so we are viewing the command structure we're in
    self:SetStartPosition() 
    
    self.selectionCircles = {}
    
    self.sentryArcs = {}
    
    self.ghostGuides = {}
    
    self.alertBlips = {}
    
    self.alertMessages = {}

    if self.guiOrders == nil then
        self.guiOrders = GetGUIManager():CreateGUIScriptSingle("GUIOrders")
    end
    
    if self.guiPlayerNames == nil then
        self.guiPlayerNames = GetGUIManager():CreateGUIScriptSingle("GUIPlayerNames")
    end
    
    self.cursorOverUI = false
    
    self.lastHotkeyIndex = nil
    
    self:TriggerButtonIndex(1, CommanderUI_IsAlienCommander())

end

function Commander:SetStartPosition()

    local entId = FindNearestEntityId("CommandStructure", self:GetOrigin())
    local commandStructure = Shared.GetEntity(entId)
    if commandStructure ~= nil then
    
        local origin = commandStructure:GetOrigin()
        self:SetWorldScrollPosition(origin.x, origin.z)
        
    else
        Print("%s:SetStartPosition(): Couldn't find command structure to center view upon.", self:GetClassName())
    end
    
end

/**
 * Allow player to create a different move if desired (Client only).
 */
function Commander:OverrideInput(input)

    // Look for scroll commands and move position
    if (bit.band(input.commands, Move.ScrollForward) ~= 0) then self.scrollY = -1 end
    if (bit.band(input.commands, Move.ScrollBackward) ~= 0) then self.scrollY = 1 end
    if (bit.band(input.commands, Move.ScrollLeft) ~= 0) then self.scrollX = -1 end
    if (bit.band(input.commands, Move.ScrollRight) ~= 0) then self.scrollX = 1 end
    
    // Completely override movement and impulses
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0
    
    // Move to position if minimap clicked or idle work clicked
    if self.setScrollPosition then
    
        input.commands = bit.bor(input.commands, Move.Minimap)
        
        // Put in yaw and pitch because they are 16 bits
        // each. Without them we get a "settling" after
        // clicking the minimap due to differences after
        // sending to the server
        input.yaw = self.minimapNormX
        input.pitch = self.minimapNormY
        
        self.setScrollPosition = false

    else    
    
        input.move.x = -self.scrollX
        input.move.y = -self.scrollY

    end
    
    if (self.hotkeyGroupButtonPressed) then
    
        if (self.hotkeyGroupButtonPressed == 1) then
            input.commands = bit.bor(input.commands, Move.Weapon1)
        end            
            
        self.hotkeyGroupButtonPressed = nil
    end
    
    if (self.selectHotkeyGroup ~= 0) then
    
        // Process hotkey select and send up to server
        if self.selectHotkeyGroup == 1 then
            input.commands = bit.bor(input.commands, Move.Weapon1)
        elseif self.selectHotkeyGroup == 2 then
            input.commands = bit.bor(input.commands, Move.Weapon2)
        elseif self.selectHotkeyGroup == 3 then
            input.commands = bit.bor(input.commands, Move.Weapon3)
        elseif self.selectHotkeyGroup == 4 then
            input.commands = bit.bor(input.commands, Move.Weapon4)
        elseif self.selectHotkeyGroup == 5 then
            input.commands = bit.bor(input.commands, Move.Weapon5)
        end
    
        self.selectHotkeyGroup = 0
        
    end
    
    return input

end

// Called when commander is jumping to a world position (jumping to an alert, etc.)
function Commander:SetWorldScrollPosition(x, z)

    if self.heightmap then
   
        self.minimapNormX = self.heightmap:GetMapX( z )
        self.minimapNormY = self.heightmap:GetMapY( x )
        self.setScrollPosition = true
        
    end
    
end

// Called when minimap is clicked or scrolled. 0,0 is upper left, 1,1 is lower right
function Commander:SetScrollPosition(x, y)
    
    if self.heightmap then
    
        self.minimapNormX = x
        self.minimapNormY = y

        self.setScrollPosition = true
        
    end
    
end

function Commander:HotkeyGroupButtonPressed(index)
    self.hotkeyGroupButtonPressed = index
end

function Commander:SetupHud()

    Client.SetMouseVisible(true)
    Client.SetMouseCaptured(false)
    Client.SetMouseClipped(true)
    
    self.menuTechButtons = {}
    
    // Create circle for display under cursor
    self.unitUnderCursorRenderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
    local modelName = ConditionalValue(self:GetTeamType() == kAlienTeamType, Commander.kAlienCircleModelName, Commander.kMarineCircleModelName)
    self.unitUnderCursorRenderModel:SetModel(modelName)
    self.unitUnderCursorRenderModel:SetIsVisible(false)
    
    self.entityIdUnderCursor = Entity.invalidId
    
    // Create sentry orientation indicator
    self.orientationRenderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
    self.orientationRenderModel:SetModel(Commander.kSentryOrientationModelName)
    self.orientationRenderModel:SetIsVisible(false)

    self.sentryRangeRenderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
    self.sentryRangeRenderModel:SetModel(Commander.kSentryRangeModelName)
    self.sentryRangeRenderModel:SetIsVisible(false)
    
    local alertsScript = GetGUIManager():CreateGUIScriptSingle("GUICommanderAlerts")
    // Every Player already has a GUIMinimap.
    local minimapScript = GetGUIManager():GetGUIScriptSingle("GUIMinimap")
    minimapScript:SetBackgroundMode(GUIMinimap.kModeMini)

    local selectionPanelScript = GetGUIManager():CreateGUIScriptSingle("GUISelectionPanel")
    
    local buttonsScriptName = ConditionalValue(self:GetTeamType() == kAlienTeamType, "GUICommanderButtonsAliens", "GUICommanderButtonsMarines")
    self.buttonsScript = GetGUIManager():CreateGUIScript(buttonsScriptName)
    self.buttonsScript:GetBackground():AddChild(selectionPanelScript:GetBackground())
    minimapScript:SetButtonsScript(self.buttonsScript)
    
    local hotkeyIconScript = GetGUIManager():CreateGUIScriptSingle("GUIHotkeyIcons")
    local logoutScript = GetGUIManager():CreateGUIScriptSingle("GUICommanderLogout")
    GetGUIManager():CreateGUIScriptSingle("GUIResourceDisplay")
    
    minimapScript:GetBackground():AddChild(hotkeyIconScript:GetBackground())
    local managerScript = GetGUIManager():CreateGUIScriptSingle("GUICommanderManager")
    
    // The manager needs to know about other commander UI scripts for things like
    // making sure mouse clicks don't click through UI elements.
    managerScript:AddChildScript(alertsScript)
    managerScript:AddChildScript(minimapScript)
    managerScript:AddChildScript(selectionPanelScript)
    managerScript:AddChildScript(self.buttonsScript)
    managerScript:AddChildScript(hotkeyIconScript)
    managerScript:AddChildScript(logoutScript)
    
    self.hudSetup = true
    
end

function Commander:Logout()

    Client.ConsoleCommand("logout")      
        
end

function Commander:ClickSelect(x, y)
    
    local pickVec = CreatePickRay( self, x, y)
    
    if(self.controlClick) then
    
        local screenStartVec = CreatePickRay( self, 0, 0)
        local screenEndVec = CreatePickRay(self, Client.GetScreenWidth(), Client.GetScreenHeight())
        
        self:ControlClickSelectEntities(pickVec, screenStartVec, screenEndVec)
        
        self:SendControlClickSelectCommand(pickVec, screenStartVec, screenEndVec)
        
    else
    
        // Try selecting a unit
        if self:ClickSelectEntities(pickVec) then
    
            //self:SendClickSelectCommand(pickVec, 1)
            
        // If nothing, try to select a squad
        elseif self:isa("MarineCommander") then    
            
            local xScalar, yScalar = Client.GetCursorPos()
            local clickedSquadNumber = self:GetSquadBlob(Vector(xScalar, yScalar, 0))
            
            if clickedSquadNumber ~= nil then
            
                self:ClientSelectSquad(clickedSquadNumber)
                
            end
        
        end
        
    end

    self.clickStartX = x
    self.clickStartY = y
    self.clickEndX = x
    self.clickEndY = y
            
end

function Commander:SendMarqueeSelectCommand(pickStartVec, pickEndVec)

    local message = BuildMarqueeSelectCommand(pickStartVec, pickEndVec)
    Client.SendNetworkMessage("MarqueeSelect", message, true)

end

function Commander:SendClickSelectCommand(pickVec)

    local message = BuildClickSelectCommand(pickVec)
    Client.SendNetworkMessage("ClickSelect", message, true)

end

function Commander:SendSelectIdCommand(entityId)

    local message = BuildSelectIdMessage(entityId)
    Client.SendNetworkMessage("SelectId", message, true)

end
function Commander:SendControlClickSelectCommand(pickVec, screenStartVec, screenEndVec)

    local message = BuildControlClickSelectCommand(pickVec, screenStartVec, screenEndVec)
    Client.SendNetworkMessage("ControlClickSelect", message, true)

end

function Commander:SendSelectHotkeyGroupMessage(groupNumber)

    local message = BuildSelectHotkeyGroupMessage(groupNumber)
    Client.SendNetworkMessage("SelectHotkeyGroup", message, true)

end

function Commander:SendAction(techId)

    local message = BuildCommActionMessage(techId)
    Client.SendNetworkMessage("CommAction", message, true)
    
end

function Commander:SendTargetedAction(techId, normalizedPickRay, orientation)

    local orientation = ConditionalValue(orientation, orientation, math.random() * 2 * math.pi)
    local message = BuildCommTargetedActionMessage(techId, normalizedPickRay.x, normalizedPickRay.y, normalizedPickRay.z, orientation)
    Client.SendNetworkMessage("CommTargetedAction", message, true)    
    
end

function Commander:SendTargetedOrientedAction(techId, normalizedPickRay, orientation)

    local message = BuildCommTargetedActionMessage(techId, normalizedPickRay.x, normalizedPickRay.y, normalizedPickRay.z, orientation)
    Client.SendNetworkMessage("CommTargetedAction", message, true)    
    
end

function Commander:SendTargetedActionWorld(techId, worldCoords, orientation)

    local message = BuildCommTargetedActionMessage(techId, worldCoords.x, worldCoords.y, worldCoords.z, ConditionalValue(orientation, orientation, 0))
    Client.SendNetworkMessage("CommTargetedActionWorld", message, true)
    
end

function Commander:UpdateOrientationAngle(x, y)

    if(self.specifyingOrientation) then
    
        // Get screen coords from world position       
        local normalizedPickRay = CreatePickRay (self, x, y)
        local trace = GetCommanderPickTarget(self, normalizedPickRay, false, true)
        
        local vecDiff = trace.endPoint - self.specifyingOrientationPosition
        vecDiff.y = 0
        
        if vecDiff:GetLength() > 1 then
        
            local normToMouse = GetNormalizedVector(vecDiff)
            
            self.orientationRenderModel:SetCoords(BuildCoordsFromDirection(-normToMouse, self.specifyingOrientationPosition, Commander.kSentryArcScale))
            self.orientationRenderModel:SetIsVisible(true)
            
            // Only for sentries
            if self.currentTechId == kTechId.Sentry then
                self.sentryRangeRenderModel:SetCoords(BuildCoordsFromDirection(-normToMouse, self.specifyingOrientationPosition, Vector(1, 1, Sentry.kRange)))
                self.sentryRangeRenderModel:SetIsVisible(true)
            end
            
            self.orientationAngle = GetYawFromVector(normToMouse)
            
        end
        
    else
        self.orientationAngle = 0
        self.orientationRenderModel:SetIsVisible(false)
        self.sentryRangeRenderModel:SetIsVisible(false)
    end
    
end

// Only called when not running prediction
function Commander:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    if isLocal then
        
        self:UpdateMenu(deltaTime)
        
        // Update highlighted unit under cursor
        local xScalar, yScalar = Client.GetCursorPos()
        local x = xScalar * Client.GetScreenWidth()
        local y = yScalar * Client.GetScreenHeight()
        
        if self.ghostStructure == nil and not self.cursorOverUI then
            self.entityIdUnderCursor = self:GetUnitIdUnderCursor(  CreatePickRay( self, x, y) )
        else
            self.entityIdUnderCursor = Entity.invalidId
        end
        
        self:UpdateOrientationAngle(x, y)
        
        self:UpdateGhostStructureVisuals()        
        
        self:UpdateSelectionCircles()
        
        self:UpdateGhostGuides()
        
        self:UpdateCircleUnderCursor()
        
        self:UpdateCursor()

        self.lastMouseX = x
        self.lastMouseY = y
        
    end
    
end

// For debugging order-giving, selection, etc.
function Commander:DrawDebugTrace()

    if(self.lastMouseX ~= nil and self.lastMouseY ~= nil) then
    
        local trace = GetCommanderPickTarget(self, Client.CreatePickingRayXY(self.lastMouseX, self.lastMouseY))
        
        if(trace ~= nil and trace.endPoint ~= nil) then
        
            Shared.CreateEffect(self, "cinematics/debug.cinematic", nil, Coords.GetTranslation(trace.endPoint))
            
        end
        
    end
    
end

function Commander:GetCircleSizeForEntity(entity)

    local size = ConditionalValue(entity:isa("Player"),2.0, 2)
    size = ConditionalValue(entity:isa("Drifter"), 2.5, size)
    size = ConditionalValue(entity:isa("Hive"), 6.5, size)
    size = ConditionalValue(entity:isa("MAC"), 2.0, size)
    size = ConditionalValue(entity:isa("Door"), 4.0, size)
    size = ConditionalValue(entity:isa("InfantryPortal"), 3.5, size)
    size = ConditionalValue(entity:isa("Extractor"), 3.0, size)
    size = ConditionalValue(entity:isa("CommandStation"), 5.5, size)
    size = ConditionalValue(entity:isa("Egg"), 2.5, size)
    size = ConditionalValue(entity:isa("Cocoon"), 3.0, size)
    size = ConditionalValue(entity:isa("Armory"), 4.0, size)
    size = ConditionalValue(entity:isa("Harvester"), 3.7, size)
    size = ConditionalValue(entity:isa("RoboticsFactory"), 4.3, size)
    size = ConditionalValue(entity:isa("ARC"), 3.5, size)
    return size
    
end

function Commander:UpdateSelectionCircles()

    // Check self.selectionCircles because this function may be called before it is valid.
    if not Shared.GetIsRunningPrediction() and self.selectionCircles ~= nil then
        
        // Selection changed, so deleted old circles and create new ones
        if self.createSelectionCircles then
            
            self:DestroySelectionCircles()
        
            // Create new ones
            for index, entityEntry in pairs(self.selectedEntities) do
                
                local renderModelCircle = Client.CreateRenderModel(RenderScene.Zone_Default)
                renderModelCircle:SetModel(Commander.kSelectionCircleModelName)
                                
                // Insert pair into selectionCircles: {entityId, render model}
                table.insert(self.selectionCircles, {entityEntry[1], renderModelCircle})
               
                // Now create sentry arcs for any selected sentries
                local entity = Shared.GetEntity(entityEntry[1])
                if entity and entity:isa("Sentry") then
                
                    local sentryArcCircle = Client.CreateRenderModel(RenderScene.Zone_Default)
                    sentryArcCircle:SetModel(Commander.kSentryOrientationModelName)

                    local sentryRange = Client.CreateRenderModel(RenderScene.Zone_Default)
                    sentryRange:SetModel(Commander.kSentryRangeModelName)
                
                    // Insert pair into sentryArcs: {entityId, sentry arc render model, sentry range render model}
                    table.insert(self.sentryArcs, {entityEntry[1], sentryArcCircle, sentryRange})
                    
                end
 
            end
            
            self.createSelectionCircles = nil
            
        end
        
        // Update positions and scale for each
        local poseParams = PoseParams()
        
        for index, circlePair in ipairs(self.selectionCircles) do
        
            local entity = Shared.GetEntity(circlePair[1])
            if entity ~= nil then
            
                local scale = self:GetCircleSizeForEntity(entity)
                local renderModelCircle = circlePair[2]
                
                // Set position, orientation, scale (add in a littler vertical to avoid z-fighting)
                renderModelCircle:SetCoords(BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), Vector(entity:GetOrigin() + Vector(0, kZFightingConstant, 0)), scale))
                renderModelCircle:SetMaterialParameter("healthPercentage", entity:GetHealthScalar() * 100)
                local buildPercentage = 1
                if entity:isa("Structure") then
                    buildPercentage = entity:GetBuiltFraction()
                end
                renderModelCircle:SetMaterialParameter("buildPercentage", buildPercentage * 100)
                
            end
            
        end
        
        // Set size and orientation of visible sentry arcs
        for index, sentryPair in ipairs(self.sentryArcs) do
        
            local sentry = Shared.GetEntity(sentryPair[1])
            if sentry ~= nil then
            
                // Draw sentry arc at scale 1 around sentry to show cone
                local sentryArcCircle = sentryPair[2]                
                sentryArcCircle:SetCoords(BuildCoordsFromDirection(-sentry:GetCoords().zAxis, sentry:GetOrigin() + Vector(0, .05, 0), Commander.kSentryArcScale))

                // Draw line model scaled up so we can see sentry range
                local sentryLine = sentryPair[3]                
                sentryLine:SetCoords(BuildCoordsFromDirection(-sentry:GetCoords().zAxis, sentry:GetOrigin() + Vector(0, .05, 0), Vector(1, 1, Sentry.kRange)))
  
            end
            
        end
        
    end
    
end

function Commander:UpdateCircleUnderCursor()
    
    local visibility = false
    
    if self.entityIdUnderCursor ~= Entity.invalidId then
    
        local entity = Shared.GetEntity(self.entityIdUnderCursor)
        if entity ~= nil then
            
            local scale = self:GetCircleSizeForEntity(entity)
            
            // Set position, orientation, scale
            self.unitUnderCursorRenderModel:SetCoords(BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), Vector(entity:GetOrigin()), scale))
            
            visibility = true
            
        end        
        
    end
    
    self.unitUnderCursorRenderModel:SetIsVisible( visibility )

end

// Set the context-sensitive mouse cursor 
// Marine Commander default (like arrow from Starcraft 2, pointing to upper-left, MarineCommanderDefault.dds)
// Alien Commander default (like arrow from Starcraft 2, pointing to upper-left, AlienCommanderDefault.dds)
// Valid for friendly action (green "brackets" in Starcraft 2, FriendlyAction.dds)
// Valid for neutral action (yellow "brackets" in Starcraft 2, NeutralAction.dds)
// Valid for enemy action (red "brackets" in Starcraft 2, EnemyAction.dds)
// Build/target default (white crosshairs, BuildTargetDefault.dds)
// Build/target enemy (red crosshairs, BuildTargetEnemy.dds)
function Commander:UpdateCursor()

    // By default, use side-specific default cursor
    local baseCursor = ConditionalValue(self:GetTeamType() == kAlienTeamType, "AlienCommanderDefault", "MarineCommanderDefault")

    // Update highlighted unit under cursor
    local xScalar, yScalar = Client.GetCursorPos()
    local highlightSquad = -1
    
    if Client and self:isa("MarineCommander") then
    
        highlightSquad = self:GetSquadBlob(Vector(xScalar, yScalar, 0))
        
    end
    
    local entityUnderCursor = nil

    if(self.entityIdUnderCursor ~= Entity.invalidId) then
    
        entityUnderCursor = Shared.GetEntity(self.entityIdUnderCursor)
        
        if entityUnderCursor:GetTeamNumber() == self:GetTeamNumber() then
        
            baseCursor = "FriendlyAction"
            
        elseif entityUnderCursor:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber()) then
        
            baseCursor = "EnemyAction"
            
        else
        
            baseCursor = "NeutralAction"
            
        end
        
    elseif(highlightSquad >= 0) then

        baseCursor = "FriendlyAction"

    end
    
    // If we're building or in a targeted mode, use a special targeting cursor
    if self.ghostStructure ~= nil then
    
        baseCursor = "BuildTargetDefault"
    
    // Or if we're targeting an ability
    elseif self.currentTechId ~= nil and self.currentTechId ~= kTechId.None then
    
        local techNode = GetTechNode(self.currentTechId)
        
        if((techNode ~= nil) and techNode:GetRequiresTarget()) then

            baseCursor = "BuildTargetDefault"

            if entityUnderCursor and (entityUnderCursor:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber())) then
            
                baseCursor = "BuildTargetEnemy"
                
            end
            
        end
        
    end
    
    // Set the cursor if it changed
    local cursorTexture = string.format("ui/Cursor_%s.dds", baseCursor)
    if(self.cursorOverUI) then

        cursorTexture = "ui/Cursor_MenuDefault.dds"
    
    end
    if cursorTexture ~= self.lastCursorTexture then
    
        Client.SetCursor(cursorTexture)
        self.lastCursorTexture = cursorTexture
        
    end
    
end

function Commander:ClientOnMousePress(mouseButton, x, y)

    self.mouseButtonDown[mouseButton + 1] = true
    
    if self.mouseButtonUpSinceAction[mouseButton + 1] then
        
        if(mouseButton == 0) then
            
            // Only allowed when there is not a ghost structure or the structure is valid.
            if self.ghostStructure == nil then
                local techNode = GetTechNode(self.currentTechId)
                if((self.currentTechId == nil) or (techNode == nil) or not techNode:GetRequiresTarget()) then
                    // Select things near click.
                    self:ClickSelect(x, y)
                end
            end
            
        end
        
    end
    
end

function Commander:ClientOnMouseRelease(mouseButton, x, y)

    local displayConfirmationEffect = false
    
    local normalizedPickRay = CreatePickRay(self, x, y)    
    if(mouseButton == 0) then
        
        // Don't do anything if we're ghost structure is at invalid place
        if self.ghostStructure == nil or self.ghostStructureValid == true then

            // See if we have indicated an orientation for the structure yet (sentries only right now)
            if(LookupTechData(self.currentTechId, kTechDataSpecifyOrientation, false) and not self.specifyingOrientation) then
            
                // Compute world position where we will place this entity
                local trace = GetCommanderPickTarget(self, normalizedPickRay, false, true)
                VectorCopy(trace.endPoint, self.specifyingOrientationPosition)
                
                self.specifyingOrientationPickVec = Vector()
                VectorCopy(normalizedPickRay, self.specifyingOrientationPickVec)
                
                self.specifyingOrientation = true
                
                self:UpdateOrientationAngle(x, y)
                
            else
            
                // If we're in a mode, clear it and handle it
                local techNode = GetTechNode(self.currentTechId)
                if((self.currentTechId ~= nil) and (techNode ~= nil) and techNode:GetRequiresTarget()) then
            
                    local techNode = GetTechNode(self.currentTechId)
                    if(techNode ~= nil and techNode.available) then

                        local orientationAngle = ConditionalValue(self.specifyingOrientation, self.orientationAngle, NetworkRandom() * 2*math.pi)
                        if((self.currentTechId == kTechId.CommandStation) or (self.currentTechId == kTechId.Hive)) then
                            orientationAngle = 0
                        end
                                
                        if LookupTechData(self.currentTechId, kTechDataSpecifyOrientation, false) then
            
                            // Send world coords of sentry placement instead of normalized pick ray.
                            // Because the player may have moved since dropping the sentry and orienting it.
                            self:SendTargetedActionWorld(self.currentTechId, self.specifyingOrientationPosition, orientationAngle)
                            
                        else                        
                        
                            local pickVec = ConditionalValue(self.specifyingOrientation, self.specifyingOrientationPickVec, normalizedPickRay)
                            self:SendTargetedOrientedAction(self.currentTechId, pickVec, orientationAngle)
                            
                        end
 
                        self:SetCurrentTech(kTechId.None)
                        
                        displayConfirmationEffect = true

                    end
                    
                    self.specifyingOrientation = false
                    
                end
                
                // Clear mode after executed
                self.currentTechId = kTechId.None
                self.specifyingOrientation = false
                
            end
            
        end
        
    // right-click order
    elseif(mouseButton == 1) then
       
        if self.ghostStructure ~= nil then
            player:SetCurrentTech(kTechId.None)
        else
            self:SendTargetedAction(kTechId.Default, normalizedPickRay)
            displayConfirmationEffect = true
        end
       
    end
    
    if displayConfirmationEffect then
    
        local trace = GetCommanderPickTarget(self, normalizedPickRay)
        local effectName = self:GetOrderConfirmedEffect()
        if effectName ~= "" then
            Shared.CreateEffect(nil, effectName, nil, Coords.GetTranslation(trace.endPoint))
        end
        
    end
    
    self.mouseButtonDown[mouseButton + 1] = false
    self.mouseButtonUpSinceAction[mouseButton + 1] = true
    
end

function Commander:GetMouseButtonDown(mouseButton)
    return self.mouseButtonDown[mouseButton + 1]
end

function Commander:SelectMarquee(selectStartX, selectStartY, selectEndX, selectEndY)
   
    // Create normalized coords which can be used on client and server
    local pickStartVec = CreatePickRay(self, selectStartX, selectStartY)
    local pickEndVec  = CreatePickRay(self, selectEndX, selectEndY)

    // Process selection locally
    self:MarqueeSelectEntities(pickStartVec, pickEndVec)
    
    // Send selection command to server
    self:SendMarqueeSelectCommand(pickStartVec, pickEndVec)
    
    self.clickStartX = selectStartX*Client.GetScreenWidth()
    self.clickStartY = selectStartY*Client.GetScreenHeight()
    self.clickEndX = selectEndX*Client.GetScreenWidth()
    self.clickEndY = selectEndY*Client.GetScreenHeight()

end

function Commander:SetCurrentTech(techId)
    
    // Change menu if it is a menu
    local techNode = GetTechNode(techId)
    
    if(techNode ~= nil and techNode:GetIsMenu()) then
    
        self.menuTechId = techId
        
    end
    
    if techNode and not techNode:GetRequiresTarget() and not techNode:GetIsBuy() and not techNode:GetIsEnergyBuild() then
        
        // Send action up to server. Necessary for even menu changes as 
        // server validates all actions.
        self:SendAction(techId)
        
    end 
   
    // Remember this techId, which we need during ClientOnMouseRelease()
    self.currentTechId = techId
    
    self.specifyingOrientation = false
    
    self:CreateGhostStructure(techId)
    
end

function Commander:TriggerButtonIndex(index, isAlien)
    // $AS - HACKS: So Aliens do not really have this concept of tabs
    // like marines do and so using the tab behavior really messes them up
    // for now until we refactor this code a little better I have put in this
    // horrible hack to make it all work!!! 
    if isAlien then
        self.menuTechId =  kTechId.RootMenu
        self:UpdateSharedTechButtons()
        self:ComputeMenuTechAvailability()
    else
        local commButtons = self.buttonsScript
        if CommanderUI_MenuButtonRequiresTarget(index) and commButtons then
            commButtons:SetTargetedButton(index)
        end
    
        CommanderUI_MenuButtonAction(index)
    
        if commButtons then    
            commButtons:SelectTab(index)    
        end
    end
end