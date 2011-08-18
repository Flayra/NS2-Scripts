//======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Utility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// NS2-specific utility functions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

function GetAttachEntity(techId, position, snapRadius)

    local attachClass = LookupTechData(techId, kStructureAttachClass)    

    if attachClass then
    
        for index, currentEnt in ipairs( GetEntitiesWithinRange(attachClass, position, ConditionalValue(snapRadius, snapRadius, .5)) ) do
        
            if not currentEnt:GetAttached() then
            
                return currentEnt
                
            end
            
        end
        
    end
    
    return nil
    
end

function GetBuildAttachRequirementsMet(techId, position, teamNumber, snapRadius)

    ASSERT(kStructureAttachRange ~= nil)    

    local legalBuild = true
    local attachEntity = nil
    
    local legalPosition = Vector(position)
    
    // Make sure we're within range of something that's required (ie, an infantry portal near a command station)
    local attachRange = LookupTechData(techId, kStructureAttachRange, 0)
    local buildNearClass = LookupTechData(techId, kStructureBuildNearClass)
    if buildNearClass then
        
        local ents = {}
        
        // Handle table of class names
        if type(buildNearClass) == "table" then
            for index, className in ipairs(buildNearClass) do
                table.copy(GetEntitiesForTeamWithinRange(className, teamNumber, position, attachRange), ents, true)
            end
        else
            ents = GetEntitiesForTeamWithinRange(buildNearClass, teamNumber, position, attachRange)
        end
        
        legalBuild = (table.count(ents) > 0)
        
    end

    // For build tech that must be attached, find free attachment nearby. Snap position to it.
    local attachClass = LookupTechData(techId, kStructureAttachClass)    
    if legalBuild and attachClass then

        // If attach range specified, then we must be within that range of this entity
        // If not specified, but attach class specified, we attach to entity of that type
        // so one must be very close by (.5)
        legalBuild = false
        
        attachEntity = GetAttachEntity(techId, position, snapRadius)
        if attachEntity then            
        
            legalBuild = true
                
            VectorCopy(attachEntity:GetOrigin(), legalPosition)
            
        end
    
    end
    
    return legalBuild, legalPosition, attachEntity
    
end

function GetInfestationRequirementsMet(techId, position)

    local requirementsMet = true
    
    // Check infestation requirements
    if LookupTechData(techId, kTechDataRequiresInfestation) then

        if not GetIsPointOnInfestation(position) then
            requirementsMet = false
        end
        
    // Don't allow marine structures on infestation
    elseif LookupTechData(techId, kTechDataNotOnInfestation) then

        if GetIsPointOnInfestation(position) then
            requirementsMet = false
        end
        
    end
    
    return requirementsMet
    
end

function GetExtents(techId)

    local extents = LookupTechData(techId, kTechDataMaxExtents)
    if not extents then
        extents = Vector(.5, .5, .5)
    end
    return extents

end

// Assumes position at base of structure, so adjust position up by y extents
// this function should get the surface normal of the surface being built on
function GetBuildNoCollision(techId, position, attachEntity, ignoreEntity)

    local filter = nil
    
    if ignoreEntity and attachEntity then
        filter = EntityFilterTwo(ignoreEntity, attachEntity)
    elseif ignoreEntity then
        filter = EntityFilterOne(ignoreEntity)
    elseif attachEntity then
        filter = EntityFilterOne(attachEntity)
    end

    local result = false
    local canBuildOnWall = LookupTechData(techId, kStructureBuildOnWall)
    
    local extents = GetExtents(techId)
    local trace = Shared.TraceBox(extents, position + Vector(0, extents.y + .01, 0), position + Vector(0, extents.y + .02, 0), PhysicsMask.AllButPCsAndInfestation, filter)
    
    if (not canBuildOnWall) then
      // $AS FIXME: This is totally lame in how I should have to do this :/
      local noBuild = Pathing.GetIsFlagSet(position, extents, Pathing.PolyFlag_NoBuild)
      local walk = Pathing.GetIsFlagSet(position, extents, Pathing.PolyFlag_Walk)
      if (not noBuild and walk) then
        result = true
      end
    else
        if trace.fraction ~= 1 then
            // check if we can tilt the building a little to allow it to build on this surface
            local normal = Vector(trace.normal)
            normal:Normalize()
            local tilt = Vector.yAxis:DotProduct(normal)
            // normal buildings can only tilt by around 10 degrees, buildOnWall can tilt freely
            local maxTilt = canBuildOnWall and 0 or 0.9  
            if math.abs(tilt) >= maxTilt then
                // align along normal
                p1 = position + normal * 0.01
                p2 = position + normal * extents.y * 2
                trace = Shared.TraceViewBox(extents.x, extents.z, 0, p1 , p2, PhysicsMask.AllButPCsAndInfestation, filter)
            end
        end  
        
        result = (trace.fraction == 1)
    end
    return result, trace   
end

