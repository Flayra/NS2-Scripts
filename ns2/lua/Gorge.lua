// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gorge.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Weapons/Alien/SpitSpray.lua")
Script.Load("lua/Weapons/Alien/InfestationAbility.lua")
Script.Load("lua/Weapons/Alien/HydraAbility.lua")
Script.Load("lua/Weapons/Alien/CystAbility.lua")
Script.Load("lua/Weapons/Alien/BileBomb.lua")
Script.Load("lua/Weapons/Alien/HarvesterAbility.lua")
Script.Load("lua/Weapons/Alien/Absorb.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

class 'Gorge' (Alien)

if (Server) then    
    Script.Load("lua/Gorge_Server.lua")
end

Gorge.networkVars = {
    bellyYaw            = "float",
    slideFlinchAmount   = "float",
    timeToEndSlide      = "float"
}

Gorge.kMapName = "gorge"

Gorge.kModelName = PrecacheAsset("models/alien/gorge/gorge.model")
Gorge.kViewModelName = PrecacheAsset("models/alien/gorge/gorge_view.model")
Gorge.kTauntSound = PrecacheAsset("sound/ns2.fev/alien/gorge/taunt")
Gorge.kSlideHitSound = PrecacheAsset("sound/ns2.fev/alien/gorge/hit")
Gorge.kJumpSoundName = PrecacheAsset("sound/ns2.fev/alien/gorge/jump")

// Particle effects
Gorge.kSoakEffect = PrecacheAsset("cinematics/alien/gorge/soak.cinematic")
Gorge.kSoakViewEffect = PrecacheAsset("cinematics/alien/gorge/soak_view.cinematic")
Gorge.kSlideEffect = PrecacheAsset("cinematics/alien/gorge/slide.cinematic")

Gorge.kMass = 80                    // I hope this is more than 16-bits! ;) Fatty!
Gorge.kXZExtents = 0.5              // Wide load
Gorge.kYExtents = 0.475
Gorge.kHealth = kGorgeHealth
Gorge.kArmor = kGorgeArmor
Gorge.kFov = 95
Gorge.kDamageEnergyFactor = 3.0     // Damage per alien energy unit that can be soaked
Gorge.kJumpHeight = 1.2
Gorge.kStartSlideForce = 14
Gorge.kViewOffsetHeight = .6
Gorge.kMaxGroundSpeed = 5.1
Gorge.kMaxSlidingSpeed = 10
Gorge.kSlidingMoveInputScalar = 0.00015
Gorge.kBuildingModeMovementScalar = 0.001
Gorge.kSlidingTurnRate = .25        // For limiting yaw rage of change when sliding. Radians/second
Gorge.kSlideFlinchRecoveryRate = .6

// Animations
Gorge.kBellySlide = "slide"
Gorge.kGorgeBellyYaw = "belly_yaw"    
Gorge.kStartSlide = "belly_jump"
Gorge.kEndSlide = "belly_out"
Gorge.kSlideFlinch = "belly_impact"
Gorge.kSlideFlinchIntensity = "intensity"
Gorge.kFlinch = "flinch1"
Gorge.kBigFlinch = "flinch2"
Gorge.kCreateStructure = "chamber"

PrepareClassForMixin(Gorge, GroundMoveMixin)
PrepareClassForMixin(Gorge, CameraHolderMixin)

function Gorge:OnInit()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Gorge.kFov })
    
    Alien.OnInit(self)
    
    self.bellyYaw = 0
    self.slideFlinchAmount = 0
    self.timeToEndSlide = 0

end

function Gorge:GetBaseArmor()
    return Gorge.kArmor
end

function Gorge:GetArmorFullyUpgradedAmount()
    return kGorgeArmorFullyUpgradedAmount
end

function Gorge:GetMaxViewOffsetHeight()
    return Gorge.kViewOffsetHeight
end

function Gorge:GetCrouchShrinkAmount()
    return 0
end

function Gorge:GetViewModelName()
    return Gorge.kViewModelName
end

function Gorge:GetJumpHeight()
    return Gorge.kJumpHeight
end

function Gorge:GetHasSpecialAbility()
    return true
end

// For special ability, return an array of energy (0-1), energy cost (0-1), tex x offset, tex y offset, 
// visibility (boolean), command name
function Gorge:GetSpecialAbilityInterfaceData()

    local vis = self:GetInactiveVisible() or (self:GetEnergy() ~= Ability.kMaxEnergy)
    return { self:GetEnergy()/Ability.kMaxEnergy, 0, 0, kAbilityOffset.Absorb, vis, GetDescForMove(Move.Crouch) }
    
end

function Gorge:GetCanNewActivityStart()
    return not self:GetIsSliding() and Alien.GetCanNewActivityStart(self)
end

function Gorge:HandleJump(input, velocity)
    if not self:GetIsSliding() then
        Alien.HandleJump(self, input, velocity)
    end
end

