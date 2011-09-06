// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Player coordinates - z is forward, x is to the left, y is up.
// The origin of the player is at their feet.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Globals.lua")
Script.Load("lua/TechData.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/TooltipMixin.lua")
Script.Load("lua/WeaponOwnerMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/mixins/ControllerMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FuryMixin.lua")
Script.Load("lua/FrenzyMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/TargetMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/HiveSightBlipMixin.lua")

/**
 * Player should not be instantiated directly. Only instantiate a Player through
 * one of the derived types.
 */
class 'Player' (ScriptActor)

Player.kTooltipSound    = PrecacheAsset("sound/ns2.fev/common/tooltip")
Player.kToolTipInterval = 18

if (Server) then
    Script.Load("lua/Player_Server.lua")
else
    Script.Load("lua/Player_Client.lua")
    Script.Load("lua/Chat.lua")
end

Player.kMapName = "player"

Player.kModelName                   = PrecacheAsset("models/marine/male/male.model")
Player.kSpecialModelName            = PrecacheAsset("models/marine/male/male_special.model")
Player.kClientConnectSoundName      = PrecacheAsset("sound/ns2.fev/common/connect")
Player.kNotEnoughResourcesSound     = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/more")
Player.kInvalidSound                = PrecacheAsset("sound/ns2.fev/common/invalid")
Player.kChatSound                   = PrecacheAsset("sound/ns2.fev/common/chat")

// Animations
Player.kAnimRun = "run"
Player.kAnimTaunt = "taunt"
Player.kAnimStartJump = "jumpin"
Player.kAnimEndJump = "jumpout"
Player.kAnimJump = "jump"
Player.kAnimReload = "reload"
Player.kRunIdleSpeed = 1

Player.kLoginBreakingDistance = 150
Player.kUseRange  = 1.6
Player.kDownwardUseRange = 2.2
Player.kUseHolsterTime = .5
Player.kDefaultBuildTime = .2
    
Player.kGravity = -24
Player.kMass = 90.7 // ~200 pounds (incl. armor, weapons)
Player.kWalkBackwardSpeedScalar = 0.4
Player.kJumpHeight =  1
Player.kOnGroundDistance = 0.05

// The physics shapes used for player collision have a "skin" that makes them appear to float, this makes the shape
// smaller so they don't appear to float anymore
Player.kSkinCompensation = 0.9
Player.kXZExtents = 0.35
Player.kYExtents = .95
Player.kViewOffsetHeight = Player.kYExtents * 2 - .28 // Eyes a bit below the top of the head. NS1 marine was 64" tall.
Player.kFov = 90

// Percentage change in height when full crouched
Player.kCrouchShrinkAmount = .5
// Slow down players when crouching
Player.kCrouchSpeedScalar = .5
// How long does it take to crouch or uncrouch
Player.kCrouchAnimationTime = .25

Player.kMinVelocityForGravity = .5
Player.kThinkInterval = .2
Player.kMinimumPlayerVelocity = .05    // Minimum player velocity for network performance and ease of debugging

// Player speeds
Player.kWalkMaxSpeed = 5                // Four miles an hour = 6,437 meters/hour = 1.8 meters/second (increase for FPS tastes)
Player.kMaxWalkableNormal =  math.cos( math.rad(45) )

Player.kAcceleration = 40
Player.kRunAcceleration = 100
Player.kLadderAcceleration = 50

// Out of breath
Player.kTimeToLoseBreath = 10
Player.kTimeToGainBreath = 20

Player.kTauntMovementScalar = .05           // Players can only move a little while taunting

Player.kDamageIndicatorDrawTime = 1

// The slowest scalar of our max speed we can go to because of jumping
Player.kMinSlowSpeedScalar = .3

// kMaxHotkeyGroups is defined at a global level so that NetworkMessages.lua can access the constant.
Player.kMaxHotkeyGroups = kMaxHotkeyGroups

Player.kUnstickDistance = .1
Player.kUnstickOffsets = { 
    Vector(0, Player.kUnstickDistance, 0), 
    Vector(Player.kUnstickDistance, 0, 0), 
    Vector(-Player.kUnstickDistance, 0, 0), 
    Vector(0, 0, Player.kUnstickDistance), 
    Vector(0, 0, -Player.kUnstickDistance)
}

Player.stepTotalTime    = 0.1   // Total amount of time to interpolate up a step

// Assumes the "ups" are listed in order after the "downs"
Player.kTapMode = enum( {'None', 'LeftDown', 'LeftUp', 'RightDown', 'RightUp', 'ForwardDown', 'ForwardUp', 'BackDown', 'BackUp'} )

// When changing these, make sure to update Player:CopyPlayerDataFrom. Any data which 
// needs to survive between player class changes needs to go in here.
// Compensated variables are things that you want reverted when processing commands
// so basically things that are important for defining whether or not something can be shot
// for the player this is anything that can affect the hit boxes, like the animation that's playing,
// the current animation time, pose parameters, etc (not for the player firing but for the
// player being shot). 
Player.networkVars =
{
    
    // Controlling client index. -1 for not being controlled by a live player (ragdoll, fake player)
    clientIndex             = "integer",
    
    // 0 means no active weapon, 1 means first child weapon, etc.
    activeWeaponIndex       = "integer (0 to 10)",
    activeWeaponHolstered   = "boolean",

    viewModelId             = "entityid",

    resources               = "float",
    teamResources           = "float",
    gameStarted             = "boolean",
    countingDown            = "boolean",
    frozen                  = "boolean",       
    
    timeOfDeath             = "float",
    timeOfLastUse           = "float",
   
    timeOfLastWeaponSwitch  = "float",
    crouching               = "compensated boolean",
    timeOfCrouchChange      = "compensated float",
    
    flareStartTime          = "float",
    flareStopTime           = "float",
    flareScalar             = "float",
    
    desiredPitch            = "float",
    desiredRoll             = "float",

    showScoreboard          = "boolean",
    sayingsMenu             = "integer (0 to 6)",
    timeLastMenu            = "float",
    darwinMode              = "boolean",
    
    // True if target under reticle can be damaged
    reticleTarget           = "boolean",
    
    // Time we last did damage to a target
    timeTargetHit           = "float",
       
    // Set to true when jump key has been released after jump processed
    // Used to require the key to pressed multiple times
    jumpHandled             = "boolean",
    timeOfLastJump          = "float",
    onGround                = "boolean",
    onGroundNeedsUpdate     = "boolean",
    
    onLadder                = "boolean",
    
    // Player-specific mode. When set to kPlayerMode.Default, player moves and acts normally, otherwise
    // he doesn't take player input. Change mode and set modeTime to the game time that the mode
    // ends. ProcessEndMode() will be called when the mode ends. Return true from that to process
    // that mode change, otherwise it will go back to kPlayerMode.Default. Used for things like taunting,
    // building structures and other player actions that take time while the player is stationary.
    mode                    = "enum kPlayerMode",
    
    // Time when mode will end. Set to -1 to have it never end.
    modeTime                = "float",
    
    primaryAttackLastFrame      = "boolean",
    secondaryAttackLastFrame    = "boolean",
    // Indicates how active the player has been
    outOfBreath             = "integer (0 to 255)",
    
    // The next point in the world to go to in order to reach an order target location
    nextOrderWaypoint       = "vector",
    
    // The final point in the world to go to in order to reach an order target location
    finalWaypoint           = "vector",
    
    // Whether this entity has a next order waypoint
    nextOrderWaypointActive = "boolean",
    
    // Move, Build, etc.
    waypointType            = "enum kTechId",
    
    fallReadyForPlay        = "integer (0 to 3)",
    
    // Used to smooth out the eye movement when going up steps.
    stepStartTime           = "float",
    stepAmount              = "float",
    
    isUsing                 = "boolean",
    
    // Reduce max player velocity in some cases (marine jumping)
    slowAmount              = "float",
    
    // For double-tapping moves
    tapMode                 = "enum Player.kTapMode",
    tapModeTime             = "float",
}

PrepareClassForMixin(Player, ControllerMixin)
PrepareClassForMixin(Player, LiveMixin)
PrepareClassForMixin(Player, UpgradableMixin)
PrepareClassForMixin(Player, GameEffectsMixin)
PrepareClassForMixin(Player, FuryMixin)
PrepareClassForMixin(Player, FlinchMixin)
PrepareClassForMixin(Player, OrdersMixin)
PrepareClassForMixin(Player, FireMixin)

