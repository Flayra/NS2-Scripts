// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/OrderSelfMixin.lua")
Script.Load("lua/DisorientableMixin.lua")

class 'Marine' (Player)

Marine.kMapName = "marine"

if(Server) then
    Script.Load("lua/Marine_Server.lua")
else
    Script.Load("lua/Marine_Client.lua")
end

Marine.kModelName = PrecacheAsset("models/marine/male/male.model")
Marine.kSpecialModelName = PrecacheAsset("models/marine/male/male_special.model")

Marine.kDieSoundName = PrecacheAsset("sound/ns2.fev/marine/common/death")
Marine.kFlashlightSoundName = PrecacheAsset("sound/ns2.fev/common/light")
Marine.kGunPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_gun")
Marine.kJetpackPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_jetpack")
Marine.kSpendResourcesSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")
Marine.kCatalystSound = PrecacheAsset("sound/ns2.fev/marine/common/catalyst")
Marine.kSquadSpawnSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn")
Marine.kChatSound = PrecacheAsset("sound/ns2.fev/marine/common/chat")
Marine.kSoldierLostAlertSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/soldier_lost")

Marine.kFlinchEffect = PrecacheAsset("cinematics/marine/hit.cinematic")
Marine.kFlinchBigEffect = PrecacheAsset("cinematics/marine/hit_big.cinematic")
Marine.kSquadSpawnEffect = PrecacheAsset("cinematics/marine/squad_spawn")

Marine.kJetpackEffect = PrecacheAsset("cinematics/marine/jetpack/jet.cinematic")
Marine.kJetpackTrailEffect = PrecacheAsset("cinematics/marine/jetpack/trail.cinematic")

// Jetpack
Marine.kJetpackStart = PrecacheAsset("sound/ns2.fev/marine/common/jetpack_start")
Marine.kJetpackLoop = PrecacheAsset("sound/ns2.fev/marine/common/jetpack_on")
Marine.kJetpackEnd = PrecacheAsset("sound/ns2.fev/marine/common/jetpack_end")

Marine.kEffectNode = "fxnode_playereffect"
Marine.kHealth = kMarineHealth
Marine.kBaseArmor = kMarineArmor
Marine.kArmorPerUpgradeLevel = kArmorPerUpgradeLevel
Marine.kMaxSprintFov = 95
Marine.kWeaponLiftDelay = .2
// Player phase delay - players can only teleport this often
Marine.kPlayerPhaseDelay = 2

// Overlay animations translate to "weaponname_overlayname" for marines.
// So "fire" translates to "rifle_fire" for marines but "bite" is just "bite" for aliens.
// If marine has no weapon (in ready room), then overlay anims will be just the basic names.
Marine.kAnimOverlayFire = "fire"
Marine.kAnimSprint = "sprint"
Marine.kSprintTime = .5                     // Time it takes to get to top speed
Marine.kUnsprintTime = .25                   // Time it takes to come to rest

Marine.kWalkMaxSpeed = 5                // Four miles an hour = 6,437 meters/hour = 1.8 meters/second (increase for FPS tastes)
Marine.kRunMaxSpeed = 6.0               // 10 miles an hour = 16,093 meters/hour = 4.4 meters/second (increase for FPS tastes)
Marine.kRunInfestationMaxSpeed = 5.2    // 10 miles an hour = 16,093 meters/hour = 4.4 meters/second (increase for FPS tastes)

// Allow JPers to go faster in the air, but still capped
Marine.kAirSpeedMultiplier = 3

// Marine weight scalars (from NS1)
Marine.kStowedWeaponWeightScalar = .7

// How fast does our armor get repaired by marines
Marine.kArmorWeldRate = 12
Marine.kWeldedEffectsInterval = .5

