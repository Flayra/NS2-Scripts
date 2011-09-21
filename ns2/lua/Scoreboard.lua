//=============================================================================
//
// lua/Scoreboard.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================
local playerData = { }

function Scoreboard_Clear()

    playerData = { }
    
end

// Score > Kills > Deaths > Resources
function Scoreboard_Sort()

    function sortByScore(player1, player2)
    
        if player1.Score == player2.Score then
        
            if player1.Kills == player2.Kills then
            
                if player1.Deaths == player2.Deaths then    
                
                    if player1.Resources == player2.Resources then    
                    
                        // Somewhat arbitrary but keeps more coherence and adds players to bottom in case of ties
                        return player1.ClientIndex > player2.ClientIndex
                        
                    else
                        return player1.Resources > player2.Resources
                    end
                    
                else
                    return player1.Deaths < player2.Deaths
                end
                
            else
                return player1.Kills > player2.Kills
            end
            
        else
            return player1.Score > player2.Score    
        end        
        
    end
    
    // Sort it by entity id
    table.sort(playerData, sortByScore)

end

// Hooks from console commands coming from server
function Scoreboard_OnResetGame()

    // For each player, clear game data (on reset)
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        playerRecord.EntityId = 0
        playerRecord.EntityTeamNumber = 0
        playerRecord.Score = 0
        playerRecord.Kills = 0
        playerRecord.Deaths = 0
        playerRecord.IsCommander = false
        playerRecord.Resources = 0
        playerRecord.Status = ""
        playerRecord.IsSpectator = false
        
    end 

end

function Scoreboard_OnClientDisconnect(clientIndex)

    table.removeConditional(  playerData, function (element) return element.ClientIndex == clientIndex end )
    return true
    
end

function Scoreboard_SetPlayerData(clientIndex, entityId, playerName, teamNumber, score, kills, deaths, resources, isCommander, status, isSpectator)

    // Lookup record for player and update it
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord.ClientIndex == clientIndex then

            // Update entry
            playerRecord.EntityId = entityId
            playerRecord.Name = playerName
            playerRecord.EntityTeamNumber = teamNumber
            playerRecord.Score = score
            playerRecord.Kills = kills
            playerRecord.Deaths = deaths
            playerRecord.IsCommander = isCommander
            playerRecord.Resources = resources
            playerRecord.Status = status
            playerRecord.IsSpectator = isSpectator
            
            Scoreboard_Sort()
            
            return
            
        end
        
    end
        
    // Otherwise insert a new record
    local playerRecord = {}
    playerRecord.ClientIndex = clientIndex
    playerRecord.EntityId = entityId
    playerRecord.Name = playerName
    playerRecord.EntityTeamNumber = teamNumber
    playerRecord.Score = score
    playerRecord.Kills = kills
    playerRecord.Deaths = deaths
    playerRecord.IsCommander = isCommander
    playerRecord.Resources = 0
    playerRecord.Ping = 0
    playerRecord.Status = status
    playerRecord.IsSpectator = isSpectator
    
    table.insert(playerData, playerRecord )
    
    Scoreboard_Sort()
    
end

function Scoreboard_SetPing(clientIndex, ping)

    local setPing = false
    
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        if playerRecord.ClientIndex == clientIndex then
            playerRecord.Ping = ping
            setPing = true
        end
        
    end
    
end

// Set local data for player so scoreboard updates instantly
function Scoreboard_SetLocalPlayerData(playerName, index, data)
    
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord.Name == playerName then
        
            playerRecord[index] = data

            break
            
        end
        
    end
    
end

function Scoreboard_GetPlayerData(clientIndex, dataType)

    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if playerRecord.ClientIndex == clientIndex then

            return playerRecord[dataType]
            
        end

    end
    
    return nil
    
end

/**
 * Determine if scoreboard is visible
 */
function ScoreboardUI_GetVisible()
    local player = Client.GetLocalPlayer()
    return (player ~= nil) and player.showScoreboard
end

/**
 * Get table of scoreboard player recrods for all players with team numbers in specified table.
 */
function GetScoreData(teamNumberTable)

    local scoreData = { }
    
    for index, playerRecord in ipairs(playerData) do
        if table.find(teamNumberTable, playerRecord.EntityTeamNumber) then
            table.insert(scoreData, playerRecord)
        end
    end
    
    return scoreData
    
end

/**
 * Get score data for the blue team
 */
function ScoreboardUI_GetBlueScores()
    return GetScoreData({ kTeam1Index })
end

/**
 * Get score data for the red team
 */
function ScoreboardUI_GetRedScores()
    return GetScoreData({ kTeam2Index })
end

/**
 * Get score data for everyone not playing.
 */
function ScoreboardUI_GetSpectatorScores()
    return GetScoreData({ kTeamReadyRoom, kSpectatorIndex })
end

function ScoreboardUI_GetAllScores()
    return GetScoreData({ kTeam1Index, kTeam2Index, kTeamReadyRoom, kSpectatorIndex })
end

function ScoreboardUI_GetTeamResources(teamNumber)

    local teamInfo = GetEntitiesForTeam("TeamInfo", teamNumber)
    if table.count(teamInfo) > 0 then
        return teamInfo[1]:GetTeamResources()
    end
    
    return 0

end

/**
 * Get the name of the blue team
 */
function ScoreboardUI_GetBlueTeamName()
    return kTeam1Name
end

/**
 * Get the name of the red team
 */
function ScoreboardUI_GetRedTeamName()
    return kTeam2Name
end

/**
 * Get the name of the spectator team
 */
function ScoreboardUI_GetSpectatorTeamName()
    return kSpectatorTeamName
end

/**
 * Return true if playerName is a local player.
 */
function ScoreboardUI_IsPlayerLocal(playerName)
    
    local player = Client.GetLocalPlayer()
    
    // Get entry with this name and check entity id
    if player then
    
        for i = 1, table.maxn(playerData) do

            local playerRecord = playerData[i]        
            if playerRecord.Name == playerName then

                return (player:GetClientIndex() == playerRecord.ClientIndex)
                
            end
            
        end    
        
    end
    
    return false
    
end

function ScoreboardUI_GetOrderedCommanderNames(teamNumber)

    local commanders = {}
    
    // Create table of commander entity ids and names
    for i = 1, table.maxn(playerData) do
    
        local playerRecord = playerData[i]
        
        if (playerRecord.EntityTeamNumber == teamNumber) and playerRecord.IsCommander then
            table.insert( commanders, {playerRecord.EntityId, playerRecord.Name} )
        end
        
    end
    
    function sortCommandersByEntity(pair1, pair2)
        return pair1[1] < pair2[1]
    end
    
    // Sort it by entity id
    table.sort(commanders, sortCommandersByEntity)
    
    // Return names in order
    local commanderNames = {}
    for index, pair in ipairs(commanders) do
        table.insert(commanderNames, pair[2])
    end
    
    return commanderNames
    
end

function ScoreboardUI_GetNumberOfAliensByType(alienType)

    local numberOfAliens = 0
    
    for index, playerRecord in ipairs(playerData) do
        if alienType == playerRecord.Status then
            numberOfAliens = numberOfAliens + 1
        end
    end
    
    return numberOfAliens

end