function Player:OnCreate()
    
    ScriptActor.OnCreate(self)
    
    InitMixin(self, ControllerMixin)
    InitMixin(self, TooltipMixin, { kTooltipSound = Player.kTooltipSound, kToolTipInterval = Player.kToolTipInterval })
    InitMixin(self, WeaponOwnerMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FuryMixin)
    InitMixin(self, FrenzyMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, OrdersMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, SelectableMixin)
    if Server then
        InitMixin(self, TargetMixin)
        InitMixin(self, LOSMixin)
        InitMixin(self, HiveSightBlipMixin)
    end
    
    self:SetLagCompensated(true)
    
    self:SetUpdates(true)
    
    if (Server) then
        self.name = ""
    end

    self.maxExtents     = Vector( LookupTechData(self:GetTechId(), kTechDataMaxExtents, Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents)) )
    self.viewOffset     = Vector( 0, 0, 0 )

    self.clientIndex = -1
    self.client = nil

    self.activeWeaponIndex = 0
    self.activeWeaponHolstered = false
   
    self.overlayAnimationName = ""
   
    self.showScoreboard = false
    
    if Server then
        self.sendTechTreeBase = false
    end
    
    if Client then
        self.showSayings = false
    end
    
    self.sayingsMenu = 0
    self.timeLastMenu = 0    
    self.darwinMode = false
    self.timeLastSayingsAction = 0
    self.reticleTarget = false
    self.timeTargetHit = 0
    self.kills = 0
    self.deaths = 0
    
    self.jumpHandled = false
    self.leftFoot = true
    self.mode = kPlayerMode.Default
    self.modeTime = -1
    self.primaryAttackLastFrame = false
    self.secondaryAttackLastFrame = false
    self.outOfBreath = 0
    
    self.requestsScores = false   
    self.viewModelId = Entity.invalidId
    
    self.usingStructure = nil
    self.timeOfLastUse  = 0
    self.timeOfLastWeaponSwitch = nil
    self.respawnQueueEntryTime = nil

    self.timeOfDeath = nil
    self.crouching = false
    self.timeOfCrouchChange = 0
    self.onGroundNeedsUpdate = true
    self.onGround = false
    
    self.onLadder = false
    
    self.timeLastOnGround = 0
    
    self.fallReadyForPlay = 0

    self.flareStartTime = 0
    self.flareStopTime = 0
    self.flareScalar = 1
    self.resources = 0
    
    self.stepStartTime = 0
    self.stepAmount    = 0
            
    // Create the controller for doing collision detection.
    // Just use default values for the capsule size for now. Player will update to correct
    // values when they are known.
    self:CreateController(PhysicsGroup.PlayerControllersGroup)

    // Make the player kinematic so that bullets and other things collide with it.
    self:SetPhysicsGroup(PhysicsGroup.PlayerGroup)
    
    self.nextOrderWaypoint = nil
    self.finalWaypoint = nil
    self.nextOrderWaypointActive = false
    self.waypointType = kTechId.None
    
    self.isUsing = false
    self.slowAmount = 0

    self.tapMode = Player.kTapMode.None
    self.tapModeTime = nil
    
end

function Player:OnInit()

    ScriptActor.OnInit(self)
    
    // Only give weapons when playing
    if Server and self:GetTeamNumber() ~= kNeutralTeamType then
           
        self:InitWeapons()
        
    end

    // Set true on creation 
    if Server then
        self:SetName(kDefaultPlayerName)
    end
    self:SetScoreboardChanged(true)
    
    self:SetViewOffsetHeight(self:GetMaxViewOffsetHeight())
    
    self:UpdateControllerFromEntity()
        
    self:TriggerEffects("idle")
        
    if Server then
        self:SetNextThink(Player.kThinkInterval)
    end
    
    // Initialize hotkey groups. This is in player because
    // it needs to be preserved across player replacements.
    
    // Table of table of ids, in order of hotkey groups
    self:InitializeHotkeyGroups()
    
    self:LoadHeightmap()
    
end

function Player:InitializeHotkeyGroups()

    self.hotkeyGroups = {}
    
    for i = 1, Player.kMaxHotkeyGroups do
        table.insert(self.hotkeyGroups, {})
    end

end

function Player:OnEntityChange(oldEntityId, newEntityId)

    ScriptActor.OnEntityChange(self, oldEntityId, newEntityId)
    
    if Server and self.hotkeyGroups then

        // Loop through hotgroups and update accordingly
        for i = 1, Player.kMaxHotkeyGroups do
        
            for index, entityId in ipairs(self.hotkeyGroups[i]) do
            
                if(entityId == oldEntityId) then
                
                    if(newEntityId ~= nil) then
                    
                        self.hotkeyGroups[i][index] = newEntityId
                        
                    else
                    
                        table.remove(self.hotkeyGroups[i], index)
                        
                    end
                    
                    if self.SendHotkeyGroup ~= nil then
                        self:SendHotkeyGroup(i)
                    end
                    
                end
                
            end
            
        end

    end

    if Client then

        if self:GetId() == oldEntityId then
            // If this player is changing is any way, just assume the
            // buy/evolve menu needs to close.
            self:CloseMenu(kClassFlashIndex)
        end

    end

end

/**
 * Returns text describing the current status of the Player. Returns nil
 * as the second parameter as this is used as a progress indicator for
 * some entities (the Player doesn't have any progress to report on).
 */
function Player:GetStatusDescription()
    return string.format("%s - %s", self:GetName(), self:GetClassName()), nil
end

// Special unique client-identifier 
function Player:GetClientIndex()
    return self.clientIndex
end

function Player:_CheckInputInversion(input)

    // Invert mouse if specified in options.
    local invertMouse = Client.GetOptionBoolean(kInvertedMouseOptionsKey, false)
    if invertMouse then
        input.pitch = -input.pitch
    end

end

function Player:OverrideInput(input)

    self:_CheckInputInversion(input)
    
    local maxPitch = Math.Radians(89.9)
    input.pitch = Math.Clamp(input.pitch, -maxPitch, maxPitch)
    
    if self.timeClosedMenu and (Shared.GetTime() < self.timeClosedMenu + .25) then
    
        // Don't allow weapon firing
        local removePrimaryAttackMask = bit.bxor(0xFFFFFFFF, Move.PrimaryAttack)
        input.commands = bit.band(input.commands, removePrimaryAttackMask)
        
    end
    
    if self.frozen then
        // Don't allow secondary attack while frozen to prevent skulks from jumping around.
        local removeSecondaryAttackMask = bit.bxor(0xFFFFFFFF, Move.SecondaryAttack)
        input.commands = bit.band(input.commands, removeSecondaryAttackMask)
    end
    
    self:OverrideSayingsMenu(input)
    
    return input
    
end

function Player:OverrideSayingsMenu(input)

    if(self:GetHasSayings() and ( bit.band(input.commands, Move.ToggleSayings1) ~= 0 or bit.band(input.commands, Move.ToggleSayings2) ~= 0 or bit.band(input.commands, Move.ToggleVoteMenu) ~= 0 ) ) then
    
        // If enough time has passed
        if(self.timeLastSayingsAction == nil or (Shared.GetTime() > self.timeLastSayingsAction + .2)) then

            local newMenu = 1
            if bit.band(input.commands, Move.ToggleSayings2) ~= 0 then
                newMenu = ConditionalValue(self:isa("Alien"), 1, 2)
            elseif bit.band(input.commands, Move.ToggleVoteMenu) ~= 0 then
                newMenu = ConditionalValue(self:isa("Alien"), 2, 3)
            end

            // If not visible, bring up menu
            if(not self.showSayings) then
            
                self.showSayings = true
                self.showSayingsMenu = newMenu
                
            // else if same menu and visible, hide it
            elseif(newMenu == self.showSayingsMenu) then
            
                self.showSayings = false
                self.showSayingsMenu = nil                
            
            // If different, change menu without showing or hiding
            elseif(newMenu ~= self.showSayingsMenu) then
            
                self.showSayingsMenu = newMenu
                
            end
            
        end
        
        // Sayings toggles are handled client side.
        local removeToggleMenuMask = bit.bxor(0xFFFFFFFF, Move.ToggleSayings1)
        input.commands = bit.band(input.commands, removeToggleMenuMask)
        removeToggleMenuMask = bit.bxor(0xFFFFFFFF, Move.ToggleSayings2)
        input.commands = bit.band(input.commands, removeToggleMenuMask)
        removeToggleMenuMask = bit.bxor(0xFFFFFFFF, Move.ToggleVoteMenu)
        input.commands = bit.band(input.commands, removeToggleMenuMask)

        // Record time
        self.timeLastSayingsAction = Shared.GetTime()
        
    end
    
    // Intercept any execute sayings commands.
    if self.showSayings then
        local weaponSwitchCommands = { Move.Weapon1, Move.Weapon2, Move.Weapon3, Move.Weapon4, Move.Weapon5 }
        for i, weaponSwitchCommand in ipairs(weaponSwitchCommands) do
            if bit.band(input.commands, weaponSwitchCommand) ~= 0 then
                // Tell the server to execute this saying.
                local message = BuildExecuteSayingMessage(i, self.showSayingsMenu)
                Client.SendNetworkMessage("ExecuteSaying", message, true)
                local removeWeaponMask = bit.bxor(0xFFFFFFFF, weaponSwitchCommand)
                input.commands = bit.band(input.commands, removeWeaponMask)
                self.showSayings = false
            end
        end
    end

end

function Player:GetIsFirstPerson()
    return (Client and (Client.GetLocalPlayer() == self) and not self:GetIsThirdPerson())
end

/**
 * Returns the current view offset based on crouch.
 * Also specifies listener position.
 */
