// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handles Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Player.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/Mixins/CommanderMoveMixin.lua")

class 'Commander' (Player)
Commander.kMapName = "commander"

Script.Load("lua/Commander_Hotkeys.lua")

Commander.kSpendTeamResourcesSoundName = PrecacheAsset("sound/ns2.fev/marine/common/comm_spend_metal")
Commander.kSpendResourcesSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")

Commander.kSelectionCircleModelName = PrecacheAsset("models/misc/marine-build/marine-build.model")
Commander.kSentryOrientationModelName = PrecacheAsset("models/misc/sentry_arc/sentry_arc.model")
Commander.kSentryRangeModelName = PrecacheAsset("models/misc/sentry_arc/sentry_line.model")
Commander.kMarineCircleModelName = PrecacheAsset("models/misc/circle/circle.model")
Commander.kAlienCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")

Commander.kSentryArcScale = 8

// Extra hard-coded vertical distance that makes it so we set our scroll position,
// we are looking at that point, instead of setting our position to that point)
Commander.kViewOffsetXHeight = 5
// Default height above the ground when there's no height map
Commander.kDefaultCommanderHeight = 11
Commander.kFov = 90
Commander.kScoreBoardDisplayDelay = .12

// Snap structures to attach points within this range
Commander.kAttachStructuresRadius = 5

Commander.kScrollVelocity = 40

// Snap structures within this range to attach points.
Commander.kStructureSnapRadius = 4

Script.Load("lua/Commander_Selection.lua")

if (Server) then
    Script.Load("lua/Commander_Server.lua")
else
    Script.Load("lua/Commander_Client.lua")
end

Commander.kMaxSubGroupIndex = 32

Commander.kSelectMode = enum( {'None', 'SelectedGroup', 'JumpedToGroup'} )

Commander.networkVars = 
{
    timeScoreboardPressed   = "float",
    focusGroupIndex         = string.format("integer (1 to %d)", Commander.kMaxSubGroupIndex),
    numIdleWorkers          = string.format("integer (0 to %d)", kMaxIdleWorkers),
    numPlayerAlerts         = string.format("integer (0 to %d)", kMaxPlayerAlerts),
    commanderCancel         = "boolean",
    commandStationId        = "entityid",
    // Set to a number after a hotgroup is selected, so we know to jump to it next time we try to select it
    positionBeforeJump      = "vector",
    gotoHotKeyGroup         = string.format("integer (0 to %d)", Player.kMaxHotkeyGroups)
}

PrepareClassForMixin(Commander, CameraHolderMixin)
PrepareClassForMixin(Commander, CommanderMoveMixin)

function Commander:OnInit()

    InitMixin(self, CameraHolderMixin, { kFov = Commander.kFov })
    // CommanderMoveMixin requires the GetViewAngles() function that CameraHolderMixin provides.
    InitMixin(self, CommanderMoveMixin, { kGravity = 0, kScrollVelocity = Commander.kScrollVelocity,
                                          kDefaultHeight = Commander.kDefaultCommanderHeight,
                                          kViewOffsetXHeight = Commander.kViewOffsetXHeight })
    
    InitMixin(self, BuildingMixin)
    
    Player.OnInit(self)

    self.selectedEntities = {}
    
    self.selectedSubGroupEntityIds = {}

    self:SetIsVisible(false)
    
    self:SetDefaultSelection()
    
    if(Client) then

        self.drawResearch = false
        
        // Remember which buttons are down.
        self.mouseButtonDown = {false, false, false}
        // Start off assuming all buttons are up.
        self.mouseButtonUpSinceAction = {true, true, true}
        
        self.specifyingOrientation = false
        self.orientationAngle = 0
        self.specifyingOrientationPosition = Vector(0, 0, 0)
        
        self.scrollX = 0
        self.scrollY = 0       
        
        self.ghostStructure = nil
        self.ghostStructureValid = false
        
        self.currentTechId = kTechId.None
                
    end
    
    if(Server) then
    
        // Wait a short time before sending hotkey groups to make sure
        // client has been replaced by commander
        self.timeToSendHotkeyGroups = Shared.GetTime() + .5
        
        self.alerts = {}
        
    end

    self.timeScoreboardPressed = 0
    self.focusGroupIndex = 1
    self.numIdleWorkers = 0
    self.numPlayerAlerts = 0
    self.positionBeforeJump = Vector(0, 0, 0)
    self.selectMode = Commander.kSelectMode.None
    self.commandStationId = Entity.invalidId
    
    self:SetUpdateWeapons(false)
    
end

