// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Entity.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function EntityToString(entity)

    if (entity == nil) then
        return "nil"
    elseif (type(entity) == "number") then
        string.format("EntityToString(): Parameter is a number (%s) instead of entity ", tostring(entity))
    elseif (entity:isa("Entity")) then
        return entity:GetClassName()
    end
    
    return string.format("EntityToString(): Parameter isn't an entity but %s instead", tostring(entity))
    
end

/**
 * For use in Lua for statements to iterate over EntityList objects.
 */
function ientitylist(entityList)
    local function ientitylist_it(entityList, currentIndex)
        if currentIndex >= entityList:GetSize() then
            return nil
        end
        local currentEnt = entityList:GetEntityAtIndex(currentIndex)
        currentIndex = currentIndex + 1
        return currentIndex, currentEnt
    end
    return ientitylist_it, entityList, 0
end

function GetEntitiesWithFilter(entityList, filterFunction)

    ASSERT(entityList ~= nil)
    ASSERT(type(filterFunction) == "function")
    
    local filteredEntities = { }
    
    for index, entity in ientitylist(entityList) do
        if filterFunction(entity) then
            table.insert(filteredEntities, entity)
        end
    end
    
    return filteredEntities

end

function EntityListToTable(entityList)

    return GetEntitiesWithFilter(entityList, function(entity) return true end)

end

function GetEntitiesForTeam(className, teamNumber)

    ASSERT(type(className) == "string")
    ASSERT(type(teamNumber) == "number")
    
    local function teamFilterFunction(entity)
        return entity:GetTeamNumber() == teamNumber
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), teamFilterFunction)

end

function GetEntitiesForTeamWithinRange(className, teamNumber, origin, range)

    ASSERT(type(className) == "string")
    ASSERT(type(teamNumber) == "number")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    
    local function teamInRangeFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (range * range)
        return entity:GetTeamNumber() == teamNumber and inRange
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), teamInRangeFilterFunction)
    
end

function GetEntitiesWithinRange(className, origin, range)

    ASSERT(type(className) == "string")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    
    local function inRangeFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (range * range)
        return inRange
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), inRangeFilterFunction)
    
end

function GetEntitiesForTeamWithinXZRange(className, teamNumber, origin, range)
    
    ASSERT(type(className) == "string")
    ASSERT(type(teamNumber) == "number")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    
    local function inRangeXZFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquaredXZ() <= (range * range)
        return entity:GetTeamNumber() == teamNumber and inRange
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), inRangeXZFilterFunction)
    
end

function GetEntitiesForTeamWithinRangeAreVisible(className, teamNumber, origin, range, visibleState)

    ASSERT(type(className) == "string")
    ASSERT(type(teamNumber) == "number")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    ASSERT(type(visibleState) == "boolean")
    
    local function teamInRangeVisibleStateFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (range * range)
        return entity:GetTeamNumber() == teamNumber and inRange and entity:GetIsVisible() == visibleState
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), teamInRangeVisibleStateFilterFunction)
    
end

function GetEntitiesWithinRangeAreVisible(className, origin, range, visibleState)

    ASSERT(type(className) == "string")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    ASSERT(type(visibleState) == "boolean")
    
    local function teamInRangeVisibleStateFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (range * range)
        return inRange and entity:GetIsVisible() == visibleState
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), teamInRangeVisibleStateFilterFunction)
    
end

function GetEntitiesWithinXZRangeAreVisible(className, origin, range, visibleState)

    ASSERT(type(className) == "string")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    ASSERT(type(visibleState) == "boolean")
    
    local function inRangeXZFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquaredXZ() <= (range * range)
        return inRange and entity:GetIsVisible()
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), inRangeXZFilterFunction)
    
end

function GetEntitiesWithinRangeInView(className, range, player)

    ASSERT(type(className) == "string")
    ASSERT(type(range) == "number")
    ASSERT(player ~= nil)
    
    function withinViewFilter(entity)
        local dist = player:GetDistance(entity)
        return (dist <= range) and player:GetCanSeeEntity(entity)
    end
    
    return GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(className), withinViewFilter)
    
