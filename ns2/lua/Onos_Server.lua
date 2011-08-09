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
    self:GiveItem(BoneShield.kMapName)
    self:GiveItem(Stomp.kMapName)

    self:SetActiveWeapon(Gore.kMapName)
    
end
