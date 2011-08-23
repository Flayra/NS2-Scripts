// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPack_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A buildable, potentially portable, marine power source.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

function PowerPack:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:UpdateNearbyPowerState()

end

// Needed for recycling 
function PowerPack:OnDestroy()

    Structure.OnDestroy(self)
    
    self:UpdateNearbyPowerState()
    
end

function PowerPack:UpdateNearbyPowerState()

    // Trigger event to update power for nearby structures
    local structures = GetEntitiesForTeamWithinXZRange("Structure", self:GetTeamNumber(), self:GetOrigin(), PowerPack.kRange)

    for index, structure in ipairs(structures) do
    
        structure:UpdatePoweredState()
        
    end

end