end

function GetEntitiesMatchAnyTypesForTeam(typeList, teamNumber)

    ASSERT(type(typeList) == "table")
    ASSERT(type(teamNumber) == "number")
    
    local function teamFilter(entity)
        return entity:GetTeamNumber() == teamNumber
    end
    
    local allMatchingEntsList = { }
    
    for i, type in ipairs(typeList) do
        local matchingEntsForType = GetEntitiesWithFilter(Shared.GetEntitiesWithClassname(type), teamFilter)
        table.adduniquetable(matchingEntsForType, allMatchingEntsList)
    end
    
    return allMatchingEntsList

end

function GetEntitiesMatchAnyTypes(typeList)

    ASSERT(type(typeList) == "table")
    
    local allMatchingEntsList = { }
    
    for i, type in ipairs(typeList) do
        for i, entity in ientitylist(Shared.GetEntitiesWithClassname(type)) do
            table.insertunique(allMatchingEntsList, entity)
        end
    end
    
    return allMatchingEntsList

end

function GetEntitiesWithMixin(mixinType)

    ASSERT(type(mixinType) == "string")
    
    return EntityListToTable(Shared.GetEntitiesWithTag(mixinType))

end

function GetEntitiesWithMixinForTeam(mixinType, teamNumber)

    ASSERT(type(mixinType) == "string")
    ASSERT(type(teamNumber) == "number")
    
    local function onTeamFilterFunction(entity)
        return entity:GetTeamNumber() == teamNumber
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithTag(mixinType), onTeamFilterFunction)

end

function GetEntitiesWithMixinWithinRange(mixinType, origin, range)

    ASSERT(type(mixinType) == "string")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    
    local function inRangeFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (range * range)
        return inRange
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithTag(mixinType), inRangeFilterFunction)
    
end

function GetEntitiesWithMixinWithinRangeAreVisible(mixinType, origin, range, visibleState)

    ASSERT(type(mixinType) == "string")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    ASSERT(type(visibleState) == "boolean")
    
    local function teamInRangeVisibleStateFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (range * range)
        return inRange and entity:GetIsVisible() == visibleState
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithTag(mixinType), teamInRangeVisibleStateFilterFunction)
    
end

function GetEntitiesWithMixinForTeamWithinRange(mixinType, teamNumber, origin, range)

    ASSERT(type(mixinType) == "string")
    ASSERT(type(teamNumber) == "number")
    ASSERT(origin ~= nil)
    ASSERT(type(range) == "number")
    
    local function teamInRangeFilterFunction(entity)
        local inRange = (entity:GetOrigin() - origin):GetLengthSquared() <= (range * range)
        return entity:GetTeamNumber() == teamNumber and inRange
    end
    return GetEntitiesWithFilter(Shared.GetEntitiesWithTag(mixinType), teamInRangeFilterFunction)
    
end

// Fades damage linearly from center point to radius (0 at far end of radius)
function RadiusDamage(entities, centerOrigin, radius, fullDamage, attacker, ignoreLOS)

    // Do damage to every target in range
    for index, target in ipairs(entities) do
    
        // Find most representative point to hit
        local targetOrigin = target:GetOrigin()
        if target.GetModelOrigin then
            targetOrigin = target:GetModelOrigin()
        end
        if target.GetEngagementPoint then
            targetOrigin = target:GetEngagementPoint()
        end
        
        // Trace line to each target to make sure it's not blocked by a wall 
        local wallBetween, distanceFromTarget = GetWallBetween(centerOrigin, targetOrigin, target, attacker)
        if (ignoreLOS or not wallBetween) and (distanceFromTarget <= radius) then
        
            // Damage falloff
            local damageFalloff = fullDamage / radius
            local damage = fullDamage - distanceFromTarget * damageFalloff
            
            local damageDirection = targetOrigin - centerOrigin
            damageDirection:Normalize()
            
            target:TakeDamage(damage, attacker, attacker, target:GetOrigin(), damageDirection)

        end
        
    end
    
