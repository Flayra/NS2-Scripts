// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Gamerules.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Gamerules.lua")

if(Client) then
    Script.Load("lua/NS2ConsoleCommands_Client.lua")
else
    Script.Load("lua/NS2ConsoleCommands_Server.lua")
end

class 'NS2Gamerules' (Gamerules)

NS2Gamerules.kMapName = "ns2_gamerules"

NS2Gamerules.kGamerulesThinkInterval = .5
NS2Gamerules.kGameEndCheckInterval = .75
NS2Gamerules.kPregameLength = 15
NS2Gamerules.kCountDownLength = 6
NS2Gamerules.kTimeToReadyRoom = 8

////////////
// Server //
////////////
if(Server) then

Script.Load("lua/PlayingTeam.lua")
Script.Load("lua/ReadyRoomTeam.lua")
Script.Load("lua/SpectatingTeam.lua")

NS2Gamerules.kMarineStartSound   = PrecacheAsset("sound/ns2.fev/marine/voiceovers/game_start")
NS2Gamerules.kAlienStartSound    = PrecacheAsset("sound/ns2.fev/alien/voiceovers/game_start")
NS2Gamerules.kVictorySound       = PrecacheAsset("sound/ns2.fev/common/victory")
NS2Gamerules.kDefeatSound        = PrecacheAsset("sound/ns2.fev/common/loss")
NS2Gamerules.kCountdownSound     = PrecacheAsset("sound/ns2.fev/common/countdown")

NS2Gamerules.kInfestationEffectsUpdateRate = .3

// Allow players to spawn in for free (not using IP or eggs) for this many seconds after the game starts
NS2Gamerules.kFreeSpawnTime = 15

function NS2Gamerules:BuildTeam(teamType)

    if(teamType == kAlienTeamType) then
        return AlienTeam()
    end
    
    return MarineTeam()
    
end

function NS2Gamerules:SetGameState(state)

    if state ~= self.gameState then
    
        self.gameState = state
        self.timeGameStateChanged = Shared.GetTime()
        self.timeSinceGameStateChanged = 0
        
        local frozenState = (state == kGameState.Countdown) and (not Shared.GetDevMode())
        self.team1:SetFrozenState(frozenState)
        self.team2:SetFrozenState(frozenState)
        
        if self.gameState == kGameState.Started then
            self.gameStartTime = Shared.GetTime()
        end

    end
    
end

function NS2Gamerules:GetGameState()
    return self.gameState
end

function NS2Gamerules:OnCreate()

    // Calls SetGamerules()
    Gamerules.OnCreate(self)
    
    // Create team objects
    self.team1 = self:BuildTeam(kTeam1Type)
    self.team1:Initialize(kTeam1Name, kTeam1Index)

    self.team2 = self:BuildTeam(kTeam2Type)
    self.team2:Initialize(kTeam2Name, kTeam2Index)

    self.worldTeam = ReadyRoomTeam()
    self.worldTeam:Initialize("World", kTeamReadyRoom)

    self.spectatorTeam = SpectatingTeam()
    self.spectatorTeam:Initialize("Spectator", kSpectatorIndex)

    self:SetGameState(kGameState.NotStarted)
    
    self.allTech = false
    self.orderSelf = false
    self.autobuild = false
  
    self:SetIsVisible(false)
    self:SetPropagate(Entity.Propagate_Never)
    
    self.justCreated = true
    
end

function NS2Gamerules:OnDestroy()

    self.team1:Uninitialize()
    self.team1 = nil
    self.team2:Uninitialize()
    self.team2 = nil
    self.worldTeam:Uninitialize()
    self.worldTeam = nil
    self.spectatorTeam:Uninitialize()
    self.spectatorTeam = nil

    Gamerules.OnDestroy(self)

end


function NS2Gamerules:GetFriendlyFire()
    return false
end

// All damage is routed through here.
function NS2Gamerules:CanEntityDoDamageTo(attacker, target)
    return CanEntityDoDamageTo(attacker, target, Shared.GetCheatsEnabled(), Shared.GetDevMode(), self:GetFriendlyFire())
end

function NS2Gamerules:OnClientDisconnect(client)

    local player = client:GetControllingPlayer()

    // When a player disconnects remove them from their team
    if (player ~= nil) then
        local team = self:GetTeam(player:GetTeamNumber())
        
        if team then
            team:RemovePlayer(player)
        end
    end
    
    Gamerules.OnClientDisconnect(self, client)
    
end

