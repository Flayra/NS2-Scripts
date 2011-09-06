// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIOrders.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// Manages the orders that are drawn for selected units for the Commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIOrders' (GUIScript)

GUIOrders.kOrderImageName = "ui/marine_buildmenu.dds"

GUIOrders.kOrderTextureSize = 80
GUIOrders.kDefaultOrderSize = 25
GUIOrders.kMaxOrderSize = 200

GUIOrders.kOrderObstructedColor = Color(1, 1, 1, .75)
GUIOrders.kOrderVisibleColor = Color(1, 1, 1, 0)

function GUIOrders:Initialize()

    self.activeOrderList = { }
    self.currentFrame = 0
    
end

function GUIOrders:Uninitialize()

    for i, orderModel in ipairs(self.activeOrderList) do
        Client.DestroyRenderModel(orderModel)
    end
    self.activeOrderList = { }
    
end

function GUIOrders:Update(deltaTime)

    PROFILE("GUIOrders:Update")

    self:UpdateOrderList(PlayerUI_GetOrderInfo())
    
end

function GUIOrders:UpdateOrderList(orderList)
    
    local numElementsPerOrder = 4
    local numOrders = table.count(orderList) / numElementsPerOrder
    
    while numOrders > table.count(self.activeOrderList) do
        local newOrderItem = self:CreateOrderItem()       
        table.insert(self.activeOrderList, newOrderItem)
    end

    while table.count(self.activeOrderList) > numOrders do
        local orderModel = self.activeOrderList[table.count(self.activeOrderList)]
        Client.DestroyRenderModel(orderModel)
        table.remove(self.activeOrderList, table.count(self.activeOrderList))
    end    
    
    // Update current order state.
    local currentIndex = 1
    local orderIndex = 1
    
    while numOrders > 0 do
    
        local updateOrder = self.activeOrderList[orderIndex]        
        
        local radius = 1
        local orderLocation = orderList[currentIndex + 2]
        updateOrder:SetCoords(BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), orderLocation + Vector(0, kZFightingConstant, 0), radius * 2))        
        numOrders = numOrders - 1
        
        currentIndex = currentIndex + numElementsPerOrder
        orderIndex = orderIndex + 1
        
    end

end

function GUIOrders:CreateOrderItem()
    
    local modelIndex = Shared.GetModelIndex(Commander.kMarineCircleModelName)
    local newOrderItem = Client.CreateRenderModel(RenderScene.Zone_Default)
    newOrderItem:SetModel(modelIndex)
    return newOrderItem
    
end