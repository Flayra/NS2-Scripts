// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\OrdersMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

OrdersMixin = { }
OrdersMixin.type = "Orders"

OrdersMixin.expectedCallbacks =
{
    // GetExtents() is required by GetGroundAt().
    GetExtents = "Returns a Vector describing the extents of this Entity."
}

local kTimeSinceDamageDefendComplete = 10
local kDefendCompleteDistance = 5

function OrdersMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "OrdersMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        ignoreOrders    = "boolean",
        orderPosition   = "vector",
        orderType       = "enum kTechId"
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function OrdersMixin:__initmixin()

    self.ignoreOrders = false
    
    self.orderPosition = Vector(0, 0, 0)
    
    self.orderType = kTechId.None
    
    // Current orders. List of order entity ids.
    self.orders = { }
    
end

function OrdersMixin:TransferOrders(dest)
    
    table.copy(self.orders, dest.orders)
    dest:_OrderChanged()
    
    table.clear(self.orders)
    self:_OrderChanged()
    
end
AddFunctionContract(OrdersMixin.TransferOrders, { Arguments = { "Entity", "Entity" }, Returns = { } })

function OrdersMixin:GetHasOrder()
    return self:GetCurrentOrder() ~= nil
end
AddFunctionContract(OrdersMixin.GetHasOrder, { Arguments = { "Entity" }, Returns = { "boolean" } })

function OrdersMixin:GetNumOrders()
    return table.count(self.orders)
end
AddFunctionContract(OrdersMixin.GetNumOrders, { Arguments = { "Entity" }, Returns = { "number" } })

function OrdersMixin:SetIgnoreOrders(setIgnoreOrders)
    self.ignoreOrders = setIgnoreOrders
end
AddFunctionContract(OrdersMixin.SetIgnoreOrders, { Arguments = { "Entity", "boolean" }, Returns = { } })

function OrdersMixin:GetIgnoreOrders()
    return self.ignoreOrders
end
AddFunctionContract(OrdersMixin.GetIgnoreOrders, { Arguments = { "Entity" }, Returns = { "boolean" } })

/**
 * Children can provide a OnOverrideOrder function to issue build, construct, etc. orders on right-click.
 */
function OrdersMixin:_OverrideOrder(order)

    if self.OnOverrideOrder then
        self:OnOverrideOrder(order)
    elseif order:GetType() == kTechId.Default then
        order:SetType(kTechId.Move)
    end
    
end
AddFunctionContract(OrdersMixin._OverrideOrder, { Arguments = { "Entity", "Order" }, Returns = { } })

// Create order, set it, override it
function OrdersMixin:GiveOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst)

    ASSERT(type(orderType) == "number")
    ASSERT(type(targetId) == "number")
    
    if self.ignoreOrders then
        return kTechId.None
    end
    
    local order = CreateOrder(orderType, targetId, targetOrigin, orientation)
    
    self:_OverrideOrder(order)
    
    if clearExisting == nil then
        clearExisting = true
    end
    
    if insertFirst == nil then
        insertFirst = true
    end
    
    self:_SetOrder(order, clearExisting, insertFirst)
    
    return order:GetType()

end
AddFunctionContract(OrdersMixin.GiveOrder, { Arguments = { "Entity", "number", "number", { "Vector", "nil" }, { "Vector", "nil" }, { "boolean", "nil" }, { "boolean", "nil" } }, Returns = { "number" } })

function OrdersMixin:ClearOrders()

    if table.count(self.orders) > 0 then
    
        self:_DestroyOrders()
        self:_OrderChanged()
        
    end
    
