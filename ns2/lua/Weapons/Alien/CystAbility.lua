// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\CystAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Gorge builds hydra.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'CystAbility' (DropStructureAbility)

CystAbility.kMapName = "cyst_ability"

function CystAbility:GetEnergyCost(player)
    return 40
end

function CystAbility:GetPrimaryAttackDelay()
    return 1.0
end

function CystAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function CystAbility:GetDropStructureId()
    return kTechId.MiniCyst
end

function CystAbility:GetSuffixName()
    return "minicyst"
end

function CystAbility:GetDropClassName()
    return "MiniCyst"
end

function CystAbility:GetDropMapName()
    return MiniCyst.kMapName
end

function CystAbility:GetHUDSlot()
    return 3
end

function CystAbility:GetConnection()

    PROFILE("CystAbility:GetConnection")

    local player = self:GetParent()
    local coords = self:GetPositionForStructure(player)
    return GetCystParentFromPoint(coords.origin, coords.yAxis)
    
end

function CystAbility:GetGhostModelName()

    // Use a different model if we're within connection range or not
    local connectedEnt = self:GetConnection()
    return ConditionalValue(connectedEnt, MiniCyst.kModelName, MiniCyst.kOffModelName)
    
end

function CystAbility:CreateStructure(coords, player)

    // Create mini cyst
    local cyst, connected = CreateCyst(player, coords.origin, coords.yAxis, true)
    
    // Set initial model on cyst depending if we're connected or not
    if cyst then
        local modelName = cyst:GetCystModelName(connected)
        cyst:SetModel(modelName)
    end
    
    return cyst
    
end

/* Uncomment to see lines to connection
if Client then
function CystAbility:OnUpdate(deltaTime)

    DropStructureAbility.OnUpdate(self, deltaTime)
    
    local connectedEnt, connectedTrack = self:GetConnection()
    if connectedEnt then
        local player = self:GetParent()
        local coords = self:GetPositionForStructure(player)
        DebugLine(coords.origin, connectedEnt:GetModelOrigin(), 1, 0, 0, 1, 0, 1)
    end
    
end
end
*/

Shared.LinkClassToMap("CystAbility", CystAbility.kMapName, {} )
