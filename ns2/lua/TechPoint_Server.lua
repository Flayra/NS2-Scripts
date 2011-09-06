// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechPoint_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function TechPoint:GetCanTakeDamageOverride()
    return false
end

function TechPoint:Reset()
    
    self:OnInit()
    
    self:ClearAttached()

    self:SetAnimation(TechPoint.kMarineAnim, true)
    
end

// Spawn command station or hive on tech point
function TechPoint:SpawnCommandStructure(teamNumber)

    local alienTeam = (GetGamerules():GetTeam(teamNumber):GetTeamType() == kAlienTeamType)
    local techId = ConditionalValue(alienTeam, kTechId.Hive, kTechId.CommandStation)
    
    return CreateEntityForTeam(techId, Vector(self:GetOrigin()), teamNumber)
    
end

function TechPoint:SetTechLevel(techLevel)
    self.techLevel = techLevel
end
