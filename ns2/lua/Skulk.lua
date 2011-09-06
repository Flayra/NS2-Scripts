// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/BiteLeap.lua")
Script.Load("lua/Weapons/Alien/Parasite.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/StunMixin.lua")

class 'Skulk' (Alien)

Skulk.kMapName = "skulk"

Skulk.kModelName = PrecacheAsset("models/alien/skulk/skulk.model")
Skulk.kViewModelName = PrecacheAsset("models/alien/skulk/skulk_view.model")

Skulk.kIdleSound = PrecacheAsset("sound/ns2.fev/alien/skulk/idle")

if Server then
    Script.Load("lua/Skulk_Server.lua", true)
elseif Client then
    Script.Load("lua/Skulk_Client.lua", true)
end

Skulk.networkVars = 
{
    wallWalking                 = "compensated boolean",
    timeLastWallWalkCheck       = "float",
    leaping                     = "compensated boolean",
    timeOfLeap                  = "float",
    leapingAnimationPlaying     = "compensated boolean",
    wallWalkingNormalGoal       = "compensated vector",
    wallWalkingNormalCurrent    = "compensated vector",
    wallWalkingStickGoal        = "compensated vector",
    wallWalkingStickEnabled     = "compensated boolean"
}

// Balance, movement, animation
Skulk.kJumpRepeatTime = .25
Skulk.kViewOffsetHeight = .55
Skulk.kHealth = kSkulkHealth
Skulk.kArmor = kSkulkArmor
Skulk.kLeapVerticalVelocity = 4
Skulk.kLeapTime = 0.2
// kLeapPreventStickTime is used as a time period not to stick to walls after leaping.
Skulk.kLeapPreventStickTime = 0.05
Skulk.kLeapForce = 10
Skulk.kMaxSpeed = 7 // 8.7
Skulk.kMaxWalkSpeed = Skulk.kMaxSpeed / 2
Skulk.kLeapSpeed = 25
Skulk.kAcceleration = 65
Skulk.kFov = 110
Skulk.kMass = 45 // ~100 pounds
Skulk.kWallWalkCheckInterval = .2
// This is how quickly the 3rd person model will adjust to the new normal.
Skulk.kWallWalkNormalSmoothRate = 6
// How big the spheres are that are casted out to find walls, "feelers".
Skulk.kWallWalkingFeelerSize = 0.1
Skulk.kNormalWallWalkRange = 0.2
Skulk.kStickyWallWalkRange = 0.5
Skulk.kXExtents = .45
Skulk.kYExtents = .45
Skulk.kZExtents = .45
Skulk.kAnimWallRun = "wallrun"
// Override jump animations with leap (it's a regular jump with different physics)
Skulk.kAnimStartLeap = "leap_start"
Skulk.kAnimEndLeap = "leap_end"
Skulk.kAnimLeap = "leap"

PrepareClassForMixin(Skulk, GroundMoveMixin)
PrepareClassForMixin(Skulk, CameraHolderMixin)
// The Skulk can be stunned in melee attacked while it is in the air.
// See GetIsKnockbackAllowed() below for more.
PrepareClassForMixin(Skulk, StunMixin)

function Skulk:OnInit()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Skulk.kFov })
    InitMixin(self, StunMixin)
    
    Alien.OnInit(self)
    
    // Idle always plays and has a speed param updated below
    Shared.PlaySound(self, Skulk.kIdleSound)
    
    self.wallWalking = false
    self.wallWalkingNormalCurrent = Vector.yAxis
    self.wallWalkingNormalGoal    = Vector.yAxis
    
    if Client then
        self.currentCameraRoll = 0
        self.goalCameraRoll    = 0
    end
    
    self.leaping = false
    self.leapingAnimationPlaying = false

end

function Skulk:OnDestroy()

    Alien.OnDestroy(self)
    
    Shared.StopSound(self, Skulk.kIdleSound)
    
end

function Skulk:GetBaseArmor()
    return Skulk.kArmor
end

