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
    self:SetIsPowerSource(true)
end

function PowerPack:OnKill()
    Structure.OnKill(self)

    self:SetIsPowerSource(false)    
end

