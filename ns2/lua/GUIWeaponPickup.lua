
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIWeaponPickup.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kIconWidth = 128
local kIconHeight = 64

local kPickupBackgroundHeight = 32
local kPickupBackgroundSmallWidth = 32
local kPickupBackgroundBigWidth = 64
local kBackgroundWidthBuffer = 26
local kPickupBackgroundSmallCoords = { 7, 323, 38, 354 }
local kPickupBackgroundBigCoords = { 53, 323, 116, 354 }
local kBackgroundYOffset = -10

local kPickupKeyFontSize = 22
local kPickupTextFontSize = 20

local kIconsTextureName = "ui/pickup_icons.dds"
local kIconOffsets = { }
kIconOffsets["Rifle"] = 0
kIconOffsets["Shotgun"] = 1
kIconOffsets["Pistol"] = 2
kIconOffsets["Flamethrower"] = 3
kIconOffsets["GrenadeLauncher"] = 4

class 'GUIWeaponPickup' (GUIScript)

function GUIWeaponPickup:Initialize()

    self.pickupIcon = GUIManager:CreateGraphicItem()
    self.pickupIcon:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.pickupIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.pickupIcon:SetTexture(kIconsTextureName)
    self.pickupIcon:SetIsVisible(false)
    
    self.pickupKeyBackground = GUIManager:CreateGraphicItem()
    self.pickupKeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.pickupKeyBackground:SetTexture(kIconsTextureName)
    self.pickupIcon:AddChild(self.pickupKeyBackground)
    
    self.pickupKey = GUIManager:CreateTextItem()
    self.pickupKey:SetFontSize(kPickupKeyFontSize)
    self.pickupKey:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.pickupKey:SetTextAlignmentX(GUIItem.Align_Center)
    self.pickupKey:SetTextAlignmentY(GUIItem.Align_Center)
    self.pickupKey:SetColor(Color(0, 0, 0, 1))
    self.pickupKey:SetFontIsBold(true)
    self.pickupKey:SetText("")
    self.pickupKeyBackground:AddChild(self.pickupKey)

end

function GUIWeaponPickup:Uninitialize()
    
    GUI.DestroyItem(self.pickupKey)
    self.pickupKey = nil
    
    GUI.DestroyItem(self.pickupKeyBackground)
    self.pickupKeyBackground = nil
    
    GUI.DestroyItem(self.pickupIcon)
    self.pickupIcon = nil
    
end

function GUIWeaponPickup:ShowWeaponData(weaponType)

    self.pickupIcon:SetIsVisible(true)
    local iconIndex = kIconOffsets[weaponType]
    self.pickupIcon:SetTexturePixelCoordinates(0, iconIndex * kIconHeight, kIconWidth, (iconIndex + 1) * kIconHeight)
    self.pickupIcon:SetPosition(Vector(-kIconWidth / 2, (-kIconHeight / 2) + Client.GetScreenHeight() / 4, 0))
    
    local buttonText = BindingsUI_GetInputValue("Drop")
    self.pickupKey:SetText(buttonText)
    local buttonTextWidth = self.pickupKey:GetTextWidth(buttonText)
    
    local backgroundWidth = kPickupBackgroundSmallWidth
    local backgroundHeight = kPickupBackgroundHeight
    local backgroundTextureCoordinates = kPickupBackgroundSmallCoords
    if string.len(buttonText) > 2 then
        backgroundWidth = ((kPickupBackgroundBigWidth > buttonTextWidth + kBackgroundWidthBuffer) and kPickupBackgroundBigWidth) or (buttonTextWidth + kBackgroundWidthBuffer)
        backgroundTextureCoordinates = kPickupBackgroundBigCoords
    end
    
    self.pickupKeyBackground:SetPosition(Vector(-backgroundWidth / 2, -backgroundHeight + kBackgroundYOffset, 0))
    self.pickupKeyBackground:SetSize(Vector(backgroundWidth, backgroundHeight, 0))
    self.pickupKeyBackground:SetTexturePixelCoordinates(unpack(backgroundTextureCoordinates))

end

function GUIWeaponPickup:HideWeaponData()
    self.pickupIcon:SetIsVisible(false)
end