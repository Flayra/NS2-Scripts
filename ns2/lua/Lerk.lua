// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Lerk.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
//    Modified by: James Gu (twiliteblue) on 5 Aug 2011
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Weapons/Alien/Spikes.lua")
Script.Load("lua/Weapons/Alien/Spores.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

class 'Lerk' (Alien)

Lerk.kMapName = "lerk"

if(Server) then
    Script.Load("lua/Lerk_Server.lua")
end

Lerk.kModelName = PrecacheAsset("models/alien/lerk/lerk.model")
Lerk.kViewModelName = PrecacheAsset("models/alien/lerk/lerk_view.model")

Lerk.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/lerk/spawn")
Lerk.kFlapSound = PrecacheAsset("sound/ns2.fev/alien/lerk/flap")

Lerk.networkVars =
{
    flappedSinceLeftGround  = "boolean",
    gliding                 = "boolean",
}

Lerk.kViewOffsetHeight = .5
Lerk.XZExtents = .4
Lerk.YExtents = .4
Lerk.kJumpImpulse = 4
Lerk.kFlapUpImpulse = 4   
Lerk.kFlapStraightUpImpulse = 6
Lerk.kFlapThrustMoveScalar = 1         //.85
Lerk.kFov = 100
Lerk.kZoomedFov = 35
Lerk.kMass = 54  // ~120 pounds
Lerk.kJumpHeight = 1.5
Lerk.kSwoopGravityScalar = -30.0
Lerk.kRegularGravityScalar = -7
Lerk.kFlightGravityScalar = -4
Lerk.kMaxWalkSpeed = 2.8            // Lerks walk slowly to encourage flight
Lerk.kMaxSpeed = 13
Lerk.kAirAcceleration = 4
Lerk.kHealth = kLerkHealth
Lerk.kArmor = kLerkArmor
Lerk.kAnimRun = "run"
Lerk.kAnimFly = "fly"
Lerk.kAnimLand = "land"

PrepareClassForMixin(Lerk, GroundMoveMixin)
PrepareClassForMixin(Lerk, CameraHolderMixin)

function Lerk:OnInit()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Lerk.kFov })
    
    Alien.OnInit(self)
    
    self.flappedSinceLeftGround = false
    self.gliding = false
    
end

function Lerk:GetBaseArmor()
    return Lerk.kArmor
end

function Lerk:GetArmorFullyUpgradedAmount()
    return kLerkArmorFullyUpgradedAmount
end

function Lerk:GetMaxViewOffsetHeight()
    return Lerk.kViewOffsetHeight
end

function Lerk:GetCrouchShrinkAmount()
    return 0
end

function Lerk:GetViewModelName()
    return Lerk.kViewModelName
end

// Gain speed gradually the longer we stay in the air
function Lerk:GetMaxSpeed()

    local success, speed = self:GetCamouflageMaxSpeed(self.movementModiferState)
    if success then
        return speed
    end

    speed = Lerk.kMaxWalkSpeed
    if not self:GetIsOnGround() then
    
        local kBaseAirScalar = 1.2      // originally 0.5
        local kAirTimeToMaxSpeed = 5  // originally 10
        local airTimeScalar = Clamp((Shared.GetTime() - self.timeLastOnGround) / kAirTimeToMaxSpeed, 0, 1)
        local speedScalar = kBaseAirScalar + airTimeScalar * (1 - kBaseAirScalar)
        speed = Lerk.kMaxWalkSpeed + speedScalar * (Lerk.kMaxSpeed - Lerk.kMaxWalkSpeed)
        
        // half max speed while the walk key is pressed
        if self.movementModiferState then
            speed = speed * 0.5
        end        
        //Print("timeLastOnGround: %.2f, airTimeScalar: %.2f, speed scalar: %.2f, speed: %.2f", self.timeLastOnGround, airTimeScalar, speedScalar, speed)           
        
    end 
    
    return speed * self:GetSlowSpeedModifier()
    
end

function Lerk:GetAcceleration()
    return ConditionalValue(self:GetIsOnGround(), Alien.GetAcceleration(self), Lerk.kAirAcceleration)
end

function Lerk:GetMass()
    return Lerk.kMass
end

function Lerk:GetJumpHeight()
    return Lerk.kJumpHeight
end

