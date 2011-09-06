// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/MapBlip.lua
//
// MapBlips are displayed on player minimaps based on relevancy.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'MapBlip' (Entity)

MapBlip.kMapName = "MapBlip"

MapBlip.networkVars =
{
    mapBlipType     = "enum kMinimapBlipType",
    mapBlipTeam     = "integer (" .. ToString(kTeamInvalid) .. " to " .. ToString(kSpectatorIndex) .. ")",
    rotation        = "float",
    ownerEntityId   = "entityid"
}

function MapBlip:OnCreate()

    Entity.OnCreate(self)
    
    self:SetUpdates(false)
    
    self.mapBlipType = kMinimapBlipType.TechPoint
    self.mapBlipTeam = kTeamReadyRoom
    self.rotation = 0
    self.ownerEntityId = Entity.invalidId
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
end

function MapBlip:UpdateRelevancy()

	self:SetRelevancyDistance(Math.infinity)
	
	local mask = 0
	
	if self.mapBlipTeam == kTeam1Index or self.mapBlipTeam == kTeamInvalid or self:GetIsSighted() then
		mask = bit.bor(mask, kRelevantToTeam1)
	end
	if self.mapBlipTeam == kTeam2Index or self.mapBlipTeam == kTeamInvalid or self:GetIsSighted() then
		mask = bit.bor(mask, kRelevantToTeam2)
	end
		
	self:SetExcludeRelevancyMask( mask )

end

function MapBlip:SetOwner(ownerId, blipType, blipTeam)

    self.ownerEntityId = ownerId
    self.mapBlipType = blipType
    self.mapBlipTeam = blipTeam

end

function MapBlip:GetOwnerEntityId()

    return self.ownerEntityId

end

function MapBlip:GetType()

    return self.mapBlipType

end

function MapBlip:GetTeamNumber()

    return self.mapBlipTeam

end

function MapBlip:GetRotation()

    return self.rotation

end

function MapBlip:GetIsSighted()

    local owner = Shared.GetEntity(self.ownerEntityId)
    
    if owner then
        if owner.GetTeamNumber and owner:GetTeamNumber() == kTeamReadyRoom and owner:GetAttached() then
            owner = owner:GetAttached()
        end
        return owner:GetIsSighted()
    end
    
    return false
    
end

// Called (server side) when a mapblips owner has changed its map-blip dependent state
function MapBlip:Update(deltaTime)

    PROFILE("MapBlip:Update")

    if self.ownerEntityId and Shared.GetEntity(self.ownerEntityId) then
    
        local owner = Shared.GetEntity(self.ownerEntityId)
        
        local fowardNormal = owner:GetCoords().zAxis
        self.rotation = math.atan2(fowardNormal.x, fowardNormal.z)
        
        self:SetOrigin(owner:GetOrigin())
        
        self:UpdateRelevancy()
        
    end
    
end

function MapBlip:GetIsValid ()

    local entity = Shared.GetEntity(self:GetOwnerEntityId())
    if entity == nil then
        return false
    end

    if entity.GetIsBlipValid then
        return entity:GetIsBlipValid()
    end

    return true
    
end

Shared.LinkClassToMap( "MapBlip", MapBlip.kMapName, MapBlip.networkVars )