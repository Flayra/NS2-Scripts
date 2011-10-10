// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Onos:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(Gore.kMapName)
    
    if self:GetHasUpgrade(kTechId.BoneShield) then
        self:GiveItem(BoneShield.kMapName)
    end
    
    if self:GetHasUpgrade(kTechId.Stomp) then
        self:GiveItem(Stomp.kMapName)
    end

    self:SetActiveWeapon(Gore.kMapName)
    
end

function Onos:OnGiveUpgrade(techId)

    if techId == kTechId.BoneShield then
    
        self:GiveItem(BoneShield.kMapName)
        
    elseif techId == kTechId.Stomp then
    
        self:GiveItem(Stomp.kMapName)

    end
    
end