function Lerk:GetFrictionForce(input, velocity)
    
    local frictionScalar = 2

    if self.gliding then
        return Vector(0, 0, 0)
    end
    
    // When in the air, but not gliding (spinning out of control)
    // Allow holding the jump key to reduce velocity, and slow the fall
    if (not self:GetIsOnGround()) and (bit.band(input.commands, Move.Jump) ~= 0) and (not self.gliding) then        
        if velocity.y < 0 then
            return Vector(-velocity.x, -velocity.y, -velocity.z) * frictionScalar
        else
            return Vector(-velocity.x, 0, -velocity.z) * frictionScalar
        end
    end
    
    return Alien.GetFrictionForce(self, input, velocity)
    
end


// Lerk flight
//
// Lift = New vertical movement
// Thrust = New forward direction movement
//
// First flap should take off of ground and have you hover a bit before landing 
// Flapping without pressing forward applies more lift but 0 thrust. Flapping while
// holding forward moves you in that direction, but if looking down there's no lift.
// Flapping while pressing forward and backward are the same.
// Tilt view a bit when banking. Hold jump key to glide then look down to swoop down.
// When gliding while looking up or horizontal, hover in mid-air.
function Lerk:HandleJump(input, velocity)

    if(self:GetIsOnGround()) then

        velocity.y = velocity.y + Lerk.kJumpImpulse
    
        self.timeOfLastJump = Shared.GetTime()
        
    else
    
        self:Flap(input, velocity)  
        
    end
        
end

function Lerk:HandleButtons(input)

    PROFILE("Lerk:HandleButtons")

    Alien.HandleButtons(self, input)
    
    if self:GetIsOnGround() then
        self.flappedSinceLeftGround = false
    end
    
end

if Client then
function Lerk:ModifyViewModelCoords(coords)

    if self.gliding then
    
        // Rotate view model coords around zAxis when gliding
        
    end
    
end
end

// Called from GroundMoveMixin.
function Lerk:ComputeForwardVelocity(input)

    // If we're in the air, move a little to left and right, but move in view direction when 
    // pressing forward. Modify velocity when looking up or down.
    if not self:GetIsOnGround() then
        
        local move          = GetNormalizedVector(input.move)
        local viewCoords    = self:GetViewAngles():GetCoords()
        
        if self.gliding then
        
            // Gliding: ignore air control
            // Add or remove velocity depending if we're looking up or down
            local zAxis = viewCoords.zAxis
           
            local dot = Clamp(Vector(0, -1, 0):DotProduct(zAxis), 0, 1)

            local glideAmount = dot// math.sin( dot * math.pi / 2 )

            local glideVelocity = viewCoords.zAxis * math.abs(glideAmount) * self:GetAcceleration()

            return glideVelocity
            
        else
        
            // Not gliding: use normal ground movement, or air control if we're in the air
            local transformedVertical = viewCoords:TransformVector( Vector(0, 0, move.z) )

            local moveVelocity = viewCoords:TransformVector( move ) * self:GetAcceleration()

            return moveVelocity
            
        end
    
    else
        // Fallback on the base function.
        return Alien.ComputeForwardVelocity(self, input)
    end
    
end

function Lerk:RedirectVelocity(redirectDir)

    local velocity = self:GetVelocity() 
    local xzSpeed = GetNormalizedVector(Vector(redirectDir.x, 0, redirectDir.z))    
    local ySpeed = 0
    
    local newVelocity = redirectDir * velocity:GetLength() //+ Vector(0, ySpeed, 0)
    self:SetVelocity(newVelocity)       

end

function Lerk:PreUpdateMove(input, runningPrediction)

    PROFILE("Lerk:PreUpdateMove")

    // If we're gliding, redirect velocity to whichever way we're looking
    // so we get that cool soaring feeling from NS1
    // Now with strafing and air brake
    if not self:GetIsOnGround() then
    
        local move = GetNormalizedVector(input.move)     
        local viewCoords = self:GetViewAngles():GetCoords()
        local redirectDir = self:GetViewAngles():GetCoords().zAxis
        local velocity = GetNormalizedVector(self:GetVelocity())
        
        if self.gliding then     
                               
            // Glide forward, strafe left/right, or brake slowly
            if (move.z ~= 0) then
            
                // Forward/Back key pressed - Glide in the facing direction
                // Allow some backward acceleration and some strafing
                move.z = Clamp(move.z, -0.05, 0)
                move.x = Clamp(move.x, -0.5, 0.5)                
                redirectDir = redirectDir + viewCoords:TransformVector( move )
                
            else
            
                // Non forward/back-key gliding, zero download velocity
                // Useful for maintaining height when attacking targets below
                move.x = Clamp(move.x, -0.5, 0.5)
                redirectDir = Vector(redirectDir.x, math.max(redirectDir.y, velocity.y, -0.01), redirectDir.z)                
                redirectDir = redirectDir + viewCoords:TransformVector( move )
                redirectDir:Normalize()

            end

            // Limit max speed so strafing does not increase total velocity
            if (redirectDir:GetLength() > 1) then
                redirectDir:Normalize()
            end

            self:RedirectVelocity(redirectDir)

        end

    end
    
