// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Trigger.lua
//
//    Created by:   Brian Cronin (brian@unknownworlds.com)
//
// General purpose trigger object. Kind of like "brush" entities from Half-life.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'Trigger' (ScriptActor)

Trigger.kMapName = "trigger"

local networkVars =
{
    name        = string.format("string (%d)", kMaxEntityStringLength),
    scale       = "vector"
}

function Trigger:OnInit()

    ScriptActor.OnInit(self)
    
    // This is a vector, not a float
    if not self.scale then
        self.scale = Vector(1, 1, 1)
    end
    
    if not self.physicsBody then
    
        local extents = self.scale / 4
        local coords = self:GetAngles():GetCoords()
        coords.origin = Vector(self:GetOrigin())
        // The physics origin is at it's center
        coords.origin.y = coords.origin.y + extents.y
    
        //Print("CreatePhysicsBoxBody(%s => %s, %s)", ToString(self.name), coords.origin:tostring(), self.scale:tostring())
        self.physicsBody = Shared.CreatePhysicsBoxBody(false, extents, 0, coords)
        self.physicsBody:SetTriggerEnabled(true)
        self.physicsBody:SetEntity( self )
        self.physicsBody:SetCollisionEnabled(false)
        
    end
    
end

function Trigger:GetName()
    return self.name
end

function Trigger:GetIsPointInside(point)

    local inside = false
    
    if self.physicsBody then
        inside = self.physicsBody:GetContainsPoint(point)        
    end
    
    return inside
    
end


function Trigger:tostring()
    return string.format("Trigger: \"%s\" origin: %s, scale: %s", ToString(self.name), self:GetOrigin():tostring(), self.scale:tostring()) 
end

function Trigger:OnDestroy()

    ScriptActor.OnDestroy(self)

    if self.physicsBody then
    
        Shared.DestroyCollisionObject(self.physicsBody)
        self.physicsBody = nil
        
    end
    
end

// Child classes should override this
function Trigger:OnTriggerEntered(enterEnt, triggerEnt)
end

function Trigger:OnTriggerExited(exitEnt, triggerEnt)
end

// Child classes should override this
Shared.LinkClassToMap("Trigger", Trigger.kMapName, networkVars)