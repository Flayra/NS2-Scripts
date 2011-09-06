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
Script.Load("lua/LoopingSoundMixin.lua")

class 'Spores' (Ability)

Spores.kMapName = "spores"
Spores.kSwitchTime = .5
Spores.kSporeDustCloudLifetime = 8.0      
Spores.kSporeCloudLifetime = 6.0      // From NS1
Spores.kSporeDustCloudDPS = kSporesDustDamagePerSecond
Spores.kSporeCloudDPS = kSporesDamagePerSecond
Spores.kSporeDustCloudRadius = 1.5
Spores.kSporeCloudRadius = 3    // 5.7 in NS1
Spores.kLoopingDustSound = PrecacheAsset("sound/ns2.fev/alien/lerk/spore_spray")

// Points per second
Spores.kDamage = kSporesDamagePerSecond

local networkVars = {
    sporePoseParam     = "compensated float",
}

PrepareClassForMixin(Spores, LoopingSoundMixin)

function Spores:OnCreate()
    Ability.OnCreate(self)
    self.sporePoseParam = 0
end

function Spores:OnInit()
    Ability.OnInit(self)
    InitMixin(self, LoopingSoundMixin)
end

function Spores:GetEnergyCost(player)
    return kSporesDustEnergyCost
end

/*
function Spores:GetSecondaryEnergyCost(player)
    return kSporesCloudEnergyCost
end
*/

function Spores:GetPrimaryAttackDelay()
    return kSporesDustFireDelay
end

/*
function Spores:GetSecondaryAttackDelay()
    return kSporesCloudFireDelay
end
*/

function Spores:GetIconOffsetY(secondary)
    return kAbilityOffset.Spores
end

local function CreateSporeCloud(origin, player, lifetime, damage, radius)

    local spores = CreateEntity(SporeCloud.kMapName, origin, player:GetTeamNumber())
    
    spores:SetOwner(player)
    spores:SetLifetime(lifetime) 
    spores:SetDamage(damage) 
    spores:SetRadius(radius)  
    spores:SetCoords(player:GetCoords())
    
    return spores
    
end

function Spores:PerformPrimaryAttack(player)

    // Create long-lasting spore cloud near player that can be used to prevent marines from passing through an area
    player:SetActivityEnd(player:AdjustAttackDelay(self:GetPrimaryAttackDelay()))
    
    if Server then
    
        local origin = player:GetModelOrigin()
        local sporecloud = CreateSporeCloud(origin, player, Spores.kSporeDustCloudLifetime, Spores.kSporeDustCloudDPS, Spores.kSporeDustCloudRadius)
        if not self:GetIsLoopingSoundPlaying() then
            self:PlayLoopingSound(player, Spores.kLoopingDustSound)
        end
        
    end
    
    return true
    
end

function Spores:OnStopLoopingSound(parent)
end

function Spores:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    self:StopLoopingSound(player)
    
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
