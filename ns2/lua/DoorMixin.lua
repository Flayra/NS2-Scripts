// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DoorMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

DoorMixin = { }
DoorMixin.type = "Door"

function DoorMixin:__initmixin()    
end

// Children can provide a OverrideDoorInteraction function to provide their own door interaction
// functionality
function DoorMixin:OverrideDoorInteraction(inEntity)
    if self.OnOverrideDoorInteraction then
        return self:OnOverrideDoorInteraction(inEntity)
    end
    return false, 0
end
AddFunctionContract(DoorMixin.OverrideDoorInteraction, { Arguments = { "Entity", "Entity" }, Returns = { "boolean", "number" } })

// Function to check and see if this object can interact
function DoorMixin:GetCanDoorInteract(inEntity)
    return self:OverrideDoorInteraction(inEntity)
end
AddFunctionContract(DoorMixin.GetCanDoorInteract, { Arguments = { "Entity", "Entity" }, Returns = { "boolean", "number" } })