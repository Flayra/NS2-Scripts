//======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Utility_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Server-side NS2-specific utility functions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

function CreateEntityForTeam(techId, position, teamNumber, player)

    local newEnt = nil
    
    local mapName = LookupTechData(techId, kTechDataMapName)
    
    // Allow entities to be positioned off ground (eg, hive hovers over tech point)        
    local spawnHeight = LookupTechData(techId, kTechDataSpawnHeightOffset, .05)
    local spawnHeightPosition = Vector( position.x, 
                                        position.y + LookupTechData(techId, kTechDataSpawnHeightOffset, .05), 
                                        position.z)
    
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

function GetAlienEvolveResearchTime(evolveResearchTime, entity)

    local metabolizeEffects = entity:GetStackableGameEffectCount(kMetabolizeGameEffect)
    
    // Diminishing returns?
    return evolveResearchTime + evolveResearchTime * metabolizeEffects * kMetabolizeResearchScalar
            
end

// Returns true or false along with location (on ground, inside level) that has space for entity. 
// Last parameter is length of box size that is used to make sure location is big enough (can be nil).
// Returns point sitting on ground. Pass optional entity min distance parameter to return point at least
// that far from any other ScriptActor (radii in XZ). Check visible entities only.
// Perform some extra traces to make sure the entity is on a flat surface and not on top of a railing.

function GetRandomSpaceForEntity(basePoint, minRadius, maxRadius, boxExtents, minEntityDistance)
   
    // Find clear space at radius 
    for i = 0, 30 do
    
        local randomRadians = math.random() * 2 * math.pi
        local distance = minRadius + NetworkRandom()*(maxRadius - minRadius)
        local offset = Vector( math.cos(randomRadians) * distance, .2, math.sin(randomRadians) * distance )
        local testLocation = basePoint + offset
        
        local finalLocation = Vector(testLocation)
        DropToFloor(finalLocation)
        
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
            if trace.fraction > 0 and trace.fraction < 1 and (trace.entity == nil or not trace.entity:isa("ScriptActor")) then
            
                VectorCopy(trace.endPoint, spawnPoint)
                
                trace = Shared.TraceRay(trace.endPoint + Vector(0, capsuleHeight / 2, 0), origin, PhysicsMask.AllButPCs, filter)
                
                if (trace.fraction == 1) then
                
                    // Return origin for player
                    return spawnPoint - Vector(0, capsuleHeight / 2, 0)
                    
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
    local locationSpawns = Server.sortedEggSpawnList[locationName]
    if type(locationSpawns) == "table" then
    
        local numEggSpawns = table.count(locationSpawns)
        if numEggSpawns > 0 then
            
            local randomBaseOffset = Shared.GetRandomInt(1, numEggSpawns)
            
            for index = 1, numEggSpawns do
            
                local offset = randomBaseOffset + index 
                if offset > numEggSpawns then
                    offset = offset - numEggSpawns
                end
                
                local spawn = locationSpawns[offset]
                
                if GetCanEggFit(spawn:GetOrigin()) then
            
                    return true, spawn
                    
                end
                
            end
            
        end 
        
    end
    
    return false, nil
    
end

// Don't spawn eggs on railings or edges of steps, etc. Check each corner of the egg to make 
// sure the heights are all about the same
function GetFullyOnGround(position, maxExtentsDimension, numSlices, variationAllowed)

    ASSERT(type(maxExtentsDimension) == "number")
    ASSERT(maxExtentsDimension > 0)
    ASSERT(type(numSlices) == "number")
    ASSERT(numSlices > 1)
    ASSERT(type(variationAllowed) == "number")
    ASSERT(variationAllowed > 0)

    function GetGroundHeight(position)

        local trace = Shared.TraceRay(position, position - Vector(0, 1, 0), PhysicsMask.AllButPCs, EntityFilterOne(nil))
        return position.y - trace.fraction
        
    end
    
    
    // Get height of surface underneath center of egg
    local centerHeight = GetGroundHeight(position)
    
    // Make sure center isn't overhanging
    if math.abs(centerHeight - position.y) > variationAllowed then    
    
        return false        
        
    end
    
    // Four slices, in radius around edge of egg    
    for index = 1, numSlices do
    
        local angle = (index / numSlices) * math.pi * 2        
        local xOffset = math.cos(angle) * maxExtentsDimension
        local zOffset = math.sin(angle) * maxExtentsDimension
        
        local edgeHeight = GetGroundHeight(position + Vector(xOffset, 0, zOffset))
        
        if math.abs(edgeHeight - centerHeight) > variationAllowed then
        
            return false
            
        end
        
    end
    
    return true
    
end

// Assumes position is at the bottom center of the egg
function GetIsValidEggPlacement(position, checkInfestation)

    local extents = Vector(LookupTechData(kTechId.Egg, kTechDataMaxExtents))
    local eggCenter = position + Vector(0, extents.y + .05, 0)
    
    // Add some extra room around the edges to make sure eggs don't spawn too close to anything
    //extents.x = extents.x * 1
    //extents.z = extents.z * 2
    
    if not Shared.CollideBox(extents, eggCenter, PhysicsMask.FilterAll, nil) then

        local maxExtentsDimension = math.max(extents.x, extents.z)
        ASSERT(maxExtentsDimension > 0, "invalid x extents for")
    
        if GetFullyOnGround(position, maxExtentsDimension, 4, .1) then
        
            if not checkInfestation or GetIsPointOnInfestation(position) then
            
                return true
                
            end
            
        end
    
    end
    
    return false
    
end

// Translate from SteamId to player (returns nil if not found)
function GetPlayerFromUserId(userId)

    for index, currentPlayer in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        local owner = Server.GetOwner(currentPlayer)
        if owner and owner:GetUserId() == userId then
            return currentPlayer
        end
    end
    
    return nil
    
end