Marine.networkVars = 
{
    sprinting                       = "boolean",
    desiredSprinting                = "boolean",
    setSprintLoop                   = "boolean",
    sprintingScalar                 = "float",  
    timeSprintChange                = "float",
    
    // 0 = no squad, 1-10 is squad number. Make sure it can accomodate kNumSquads.
    squad                           = string.format("integer (0 to %d)", kNumSquads),
    lastSquad                       = string.format("integer (0 to %d)", kNumSquads),
    
    timeOfLastCatPack               = "float",    
    flashlightOn                    = "boolean",
    timeOfLastPhase                 = "float",
    
    // Updated every frame depending if we have a jetpack child object
    hasJetpack                      = "boolean",
    
    // 0 if not using jetpack, time jetpack started being used otherwise
    timeStartedJetpack              = "float",
    
    // If jetpack is currently active and affecting our movement
    jetpacking                      = "boolean",
    
    // 0-1 fuel which fills over time and is depleted when jetpack used
    jetpackFuel                     = "float",
    
    weaponShouldLiftDuration        = "float",
    weaponLiftInactiveTime          = "float",
    nextWeaponLiftCheckTime         = "float",

    waypointOrigin                  = "vector",
    waypointEntityId                = "entityid",
    
    timeOfLastDrop                  = "float",
    inventoryWeight                 = "compensated float"
    
}

PrepareClassForMixin(Marine, GroundMoveMixin)
PrepareClassForMixin(Marine, CameraHolderMixin)
PrepareClassForMixin(Marine, DisorientableMixin)

function Marine:OnCreate()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Player.kFov })
    
    Player.OnCreate(self)
    
    self.inventoryWeight = 0
    
    if (Client) then
   
        // Create the flash light
        
        self.flashlight = Client.CreateRenderLight()
        
        self.flashlight:SetType( RenderLight.Type_Spot )
        self.flashlight:SetColor( Color(.8, .8, 1) )
        self.flashlight:SetInnerCone( math.rad(30) )
        self.flashlight:SetOuterCone( math.rad(35) )
        self.flashlight:SetIntensity( 5 )
        self.flashlight:SetRadius( 15 ) 
        self.flashlight:SetAtmospheric( true )
        
        self.flashlight:SetIsVisible(false) 
    
    end
    
end

function Marine:OnInit()

    Player.OnInit(self)
    
    if Server then
        InitMixin(self, OrderSelfMixin, { kPriorityAttackTargets = { "Harvester" } })
    end
    
    InitMixin(self, DisorientableMixin)
    
    // Calculate max and starting armor differently
    self.armor = 0
    
    if Server then
        self.armor = self:GetArmorAmount()
        self.maxArmor = self.armor
    end
    
    self.squad = 0
    self.timeOfLastCatPack = -1
    self.hasJetpack = false
    self.timeStartedJetpack = 0
    self.jetpacking = false
    self.jetpackFuel = 0
        
    self.weaponLiftTime = 0
    self.weaponDropTime = 0
    self.weaponLiftInactiveTime = 0
    self.weaponShouldLiftDuration = 0
    self.nextWeaponLiftCheckTime = 0
    self.timeOfLastPhase = nil
    
    local viewAngles = self:GetViewAngles()
    self.lastYaw = viewAngles.yaw
    self.lastPitch = viewAngles.pitch
    
    // -1 = leftmost, +1 = right-most
    self.horizontalSwing = 0
    // -1 = up, +1 = down
    
    self.desiredSprinting = false
    self.setSprintLoop = false
    self.sprinting = false
    self.sprintingScalar = 0
    self.timeSprintChange = nil

    self.waypointOrigin = Vector(0, 0, 0)
    self.waypointEntityId = Entity.invalidId
    self.timeOfLastDrop = 0
                    
end

function Marine:GetSlowOnLand()
    return true
end

function Marine:GetArmorAmount()

    local armorLevels = 0
    
    if(GetTechSupported(self, kTechId.Armor3, true)) then
        armorLevels = 3
    elseif(GetTechSupported(self, kTechId.Armor2, true)) then
        armorLevels = 2
    elseif(GetTechSupported(self, kTechId.Armor1, true)) then
        armorLevels = 1
    end
    
    return Marine.kBaseArmor + armorLevels*Marine.kArmorPerUpgradeLevel
    
end

function Marine:OnDestroy()

    Player.OnDestroy(self)

    if (Client) then
    
        if (self.flashlight ~= nil) then
            Client.DestroyRenderLight(self.flashlight)
        end
        
    end

end

