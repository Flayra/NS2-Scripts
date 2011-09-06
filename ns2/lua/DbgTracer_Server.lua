// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DbgTracer
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// Centralized handling of server-side tracing of targeting/shooting/projectiles
//

Script.Load("lua/DbgTracer.lua")
Script.Load("lua/DbgTracer_Commands.lua")

function DbgTracer:Init()

    self.targetingTracer = DbgTargetingTracer()
    self.targetingTracer:Init("targetings", 0.25, { 0, 0, 1, 0.8 })
        
    self.projectileTracer = DbgProjectileTracer()
    DbgProjectileTracer:Init("projectiles", 1,{ 0, 1, 0, 0.8 }) 
    
    self.bulletHitTracer = DbgBulletTracer()
    self.bulletHitTracer:Init("bulletHits", 3, { 1, 0, 0, 0.8 }, true)
    
    self.bulletMissTracer = DbgBulletTracer()
    self.bulletMissTracer:Init("bulletMisses", 0.3, { 0, 1, 0, 0.8 })
    
    self.meleeHitTracer = DbgMeleeTracer()
    self.meleeHitTracer:Init("meleeHits", 3, { 1, 0, 0, 0.8 }, true)
    
    self.meleeMissTracer = DbgMeleeTracer()
    self.meleeMissTracer:Init("meleeMisses", 1, { 0, 1, 0, 0.8 })
    
    // collect all our tracers.
    self.tracers = {
        self.targetingTracer,
        self.projectileTracer, 
        self.bulletHitTracer,
        self.bulletMissTracer,
        self.meleeHitTracer,
        self.meleeMissTracer }
end

/**
 * Trace the given projectile entity.
 * projectiles are a bit bitchy ... we trace them by drawing from old point to new point
 * alternating - that cuts down on the number of DebugLines we do.
 */
function DbgTracer:TraceProjectile(entity) 
    self.projectileTracer:Trace(entity)
end

/**
 * Trace a shot from the given shooter, starting at startPoint and with the resulting trace
 */
function DbgTracer:TraceBullet(attacker, startPoint, trace)
    self:_TraceHitMiss(attacker, startPoint, trace, self.bulletHitTracer, self.bulletMissTracer)
end

function DbgTracer:TraceMelee(attacker, startPoint, trace, capsule)
    self:_TraceHitMiss(attacker, startPoint, trace, self.meleeHitTracer, self.meleeMissTracer, capsule)
end

/**
 * Trace a targeting attempt.
 */
function DbgTracer:TraceTargeting(attacker, target, startPoint, trace)
    if attacker:isa("Hydra") or attacker:isa("Sentry") or attacker:isa("Whip") then
        self.targetingTracer:Trace(attacker, target, startPoint, trace)
    end
end


function DbgTracer:_TraceHitMiss(attacker, startPoint, trace, hitTracer, missTracer, capsule)
     if trace.entity ~= nil and HasMixin(trace.entity, "Live") then
        hitTracer:Trace(attacker, startPoint, trace, capsule)
    else
        missTracer:Trace(attacker, startPoint, trace, capsule)
    end   
end


function DbgTracer:OnUpdate(deltaTime)
    for _,tracer in ipairs(self.tracers) do
        tracer:Flush()
    end
end

function DbgTracer:Toggle(name)
    local msg = nil
    if name and string.len(name) > 0 then
        for _,tracer in ipairs(self.tracers) do
            if name=="all" or 1 == string.find(tracer.name, name) then
                tracer:Toggle()
                msg = (msg and (msg .. ", ") or "Toggled: ") .. tracer.name 
            end
        end
    end
    return msg
end

function DbgTracer:SetDuration(name, duration)
    local msg = nil
    if name and string.len(name) > 0 then
        for _,tracer in ipairs(self.tracers) do
            if name=="all" or 1 == string.find(tracer.name, name) then
                tracer.duration = duration
                msg = (msg and (msg .. ", ") or "Duration set to " .. duration .. " for : ") .. tracer.name 
            end
        end
    end
    return msg
end

function DbgTracer:StatusMsg(result)
    result = result or "Usage: trace <prefix>. Tracers with matching prefixes will toggle.\n      tracedur <prefix> <duration>. Changes lifetime of traces"
    for _,tracer in ipairs(self.tracers) do
        result = result .. "\n" .. tracer.name .. " = " .. tracer:Status() .. ", dur " .. tracer.duration
    end
    return result
end


function DbgTracer:GetTracer(name)
    for _,tracer in ipairs(self.tracers) do
        if tracer.name == name then
            return tracer
        end
    end    
    return nil
end



/**
 * Base individually enabled tracer class.
 * Keeps track of enabled status, and duration/color of line to draw.
 *
 * Each individual class has a Trace() method that collects traces and 
 * a Flush() method that actually draws things.
 */
class 'DbgBaseTracer'
function DbgBaseTracer:Init(name, duration, color)
    self.name = name
    self.duration = duration
    self.completeColor = color  
    self.incompleteColor = color 
    self.enabled = false
end

function DbgBaseTracer:Status()
    return self.enabled and "on" or "off"   
end

function DbgBaseTracer:Toggle()
    self.enabled = not self.enabled
    return self.enabled
end

function DbgBaseTracer:Line(p1, p2, frac)
    local color = frac and frac < 1 and self.incompleteColor or self.completeColor
    DebugLine(p1, p2, self.duration, unpack(color))
end

function DbgBaseTracer:Box(p1, p2, extents)
    extents = extents or DbgTracer.kZeroExtents
    DebugBox(p1, p2, extents, self.duration, unpack(self.completeColor))
end