function Player:GetViewOffset()
    return self.viewOffset
end

/**
 * Returns the view offset with the step smoothing factored in.
 */
function Player:GetSmoothedViewOffset()

    local deltaTime = Shared.GetTime() - self.stepStartTime
    
    if deltaTime < Player.stepTotalTime then
        return self.viewOffset + Vector( 0, -self.stepAmount * (1 - deltaTime / Player.stepTotalTime), 0 )
    end
    
    return self.viewOffset
    
end

/**
 * Stores the player's current view offset. Calculated from GetMaxViewOffset() and crouch state.
 */
function Player:SetViewOffsetHeight(newViewOffsetHeight)
    self.viewOffset.y = newViewOffsetHeight
end

function Player:GetMaxViewOffsetHeight()
    return Player.kViewOffsetHeight
end

function Player:GetCanViewModelIdle()
    local activeWeaponCanIdle = true
    if self:GetActiveWeapon() then
        activeWeaponCanIdle = self:GetActiveWeapon():GetCanIdle()
    end
    return self:GetIsAlive() and self:GetCanNewActivityStart() and (self.mode == kPlayerMode.Default) and activeWeaponCanIdle
end

function Player:LoadHeightmap()

    // Load height map
    self.heightmap = HeightMap()   
    local heightmapFilename = string.format("maps/overviews/%s.hmp", Shared.GetMapName())
    
    if(not self.heightmap:Load(heightmapFilename)) then
        Shared.Message("Couldn't load height map " .. heightmapFilename)
        self.heightmap = nil
    end

end

function Player:GetHeightmap()
    return self.heightmap
end

// worldX => -map y
// worldZ => +map x
function Player:GetMapXY(worldX, worldZ)

    local success = false
    local mapX = 0
    local mapY = 0

    if self.heightmap then
        mapX = self.heightmap:GetMapX(worldZ)
        mapY = self.heightmap:GetMapY(worldX)
    else
        Print("Player:GetMapXY(): heightmap is nil")
        return false, 0, 0
    end

    if mapX >= 0 and mapX <= 1 and mapY >= 0 and mapY <= 1 then
        success = true
    end

    return success, mapX, mapY

end

// Return modifier to our max speed (1 is none, 0 is full)
function Player:GetSlowSpeedModifier()

    // Never drop to 0 speed
    return 1 - (1 - Player.kMinSlowSpeedScalar) * self.slowAmount
    
end

// Plays view model animation, given a string or a table of weighted entries.
// Returns length of animation or 0 if animation wasn't found. 
function Player:SetViewAnimation(animName, noForce, blend, speed)

    local length = 0.0
    
    if not speed then
        speed = 1
    end
    
    if (animName ~= nil and animName ~= "") then
    
        local viewModel = self:GetViewModelEntity()
        if (viewModel ~= nil) then

            local force = not noForce
            local success = false
            
            if blend then
                success = viewModel:SetAnimationWithBlending(animName, self:GetBlendTime(), force, speed)
                length = viewModel:GetAnimationLength(animName) / speed                
            else
                success = viewModel:SetAnimation(animName, force, speed)
                length = viewModel:GetAnimationLength(animName) / speed
            end
            
            if success then
            
                if Client then
                    self:UpdateRenderModel()
                end
                
                viewModel:UpdateBoneCoords()
            end
            
            if not success and force then
                Print("%s:SetViewAnimation(%s) failed.", self:GetClassName(), tostring(animSpecifier))
            end
            
        else
            Print("Player:SetViewAnimation(%s) - couldn't find view model", animName)
        end
        
    end
    
    return length
    
end

function Player:GetViewAnimationLength(animName)

    local length = 0
    
    local viewModel = self:GetViewModelEntity()
    if (viewModel ~= nil) then
        if animName and animName ~= "" then
            length = viewModel:GetAnimationLength(animName)
        else 
            length = viewModel:GetAnimationLength(nil)
        end
    end
    
    return length
    
end

function Player:SetViewOverlayAnimation(overlayAnim)

    local viewModel = self:GetViewModelEntity()
    if (viewModel ~= nil) then
        viewModel:SetOverlayAnimation(overlayAnim)
    end
    
end

function Player:GetController()

    return self.controller
    
end

function Player:PrimaryAttack()

    local weapon = self:GetActiveWeapon()
    if weapon and self:GetCanNewActivityStart() then
        weapon:OnPrimaryAttack(self)
    end
    
end

function Player:SecondaryAttack()

    local weapon = self:GetActiveWeapon()        
    if weapon and self:GetCanNewActivityStart() then
        weapon:OnSecondaryAttack(self)
    end

end

function Player:PrimaryAttackEnd()

    local weapon = self:GetActiveWeapon()
    if weapon then
        weapon:OnPrimaryAttackEnd(self)
    end

end

function Player:SecondaryAttackEnd()

    local weapon = self:GetActiveWeapon()
    if weapon then
        weapon:OnSecondaryAttackEnd(self)
    end
    
end

function Player:SelectNextWeapon()

    PROFILE("Player:SelectNextWeapon")

    self:SelectNextWeaponInDirection(1)
    
end

function Player:SelectPrevWeapon()

    PROFILE("Player:SelectPrevWeapon")
    
    self:SelectNextWeaponInDirection(-1)
    
end

function Player:SelectNextWeaponInDirection(direction)

    local activeIndex = self:GetActiveWeaponIndex()
    local weaponList = self:GetHUDOrderedWeaponList()
    local numWeapons = table.count(weaponList)
    
    if numWeapons > 0 then
    
        local newIndex = activeIndex + direction
        // Handle wrap around.
        if newIndex > numWeapons then
            newIndex = 1
        elseif newIndex < 1 then
            newIndex = numWeapons
        end
        
        self:SetActiveWeapon(weaponList[newIndex]:GetMapName())
        
    end
    
end

function Player:GetActiveWeaponName()

    local activeWeaponName = ""
    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon ~= nil then
        activeWeaponName = activeWeapon:GetClassName()
    end
    
    return activeWeaponName
    
end

function Player:Reload()
    local weapon = self:GetActiveWeapon()
    if(weapon ~= nil and self:GetCanNewActivityStart()) then
        weapon:OnReload(self)
    end
end

/**
 * Check to see if there's a ScriptActor we can use. Checks any attachpoints returned from  
 * GetAttachPointOrigin() and if that fails, does a regular traceray. Returns true if we processed the action.
 */
function Player:Use(timePassed)

    PROFILE("Player:Use")

    ASSERT(timePassed >= 0)
    
    local success = false
    
    local startPoint = self:GetEyePos()
    local viewCoords = self:GetViewAngles():GetCoords()
    
    // To make building low objects like an infantry portal easier, increase the use range
    // as we look downwards. This effectively makes use trace in a box shape when looking down.
    local useRange = Player.kUseRange
    local sinAngle = viewCoords.zAxis:GetLengthXZ()
    if viewCoords.zAxis.y < 0 and sinAngle > 0 then
        useRange = Player.kUseRange / sinAngle
        if -viewCoords.zAxis.y * useRange > Player.kDownwardUseRange then
            useRange = Player.kDownwardUseRange / -viewCoords.zAxis.y
        end
    end
    
    // Get entities in radius
    
    local ents = GetEntitiesForTeamWithinRange("ScriptActor", self:GetTeamNumber(), self:GetOrigin(), useRange)
    for index, entity in ipairs(ents) do
    
        // Look for attach point
        local attachPointName = entity:GetUseAttachPoint()
        
        if attachPointName ~= "" and entity:GetCanBeUsed(self) then

            local attachPoint = entity:GetAttachPointOrigin(attachPointName)
            local toAttachPoint = attachPoint - startPoint
            local legalUse = toAttachPoint:GetLength() < useRange and viewCoords.zAxis:DotProduct(GetNormalizedVector(toAttachPoint)) > .8
            
            if(legalUse and entity:OnUse(self, timePassed, true, attachPoint)) then
            
                success = true
                
                break
                
            end
            
        end 
        
    end
    
    // If failed, do a regular trace with entities that don't have use attach points
    if not success then

        local endPoint = startPoint + viewCoords.zAxis * useRange
        local activeWeapon = self:GetActiveWeapon()
        
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))
        
        if trace.fraction < 1 and trace.entity ~= nil then
            local entityName = trace.entity:GetMapName()
            if trace.entity:GetCanBeUsed(self) then
                success = trace.entity:OnUse(self, timePassed, false, trace.endPoint)
            end
        end
        
    end
    
    // Put away weapon when we +use
    if success then
    
        if self:isa("Marine") and not self:GetWeaponHolstered() then
            self:Holster(true)
        end
        
        self:SetActivityEnd(Structure.kUseInterval)
        self:SetIsUsing(true)
    end
    
    self.timeOfLastUse = Shared.GetTime()
    
    return success
    
end

// Play different animations depending on current weapon
function Player:GetCustomAnimationName(animName)
    local activeWeapon = self:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        return string.format("%s_%s", activeWeapon:GetMapName(), animName)
    else
        return animName
    end
end

function Player:Buy()
end