function Gorge:GetDesiredSliding(input)

    local desiredSliding = (bit.band(input.commands, Move.MovementModifier) ~= 0) and (not self.crouching) and self:GetVelocity():GetLengthXZ() > 1
    
    // Not allowed to start sliding while in the air
    if (not self:GetIsOnGround() and desiredSliding and self.mode == kPlayerMode.Default) then
        desiredSliding = false
    end
    
    // Must stay in slide mode while we recover after hitting something
    if (self.timeToEndSlide ~= 0) then
        desiredSliding = true
    end
    
    return desiredSliding

end

// Handle transitions between starting-sliding, sliding, and ending-sliding
function Gorge:UpdateSliding(input)

    local desiredSliding = self:GetDesiredSliding(input)
        
    if (desiredSliding and self.mode == kPlayerMode.Default and self:GetIsOnGround() and not self:GetIsJumping()) then
        
        self:SetAnimAndMode(Gorge.kStartSlide, kPlayerMode.GorgeStartSlide)
        
        // For modifying velocity
        self.startedSliding = true

        self.lastYaw = self:GetViewAngles().yaw
                        
    elseif (not desiredSliding and self.mode == kPlayerMode.GorgeSliding) then

        self:SetAnimAndMode(Gorge.kEndSlide, kPlayerMode.GorgeEndSlide)
        
    end 

    // Have Gorge lean into turns depending on input. He leans more at higher rates of speed.
    if self:GetIsSliding() then

        local kGorgeLeanSpeed = 2
        local desiredBellyYaw = 2*(-input.move.x/Gorge.kSlidingMoveInputScalar)*(self:GetVelocity():GetLength()/self:GetMaxSpeed())
        self.bellyYaw = Slerp(self.bellyYaw, desiredBellyYaw, input.time*kGorgeLeanSpeed)
        
    end
    
end

function Gorge:ModifyVelocity(input, velocity)

    Alien.ModifyVelocity(self, input, velocity)

    // Give a little push forward to make sliding useful
    if self.startedSliding then
    
        local pushDirection = GetNormalizedVector(self:GetVelocity())
        local impulse = pushDirection * Gorge.kStartSlideForce

        velocity.x = velocity.x + impulse.x
        velocity.y = velocity.y + impulse.y
        velocity.z = velocity.z + impulse.z
        
        self.startedSliding = false

    end
    
end

function Gorge:SetAnimAndMode(animName, mode)

    Alien.SetAnimAndMode(self, animName, mode)
    
    // Belly sliding
    if mode == kPlayerMode.GorgeStartSlide then
        self:SetViewAnimation("belly_in")
    elseif mode == kPlayerMode.GorgeSliding then
        self:SetViewAnimation("belly")
    elseif mode == kPlayerMode.GorgeEndSlide then
        self:SetViewAnimation("belly_out")
    
    // Taunting
    elseif mode == kPlayerMode.Taunt then
        self:SetViewAnimation("taunt")
    end
    
    if animName == Gorge.kBellySlide then
        self.modeTime = -1
    end
    
    /*
    if mode == kPlayerMode.GorgeStructure then
        local velocity = self:GetVelocity()
        velocity:Scale(.5)
        self:SetVelocity(velocity)
    end
    */
    
end

function Gorge:HandleButtons(input)

    PROFILE("Gorge:HandleButtons")
    
    Alien.HandleButtons(self, input)
    
    // Shift key for belly slide
    self:UpdateSliding(input)
    
end

/*
function Gorge:OnCapsuleTraceHit(originalVelocity, collisionNormal, newVelocity, entity)

    Alien.OnCapsuleTraceHit(self, originalVelocity, collisionNormal, newVelocity, entity)
    
    if (self:GetIsSliding() and (self.timeToEndSlide == 0)) then
    
        // Only crash with a substantial collision
        local originalVelocityLength = originalVelocity:GetLength()
        local newVelocityLength = newVelocity:GetLength()
        local hitWall = ( math.abs( collisionNormal:DotProduct(Vector(0, 1, 0)) ) < .5 )
        
        if ((originalVelocityLength > 2) and (newVelocityLength < originalVelocityLength/2) and hitWall) then
            
            self.slideFlinchAmount = 1 - (newVelocityLength / (originalVelocityLength/2))
            
            self:SetAnimationWithBlending(Gorge.kSlideFlinch)
            
            self.timeToEndSlide = Shared.GetTime() + self.slideFlinchAmount / Gorge.kSlideFlinchRecoveryRate
            
            self:PlaySound(Gorge.kSlideHitSound)
            
            self:SetSoundParameter(Gorge.kSlideHitSound, "intensity", self.slideFlinchAmount, 10)
            
        end
    
    end
    
end
*/

function Gorge:UpdateAnimation(timePassed)
    
    PROFILE("Gorge:UpdateAnimation")
    
    if (self.timeToEndSlide == 0) then
        Alien.UpdateAnimation(self, timePassed)
    end
    
    self.slideFlinchAmount = math.min(math.max(self.slideFlinchAmount - timePassed * Gorge.kSlideFlinchRecoveryRate, 0), 1)
    
    if (self.timeToEndSlide ~= 0 and Shared.GetTime() > self.timeToEndSlide) then
           
        self:SetAnimAndMode(Gorge.kEndSlide, kPlayerMode.GorgeEndSlide)
            
        self.slideFlinchAmount = 0
        
        self.timeToEndSlide = 0
        
    end

