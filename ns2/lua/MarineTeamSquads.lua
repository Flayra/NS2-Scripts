// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineTeamSquads.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Manages marine squads. Shared on client and server.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Put most quick to say colors as most common squads. New squads 
// choose earlier colors in this array first, although later squads
// can exist if the earlier ones die off.
local kSquadColors =
{
    // Squad 1
    {255, 0, 0, 255},      // red
    {0, 0, 255, 255},      // blue
    {0, 255, 0, 255},      // green
    {255, 255, 0, 255},    // yellow
    {255, 166, 0, 255},    // best squad - orange    
    {231, 0, 255, 255},    // purple
    {255, 255, 255, 255},  // white
    {0, 0, 0, 255},        // black
    {255, 154, 237, 255},  // pink
    {7, 244, 241, 255},    // cyan
}

local kSquadNames = { "Red", "Blue", "Green", "Yellow", "Purple", "Orange", "White", "Black", "Pink", "Cyan" }

// Max number of squads
kNumSquads = 10

// Max number of marines in a squad
kMaxSquadSize = 6

// Distance between players in meters in order to group them. Also draw circle radius.
local kSquadRadius = 4

// Need this many players to join a squad, else players have no squad
kSquadMinimumEntityCount = 2

// Returns table of squad numbers that entities are in, from most to least. If equal 
// number of entities in multiple squads, returns lower numbers first. Doesn't count
// entities with squad of 0.
function GetSquadIndicesForEntities(entities)

    // Stores entries as {squadIndex, # entities}
    local kSquadIndex = 1
    local kSquadEntityCount = 2
    local squadEntities = {}
    
    for i = 1, kNumSquads do
        squadEntities[i] = {i, 0}
    end
    
    for index, entity in ipairs(entities) do
    
        local squadIndex = entity:GetSquad()
        
        if(squadIndex > 0) then
        
            squadEntities[squadIndex][kSquadEntityCount] = squadEntities[squadIndex][kSquadEntityCount] + 1
            
        end
        
    end
    
    local numElements = table.maxn(squadEntities)
    if(numElements > 1) then

        // Sort largest to smallest    
        function sort(entity1, entity2)
            
            return entity2[kSquadEntityCount] < entity1[kSquadEntityCount]
            
        end

        table.sort(squadEntities, sort)
        
    end

    // Construct table of just squad indices    
    local finalSquadIndices = {}
    
    for i = 1, table.maxn(squadEntities) do
    
        local entityCount = squadEntities[i][kSquadEntityCount]
        
        if(entityCount > 0) then
        
            table.insertunique(finalSquadIndices, squadEntities[i][kSquadIndex])
            
        end
        
    end
    
    return finalSquadIndices
    
end

function AssignEntitiesToSquad(entities, squadNumber)

    for index, entity in ipairs(entities) do
    
        entity:SetSquad(squadNumber)
        
    end
    
end

function GetSquadRadius()
    return kSquadRadius
end

function GetColorForSquad(squadIndex)

    if squadIndex and (squadIndex > 0) and (squadIndex <= GetMaxSquads()) then
        return kSquadColors[squadIndex]
    end
    
    return nil
    
end

function GetNameForSquad(squadIndex)

    if(squadIndex > 0 and squadIndex <= GetMaxSquads()) then
        return string.format("%s squad", kSquadNames[squadIndex])
    end
    
    return ""
    
end

function GetMaxSquads()
    return kNumSquads
end

function GetMaxSquadSize()
    return kMaxSquadSize
end

function GetSquadRadius()
    return kSquadRadius
end

function GetSquadClass()
    return "Marine"
end

// Pass in player, returns squad of players near player
function GetGroupOfPlayersNearPlayer(player, playerList)

    local squad = {}
    table.insertunique(squad, player)
    
    while (true) do
    
        local madeChanges = false

        // For each player in squad
        for squadIndex, squadEntity in ipairs(squad) do
        
            // For each other player in list, not in squad
            for index, currentPlayer in ipairs(playerList) do
            
                // If players are close, add to squad
                if(squadEntity ~= currentPlayer and not table.find(squad, currentPlayer)) then
            
                    // If nearby, add to our squad
                    local dist = squadEntity:GetDistance(currentPlayer)
                
                    if(dist <= GetSquadRadius()*2) then
                
                        table.insertunique(squad, currentPlayer)
                        
                        // Process again because addition of new player to squad could bring in more players
                        madeChanges = true
                    
                    end
            
                end

            end
    
        end
        
        if(not madeChanges) then
        
            return squad
            
        end

    end
                