end

/**
 * Get list of child entities for player. Pass optional class name
 * to get only entities of that type.
 */
function GetChildEntities(player, isaClassName)

    local childEntities = { }
    
    for i = 0, player:GetNumChildren() - 1 do
        local currentChild = player:GetChildAtIndex(i)
        if isaClassName == nil or currentChild:isa(isaClassName) then
            table.insert(childEntities, currentChild)
        end
    end
    
    return childEntities
    
end

// Return entity number or -1 if not found
function FindNearestEntityId(className, location)

    local entityId = -1
    local shortestDistance = nil   
    
    for index, current in ientitylist(Shared.GetEntitiesWithClassname(className)) do

        local distance = (current:GetOrigin() - location):GetLength()
        
        if(shortestDistance == nil or distance < shortestDistance) then
        
            entityId = current:GetId()
            shortestDistance = distance
            
        end
            
    end    
    
    return entityId
    
end

/**
 * Given a list of entities (representing spawn points), returns a randomly chosen
 * one which is unobstructed for the player. If none of them are unobstructed, the
 * method returns nil.
 */
function GetRandomClearSpawnPoint(player, spawnPoints)

    local numSpawnPoints = table.maxn(spawnPoints)
    
    // Start with random spawn point then move up from there
    local baseSpawnIndex = NetworkRandomInt(1, numSpawnPoints)

    for i = 1, numSpawnPoints do

        local spawnPointIndex = ((baseSpawnIndex + i) % numSpawnPoints) + 1
        local spawnPoint = spawnPoints[spawnPointIndex]

        // Check to see if the spot is clear to spawn the player.
        local spawnOrigin = Vector(spawnPoint:GetOrigin())
        local spawnAngles = Angles(spawnPoint:GetAngles())
        spawnOrigin.y = spawnOrigin.y + .5
        
        spawnAngles.pitch = 0
        spawnAngles.roll  = 0
        
        player:SpaceClearForEntity(spawnOrigin)
        
        return spawnPoint
            
    end
    
    Print("GetRandomClearSpawnPoint - No unobstructed spawn point to spawn %s (tried %d)", player:GetName(), numSpawnPoints)
    
    return nil

end

// Look for unoccupied spawn point nearest given position
function GetClearSpawnPointNearest(player, spawnPoints, position)

    // Build sorted list of spawns, closest to farthest
    local sortedSpawnPoints = {}
    table.copy(spawnPoints, sortedSpawnPoints)
    
    // The comparison function must return a boolean value specifying whether the first argument should 
    // be before the second argument in the sequence (he default behavior is <).
    function sort(spawn1, spawn2)
        return (spawn1:GetOrigin() - position):GetLength() < (spawn2:GetOrigin() - position):GetLength()
    end    
    table.sort(sortedSpawnPoints, sort)

    // Build list of spawns in 
    for i = 1, table.maxn(sortedSpawnPoints) do 

        // Check to see if the spot is clear to spawn the player.
        local spawnPoint = sortedSpawnPoints[i]
        local spawnOrigin = Vector(spawnPoint:GetOrigin())

        if (player:SpaceClearForEntity(spawnOrigin)) then
        
            return spawnPoint
            
        end
        
    end
    
    Print("GetClearSpawnPointNearest - No unobstructed spawn point to spawn " , player:GetName())
    
    return nil

end

/**
 * Not all Entities have eyes. Play it safe.
 */
function GetEntityEyePos(entity)
    return (entity.GetEyePos and entity:GetEyePos()) or entity:GetOrigin()
end

/**
 * Not all Entities have view angles. Play it safe.
 */
function GetEntityViewAngles(entity)
    return (entity.GetViewAngles and entity:GetViewAngles()) or entity:GetAngles()
end