end

function Gorge:UpdatePoseParameters(deltaTime)

    PROFILE("Gorge:UpdatePoseParameters")

    Alien.UpdatePoseParameters(self, deltaTime)
    
    self:SetPoseParam(Gorge.kGorgeBellyYaw, self.bellyYaw*45)
    
    self:SetPoseParam(Gorge.kSlideFlinchIntensity, Clamp(self.slideFlinchAmount, 0, 1))
    
end

function Gorge:GetIsSliding()
    return (self.mode == kPlayerMode.GorgeStartSlide) or (self.mode == kPlayerMode.GorgeSliding)
end

function Gorge:AdjustMove(input)

    PROFILE("Gorge:AdjustMove")

    Alien.AdjustMove(self, input)

    // Can't do anything for a bit after a crash
    if (self.timeToEndSlide ~= 0) then
    
        input.move:Scale(0)
    
    elseif (self:GetIsSliding()) then

        input.move:Scale(Gorge.kSlidingMoveInputScalar)

    elseif self.mode == kPlayerMode.GorgeStructure then
    
        // Don't move much
        input.move:Scale(Gorge.kBuildingModeMovementScalar)
        
    end
    
    return input

end

function Gorge:ConstrainMoveVelocity(moveVelocity)   

    Alien.ConstrainMoveVelocity(self, moveVelocity)
    
    if self:GetIsSliding() then
        moveVelocity:Scale(.02)
    //elseif self.mode == kPlayerMode.GorgeStructure then
    //    moveVelocity:Scale(Gorge.kBuildingModeMovementScalar)
    end
    
end

function Gorge:GetFrictionForce(input, velocity)

    if(self:GetIsSliding()) then
    
        local scalar = .4
        return Vector(-velocity.x, 0, -velocity.z) * scalar

    elseif self.mode == kPlayerMode.GorgeStructure then
    
        local scalar = 18
        return Vector(-velocity.x, 0, -velocity.z) * scalar
        
    end

    return Alien.GetFrictionForce(self, input, velocity)
    
end

function Gorge:SetCrouchState(newCrouchState)
    self.crouching = newCrouchState
end

function Gorge:GetMaxSpeed()

    local success, speed = self:GetCamouflageMaxSpeed(self.movementModiferState)
    if success then
        return speed
    end

    speed = Gorge.kMaxGroundSpeed
    
    if self:GetIsSliding() then
    
        speed = Gorge.kMaxSlidingSpeed

    end
    
    return speed * self:GetSlowSpeedModifier()
    
end

function Gorge:GetMass()
    return Gorge.kMass
end

function Gorge:GetTauntSound()
    return Gorge.kTauntSound
end

function Gorge:ProcessEndMode()

    if(self.mode == kPlayerMode.GorgeStartSlide) then
    
        self:SetAnimAndMode(Gorge.kBellySlide, kPlayerMode.GorgeSliding)
        return true

    end

    return false
    
end

// If we're sliding, set desired pitch/roll so model orients flat on ground
function Gorge:UpdateViewAngles(input)

    PROFILE("Gorge:UpdateViewAngles")

    local desiredPitch = nil
    local desiredRoll = nil
   
    if(self:GetIsSliding()) then
    
        local trace = Shared.TraceRay(self:GetOrigin(), self:GetOrigin() - Vector(0, 2, 0), PhysicsMask.AllButPCs, EntityFilterOne(self))
        
        if(trace.fraction < 1) then
        
            local coords = BuildCoords(trace.normal, self:GetViewAngles():GetCoords().zAxis)
            local angles = Angles()
            angles:BuildFromCoords(coords)
            
            // Set wall pitch and wall roll 
            desiredPitch = angles.pitch
            desiredRoll = angles.roll
            
        end
        
    end
    
    self:SetDesiredPitch(desiredPitch)
    self:SetDesiredRoll(desiredRoll)
    
    Alien.UpdateViewAngles(self, input)
    
end

function Gorge:UpdateHelp()

    local activeWeaponName = self:GetActiveWeaponName()   

    if self:AddTooltipOnce("You are now a Gorge! You can heal players and build structures - but stay away from enemies.") then
        return true
    elseif self:AddTooltipOnce("Press left-click to spit and right-click to heal players or structures.") then
        return true
    elseif activeWeaponName ~= "HydraAbility" and self:AddTooltipOnce("Switch to weapon #2 to build hydras that attack enemies.") then
        return true       
    elseif activeWeaponName == "HydraAbility" and self:AddTooltipOnce("Building a Hydra costs you resources, but you can build as many as you like.") then
        return true       
    elseif activeWeaponName == "HydraAbility" and self:AddTooltipOnce("Hydras can even be built on walls and ceilings!") then
        return true       
    elseif self:AddTooltipOnce("Hold shift while moving belly slide!") then
        return true
    end
    
    return false
    
end


Shared.LinkClassToMap("Gorge", Gorge.kMapName, Gorge.networkVars )