// Needed so player origin is same as camera for selection
function Commander:GetViewOffset()
    return Vector(0, 0, 0)
end

function Commander:GetMaxViewOffsetHeight()
    return 0
end

function Commander:GetTeamType()
    return kNeutralTeamType
end

function Commander:HandleButtons(input)
  
    PROFILE("Commander:HandleButtons")
    
    // Set Commander orientation to looking down but not straight down for visual interest
    local yawDegrees    = 90
    local pitchDegrees  = 70
    local angles        = Angles((pitchDegrees/90)*math.pi/2, (yawDegrees/90)*math.pi/2, 0)   
    
    // Update to the current view angles.
    self:SetViewAngles(angles)
    
    // Update shift order drawing/queueing
    self.queuingOrders = (bit.band(input.commands, Move.MovementModifier) ~= 0)
    self.controlClick = (bit.band(input.commands, Move.Crouch) ~= 0)
    
    // Check for commander cancel action. It is reset in the flash hook to make 
    // sure it's recognized.
    if(bit.band(input.commands, Move.Exit) ~= 0) then
        // TODO: If we have nothing to cancel, bring up menu
        //ShowInGameMenu()
        self.commanderCancel = true
    end

    if Client and not Shared.GetIsRunningPrediction() then    
    
        self:HandleCommanderESC(input)
        self:HandleCommanderHotkeys(input)
        
    end
    
    if Client then
        self:ShowMap(bit.band(input.commands, Move.ShowMap) ~= 0)
    end
    
end

// Don't show scoreboard right away, also use tab to handle sub-group selection through UI cleverness
function Commander:UpdateScoreboard(input)

    // If player holds scoreboard key (tab), show scores. If they tap it, switch
    // focus to next sub-group within selection
    if (bit.band(input.commands, Move.Scoreboard) ~= 0) then
    
        if self.timeScoreboardPressed == 0 then
            self.timeScoreboardPressed = Shared.GetTime()
        end
        
        if Shared.GetTime() > (self.timeScoreboardPressed + Commander.kScoreBoardDisplayDelay) then
            self.showScoreboard = true
        end
    
    else
    
        // If we're showing scoreboard, hide it
        if self.showScoreboard then
        
            self.showScoreboard = false

        elseif self.timeScoreboardPressed ~= 0 then
        
            // else switch to next sub group
            self.focusGroupIndex = ( self.focusGroupIndex + 1 ) % Commander.kMaxSubGroupIndex
            
        end
        
        self.timeScoreboardPressed = 0
        
    end

end

function Commander:UpdateCrouch()
end

function Commander:UpdateViewAngles()
end

// Move commander without any collision detection
function Commander:UpdatePosition(velocity, time)

    PROFILE("Commander:UpdatePosition")

    local offset = velocity * time
    
    if self.controller then
    
        self:UpdateControllerFromEntity()
        
        self.controller:SetPosition(self:GetOrigin() + offset)

        self:UpdateOriginFromController()

    end    

    return velocity
    
end

function Commander:UpdateAnimation(timePassed)
end

function Commander:GetNumIdleWorkers()
    return self.numIdleWorkers
end

function Commander:GetNumPlayerAlerts()
    return self.numPlayerAlerts
end

function Commander:UpdateMisc(input)

    PROFILE("Commander:UpdateMisc")

    if Server then
        self:UpdateNumIdleWorkers()
        self:UpdateAlerts()
    end
    
    if Client then
        self:UpdateChat(input)
    end
    
end

// Returns true if it set our position
function Commander:ProcessNumberKeysMove(input, newPosition)

    local setPosition = false
    local number = 0
    
    if (bit.band(input.commands, Move.Weapon1) ~= 0) then
        number = 1
    elseif (bit.band(input.commands, Move.Weapon2) ~= 0) then
        number = 2
    elseif (bit.band(input.commands, Move.Weapon3) ~= 0) then
        number = 3
    elseif (bit.band(input.commands, Move.Weapon4) ~= 0) then
        number = 4
    elseif (bit.band(input.commands, Move.Weapon5) ~= 0) then
        number = 5
    end
    
    if (number ~= 0) then
    
        if (bit.band(input.commands, Move.Crouch) ~= 0) then
        
            if Server then
                self:CreateHotkeyGroup(number)
            end
            
        // Make sure we're not selecting a squad
        elseif (bit.band(input.commands, Move.MovementModifier) == 0) then
        
            setPosition = self:ProcessHotkeyGroup(number, newPosition)
        
        end
        
    end
    
    return setPosition
    
end