function Skulk:GetArmorFullyUpgradedAmount()
    return kSkulkArmorFullyUpgradedAmount
end

function Skulk:GetMaxViewOffsetHeight()
    return Skulk.kViewOffsetHeight
end

function Skulk:GetCrouchShrinkAmount()
    return 0
end

function Skulk:GetAirMoveScalar()
    return 1.0
end

// The Skulk movement should factor in the vertical velocity
// only when wall walking.
function Skulk:GetMoveSpeedIs2D()
    return not self:GetIsWallWalking()
end

function Skulk:OnLeap()

    local velocity = self:GetVelocity()

    local forwardVec = self:GetViewAngles():GetCoords().zAxis
    local newVelocity = velocity + forwardVec * Skulk.kLeapForce
    
    // Add in vertical component.
    newVelocity.y = newVelocity.y + Skulk.kLeapVerticalVelocity
    
    self:SetVelocity(newVelocity)
    
    self.leaping = true
    self.timeOfLeap = Shared.GetTime()
    
    self:SetOverlayAnimation(Skulk.kAnimStartLeap)
    self:SetActivityEnd(Skulk.kLeapTime)
    
end

function Skulk:GetViewModelName()
    return Skulk.kViewModelName
end

function Skulk:GetCanJump()
    return self:GetIsOnGround() or self:GetIsWallWalking()
end

function Skulk:GetIsWallWalking()
    return self.wallWalking
end

function Skulk:GetIsLeaping()
    return self.leaping
end

// Skulks do not respect ladders due to their wall walking superiority.
function Skulk:GetIsOnLadder()
    return false
end

function Skulk:UpdateMoveAnimation()

    if( self:GetIsOnGround() ) then
    
        self:SetAnimationWithBlending(Player.kAnimRun)
        
    elseif(self:GetIsWallWalking()) then
        
        self:SetAnimationWithBlending(Skulk.kAnimWallRun)
        
    end
    
    self:UpdateMoveSounds()
    
end

function Skulk:UpdateMoveSounds()

    // TODO: 
    //local currSpeed = self:GetVelocity():GetLength() / self:GetMaxSpeed()
    //self:SetSoundParameter(Skulk.kMetalLayer, "speed", currSpeed, 10)
    
end

// When leaping, override jump animations
function Skulk:GetCustomAnimationName(animName)

    if(self.leaping or self.leapingAnimationPlaying) then

        if (animName == Player.kAnimStartJump) then
            // Leaping animation has started.
            self.leapingAnimationPlaying = true
            return Skulk.kAnimStartLeap
            
        elseif (animName == Player.kAnimJump) then
            return Skulk.kAnimLeap
            
        elseif (animName == Player.kAnimEndJump) then
            // When the current animation is end jump and it is over, the animation is over.
            if (self:GetCustomAnimationName() == Player.kAnimEndJump and self:GetOverlayAnimationFinished()) then
                self.leapingAnimationPlaying = false
            end
            return Skulk.kAnimEndLeap
        end
        
    end
    
    return Alien.GetCustomAnimationName(self, animName)

end