function Player:Holster(force)

    local success = false
    local weapon = self:GetActiveWeapon()
    
    if weapon and (force or self:GetCanNewActivityStart()) then
    
        weapon:OnHolster(self)
        
        self.activeWeaponHolstered = true
        
        success = true
        
    end
    
    return success

end

function Player:Draw(previousWeaponName)

    local success = false
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and self:GetCanNewActivityStart()) then
    
        weapon:OnDraw(self, previousWeaponName)
        
        self.activeWeaponHolstered = false
        
        success = true
    end
        
    return success
    
end

function Player:GetWeaponHolstered()
    return self.activeWeaponHolstered
end

function Player:GetExtentsOverride()

    local extents = self:GetMaxExtents()
    if self.crouching then
        extents.y = extents.y * (1 - self:GetCrouchShrinkAmount())
    end
    return extents
    
end

function Player:GetMaxExtents()
    return Vector(self.maxExtents)    
end

/**
 * Returns true if the player is currently on a team and the game has started.
 */
function Player:GetIsPlaying()
    return self.gameStarted and (self:GetTeamNumber() == kTeam1Index or self:GetTeamNumber() == kTeam2Index)
end

function Player:GetCanTakeDamageOverride()
    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index)
end

function Player:GetCanSeeEntity(targetEntity)
    return GetCanSeeEntity(self, targetEntity)
end

// Individual resources
function Player:GetResources()
    return self.resources
end

// Returns player mass in kg
function Player:GetMass()
    return Player.kMass
end

function Player:AddResources(amount)
    local newResources = math.max(math.min(self.resources + amount, kMaxResources), 0)
    if newResources ~= self.resources then
        self.resources = newResources
        self:SetScoreboardChanged(true)
    end
    
end

function Player:AddTeamResources(amount)
    self.teamResources = math.max(math.min(self.teamResources + amount, kMaxResources), 0)
end

function Player:GetDisplayResources()

    local displayResources = self.resources
    if(Client and self.resourceDisplay) then
        displayResources = self.animatedResourcesDisplay:GetDisplayValue()
    end
    return math.floor(displayResources)
    
end

function Player:GetDisplayTeamResources()

    local displayTeamResources = self.teamResources
    if(Client and self.resourceDisplay) then
        displayTeamResources = self.animatedTeamResourcesDisplay:GetDisplayValue()
    end
    return displayTeamResources
    
end

// Team resources
function Player:GetTeamResources()
    return self.teamResources
end

// MoveMixin callbacks.
// Compute the desired velocity based on the input. Make sure that going off at 45 degree angles
// doesn't make us faster.
function Player:ComputeForwardVelocity(input)

    local forwardVelocity = Vector(0, 0, 0)

    local move          = GetNormalizedVector(input.move)
    local angles        = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    local viewCoords    = angles:GetCoords()
    
    local accel = ConditionalValue(self:GetIsOnLadder(), Player.kLadderAcceleration, self:GetAcceleration())
    local moveVelocity = viewCoords:TransformVector( move ) * accel
    self:ConstrainMoveVelocity(moveVelocity)
    
    // Make sure that moving forward while looking down doesn't slow 
    // us down (get forward velocity, not view velocity)
    local moveVelocityLength = moveVelocity:GetLength()
    
    if(moveVelocityLength > 0) then

        local moveDirection = self:GetMoveDirection(moveVelocity)
        
        // Trying to move straight down
        if(not ValidateValue(moveDirection)) then
            moveDirection = Vector(0, -1, 0)
        end
        
        forwardVelocity = moveDirection * moveVelocityLength
        
    end
    
    return forwardVelocity

end

function Player:GetFrictionForce(input, velocity)
    
    local frictionScalar = 0

    // Don't apply friction when we're moving on the ground,
    // it affects our max speed too much. Just bring us to a stop
    // when we stop trying to move.
    if(self:GetIsOnGround() and input.move:GetLength() == 0) then
        frictionScalar = 8
    end
    
    local scaleVelY = 0
    if(self:GetIsOnLadder()) then
        frictionScalar = 8
        scaleVelY = -velocity.y
    end
    
    return Vector(-velocity.x, scaleVelY, -velocity.z) * frictionScalar
    
end

function Player:GetGravityAllowed()

    // No gravity when on ladders or on the ground.
    return not self:GetIsOnLadder() and not self:GetIsOnGround()
    
end

function Player:GetMoveDirection(moveVelocity)

    if(self:GetIsOnLadder()) then
    
        return GetNormalizedVector(moveVelocity)

    end
    
    local up = Vector(0, 1, 0)
    local right = GetNormalizedVector(moveVelocity):CrossProduct(up)
    local moveDirection = up:CrossProduct(right)
    moveDirection:Normalize()
    
    return moveDirection
    
end

function Player:EndUse(deltaTime)
    if not self:GetIsUsing() then
        return
    end        
    
    // Pull out weapon again if we haven't built for a bit
    if self:GetWeaponHolstered() and self:isa("Marine") and ((Shared.GetTime() - self.timeOfLastUse) > Structure.kUseInterval) then
        // $AS - So its possible that when this code gets his there might be an activity going 
        if (self:Draw()) then
            self:SetIsUsing(false)
        end
    elseif self:isa("Alien") then
        self:SetIsUsing(false)
    end

    local viewModel = self:GetViewModelEntity()
    if viewModel then
        
        local newVisState = not self:GetWeaponHolstered()
        if newVisState ~= viewModel:GetIsVisible() then
        
            viewModel:SetIsVisible(newVisState)        
            
        end
        
    end
    
    self.updatedSinceUse = true
    
end

// Make sure we can't move faster than our max speed (esp. when holding
// down multiple keys, going down ramps, etc.)
function Player:ClampSpeed(input, velocity)

    PROFILE("Player:ClampSpeed")

    // Only clamp XZ speed so it feels better
    local moveSpeedXZ = velocity:GetLengthXZ()        
    local maxSpeed = self:GetMaxSpeed()
    
    // Players moving backwards can't go full speed    
    if input.move.z < 0 then
    
        maxSpeed = maxSpeed * self:GetMaxBackwardSpeedScalar()
        
    end
    
    if (moveSpeedXZ > maxSpeed) then
    
        local velocityY = velocity.y
        velocity:Scale( maxSpeed / moveSpeedXZ )
        velocity.y = velocityY
        
    end 
    
    return velocity
    
end

// Allow child classes to alter player's move at beginning of frame. Alter amount they
// can move by scaling input.move, remove key presses, etc.
function Player:AdjustMove(input)

    PROFILE("Player:AdjustMove")
    
    // Don't allow movement when frozen in place
    if(self.frozen) then
    
        input.move:Scale(0)
        
    else        
    
        // Allow child classes to affect how much input is allowed at any time
        if (self.mode == kPlayerMode.Taunt) then
    
            input.move:Scale(Player.kTauntMovementScalar)
            
        end
        
    end
    
    return input
    
end

function Player:UpdateViewAngles(input)

    PROFILE("Player:UpdateViewAngles")
    
    if self.desiredRoll ~= nil then
    
        local angles = Angles(self:GetAngles())        
        local kRate = input.time * 10
        angles.roll = SlerpRadians(angles.roll, self.desiredRoll, kRate)
       
        self:SetAngles(angles)

    end
    
    if self.desiredPitch ~= nil then
    
        local angles = Angles(self:GetAngles())        
        local kRate = input.time * 10
        angles.pitch = SlerpRadians(angles.pitch, self.desiredPitch, kRate)
       
        self:SetAngles(angles)

    end
        
    // Update to the current view angles.    
    local viewAngles = Angles(input.pitch, input.yaw, 0)
    self:SetViewAngles(viewAngles)
        
    // Update view offset from crouching
    local viewY = self:GetMaxViewOffsetHeight()
    viewY = viewY - viewY * self:GetCrouchShrinkAmount() * self:GetCrouchAmount()

    // Don't set new view offset height unless needed (avoids Vector churn).
    local lastViewOffsetHeight = self:GetSmoothedViewOffset().y
    if math.abs(viewY - lastViewOffsetHeight) > kEpsilon then
        self:SetViewOffsetHeight(viewY)
    end
    
end

function Player:SetDesiredRoll(roll)
    self.desiredRoll = roll
end

function Player:SetDesiredPitch(pitch)
    self.desiredPitch = pitch
end


do

    local function GetId(player)
        if player.clientIndex and player.clientIndex ~= -1 then
            return player.clientIndex
        end 
        return player:GetId()
    end

    function DumpPlayerData(mover, input)

        local mode
        
        if Client then
            if Shared.GetIsRunningPrediction() then
                mode = "prediction"
            else
                mode = "client"
            end
        else
            mode = "server"
        end
        
        Shared.Message( string.format( ">>> OnProcessMove %s Player %d time = %f", mode, GetId(mover), Shared.GetTime() ) )

        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            local origin = player:GetOrigin()
            local height, radius = player:GetControllerSize()
            Shared.Message( string.format(">>>> Player %d: %f, %f, %f, %f", GetId(player), origin.x, origin.y, origin.z, radius) )
        end
        
    end