function NS2Gamerules:OnEntityCreate(entity)

    self:OnEntityChange(nil, entity:GetId())

    if entity.GetTeamNumber then
    
        local team = self:GetTeam(entity:GetTeamNumber())
        
        if team then
        
            if entity:isa("Player") then
        
                if team:AddPlayer(entity) then

                    // Tell team to send entire tech tree on team change
                    entity.sendTechTreeBase = true

                    // Clear all hotkey groups on team change since old
                    // hotkey groups will be invalid.
                    entity:InitializeHotkeyGroups()                
                    
                end 
               
                // Send scoreboard changes to everyone    
                entity:SetScoreboardChanged(true)                

            elseif entity:isa("Structure") then
            
                team:TechAdded(entity)
            
            end
            
        end
        
    end
    
end

function NS2Gamerules:OnEntityDestroy(entity)
    
    self:OnEntityChange(entity:GetId(), nil)

    if entity.GetTeamNumber then
    
        local team = self:GetTeam(entity:GetTeamNumber())
        if team then
        
            if entity:isa("Player") then
                team:RemovePlayer(entity)
                
            elseif entity:isa("Structure") then
            
                team:TechRemoved(entity)
            
            end
            
        end
        
    end
   
end

// Update player and entity lists
function NS2Gamerules:OnEntityChange(oldId, newId)

    PROFILE("NS2Gamerules:OnEntityChange")
    
    self.worldTeam:OnEntityChange(oldId, newId)
    self.team1:OnEntityChange(oldId, newId)
    self.team2:OnEntityChange(oldId, newId)
    self.spectatorTeam:OnEntityChange(oldId, newId)

    // Keep server map entities up to date    
    local index = table.find(Server.mapLoadLiveEntityValues, oldId)
    if index then
    
        table.removevalue(Server.mapLoadLiveEntityValues, oldId)
        if newId then
        
            table.insert(Server.mapLoadLiveEntityValues, newId)
            
        end
        
    end
    
    local allScriptActors = Shared.GetEntitiesWithClassname("ScriptActor")
    
    // Tell every ScriptActor we've changed ids been deleted (changed to nil)
    for index, ent in ientitylist(allScriptActors) do
        if ent:GetId() ~= oldId then
            ent:OnEntityChange(oldId, newId)
        end
    end   

end

local function PostKillStat(targetEntity, attacker, doer)

    if not attacker or not targetEntity or not doer then
        return
    end

    // General info.
    local urlString = "http://unknownworldsstats.appspot.com/statkill?version=" .. ToString(Shared.GetBuildNumber())
    urlString = urlString .. "&map=" .. Shared.GetMapName()

    // Attacker info.
    urlString = urlString .. "&attacker_type=" .. attacker:GetClassName()
    urlString = urlString .. "&attacker_team=" .. attacker:GetTeamType()
    urlString = urlString .. "&attacker_weapon=" .. doer:GetClassName()
    local attackerOrigin = attacker:GetOrigin()
    urlString = urlString .. "&attackerx=" .. string.format("%.2f", attackerOrigin.x)
    urlString = urlString .. "&attackery=" .. string.format("%.2f", attackerOrigin.y)
    urlString = urlString .. "&attackerz=" .. string.format("%.2f", attackerOrigin.z)

    // Target info.
    urlString = urlString .. "&target_type=" .. targetEntity:GetClassName()
    urlString = urlString .. "&target_team=" .. targetEntity:GetTeamType()
    local targetWeapon = "None"
    if targetEntity.GetActiveWeapon and targetEntity:GetActiveWeapon() then
        targetWeapon = targetEntity:GetActiveWeapon():GetClassName()
    end
    urlString = urlString .. "&target_weapon=" .. targetWeapon
    local targetOrigin = targetEntity:GetOrigin()
    urlString = urlString .. "&targetx=" .. string.format("%.2f", targetOrigin.x)
    urlString = urlString .. "&targety=" .. string.format("%.2f", targetOrigin.y)
    urlString = urlString .. "&targetz=" .. string.format("%.2f", targetOrigin.z)
    urlString = urlString .. "&target_lifetime=" .. string.format("%.2f", Shared.GetTime() - targetEntity:GetCreationTime())
    
    Shared.GetWebpage(urlString, function (data) end)

end