// Update wall-walking from current origin
function Skulk:PreUpdateMove(input, runningPrediction)

    PROFILE("Skulk:PreUpdateMove")

    local angles = Angles(self:GetAngles())
    
    // Crouching turns off wallwalking like in NS
    if self.crouching or self:GetRecentlyWallJumped() or self:GetLeapPreventWallStick() then
    
        self.wallWalking = false
        
    else

        // Don't check wall walking every frame for performance    
        if (Shared.GetTime() > (self.timeLastWallWalkCheck + Skulk.kWallWalkCheckInterval)) then

            // Most of the time, it returns a fraction of 0, which means
            // trace started outside the world (and no normal is returned)           
            local goal = self:GetAverageWallWalkingNormal(Skulk.kNormalWallWalkRange)
            
            if goal ~= nil then
                self.wallWalkingNormalGoal = goal
                self.wallWalkingStickGoal = goal
                self.wallWalkingStickEnabled = true
                self.wallWalking = true
            // If not on the ground, check for a wall a bit further away and move towards it like a magnet.
            elseif not self:GetIsOnGround() then
                // If the player is trying to stick to the wall put some extra
                // effort into keeping them on it.
                local stickDirectionGoal = self:GetAverageWallWalkingNormal(Skulk.kStickyWallWalkRange)
                if stickDirectionGoal then
                    self.wallWalkingNormalGoal = stickDirectionGoal
                    self.wallWalkingStickGoal = stickDirectionGoal
                    self.wallWalkingStickEnabled = true
                    self.wallWalking = true
                else
                    self.wallWalking = false
                end
            end
            
            self.timeLastWallWalkCheck = Shared.GetTime()
            
        end 
    
    end
    
    local smoothMultiplier = 1
    if self.wallWalking == false then
        // When not wall walking, the goal is always directly up (running on ground).
        self.wallWalkingNormalGoal = Vector.yAxis
        self.wallWalkingStickGoal = nil
        self.wallWalkingStickEnabled = false
        // Smooth out faster when not wall walking.
        smoothMultiplier = 3
    end

    if self.leaping and (Alien.GetIsOnGround(self) or self.wallWalking) and (Shared.GetTime() > self.timeOfLeap + Skulk.kLeapTime) then
        self.leaping = false
    end

    // Smooth out the normal.
    local normalDiff = self.wallWalkingNormalGoal - self.wallWalkingNormalCurrent
    // Check if the vectors are polar opposites.
    if self.wallWalkingNormalGoal:DotProduct(self.wallWalkingNormalCurrent) == -1 then
        // Prefer spinning around the x axis.
        if self:GetCoords().xAxis:DotProduct(self.wallWalkingNormalGoal) ~= -1 then
            normalDiff = self.wallWalkingNormalGoal - self:GetCoords().xAxis
        else
            normalDiff = self.wallWalkingNormalGoal - self.wallWalkingNormalCurrent:GetPerpendicular()
        end
    end
    
    self.wallWalkingNormalCurrent = self.wallWalkingNormalCurrent + (normalDiff * (input.time * Skulk.kWallWalkNormalSmoothRate * smoothMultiplier))

    if self.wallWalkingNormalCurrent:Normalize() < 0.01 then
        self.wallWalkingNormalCurrent = Vector(0, 1, 0)  
    end
    
    // Build out the orientation.
    
    local viewCoords = self:GetViewCoords()
    local coords     = Coords()
    
    coords.yAxis = self.wallWalkingNormalCurrent
    
    // Try to align the forward direction with our view forward direction
    coords.zAxis = viewCoords.zAxis

    coords.xAxis = coords.yAxis:CrossProduct( coords.zAxis )
    if (coords.xAxis:Normalize() < 0.01) then
        // We have to choose the x-axis arbitrarily since we're
        // looking along the normal direction.
        coords.xAxis = coords.yAxis:GetPerpendicular()
    end
    
    coords.zAxis = coords.xAxis:CrossProduct( coords.yAxis )
    angles:BuildFromCoords(coords)
    
    self:SetAngles(angles)
    
    // Make sure the Skulk isn't intersecting with any geometry.
    if self.wallWalking == true then
        self:PreventWallWalkIntersection(input.time)
    end

end

