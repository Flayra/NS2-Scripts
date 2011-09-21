// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\SelectableMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * SelectableMixin marks entities as selectable to a commander.
 */
SelectableMixin = { }
SelectableMixin.type = "Selectable"

SelectableMixin.optionalCallbacks =
{
    OnGetIsSelectable = "Returns if this entity is selectable or not"
}

function SelectableMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "SelectableMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        selectable       = "boolean",        
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function SelectableMixin:__initmixin()
    self.selectable = true
end

function SelectableMixin:SetSelectable(selectable)
    self.selectable = selectable
end
AddFunctionContract(SelectableMixin.SetSelectable, { Arguments = { "Entity", "Boolean" }, Returns = { } })

function SelectableMixin:GetIsSelectable()

    if self.OnGetIsSelectable then           
        return self:OnGetIsSelectable()
    end
    
    return self.selectable    
end
AddFunctionContract(SelectableMixin.GetIsSelectable, { Arguments = { "Entity" }, Returns = { "boolean" } })