function Marine:UpdateJetpack(input)

    if self.hasJetpack then
    
        local jumpPressed = (bit.band(input.commands, Move.Jump) ~= 0)
    
        // Give jetpack energy over time
        self.jetpackFuel = Clamp(self.jetpackFuel + input.time * kJetpackReplenishFuelRate, 0, 1)
    
        // Update jetpack energy
        if self.jetpacking then
        
            self.jetpackFuel = Clamp(self.jetpackFuel - input.time * kJetpackUseFuelRate, 0, 1)
            
            if self.jetpackFuel == 0 or not jumpPressed then
            
                Shared.StopSound(self, Marine.kJetpackStart)
                Shared.StopSound(self, Marine.kJetpackLoop)
                
                if Client then
                    Print(Marine.kJetpackEnd)
                    Shared.PlaySound(self, Marine.kJetpackEnd)
                end
                
                self.jetpacking = false
                
                self.timeStartedJetpack = 0
                
            end
            
            // TODO: Set fuel parameter to give feedback to player about current state
            
        end
        
        if jumpPressed and self.timeStartedJetpack == 0 and self:GetIsOnGround() and not self.jetpacking then
        
            // Start jetpacking
            if Client then
            
                Shared.PlaySound(self, Marine.kJetpackStart)
                
                // Start loop sound if we're not playing it already
                Shared.PlaySound(self, Marine.kJetpackLoop)

            end
            
            self.jetpacking = true
            self.timeStartedJetpack = Shared.GetTime()
                                
        end
        
    else
    
        self.jetpackFuel = 0
        
    end

end

// Called from GroundMoveMixin.
function Marine:ComputeForwardVelocity(input)

    // Call the original function to get the base forward velocity.
    local forwardVelocity = Player.ComputeForwardVelocity(self, input)

    // Modify it only if jetpacking.
    if self.jetpacking then
        forwardVelocity = forwardVelocity + Vector(0, 2, 0)
    end

    return forwardVelocity

end

function Marine:HandleButtons(input)

    PROFILE("Marine:HandleButtons")
    
    if(not self.sprinting) then
    
        Player.HandleButtons(self, input)
    
    else
    
        // Allow show map even when sprinting.
        self:UpdateShowMap(input)
        
    end
    
    // Update sprinting state
    self:UpdateSprintingState(input)
    
    if (bit.band(input.commands, Move.ToggleFlashlight) ~= 0) then
    
        self:SetFlashlightOn( not self:GetFlashlightOn() )
        Shared.PlaySound(self, Marine.kFlashlightSoundName)
        
    end
    
    self:UpdateJetpack(input)
    
end

function Marine:SetFlashlightOn(state)
    self.flashlightOn = state
end

function Marine:GetFlashlightOn()
    return self.flashlightOn
end

function Marine:GetCanIdle()
    return not self.sprinting
end

function Marine:UpdateSprintingState(input)

    PROFILE("Marine:UpdateSprintingState")

    local velocity = self:GetVelocity()
    local speed = velocity:GetLength()
    
    // Allow small little falls to not break our sprint (stairs)    
    self.desiredSprinting = (bit.band(input.commands, Move.MovementModifier) ~= 0) and (speed > 1) and not self.crouching and (self.timeLastOnGround ~= nil and Shared.GetTime() < self.timeLastOnGround + .4) 
    
    if input.move.z < -kEpsilon then
    
        self.desiredSprinting = false
        self.setSprintLoop = false    
        
    else
    
        // Only allow sprinting if we're pressing forward and moving in that direction
        local normMoveDirection = GetNormalizedVectorXZ(self:GetViewCoords():TransformVector( input.move ) )
        local normVelocity = GetNormalizedVectorXZ( velocity )
        local viewFacing = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)

        if normVelocity:DotProduct(normMoveDirection) < .6 or normMoveDirection:DotProduct(viewFacing) < .5 then
            self.desiredSprinting = false
        end
        
    end
    
    if(self.desiredSprinting ~= self.sprinting and self:GetCanNewActivityStart()) then

        local weapon = self:GetActiveWeapon()
        if(weapon ~= nil) then       
 
            local viewModelAnimation = weapon:GetSprintEndAnimation()
            if(self.desiredSprinting) then 
            
                viewModelAnimation = weapon:GetSprintStartAnimation()
                self.setSprintLoop = false    
                
            end
            
            self.timeSprintChange = Shared.GetTime()
            
            // Play it but don't force it if already playing
            local length = self:SetViewAnimation(viewModelAnimation, true, false)
            if length > 0 then
                self:SetActivityEnd( length )
            end
            
            self.sprinting = self.desiredSprinting
            
        end
    
    else
    
        // Play run loop but don't force it if already playing
        if(self.sprinting and self:GetCanNewActivityStart() and not self.setSprintLoop) then
        
            local weapon = self:GetActiveWeapon()
            if weapon ~= nil then
            
                local sprintAnim = weapon:GetSprintAnimation()
                local length = self:SetViewAnimation(sprintAnim, true, false)
                self.setSprintLoop = true

            end
            
        end
        
    end
    
    // Update sprinting scalar
    if self.timeSprintChange ~= nil then
    
        if self.desiredSprinting then
            self.sprintingScalar = Clamp((Shared.GetTime() - self.timeSprintChange)/Marine.kSprintTime, 0, 1)
        else
            self.sprintingScalar = 1 - Clamp((Shared.GetTime() - self.timeSprintChange)/Marine.kUnsprintTime, 0, 1)
        end
        
    else
        self.sprintingScalar = 0
    end

    // Update fov as we're sprinting
    //self:SetFov(Player.kFov + self.sprintingScalar*(Marine.kMaxSprintFov - Player.kFov))
    
