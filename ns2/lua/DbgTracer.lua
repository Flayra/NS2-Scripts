// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DbgTracer
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// Centralized handling of server-side tracing of targeting/shooting/projectiles
//

Script.Load("lua/DbgTracer_Commands.lua")

class 'DbgTracer'

DbgTracer.kZeroExtents = Vector(0,0,0)
// missing a numerical constant for this. Hardcoded in Weapon:CheckMeleeCapsule
DbgTracer.kMeleeAttackExtent = 0.4

DbgTracer.kClientColor = { 1, 1, 0, 0.8 } // yellow
DbgTracer.clientDuration = 10
DbgTracer.clientTracingEnabled = false

/**
  * Finds a suitable mobile target that the shooter was aiming at but missed.
  */
function DbgTracer.FindAimedAtTarget(shooter, startPoint, endPoint)
    // look for enemy players to mark up 
    local enemyTeamNumber = GetEnemyTeamNumber(shooter:GetTeamNumber())
    local targets = GetEntitiesMatchAnyTypesForTeam({"Player", "MAC", "Drifter" }, enemyTeamNumber)

    // find the closest one to our los
    local selValue, selCos = -10000,0
    local losVector = GetNormalizedVector(startPoint - endPoint)
    local entity = nil

    for i,target in ipairs(targets) do

        local targetVector = GetNormalizedVector(startPoint - target:GetOrigin())

        local cos = Math.DotProduct(losVector, targetVector)
        local range = (startPoint - target:GetOrigin()):GetLength()
        // fudge a bit to make closer targets better
        local value = cos - range * range * (1 - cos)

        if (entity == nil or value > selValue) then
            entity, selValue, selCos = target, value, cos
        end

    end   

     // if our best target isn't really that good, we require it to be close
    if entity and selCos < 0.8 and (entity:GetOrigin() - startPoint):GetLength() > 5 then
        entity = nil
    end
    return entity
end

function DbgTracer.GetBoundingBox(entity) 

    local model = Shared.GetModel(entity.modelIndex)  

    if (model ~= nil) then

        local min, max = model:GetExtents()
        local p = entity:GetOrigin()
        return { p + min, p + max }

    end

    // no model found, return a 2x2m cube
    local v1 = Vector(1,1,1)
    return { entity:GetOrigin() - v1, entity.getOrigin() + v1 }
end

if Client then

function DbgTracer.MarkClientFire(shooter, startPoint)

    if DbgTracer.clientTracingEnabled then
        //Shared.Message("Client; attack by " .. ToString(shooter) .. " from " .. ToString(startPoint) .. " at " .. Shared.GetTime()) 
        local endPoint   = startPoint + player:GetViewAngles():GetCoords().zAxis
        DebugBox(startPoint,startPoint, Vector(0.01,0.01,0.01), DbgTracer.clientDuration, unpack(DbgTracer.kClientColor))

        local aimedAtTarget = DbgTracer.FindAimedAtTarget(player, startPoint, endPoint)

        if aimedAtTarget then

            local bbox = DbgTracer.GetBoundingBox(aimedAtTarget)
            local min,max = unpack(bbox)
            DebugBox(min, max, DbgTracer.kZeroExtents, DbgTracer.clientDuration, unpack(DbgTracer.kClientColor))   

        end
    end
end

function OnCommandClientTrace()
    local now = Shared.GetTime()
    if now ~= DbgTracer.lastChangeTime then 
        DbgTracer.clientTracingEnabled = not DbgTracer.clientTracingEnabled 
        Shared.Message("Client tracing " .. (DbgTracer.clientTracingEnabled and "on" or "off"))
        DbgTracer.lastChangeTime = now
    end
end

function OnCommandClientTraceDur(dur)
    DbgTracer.clientDuration = tonumber(dur)
    Shared.Message("Client tracing duration " .. DbgTracer.clientDuration)
end

Event.Hook("Console_ctrace",             OnCommandClientTrace)
Event.Hook("Console_ctracedur",          OnCommandClientTraceDur)
end