// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Lerk.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
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
Lerk.kJumpImpulse = 5
Lerk.kFlapUpImpulse = 4             // NS1 made this 2/3 of kFlapStraightUpImpulse
Lerk.kFlapStraightUpImpulse = 6
Lerk.kFlapThrustMoveScalar = .85 // From NS1
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
    
        local kBaseAirScalar = .5
        local kAirTimeToMaxSpeed = 10
        local airTimeScalar = Clamp((Shared.GetTime() - self.timeLastOnGround) / kAirTimeToMaxSpeed, 0, 1)
        local speedScalar = kBaseAirScalar + airTimeScalar * (1 - kBaseAirScalar)
        speed = Lerk.kMaxWalkSpeed + speedScalar * (Lerk.kMaxSpeed - Lerk.kMaxWalkSpeed)
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
        
            // Add or remove velocity depending if we're looking up or down
            local dot = Clamp(Vector(0, -1, 0):DotProduct(viewCoords.zAxis), 0, 1)
            
            local glideAmount = dot // math.sin( dot * math.pi / 2 )
            
            local glideVelocity = viewCoords.zAxis * math.abs(glideAmount) * self:GetAcceleration() * 5
            
            return glideVelocity
            
        else
        
            // Don't allow a lot of lateral movement while flying
            move.x = Sign(move.x) * .1
            
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
    if velocity.y <= 0 then

        local newVelocity = redirectDir * self:GetVelocity():GetLength()
        self:SetVelocity(newVelocity)

    else
        
        local zAxis = redirectDir//self:GetViewAngles():GetCoords().zAxis    
        local xzLook = GetNormalizedVector(Vector(zAxis.x, 0, zAxis.z))
        local newVelocity = xzLook * velocity:GetLengthXZ() + Vector(0, velocity.y, 0)
        self:SetVelocity(newVelocity)            
        
    end

end

function Lerk:PreUpdateMove(input, runningPrediction)

    PROFILE("Lerk:PreUpdateMove")

    // If we're gliding, redirect velocity to whichever way we're looking
    // so we get that cool soaring feeling from NS1
    if not self:GetIsOnGround() then

        if self.gliding then
        
            // If we're strafing, redirect velocity towards direction we're pressing
            // otherwise re-direct direction we're facing
            local redirectDir = self:GetViewAngles():GetCoords().zAxis
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
    
    self.gliding = (not self:GetIsOnGround() and self.flappedSinceLeftGround and (bit.band(input.commands, Move.Jump) ~= 0) and dot >= .8)

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

    local flapVelocity = Vector(0, 0, 0)
    
    // Thrust forward or backward
    if(input.move:GetLength() > 0) then
    
        flapVelocity = GetNormalizedVector(self:GetViewCoords():TransformVector( input.move )) * self:GetAcceleration() * Lerk.kFlapThrustMoveScalar
        
    else
    
        // Get more lift when that's all we're doing
        flapVelocity.y = flapVelocity.y + Lerk.kFlapStraightUpImpulse
        
    end
    
    VectorCopy(velocity + flapVelocity, velocity)

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