end

// You can't modify a compensated field for another (relevant) entity during OnProcessMove(). The
// "local" player doesn't undergo lag compensation it's only all of the other players and entities.
// For example, if health was compensated, you can't modify it when a player was shot -
// it will just overwrite it with the old value after OnProcessMove() is done. This is because
// compensated fields are rolled back in time, so it needs to restore them once the processing
// is done. So it backs up, synchs to the old state, runs the OnProcessMove(), then restores them. 
function Player:OnProcessMove(input)

    PROFILE("Player:OnProcessMove")

    SetRunningProcessMove(self)
    
    ScriptActor.OnProcessMove(self, input)
    
    // Only update player movement on server or for local player
    if (self:GetIsAlive() and (Server or (Client.GetLocalPlayer() == self))) then
        
        ASSERT(self.controller ~= nil)

        // Force an update to whether or not we're on the ground in case something
        // has moved out from underneath us.
        self.onGroundNeedsUpdate = true      
        local wasOnGround = self.onGround
        
        // Allow children to alter player's move before processing. To alter the move
        // before it's sent to the server, use OverrideInput
        input = self:AdjustMove(input)

        // Update player angles and view angles smoothly from desired angles if set. 
        // But visual effects should only be calculated when not predicting.
        self:UpdateViewAngles(input)
        
        // Check for jumping, attacking, etc.
        self:HandleButtons(input)

        if HasMixin(self, "Move") then
            // Update origin and velocity from input move (main physics behavior).
            self:UpdateMove(input)
        end
        
        // Animation transitions (walking, jumping, etc.)
        self:UpdateAnimationTransitions(input.time)

        self:UpdateMaxMoveSpeed(input.time) 
    
        self:UpdateJumpLand(wasOnGround)
        
        // Everything else
        self:UpdateMisc(input)
        
        self:UpdateSharedMisc(input)
        
        // Debug if desired
        //self:OutputDebug()
        
    elseif not self:GetIsAlive() and Client and (Client.GetLocalPlayer() == self) then
    
        // Allow the use of scoreboard, chat, and map even when not alive.
        self:UpdateScoreboard(input)
        self:UpdateChat(input)
        self:UpdateShowMap(input)
        
    end
    
    if (not Shared.GetIsRunningPrediction()) then
    
        self:UpdatePoseParameters(input.time)
        
        // Since we changed the coords for the player, update the physics model.
        self:SetPhysicsDirty()
        
        // Force the view model to be dirty so the animation properly predicts.
        local viewModel = self:GetViewModelEntity()
        if (viewModel ~= nil) then
            viewModel:SetPhysicsDirty()
        end

    end
    
    if Server then
        // Because we aren't predicting the use operation, we shouldn't predict
        // the end of the use operation (or else with lag we can get rogue weapon
        // drawing while holding down use)
        self:EndUse(input.time)
    end
    
    SetRunningProcessMove(nil)

    
end

function Player:GetSlowOnLand()
    return false
end

function Player:UpdateMaxMoveSpeed(deltaTime)    

    ASSERT(deltaTime >= 0)
    
    // Only recover max speed when on the ground
    if self:GetIsOnGround() then
    
        local newSlow = math.max(0, self.slowAmount - deltaTime)
        //if newSlow ~= self.slowAmount then
        //    Print("UpdateMaxMoveSpeed(%s) => %s => %s (time: %s)", ToString(deltaTime), ToString(self.slowAmount), newSlow, ToString(Shared.GetTime()))
        //end
        self.slowAmount = newSlow    
        
    end
    
end

function Player:OutputDebug()

    local startPoint = Vector(self:GetOrigin())
    startPoint.y = startPoint.y + self:GetExtents().y
    DebugBox(startPoint, startPoint, self:GetExtents(), .05, 1, 1, 0, 1)
    
end

// Note: It doesn't look like this is being used anymore.
function Player:GetItem(mapName)
    
    for i = 0, self:GetNumChildren() - 1 do
    
        local currentChild = self:GetChildAtIndex(i)
        if currentChild:GetMapName() == mapName then
            return currentChild
        end

    end
    
    return nil
    
end

function Player:GetTraceCapsule()
    return GetTraceCapsuleFromExtents(self:GetExtents())    
end

// Required by ControllerMixin.
function Player:GetControllerSize()
    return GetTraceCapsuleFromExtents(self:GetExtents())    
end

// Required by ControllerMixin.
function Player:GetMovePhysicsMask()
    return PhysicsMask.Movement
end

/**
 * Moves the player downwards (by at most a meter).
 */
function Player:DropToFloor()

    if self.controller then
        self:UpdateControllerFromEntity()
        self.controller:Move( Vector(0, -1, 0), self:GetMovePhysicsMask())    
        self:UpdateOriginFromController()
    end

end

function Player:Unstick()

    // This code causes the player to move erratically when colliding with another
    // player. It does not appear to actually be necessary, so I've commented it out
    // but left it in case we discover a need for it.
    /*
    local start = Vector(self:GetOrigin())

    local unstickOffset = Vector(0, 0.25, 0)
    local trace = self.controller:Trace( unstickOffset, self:GetMovePhysicsMask())
    
    if trace.fraction == 1 then

        self:SetOrigin(self:GetOrigin() + unstickOffset)
        self:UpdateControllerFromEntity()
    
        if self:GetIsStuck() then
            // Moving up didn't unstick us, so go back to where we were
            self:SetOrigin(start)
            self:UpdateControllerFromEntity()
            return true
        else
            Print("Unstuck!")
        end
    
    end
    
    // Try moving player in a couple different directions until we're unstuck
    for index, direction in ipairs(Player.kUnstickOffsets) do
    
        local trace = self.controller:Trace(direction, self:GetMovePhysicsMask())
        if trace.fraction == 1 then
        
            self:SetOrigin(self:GetOrigin() + direction)
            self:UpdateControllerFromEntity()
            return true
            
        end

    end
    */
    
    return false
    
end

function Player:UpdatePosition(velocity, time)

    PROFILE("Player:UpdatePosition")

    // We need to make a copy so that we aren't holding onto a reference
    // which is updated when the origin changes.
    local start         = Vector(self:GetOrigin())
    local startVelocity = Vector(velocity)

    local maxSlideMoves = 4

    local offset     = nil
    local stepHeight = self:GetStepHeight()
    local onGround   = self:GetIsOnGround()    

    // Handle when we're interpenetrating an object usually due to animation. Ie we're under a hive that's breathing into us
    // or when we're standing on top of animated structures like Hives, Extractors, etc.
    local stuck = self:GetIsStuck()
    if stuck then    
        self:Unstick()
    end

    local completedMove = self:PerformMovement( velocity * time, maxSlideMoves, velocity )
    
    if not completedMove and onGround then
        
        // Go back to the beginning and now try a step move.
        self:SetOrigin(start)
    
        // First move the character upwards to allow them to go up stairs and over small obstacles. 
        self:PerformMovement( Vector(0, stepHeight, 0), 1 )
        local steppedStart = self:GetOrigin()
        
        if self:GetIsColliding() then

            // Moving up didn't allow us to go over anything, so move back
            // to the start position so we don't get stuck in an elevated position
            // due to not being able to move back down.
            self:SetOrigin(start)
            offset = Vector(0, 0, 0)
        
        else

            offset = steppedStart - start
        
            // Now try moving the controller the desired distance.
            VectorCopy( startVelocity, velocity )
            self:PerformMovement( startVelocity * time, maxSlideMoves, velocity )
            
        end
        
    else
        offset = Vector(0, 0, 0)
    end
    
    if onGround then
    
        // Finally, move the player back down to compensate for moving them up.
        // We add in an additional step  height for moving down steps/ramps.
        offset.y = -(offset.y + stepHeight)
        self:PerformMovement( offset, 1, nil )
        
        // Check to see if we moved up a step and need to smooth out
        // the movement.
        
        local yDelta = self:GetOrigin().y - start.y
        
        if (yDelta ~= 0) then

            // If we're already interpolating up a step, we need to take that into account
            // so that we continue that interpolation, plus our new step interpolation
        
            local deltaTime      = Shared.GetTime() - self.stepStartTime
            local prevStepAmount = 0
            
            if deltaTime < Player.stepTotalTime then
                prevStepAmount = self.stepAmount * (1 - deltaTime / Player.stepTotalTime)
            end        
        
            self.stepStartTime = Shared.GetTime()
            self.stepAmount    = yDelta + prevStepAmount
            
        end    
        
    end
    
    return velocity

end

// Return the height that this player can step over automatically
function Player:GetStepHeight()
    return .5
end

function Player:GetBreathingHeight()
    return 0
end

