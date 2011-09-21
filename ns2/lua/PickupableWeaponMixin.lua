// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PickupableWeaponMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

PickupableWeaponMixin = { }
PickupableWeaponMixin.type = "Pickupable"

PickupableWeaponMixin.expectedCallbacks =
{
    GetParent = "Returns the parent entity of this pickupable."
}

function PickupableWeaponMixin:__initmixin()
end

function PickupableWeaponMixin:GetIsValidRecipient(recipient)
    return self:GetParent() == nil
end