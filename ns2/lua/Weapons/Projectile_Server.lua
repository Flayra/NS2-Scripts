// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Projectile_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/PhysicsGroups.lua")

/**
 * Sets the linear velocity of the projectile in world space.
 */
function Projectile:SetVelocity(velocity)

    self:CreatePhysics()
    self.physicsBody:SetLinearVelocity(velocity)

end

/**
 * Creates the physics representation for the projectile (if necessary).
 */
function Projectile:CreatePhysics()

    if (self.physicsBody == nil) then
        self.physicsBody = Shared.CreatePhysicsSphereBody(true, self.radius, self.mass, self:GetCoords() )
        self.physicsBody:SetGravityEnabled(true)
        self.physicsBody:SetGroup( PhysicsGroup.ProjectileGroup )
        self.physicsBody:SetEntity( self )
        // Projectiles need to have continuous collision detection so they
        // don't tunnel through walls and other objects.
        self.physicsBody:SetCCDEnabled(true)
        self.physicsBody:SetPhysicsType( CollisionObject.Dynamic )
        self.physicsBody:SetLinearDamping(self.linearDamping)
        self.physicsBody:SetRestitution(self.restitution)
    end
    
end

/**
 * From Actor. We need to override as Projectile manages it's own physics.
 */
function Projectile:SetPhysicsType(physicsType)

    self.physicsType = physicsType
    
    if (self.physicsBody) then
    
        if (self.physicsType == PhysicsType.Kinematic) then
            self.physicsBody:SetSimulationEnabled(false)
        elseif (self.physicsType == PhysicsType.Dynamic) then
            self.physicsBody:SetSimulationEnabled(true)
        end
    
    end

end

function Projectile:SetGravityEnabled(state)
    if self.physicsBody then
        self.physicsBody:SetGravityEnabled(state)
    else
        Print("%s:SetGravityEnabled(%s) - Physics body is nil.", self:GetClassName(), tostring(state))
    end
end        

/**
 * Called when the projectile collides with something. Can be overridden by
 * derived classes.
 */
function Projectile:OnCollision(entityHit)
end    

function Projectile:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    self:CreatePhysics()

    // If the projectile has moved outside of the world, destroy it
    local coords = self.physicsBody:GetCoords()
    local origin = coords.origin
    
    local maxDistance = 1000
    
    if origin:GetLengthSquared() > maxDistance * maxDistance then
        Print( "%s moved outside of the playable area, destroying", self:GetClassName() )
        DestroyEntity(self)
    else
        // Update the position/orientation of the entity based on the current
        // position/orientation of the physics object.
        self:SetCoords( coords )
        Server.dbgTracer:TraceProjectile(self)
    end
    
end

function Projectile:SetOrientationFromVelocity()

    // Set orientation according to velocity
    local velocity = self:GetVelocity()
    if velocity:GetLength() > 0 and self.physicsBody then

        local coords = self.physicsBody:GetCoords()
        local normVelocity = GetNormalizedVector(velocity)        
        local normal = Vector(0, 1, 0)
        
        self:SetCoords( BuildCoordsFromDirection(normVelocity, self:GetOrigin()) )
        
    end

end

function Projectile:SetOwner(player)

    local success = ScriptActor.SetOwner(self, player)
    
    if success and player ~= nil and self.physicsBody and player:GetController() then
    
        // Make sure the owner cannot collide with the projectile
        Shared.SetPhysicsObjectCollisionsEnabled(self.physicsBody, player:GetController(), false)

    end
    
    return success
    
end

// Creates projectile on our team 1 meter in front of player
function CreateViewProjectile(mapName, player)   

    local viewCoords = player:GetViewAngles():GetCoords()
    local startPoint = player:GetEyePos() + viewCoords.zAxis
    
    local projectile = CreateEntity(mapName, startPoint, player:GetTeamNumber())
    SetAnglesFromVector(projectile, viewCoords.zAxis)
    
    // Set spit owner to player so we don't collide with ourselves and so we
    // can attribute a kill to us
    projectile:SetOwner(player)
    
    return projectile
        
end

// Register for callbacks when projectiles collide with the world
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, 0 )
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, PhysicsGroup.DefaultGroup )
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, PhysicsGroup.StructuresGroup )
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, PhysicsGroup.PlayerControllersGroup)
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, PhysicsGroup.CommanderPropsGroup )
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, PhysicsGroup.AttachClassGroup )
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, PhysicsGroup.CommanderUnitGroup )
Shared.SetPhysicsCollisionCallbackEnabled( PhysicsGroup.ProjectileGroup, PhysicsGroup.CollisionGeometryGroup )