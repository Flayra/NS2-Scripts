//=============================================================================
//
// lua\Weapons\Marine\Grenade.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Grenade' (Projectile)

Grenade.kMapName            = "grenade"
Grenade.kModelName          = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

Grenade.kDamageRadius       = kGrenadeLauncherGrenadeDamageRadius
Grenade.kMaxDamage          = kGrenadeLauncherGrenadeDamage
Grenade.kLifetime           = kGrenadeLifetime

function Grenade:OnCreate()

    Projectile.OnCreate(self)
    self:SetModel( Grenade.kModelName )
    
    // Explode after a bit
    self:SetNextThink(Grenade.kLifetime)
    
end

function Grenade:GetDeathIconIndex()
    return kDeathMessageIcon.Grenade
end

function Grenade:GetDamageType()
    return kGrenadeLauncherGrenadeDamageType
end

if (Server) then

    function Grenade:OnCollision(targetHit)
    
        if targetHit and (HasMixin(targetHit, "Live") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) and self:GetOwner() ~= targetHit then
            self:Detonate(targetHit)            
        else
            if self:GetVelocity():GetLength() > 2 then
                self:TriggerEffects("grenade_bounce")
            end
        end
        
    end    
    
    // Blow up after a time
    function Grenade:OnThink()
        self:Detonate(nil)
    end
    
    function Grenade:Detonate(targetHit)
    
        // Do damage to nearby targets.
        local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Grenade.kDamageRadius)
        
        // Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
        table.insertunique(hitEntities, self:GetOwner())
        
        RadiusDamage(hitEntities, self:GetOrigin(), Grenade.kDamageRadius, Grenade.kMaxDamage, self)
        
        local surface = GetSurfaceFromEntity(targetHit)        
        local params = {surface = surface}
        if not targetHit then
            params[kEffectHostCoords] = BuildCoords(Vector(0, 1, 0), self:GetCoords().zAxis, self:GetOrigin(), 1)
        end
        
        self:TriggerEffects("grenade_explode", params)

        DestroyEntity(self)
        
    end

end

Shared.LinkClassToMap("Grenade", Grenade.kMapName)