function CheckBuildEntityRequirements(techId, position, player, ignoreEntity)
    
    local legalBuild = true
    local errorString = ""
    
    local techTree = nil
    if Client then
        techTree = GetTechTree()
    else
        techTree = player:GetTechTree()
    end

    local techNode = techTree:GetTechNode(techId)
    local attachClass = LookupTechData(techId, kStructureAttachClass)                
    
    // Build tech can't be built on top of LiveScriptActors
    if techNode and techNode:GetIsBuild() then
    
        local trace = Shared.TraceBox(GetExtents(techId), position + Vector(0, 1, 0), position - Vector(0, 3, 0), PhysicsMask.AllButPCs, EntityFilterOne(ignoreEntity))
        
        // $AS - We special case Drop Packs as they are not LiveScriptActors but you should not be
        // able to build on top of them
        if trace.entity and trace.entity:GetHasPathingFlag(kPathingFlags.UnBuildable) then
            legalBuild = false
        end
        
        // Now make sure we're not building on top of something that is used for another purpose (ie, armory blocking use of tech point)
        if trace.entity then
            
            local hitClassName = trace.entity:GetClassName()
            if GetIsAttachment(hitClassName) and (hitClassName ~= attachClass) then
                legalBuild = false
            end

        end

        /*if legalBuild then
            DebugLine(position, position - Vector(0, 2, 0), 10, 0, 1, 0, 1)
        else
            DebugLine(position, position - Vector(0, 2, 0), 10, 1, 0, 0, 1)
        end*/
        
    end

    if techNode and (techNode:GetIsBuild() or techNode:GetIsBuy() or techNode:GetIsEnergyBuild()) and legalBuild then        
    
        local numFriendlyEntitiesInRadius = 0
        local entities = GetEntitiesForTeamWithinXZRange("ScriptActor", player:GetTeamNumber(), position, kMaxEntityRadius)
        
        for index, entity in ipairs(entities) do
            
            if not entity:isa("Infestation") then
            
                // Count number of friendly non-player units nearby and don't allow too many units in one area (prevents MAC/Drifter/Sentry spam/abuse)
                if not entity:isa("Player") and (entity:GetTeamNumber() == player:GetTeamNumber()) and entity:GetIsVisible() then
                
                    numFriendlyEntitiesInRadius = numFriendlyEntitiesInRadius + 1

                    if numFriendlyEntitiesInRadius >= (kMaxEntitiesInRadius - 1) then
                    
                        errorString = "TOO_MANY_ENTITES"
                        legalBuild = false
                        break
                        
                    end
                    
                end
                
            end
            
        end
                
        // Now check nearby entities to make sure we're not building on top of something that is used for another purpose (ie, armory blocking use of tech point)
        for index, currentEnt in ipairs( GetEntitiesWithinRange( "ScriptActor", position, 1.5) ) do
        
            local nearbyClassName = currentEnt:GetClassName()
            if GetIsAttachment(nearbyClassName) and (nearbyClassName ~= attachClass) then            
                legalBuild = false                
            end
            
        end
        
    end
    
    return legalBuild, errorString
            
end

// Returns true or false if build attachments are fulfilled, as well as possible attach entity 
// to be hooked up to. If snap radius passed, then snap build origin to it when nearby. Otherwise
// use only a small tolerance to see if entity is close enough to an attach class.
function GetIsBuildLegal(techId, position, snapRadius, player, ignoreEntity)

    local legalBuild = true
    local legalPosition = position
    local attachEntity = nil
    local errorString = ""
    
    // If structure needs to be attached to an entity, make sure it's near enough to one.
    // Snaps position to it if necessary. Also makes sure we're not building on an attach 
    // point that's used for something else (ie, putting an armory on a resource nozzle)
    local teamNumber = -1
    if player then
        teamNumber = player:GetTeamNumber()
    elseif ignoreEntity then
        teamNumber = ignoreEntity:GetTeamNumber()
    end
    
    // Check attach points
    legalBuild, legalPosition, attachEntity = GetBuildAttachRequirementsMet(techId, legalPosition, teamNumber, snapRadius)
    
    // Check collision and make sure there aren't too many entities nearby
    if legalBuild and player then
        legalBuild, errorString = CheckBuildEntityRequirements(techId, legalPosition, player, ignoreEntity)
    end    
    
    // Make sure tech node is available
    if legalBuild then
        ASSERT(teamNumber ~= -1)
        local techTree = GetTechTree(teamNumber)
        ASSERT(techTree)
        local techNode = techTree:GetTechNode(techId)
        ASSERT(techNode)
        legalBuild = techNode:GetAvailable()        
    end
    
    // Display tooltip error
    if not legalBuild and errorString ~= "" and HasMixin(player, "Tooltip") then
    
        player:AddLocalizedTooltip(errorString, false, false)
        
    // Check infestation requirements
    elseif legalBuild then
    
        legalBuild = GetInfestationRequirementsMet(techId, legalPosition)
    
        // Check collision
        local trace = nil
        if legalBuild then    
            legalBuild, trace = GetBuildNoCollision(techId, legalPosition, attachEntity, ignoreEntity)
        end
        
         // check special build requirements. We do it here because we have the trace from the building available to find out the normal
        if legalBuild then
            local method = LookupTechData(techId, kTechDataBuildRequiresMethod, nil)
            if method then
                legalBuild = method(techId, legalPosition, trace.normal, player)
            end 
        end
               
    end
    
    return legalBuild, legalPosition, attachEntity, errorString

end

function GetTriggerEntity(position, teamNumber)

    local triggerEntity = nil
    local minDist = nil
    local ents = GetEntitiesForTeamWithinRange("LiveScriptActor", teamNumber, position, .5)
    
    for index, ent in ipairs(ents) do
    
        local dist = (ent:GetOrigin() - position):GetLength()
        
        if not minDist or (dist < minDist) then
        
            triggerEntity = ent
            minDist = dist
            
        end
    
    end
    
    return triggerEntity
    
end

if Server then

function CreateEntityForTeam(techId, position, teamNumber, player)

    local newEnt = nil
    
    local mapName = LookupTechData(techId, kTechDataMapName)
    
    // Allow entities to be positioned off ground (eg, hive hovers over tech point)        
    local spawnHeight = LookupTechData(techId, kTechDataSpawnHeightOffset, .05)
    local spawnHeightPosition = Vector(position.x, position.y + LookupTechData(techId, kTechDataSpawnHeightOffset, .05), position.z)
    
    newEnt = CreateEntity( mapName, spawnHeightPosition, teamNumber )
    
    // Hook it up to attach entity
    local attachEntity = GetAttachEntity(techId, position)    
    if attachEntity then    
        newEnt:SetAttached(attachEntity)        
    end
    
    return newEnt
    
end

function CreateEntityForCommander(techId, position, commander)
    
    local newEnt = CreateEntityForTeam(techId, position, commander:GetTeamNumber(), commander)
    
    if newEnt then
        newEnt:SetOwner(commander)
    end
    
    UpdateInfestationMask(newEnt)
    
    return newEnt
    