end
AddFunctionContract(OrdersMixin.ClearOrders, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:Reset()
    self:ClearOrders()
end
AddFunctionContract(OrdersMixin.Reset, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:OnKill()
    self:ClearOrders()
end
AddFunctionContract(OrdersMixin.OnKill, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:_DestroyOrders()
    
    // Allow ents to hook destruction of current order.
    local first = true
    
    // Delete all order entities.
    for index, orderEntId in ipairs(self.orders) do
    
        local orderEnt = Shared.GetEntity(orderEntId)
        ASSERT(orderEnt ~= nil)
        
        if first then
        
            if self.OnDestroyCurrentOrder and orderEnt ~= nil then
                self:OnDestroyCurrentOrder(orderEnt)
            end
            first = false
            
        end
        
        DestroyEntity(orderEnt)            
        
    end
    
    table.clear(self.orders)

end
AddFunctionContract(OrdersMixin._DestroyOrders, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:GetHasSpecifiedOrder(orderEnt)

    ASSERT(orderEnt ~= nil and orderEnt.GetId ~= nil)
    
    for index, orderEntId in ipairs(self.orders) do
        if orderEntId == orderEnt:GetId() then
            return true
        end
    end
    
    return false

end
AddFunctionContract(OrdersMixin.GetHasSpecifiedOrder, { Arguments = { "Entity", "Order" }, Returns = { "boolean" } })

function OrdersMixin:_SetOrder(order, clearExisting, insertFirst)

    if self.ignoreOrders then
        return
    end
    
    if clearExisting then
        self:ClearOrders()
    end

    // Always snap the location of the order to the ground.
    local location = order:GetLocation()
    if location then
        location = GetGroundAt(self, location, PhysicsMask.AIMovement)
        order:SetLocation(location)
    end
    
    if insertFirst then
        table.insert(self.orders, 1, order:GetId())
    else    
        table.insert(self.orders, order:GetId())
    end
    
    self:_OrderChanged()

end
AddFunctionContract(OrdersMixin._SetOrder, { Arguments = { "Entity", "Order", "boolean", "boolean" }, Returns = { } })

function OrdersMixin:GetCurrentOrder()

    local currentOrder = nil
    
    if self.orders and table.maxn(self.orders) > 0 then
        local orderId = self.orders[1] 
        currentOrder = Shared.GetEntity(orderId)
        ASSERT(currentOrder ~= nil)
    end

    return currentOrder
    
end
AddFunctionContract(OrdersMixin.GetCurrentOrder, { Arguments = { "Entity" }, Returns = { { "Order", "nil" } } })

function OrdersMixin:ClearCurrentOrder()

    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        DestroyEntity(currentOrder)
        
        table.remove(self.orders, 1)
        
    end
    
    self:_OrderChanged()
    
end
AddFunctionContract(OrdersMixin.ClearCurrentOrder, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:CompletedCurrentOrder()

    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        if self.OnOrderComplete then
            self:OnOrderComplete(currentOrder)
        end
    
        self:ClearCurrentOrder()
        
    end
    
end
AddFunctionContract(OrdersMixin.CompletedCurrentOrder, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:_OrderChanged()
    
    if self:GetHasOrder() then
    
        local order = self:GetCurrentOrder()
        local orderLocation = order:GetLocation()
        self.orderPosition = nil
        if orderLocation then
            self.orderPosition = Vector(orderLocation)
        end
        self.orderType = order:GetType()
        
    end
    
    if self.OnOrderChanged then
        self:OnOrderChanged()
    end
    
end
AddFunctionContract(OrdersMixin._OrderChanged, { Arguments = { "Entity" }, Returns = { } })

// Convert rally orders to move and we're done.
function OrdersMixin:ProcessRallyOrder(originatingEntity)

    if self.ignoreOrders then
        return
    end
    
    originatingEntity:TransferOrders(self)
    
    // Convert rally orders to move and we're done
    for index, orderId in ipairs(self.orders) do
    
        local order = Shared.GetEntity(orderId)
        ASSERT(order ~= nil)
        
        if order:GetType() == kTechId.SetRally then
            order:SetType(kTechId.Move)
        end
        
    end
    
end
AddFunctionContract(OrdersMixin.ProcessRallyOrder, { Arguments = { "Entity", "Entity" }, Returns = { } })

function OrdersMixin:UpdateOrder()

    PROFILE("OrdersMixin:UpdateOrder")

    local currentOrder = self:GetCurrentOrder()
    
    if(currentOrder ~= nil) then
    
        local orderType = currentOrder:GetType()
        
        if orderType == kTechId.Move or orderType == kTechId.SquadMove then
        
            if (currentOrder:GetLocation() - self:GetOrigin()):GetLength() < 1.5 then
                
                self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
                self:CompletedCurrentOrder()
                
            end
        
        elseif orderType == kTechId.Construct then
        
            local orderTarget = Shared.GetEntity(currentOrder:GetParam())
            
            if orderTarget == nil or not orderTarget:GetIsAlive() or orderTarget:GetIsBuilt() then
                self:CompletedCurrentOrder()
            end
            
            if orderTarget ~= nil and orderTarget:GetIsBuilt() then
                self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
            end

        elseif orderType == kTechId.Attack then

            local orderTarget = Shared.GetEntity(currentOrder:GetParam())

            if not orderTarget or orderTarget:GetId() == Entity.invalidId then
            
                self:ClearOrders()
                
            elseif not HasMixin(orderTarget, "Live") or not orderTarget:GetIsAlive() then
            
                self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
                self:CompletedCurrentOrder()
                
            end
        
        elseif orderType == kTechId.SquadDefend then
            
            local orderTarget = Shared.GetEntity(currentOrder:GetParam())
            
            if not orderTarget or orderTarget:GetId() == Entity.invalidId or
               not HasMixin(orderTarget, "Live") or not orderTarget:GetIsAlive() then
            
                self:ClearOrders()
                
            elseif HasMixin(orderTarget, "Live") and (Shared.GetTime() - orderTarget:GetTimeOfLastDamage()) > kTimeSinceDamageDefendComplete then

                // Only complete if self is close enough to the target.
                if (self:GetOrigin() - orderTarget:GetOrigin()):GetLengthSquared() < (kDefendCompleteDistance * kDefendCompleteDistance) then
                    self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
                    self:CompletedCurrentOrder()
                else
                    self:ClearOrders()
                end
            
            end
            
        end
        
    end
    
end
AddFunctionContract(OrdersMixin.UpdateOrder, { Arguments = { "Entity" }, Returns = { } })

// Note: This needs to be tested.
// Get target of attack order, if any.
function OrdersMixin:GetTarget()

    local target = nil

    local order = self:GetCurrentOrder()
    if order ~= nil and (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) then
        target = Shared.GetEntity(order:GetParam())
    end
    
    return target
    
end

// Note: This needs to be tested.
function OrdersMixin:PerformAction(techNode, position)

    local results = { self:OnPerformAction(techNode, position) }
    
    // Return true if any of the callbacks returned true.
    for i, result in pairs(results) do
    
        if result then
            return true
        end
        
    end
    
    return false
    
end

/**
 * Other mixins can implement this function to handle more specific actions.
 * Called when tech tree action is performed on the entity.
 * Return true if legal and action handled. Position passed if applicable.
 */
function OrdersMixin:OnPerformAction(techNode, position)

    if techNode:GetTechId() == kTechId.Stop then
        self:ClearOrders()
        return true
    end
    
    return false
    
end