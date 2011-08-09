// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\HydraAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Gorge builds hydra.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")

class 'HydraAbility' (DropStructureAbility)

HydraAbility.kMapName = "hydra_ability"

function HydraAbility:GetEnergyCost(player)
    return 40
end

function HydraAbility:GetPrimaryAttackDelay()
    return 1.0
end

function HydraAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function HydraAbility:GetDropStructureId()
    return kTechId.Hydra
end

function HydraAbility:GetSuffixName()
    return "hydra"
end

function HydraAbility:GetDropClassName()
    return "Hydra"
end

function HydraAbility:GetDropMapName()
    return Hydra.kMapName
end

function HydraAbility:GetHUDSlot()
    return 2
end

Shared.LinkClassToMap("HydraAbility", HydraAbility.kMapName, {} )