function Skulk:UpdatePosition(velocity, time)

    // Fallback on default behavior when on the ground.
    if self:GetIsOnGround() then
        return Alien.UpdatePosition(self, velocity, time)
    end
    
    // We need to make a copy so that we aren't holding onto a reference
    // which is updated when the origin changes.
    local start = Vector(self:GetOrigin())

    // First move the Skulk upwards from their current orientation to go over small obstacles. 
    local offset = nil
    local stepHeight = self:GetStepHeight()

    // Handle when we're interpenetrating an object usually due to animation. Ie we're under a hive that's breathing into us
    // or when we're standing on top of animated structures like Hives, Extractors, etc.
    local stuck = self:GetIsStuck()
    if stuck then    
        self:Unstick()
    end

    // First try moving capsule half the desired distance.
    self:PerformMovement(velocity * time * 0.5, 10, nil)
    
    // Then attempt to run over objects in the way.
    self:PerformMovement( self:GetCoords().yAxis * stepHeight, 1 )
    offset = self:GetOrigin() - start

    // Complete the move.
    self:PerformMovement(velocity * time * 0.5, 10, nil)

    // Finally, move the skulk back down to compensate for moving them up.
    // We add in an additional step height for moving down steps/ramps.
    offset = -(self:GetCoords().yAxis * stepHeight)
    self:PerformMovement( offset, 1, nil, true )
    
    // Move towards the stick goal if there is a stick goal.
    if self.wallWalkingStickEnabled and self.wallWalkingStickGoal then
        self:PerformMovement(-self.wallWalkingStickGoal * (time * 2), 1, nil)
    end
    
    return velocity

end


function Skulk:PreventWallWalkIntersection(dt)
    
    PROFILE("Skulk:PreventWallWalkIntersection")
    
    // Try moving skulk in a few different directions until we're not intersecting.
    local intersectDirections = { self:GetCoords().xAxis,
                                  -self:GetCoords().xAxis,
                                  self:GetCoords().zAxis,
                                  -self:GetCoords().zAxis }
    
    local originChanged = 0
    local length = self:GetExtents():GetLength()
    local origin = self:GetOrigin()
    for index, direction in ipairs(intersectDirections) do
    
        local extentsDirection = length * 0.75 * direction
        local trace = Shared.TraceRay(origin, origin + extentsDirection, self:GetMovePhysicsMask(), EntityFilterOne(self))
        if trace.fraction < 1 then
            self:PerformMovement((-extentsDirection * dt * 5 * (1 - trace.fraction)), 3)
        end

    end

end

function Skulk:UpdateCrouch()

    // Skulks cannot crouch!
    
end

function Skulk:AdjustModelCoords(modelCoords)

    if(self.wallWalking == true) then        
        local offset = (self:GetOrigin() - self:GetModelOrigin()):GetLength()
        local angles = self:GetAngles()
        // The addOffset to is take into account the extra offset when upside down
        local addOffset = (math.abs(angles.roll) - (math.pi / 2)) / math.pi
        modelCoords.origin = modelCoords.origin + Vector(self.wallWalkingNormalCurrent * -(offset + addOffset))
    end
    
end

function Skulk:GetMaxSpeed()

    local success, speed = self:GetCamouflageMaxSpeed(self.movementModiferState)
    if success then
        return speed
    end
    
    local maxspeed = 0

    if self.leaping then
        maxspeed = Skulk.kLeapSpeed
    else
        maxspeed = ConditionalValue(self.movementModiferState, Skulk.kMaxWalkSpeed, Skulk.kMaxSpeed)
    end
    
    return maxspeed * self:GetSlowSpeedModifier()
    
end

function Skulk:GetAcceleration()
    return Skulk.kAcceleration
end

function Skulk:GetMass()
    return Skulk.kMass
end