// Assumes number non-zero
function Commander:ProcessHotkeyGroup(number, newPosition)

    local setPosition = false
    
    if (self.gotoHotKeyGroup == 0) or (number ~= self.gotoHotKeyGroup) then
    
        // Select hotgroup        
        self:SelectHotkeyGroup(number)        
        self.positionBeforeJump = Vector(self:GetOrigin())
        self.gotoHotKeyGroup = number
        
    else
    
        // Jump to hotgroup if we're selecting same one and not nearby
        if self.gotoHotKeyGroup == number then
        
            setPosition = self:GotoHotkeyGroup(number, newPosition)
            
        end
        
    end

    return setPosition
    
end

function Commander:GetIsCommander()
    return true
end

function Commander:GetOrderConfirmedEffect()
    return ""
end

/**
 * Returns the x-coordinate of the commander current position in the minimap.
 */
function Commander:GetScrollPositionX()
    local scrollPositionX = 1
    local heightmap = self:GetHeightmap()
    if(heightmap ~= nil) then
        scrollPositionX = heightmap:GetMapX( self:GetOrigin().z )
    end
    return scrollPositionX
end

/**
 * Returns the y-coordinate of the commander current position in the minimap.
 */
function Commander:GetScrollPositionY()
    local scrollPositionY = 1
    local heightmap = self:GetHeightmap()
    if(heightmap ~= nil) then
        scrollPositionY = heightmap:GetMapY( self:GetOrigin().x + Commander.kViewOffsetXHeight )
    end
    return scrollPositionY
end

// For making top row the same. Marine commander overrides to set top four icons to always be identical.
function Commander:GetTopRowTechButtons()
    return {}
end

function Commander:GetSelectionRowsTechButtons(menuTechId)
    return {}
end

function Commander:GetCurrentTechButtons(techId, entity)

    local techButtons = {}

    local topRowTechButtons = self:GetTopRowTechButtons()
    if topRowTechButtons then
        table.copy(topRowTechButtons, techButtons, true)
    end
    
    local selectedTechButtons = nil
    if entity then
        selectedTechButtons = entity:GetTechButtons(techId, self:GetTeamType())
    end
    if not selectedTechButtons then
        selectedTechButtons = self:GetSelectionRowsTechButtons(techId)
    end
    
    if selectedTechButtons then
        table.copy(selectedTechButtons, techButtons, true)
    end
    
    return techButtons

end

// Updates hotkeys to account for entity changes. Pass both parameters to indicate
// that an entity has changed (ie, a player has changed class), or pass nil
// for newEntityId to indicate an entity has been destroyed.
function Commander:OnEntityChange(oldEntityId, newEntityId)
    
    // Replace old object with new one if selected
    local newSelection = {}
    table.copy(self.selectedEntities, newSelection)
    
    local selectionChanged = false
    for index, pair in ipairs(newSelection) do

        if pair[1] == oldEntityId then
        
            if newEntityId then
                pair[1] = newEntityId
            else
                table.remove(newSelection, index)                
            end  
            
            selectionChanged = true
            
        end
        
    end
    
    if selectionChanged then
        self:InternalSetSelection(newSelection, true)
    end
    
    // Hotkey groups are handled in player.
    Player.OnEntityChange(self, oldEntityId, newEntityId)
   
end

function Commander:GetIsEntityNameSelected(className)

    for tableIndex, entityPair in ipairs(self.selectedEntities) do
    
        local entityIndex = entityPair[1]
        local entity = Shared.GetEntity(entityIndex)
        
        // Don't allow it to be researched while researching
        if( entity ~= nil and entity:isa(className) ) then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Commander:OnUpdate(deltaTime)

    Player.OnUpdate(self, deltaTime)

    // Remove selected units that are no longer valid for selection
    self:UpdateSelection(deltaTime)
    
    if Server then
    
        self:UpdateHotkeyGroups()
      
    end
        
end

// Draw waypoint of selected unit as our own as quick ability for commander to see results of orders
function Commander:GetVisibleWaypoint()

    if self.selectedEntities and table.count(self.selectedEntities) > 0 then
    
        local ent = Shared.GetEntity(self.selectedEntities[1][1])
        
        if ent and ent:isa("Player") then
        
            return ent:GetVisibleWaypoint()
            
        end
        
    end
    
    return Player.GetVisibleWaypoint(self)
    
end

function Commander:GetHostCommandStructure()
    return Shared.GetEntity(self.commandStationId)
end

function Commander:GetCanDoDamage()
    return false
end

function Commander:OverrideCheckvision()
  return false
end

Shared.LinkClassToMap( "Commander", Commander.kMapName, Commander.networkVars )
