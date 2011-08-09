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
SporeCloud.kThinkInterval = .5  // From NS1
SporeCloud.kDamage = kSporesDamagePerSecond * SporeCloud.kThinkInterval
SporeCloud.kDamageRadius = 3    // 5.7 in NS1
SporeCloud.kLifetime = 6.0      // From NS1

// Keep table of entities that have been hurt by spores to make
// spores non-stackable. List of {entityId, time} pairs.
gHurtBySpores = {}

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
    
    local scalar = Clamp(((Shared.GetTime() - self.createTime) / SporeCloud.kLifetime) * 12, 0, 1)
    return scalar * SporeCloud.kDamageRadius
    
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
    
        if (entity:GetOrigin() - self:GetOrigin()):GetLength() < damageRadius then

            if not entity:isa("Commander") and not GetEntityRecentlyHurt(entity:GetId(), (time - SporeCloud.kThinkInterval)) then

                // Make sure spores can "see" target
                local targetPosition = entity:GetOrigin() + Vector(0, entity:GetExtents().y, 0)
                local trace = Shared.TraceRay(self:GetOrigin(), targetPosition, PhysicsMask.Bullets, filterNonDoors)
                if trace.fraction == 1.0 or trace.entity == entity then
                
                    entity:TakeDamage(SporeCloud.kDamage, self:GetOwner(), self)
                    
                    // Spores can't hurt this entity for SporeCloud.kThinkInterval
                    SetEntityRecentlyHurt(entity:GetId())
                    
                end
                
            end
            
        end
        
    end
    
    if Shared.GetTime() > (self.createTime + SporeCloud.kLifetime) then
        DestroyEntity(self)        
    else
        self:SetNextThink(SporeCloud.kThinkInterval)
    end
    
end

function SporeCloud:OnInit()

    ScriptActor.OnInit(self)
    
    self:SetUpdates(true)

    if Server then
        self:SetNextThink(SporeCloud.kThinkInterval)
    end
    
    /* For debugging damage radius */    
    /*if Client then
        self:SetUpdates(true)
    end*/
    
    self.createTime = Shared.GetTime()
    
end

/* For debugging damage radius */       
/*
function SporeCloud:OnUpdate(deltaTime)
    if Client then
        local damageRadius = self:GetDamageRadius()
        DebugCapsule(self:GetOrigin(), self:GetOrigin(), damageRadius, 0, deltaTime)
    end
end
*/

Shared.LinkClassToMap("SporeCloud", SporeCloud.kMapName, {} )
