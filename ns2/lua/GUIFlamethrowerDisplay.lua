// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIFlamethrowerDisplay.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Displays the ammo counter for the shotgun.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

// Global state that can be externally set to adjust the display.
weaponClip     = 0
weaponAmmo     = 0
weaponAuxClip  = 0

bulletDisplay  = nil

//GUIFlamethrowerDisplay.kClipDisplay = { 0, 198, 20, 103 }

class 'GUIFlamethrowerDisplay' (GUIScript)

function GUIFlamethrowerDisplay:Initialize()

    self.weaponClip     = 0
    self.weaponAmmo     = 0
    self.maxClip = 14
    self.maxAmmo = 60
    self.maxClipHeight = 80
    self.maxAmmoWidth = 210

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize( Vector(256, 128, 0) )
    self.background:SetPosition( Vector(0, 0, 0))    
    self.background:SetTexture("ui/FlamethrowerDisplay.dds")
    
    self.ammoDisplayBg = GUIManager:CreateGraphicItem()
    self.ammoDisplayBg:SetSize( Vector(-210, 8, 0) )
    self.ammoDisplayBg:SetPosition( Vector(230, 7, 0))
    self.ammoDisplayBg:SetColor(Color(0.2, 0.65, 0.9, 0.2))
    
    self.clipDisplayBg = GUIManager:CreateGraphicItem()
    self.clipDisplayBg:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.clipDisplayBg:SetSize( Vector(170, -90, 0) )
    self.clipDisplayBg:SetPosition( Vector(-90, 50, 0))
    self.clipDisplayBg:SetColor(Color(0.2, 0.65, 0.9, 0.2))
    
    self.ammoDisplay = GUIManager:CreateGraphicItem()
    self.ammoDisplay:SetSize( Vector(-0, 8, 0) )
    self.ammoDisplay:SetPosition( Vector(230, 7, 0))
    self.ammoDisplay:SetColor(Color(0.2, 0.65, 0.9, 0.99))
    
    self.clipDisplay = GUIManager:CreateGraphicItem()
    self.clipDisplay:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.clipDisplay:SetSize( Vector(140, -0, 0) )
    self.clipDisplay:SetPosition( Vector(-75, 50, 0))
    self.clipDisplay:SetColor(Color(0.2, 0.65, 0.9, 0.99))
    
    
    self.background:AddChild(self.ammoDisplayBg)
    self.background:AddChild(self.clipDisplayBg)
    self.background:AddChild(self.ammoDisplay)
    self.background:AddChild(self.clipDisplay)
    
    // Force an update so our initial state is correct.
    self:Update(0)

end

function GUIFlamethrowerDisplay:Update(deltaTime)

    PROFILE("GUIFlamethrowerDisplay:Update")
    
    // Update the clip and ammo counter.
    local clipFraction = self.weaponClip / self.maxClip
    local clipHeigth = self.maxClipHeight * clipFraction * -1
    
    local ammoFraction = self.weaponAmmo / self.maxAmmo
    local ammoWidth = self.maxAmmoWidth * ammoFraction * -1
    
    self.clipDisplay:SetSize( Vector(140, clipHeigth, 0) )
    self.ammoDisplay:SetSize( Vector(ammoWidth, 8, 0) )
    
end

function GUIFlamethrowerDisplay:SetClip(weaponClip)
    self.weaponClip = weaponClip
end

function GUIFlamethrowerDisplay:SetClipSize(weaponClipSize)
    self.weaponClipSize = weaponClipSize
end

function GUIFlamethrowerDisplay:SetAmmo(weaponAmmo)
    self.weaponAmmo = weaponAmmo
end

/**
 * Called by the player to update the components.
 */
function Update(deltaTime)

    bulletDisplay:SetClip(weaponClip)
    bulletDisplay:SetAmmo(weaponAmmo)
    bulletDisplay:Update(deltaTime)
        
end

/**
 * Initializes the player components.
 */
function Initialize()

    GUI.SetSize( 256, 128 )

    bulletDisplay = GUIFlamethrowerDisplay()
    bulletDisplay:Initialize()
    bulletDisplay:SetClipSize(50)

end

Initialize()