end

function Marine:GetCanViewModelIdle()
    return Player.GetCanViewModelIdle(self) and not self.sprinting
end

// Check if friendly or world obstacle is in front of us so we can swing up our weapon for cool factor
function Marine:UpdateLiftWeapon(input)

    PROFILE("Marine:UpdateWeaponLift")

    local activeWeapon = self:GetActiveWeapon()
    local time = Shared.GetTime()
    
    if(activeWeapon and (self.nextWeaponLiftCheckTime == 0) or time > self.nextWeaponLiftCheckTime) then
    
        self.nextWeaponLiftCheckTime = time + .25
        
        local viewCoords = self:GetViewAngles():GetCoords()
        
        // Don't lift weapon when we're looking up or down
        local viewNonVertical = GetNormalizedVector(Vector(viewCoords.zAxis.x, 0, viewCoords.zAxis.z))
        if viewNonVertical:DotProduct(viewCoords.zAxis) > .7 then
        
            local startPoint = self:GetEyePos()
            local endPoint = startPoint + viewCoords.zAxis * 2
            
            local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))
            if(trace.fraction ~= 1 and (trace.entity == nil or trace.entity:GetTeamNumber() ~= GetEnemyTeamNumber(self:GetTeamNumber()))) then
            
                self.weaponShouldLiftDuration = self.weaponShouldLiftDuration + input.time
                return
                
            end
            
        end 
       
    end
    
    self.weaponShouldLiftDuration = 0
    
end

function Marine:GetShouldLiftWeapon()
    return (self.weaponShouldLiftDuration > Marine.kWeaponLiftDelay) and self:GetVelocity():GetLength() < .5 
end

function Marine:CanDrawWeapon()
    return not self.sprinting
end

function Marine:GetSquad()
    return self.squad
end

function Marine:SetSquad(squadIndex)
    self.squad = squadIndex
end

function Marine:GetWeaponInHUDSlot(slot)
    
    local weapon = nil
    
    local childEntities = GetChildEntities(self, "Weapon")
    
    if(table.maxn(childEntities) > 0) then
    
        for index, entity in ipairs(childEntities) do
            
            if(entity:GetHUDSlot() == slot) then
            
                weapon = entity
                break
                
            end
                
        end
    
    end
    
    return weapon
    
end

function Marine:GetCanJump()
    return Player.GetCanJump(self) and not self.sprinting
end

// Take into account our weapon inventory and current weapon
function Marine:GetInventorySpeedScalar()
    return 1 - self.inventoryWeight
end

function Marine:UpdateSharedMisc(input)
    Player.UpdateSharedMisc(self, input)
    self:UpdateInventoryWeight()
end

function Marine:UpdateInventoryWeight()

    // Loop through all weapons, getting weight of each one
    local totalWeight = 0
    
    local activeWeapon = self:GetActiveWeapon()
    local weaponList = self:GetHUDOrderedWeaponList()
    for index = 1, table.count(weaponList) do

        local weapon = weaponList[index]
        local weaponWeight = ConditionalValue(activeWeapon and (weapon:GetId() == activeWeapon:GetId()), weapon:GetWeight(), weapon:GetWeight() * Marine.kStowedWeaponWeightScalar)
        
        // Active items count full, count less when stowed 
        totalWeight = totalWeight + weaponWeight
            
    end            
    
    self.inventoryWeight = Clamp(totalWeight, 0, 1)

end

