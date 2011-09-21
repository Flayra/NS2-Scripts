// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\SpectatorMoveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/Mixins/BaseMoveMixin.lua")

SpectatorMoveMixin = { }
SpectatorMoveMixin.type = "MoveChild"

SpectatorMoveMixin.expectedCallbacks = {
    GetAcceleration = "Should return a number value representing the acceleration.",
    GetMaxSpeed = "Should return a number value representing the maximum speed this Entity can go." }

SpectatorMoveMixin.optionalCallbacks = {
    ConvertToViewAngles = "Return the current view angles based on the input pitch and yaw passed in." }

function SpectatorMoveMixin.__prepareclass(toClass)

    PrepareClassForMixin(toClass, BaseMoveMixin)
    
end

function SpectatorMoveMixin:__initmixin()

    InitMixin(self, BaseMoveMixin, { kGravity = 0 })
    
end

/**
 * Update position from velocity, not performing collision with the world.
 */
function SpectatorMoveMixin:_UpdatePosition(velocity, time)

    local offset = velocity * time
    local newOrigin = Vector(self:GetOrigin()) + offset
    self:SetOrigin(newOrigin)

end

function SpectatorMoveMixin:UpdateMove(input)

    local velocity = self:GetVelocity()
    
    local angles = Angles(input.pitch, input.yaw, 0)
    if self.ConvertToViewAngles then
        angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    end
    
    self.viewPitch = angles.pitch
    self.viewYaw = angles.yaw
    self.viewRoll = angles.roll
    
    local viewCoords = angles:GetCoords()
    
    // Apply acceleration in the direction we're looking (flying).
    local moveVelocity = viewCoords:TransformVector(input.move) * self:GetAcceleration()
    velocity = velocity + moveVelocity * input.time
    
    // Apply friction.
    local frictionForce = Vector(-velocity.x, -velocity.y, -velocity.z) * 5
    velocity = velocity + frictionForce * input.time
    
    // Clamp speed.
    local velocityLength = velocity:GetLength()
    if velocityLength > self:GetMaxSpeed() then
        velocity:Scale(self:GetMaxSpeed() / velocityLength)
    end

    self:_UpdatePosition(velocity, input.time)

    self:SetVelocity(velocity)
    
end
AddFunctionContract(SpectatorMoveMixin.UpdateMove, { Arguments = { "Entity", "Move" }, Returns = { } })