// Called whenever an entity is killed. Killer could be the same as targetEntity. Called before entity is destroyed.
function NS2Gamerules:OnKill(targetEntity, damage, attacker, doer, point, direction)

    PostKillStat(targetEntity, attacker, doer)
    
    self.team1:OnKill(targetEntity, damage, attacker, doer, point, direction)
    self.team2:OnKill(targetEntity, damage, attacker, doer, point, direction)
    self.worldTeam:OnKill(targetEntity, damage, attacker, doer, point, direction)
    self.spectatorTeam:OnKill(targetEntity, damage, attacker, doer, point, direction)
    
end

// Find team start with team 0 or for specified team. Remove it from the list so other teams don't start there. Return nil if there are none.
function NS2Gamerules:ChooseTeamLocation(teamLocations, teamNumber)

    local teamLocation = nil
    local validLocations = {}
    local currentIndex = 1
    
    // Build list of valid starts (marked as "neutral" or for this team in map)
    for index, currentLocation in pairs(teamLocations) do
    
        local teamNum = currentLocation:GetTeamNumber()
        if(teamNum == 0 or teamNum == teamNumber) then
        
            validLocations[currentIndex] = currentLocation
            currentIndex = currentIndex + 1
            
        end
        
    end
    
    // Select entry randomly
    teamLocation = table.random(validLocations)
    if(teamLocation ~= nil) then
    
        // Remove it from the list so it isn't chosen by other team
        table.removevalue(teamLocations, teamLocation) 
        
    else    
        Print("ChooseTeamStart couldn't find a remaining team start location for team %d", teamNumber)   
    end    
    
    return teamLocation
    
end

// Use this function to change damage according to current upgrades
function NS2Gamerules:GetUpgradedDamage(attacker, doer, damage, damageType)

    local damageScalar = 1

    if attacker ~= nil then
    
        // Check damage type. We can only have one of these at a time.
        if (damageType == kDamageType.Normal) then    
        
            if(GetTechSupported(attacker, kTechId.Weapons3, true)) then
            
                damageScalar = kWeapons3DamageScalar
                
            elseif(GetTechSupported(attacker, kTechId.Weapons2, true)) then
            
                damageScalar = kWeapons2DamageScalar
                
            elseif(GetTechSupported(attacker, kTechId.Weapons1, true)) then
            
                damageScalar = kWeapons1DamageScalar
                
            end
            
        end
        
        // Alien melee upgrades
        if doer:isa("BiteLeap") or doer:isa("SwipeBlink") or doer:isa("Gore") then
        
            if(GetTechSupported(attacker, kTechId.Melee3Tech, true)) then
            
                damageScalar = kMelee3DamageScalar
                
            elseif(GetTechSupported(attacker, kTechId.Melee2Tech, true)) then
            
                damageScalar = kMelee2DamageScalar
                
            elseif(GetTechSupported(attacker, kTechId.Melee1Tech, true)) then
            
                damageScalar = kMelee1DamageScalar
                
            end
            
        end
        
        // Add more if under influence of whip. This looks like it should be revisited.
        if HasMixin(attacker, "GameEffects") then
        
            local numFuries = attacker:GetStackableGameEffectCount(kFuryGameEffect)
            if numFuries > 0 then
                damageScalar = damageScalar * (1 + numFuries * Whip.kFuryDamageBoost)
            end
            
        end
        
    end
        
    return damage * damageScalar
    
end
AddFunctionContract(NS2Gamerules.GetUpgradedDamage, { Arguments = { "Entity", "Entity", "number", "number" }, Returns = { } })

// logs out any players currently as the commander
function NS2Gamerules:LogoutCommanders()
    local entityTable = EntityListToTable(Shared.GetEntitiesWithClassname("CommandStructure"))
    for index, entity in ipairs(entityTable) do
        if (entity:isa("CommandStructure")) then
            entity:Logout()
        end
    end
end
 
/**
 * Starts a new game by resetting the map and all of the players. Keep everyone on current teams (readyroom, playing teams, etc.) but 
 * respawn playing players.
 */