end

if Server then
function GetAlienEvolveResearchTime(evolveResearchTime, entity)

    local metabolizeEffects = entity:GetStackableGameEffectCount(kMetabolizeGameEffect)
    
    // Diminishing returns?
    return evolveResearchTime + evolveResearchTime * metabolizeEffects * kMetabolizeResearchScalar
            
end
end

end

function GetBlockedByUmbra(entity)

    if entity ~= nil and entity:isa("LiveScriptActor") then
    
        if entity:GetGameEffectMask(kGameEffect.InUmbra) and (NetworkRandomInt(1, Crag.kUmbraBulletChance, "GetBlockedByUmbra") == 1) then
            return true
        end
        
    end
    
    return false
    
end

function GetSurfaceFromEntity(entity)

    if((entity ~= nil and entity:isa("Structure") and entity:GetTeamType() == kAlienTeamType)) then
        return "organic"
    elseif((entity ~= nil and entity:isa("Structure") and entity:GetTeamType() == kMarineTeamType)) then
        return "thin_metal"
    end

    // TODO: Do something more intelligent here
    return "thin_metal"
    
end

// Trace line to each target to make sure it's not blocked by a wall. 
// Returns true/false, along with distance traced 
function GetWallBetween(startPoint, endPoint, targetEntity, ignoreEntity)

    local currentStart = Vector(startPoint)
    local filter = EntityFilterOne(ignoreEntity)
    local dist = (startPoint - endPoint):GetLength()

    // Don't trace too much 
    for i = 0, 10 do
    
        local trace = Shared.TraceRay(currentStart, endPoint, PhysicsMask.Bullets, filter)        
        
        // Not blocked by entities, only world geometry
        if trace.fraction == 1 then
            return false, dist
        elseif not trace.entity then
            // Hit a wall
            dist = (startPoint - trace.endPoint):GetLength()
            return true, dist
        elseif trace.entity == targetEntity then
            // Hit target entity, return traced distance to it
            dist = (startPoint - trace.endPoint):GetLength()
            return false, dist
        else
            filter = EntityFilterTwo(ignoreEntity, trace.entity)
        end
        
        currentStart = trace.endPoint
        
    end    
    
    return false, dist
    
end

// Get damage type description text for tooltips
function DamageTypeDesc(damageType)
    if table.count(kDamageTypeDesc) >= damageType then
        if kDamageTypeDesc[damageType] ~= "" then
            return string.format("(%s)", kDamageTypeDesc[damageType])
        end
    end
    return ""
end

function GetHealthColor(scalar)

    local kHurtThreshold = .7
    local kNearDeadThreshold = .4
    local minComponent = 191
    local spreadComponent = 255 - minComponent

    scalar = Clamp(scalar, 0, 1)
    
    if scalar <= kNearDeadThreshold then
    
        // Faded red to bright red
        local r = minComponent + (scalar / kNearDeadThreshold) * spreadComponent
        return {r, 0, 0}
        
    elseif scalar <= kHurtThreshold then
    
        local redGreen = minComponent + ( (scalar - kNearDeadThreshold) / (kHurtThreshold - kNearDeadThreshold) ) * spreadComponent
        return {redGreen, redGreen, 0}
        
    else
    
        local g = minComponent + ( (scalar - kHurtThreshold) / (1 - kHurtThreshold) ) * spreadComponent
        return {0, g, 0}
        
    end
    
end

function GetEntsWithTechId(techIdTable)

    local ents = {}
    
    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("ScriptActor")) do
    
        if table.find(techIdTable, entity:GetTechId()) then
            table.insert(ents, entity)
        end
        
    end
    
    return ents
    
end

function GetFreeAttachEntsForTechId(techId)

    local freeEnts = {}

    local attachClass = LookupTechData(techId, kStructureAttachClass)

    if attachClass ~= nil then    
    
        for index, ent in ientitylist(Shared.GetEntitiesWithClassname(attachClass)) do
        
            if ent ~= nil and ent:GetAttached() == nil then
            
                table.insert(freeEnts, ent)
                
            end
            
        end
        
    end
    
    return freeEnts
    
end

function GetNearestFreeAttachEntity(techId, origin, range)

    local nearest = nil
    local nearestDist = nil
    
    for index, ent in ipairs(GetFreeAttachEntsForTechId(techId)) do
    
        local dist = (ent:GetOrigin() - origin):GetLengthXZ()
        
        if (nearest == nil or dist < nearestDist) and (range == nil or dist <= range) then
        
            nearest = ent
            nearestDist = dist
            
        end
        
    end
    
    return nearest
    
end

// Returns if it's legal for player to build structure or drop item, along with the position
// Assumes you're passing in build or buy tech.
function GetIsBuildPickVecLegal(techId, player, pickVec, snapRadius)

    local trace = GetCommanderPickTarget(player, pickVec, false, true)
    return GetIsBuildLegal(techId, trace.endPoint, snapRadius, player)
    
end

// Trace until we hit the "inside" of the level or hit nothing. Returns nil if we hit nothing,
// returns the world point of the surface we hit otherwise. Only hit surfaces that are facing 
// towards us.
// Input pickVec is either a normalized direction away from the commander that represents where
// the mouse was clicked, or if worldCoordsSpecified is true, it's the XZ position of the order
// given to the minimap. In that case, trace from above it straight down to find the target.
// The last parameter is false if target is for selection, true if it's for building
function GetCommanderPickTarget(player, pickVec, worldCoordsSpecified, forBuild)

    local done = false
    local startPoint = player:GetOrigin() 

    if worldCoordsSpecified and pickVec then
        startPoint = Vector(pickVec.x, player:GetOrigin().y + 20, pickVec.z)
    end
    
    local trace = nil
    
    while not done do

        // Use either select or build mask depending what it's for
        local mask = ConditionalValue(forBuild, PhysicsMask.CommanderBuild, PhysicsMask.CommanderSelect)        
        local endPoint = ConditionalValue(not worldCoordsSpecified, player:GetOrigin() + pickVec * 1000, Vector(pickVec.x, player:GetOrigin().y - 100, pickVec.z))
        trace = Shared.TraceRay(startPoint, endPoint, mask, EntityFilterOne(player))
        local hitDistance = (startPoint - trace.endPoint):GetLength()
        
        // Try again if we're inside the surface
        if(trace.fraction == 0 or hitDistance < .1) then
        
            startPoint = startPoint + pickVec
        
        elseif(trace.fraction == 1) then
        
            done = true

        // Only hit a target that's facing us (skip surfaces facing away from us)            
        elseif trace.normal.y < 0 then
        
            // Trace again from what we hit
            startPoint = trace.endPoint
            
        else
                    
            done = true
                
        end
        
    end
    
    return trace
    
