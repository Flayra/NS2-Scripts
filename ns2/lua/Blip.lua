// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/Blip.lua
//
// Alien hive sight blip. Used to reduce total amount of traffic to clients and also to allow
// them to update smoothly and quickly. Propagated to clients in regular way.
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2008-2011, Unknown Worlds Entertainment, Inc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Blip' (Entity)

Blip.kMapName = "blip"

Blip.networkVars =
{
    // No need to send entId as the entity origin is updated every frame
    blipType    = "enum kBlipType",
    entId       = "entityid"
}

function Blip:OnCreate()

    self.blipType = kBlipType.Undefined
    self.entId    = Entity.invalidId
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
end

function Blip:UpdateRelevancy()
	self:SetRelevancyDistance( kHiveSightMaxRange )
	self:SetExcludeRelevancyMask( kRelevantToTeam2 )
end

function Blip:OnGetIsRelevant(player)
    return GetGamerules():GetIsRelevant(player, self)   
end

function Blip:Update(entity, blipType)

    self.blipType = blipType

    if entity.GetEngagementPoint then
        self:SetOrigin(entity:GetEngagementPoint())
    else
        self:SetOrigin(entity:GetModelOrigin())
    end
    
    self.entId = entity:GetId()
    
end


Shared.LinkClassToMap( "Blip", Blip.kMapName, Blip.networkVars )