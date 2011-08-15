// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Weapon:Dropped(prevOwner)
end

function Weapon:UpdateDropped()

    if self:GetPhysicsType() == Actor.PhysicsType.DynamicServer and not self.dropped then
    
        self:Dropped(nil)
        self.dropped = true
        
    elseif self:GetPhysicsType() == Actor.PhysicsType.None then
        self.dropped = false
    end
        
end

function Weapon:CreateWeaponEffect(player, playerAttachPointName, entityAttachPointName, cinematicName)
        
    if not player:GetIsThirdPerson() then
        Shared.CreateAttachedEffect(player, cinematicName, player:GetViewModelEntity(), Coords.GetTranslation(player:GetViewOffset()), entityAttachPointName, true, false)    
    else        
        Shared.CreateAttachedEffect(player, cinematicName, self, Coords.GetIdentity(), entityAttachPointName, false, false)    
    end
    
end

// Return true or false and the camera coords to use for the parent player if weapon chooses
// to override camera.
function Weapon:GetCameraCoords()
    return false, nil
end

function Weapon:CreateViewModelEffect(effectName)

    local player = self:GetParent()
    local viewModel = player:GetViewModelEntity()
    Shared.CreateEffect(player, effectName, viewModel, Coords.GetTranslation(Vector(0, 0, 0) /*player:GetViewOffset()*/))

end