function NS2Gamerules:ResetGame()

    // Cleanup any peeps currently in the commander seat by logging them out
    // have to do this before we start destroying stuff.
    self:LogoutCommanders()
    
    // Destroy any map entities that are still around
    DestroyLiveMapEntities()    
    
    // Track which clients have joined teams so we don't 
    // give them starting resources again if they switch teams
    self.userIdsInGame = {}
    
    // Reset all players, delete other not map entities that were created during 
    // the game (hives, command structures, initial resource towers, etc)
    // We need to convert the EntityList to a table since we are destroying entities
    // within the EntityList here.
    local entityTable = EntityListToTable(Shared.GetEntitiesWithClassname("Entity"))
    for index, entity in ipairs(entityTable) do

        // Don't reset/delete NS2Gamerules or TeamInfo.
        if entity ~= self and not entity:isa("TeamInfo") then
        
            local isMapEntity = entity:GetIsMapEntity()
            local mapName = entity:GetMapName()
            
            if ( (entity:GetIsMapEntity() and entity:isa("ScriptActor")) or entity:isa("Player") ) then
                entity:Reset()
            else
                DestroyEntity(entity)
            end

        end       
 
    end
    
    // Create living map entities fresh
    CreateLiveMapEntities()
    
    // Build list of team locations
    local teamLocations = EntityListToTable(Shared.GetEntitiesWithClassname("TeamLocation"))
    local numTeamLocations = table.maxn(teamLocations)
    if(numTeamLocations < 2) then
        Print("Warning -- Found only %d %s entities.", numTeamLocations, TeamLocation.kMapName)
    end
    
    local resourcePoints = Shared.GetEntitiesWithClassname("ResourcePoint")
    local numResourcePoints = resourcePoints:GetSize()
    if(numResourcePoints < 2) then
        Print("Warning -- Found only %d %s entities.", numResourcePoints, ResourcePoint.kPointMapName)
    end
    
    // Reset teams (keep players on them)    
    self.team1:ResetPreservePlayers(self:ChooseTeamLocation(teamLocations, kTeam1Index))
    self.team2:ResetPreservePlayers(self:ChooseTeamLocation(teamLocations, kTeam2Index))
    self.worldTeam:ResetPreservePlayers(nil)
    self.spectatorTeam:ResetPreservePlayers(nil)
            
    // Replace players with their starting classes with default loadouts at spawn locations
    self.team1:ReplaceRespawnAllPlayers()
    self.team2:ReplaceRespawnAllPlayers()
    
    self.forceGameStart = false
    self.losingTeam = nil
    self.preventGameEnd = nil
    // Reset banned players for new game
    self.bannedPlayers = {}
    
    // Send scoreboard update, ignoring other scoreboard updates (clearscores resets everything)
    for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        Server.SendCommand(player, "onresetgame")
        //player:SetScoreboardChanged(false)
    end
    
    self:SetGameState(kGameState.NotStarted)
    
end

function NS2Gamerules:GetTeam1()
    return self.team1
end

function NS2Gamerules:GetTeam2()
    return self.team2
end

function NS2Gamerules:GetWorldTeam()
    return self.worldTeam
end

function NS2Gamerules:GetSpectatorTeam()
    return self.spectatorTeam
end

// Returns bool for success and bool if we've played in the game already
function NS2Gamerules:GetUserPlayedInGame(player)

    local success = false
    local played = false
    
    ASSERT(player:isa("Player"))
    if player:isa("Player") then
    
        local owner = Server.GetOwner(player)
        if owner then
        
            local userId = tonumber(owner:GetUserId())
            ASSERT(userId >= 0)    
            
            // Could be invalid if we're still connecting to Steam
            played = table.find(self.userIdsInGame, userId) ~= nil
            success = true
            
        end
        
    end
    
    return success, played
end

function NS2Gamerules:SetUserPlayedInGame(player)

    ASSERT(player:isa("Player"))
    local owner = Server.GetOwner(player)
    if owner then
    
        local userId = tonumber(owner:GetUserId())
        ASSERT(userId >= 0)    
        
        // Could be invalid if we're still connecting to Steam
        return table.insertunique(self.userIdsInGame, userId)
        
    end
    
    return false
    
end

