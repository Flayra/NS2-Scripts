// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ExtentsMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * ExtentsMixin allows an entity to define how much space it takes up.
 * The GetExtents() function is expected to be provided by anything that uses this mixin.
 */
ExtentsMixin = { }
ExtentsMixin.type = "Extents"

ExtentsMixin.expectedCallbacks =
{
    GetTechId = "Returns the tech Id of this entity."
}

ExtentsMixin.optionalCallbacks =
{
    GetExtentsOverride = "Returns a Vector indicating the current extents of this entity."
}

function ExtentsMixin:__initmixin()

    local maxExtents = LookupTechData(self:GetTechId(), kTechDataMaxExtents, Vector(1, 1, 1))
    self.maxExtents = Vector(maxExtents)
    
end

function ExtentsMixin:GetExtents()

    if self.GetExtentsOverride then
        return self:GetExtentsOverride()
    end
    return self:GetMaxExtents()

end
AddFunctionContract(ExtentsMixin.GetExtents, { Arguments = { "Entity" }, Returns = { "Vector" } })

function ExtentsMixin:GetMaxExtents()
    return Vector(self.maxExtents)
end
AddFunctionContract(ExtentsMixin.GetMaxExtents, { Arguments = { "Entity" }, Returns = { "Vector" } })