function Player:UpdateBreathing(timePassed)

    // Add in breathing according to how fast we're moving
    local movementSpeedScalar = 1.5//math.max(1, self:GetVelocity():GetLength())
    local currentBreathingHeight = self:GetBreathingHeight() * math.cos( Shared.GetTime() * movementSpeedScalar )
    
    local viewOffset = self:GetSmoothedViewOffset()
    viewOffset.y = viewOffset.y + currentBreathingHeight
    self:SetViewOffsetHeight(viewOffset.y)
    
    // Update out of breath scalar if we've been running
    local moveScalar = self:GetVelocity():GetLength()/self:GetMaxSpeed()
    self.outOfBreath = self.outOfBreath + (moveScalar*timePassed/Player.kTimeToLoseBreath)*255
    
    // Catch breath
    self.outOfBreath = self.outOfBreath - (1*timePassed/Player.kTimeToGainBreath)*255
    self.outOfBreath = math.max(math.min(self.outOfBreath, 255), 0)

end

/**
 * Returns a value between 0 and 1 indicating how much the player has crouched
 * visually (actual crouching is binary).
 */
function Player:GetCrouchAmount()
     
    // Get 0-1 scalar of time since crouch changed        
    local crouchScalar = 0
    if self.timeOfCrouchChange > 0 then
    
        crouchScalar = math.min(Shared.GetTime() - self.timeOfCrouchChange, Player.kCrouchAnimationTime)/Player.kCrouchAnimationTime
        
        if(self.crouching) then
            crouchScalar = math.sin(crouchScalar * math.pi/2)
        else
            crouchScalar = math.cos(crouchScalar * math.pi/2)
        end
        
    end
    
    return crouchScalar

end

function Player:GetCrouching()
    return self.crouching
end

function Player:GetCrouchShrinkAmount()
    return Player.kCrouchShrinkAmount
end

// Returns true if the player is currently standing on top of something solid. Recalculates
// onGround if we've updated our position since we've last called this.
function Player:GetIsOnGround()
    
    // Re-calculate every time SetOrigin is called
    if(self.onGroundNeedsUpdate) then
    
        self.onGround = false

        // We're not on ground for a short time after we jump
        if (self:GetOverlayAnimation() ~= self:GetCustomAnimationName(Player.kAnimStartJump) or self:GetOverlayAnimationFinished()) then

            self.onGround = self:GetIsCloseToGround(Player.kOnGroundDistance)
            
            if self.onGround then
                self.timeLastOnGround = Shared.GetTime()
            end
            
        end
        
        self.onGroundNeedsUpdate = false        
        
    end
    
    if(self:GetIsOnLadder()) then
    
        return false
        
    end

    return self.onGround
    
end

function Player:SetIsOnLadder(onLadder, ladderEntity)

    self.onLadder = onLadder
    
end

// Override this for Player types that shouldn't be on Ladders
function Player:GetIsOnLadder()

    return self.onLadder
    
end

// Recalculate self.onGround next time
function Player:SetOrigin(origin)

    Entity.SetOrigin(self, origin)
    
    self:UpdateControllerFromEntity()
    
    self.onGroundNeedsUpdate = true
    
end

// Returns boolean indicating if we're at least the passed in distance from the ground.
function Player:GetIsCloseToGround(distanceToGround)

    if self.controller == nil then
        return false
    end

    if (self:GetVelocity().y > 0 and self.timeOfLastJump ~= nil and (Shared.GetTime() - self.timeOfLastJump < .2)) then
    
        // If we are moving away from the ground, don't treat
        // us as standing on it.
        return false
        
    end
    
    // Try to move the controller downward a small amount to determine if
    // we're on the ground.
    local offset = Vector(0, -distanceToGround, 0)
    local trace = self.controller:Trace(offset, self:GetMovePhysicsMask())
    
    if (trace.fraction < 1 and trace.normal.y < Player.kMaxWalkableNormal) then
        return false
    end

    if trace.fraction < 1 then
        return true
    end
    
    return false
    
end

// Look current player position and size and determine if we're stuck
function Player:GetIsStuck()

    PROFILE("Player:GetIsStuck")
    return self.controller:Test( self:GetMovePhysicsMask() )
    
end

function Player:GetPlayFootsteps()

    local velocity = self:GetVelocity()
    local velocityLength = velocity:GetLength() 
    return not self.crouching and self:GetIsOnGround() and velocityLength > .75
    
end

function Player:GetIsJumping()

    local overlayAnim = self:GetOverlayAnimation()
    
    return  overlayAnim == self:GetCustomAnimationName(Player.kAnimStartJump) or 
            overlayAnim == self:GetCustomAnimationName(Player.kAnimJump) or 
            overlayAnim == self:GetCustomAnimationName(Player.kAnimEndJump)

end

function Player:GetCanIdle()
    local groundSpeed = self:GetVelocity():GetLengthXZ()
    local stunned = HasMixin(self, "Stun") and self:GetIsStunned()
    return groundSpeed < .5 and self:GetIsOnGround() and not stunned
end

/**
 * Called to update the animation playing on the player based on the current
 * state (not moving, jumping, etc.)
 */
function Player:UpdateAnimationTransitions(timePassed)

    PROFILE("Player:UpdateAnimationTransitions")
    
    if (self.mode == kPlayerMode.Default and self:GetIsAlive()) then
    
        // If we've been in the air long enough to finish jump animation, transition to jump animation
        // Also play jump animation when falling. 
        local overlayAnim = self:GetOverlayAnimation()
        local velocity    = self:GetVelocity()

        // If we started jumping and finished animation, or if we've stepped off something, play falling animation, 
        if ( overlayAnim == self:GetCustomAnimationName(Player.kAnimStartJump) and (self.fallReadyForPlay == 0) and self:GetOverlayAnimationFinished() ) then
            
            // fallReadyForPlay prevents the fall sound from being played multiple times
            self.fallReadyForPlay = 1
            self:SetOverlayAnimation(self:GetCustomAnimationName(Player.kAnimJump))
            
        // If we're about to land, play land animation
        elseif (overlayAnim == self:GetCustomAnimationName(Player.kAnimJump) and (self.fallReadyForPlay == 1) and (((velocity.y < 0) and self:GetIsCloseToGround(Player.kOnGroundDistance)) or self:GetIsOnGround())) then

            // Play special fall sounds depending on material
            self:TriggerEffects("fall", {surface = self:GetMaterialBelowPlayer()})
            
            self:SetOverlayAnimation(self:GetCustomAnimationName(Player.kAnimEndJump))
            
            self.fallReadyForPlay = 2
            
        elseif (overlayAnim == self:GetCustomAnimationName(Player.kAnimEndJump) and self:GetOverlayAnimationFinished()) then
        
            self:SetOverlayAnimation("")
            
            self.fallReadyForPlay = 0
            
        end
  
        self:UpdateMoveAnimation()
        
    end
    
    ScriptActor.UpdateAnimation(self, timePassed)
        
end

function Player:UpdateAnimation()
    // Override the ScriptActor version since we explicitly call this during OnProcessMove
    // for players (so we have consistent results on the client and server).
end

// Called by client/server UpdateMisc()
function Player:UpdateSharedMisc(input)

    self:UpdateBreathing(input.time)
    self:UpdateMode()
    // From WeaponOwnerMixin.
    self:UpdateWeapons(input)

    self:UpdateScoreboard(input) 
    
end

function Player:UpdateJumpLand(wasOnGround)

    // If we landed this frame
    if wasOnGround ~= nil and not wasOnGround and self.onGround then

        if self:GetSlowOnLand() and self:GetVelocity():GetLength() > (self:GetMaxSpeed() - kEpsilon) then
        
            self:AddSlowScalar(.5)
            
        end
        
    end

end

function Player:UpdateScoreboard(input)
    self.showScoreboard = (bit.band(input.commands, Move.Scoreboard) ~= 0)
end

function Player:UpdateShowMap(input)
    PROFILE("Player:UpdateShowMap")
    if Client then
        self:ShowMap(bit.band(input.commands, Move.ShowMap) ~= 0)
    end
end

function Player:UpdateMoveAnimation()

    local groundSpeed = self:GetVelocity():GetLengthXZ()
    if (groundSpeed > .1) then

        self:SetAnimationWithBlending(Player.kAnimRun)
        
    end
    
end

function Player:UpdatePoseParameters(deltaTime)

    PROFILE("Player:UpdatePoseParameters")
    
    // A Move mixins is needed for GetViewAngles().
    ASSERT(HasMixin(self, "Move"))
    
    SetPlayerPoseParameters(self, self:GetViewAngles(), self:GetVelocity(), self:GetMaxSpeed(), self:GetMaxBackwardSpeedScalar(), self:GetCrouchAmount())    

end

// By default the movement speed will not factor in the vertical velocity.
function Player:GetMoveSpeedIs2D()
    return true
end

function Player:UpdateMode()

    if(self.mode ~= kPlayerMode.Default and self.modeTime ~= -1 and Shared.GetTime() > self.modeTime) then
    
        if(not self:ProcessEndMode()) then
        
            self.mode = kPlayerMode.Default
            self.modeTime = -1
            
        end

    end
    
end

function Player:ProcessEndMode()

    if(self.mode == kPlayerMode.Knockback) then
    
        self:SetAnimAndMode("standup", kPlayerMode.StandUp)
        
        // No anim yet, set modetime manually
        self.modeTime = 1.25
        return true
        
    end
    
    return false
end

