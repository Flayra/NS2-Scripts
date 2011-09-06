// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Base class for all "live" entities. They have health and/or armor, can take damage, be killed 
// and can be given orders. Players, Drifters, MACs, ARCs, etc. Only objects of this type 
// are used for selection by the Commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/PathingMixin.lua")

class 'LiveScriptActor' (ScriptActor)

LiveScriptActor.kMapName = "livescriptactor"

LiveScriptActor.kMoveToDistance = 1

if (Server) then
    Script.Load("lua/LiveScriptActor_Server.lua")
else
    Script.Load("lua/LiveScriptActor_Client.lua")
end

LiveScriptActor.networkVars = 
{

    // Number of furys that are affecting this entity
    furyLevel               = string.format("integer (0 to %d)", kMaxStackLevel),
    
    activityEnd             = "float",  
    pathingEnabled          = "boolean"
    
}

// This should be moved out to classes that derive from LiveScriptActor soon.
PrepareClassForMixin(LiveScriptActor, LiveMixin)
PrepareClassForMixin(LiveScriptActor, OrdersMixin)
PrepareClassForMixin(LiveScriptActor, FireMixin)

function LiveScriptActor:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, LiveMixin)
    InitMixin(self, OrdersMixin, { kMoveToDistance = LiveScriptActor.kMoveToDistance })
    InitMixin(self, FireMixin)

end

// Depends on tech id being set before calling
function LiveScriptActor:OnInit()
    
    ScriptActor.OnInit(self)
    
    self.timeLastUpdate = nil
    
    self.furyLevel = 0
    
    self.activityEnd = 0
    
    self.timeOfLastAttack = 0
     
    // Ability to turn off pathing for testing
    self.pathingEnabled = true
    
    self:SetPathingFlag(kPathingFlags.UnBuildable)   
    
end

// All children should override this
function LiveScriptActor:GetExtents()
    return Vector(1, 1, 1)
end

function LiveScriptActor:ClearActivity()
    self.activityEnd = 0
end

function LiveScriptActor:SetActivityEnd(deltaTime)
    self.activityEnd = Shared.GetTime() + deltaTime
end

function LiveScriptActor:GetCanNewActivityStart()
    if(self.activityEnd == 0 or (Shared.GetTime() > self.activityEnd)) then
        return true
    end
    return false
end

function LiveScriptActor:GetCanIdle()
    return self:GetIsAlive()
end

function LiveScriptActor:OnUpdate(deltaTime)

    PROFILE("LiveScriptActor:OnUpdate")
    
    ScriptActor.OnUpdate(self, deltaTime)
    
    // Update expiring stackable game effects
    if Server then
        
        // Set fury level to be propagated to client so gameplay effects are predicted properly
        self:SetFuryLevel( self:GetStackableGameEffectCount(kFuryGameEffect) )

    end
    
    self.timeLastUpdate = Shared.GetTime()
    
end

function LiveScriptActor:GetFuryLevel()
    return self.furyLevel
end

function LiveScriptActor:AdjustFuryFireDelay(inDelay)

    // Reduce delay between attacks by number of fury effects, but 
    // decreasing in effect
    local delay = inDelay
    
    for i = 1, self.furyLevel do
        delay = delay * (1 - kFuryROFIncrease)
    end
    
    return delay
    
end

Shared.LinkClassToMap("LiveScriptActor", LiveScriptActor.kMapName, LiveScriptActor.networkVars )