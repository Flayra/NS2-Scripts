//=============================================================================
//
// lua\Weapons\Alien\Bomb.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
// Bile bomb projectile
//
//=============================================================================
Script.Load("lua/Weapons/Projectile.lua")

class 'Bomb' (Projectile)

Bomb.kMapName            = "bomb"
Bomb.kModelName          = PrecacheAsset("models/alien/gorge/bilebomb.model")

// The max amount of time a Bomb can last for
Bomb.kLifetime = 5
// 200 inches in NS1 = 5 meters
Bomb.kSplashRadius = 5

function Bomb:OnCreate()

    Projectile.OnCreate(self)
    
    self:SetModel( Bomb.kModelName )    
    
    // Remember when we're created so we can fall off damage
    self.createTime = Shared.GetTime()
        
end

function Bomb:OnInit()

    Projectile.OnInit(self)
    
    if Server then
        self:AddTimedCallback(Bomb.TimeUp, Bomb.kLifetime)
    end

end

function Bomb:GetDeathIconIndex()
    return kDeathMessageIcon.BileBomb
end

if (Server) then

    function Bomb:OnCollision(targetHit)

        // Don't hit owner - shooter
        if targetHit == nil or self:GetOwner() ~= targetHit then
        
            // Do splash damage to structures and ARCs
            local hitEntities = GetEntitiesForTeamWithinRange("Structure", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Bomb.kSplashRadius)
            table.copy(GetEntitiesForTeamWithinRange("ARC", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Bomb.kSplashRadius), hitEntities, true)
            table.copy(GetEntitiesForTeamWithinRange("MAC", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Bomb.kSplashRadius), hitEntities, true)
            
            // Do damage to every target in range
            RadiusDamage(hitEntities, self:GetOrigin(), Bomb.kSplashRadius, kBileBombDamage, self, false)
            
            self:TriggerEffects("bilebomb_hit")

            DestroyEntity(self)
                
        end    
        
    end
    
    function Bomb:TimeUp(currentRate)
    
        DestroyEntity(self)
        // Cancel the callback.
        return false
    
    end
    
end

function Bomb:OnUpdate(deltaTime)

    Projectile.OnUpdate(self, deltaTime)
    
    if Server then
        self:SetOrientationFromVelocity()
    end
    
end

Shared.LinkClassToMap("Bomb", Bomb.kMapName, {})