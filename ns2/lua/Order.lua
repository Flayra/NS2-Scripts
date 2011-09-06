// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Order.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// An order that is given to an AI unit or player.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Order' (Entity)

Order.kMapName = "order"

Order.networkVars =
{
    // No need to send entId as the entity origin is updated every frame
    orderType           = "enum kTechId",
    orderParam          = "integer",
    orderLocation       = "vector",
    orderOrientation    = "float",
}

function Order:OnCreate()

    self.orderType = kTechId.None
    self.orderParam = -1
    self.orderLocation = Vector(0, 0, 0)
    self.orderOrientation = 0
    
    //self:SetIsVisible(false)
    
    self:SetPropagate(Entity.Propagate_Callback)
    self:SetRelevancyDistance(Math.infinity)
    
end

function Order:OnGetIsRelevant(player)
    
    if player:GetIsCommander() then
        // Send orders if they belong to a unit is selected
        return player:GetSelectionHasOrder(self)
    elseif player:isa("Marine") then
        // Send orders given to players to those players
        return player.GetHasSpecifiedOrder and player:GetHasSpecifiedOrder(self)
    end
    
    return false

end

function Order:Initialize(orderType, orderParam, position, orientation)

    self.orderType = orderType
    self.orderParam = orderParam
    
    if orientation then
        self.orderOrientation = orientation
    end
    
    if position then
        self.orderLocation = position
    //else
    //    self.orderLocation = nil
    end
    
end

function Order:tostring()
    return string.format("Order type: %s Location: %s", GetDisplayNameForTechId(self.orderType), self:GetLocation():tostring())
end

function Order:GetType()
    return self.orderType
end

function Order:SetType(orderType)
    self.orderType = orderType
end

// The tech id of a building when order type is kTechId.Build, or the entity id for a build or weld order
// When moving to an entity specified here, add in GetHoverHeight() so MACs and Drifters stay off the ground
function Order:GetParam()
    return self.orderParam
end

function Order:GetLocation()

    local location = self.orderLocation

    // For move orders with an entity specified, lookup location of entity as it may have moved
    if(not location or ((self.orderType == kTechId.Move or self.orderType == kTechId.Construct) and self.orderParam > 0)) then
    
        local entity = Shared.GetEntity(self.orderParam)
        if(entity ~= nil) then
            location = Vector(entity:GetOrigin())
        end
        
    end
    
    return location
    
end

// When setting this location, add in GetHoverHeight() so MACs and Drifters stay off the ground
function Order:SetLocation(position)
    if self.orderLocation == nil then
        self.orderLocation = Vector()
    end
    self.orderLocation = position
end

// In radians - could be nil
function Order:GetOrientation()
    return self.orderOrientation
end

function CreateOrder(orderType, orderParam, position, orientation)

    local newOrder = CreateEntity(Order.kMapName)
       
    newOrder:Initialize(orderType, orderParam, position, tonumber(orientation))
    
    return newOrder
    
end

function GetOrderTargetIsConstructTarget(order, doerTeamNumber)

    if(order ~= nil) then
    
        local entity = Shared.GetEntity(order:GetParam())
                        
        if(entity ~= nil and entity:isa("Structure") and ((entity:GetTeamNumber() == doerTeamNumber) or (entity:GetTeamNumber() == kTeamReadyRoom)) and not entity:GetIsBuilt()) then
        
            return entity
            
        end
        
    end
    
    return nil

end

function GetOrderTargetIsDefendTarget(order, doerTeamNumber)

    if(order ~= nil) then
    
        local entity = Shared.GetEntity(order:GetParam())
                        
        if entity ~= nil and HasMixin(entity, "Live") and (entity:GetTeamNumber() == doerTeamNumber) then
        
            return entity
            
        end
        
    end
    
    return nil

end

function GetOrderTargetIsWeldTarget(order, doerTeamNumber)

    if(order ~= nil) then
    
        local entityId = order:GetParam()
        if(entityId > 0) then
        
            local entity = Shared.GetEntity(entityId)
            if entity ~= nil and HasMixin(entity, "Weldable") and entity:GetTeamNumber() == doerTeamNumber then
                return entity
            end
            
        end
        
    end
    
    return nil

end

Shared.LinkClassToMap( "Order", Order.kMapName, Order.networkVars )