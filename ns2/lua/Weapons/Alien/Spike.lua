//=============================================================================
//
// lua\Weapons\Alien\Spike.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Spike' (Projectile)

Spike.kMapName            = "spike"
Spike.kModelName          = PrecacheAsset("models/alien/lerk/lerk_view_spike.model")

// Seconds
Spike.kDamageFalloffInterval = 1

// The max amount of time a Spike can last for
Spike.kLifetime = 5

function Spike:OnCreate()

    Projectile.OnCreate(self)
    self:SetModel( Spike.kModelName )    
    
    // Remember when we're created so we can fall off damage
    self.createTime = Shared.GetTime()
        
end

function Spike:OnInit()

    Projectile.OnInit(self)
    
    if Server then
        self:AddTimedCallback(Spike.TimeUp, Spike.kLifetime)
    end

end

function Spike:SetDeathIconIndex(index)
    self.iconIndex = index
end

function Spike:GetDeathIconIndex()
    return self.iconIndex
end

if (Server) then

    function Spike:OnCollision(targetHit)

        // Don't hit owner - shooter
        if targetHit == nil or self:GetOwner() ~= targetHit then
        
            local didDamage = false
            
            if targetHit == nil or (targetHit:isa("LiveScriptActor") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) then

                if targetHit ~= nil then
                
                    // Do max damage for short time and then fall off over time to encourage close quarters combat instead of 
                    // hanging back and sniping
                    if self:GetOwner() then
                        local damageScalar = ConditionalValue(self:GetOwner():GetHasUpgrade(kTechId.Piercing), kPiercingDamageScalar, 1)
                        local damageTimeScalar = 1 - Clamp( (Shared.GetTime() - self.createTime) / Spike.kDamageFalloffInterval, 0, 1)
                        local damage = Spike.kMinDamage + damageTimeScalar * (Spike.kMaxDamage - Spike.kMinDamage)
                        targetHit:TakeDamage(damage * damageScalar, self:GetOwner(), self, self:GetOrigin(), nil)
                        didDamage = true
                    end
        
                end

            end            

            // Play sound and particle effect.
            TriggerHitEffects(self, targetHit, self:GetOrigin(), nil, false)
            
            // Destroy first, just in case there are script errors below
            DestroyEntity(self)
                
        end    
        
    end
    
    function Spike:TimeUp(currentRate)
    
        DestroyEntity(self)
        // Cancel the callback.
        return false
    
    end
    
end

function Spike:OnUpdate(deltaTime)

    Projectile.OnUpdate(self, deltaTime)
    
    if Server then
        self:SetOrientationFromVelocity()
    end
    
end

Shared.LinkClassToMap("Spike", Spike.kMapName, {})