// sv_accelerate/sv_airaccelerate = 10
// sv_friction = 4
// sv_stopspeed = 100
function Player:GetMaxSpeed()

    // Take into account crouching
    return ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar ) * Player.kWalkMaxSpeed
        
end

function Player:GetAcceleration()
    return Player.kAcceleration
end

// Maximum speed a player can move backwards
function Player:GetMaxBackwardSpeedScalar()
    return Player.kWalkBackwardSpeedScalar
end

function Player:GetAirMoveScalar()
    return .7
end

/**
 * Don't allow full air control but allow players to especially their movement in the opposite way they are moving (airmove).
 */
function Player:ConstrainMoveVelocity(wishVelocity)
    
    if not self:GetIsOnLadder() and not self:GetIsOnGround() and wishVelocity:GetLengthXZ() > 0 and self:GetVelocity():GetLengthXZ() > 0 then
    
        local normWishVelocity = GetNormalizedVectorXZ(wishVelocity)
        local normVelocity = GetNormalizedVectorXZ(self:GetVelocity())
        local scalar = Clamp((1 - normWishVelocity:DotProduct(normVelocity)) * self:GetAirMoveScalar(), 0, 1)
        
        wishVelocity:Scale(scalar)

    end
    
end

function Player:GetCanJump()
    return self:GetIsOnGround()
end

function Player:GetJumpHeight()
    return Player.kJumpHeight
end

// If we jump, make sure to set self.timeOfLastJump to the current time
function Player:HandleJump(input, velocity)

    if self:GetCanJump() then
    
        // Compute the initial velocity to give us the desired jump
        // height under the force of gravity.
        velocity.y = math.sqrt(-2 * self:GetJumpHeight() * self:GetGravityForce(input))

        if not Shared.GetIsRunningPrediction() then
            self:TriggerEffects("jump", {surface = self:GetMaterialBelowPlayer()})
        end
        
        // TODO: Set this somehow (set on sounds for entity, not by sound name?)
        //self:SetSoundParameter(soundName, "speed", self:GetFootstepSpeedScalar(), 1)
        
        self:SetOverlayAnimation(self:GetCustomAnimationName(Player.kAnimStartJump))
        
        self.timeOfLastJump = Shared.GetTime()
        
        self.onGroundNeedsUpdate = true
               
    end

end

// 0-1 scalar which goes away over time (takes 1 seconds to get expire of a scalar of 1)
// Never more than 1 second of recovery time
// Also reduce velocity by this amount
function Player:AddSlowScalar(scalar)

    self.slowAmount = Clamp(self.slowAmount + scalar, 0, 1)    
    
    self:SetVelocity( self:GetVelocity() * (1 - scalar) )
    
end

function Player:OnTag(tagName)

    //Print("%s:OnTag(%s)(play footsteps: %s)", self:GetClassName(), tagName, ToString(self:GetPlayFootsteps()))

    ScriptActor.OnTag(self, tagName)

    // Play footstep when foot hits the ground
    if(string.lower(tagName) == "step" and self:GetPlayFootsteps()) then
    
        self.leftFoot = not self.leftFoot
        self:TriggerEffects("footstep", {surface = self:GetMaterialBelowPlayer(), left = self.leftFoot})
        
    end
    
end

function Player:GetMaterialBelowPlayer()

    local fixedOrigin = Vector(self:GetOrigin())
    
    // Start the trace a bit above the very bottom of the origin because
    // of cases where a large velocity has pushed the origin below the
    // surface the player is on
    fixedOrigin.y = fixedOrigin.y + self:GetExtents().y / 2
    local trace = Shared.TraceRay(fixedOrigin, fixedOrigin + Vector(0, -(2.5*self:GetExtents().y + .1), 0), PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    local material = trace.surface
    // Default to metal if no surface material is found.
    if not material or string.len(material) == 0 then
        material = "metal"
    end
    
    // Have squishy footsteps on infestation 
    if self:GetGameEffectMask(kGameEffect.OnInfestation) then
        material = "organic"
    end
    
    return material
end

function Player:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocity():GetLength() / self:GetMaxSpeed(), 0, 1)
end

function Player:CanDrawWeapon()
    return true
end

function Player:HandleAttacks(input)

    PROFILE("Player:HandleAttacks")

    if (self:GetIsUsing()) then
        return
    end

    if (bit.band(input.commands, Move.PrimaryAttack) ~= 0) then
    
        self:PrimaryAttack()
        
    else
    
        if self.primaryAttackLastFrame then
        
            self:PrimaryAttackEnd()
            
        end
        
    end

    if (bit.band(input.commands, Move.SecondaryAttack) ~= 0) then
    
        self:SecondaryAttack()
        
    else
    
        if(self.secondaryAttackLastFrame ~= nil and self.secondaryAttackLastFrame) then
        
            self:SecondaryAttackEnd()
            
        end
        
    end

    // Remember if we attacked so we don't call AttackEnd() until mouse button is released
    self.primaryAttackLastFrame = (bit.band(input.commands, Move.PrimaryAttack) ~= 0)
    self.secondaryAttackLastFrame = (bit.band(input.commands, Move.SecondaryAttack) ~= 0)
    
end

// Look at keys hold down and return integer representing the direction we're going 
function Player:GetDesiredTapDirection(input)

    local newDirection = Player.kTapMode.None
    
    if input.move.z == 0 then
        if input.move.x == 1 then
            newDirection = Player.kTapMode.LeftDown
        elseif input.move.x == -1 then
            newDirection = Player.kTapMode.RightDown
        end
    elseif input.move.x == 0 then
        if input.move.z == 1 then
            newDirection = Player.kTapMode.ForwardDown
        elseif input.move.z == -1 then
            newDirection = Player.kTapMode.BackDown
        end
    end
    
    return newDirection
    
end

function Player:HandleDoubleTap(input)

    PROFILE("Player:HandleDoubleTap")
    
    // Max time interval between down and up, and up then down
    local kTapInterval = .2
    local newDirectionEnum = self:GetDesiredTapDirection(input)
    local newIsTapDown = (self.tapMode == Player.kTapMode.LeftDown or self.tapMode == Player.kTapMode.RightDown or self.tapMode == Player.kTapMode.ForwardDown or self.tapMode == Player.kTapMode.BackDown)
    local currentIsTapDown = (self.tapMode == Player.kTapMode.LeftDown or self.tapMode == Player.kTapMode.RightDown or self.tapMode == Player.kTapMode.ForwardDown or self.tapMode == Player.kTapMode.BackDown)
    
    // Check if we're releasing key after pressing it previously
    if (newDirectionEnum == Player.kTapMode.None) and (Shared.GetTime() < self.tapModeTime + kTapInterval) and currentIsTapDown then
    
        if self.tapMode == Player.kTapMode.LeftDown then
            self:SetTapMode(Player.kTapMode.LeftUp)
        elseif self.tapMode == Player.kTapMode.RightDown then
            self:SetTapMode(Player.kTapMode.RightUp)
        elseif self.tapMode == Player.kTapMode.ForwardDown then
            self:SetTapMode(Player.kTapMode.ForwardUp)
        elseif self.tapMode == Player.kTapMode.BackDown then
            self:SetTapMode(Player.kTapMode.BackUp)
        end

    // Check if we just pressed in the same direction after we previously released it
    elseif (self.tapMode == Player.kTapMode.LeftUp or self.tapMode == Player.kTapMode.RightUp or self.tapMode == Player.kTapMode.ForwardUp or self.tapMode == Player.kTapMode.BackUp) and
            // Make sure the down is matched to the up and happening quickly
           (newDirectionEnum == (self.tapMode - 1)) and (Shared.GetTime() < (self.tapModeTime + kTapInterval)) then
    
        if (newDirectionEnum == (self.tapMode - 1)) then
        
            self:OnDoubleTap(newDirectionEnum)
        
            self:SetTapMode(Player.kTapMode.None)
            
        end
    
    elseif newDirectionEnum ~= Player.kTapMode.None or (Shared.GetTime() > self.tapModeTime + kTapInterval) then
        self:SetTapMode(newDirectionEnum)        
    end
    
end

function Player:SetTapMode(mode)

    if self.tapMode ~= mode then    
        
        self.tapMode = mode
        self.tapModeTime = Shared.GetTime()            
        
    end
    
end

// Pass view model direction
function Player:OnDoubleTap(tapDirectionEnum)
end

function Player:GetPrimaryAttackLastFrame()
    return self.primaryAttackLastFrame
end

function Player:GetSecondaryAttackLastFrame()
    return self.secondaryAttackLastFrame
end

// Children can add or remove velocity according to special abilities, modes, etc.
function Player:ModifyVelocity(input, velocity)   

    PROFILE("Player:ModifyVelocity")
    
    // Must press jump multiple times to get multiple jumps 
    if (bit.band(input.commands, Move.Jump) ~= 0) and not self.jumpHandled then
    
        self:HandleJump(input, velocity)
        self.jumpHandled = true
    
    elseif self:GetIsOnGround() then

        velocity.y = 0
    
    end
    
end