end

function GetEnemyTeamNumber(entityTeamNumber)

    if(entityTeamNumber == kTeam1Index) then
        return kTeam2Index
    elseif(entityTeamNumber == kTeam2Index) then
        return kTeam1Index
    else
        return kTeamInvalid
    end    
    
end

// Returns true or false along with location (on ground, inside level) that has space for entity. 
// Last parameter is length of box size that is used to make sure location is big enough (can be nil).
// Returns point sitting on ground. Pass optional entity min distance parameter to return point at least
// that far from any other ScriptActor (radii in XZ). Check visible entities only.
// Perform some extra traces to make sure the entity is on a flat surface and not on top of a railing.
if Server then
function GetRandomSpaceForEntity(basePoint, minRadius, maxRadius, boxExtents, minEntityDistance)
   
    // Find clear space at radius 
    for i = 0, 30 do
    
        local randomRadians = math.random() * 2 * math.pi
        local distance = minRadius + NetworkRandom()*(maxRadius - minRadius)
        local offset = Vector( math.cos(randomRadians) * distance, .2, math.sin(randomRadians) * distance )
        local testLocation = basePoint + offset
        
        local finalLocation = Vector(testLocation)
        DropToFloor(finalLocation)
        
        //DebugLine(basePoint, finalLocation, .1, 1, 0, 0, 1)
        
        local valid = true
        
        // Perform trace at center, then at each of the extent corners
        if boxExtents then
        
            local tracePoints = {   finalLocation + Vector(-boxExtents, boxExtents, -boxExtents),
                                    finalLocation + Vector(-boxExtents, boxExtents,  boxExtents),
                                    finalLocation + Vector( boxExtents, boxExtents, -boxExtents),
                                    finalLocation + Vector( boxExtents, boxExtents,  boxExtents) }
                                    
            for index, point in ipairs(tracePoints) do
            
                local trace = Shared.TraceRay(finalLocation, tracePoints[index], PhysicsMask.AllButPCs, EntityFilterOne(nil))
                if (trace.fraction < 1) and (math.abs(trace.endPoint.y - finalLocation.y) > .1) then
                
                    valid = false
                    break
                    
                end
                
            end
            
        end        

        if valid then  
      
            // Make sure we don't drop out of the world
            if((finalLocation - testLocation):GetLength() < 20) then
            
                //finalLocation.y = finalLocation.y + .01
            
                if(boxExtents == nil) then
                
                    return true, finalLocation
                    
                else
                
                    if minEntityDistance == nil then
                    
                        return true, finalLocation
                    
                    else
                    
                        // Check visible entities only
                        local ents = GetEntitiesWithinXZRangeAreVisible("ScriptActor", finalLocation, minEntityDistance, true)
                        
                        if table.count(ents) == 0 then
                        
                            return true, finalLocation
                            
                        end
                        
                    end
                        
                end
                
            end
            
        end

    end

    return false, nil
    
end

// Find place for player to spawn, within range of origin. Makes sure that a line can be traced between the two points
// without hitting anything, to make sure you don't spawn on the other side of a wall. Returns nil if it can't find a 
// spawn point after a few tries.
function GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, origin, minRange, maxRange, filter)

    ASSERT(capsuleHeight > 0)
    ASSERT(capsuleRadius > 0)
    ASSERT(origin ~= nil)
    ASSERT(type(minRange) == "number")   
    ASSERT(type(maxRange) == "number")   
    ASSERT(maxRange > minRange) 
    ASSERT(minRange > 0)
    ASSERT(maxRange > 0)
    
    local center = Vector(0, capsuleHeight * 0.5 + capsuleRadius, 0)
    
    for i = 0, 15 do
    
        // Find random spot within range
        local randomRange = minRange + math.random() * (maxRange - minRange)
        local randomRadians = math.random() * math.pi * 2        
        local spawnPoint = Vector(origin.x + randomRange * math.cos(randomRadians), origin.y + 2, origin.z + randomRange * math.sin(randomRadians))
        
        // Make sure capsule isn't interpenetrating something (TraceCapsule may not return 0 if it's moving "away" from a collision)
        if not Shared.CollideCapsule(spawnPoint + center, capsuleRadius, capsuleHeight, PhysicsMask.AllButPCs, nil) then
        
            // Trace capsule to ground, making sure we're not on something like a player or structure
            local trace = Shared.TraceCapsule(spawnPoint + center, spawnPoint - Vector(0, 10, 0), capsuleRadius, capsuleHeight, PhysicsMask.AllButPCs)            
            if trace.fraction > 0 and trace.fraction < 1 and (trace.entity == nil or not trace.entity:isa("LiveScriptActor")) then
            
                VectorCopy(trace.endPoint, spawnPoint)
                
                trace = Shared.TraceRay(trace.endPoint + Vector(0, capsuleHeight / 2, 0), origin, PhysicsMask.AllButPCs, filter)
                
                if (trace.fraction == 1) then
                
                    // Return origin for player
                    return spawnPoint - Vector(0, capsuleHeight/2, 0)
                    
                end
                
            end
            
        end
        
    end
    
    return nil
    
