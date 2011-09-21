
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIPickups.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying icons over entities on the ground the local player can pickup.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kPickupsVisibleRange = 15

local function GetNearbyPickups()

    local localPlayer = Client.GetLocalPlayer()
    
    if localPlayer then
    
        local team = localPlayer:GetTeamNumber()
        local origin = localPlayer:GetOrigin()
        
        local function PickupableFilterFunction(entity)
        
            local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (kPickupsVisibleRange * kPickupsVisibleRange)
            local sameTeam = entity:GetTeamNumber() == team
            local canPickup = entity:GetIsValidRecipient(localPlayer)
            return inRange and sameTeam and canPickup
            
        end
        
        return GetEntitiesWithFilter(Shared.GetEntitiesWithTag("Pickupable"), PickupableFilterFunction)
        
    end
    
    return nil

end

local kPickupTextureYOffsets = { }
kPickupTextureYOffsets["AmmoPack"] = 0
kPickupTextureYOffsets["MedPack"] = 1
kPickupTextureYOffsets["Weapon"] = 2

local kPickupIconHeight = 64
local kPickupIconWidth = 64

local function GetPickupTextureCoordinates(pickup)

    local yOffset = nil
    for pickupType, pickupTextureYOffset in pairs(kPickupTextureYOffsets) do
    
        if pickup:isa(pickupType) then
        
            yOffset = pickupTextureYOffset
            break
            
        end
        
    end
    assert(yOffset)
    
    return 0, yOffset * kPickupIconHeight, kPickupIconWidth, (yOffset + 1) * kPickupIconHeight

end

local kMinPickupSize = 16
local kMaxPickupSize = 48
// Note: This graphic can probably be smaller as we don't need the icons to be so big.
local kTextureName = "ui/drop_icons.dds"
local kIconWorldOffset = Vector(0, 0.5, 0)
local kBounceSpeed = 2
local kBounceAmount = 0.05

class 'GUIPickups' (GUIScript)

function GUIPickups:Initialize()

    self.allPickupGraphics = { }

end

function GUIPickups:Uninitialize()

    for i, pickupGraphic in ipairs(self.allPickupGraphics) do
        GUI.DestroyItem(pickupGraphic)
    end
    self.allPickupGraphics = { }

end

function GUIPickups:GetFreePickupGraphic()

    for i, pickupGraphic in ipairs(self.allPickupGraphics) do
    
        if pickupGraphic:GetIsVisible() == false then
            return pickupGraphic
        end
    
    end
    
    local newPickupGraphic = GUIManager:CreateGraphicItem()
    newPickupGraphic:SetAnchor(GUIItem.Left, GUIItem.Top)
    newPickupGraphic:SetTexture(kTextureName)
    newPickupGraphic:SetIsVisible(false)
    
    table.insert(self.allPickupGraphics, newPickupGraphic)
    
    return newPickupGraphic

end

function GUIPickups:Update(deltaTime)

    PROFILE("GUIPickups:Update")
    
    local localPlayer = Client.GetLocalPlayer()
    
    if localPlayer then
    
        for i, pickupGraphic in ipairs(self.allPickupGraphics) do
            pickupGraphic:SetIsVisible(false)
        end
        
        local nearbyPickups = GetNearbyPickups()
        for i, pickup in ipairs(nearbyPickups) do
        
            // Check if the pickup is in front of the player.
            local playerForward = localPlayer:GetCoords().zAxis
            local playerToPickup = GetNormalizedVector(pickup:GetOrigin() - localPlayer:GetOrigin())
            local dotProduct = Math.DotProduct(playerForward, playerToPickup)
            
            if dotProduct > 0 then
            
                local freePickupGraphic = self:GetFreePickupGraphic()
                freePickupGraphic:SetIsVisible(true)
                
                local distance = (pickup:GetOrigin() - localPlayer:GetOrigin()):GetLengthSquared()
                distance = distance / (kPickupsVisibleRange * kPickupsVisibleRange)
                distance = 1 - distance
                freePickupGraphic:SetColor(Color(1, 1, 1, distance))
                
                local pickupSize = kMinPickupSize + ((kMaxPickupSize - kMinPickupSize) * distance)
                freePickupGraphic:SetSize(Vector(pickupSize, pickupSize, 0))
                
                local bounceAmount = math.sin(Shared.GetTime() * kBounceSpeed) * kBounceAmount
                local pickupWorldPosition = pickup:GetOrigin() + kIconWorldOffset + Vector(0, bounceAmount, 0)
                local pickupInScreenspace = Client.WorldToScreen(pickupWorldPosition)
                // Adjust for the size so it is in the middle.
                pickupInScreenspace = pickupInScreenspace + Vector(-pickupSize / 2, -pickupSize / 2, 0)
                freePickupGraphic:SetPosition(pickupInScreenspace)
                
                freePickupGraphic:SetTexturePixelCoordinates(GetPickupTextureCoordinates(pickup))
                
            end
        
        end
        
    end
    
end