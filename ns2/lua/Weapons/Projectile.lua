// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Projectile.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'Projectile' (ScriptActor)

Projectile.kMapName = "projectile"

Projectile.networkVars =
    {
        modelIndex          = "resource",
    }

if Server then
    Script.Load("lua/Weapons/Projectile_Server.lua")
else
    Script.Load("lua/Weapons/Projectile_Client.lua")
end

function Projectile:OnCreate()

    ScriptActor.OnCreate(self)

    self.modelIndex = 0
    
    self.radius = 0.1
    self.mass   = 1.0
    self.linearDamping = 0
    self.restitution = 0.5

    if (Client) then
        self.oldModelIndex = 0
    end
    
end

function Projectile:OnDestroy()

    ScriptActor.OnDestroy(self)

    if (Server) then
        Shared.DestroyCollisionObject(self.physicsBody)
        self.physicsBody = nil
    end
    
    if (Client) then
    
        // Destroy the render model.
        if (self.renderModel ~= nil) then
            Client.DestroyRenderModel(self.renderModel)
            self.renderModel = nil
        end
        
    end

end

function Projectile:GetVelocity()
    if self.physicsBody then
        return self.physicsBody:GetLinearVelocity()
    end
    return Vector(0, 0, 0)
end

/**
 * Projectile manages it's own physics body and doesn't require
 * a physics model from Actor.
 */
function Projectile:GetPhysicsModelAllowed()

    return false
    
end

// Dropped weapons depend on this also
Shared.LinkClassToMap("Projectile", Projectile.kMapName, Projectile.networkVars)