end


// Assumes position is at the bottom center of the egg
function GetCanEggFit(position)

    local extents = LookupTechData(kTechId.Egg, kTechDataMaxExtents)
    local maxExtentsDimension = math.max(extents.x, extents.y)
    ASSERT(maxExtentsDimension > 0, "invalid x extents for")

    local eggCenter = position + Vector(0, extents.y + .05, 0)

    local filter = nil
    local physicsMask = PhysicsMask.AllButPCs
    
    if not Shared.CollideBox(extents, eggCenter, physicsMask, filter) then
            
        return true
                    
    end
    
    return false
    
end

function GetRandomFreeEggSpawn(locationName)

    // Look for free egg_spawns in this location
    local numEggSpawns = table.count(Server.eggSpawnList)
    if numEggSpawns > 0 then
        
        // Start at a random base offset
        local randomBaseOffset = math.floor(math.random() * numEggSpawns)
        
        for index = 1, numEggSpawns do
        
            local offset = ((randomBaseOffset + index) % numEggSpawns) + 1
            local spawn = Server.eggSpawnList[offset]
            
            if GetLocationForPoint(spawn:GetOrigin()) == locationName then
            
                if GetCanEggFit(spawn:GetOrigin()) then
            
                    return true, spawn
                    
                end
            
            end
            
        end
        
    end
    
    return false, nil
    
end

end

function SpawnPlayerAtPoint(player, origin, angles)

    local originOnFloor = Vector(origin)
    originOnFloor.y = origin.y + .5
    
    //Print("Respawning player (%s) to angles: %.2f, %.2f, %.2f", player:GetClassName(), angles.yaw, angles.pitch, angles.roll)
    player:SetOrigin(originOnFloor)
    
    if angles then
        player:SetOffsetAngles(angles)
    end        
    
end

// Trace position down to ground
function DropToFloor(point)

    local done = false
    local numTraces = 0
    
    // Keep tracing until we hit something, that's not an entity (world geometry)
    local ignoreEntity = nil
    
    while not done do
    
        local trace
        
        if(ignoreEntity == nil) then
            trace = Shared.TraceRay(point, Vector(point.x, point.y - 1000, point.z), PhysicsMask.AllButPCs)
        else
            trace = Shared.TraceRay(point, Vector(point.x, point.y - 1000, point.z), PhysicsMask.AllButPCs, EntityFilterOne(ignoreEntity))
        end
        
        numTraces = numTraces + 1
        
        // Backup the end point by a small amount to avoid interpenetration.AcquireTarget
        local newPoint = trace.endPoint - trace.normal * 0.01
        VectorCopy(newPoint, point)
        
        if(trace.entity == nil or numTraces > 10) then        
            done = true
        else
            ignoreEntity = trace.entity
        end
        
    end

end

function GetNearestTechPoint(origin, teamType, availableOnly)

    // Look for nearest empty tech point to use instead
    local nearestTechPoint = nil
    local nearestTechPointDistance = 0

    for index, techPoint in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
    
        // Only use unoccupied tech points that are neutral or marked for use with our team
        local techPointTeamNumber = techPoint:GetTeamNumber()
        if( ((not availableOnly) or (techPoint:GetAttached() == nil)) and ((techPointTeamNumber == kTeamReadyRoom) or (teamType == techPointTeamNumber)) ) then
    
            local distance = (techPoint:GetOrigin() - origin):GetLength()
            if(nearestTechPoint == nil or distance < nearestTechPointDistance) then
            
                nearestTechPoint = techPoint
                nearestTechPointDistance = distance
                
            end
        
        end
        
    end
    
    return nearestTechPoint
    
end

// Computes line of sight to entity
local toEntity = Vector()
function GetCanSeeEntity(seeingEntity, targetEntity)

    local seen = false
    
    // See if line is in our view cone
    if(targetEntity:GetIsVisible()) then
    
        local eyePos = GetEntityEyePos(seeingEntity)
        local targetEntityOrigin = targetEntity:GetOrigin()
        
        // Reuse vector
        toEntity.x = targetEntityOrigin.x - eyePos.x
        toEntity.y = targetEntityOrigin.y - eyePos.y
        toEntity.z = targetEntityOrigin.z - eyePos.z

        // Normalize vector        
        local toEntityLength = math.sqrt(toEntity.x * toEntity.x + toEntity.y * toEntity.y + toEntity.z * toEntity.z)
        if toEntityLength > kEpsilon then
            toEntity.x = toEntity.x / toEntityLength
            toEntity.y = toEntity.y / toEntityLength
            toEntity.z = toEntity.z / toEntityLength
        end
        
        local seeingEntityAngles = GetEntityViewAngles(seeingEntity)
        local normViewVec = seeingEntityAngles:GetCoords().zAxis
        local dotProduct = Math.DotProduct(toEntity, normViewVec)
        local fov = 90
        if seeingEntity.GetFov then
            fov = seeingEntity:GetFov()
        end
        local halfFov = math.rad(fov/2)
        local s = math.acos(dotProduct)
        if(s < halfFov) then

            // See if there's something blocking our view of entity
            local trace = Shared.TraceRay(eyePos, targetEntity:GetModelOrigin(), PhysicsMask.AllButPCs, EntityFilterTwo(seeingEntity, targetEntity))
            
            if trace.entity ~= nil and trace.entity == seeingEntity then
                Print("Warning - GetCanSeeEntity(%s, %s): Trace line blocked by source entity.", seeingEntity:GetClassName(), targetEntity:GetClassName())
            end
            
            if(trace.fraction == 1 or trace.entity == targetEntity) then
                seen = true
            end
            
            if Server and Server.dbgTracer.seeEntityTraceEnabled then
                Server.dbgTracer:TraceTargeting(seeingEntity,targetEntity,eyePos, trace)
            end
            
        end

        // Draw red or green line
        if(Client and Shared.GetDevMode()) then
            DebugLine(eyePos, targetEntity:GetOrigin(), 5, ConditionalValue(seen, 0, 1), ConditionalValue(seen, 1, 0), 0, 1)
        end
        
    end
    
    return seen
    
