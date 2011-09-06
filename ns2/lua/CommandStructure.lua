// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'CommandStructure' (Structure)
CommandStructure.kMapName = "commandstructure"

if (Server) then
    Script.Load("lua/CommandStructure_Server.lua")
end

CommandStructure.networkVars = 
{
    occupied            = "boolean",
    commanderId         = "entityid",
}

function CommandStructure:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)
    
    self.occupied = false
    self.commanderId = Entity.invalidId
    
    self.maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth)
    self.health = self.maxHealth
    
end

function CommandStructure:GetIsOccupied()
    return self.occupied
end

function CommandStructure:GetEffectParams(tableParams)

    Structure.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterOccupied] = self.occupied
    
end

Shared.LinkClassToMap("CommandStructure", CommandStructure.kMapName, CommandStructure.networkVars)