function Marine:GetMaxSpeed()

    local onInfestation = self:GetGameEffectMask(kGameEffect.OnInfestation)
    local maxSprintSpeed = ConditionalValue(onInfestation, Marine.kWalkMaxSpeed + (Marine.kRunInfestationMaxSpeed - Marine.kWalkMaxSpeed)*self.sprintingScalar, Marine.kWalkMaxSpeed + (Marine.kRunMaxSpeed - Marine.kWalkMaxSpeed)*self.sprintingScalar)
    local maxSpeed = ConditionalValue(self.sprinting, maxSprintSpeed, Marine.kWalkMaxSpeed)
    
    // Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local inventorySpeedScalar = self:GetInventorySpeedScalar() + .17

    // Take into account crouching
    maxSpeed = ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar ) * maxSpeed

    local adjustedMaxSpeed = maxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier() * inventorySpeedScalar 
    //Print("Adjusted max speed => %.2f (without inventory: %.2f)", adjustedMaxSpeed, adjustedMaxSpeed / inventorySpeedScalar )
    return adjustedMaxSpeed
    
end

function Marine:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocity():GetLength() / (Marine.kRunMaxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier()), 0, 1)
end

function Marine:GetAcceleration()
    return ConditionalValue(self.sprinting, Player.kRunAcceleration, Player.kAcceleration)
end

// Returns -1 to 1
function Marine:GetWeaponSwing()
    return self.horizontalSwing
end

function Marine:UpdateWeaponSwing(input)

    PROFILE("Marine:UpdateWeaponSwing")

    // Update to the current view angles.    
    local viewAngles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)

    local activeWeapon = self:GetActiveWeapon()
    local viewModel = self:GetViewModelEntity()
    
    if(activeWeapon ~= nil and viewModel ~= nil) then

        // Look at difference between previous and current angles to add "swing" to view model
        local swingSensitivity = activeWeapon:GetSwingSensitivity()
        local yawDiff = GetAnglesDifference(self.lastYaw, viewAngles.yaw)
        self.horizontalSwing = self.horizontalSwing + yawDiff*swingSensitivity

        // Decrease it non-linearly over time (the farther off center it is the faster it will return)
        local kHorizontalSwingDampening = 100*input.time*math.sin((math.abs(self.horizontalSwing)/45)*math.pi/2)

        if(self.horizontalSwing < 0) then
            self.horizontalSwing = math.min(math.max(self.horizontalSwing + kHorizontalSwingDampening, -1), 0)
        elseif(self.horizontalSwing > 0) then
            self.horizontalSwing = math.max(math.min(self.horizontalSwing - kHorizontalSwingDampening, 1), 0)
        end

        // Calculate swing pitch (moves view model down as player looks up and vice-versa)
        // Parameter goes from -45 to 45
        local pitchDegrees = math.deg(viewAngles.pitch) 
        if pitchDegrees > 90 then
            pitchDegrees = pitchDegrees - 360
        end
        local swingPitch = -(pitchDegrees * 2 / 90) * 45
    
        viewModel:SetPoseParam(Weapon.kSwingYaw, self.horizontalSwing * activeWeapon:GetSwingAmount())
        
        // Don't use until we have this pose parameter in every weapon animation
        //viewModel:SetPoseParam(Weapon.kSwingPitch, swingPitch)
        
    end
    
    self.lastYaw = viewAngles.yaw
    self.lastPitch = viewAngles.pitch

end

function Marine:ConstrainMoveVelocity(moveVelocity)   

    Player.ConstrainMoveVelocity(self, moveVelocity)
    
    local activeWeapon = self:GetActiveWeapon()

    if(activeWeapon ~= nil) then
        moveVelocity = activeWeapon:ConstrainMoveVelocity(moveVelocity)
    end
    
end

// Set to true or false every frame
function Marine:SetWeaponLift(weaponLift)

    local prevWeaponLift = self.weaponLiftTime
    local prevWeaponDrop = self.weaponDropTime
    local time = Shared.GetTime()
    
    // If time in the future, don't allow weapon lift until it has passed
    if(time >= self.weaponLiftInactiveTime) then
    
        if(weaponLift and (self.weaponLiftTime == 0)) then
            self.weaponLiftTime = time
            self.weaponDropTime = 0
        elseif(not weaponLift and (self.weaponLiftTime ~= 0)) then
            self.weaponLiftTime = 0
            self.weaponDropTime = time
        end
        
    end
    
