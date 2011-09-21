// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TracerMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

TracerMixin = { }
TracerMixin.type = "Tracer"

TracerMixin.expectedCallbacks =
{
    GetBarrelPoint = "Returns the point where the tracer starts."
}

TracerMixin.expectedConstants =
{
    kTracerPercentage = "A value between 0 and 1 that determines how often tracers are triggered."
}

TracerMixin.optionalConstants =
{
    kRandomProvider = "Returns a number between and including 0 - 1 when called."
}

local kTracerSpeed = 75
// Limiting the number of tracers fired will decrease the amount of network traffic required.
local kTracerNumberWrapAround = 250

function TracerMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "TracerMixin expects the class to have network fields")
    
    toClass.networkVars.tracerEndPoint = "vector"
    toClass.networkVars.numberTracersFired = "integer (0 to " .. kTracerNumberWrapAround .. ")"
    
end

function TracerMixin:__initmixin()

    self.tracerEndPoint = Vector(0, 0, 0)
    self.numberTracersFired = 0
    self.oldNumberTracersFired = self.numberTracersFired

end

function TracerMixin:TriggerTracer(endPoint)

    assert(Client == nil)
    
    local randomProvider = self:GetMixinConstants().kRandomProvider
    local randomNumber = (randomProvider and randomProvider()) or math.random()
    if randomNumber < self:GetMixinConstants().kTracerPercentage then
    
        self.tracerEndPoint = endPoint
        self.numberTracersFired = self.numberTracersFired + 1
        if self.numberTracersFired > kTracerNumberWrapAround then
            self.numberTracersFired = 0
        end
        
    end

end
AddFunctionContract(TracerMixin.TriggerTracer, { Arguments = { "Entity", "Vector" }, Returns = { } })

function TracerMixin:OnUpdateRender()
    
    assert(Server == nil)
    
    if self.oldNumberTracersFired ~= self.numberTracersFired then
    
        local tracerStart = self:GetBarrelPoint()
        local tracerVelocity = GetNormalizedVector(self.tracerEndPoint - tracerStart) * kTracerSpeed
        CreateTracer(tracerStart, self.tracerEndPoint, tracerVelocity)
        
        self.oldNumberTracersFired = self.numberTracersFired
        
    end

end
AddFunctionContract(TracerMixin.OnUpdateRender, { Arguments = { "Entity" }, Returns = { } })