end

function GetLocations()

    return EntityListToTable(Shared.GetEntitiesWithClassname("Location"))

end

function GetLocationForPoint(point)

    local ents = GetLocations()
    
    for index, location in ipairs(ents) do
    
        if location:GetIsPointInside(point) then
        
            return location:GetName(), location
            
        end    
        
    end
    
    return ""

end

function GetLocationEntitiesNamed(name)

    local locationEntities = {}
    
    if name ~= nil and name ~= "" then
    
        local ents = GetLocations()
        
        for index, location in ipairs(ents) do
        
            if location:GetName() == name then
            
                table.insert(locationEntities, location)
                
            end
            
        end
        
    end

    return locationEntities
    
end

function GetLightsForPowerPoint(powerPoint)

    local lightList = {}
    
    local locationName = powerPoint:GetLocationName()
    
    local locations = GetLocationEntitiesNamed(locationName)
    
    if table.count(locations) > 0 then
    
        for index, location in ipairs(locations) do
            
            for index, renderLight in ipairs(Client.lightList) do

                if renderLight then
                
                    local lightOrigin = renderLight:GetCoords().origin
                    
                    if location:GetIsPointInside(lightOrigin) then
                    
                        table.insert(lightList, renderLight)
            
                    end
                    
                end
                
            end
            
        end
    
    else
        Print("GetLightsForPowerPoint(powerPoint): Couldn't find location entity named %s", ToString(locationName))
    end
    
    return lightList
    
end

if Client then
function ResetLights()

    for index, renderLight in ipairs(Client.lightList) do
    
        renderLight:SetColor( renderLight.originalColor )
        renderLight:SetIntensity( renderLight.originalIntensity )
        
    end                    

end
end

// Pulled out into separate function so phantasms can use it too
function SetPlayerPoseParameters(player, viewAngles, velocity, maxSpeed, maxBackwardSpeedScalar, crouchAmount)

    local pitch = -Math.Wrap( Math.Degrees(viewAngles.pitch), -180, 180 )
    
    player:SetPoseParam("body_pitch", pitch)
   
    local viewCoords = viewAngles:GetCoords()
    
    local horizontalVelocity = Vector(velocity)
    // Not all players will contrain their movement to the X/Z plane only.
    if player:GetMoveSpeedIs2D() then
        horizontalVelocity.y = 0
    end
    
    local x = Math.DotProduct(viewCoords.xAxis, horizontalVelocity)
    local z = Math.DotProduct(viewCoords.zAxis, horizontalVelocity)

    local moveYaw   = math.atan2(z, x) * 180 / math.pi
    local moveSpeed = horizontalVelocity:GetLength() / maxSpeed
    
    player:SetPoseParam("move_yaw",   moveYaw)
    player:SetPoseParam("move_speed", moveSpeed)
    player:SetPoseParam("crouch", crouchAmount)
    
end

// Pass in position on ground
function GetHasRoomForCapsule(extents, position, physicsMask, ignoreEntity)

    if extents ~= nil then
    
        local filter = ConditionalValue(ignoreEntity, EntityFilterOne(ignoreEntity), nil)
        return not Shared.CollideBox(extents, position, physicsMask, filter)
        
    else
        Print("GetHasRoomForCapsule(): Extents not valid.")
    end
    
    return false

end

function GetOnFireCinematic(ent, firstPerson)

    local className = ent:GetClassName()
    
    if firstPerson then
        return Flamethrower.kBurn1PCinematic
    elseif className == "Hive" or className == "CommandStation" then
        return Flamethrower.kBurnHugeCinematic
    elseif className == "MAC" or className == "Drifter" or className == "Sentry" or className == "Egg" or className == "Embryo" then
        return Flamethrower.kBurnSmallCinematic
    elseif className == "Onos" then
        return Flamethrower.kBurnBigCinematic
    end
    
    return Flamethrower.kBurnMedCinematic
    
end

function GetEngagementDistance(entIdOrTechId, trueTechId)

    local distance = 2
    local success = true
    
    local techId = entIdOrTechId
    if not trueTechId then
    
        local ent = Shared.GetEntity(entIdOrTechId)    
        if ent and ent.GetTechId then
            techId = ent:GetTechId()
        else
            success = false
        end
        
    end
    
    local desc = nil
    if success then
    
        distance = LookupTechData(techId, kTechDataEngagementDistance, nil)
        
        if distance then
            desc = EnumToString(kTechId, techId)    
        else
            distance = 1
            success = false
        end
        
    end    
        
    //Print("GetEngagementDistance(%s, %s) => %s => %s, %s", ToString(entIdOrTechId), ToString(trueTechId), ToString(desc), ToString(distance), ToString(success))
    
    return distance, success
    
end

function MinimapToWorld(commander, x, y)

    local heightmap = commander:GetHeightmap()
    
    // Translate minimap coords to world position
    return Vector(heightmap:GetWorldX(y), 0, heightmap:GetWorldZ(x))
    
end

function GetMinimapPlayableWidth(map)
    local mapX = map:GetMapX(map:GetOffset().z + map:GetExtents().z)
    return (mapX - .5) * 2
end

function GetMinimapPlayableHeight(map)
    local mapY = map:GetMapY(map:GetOffset().x - map:GetExtents().x)
    return (mapY - .5) * 2
end

function GetMinimapHorizontalScale(map)

    local width = GetMinimapPlayableWidth(map)
    local height = GetMinimapPlayableHeight(map)
    
    return ConditionalValue(height > width, width/height, 1)
    
end

function GetMinimapVerticalScale(map)

    local width = GetMinimapPlayableWidth(map)
    local height = GetMinimapPlayableHeight(map)
    
    return ConditionalValue(width > height, height/width, 1)
    
end

