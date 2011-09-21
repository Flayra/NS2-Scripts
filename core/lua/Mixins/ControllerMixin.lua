ControllerMixin = { }
ControllerMixin.type = "Controller"

ControllerMixin.expectedCallbacks =
{
    GetControllerSize = "Should return a height and radius",
    GetMovePhysicsMask = "Should return a mask for the physics groups to collide with"
}

function ControllerMixin:__initmixin()
    self.controller = nil
end

function ControllerMixin:OnDestroy()
    self:DestroyController()
end

function ControllerMixin:CreateController(physicsGroup)

    assert(self.controller == nil)
    
    self.controller = Shared.CreateCollisionObject(self)
    self.controller:SetGroup( physicsGroup )
    self.controller:SetTriggeringEnabled( true )
    
    // Make the controller kinematic so physically simulated objects will
    // interact/collide with it.
    self.controller:SetPhysicsType( CollisionObject.Kinematic )
    
    self:UpdateControllerFromEntity()
    
end

function ControllerMixin:DestroyController()
    if self.controller ~= nil then
        Shared.DestroyCollisionObject(self.controller)
        self.controller = nil
    end
end

/**
 * Synchronizes the origin and shape of the physics controller with the current
 * state of the entity.
 */
function ControllerMixin:UpdateControllerFromEntity()

    if self.controller ~= nil then
    
        local controllerHeight, controllerRadius = self:GetControllerSize()
        
        if controllerHeight ~= self.controllerHeight or controllerRadius ~= self.controllerRadius then
        
            self.controllerHeight = controllerHeight
            self.controllerRadius = controllerRadius
        
            // A flat bottomed cylinder works well for movement since we don't
            // slide down as we walk up stairs or over other lips. The curved
            // edges of the cylinder allows players to slide off when we hit them,
            self.controller:SetupCylinder( controllerRadius, controllerHeight, self.controller:GetCoords() )
                
        end
        
        // The origin of the controller is at its center and the origin of the
        // player is at their feet, so offset it.
        local origin = Vector(self:GetOrigin())
        origin.y = origin.y + self.controllerHeight * 0.5
        
        self.controller:SetPosition(origin)
        
    end
    
end

function ControllerMixin:OnUpdate(deltaTime)

    // Dead entities do not have a controller.
    if HasMixin(self, "Live") and not self:GetIsAlive() then
        self:DestroyController()
    end

end

/**
 * Synchronizes the origin of the entity with the current state of the physics
 * controller.
 */
function ControllerMixin:UpdateOriginFromController()
        
    // The origin of the controller is at its center and the origin of the
    // player is at their feet, so offset it.
    local origin = Vector(self.controller:GetPosition())
    origin.y = origin.y - self.controllerHeight * 0.5
    
    self:SetOrigin(origin)
    
end

/** 
 * Returns true if the entity is colliding with anything that passes its movement
 * mask at its current position.
 */
function ControllerMixin:GetIsColliding()

    if self.controller then
        self:UpdateControllerFromEntity()
        return self.controller:Test(self:GetMovePhysicsMask())
    end
    
    return false

end

/**
 * Moves by the player by the specified offset, colliding and sliding with the world.
 */
function ControllerMixin:PerformMovement(offset, maxTraces, velocity)

    local hitEntities   = nil
    local completedMove = true
    
    if self.controller then
    
        self:UpdateControllerFromEntity()

        local tracesPerformed = 0
        
        while (offset:GetLengthSquared() > 0.0 and tracesPerformed < maxTraces) do

            local trace = self.controller:Move(offset, self:GetMovePhysicsMask())
            
            if (trace.fraction < 1) then
                
                // Remove the amount of the offset we've already moved.
                offset = offset * (1 - trace.fraction)

                // Make the motion perpendicular to the surface we collided with so we slide.
                offset = offset - offset:GetProjection(trace.normal)
                
                // Redirect velocity if specified
                if velocity ~= nil then
                
                    // Scale it according to how much velocity we lost
                    local newVelocity = velocity - velocity:GetProjection(trace.normal)
                    
                    // Copy it so it's changed for caller
                    VectorCopy(newVelocity, velocity)
    
                end
                
                // Defer the processing of the callbacks until after we've finished moving,
                // since the callbacks may modify our self an interfere with our loop
                if trace.entity ~= nil and trace.entity.OnCapsuleTraceHit ~= nil then
                    if (hitEntities == nil) then
                        hitEntities = { trace.entity }
                    else
                        table.insert(hitEntities, trace.entity)
                    end    
                end

                completedMove = false

            else
                offset = Vector(0, 0, 0)
            end

            tracesPerformed = tracesPerformed + 1

        end
        
        self:UpdateOriginFromController()
        
    end
    
    // Do the hit callbacks.
    if hitEntities then
        for index, entity in ipairs(hitEntities) do
            entity:OnCapsuleTraceHit(self)
            self:OnCapsuleTraceHit(entity)
        end
    end
    
    return completedMove
    
end

function ControllerMixin:OnSynchronized()
    PROFILE("ControllerMixin:OnSynchronized")
    self:UpdateControllerFromEntity()
end