function Player:HandleButtons(input)

    PROFILE("Player:HandleButtons")

    if (bit.band(input.commands, Move.Use) ~= 0) and not self.primaryAttackLastFrame and not self.secondaryAttackLastFrame then
        self:Use(input.time)    
    end
    
    if not Shared.GetIsRunningPrediction() then
    
        // Player is bringing up the buy menu (don't toggle it too quickly)
        if (bit.band(input.commands, Move.Buy) ~= 0 and Shared.GetTime() > (self.timeLastMenu + .3)) then
        
            self:Buy()
            self.timeLastMenu = Shared.GetTime()
            
        end
        
        // When exit hit, bring up menu
        if (bit.band(input.commands, Move.Exit) ~= 0 and (Shared.GetTime() > (self.timeLastMenu + .3)) and (Client ~= nil)) then
            ExitPressed()
            self.timeLastMenu = Shared.GetTime()
        end
        
    end
        
    // Remember when jump released
    if (bit.band(input.commands, Move.Jump) == 0) then
        self.jumpHandled = false
    end
    
    self:HandleAttacks(input)
    
    self:HandleDoubleTap(input)
        
    if (bit.band(input.commands, Move.NextWeapon) ~= 0) then
        self:SelectNextWeapon()
    end
    
    if (bit.band(input.commands, Move.PrevWeapon) ~= 0) then
        self:SelectPrevWeapon()
    end
    
    if (bit.band(input.commands, Move.Reload) ~= 0) then
        self:Reload()
    end

    if ( bit.band(input.commands, Move.Drop) ~= 0 and self.Drop ) then
        self:Drop()
    end
    
    if ( bit.band(input.commands, Move.Taunt) ~= 0 ) then
        self:Taunt()
    end

    // Weapon switch
    if (bit.band(input.commands, Move.Weapon1) ~= 0) then
        self:SwitchWeapon(1)
    end
    
    if (bit.band(input.commands, Move.Weapon2) ~= 0) then
        self:SwitchWeapon(2)
    end
    
    if (bit.band(input.commands, Move.Weapon3) ~= 0) then
        self:SwitchWeapon(3)
    end
    
    if (bit.band(input.commands, Move.Weapon4) ~= 0) then
        self:SwitchWeapon(4)
    end
    
    if (bit.band(input.commands, Move.Weapon5) ~= 0) then
        self:SwitchWeapon(5)
    end
    
    local crouching = bit.band(input.commands, Move.Crouch) ~= 0
    
    if self.crouching and not crouching then
        // Attempt to stop crouching
        self:SetCrouchState(crouching)
    elseif not self.crouching and crouching then
        // Start crouching
        self:SetCrouchState(crouching)
    end
    
    self:UpdateShowMap(input)
        
end

function Player:SetCrouchState(crouching)

    PROFILE("Player:SetCrouchState")

    if crouching == self.crouching then
        return
    end
   
    if not crouching then
        
        // Check if there is room for us to stand up.
        self.crouching = crouching
        self:UpdateControllerFromEntity()
        
        if self:GetIsStuck() then
            self.crouching = true
            self:UpdateControllerFromEntity()
        else
            self.timeOfCrouchChange = Shared.GetTime()
        end
        
    else
        self.crouching = crouching
        self.timeOfCrouchChange = Shared.GetTime()
        self:UpdateControllerFromEntity()
    end

end

function Player:OnBuy()
end

function Player:GetNotEnoughResourcesSound()
    return Player.kNotEnoughResourcesSound    
end

function Player:GetIsCommander()
    return false
end

// Children should override with specific menu actions
function Player:ExecuteSaying(index, menu)
    self.executeSaying = index
end

function Player:GetAndClearSaying()
    if(self.executeSaying ~= nil) then
        local saying = self.executeSaying
        self.executeSaying = nil
        return saying
    end
    return nil
end

/**
 * Returns the view model entity.
 */
function Player:GetViewModelEntity()    

    if Server then
    if self.viewModelId == Entity.invalidId then
        self:InitViewModel()    
    end
    end
    
    return Shared.GetEntity(self.viewModelId)
    
end

/**
 * Sets the model currently displayed on the view model.
 */
function Player:SetViewModel(viewModelName, weapon)
    local viewModel = self:GetViewModelEntity()
    if viewModel then
        viewModel:SetWeapon(weapon)
        viewModel:SetModel(viewModelName)
    else
        Print("%s:SetViewModel(%s): View model nil", self:GetClassName(), ToString(viewModelName))
    end
end

function Player:OnAnimationComplete(animName)

    ScriptActor.OnAnimationComplete(self, animName)

    if animName == Player.kAnimTaunt then
        self:SetDesiredCameraDistance(0)
    end
    
end

function Player:GetTauntSound()
    return Player.kInvalidSound
end

function Player:GetTauntAnimation()
    return Player.kAnimTaunt
end

function Player:Taunt()

    if (self:GetAnimation() ~= Player.kAnimTaunt and self:GetIsOnGround()) then
    
        // Play taunt animation and sound
        self:SetAnimAndMode(self:GetTauntAnimation(), kPlayerMode.Taunt)
        
        Shared.PlaySound(self, self:GetTauntSound())

        //self:SetDesiredCameraDistance( ConditionalValue(self.desiredCameraDistance > 0, 0, 5) )
        
    end
    
end

function Player:SetAnimAndMode(animName, mode)

    local force = (self.mode ~= mode)
    self:SetAnimationWithBlending(animName, self:GetBlendTime(), force)
    
    self.mode = mode
    
    self.modeTime = Shared.GetTime() + self:GetAnimationLength(animName)
       
end

function Player:GetCanBeUsed(player)
    return false
end

function Player:GetScoreboardChanged()
    return self.scoreboardChanged
end

// Set to true when score, name, kills, team, etc. changes so it's propagated to players
function Player:SetScoreboardChanged(state)
    self.scoreboardChanged = state
end

function Player:GetTimeTargetHit()
    return self.timeTargetHit
end

function Player:GetReticleTarget()
    return self.reticleTarget
end

function Player:GetHasSayings()
    return false
end

function Player:GetSayings()
    return {}
end

// Index starts with 1
function Player:ChooseSaying(sayingIndex)
end

function Player:GetShowSayings()
    return self.showSayings
end

function Player:UpdateHelp()
    return false
end

function Player:SpaceClearForEntity(position, printResults)

    local capsuleHeight, capsuleRadius = self:GetTraceCapsule()
    local center = Vector(0, capsuleHeight * 0.5 + capsuleRadius, 0)
    
    local traceStart = position + center
    local traceEnd = traceStart + Vector(0, .1, 0)

    if capsuleRadius == 0 and printResults then    
        Print("%s:SpaceClearForEntity(): capsule radius is 0, returning true.", self:GetClassName())
        return true
    elseif capsuleRadius < 0 and printResults then
        Print("%s:SpaceClearForEntity(): capsule radius is %.2f.", self:GetClassName(), capsuleRadius)
    end
    
    local trace = Shared.TraceCapsule(traceStart, traceEnd, capsuleRadius, capsuleHeight, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    if trace.fraction ~= 1 and printCollision then
        Print("%s:SpaceClearForEntity: Hit %s", self:GetClassName(), SafeClassName(trace.entity))
    end
    
    return (trace.fraction == 1)
    
end

function Player:GetChatSound()
    return Player.kChatSound
end

function Player:GetNumHotkeyGroups()
    
    local numGroups = 0
    
    for i = 1, Player.kMaxHotkeyGroups do
    
        if (table.count(self.hotkeyGroups[i]) > 0) then
        
            numGroups = numGroups + 1
            
        end
        
    end
    
    return numGroups

end

function Player:GetHotkeyGroups()
    return self.hotkeyGroups
end

function Player:GetVisibleWaypoint()
    return self.finalWaypoint
end

// Player is incapacitated briefly
// Note: This is an old version of Knockback. See how it is handled in Weapon.lua.
function Player:Knockback(velocity)

    // Apply force
    self:SetVelocity(self:GetVelocity() + velocity)
    
    // Play animation - can't do anything until we've gotten up
    self:SetAnimAndMode("knockback", kPlayerMode.Knockback)
    
    // No animation yet, so set mode time manually
    self.modeTime = 1.25
    
end


// Overwrite to get player status description
function Player:GetPlayerStatusDesc()
    if (self:GetIsAlive() == false) then
        return "Dead"
    end
    return ""
end

function Player:GetCanGiveDamageOverride()
    return true
end

// Overwrite how players interact with doors
function Player:OnOverrideDoorInteraction(inEntity)
    return true, 4
end

function Player:SetIsUsing (isUsing)
  self.isUsing = isUsing
end

function Player:GetIsUsing ()
  return self.isUsing
end

function Player:GetDarwinMode()
    return self.darwinMode
end

function Player:OnSighted(sighted)
    if (self.GetActiveWeapon) then
        local weapon = self:GetActiveWeapon()
        if (weapon ~= nil) then
            weapon:SetRelevancy(sighted)
        end
    end
end

Shared.LinkClassToMap("Player", Player.kMapName, Player.networkVars )