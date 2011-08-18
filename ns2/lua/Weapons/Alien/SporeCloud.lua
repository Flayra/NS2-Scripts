// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SporeCloud.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'SporeCloud' (ScriptActor)

// Spores didn't stack in NS1 so consider that
SporeCloud.kMapName = "sporecloud"

// Damage per think interval (from NS1)
SporeCloud.kThinkInterval = .25  // .5 in NS1, reducing to make sure sprinting machines take damage

// Keep table of entities that have been hurt by spores to make
// spores non-stackable. List of {entityId, time} pairs.
gHurtBySpores = {}

SporeCloud.networkVars =
{
    radius = "float",
    altMode = "boolean",
}

function GetEntityRecentlyHurt(entityId, time)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId and pair[2] > time then
            return true
        end
    end
    
    return false
    
end

function SetEntityRecentlyHurt(entityId)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId then
            table.remove(gHurtBySpores, index)
        end
    end
    
    table.insert(gHurtBySpores, {entityId, Shared.GetTime()})
    
end

function SporeCloud:GetDamageType()
    return kDamageType.Gas
end

function SporeCloud:GetDeathIconIndex()
    return kDeathMessageIcon.SporeCloud
end

// Have damage radius grow to maximum non-instantly
function SporeCloud:GetDamageRadius()
    
    local scalar = Clamp((Shared.GetTime() - self.createTime) * 3, 0, 1)
    return scalar * self.radius
    
end

function SporeCloud:OnThink()

    ScriptActor.OnThink(self)

    // Expire after a time
    local time = Shared.GetTime()
    local enemies = GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber()))
    local damageRadius = self:GetDamageRadius()
    
    // When checking if spore cloud can reach something, only walls and door entities will block the damage.
    local filterNonDoors = EntityFilterAllButIsa("Door")
    for index, entity in ipairs(enemies) do
    
        local attackPoint = entity:GetModelOrigin()
        
        if (attackPoint - self:GetOrigin()):GetLength() < damageRadius then

            if not entity:isa("Commander") and not GetEntityRecentlyHurt(entity:GetId(), (time - SporeCloud.kThinkInterval)) then

                // Make sure spores can "see" target
                local trace = Shared.TraceRay(self:GetOrigin(), attackPoint, PhysicsMask.Bullets, filterNonDoors)
                if trace.fraction == 1.0 or trace.entity == entity then
                
                    entity:TakeDamage(self.damage * SporeCloud.kThinkInterval, self:GetOwner(), self)
                    
                    // Spores can't hurt this entity for SporeCloud.kThinkInterval
                    SetEntityRecentlyHurt(entity:GetId())
                    
                end
                
            end
            
        end
        
    end
    
    if Shared.GetTime() > (self.createTime + self.lifetime) then
        DestroyEntity(self)        
    else
        self:SetNextThink(SporeCloud.kThinkInterval)
    end
    
end

function SporeCloud:OnInit()

    ScriptActor.OnInit(self)
    
    if Server then
        self:SetNextThink(SporeCloud.kThinkInterval)
    end
    
    /* For debugging damage radius */    
    /*
    if Client then
        self:SetUpdates(true)
    end
    */
    
    self.createTime = Shared.GetTime()
    self.altMode = false
    
end

function SporeCloud:SetLifetime(lifetime)
    self.lifetime = lifetime
end

function SporeCloud:SetDamage(damage)
    self.damage = damage
end

function SporeCloud:SetRadius(radius)
    self.radius = radius
end

/* For debugging damage radius */       
/*
function SporeCloud:OnUpdate(deltaTime)
    if Client then
        local damageRadius = self:GetDamageRadius()
        DebugCapsule(self:GetOrigin(), self:GetOrigin(), damageRadius, 0, deltaTime)
    end
end*/

function SporeCloud:GetEffectParams(tableParams)

    ScriptActor.GetEffectParams(self, tableParams)

    tableParams[kEffectFilterInAltMode] = self.altMode
        
end

// Used on client to play effects for either dust cloud or regular cloud
function SporeCloud:SetAltMode(altMode)
    self.altMode = altMode
end

Shared.LinkClassToMap("SporeCloud", SporeCloud.kMapName, SporeCloud.networkVars )
