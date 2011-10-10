// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PickupableWeaponFinderMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

local kFindWeaponRange = 1

local function FindNearbyWeapon(toPosition)

    local nearbyWeapons = GetEntitiesWithMixinWithinRange("Pickupable", toPosition, kFindWeaponRange)
    local closestWeapon = nil
    local closestDistance = Math.infinity
    for i, nearbyWeapon in ipairs(nearbyWeapons) do
    
        if nearbyWeapon:isa("Weapon") and nearbyWeapon:GetIsValidRecipient(self) then
        
            local nearbyWeaponDistance = (nearbyWeapon:GetOrigin() - toPosition):GetLengthSquared()
            if nearbyWeaponDistance < closestDistance then
            
                closestWeapon = nearbyWeapon
                closestDistance = nearbyWeaponDistance
            
            end
            
        end
        
    end
    
    return closestWeapon

end

PickupableWeaponFinderMixin = { }
PickupableWeaponFinderMixin.type = "PickupableWeaponFinder"

PickupableWeaponFinderMixin.expectedCallbacks =
{
    GetOrigin = "Returns the position of the Entity in world space"
}

function PickupableWeaponFinderMixin:__initmixin()

    if Client and Client.GetLocalPlayer() == self then
        self.weaponPickupGUI = GetGUIManager():CreateGUIScript("GUIWeaponPickup")
    end

end

function PickupableWeaponFinderMixin:OnDestroy()

    if Client and self.weaponPickupGUI then
        GetGUIManager():DestroyGUIScript(self.weaponPickupGUI)
        self.weaponPickupGUI = nil
    end

end

function PickupableWeaponFinderMixin:GetNearbyPickupableWeapon()
    return FindNearbyWeapon(self:GetOrigin())
end

if Client then

    function PickupableWeaponFinderMixin:OnUpdate(deltaTime)
    
        if Client.GetLocalPlayer() == self and self:GetIsAlive() then
        
            local foundNearbyWeapon = FindNearbyWeapon(self:GetOrigin())
            
            if foundNearbyWeapon then
                self.weaponPickupGUI:ShowWeaponData(foundNearbyWeapon:GetClassName())
            else
                self.weaponPickupGUI:HideWeaponData()
            end
            
        end
    
    end

end