end

function Lerk:HandleAttacks(input)

    Player.HandleAttacks(self, input)
    
    // If we're holding down jump, glide
    local zAxis = self:GetViewAngles():GetCoords().zAxis    
    local velocity = self:GetVelocity()
    local dot = 0
    if velocity:GetLength() > 1 then
        dot = GetNormalizedVector(velocity):DotProduct(zAxis)
    end
    
    self.gliding = (not self:GetIsOnGround() and self.flappedSinceLeftGround and (bit.band(input.commands, Move.Jump) ~= 0) and dot >= .7)

end

// Glide if jump held down.
function Lerk:AdjustGravityForce(input, gravity)

    if bit.band(input.commands, Move.Crouch) ~= 0 then
        // Swoop
        gravity = Lerk.kSwoopGravityScalar
    elseif self.gliding and self:GetVelocity().y <= 0 then
        // Glide for a long time
        gravity = Lerk.kFlightGravityScalar
    else
        // Fall very slowly by default
        gravity = Lerk.kRegularGravityScalar
    end
    
    return gravity
    
end

function Lerk:Flap(input, velocity)

    local lift = 0
    local flapVelocity = Vector(0, 0, 0)

    // Thrust forward or backward, or laterally
    if (input.move:GetLength() > 0 )then
    
        // Flapping backward and sideways generate very small amounts of thrust        
        // Allow full forward thrust, half lateral thrust, and minimal backward thrust
        input.move.z = Clamp(input.move.z, -0.3, 1)
        input.move.x = input.move.x * 0.5
        if (input.move.x ~= 0) then
            lift = Lerk.kFlapStraightUpImpulse * 0.5
        end
        flapVelocity = GetNormalizedVector(self:GetViewCoords():TransformVector( input.move )) * self:GetAcceleration() * Lerk.kFlapThrustMoveScalar
        
    else
        // Get more lift and slow down in the XZ directions when trying to flap straight up
        lift = Lerk.kFlapStraightUpImpulse
        flapVelocity = Vector(velocity.x, 0, velocity.z) * -0.1
    end
    
    flapVelocity.y = flapVelocity.y + lift
    
    // Each flap reduces some of the previous velocity
    // So we can change direction quickly by flapping    
    VectorCopy(velocity * 0.7 + flapVelocity, velocity)

    // Play wing flap sound
    Shared.PlaySound(self, Lerk.kFlapSound)

    self.flappedSinceLeftGround = true

end

function Lerk:GetCustomAnimationName(animName)

    if (animName == Player.kAnimEndJump) then
        return Lerk.kAnimLand
    end
    
    return Alien.GetCustomAnimationName(self, animName)

end

function Lerk:UpdateMoveAnimation()

    // Use full air speed
    local speed = self:GetVelocity():GetLength()
    
    if( self:GetIsOnGround() ) then
    
        if (speed > 0.5) then
        
            self:SetAnimationWithBlending(Player.kAnimRun)

        end
        
    else
        self:SetAnimationWithBlending(Lerk.kAnimFly)
    end
    
end

function Lerk:UpdateHelp()

    local activeWeaponName = self:GetActiveWeaponName()   

    if self:AddTooltipOnce("You are now a Lerk! Tap your jump key to fly.") then
        return true
    elseif self:AddTooltipOnce("Press left-click to shoot spikes and right-click to zoom in to sniper mode.") then
        return true
    elseif self:AddTooltipOnce("Holding jump lets you glide.") then
        return true       
    elseif activeWeaponName ~= "Spores" and self:AddTooltipOnce("Switch to weapon #2 to shoot spores.") then
        return true       
    elseif activeWeaponName == "Spores" and self:AddTooltipOnce("Spores do area damage to breathing players over time. Use to control an area or displace enemies.") then
        return true       
    end
    
    return false
    
end

Shared.LinkClassToMap( "Lerk", Lerk.kMapName, Lerk.networkVars )