/**
 * Trace for targeting attempts. 
 */
 class 'DbgTargetingTracer' (DbgBaseTracer)
 
function DbgTargetingTracer:Init(name, dur, color)
    DbgBaseTracer.Init(self, name, dur, color)
    self.traces = {}
    self.incompleteColor = { 0, 0, 0.7, 1 } 
end


function DbgTargetingTracer:Trace(attacker, target, startPoint, trace)
    if self.enabled then
        table.insert(self.traces, { ToString(attacker), ToString(target), startPoint, trace.endPoint, trace.fraction, trace.entity == target })
    end
end
 
function DbgTargetingTracer:Flush()
    for i,data in ipairs(self.traces) do
        local attackerName, targetName, startPoint, endPoint, frac, hit = unpack(data)
        self:Line(startPoint, endPoint, frac)
    end
    self.traces = {}
end

/**
  * Trace for projectiles. Keeps track of old entityIds and position and
  * draws alternating lines to them (looks better and loads things less)
  */
class 'DbgProjectileTracer' (DbgBaseTracer)

function DbgProjectileTracer:Init(name, dur, color)
    DbgBaseTracer.Init(self, name, dur, color)

    self.newProjectiles = {}
    self.oldProjectiles = {} 
end

function DbgProjectileTracer:Trace(entity)
    if self.enabled then
        if entity.physicsBody then
            local pos = entity.physicsBody:GetCoords().origin
            // use the entity id in string form as the key
            self.newProjectiles["" .. entity:GetId()] = pos
        end
    end
end

function DbgProjectileTracer:Flush()
    local nextOldTable = {}
    local newPos
    for key,newPos in pairs(self.newProjectiles) do 
        local drawn, oldPos = false, nil   
        if self.oldProjectiles[key] then
            oldPos, drawn = unpack(self.oldProjectiles[key])
            if not drawn then
                self:Line(oldPos,newPos)
            end
        end
        nextOldTable[key] = { newPos, not drawn }
    end
    
    // clear old data.
    self.oldProjectiles = nextOldTable
    self.newProjectiles = {}
end


/**
 * Traces bullets. Draws a boundingbox around any hit target
 */
class 'DbgBulletTracer' (DbgBaseTracer)

function DbgBulletTracer:Init(name, dur, color, hitTracer)
    DbgBaseTracer.Init(self, name, dur, color)
    self.bullets = {}
    self.hitTracer = hitTracer and true or false
end

function DbgBulletTracer:Trace(shooter, startPoint, trace, capsule)
    if self.enabled then

        local entity, bbox, bbox2, targetId, targetId2 = trace.entity, "","","","" // bloody nil-in-table..
        if entity and not HasMixin(entity, "Live") then
            entity = nil
        end
        
        if entity and self.hitTracer then
            targetId = "" .. entity:GetId()
            bbox = DbgTracer.GetBoundingBox(entity)
        end

        // if we didn't hit something, but there is something mobile around that we 
        // may have aimed at, we show that instead

        if not entity and not self.hitTracer and shooter then
        
            entity = DbgTracer.FindAimedAtTarget(shooter, startPoint, trace.endPoint)
            
            if entity then
                targetId2 = "" .. entity:GetId()
                bbox2 = DbgTracer.GetBoundingBox(entity)
            end 
        end
        local name = shooter and shooter.GetName and shooter:GetName() or ToString(shooter)
        // remember the nil-in-table "feature" in lua - only last element in array may be null
        table.insert(self.bullets, { name, startPoint, trace.endPoint, trace.fraction, targetId, bbox, targetId2, bbox2, capsule})  
    end
end

function DbgBulletTracer:Flush()
    local targetsDrawn = {}

    for i,data in ipairs(self.bullets) do
        local shooterName, startPoint, endPoint, frac, targetId, bbox, targetId2, bbox2, capsule = unpack(data)
        // if we have a bbox, then we draw a bounding box around the target
        if bbox ~= "" then
            if not targetsDrawn[targetId] then
                self:Box(unpack(bbox))   
                targetsDrawn[targetId] = true   
                // we hit, so use our primary color for it  
                self:Line(startPoint, endPoint, nil)
            end
        else
            // if we missed, we send along the fraction to shift color depending on completeness
            self:Line(startPoint, endPoint, frac)
        end
        if bbox2 ~= "" and not targetsDrawn[targetId2] then
            self:Box(unpack(bbox2))   
            targetsDrawn[targetId2] = true  
        end 
        if capsule then
            self:DrawCapsule(startPoint, endPoint, frac, capsule)
        end 
    end
    self.bullets = {}
end

/**
 * A melee attack is a box trace, so all we change to trace melee is that we 
 * trace it as a box with the melee-attack extents.
 */
class "DbgMeleeTracer" (DbgBulletTracer)

function DbgMeleeTracer:Init(name, dur, color, hitTracer)
    DbgBulletTracer.Init(self, name, dur, color, hitTracer)
    if not hitTracer then
        self.incompleteColor = { 0, 0, 1, 0.8 }
    end
end

function DbgMeleeTracer:Trace(shooter, startPoint, trace, capsule)
    if self.enabled then
        // Shared.Message("Server; attack by " .. ToString(shooter) .. " from " .. ToString(startPoint) .. " at " .. Shared.GetTime()) 
    end
    DbgBulletTracer.Trace(self, shooter, startPoint, trace, capsule)
end

function DbgMeleeTracer:DrawCapsule(startPoint, endPoint, frac, capsule)  
    local color = frac and frac < 1 and self.incompleteColor or self.completeColor
    DebugTraceBox(capsule, startPoint, endPoint, self.duration, unpack(color))
end