function NS2Gamerules:UpdateScores()

    if(self.timeToSendScores == nil or Shared.GetTime() > self.timeToSendScores) then
    
        local allPlayers = Shared.GetEntitiesWithClassname("Player")

        // If any player scoreboard info has changed, send those updates to everyone
        for index, fromPlayer in ientitylist(allPlayers) do
        
            // Send full update if any part of it changed
            if(fromPlayer:GetScoreboardChanged()) then
            
                // If any value has changed then we also want to update the internal score
                // so we can update steams player info.
                Server.UpdatePlayerInfo(fromPlayer, fromPlayer:GetName(), fromPlayer:GetScore())
                
                if(fromPlayer:GetName() ~= "") then
                
                    // Now send scoreboard info to everyone, including fromPlayer     
                    for index, sendToPlayer in ientitylist(allPlayers) do
                        // Build the message per player as some info is not synced for players
                        // on the other team.
                        local scoresMessage = BuildScoresMessage(fromPlayer, sendToPlayer)
                        Server.SendNetworkMessage(sendToPlayer, "Scores", scoresMessage, true)
                    end
                    
                    fromPlayer:SetScoreboardChanged(false)
                    
                else
                    Print("Player name empty, can't send scoreboard update.")
                end
                
            end
            
        end
        
        // When players connect to server, they send up a request for scores (as they 
        // may not have finished connecting when the scores where previously sent)    
        for index, requestingPlayer in ientitylist(allPlayers) do

            // Check for empty name string because player isn't connected yet
            if(requestingPlayer:GetRequestsScores() and requestingPlayer:GetName() ~= "") then
            
                // Send player all scores
                for index, fromPlayer in ientitylist(allPlayers) do
                
                    for index, sendToPlayer in ientitylist(allPlayers) do
                        local scoresMessage = BuildScoresMessage(fromPlayer, sendToPlayer)
                        Server.SendNetworkMessage(requestingPlayer, "Scores", scoresMessage, true)
                    end
                    
                end
                
                requestingPlayer:SetRequestsScores(false)
                
            end
            
        end
            
        // Time to send next score
        self.timeToSendScores = Shared.GetTime() + kScoreboardUpdateInterval
        
    end

end

// Batch together string with pings of every player to update scoreboard. This is a separate
// command to keep network utilization down.
function NS2Gamerules:UpdatePings()

    if(self.timeToSendPings == nil or Shared.GetTime() > self.timeToSendPings) then
    
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        
            Server.SendNetworkMessage( "Ping", BuildPingMessage(player:GetClientIndex(), player:GetPing()), true )

        end
        
        self.timeToSendPings = Shared.GetTime() + kUpdatePingsInterval
        
    end            

end

// Commander ejection functionality
function NS2Gamerules:CastVoteByPlayer( voteTechId, player )

    if voteTechId == kTechId.VoteDownCommander1 or voteTechId == kTechId.VoteDownCommander2 or voteTechId == kTechId.VoteDownCommander3 then

        // Get the 1st, 2nd or 3rd commander by entity order (does this on client as well)    
        local playerIndex = (voteTechId - kTechId.VoteDownCommander1 + 1)        
        local commanders = GetEntitiesForTeam("Commander", player:GetTeamNumber())
        
        if playerIndex <= table.count(commanders) then
        
            local targetCommander = commanders[playerIndex]
            local team = player:GetTeam()
            
            if player and team.VoteToEjectCommander then
                team:VoteToEjectCommander(player, targetCommander)
            end
            
        end
        
    end
    
end

function NS2Gamerules:OnMapPostLoad()

    Gamerules.OnMapPostLoad(self)
    
    // Now allow script actors to hook post load
    local allScriptActors = Shared.GetEntitiesWithClassname("ScriptActor")
    for index, scriptActor in ientitylist(allScriptActors) do
        scriptActor:OnMapPostLoad()
    end
    
end

function NS2Gamerules:UpdateInfestationEffects()

    local time = Shared.GetTime()
    
    if self.timeLastInfestationEffectsUpdate == nil or (time > self.timeLastInfestationEffectsUpdate + NS2Gamerules.kInfestationEffectsUpdateRate) then
    
        UpdateInfestationMasks()
        
        self.timeLastInfestationEffectsUpdate = time
        
    end
    
end

function NS2Gamerules:UpdateToReadyRoom()

    local state = self:GetGameState()
    if(state == kGameState.Team1Won or state == kGameState.Team2Won or state == kGameState.Draw) then
    
        if self.timeSinceGameStateChanged >= NS2Gamerules.kTimeToReadyRoom then
        
            // Force the commanders to logout before we spawn people
            // in the ready room
            self:LogoutCommanders()
    
            // Set all players to ready room team
            local function SetReadyRoomTeam(player)
                self:JoinTeam(player, kTeamReadyRoom)
            end
            Server.ForAllPlayers(SetReadyRoomTeam)

            // Spawn them there and reset teams
            self:ResetGame()

        end
        
    end
    
end

function NS2Gamerules:OnUpdate(timePassed)

    PROFILE("NS2Gamerules:OnUpdate")
    
    GetEffectManager():OnUpdate(timePassed)

    if Server then

        if self.justCreated then
        
            if not self.gameStarted then
                self:ResetGame()
            end
            
            self.justCreated = false

        end
        
        if self:GetMapLoaded() then
        
            self:CheckGameStart()
            self:CheckGameEnd()

            self:UpdatePregame(timePassed)
            self:UpdateToReadyRoom()
            
            self.timeSinceGameStateChanged = self.timeSinceGameStateChanged + timePassed
            
            self.worldTeam:Update(timePassed)
            self.team1:Update(timePassed)
            self.team2:Update(timePassed)
            self.spectatorTeam:Update(timePassed)
            
            // Send scores every so often
            self:UpdateScores()
            self:UpdatePings()
            self:UpdateInfestationEffects()
            
        end
    
    end
    
