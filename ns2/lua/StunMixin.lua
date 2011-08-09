// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\StunMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

StunMixin = { }
StunMixin.type = "Stun"

function StunMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "StunMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        stunTime = "interpolated float"
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function StunMixin:__initmixin()

    self.stunTime = 0
    
    self:MixinWatchEvent("VelocityChanging", self._VelocityChangingEvent)
    
end

function StunMixin:SetStunTime(setStunTime)

    self.stunTime = setStunTime

end
AddFunctionContract(StunMixin.SetStunTime, { Arguments = { "Entity", "number" }, Returns = { } })

function StunMixin:GetIsStunned()

    return Shared.GetTime() < self.stunTime

end
AddFunctionContract(StunMixin.GetIsStunned, { Arguments = { "Entity" }, Returns = { "boolean" } })

function StunMixin:_VelocityChangingEvent(newVelocity)

    // Velocity is dampened when stunned. Downward velocity is not dampened (gravity).
    if self:GetIsStunned() then
        return self:GetVelocity() + Vector(newVelocity.x * 0.1, (newVelocity.y < 0 and newVelocity.y) or (newVelocity.y * 0.1), newVelocity.z * 0.1)
    end

end
AddFunctionContract(StunMixin._VelocityChangingEvent, { Arguments = { "Entity", "Vector" }, Returns = { { "Vector", "nil" } } })