function GetMinimapNormCoordsFromPlayable(map, playableX, playableY)

    local playableWidth = GetMinimapPlayableWidth(map)
    local playableHeight = GetMinimapPlayableHeight(map)
    
    return playableX * (1 / playableWidth), playableY * (1 / playableHeight)
    
end

// If we hit something, create an effect (sparks, blood, etc.).        
function TriggerHitEffects(doer, target, origin, surface, melee)

    local tableParams = {}

    if target and target.GetClassName then
        tableParams[kEffectFilterClassName] = target:GetClassName()
        tableParams[kEffectFilterIsMarine] = target:GetTeamType() == kMarineTeamType
        tableParams[kEffectFilterIsAlien] = target:GetTeamType() == kAlienTeamType
    end
    
    tableParams[kEffectSurface] = ConditionalValue(type(surface) == "string" and surface ~= "", surface, "metal")
    
    if origin then
        tableParams[kEffectHostCoords] = Coords.GetTranslation(origin)
    else
        tableParams[kEffectHostCoords] = Coords.GetIdentity()
    end
    
    if doer then
        tableParams[kEffectFilterDoerName] = doer:GetClassName()
    end
    
    tableParams[kEffectFilterInAltMode] = (melee == true)

    GetEffectManager():TriggerEffects("hit_effect", tableParams, doer)
    
end

function GetIsPointOnInfestation(point)

    local onInfestation = false
    
    // See if entity is on infestation
    for infestationIndex, infestation in ientitylist(Shared.GetEntitiesWithClassname("Infestation")) do
    
        if infestation:GetIsPointOnInfestation(point) then
        
            onInfestation = true
            break
            
        end
        
    end
    
    return onInfestation

end

function CreateStructureInfestation(coords, teamNumber, infestationRadius, percent)

    local infestation = CreateEntity(Infestation.kMapName, coords.origin, teamNumber)
    
    infestation:SetMaxRadius(infestationRadius)
    
    infestation:SetCoords(coords)
    
    if percent then
        infestation:SetRadiusPercent(percent)
    end
    
    return infestation

end

// Get nearest valid target for commander ability activation, of specified team number nearest specified position.
// Returns nil if none exists in range.
function GetActivationTarget(teamNumber, position)

    local nearestTarget = nil
    local nearestDist = nil
    
    local targets = GetEntitiesForTeamWithinRange("LiveScriptActor", teamNumber, position, 2)
    for index, target in ipairs(targets) do
    
        if target:GetIsVisible() and not target:isa("Infestation") then
        
            local dist = (target:GetOrigin() - position):GetLength()
            if nearestTarget == nil or dist < nearestDist then
            
                nearestTarget = target
                nearestDist = dist
                
            end
            
        end
        
    end
    
    return nearestTarget
    
end

// Translate from SteamId to player (returns nil if not found)
if Server then
function GetPlayerFromUserId(userId)

    for index, currentPlayer in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        local owner = Server.GetOwner(currentPlayer)
        if owner and owner:GetUserId() == userId then
            return currentPlayer
        end
    end
    
    return nil
    
end
end

// Get information about entity when looking at it. 
function GetCrosshairText(entity, teamNumber)

    local text = ""
    
    if entity:isa("Player") and entity:GetIsAlive() then
    
        // If the target is an Embryo and is on the enemy team, we should mask their name
        if entity:isa("Embryo") and entity:GetTeamNumber() == GetEnemyTeamNumber(teamNumber) then
        
            local statusText = string.format("(%.0f%%)", Clamp(math.ceil(entity:GetHealthScalar() * 100), 0, 100))
            text = string.format("%s %s", GetDisplayNameForTechId(kTechId.Egg), statusText)
            
        else
            
            local playerName = Scoreboard_GetPlayerData(entity:GetClientIndex(), "Name")
                    
            if playerName ~= nil then
            
                text = playerName
            
            end
        
            if entity:GetTeamNumber() == teamNumber then
            
                if entity:isa("Marine") then
                
                    // Show health/armor scalars separately so marines know when to repair
                    local healthPct = math.ceil((entity:GetHealth() / entity:GetMaxHealth()) * 100)
                    local armorPct = math.ceil((entity:GetArmor() / entity:GetMaxArmor()) * 100)
                    
                    if healthPct == 100 and armorPct == 100 then
                        text = string.format("%s (%d%%)", text, 100)
                    else
                        text = string.format("%s (%d%%/%d%%)", text, healthPct, armorPct)
                    end
                    
                else
                    // But aliens only ever need total %
                    text = string.format("%s (%d%%)", text, math.ceil(entity:GetHealthScalar()*100))
                end                
                
            end
            
        end
        
    // Add quickie damage feedback and structure status
    elseif (entity:isa("Structure") or entity:isa("MAC") or entity:isa("Drifter") or entity:isa("ARC")) and entity:GetIsAlive() then
    
        // Don't show built % for enemies, show health instead
        local enemyTeam = (GetEnemyTeamNumber(entity:GetTeamNumber()) == teamNumber)
        local techId = entity:GetTechId()
        local statusText = string.format("(%.0f%%)", Clamp(math.ceil(entity:GetHealthScalar() * 100), 0, 100))        
        if entity:isa("Structure") and not enemyTeam then
            if not entity:GetIsBuilt() then
                statusText = string.format("(%.0f%%)", Clamp(math.ceil(entity:GetBuiltFraction() * 100), 0, 100))
            // Show where phase gate will send player to
            elseif entity:isa("PhaseGate") and entity:GetDestLocationId() ~= Entity.invalidId then
                local destGateId = entity:GetDestLocationId()
                local destGate = Shared.GetEntity(destGateId)
                if destGate then
                    statusText = string.format("to %s", destGate:GetName())
                end
            end
        end
        
        local secondaryText = ""
        if entity:isa("Structure") then

            // Display location name for power point so we know what it affects
            if entity:isa("PowerPoint") then
            
                if not entity:GetIsPowered() then
                    secondaryText = "Destroyed " .. entity:GetLocationName() .. " "
                else
                    secondaryText = entity:GetLocationName() .. " "
                end
                
            elseif not entity:GetIsBuilt() then
                secondaryText = "Unbuilt "
            elseif entity:GetRequiresPower() and not entity:GetIsPowered() then
                secondaryText = "Unpowered "
            
            elseif entity:isa("Whip") then
            
                if not entity:GetIsRooted() then
                    secondaryText = "Unrooted "
                end

            else
            
                // If we're upgrading, show status
                local researchId = entity:GetResearchingId()
                local researchTechNode = GetTechTree():GetTechNode(researchId)
                if researchTechNode and researchTechNode:GetIsUpgrade() then
                
                    if not enemyTeam then
                        statusText = string.format("(%.0f%%)", Clamp(math.ceil(entity:GetResearchProgress() * 100), 0, 100))
                    else
                        statusText = string.format("(in progress)")
                    end
                    
                end

            end
            
        end
        
        local primaryText = GetDisplayNameForTechId(techId)
        if entity.GetDescription then
            primaryText = entity:GetDescription()
        end
        
        local cloaked = (HasMixin(entity, "Cloakable") and entity:GetIsCloaked())
        local cloakedText = ConditionalValue(cloaked, " (cloaked)", "")

        text = string.format("%s%s %s%s", secondaryText, primaryText, statusText, cloakedText)

    end
    
    return text    
    
