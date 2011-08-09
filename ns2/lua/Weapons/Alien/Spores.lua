// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Spores.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/SporeCloud.lua")

class 'Spores' (Ability)

Spores.kMapName = "spores"
Spores.kDelay = kSporesFireDelay
Spores.kSwitchTime = .5

// Points per second
Spores.kDamage = kSporesDamagePerSecond

local networkVars = {
    sporePoseParam     = "compensated float"
}

function Spores:OnCreate()
    Ability.OnCreate(self)
    self.sporePoseParam = 0
end

function Spores:GetEnergyCost(player)
    return kSporesEnergyCost
end

function Spores:GetPrimaryAttackDelay()
    return Spores.kDelay
end

function Spores:GetIconOffsetY(secondary)
    return kAbilityOffset.Spores
end

function Spores:PerformPrimaryAttack(player)
    
    player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))

    // Trace instant line to where it should hit
    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()    
    local startPoint = player:GetEyePos()

    local trace = Shared.TraceRay(startPoint, startPoint + viewCoords.zAxis * kLerkSporeShootRange, PhysicsMask.Bullets, EntityFilterOne(player))
    
    // Create spore cloud that will damage players
    if Server then
   
        local spawnPoint = trace.endPoint + (trace.normal * 0.5)
        local spores = CreateEntity(SporeCloud.kMapName, spawnPoint, player:GetTeamNumber())
        spores:SetOwner(player)

        self:TriggerEffects("spores", {effecthostcoords = Coords.GetTranslation(spawnPoint) })

    end
    
    return true
        
end

function Spores:GetHUDSlot()
    return 2
end

function Spores:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)
    
    self.sporePoseParam = Clamp(Slerp(self.sporePoseParam, 1, (1 / kLerkWeaponSwitchTime) * input.time), 0, 1)
    
    viewModel:SetPoseParam("spore", self.sporePoseParam)
    
end

Shared.LinkClassToMap("Spores", Spores.kMapName, networkVars )
