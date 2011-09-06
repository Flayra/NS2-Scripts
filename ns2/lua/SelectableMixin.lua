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
    OnGetIsSelectable = "Passes in a table with a Selectable field that can be set to true or false."
}

function SelectableMixin:__initmixin()
end

function SelectableMixin:GetIsSelectable()

    if self.OnGetIsSelectable then
    
        // Assume selectable by default.
        local selectableTable = { Selectable = true }
        self:OnGetIsSelectable(selectableTable)
        return selectableTable.Selectable
        
    end
    
    return true
    
end
AddFunctionContract(SelectableMixin.GetIsSelectable, { Arguments = { "Entity" }, Returns = { "boolean" } })