end

function GetSelectionText (entity, teamNumber)
    local text = ""
    
    local cloaked = (HasMixin(entity, "Cloakable") and entity:GetIsCloaked())
    local cloakedText = ConditionalValue(cloaked, " (cloaked)", "")
    
    if entity:isa("Player") and entity:GetIsAlive() then
        local playerName = Scoreboard_GetPlayerData(entity:GetClientIndex(), "Name")
                    
        if playerName ~= nil then
            
            text = string.format("%s%s", playerName, cloakedText)
        end
                    
    elseif entity:GetIsAlive() then
    
        // Don't show built % for enemies, show health instead
        local enemyTeam = (GetEnemyTeamNumber(entity:GetTeamNumber()) == teamNumber)
        local techId = entity:GetTechId()        

        local secondaryText = ""
        if entity:isa("Structure") then
            if not entity:GetIsBuilt() then
                secondaryText = "Unbuilt "
            elseif entity:GetRequiresPower() and not entity:GetIsPowered() then
                secondaryText = "Unpowered "
            
            elseif entity:isa("Whip") then
            
                if not entity:GetIsRooted() then
                    secondaryText = "Unrooted "
                end            
            end
            
        end
        
        local primaryText = GetDisplayNameForTechId(techId)
        if entity.GetDescription then
            primaryText = entity:GetDescription()
        end

        text = string.format("%s%s%s", secondaryText, primaryText, cloakedText)

    end
    
    return text    
end

function GetCostForTech(techId)

    local cost = LookupTechData(techId, kTechDataCostKey, 0)
    
    if Shared.GetCheatsEnabled() then
        cost = 0
    end
    
    return cost
    
end

/**
 * Adds additional points to the path to ensure that no two points are more than
 * maxDistance apart.
 */
function SubdividePathPoints(points, maxDistance)
    PROFILE("SubdividePathPoints") 
    local numPoints   = #points    
    
    local i = 1
    while i < numPoints do
        
        local point1 = points[i]
        local point2 = points[i + 1]

        // If the distance between two points is large, add intermediate points
        
        local delta    = point2 - point1
        local distance = delta:GetLength()
        local numNewPoints = math.floor(distance / maxDistance)
        local p = 0
        for j=1,numNewPoints do

            local f = j / numNewPoints
            local newPoint = point1 + delta * f
            if (table.find(points, newPoint) == nil) then
                i = i + 1
                table.insert( points, i, newPoint )
                p = p + 1
            end                     
        end 
        i = i + 1    
        numPoints = numPoints + p        
    end           
end

local function GetTraceEndPoint(src, dst, trace, skinWidth)

    local delta    = dst - src
    local distance = delta:GetLength()
    local fraction = trace.fraction
    fraction = Math.Clamp( fraction + (fraction - 1.0) * skinWidth / distance, 0.0, 1.0 )
    
    return src + delta * fraction

end

/**
 * Returns a list of point connecting two points together. If there's no path, returns nil.
 */
function FindConnectionPath(src, dst)
    PROFILE("FindConnectionPath")  
    local mask = CreateGroupsFilterMask(PhysicsGroup.StructuresGroup, PhysicsGroup.PlayerControllersGroup, PhysicsGroup.PlayerGroup)
    
    local climbAmount   = 0.3   // Distance to "climb" over obstacles each iteration
    local climbOffset   = Vector(0, climbAmount, 0)
    local maxIterations = 10    // Maximum number of attempts to trace to the dst
    
    local points = { }    
    
    // Query the pathing system for the path to the dst
    // if fails then fallback to the old system
    Pathing.GetPathPoints(src, dst, points)    
    if (#(points) ~= 0 ) then        
        SubdividePathPoints( points, 0.5 )        
        return points
    end        
    
    for i=1,maxIterations do

        local trace = Shared.TraceRay(src, dst, mask)
        table.insert( points, src )
        
        if trace.fraction == 1 or trace.endPoint:GetDistanceSquared(dst) < (0.25 * 0.25) then
            table.insert( points, dst )
            SubdividePathPoints( points, 0.5 )
            return points
        elseif trace.fraction == 0 then
            return nil
        end
        
        local endPoint = GetTraceEndPoint(src, dst, trace, 0.1)
        local upPoint  = endPoint + climbOffset
        
        // Move up to the hit point and over any obstacles.
        trace = Shared.TraceRay( endPoint, upPoint, mask )
        src = GetTraceEndPoint(endPoint, upPoint, trace, 0.1)

    end
            
    return nil

end