end

// Call when firing weapon so it doesn't happen for a bit
function Marine:DeactivateWeaponLift(delay)
    local timeDelay = ConditionalValue(delay ~= nil, delay, 2)
    self.weaponLiftInactiveTime = Shared.GetTime() + timeDelay
    self.weaponLiftTime = 0
    self.weaponDropTime = 0
    self.weaponShouldLiftDuration = 0
end

function Marine:GetWeaponLiftTime()
    return self.weaponLiftTime
end

function Marine:GetWeaponDropTime()
    return self.weaponDropTime
end

function Marine:UpdateMoveAnimation()
    if(self.sprinting) then
        self:SetAnimationWithBlending(Marine.kAnimSprint)
    else
        self:SetAnimationWithBlending(Player.kAnimRun)
    end
    
end

function Marine:UpdateMisc(input)

    PROFILE("Marine:UpdateMisc")

    if not Shared.GetIsRunningPrediction() then
    
        /*
        // Removed weapon swing until we get feel nailed
        self:UpdateWeaponSwing(input)
        */
        
        if(self.sprinting) then
            self:SetAnimationWithBlending(Marine.kAnimSprint)
        else
            self:UpdateLiftWeapon(input)
            self:SetWeaponLift(self:GetShouldLiftWeapon())
        end

    end    
            
    Player.UpdateMisc(self, input)
        
end

function Marine:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 

        // Show orders     
        techButtons = { kTechId.SquadAttack, kTechId.SquadMove, kTechId.SquadDefend, kTechId.None,
                        kTechId.SquadSeekAndDestroy, kTechId.SquadHarass, kTechId.SquadRegroup, kTechId.None }
        
    end
    
    return techButtons
 
end

function Marine:GetIsCatalysted()
    return (self.timeOfLastCatPack ~= -1) and (Shared.GetTime() > (self.timeOfLastCatPack - CatPack.kDuration))
end

function Marine:GetCatalystFireModifier()
    return ConditionalValue(self:GetIsCatalysted(), CatPack.kWeaponDelayModifer, 1)
end

function Marine:GetCatalystMoveSpeedModifier()
    return ConditionalValue(self:GetIsCatalysted(), CatPack.kMoveSpeedScalar, 1)
end

function Marine:GetHasSayings()
    return true
end

// Other
function Marine:GetSayings()

    if(self.showSayings) then
    
        if(self.showSayingsMenu == 1) then
            return marineRequestSayingsText
        end
        if(self.showSayingsMenu == 2) then
            return marineGroupSayingsText
        end
        if(self.showSayingsMenu == 3) then
            return GetVoteActionsText(self:GetTeamNumber())
        end
        
    end
    
    return nil
    
end

function Marine:ExecuteSaying(index, menu)

    if not Player.ExecuteSaying(self, index, menu) then

        if(Server) then
        
            if menu == 3 then
                GetGamerules():CastVoteByPlayer( voteActionsActions[index], self )
            else
            
                local sayings = marineRequestSayingsSounds
                local sayingActions = marineRequestActions
                
                if(menu == 2) then
                    sayings = marineGroupSayingsSounds
                    sayingActions = marineGroupRequestActions
                end

                self:PlaySound(sayings[index])
                
                local techId = sayingActions[index]
                if techId ~= kTechId.None then
                    self:GetTeam():TriggerAlert(techId, self)
                end
                
            end
            
        end
        
    end
    
end

function Marine:GetChatSound()
    return Marine.kChatSound
end

function Marine:GetDeathMapName()
    return MarineSpectator.kMapName
end

function Marine:UpdateHelp()

    local activeWeaponName = self:GetActiveWeaponName()   
    local activeWeapon = self:GetActiveWeapon()
    local outOfAmmo = (activeWeapon ~= nil and activeWeapon:isa("ClipWeapon") and activeWeapon:GetClip() == 0 and activeWeapon:GetAmmo() == 0)
    
    if self:AddTooltipOnce("You are now a marine! Press left-click to fire your rifle, right-click for a melee attack.") then
        return true
    elseif self:AddTooltipOnce("Hold your shift key while pressing forward to sprint.") then
        return true
    elseif activeWeaponName == "Pistol" and self:AddTooltipOnce("Press left-click to fire your pistol, right-click to switch to a slower more accurate mode.") then
        return true
    elseif activeWeaponName == "Axe" and self:AddTooltipOnce("The axe is especially effective against structures.") then
        return true
    elseif outOfAmmo and self:AddTooltipOnce("You are out of ammo - get more at an Armory.") then
        return true
    elseif (self:GetHealthScalar() < .4) and self:AddTooltipOnce("You are hurt - go to an Armory or pick up a health pack from the Commander.") then
        return true
    end
    
    return false
    