function Skulk:TraceWallNormal(startPoint, endPoint, normals)
    
    local theTrace = Shared.TraceCapsule(startPoint, endPoint, Skulk.kWallWalkingFeelerSize, Skulk.kWallWalkingFeelerSize, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    // Don't allow wall-walking on entities    
    if (theTrace.fraction > 0 and theTrace.fraction < 1 and theTrace.entity == nil) then
    
        table.insert(normals, theTrace.normal)
        return true
        
    end
    
    return false
    
end

/**
 * Returns the average normal within wall-walking range. Perform 8 trace lines in circle around us and 1 above us, but not below.
 * Returns nil if we aren't in range of a valid wall-walking surface.  For any surfaces hit, remember surface normal and average 
 * with others hit so we know if we're wall-walking and the normal to orient our model and the direction to jump away from
 * when jumping off a wall.
 */
function Skulk:GetAverageWallWalkingNormal(extraRange)
    
    local startPoint = Vector(self:GetOrigin())
    local extents = self:GetExtents()
    startPoint.y = startPoint.y + extents.y

    local numTraces = 8
    local wallNormals = {}
    
    // Trace in a circle around Skulk, looking for walls we hit
    local wallWalkingRange = math.max(extents.x, extents.y) + extraRange
    local endPoint = Vector()
    
    for i = 0, numTraces - 1 do
    
        local angle = ((i * 360/numTraces) / 360) * math.pi * 2
        local directionVector = Vector(math.cos(angle), 0, math.sin(angle))
        
        // Avoid excess vector creation
        endPoint.x = startPoint.x + directionVector.x * wallWalkingRange
        endPoint.y = startPoint.y
        endPoint.z = startPoint.z + directionVector.z * wallWalkingRange
        self:TraceWallNormal(startPoint, endPoint, wallNormals)
        
    end
    
    // Trace above too.
    self:TraceWallNormal(startPoint, startPoint + Vector(0, wallWalkingRange, 0), wallNormals)
    
    // Average results
    local numNormals = table.maxn(wallNormals)
    
    if (numNormals > 0) then
    
        // Check if the Skulk is right above a surface it can stand on.
        // Even if the Skulk is in "wall walking mode", we want it to look
        // like it is standing on a surface if it is right above it.
        local groundTrace = Shared.TraceRay(startPoint, startPoint + Vector(0, -wallWalkingRange, 0), PhysicsMask.AllButPCs, EntityFilterOne(self))
        if (groundTrace.fraction > 0 and groundTrace.fraction < 1 and groundTrace.entity == nil) then
            return groundTrace.normal
        end
        
        local average = Vector(0, 0, 0)
    
        for i,currentNormal in ipairs(wallNormals) do
            average = average + currentNormal
        end
        
        if (average:Normalize() > 0) then
            return average
        end
        
    end
    
    return nil
    
end

/**
 * Don't allow us to jump too quickly to avoid multiple jumps off the same
 * surface (as we can jump off a wall when we're not actually touching it,
 * including right after we jumped). Also, don't start sticking to a wall
 * too soon after we jumped or it will slow us down.
 */
function Skulk:GetRecentlyWallJumped()
    return not (self.timeOfLastJump == nil or (Shared.GetTime() > (self.timeOfLastJump + Skulk.kJumpRepeatTime)))
end

/**
 * Do not allow sticking to a wall right after leaping.
 */
function Skulk:GetLeapPreventWallStick()
    return self.timeOfLeap ~= nil and Shared.GetTime() < self.timeOfLeap + Skulk.kLeapPreventStickTime
end

function Skulk:GetFrictionForce(input, velocity)

    local frictionForce = nil

    if self:GetIsWallWalking() then    
    
        // No gravity when wall walking so increase friction
        frictionForce = Vector(-velocity.x, -velocity.y, -velocity.z) * 5
        
    else 
        frictionForce = Alien.GetFrictionForce(self, input, velocity)
    end   
    
    return frictionForce
    
end

function Skulk:AdjustGravityForce(input, gravity)

    // No gravity when we're sticking to a wall.
    if self:GetIsWallWalking() then
        gravity = 0
    end
    
    return gravity
    
end

function Skulk:GetMoveDirection(moveVelocity)

    // Don't constrain movement to XZ so we can walk smoothly up walls
    if self:GetIsWallWalking() then
        return GetNormalizedVector(moveVelocity)
    end
    
    return Alien.GetMoveDirection(self, moveVelocity)
    
end

/**
 * Don't allow full air control but account for wall-walking.
 */
function Skulk:ConstrainMoveVelocity(moveVelocity)
    
    if not self:GetIsOnGround() and not self:GetIsWallWalking() then
        Alien.ConstrainMoveVelocity(self, moveVelocity)
    end
    
end

// Normally players moving backwards can't go full speed, but wall-walking skulks can
function Skulk:GetMaxBackwardSpeedScalar()
    return ConditionalValue(self:GetIsWallWalking(), 1, Alien.GetMaxBackwardSpeedScalar(self))
end

function Skulk:ClampSpeed(input, velocity)

    if self:GetIsWallWalking() then
    
        // Clamp XYZ speed
        local moveSpeed = velocity:GetLength()
        local maxSpeed = self:GetMaxSpeed()
        
        if (moveSpeed > maxSpeed) then
        
            velocity:Scale( maxSpeed / moveSpeed )
            
        end 

    else
    
        // Otherwise clamp XZ
        velocity = Alien.ClampSpeed(self, input, velocity)
        
    end    
    
    return velocity
    
end

function Skulk:GetIsCloseToGround(distanceToGround)

    if self:GetIsWallWalking() then
        return false
    end
    
    return Alien.GetIsCloseToGround(self, distanceToGround)
    
end

/*
function Skulk:HandleJump(input, velocity)

    // Normal jump
    if (self:GetIsOnGround()) then

        Alien.HandleJump(self, input, velocity)

    // Jumping off wall            
    elseif (self.wallWalking and not self:GetRecentlyWallJumped()) then

        // If we're not moving much, leap straight off the wall
        local kWallJumpVelocityMinimum = 2
        if(velocity:GetLength() < kWallJumpVelocityMinimum) then

            local kWallJumpVelocity = 70
            local wallJumpVelocity = Vector(0, 0, 1)
            VectorCopy(self.wallWalkingNormalGoal, wallJumpVelocity)
            wallJumpVelocity:Scale(kWallJumpVelocity)
            
            velocity.x = velocity.x + wallJumpVelocity.x
            velocity.y = velocity.y + wallJumpVelocity.y
            velocity.z = velocity.z + wallJumpVelocity.z
            
            self:SetOverlayAnimation(Player.kAnimStartJump)

            self.timeOfLastJump = Shared.GetTime()
            
        // Jump off wall surface we're touching
        else
        
            local viewAngles = self:GetViewAngles()
            local viewCoords = viewAngles:GetCoords()

            // Add jump velocity along view direction and also "up" and away from wall
            local kWallJumpForce = 4.0
            local newVelocity = velocity

            newVelocity = newVelocity + viewCoords.yAxis * kWallJumpForce
            newVelocity = newVelocity + self.wallWalkingNormalGoal * kWallJumpForce

            VectorCopy(newVelocity, velocity)
            
            self:SetOverlayAnimation(Player.kAnimStartJump)

            self.timeOfLastJump = Shared.GetTime()

        end
        
    end
    
end
*/

function Skulk:GetPlayFootsteps()

    local velocity = self:GetVelocity()
    local velocityLength = velocity:GetLength() 
    
    // Don't play footsteps when we're walking
    return (self:GetIsOnGround() or self:GetIsWallWalking()) and velocityLength > .75 and not self.movementModiferState
    
end

function Skulk:UpdateHelp()

    if self:AddTooltipOnce("You are now a Skulk! Your health is in the lower left and your energy is the yellow circle in the lower right.") then
        return true
    elseif self:AddTooltipOnce("Sneak up on enemies and press left-click to bite them.") then
        return true
    elseif self:GetHasUpgrade(kTechId.Leap) and self:AddTooltipOnce("Press right-click to do a running leap!") then
        return true
    elseif self:AddTooltipOnce("You can walk on walls and ceilings! Just look up a wall and press forward!") then
        return true
    elseif self:AddTooltipOnce("You can hold shift to move silently.") then
        return true
    elseif self:AddTooltipOnce("You can hold crouch to disable wall walking (to drop on opponent or while leaping).") then
        return true
    end
    
    return false
    
end

function Skulk:GetIsOnGround()

    if self.leaping then
        return false
    end
    
    return Alien.GetIsOnGround(self) and not self:GetIsWallWalking()
    
end

/**
 * Knockback only allowed while the Skulk is in the air (jumping or leaping).
 */
function Skulk:GetIsKnockbackAllowed()

    return not self:GetIsOnGround() and not self:GetIsWallWalking()

end

Shared.LinkClassToMap( "Skulk", Skulk.kMapName, Skulk.networkVars )