end

// Returns the best squad index (color) given the players in specified squad and the squads they are in.
// Keeps majority ownership if possible. Takes a table of players and a table of assigned squad indices not to use.
function GetBestSquadIndex(squad, assignedSquadIndices)

    local squadIndices = GetSquadIndicesForEntities(squad)
    
    // Determine new squad number from majority ownership, biasing towards lowest squad number (make sure it isn't already used)
    if(table.maxn(squadIndices) > 0) then
    
        for index, squadIndex in ipairs(squadIndices) do
        
            if(not table.find(assignedSquadIndices, squadIndex)) then
            
                return squadIndex                
                
            end
            
        end
        
    end
    
    // Otherwise if squads unassigned or squads taken, find first free squad index
    for squadIndex = 1, kNumSquads do
    
        if(not table.find(assignedSquadIndices, squadIndex)) then
        
            return squadIndex
            
        end
        
    end
    
    return 0
    
end

// Build list of squads, sorted from biggest to smallest
function GetSortedSquadList(playerList)

    local squadList = {}
    
    // For each player
    for index, player in ipairs(playerList) do
    
        function sortSquad(player1, player2)
            return player2:GetId() > player1:GetId()
        end
    
        local squad = GetGroupOfPlayersNearPlayer(player, playerList)
        
        // Sort squad so we squads with the same players in a different order aren't counted twice
        table.sort(squad, sortSquad)
        
        table.insertunique(squadList, squad)
        
    end    
    
    // Sort from biggest to smallest, if necessary
    if(table.maxn(squadList) > 1) then
    
        function sortTable(squad1, squad2)
            return table.maxn(squad2) < table.maxn(squad1)
        end
    
        table.sort(squadList, sortTable)
        
    end
    
    return squadList
    
end

// Returns spawn point for player if it found one that isn't intersecting the world
// or other entities, otherwise returns nil
function ChooseRandomSpawn(center, player)

    // Pick a random position around center point of squad
    local testOrigin = center + Vector( (NetworkRandom() - .5) * 6, NetworkRandom() * 1.5, (NetworkRandom() - .5) * 6)
    DropToFloor(testOrigin)

    local filter = ConditionalValue(player, EntityFilterOne(player), nil)
    local physicsMask = PhysicsMask.AllButPCs
    
    // (TODO: re-enable this test when function works) If player has room to spawn here, stop looking
    if not Shared.CollideBox(player:GetExtents(), testOrigin, physicsMask, filter) then

        return testOrigin
        
    end
    
    return nil

end

// Return random spawn point, angles and view angles when spawning into a squad.
// Returns nil if squad doesn't exist or no valid spawn point exists.
function GetSpawnInSquad(marine, squadIndex)
    
    // Get centroid for all players in squad
    local numInSquad = 0
    local totalPosition = Vector(0, 0, 0)
    
    if(squadIndex ~= nil and squadIndex > 0) then
    
        function addPosition(entity)
        
            if(entity:GetSquad() == squadIndex) then
            
                totalPosition = totalPosition + entity:GetOrigin()
                numInSquad = numInSquad + 1
                
            end
            
        end
        
        local squadEntities = GetEntitiesForTeam(GetSquadClass(), marine:GetTeamNumber())
        table.foreachfunctor(squadEntities, addPosition)

        if(numInSquad >= kSquadMinimumEntityCount) then
        
            local centroid = Vector(totalPosition.x / numInSquad, totalPosition.y / numInSquad, totalPosition.z / numInSquad)            
            local success, spawnOrigin = GetRandomSpaceForEntity(centroid, 0, 7, 3)
            if(success) then
            
                // Spawn player a little off ground to avoid stuck issues
                spawnOrigin.y = spawnOrigin.y + .1
                
                // Pick a random player in the squad to copy their direction
                local randomSquadMate = table.random(squadEntities)
                
                return spawnOrigin, randomSquadMate:GetAngles(), randomSquadMate:GetViewAngles()
                
            end
            
        end
        
    end
    
    return nil, nil, nil

end