end

/**
 * Ends the current game
 */
function NS2Gamerules:EndGame(winningTeam)

    if self:GetGameState() == kGameState.Started then

        // Set losing team        
        local losingTeam = nil
        if(winningTeam == self.team1) then
            self:SetGameState(kGameState.Team2Won)
            losingTeam = self.team2            
        else
            self:SetGameState(kGameState.Team1Won)
            losingTeam = self.team1            
        end
        
        self.losingTeam = losingTeam

        // Play win/loss sounds
        winningTeam:PlayPrivateTeamSound(NS2Gamerules.kVictorySound)
        losingTeam:PlayPrivateTeamSound(NS2Gamerules.kDefeatSound)

        // Display win/loss message
        local winMsg = "Your team won the game!"
        winningTeam:AddTooltip(winMsg)

        local loseMsg = "Your team lost the game."
        losingTeam:AddTooltip(loseMsg)
        
        self.team1:ClearRespawnQueue()
        self.team2:ClearRespawnQueue()
        
        local gameLengthString = string.format("%.2f", Shared.GetTime() - self.gameStartTime)
        local urlString = "http://unknownworldsstats.appspot.com/statendgame?version=" .. ToString(Shared.GetBuildNumber()) .. "&winner=" .. ToString(winningTeam:GetTeamType()) .. "&length=" .. gameLengthString .. "&map=" .. Shared.GetMapName()
        Shared.GetWebpage(urlString, function (data) end)
        
    end

end

function NS2Gamerules:DrawGame()

    if self:GetGameState() == kGameState.Started then
    
        self:SetGameState(kGameState.Draw)
        
        // Play loss sounds for both teams
        self.team1:PlayPrivateTeamSound(NS2Gamerules.kDefeatSound)
        self.team2:PlayPrivateTeamSound(NS2Gamerules.kDefeatSound)
        
        // Display "draw" message
        local drawMessage = "The game was a draw!"
        self.team1:BroadcastMessage(drawMessage)
        self.team2:BroadcastMessage(drawMessage)
        
        self.team1:AddTooltip(drawMessage)
        self.team2:AddTooltip(drawMessage)

        self.team1:ClearRespawnQueue()
        self.team2:ClearRespawnQueue()  

    end

end

function NS2Gamerules:GetTeam(teamNum)

    local team = nil    
    if(teamNum == kTeamReadyRoom) then
        team = self.worldTeam
    elseif(teamNum == kTeam1Index) then
        team = self.team1
    elseif(teamNum == kTeam2Index) then
        team = self.team2
    elseif(teamNum == kSpectatorIndex) then
        team = self.spectatorTeam
    end
    return team
    
end

function NS2Gamerules:GetRandomTeamNumber()

    // Return lesser of two teams, or random one if they are the same
    local team1Players = self.team1:GetNumPlayers()
    local team2Players = self.team2:GetNumPlayers()
    
    if team1Players < team2Players then
        return self.team1:GetTeamNumber()
    elseif team2Players < team1Players then
        return self.team2:GetTeamNumber()
    end
    
    return ConditionalValue(math.random() < .5, kTeam1Index, kTeam2Index)
    
end

// Enforce balanced teams
function NS2Gamerules:GetCanJoinTeamNumber(teamNumber)

    local team1Players = self.team1:GetNumPlayers()
    local team2Players = self.team2:GetNumPlayers()
    
    if (team1Players > team2Players) and (teamNumber == self.team1:GetTeamNumber()) then
        return false
    elseif (team2Players > team1Players) and (teamNumber == self.team2:GetTeamNumber()) then
        return false
    end
    
    return true

end

/**
 * Returns two return codes: success and the player on the new team. This player could be a new
 * player (the default respawn type for that team) or it will be the original player if the team 
 * wasn't changed (false, original player returned). Pass force = true for second parameter
 * to make player change team no matter what and to respawn immediately.
 */