end

// Pass entity id or vector of world origin
function Marine:SetWaypoint(waypoint)

    if destwaypoint:isa("Vector") then
    
        self.waypointOrigin = waypoint
        self.waypointEntityId = Entity.invalidId
        
    else
    
        self.waypointOrigin = Vector(0, 0, 0)
        self.waypointEntityId = waypoint
        
    end
    
end

// Returns the name of the primary weapon
function Marine:GetPlayerStatusDesc()

    local status = ""
    
    if (self:GetIsAlive() == false) then
        return "Dead"
    end
    
    local weapon = self:GetWeaponInHUDSlot(1)
    if (weapon) then
        if (weapon:isa("GrenadeLauncher")) then
            return "Grenade Launcher"
        elseif (weapon:isa("Rifle")) then
            return "Rifle"
        elseif (weapon:isa("Shotgun")) then
            return "Shotgun"
        elseif (weapon:isa("Flamethrower")) then
            return "Flamethrower"
        end
    end
    
    return status
end

function Marine:GetCanDropWeapon(weapon)

    if not weapon then
        weapon = self:GetActiveWeapon()
    end
    
    if( weapon ~= nil and weapon.GetIsDroppable and weapon:GetIsDroppable() ) then
    
        // Don't drop weapons too fast
        if self.timeOfLastDrop == 0 or (Shared.GetTime() > self.timeOfLastDrop + 1.5) then
            return true
        end
        
    end
    
    return false
    
end

// Do basic prediction of the weapon drop on the client so that any client
// effects for the weapon can be dealt with
function Marine:Drop(weapon)

    local activeWeapon = self:GetActiveWeapon()
    
    if not weapon then
        weapon = activeWeapon
    end

    if weapon == activeWeapon then
        self:SelectNextWeapon()
    end
    
    if self:GetCanDropWeapon(weapon) then
        
        weapon:OnPrimaryAttackEnd(self)
    
        // Remove from player's inventory
        if Server then
            self:RemoveWeapon(weapon)
        end
        
        // Make sure we're ready to deploy new weapon so we switch to it properly
        self:ClearActivity()
        
        if Server then
            local weaponSpawnPoint = self:GetAttachPointOrigin(Weapon.kHumanAttachPoint)
            weapon:SetOrigin(weaponSpawnPoint)
        end
        
        // Tell weapon not to be picked up again for a bit
        weapon:Dropped(self)
        
        // Set activity end so we can't drop like crazy
        self.timeOfLastDrop = Shared.GetTime() 
        
        return true
        
    end
    
    return false

end

function Marine:GetCanBeUsed()

    // Allow team-mates to fix our armor 
    if self:GetIsAlive() and (self.armor < self.maxArmor) then
        return true
    end
    
    return Player.GetCanBeUsed(self)
    
end

function Marine:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    // Allow others to repair our armor
    if self:GetArmor() < self:GetMaxArmor() then
    
        self:SetArmor( self:GetArmor() + elapsedTime * Marine.kArmorWeldRate )
    
        // Trigger welding effects occassionally
        if Server then
        
            if not self.timeOfNextWeldedEffects or (Shared.GetTime() > self.timeOfNextWeldedEffects) then
            
                self:TriggerEffects("marine_welded", {effecthostcoords = BuildCoordsFromDirection(player:GetViewCoords().zAxis, usePoint), false})
                self.timeOfNextWeldedEffects = Shared.GetTime() + Marine.kWeldedEffectsInterval
                
            end
            
            // Give a point for restoring to full armor
            if self:GetArmor() == self:GetMaxArmor() then
                player:AddScore(kRepairMarineArmorPointValue)
            end
            
        end
        
        return true
        
    end
    
    return Player.OnUse(self, player, elapsedTime, useAttachPoint, usePoint)
    
end

// No animations for it yet
function Marine:Taunt()
end

Shared.LinkClassToMap( "Marine", Marine.kMapName, Marine.networkVars )