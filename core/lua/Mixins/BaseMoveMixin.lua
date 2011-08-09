// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\BaseMoveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

BaseMoveMixin = { }
BaseMoveMixin.type = "Move"

BaseMoveMixin.expectedCallbacks = {
    UpdateMove = "The move behavior is handled by another mixin that provides this call." }

BaseMoveMixin.optionalCallbacks = {
    AdjustGravityForce = "Should return the current gravity force for the entity using this Mixin." }

BaseMoveMixin.expectedConstants = {
    kGravity = "The force on the y axis that gravity will apply." }

BaseMoveMixin.kMinimumVelocity = .05

function BaseMoveMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "BaseMoveMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        velocity = "compensated interpolated vector",
        gravityEnabled = "compensated boolean",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function BaseMoveMixin:__initmixin()

    self.velocity = Vector(0, 0, 0)
    self.gravityEnabled = true
    
end

function BaseMoveMixin:SetVelocity(velocity)

    // Notify any other mixin that cares. They may want to modify the velocity.
    // The passed in velocity will be returned if they don't modify it.
    velocity = self:MixinSendEvent("VelocityChanging", velocity)

    self.velocity = velocity

    // Snap to 0 when close to zero for network performance and our own sanity.
    if math.abs(self.velocity:GetLength()) < BaseMoveMixin.kMinimumVelocity then
        self.velocity:Scale(0)
    end

end
AddFunctionContract(BaseMoveMixin.SetVelocity, { Arguments = { "Entity", "Vector" }, Returns = { } })

function BaseMoveMixin:GetVelocity()
    return self.velocity
end
AddFunctionContract(BaseMoveMixin.GetVelocity, { Arguments = { "Entity" }, Returns = { "Vector" } })

function BaseMoveMixin:SetGravityEnabled(state)
    self.gravityEnabled = state
end
AddFunctionContract(BaseMoveMixin.SetGravityEnabled, { Arguments = { "Entity", "boolean" }, Returns = { } })

function BaseMoveMixin:GetGravityEnabled()
    return self.gravityEnabled
end
AddFunctionContract(BaseMoveMixin.GetGravityEnabled, { Arguments = { "Entity" }, Returns = { "boolean" } })

function BaseMoveMixin:GetGravityForce(input)

    local gravity = self:GetMixinConstants().kGravity
    
    if self.AdjustGravityForce then
        gravity = self:AdjustGravityForce(input, gravity)
    end
    
    return gravity
    
end
AddFunctionContract(BaseMoveMixin.GetGravityForce, { Arguments = { "Entity", "Move" }, Returns = { "number" } })