function NS2Gamerules:JoinTeam(player, newTeamNumber, force)

    local success = false
    
    // Join new team
    if(player and player:GetTeamNumber() ~= newTeamNumber or force) then
    
        local team = self:GetTeam(newTeamNumber)

        // Spawn immediately if going to ready room, game hasn't started, cheats on, or game started recently
        if (newTeamNumber == kTeamReadyRoom) or not self:GetGameStarted() or Shared.GetCheatsEnabled() or (Shared.GetTime() < (self.gameStartTime + NS2Gamerules.kFreeSpawnTime) or force ) then
        
            success, newPlayer = team:ReplaceRespawnPlayer(player, nil, nil)
        
        else
        
            // Destroy the existing player and create a spectator in their place.
            local mapName = ConditionalValue(team:isa("AlienTeam"), AlienSpectator.kMapName, Spectator.kMapName)
            newPlayer = player:Replace(mapName, newTeamNumber)
            
            // Queue up the spectator for respawn.
            team:PutPlayerInRespawnQueue(newPlayer, Shared.GetTime())
            
            success = true
            
        end
        
        newPlayer:TriggerEffects("join_team")
        
        return success, newPlayer
                       
    end
    
    // Return old player
    return success, player

end

function NS2Gamerules:GetGameStarted()
    return (self.gameState == kGameState.Started)
end

/* For test framework only. Prevents game from ending on its own also. */
function NS2Gamerules:SetGameStarted()
    self:SetGameState(kGameState.Started)
    self.preventGameEnd = true
end

function NS2Gamerules:SetPreventGameEnd(state)
    self.preventGameEnd = state
end

function NS2Gamerules:AddGlobalTooltip(tooltipMsg)
    self.worldTeam:AddTooltip(tooltipMsg)
    self.team1:AddTooltip(tooltipMsg)
    self.team2:AddTooltip(tooltipMsg)
    self.spectatorTeam:AddTooltip(tooltipMsg)
end

function NS2Gamerules:StartCountdown()

    self:ResetGame()
    
    self:SetGameState(kGameState.Countdown)

    local countdownTime = NS2Gamerules.kCountDownLength
    //if(Shared.GetDevMode() or Shared.GetCheatsEnabled()) then
    //    self.countdownTime = 0
    //end    
    self.countdownTime = countdownTime
    
    self.lastCountdownPlayed = nil    
   
end

function NS2Gamerules:CheckGameStart()

    if(self:GetGameState() == kGameState.NotStarted or self:GetGameState() == kGameState.PreGame) then
    
        // Start pre-game when both teams have players or when once side does if cheats are enabled
        local team1Players = self.team1:GetNumPlayers()
        local team2Players = self.team2:GetNumPlayers()
        
        if  (team1Players > 0 and team2Players > 0) or (Shared.GetCheatsEnabled() and (team1Players > 0 or team2Players > 0)) then
        
            if self:GetGameState() == kGameState.NotStarted then
            
                // Tell everyone the game will be starting shortly
                self:AddGlobalTooltip(string.format("The game will start in %d seconds...", NS2Gamerules.kPregameLength))
                self:SetGameState(kGameState.PreGame)

            end
            
        elseif self:GetGameState() == kGameState.PreGame then
            self:AddGlobalTooltip("Game start cancelled")
            self:SetGameState(kGameState.NotStarted)
        end
        
    end
    
end

function NS2Gamerules:CheckGameEnd()
    
    if(self:GetGameStarted() and self.timeGameEnded == nil and not Shared.GetCheatsEnabled() and not self.preventGameEnd) then
    
        if self.timeLastGameEndCheck == nil or (Shared.GetTime() > self.timeLastGameEndCheck + NS2Gamerules.kGameEndCheckInterval) then
        
            local team1Lost = self.team1:GetHasTeamLost()
            local team2Lost = self.team2:GetHasTeamLost()
            local team1Won = self.team1:GetHasTeamWon()
            local team2Won = self.team2:GetHasTeamWon()
            
            if((team1Lost and team2Lost) or (team1Won and team2Won)) then
                self:DrawGame()
            elseif(team1Lost or team2Won) then
                self:EndGame(self.team2)
            elseif(team2Lost or team1Won) then
                self:EndGame(self.team1)
            end
            
            self.timeLastGameEndCheck = Shared.GetTime()
            
        end
                
    end
    
end

