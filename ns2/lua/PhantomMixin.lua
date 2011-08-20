// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PhantomMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

PhantomMixin = { }
PhantomMixin.type = "Phantom"

PhantomMixin.expectedCallbacks =
{
    GetTechId = "Used for?"
}

function PhantomMixin.__prepareclass(toClass)   

    ASSERT(toClass.networkVars ~= nil, "PhantomMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        // 0 when not active, > 0 when object is a phantom
        lifetime = "float",
        expired = "boolean",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function PhantomMixin:__initmixin()   
    self.lifetime = 0 
    self.expired = false
end

// Set duration after which we will expire
function PhantomMixin:SetLifetime(lifetime)

    ASSERT(type(lifetime) == "number")
    ASSERT(lifetime >= 0)
    
    self.lifetime = lifetime
    self.expired = false
    
end

function PhantomMixin:GetIsExpired()
    return self.expired
end

function PhantomMixin:OnUpdate(deltaTime)

    self.lifetime = math.max(self.lifetime - deltaTime, 0)
    
    if not self.expired and self.lifetime == 0 then
        self.expired = true
    end
    
end

function PhantomMixin:GetIsPhantom()
    return (self.lifetime > 0)
end





