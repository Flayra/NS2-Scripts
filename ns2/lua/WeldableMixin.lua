// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\WeldableMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/BalanceHealth.lua")

WeldableMixin = { }
WeldableMixin.type = "Weldable"

WeldableMixin.optionalCallbacks =
{
    GetCanBeWeldedOverride = "Return true booleans: if we can be welded now and if we can be welded in the future.",
}

WeldableMixin.expectedCallbacks =
{
    OnWeld = "When welded (welding entity, elapsed time). Returns boolean indicating if weld had effect.",
    GetTeamNumber = "From ScriptActor",
}

WeldableMixin.expectedMixins =
{
    Live = "",
}

// If entity is ready to be welded by buildbot right now, and in the future
function WeldableMixin:GetCanBeWelded(entity)

    // Can't weld yourself!
    if entity == self then
      return false
    end

    if self.GetCanBeWeldedOverride then
        return self:GetCanBeWeldedOverride(entity)
    end
    
    local canBeWeldedNow = 
        (entity:GetTeamNumber() == self:GetTeamNumber()) and 
        (self:GetHealth() < self:GetMaxHealth() or self:GetArmor() < self:GetMaxArmor())
        
    local canBeWeldedFuture = false
    
    return canBeWeldedNow, canBeWeldedFuture
    
end
AddFunctionContract(WeldableMixin.GetCanBeWelded, { Arguments = { "Entity" }, Returns = { "boolean", "boolean" } })