function NS2Gamerules:UpdatePregame(timePassed)

    if self:GetGameState() == kGameState.PreGame then
    
        local preGameTime = NS2Gamerules.kPregameLength
        if(Shared.GetDevMode() or Shared.GetCheatsEnabled()) then
            preGameTime = 0
        end

        if self.timeSinceGameStateChanged > preGameTime then
            self:StartCountdown()
        end
        
    elseif self:GetGameState() == kGameState.Countdown then
    
        self.countdownTime = self.countdownTime - timePassed

        // Play count down sounds for last few seconds of count-down
        local countDownSeconds = math.ceil(self.countdownTime)
        if(self.lastCountdownPlayed ~= countDownSeconds and (countDownSeconds < 4)) then        

            self.worldTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
            self.team1:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
            self.team2:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
            self.spectatorTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)

            self.lastCountdownPlayed = countDownSeconds
            
        end
        
        if(self.countdownTime <= 0) then
        
            //if(not Shared.GetDevMode()) then
           
                self.team1:PlayPrivateTeamSound(ConditionalValue(self.team1:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                self.team2:PlayPrivateTeamSound(ConditionalValue(self.team2:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                
            //end

            self:SetGameState(kGameState.Started)
            
        end
        
    end
            
end

function NS2Gamerules:GetIsRelevant(player, entity)
        
    if player:GetIsCommander() then
        /*    
        // Send down all players to the commander so select all works
        if entity:isa("Player") and not entity:isa("Commander") and not entity:isa("Spectator") and (entity:GetTeamNumber() == player:GetTeamNumber()) then
            relevant = true
        // Send our hotgroups and also the command station we're in
        elseif(player:GetIsEntitySelected(entity) or player:GetIsEntityHotgrouped(entity) or player:GetIsEntityIdleWorker(entity)) then
            relevant = true
        end        
        */
    elseif player:isa("Spectator") then
        // Make sure target is sent to player
        local target = player:GetTarget()
        return target and target:GetId() == entity:GetId()
    end
    
    return false

end

function NS2Gamerules:GetLosingTeam()
    return self.losingTeam
end

function NS2Gamerules:GetAllTech()
    return self.allTech
end

function NS2Gamerules:SetAllTech(state)

    if state ~= self.allTech then
    
        self.allTech = state
        
        self.team1:GetTechTree():SetTechChanged()
        self.team2:GetTechTree():SetTechChanged()
        
    end
    
end

function NS2Gamerules:GetAutobuild()
    return self.autobuild
end

function NS2Gamerules:SetAutobuild(state)
    self.autobuild = state
end

function NS2Gamerules:SetOrderSelf(state)
    self.orderSelf = state
end

function NS2Gamerules:GetOrderSelf()
    return self.orderSelf
end

function NS2Gamerules:GetIsPlayerFollowingTeamNumber(player, teamNumber)

    local following = false
    
    if player:isa("Spectator") then
    
        local playerId = player:GetFollowingPlayerId()
        
        if playerId ~= Entity.invalidId then
        
            local followedPlayer = Shared.GetEntity(playerId)
            
            if followedPlayer and followedPlayer:GetTeamNumber() == teamNumber then
            
                following = true
                
            end
            
        end

    end
    
    return following

end

// Function for allowing teams to hear each other's voice chat
function NS2Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer)

    local canHear = false
    
    // Check if the listerner has the speaker muted.
    if listenerPlayer:GetClientMuted(speakerPlayer:GetClientIndex()) then
        return false
    end
    
    // If both players have the same team number, they can hear each other
    if(listenerPlayer:GetTeamNumber() == speakerPlayer:GetTeamNumber()) then
        canHear = true
    end
        
    // Or if cheats or dev mode is on, they can hear each other
    if(Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
        canHear = true
    end
    
    // If we're spectating a player, we can hear their team (but not in tournamentmode, once that's in)
    if self:GetIsPlayerFollowingTeamNumber(listenerPlayer, speakerPlayer:GetTeamNumber()) then
        canHear = true
    end
    
    return canHear
    
end

function NS2Gamerules:RespawnPlayer(player)

    local team = player:GetTeam()
    team:RespawnPlayer(player, nil, nil)
    
end

// Add SteamId of player to list of players that can't command again until next game
function NS2Gamerules:BanPlayerFromCommand(playerId)
    ASSERT(type(playerId) == "number")
    table.insertunique(self.bannedPlayers, playerId)
end

function NS2Gamerules:GetPlayerBannedFromCommand(playerId)
    ASSERT(type(playerId) == "number")
    return (table.find(self.bannedPlayers, playerId) ~= nil)
end

////////////////    
// End Server //
////////////////
end

////////////
// Shared //
////////////
function NS2Gamerules:SetupConsoleCommands()

    Gamerules.SetupConsoleCommands(self)    
    
    
end

Shared.LinkClassToMap("NS2Gamerules", NS2Gamerules.kMapName, {})
