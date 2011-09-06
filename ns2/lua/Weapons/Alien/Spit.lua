//=============================================================================
//
// lua\Weapons\Alien\Spit.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Spit' (Projectile)

Spit.kMapName            = "spit"
Spit.kModelName          = PrecacheAsset("models/alien/gorge/spit_proj.model")
Spit.kSpitHitSound       = PrecacheAsset("sound/ns2.fev/alien/gorge/spit_hit")
Spit.kSpitHitEffect      = PrecacheAsset("cinematics/alien/gorge/spit_impact.cinematic")
Spit.kDamage             = kSpitDamage

function Spit:OnInit()

    Projectile.OnInit(self)
    
    self:SetModel( Spit.kModelName )
    
end

function Spit:OnDestroy()

    if Server then
        self:SetOwner(nil)
    end
    
    Projectile.OnDestroy(self)

end

function Spit:GetDeathIconIndex()
    return kDeathMessageIcon.Spit
end

if (Server) then

    function Spit:OnCollision(targetHit)

        // Don't hit owner - shooter
        if targetHit == nil or self:GetOwner() ~= targetHit then
        
            local didDamage = false
            
            if targetHit == nil or (HasMixin(targetHit, "Live") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) then

                if targetHit ~= nil then
                
                    targetHit:TakeDamage(Spit.kDamage, self:GetOwner(), self, self:GetOrigin(), nil)
                    didDamage = true
                    
                end

            end            
            
            if not didDamage then
                TriggerHitEffects(self, targetHit, self:GetOrigin(), nil, false)
            end
            
            // Destroy first, just in case there are script errors below
            DestroyEntity(self)
                
        end    
        
    end
    
end

Shared.LinkClassToMap("Spit", Spit.kMapName)