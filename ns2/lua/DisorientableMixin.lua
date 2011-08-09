// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DisorientableMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

DisorientableMixin = { }
DisorientableMixin.type = "Disorientable"

DisorientableMixin.expectedCallbacks = {}

function DisorientableMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "DisorientableMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        disorientedAmount = "float",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function DisorientableMixin:__initmixin()
    self.disorientedAmount = 0
end

function DisorientableMixin:GetDisorientedAmount()
    return self.disorientedAmount
end

function DisorientableMixin:SetDisorientedAmount(amount)

    ASSERT(amount >= 0)
    ASSERT(amount <= 1)

    self.disorientedAmount = amount
    
end
