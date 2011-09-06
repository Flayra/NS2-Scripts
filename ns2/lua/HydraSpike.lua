//=============================================================================
//
// lua\Weapons\Alien\Spike.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'HydraSpike' (Projectile)

HydraSpike.kMapName            = "hydraspike"
HydraSpike.kModelName          = PrecacheAsset("models/alien/lerk/lerk_view_spike.model")

HydraSpike.kDamage             = kHydraSpikeDamage

function HydraSpike:OnCreate()

    Projectile.OnCreate(self)
    self:SetModel( HydraSpike.kModelName )    
    self:SetUpdates(true)
    
end

function HydraSpike:GetDeathIconIndex()
    return kDeathMessageIcon.HydraSpike
end

if (Server) then

    function HydraSpike:OnCollision(targetHit)

        // Don't hit parent - shooter
        if targetHit == nil or (targetHit ~= nil and self:GetParentId() ~= targetHit:GetId()) then

            if targetHit ~= nil and HasMixin(targetHit, "Live") and GetGamerules():CanEntityDoDamageTo(self, targetHit) then
                targetHit:TakeDamage(HydraSpike.kDamage, self, self, self:GetOrigin(), nil)
            end            

            TriggerHitEffects(self, targetHit, self:GetOrigin(), nil, false)

            DestroyEntity(self)
                
        end    
        
    end
    
end

Shared.LinkClassToMap("HydraSpike", HydraSpike.kMapName, {})