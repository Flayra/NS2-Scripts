// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Heavy.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Marine.lua")

class 'Heavy' (Marine)

Heavy.kMapName = "heavy"

Heavy.kModelName = PrecacheAsset("models/marine/heavy/heavy.model")

Heavy.kHealth = kExosuitHealth
Heavy.kBaseArmor = kExosuitArmor
Heavy.kWalkMaxSpeed = 1.38
Heavy.kViewOffsetHeight = 2.3
Heavy.kAcceleration = 20
Heavy.kSprintAcceleration = 30
Heavy.kXZExtents = .55
Heavy.kYExtents = 1.2

// Overlay animations translate to "weaponname_overlayname" for marines.
// So "fire" translates to "rifle_fire" for marines but "bite" is just "bite" for aliens.
// If marine has no weapon (in ready room), then overlay anims will be just the basic names.
Heavy.kAnimOverlayFire = "fire"

function Heavy:OnInit()

    Marine.OnInit(self)
    
    self.health    = Heavy.kHealth
    self.maxHealth = Heavy.kHealth    
    
    VectorCopy(Vector(Heavy.kXZExtents, Heavy.kYExtents, Heavy.kXZExtents), self.maxExtents)
                      
end

function Heavy:InitWeapons()
end

function Heavy:GetMaxViewOffsetHeight()
    return Heavy.kViewOffsetHeight
end

function Heavy:GetArmorAmount()

    local armorLevels = 0
    
    if(GetHasTech(self, kTechId.Armor3)) then
        armorLevels = 3
    elseif(GetHasTech(self, kTechId.Armor2)) then
        armorLevels = 2
    elseif(GetHasTech(self, kTechId.Armor1)) then
        armorLevels = 1
    end
    
    return Heavy.kBaseArmor + armorLevels*kExosuitArmorPerUpgradeLevel
    
end

function Heavy:GetAcceleration()
    return ConditionalValue(self.sprinting, Heavy.kSprintAcceleration, Heavy.kAcceleration)
end

function Heavy:GetMaxSpeed()
    return Heavy.kWalkMaxSpeed
end

Shared.LinkClassToMap( "Heavy", Heavy.kMapName, {} )