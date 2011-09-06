// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A buildable, potentially portable, marine power source.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'PowerPack' (Structure)

PowerPack.kMapName = "powerpack"

PowerPack.kModelName = PrecacheAsset("models/marine/portable_node/portable_node.model")

PowerPack.kRange = 12

if Server then
    Script.Load("lua/PowerPack_Server.lua")
end

function PowerPack:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function PowerPack:OnInit()

    self:SetModel(PowerPack.kModelName)
    
    Structure.OnInit(self)
    
end

function PowerPack:GetIsPowered()
    return self:GetIsAlive()
end

// Temporarily don't use "target" attach point
function PowerPack:GetEngagementPoint()
    return ScriptActor.GetEngagementPoint(self)
end

function PowerPack:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        local techButtons = {   kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
                                kTechId.None, kTechId.None, kTechId.None, kTechId.None }
        
        return techButtons
        
    end
    
    return nil
    
end

function PowerPack:GetRequiresPower()
    return false
end

Shared.LinkClassToMap("PowerPack", PowerPack.kMapName, {})

