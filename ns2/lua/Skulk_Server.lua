// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Skulk:InitWeapons()

    Alien.InitWeapons(self)
    
    self:GiveItem(BiteLeap.kMapName)
    self:GiveItem(Parasite.kMapName)
    
    self:SetActiveWeapon(BiteLeap.kMapName)
    
end

// Handle carapace
function Skulk:GetHealthPerArmorOverride(damageType, currentHealthPerArmor)

    if ( self:GetHasUpgrade(kTechId.Carapace) ) then
    
        return kCarapaceHealthPerArmor
    
    end
    
    return currentHealthPerArmor
    
end
