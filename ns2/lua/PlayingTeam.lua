// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PlayingTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Team.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/TeamDeathMessageMixin.lua")

class 'PlayingTeam' (Team)

PlayingTeam.kObliterateVictoryTeamResourcesNeeded = 500
PlayingTeam.kUnitMaxLOSDistance = 30
PlayingTeam.kUnitMinLOSDistance = 1.5
PlayingTeam.kStructureMinLOSDistance = 10

PlayingTeam.kTooltipHelpInterval = 1

// How often to compute LOS visibility for entities (seconds)
PlayingTeam.kLOSUpdateInterval = 1
PlayingTeam.kTechTreeUpdateTime = 1

PlayingTeam.kBaseAlertInterval = 6
PlayingTeam.kRepeatAlertInterval = 12

// How often to update clear and update game effects
PlayingTeam.kUpdateGameEffectsInterval = .3

/**
 * spawnEntity is the name of the map entity that will be created by default
 * when a player is spawned.
 */
function PlayingTeam:Initialize(teamName, teamNumber)

    InitMixin(self, TeamDeathMessageMixin)
    
    Team.Initialize(self, teamName, teamNumber)

    self.respawnEntity = nil
    
    self:OnCreate()
        
    self.timeSinceLastLOSUpdate = Shared.GetTime()
    
    self.ejectCommVoteManager = VoteManager()
    self.ejectCommVoteManager:Initialize()

    local teamInfoEntity = Server.CreateEntity(TeamInfo.kMapName)
    self.teamInfoEntityId = teamInfoEntity:GetId()
    teamInfoEntity:SetWatchTeam(self)

end

function PlayingTeam:Uninitialize()

    if self.teamInfoEntityId and Shared.GetEntity(self.teamInfoEntityId) then
        Server.DestroyEntity(Shared.GetEntity(self.teamInfoEntityId))
        self.teamInfoEntityId = nil
    end
    
    Team.Uninitialize(self)

end

function PlayingTeam:AddPlayer(player)

    local added = Team.AddPlayer(self, player)
    
    player.teamResources = self.teamResources
    
    return added
    
end

function PlayingTeam:OnCreate()

    Team.OnCreate(self)
    
    self.structures = {}
      
end

function PlayingTeam:OnInit()

    Team.OnInit(self)
    
    self:InitTechTree()
    self.timeOfLastTechTreeUpdate = nil
    
    table.clear(self.structures)
    
    self.lastPlayedTeamAlertName = nil
    self.timeOfLastPlayedTeamAlert = nil
    self.alerts = {}
    
    self.teamResources = 0
    self.totalTeamResourcesCollected = 0
    self:AddTeamResources(kPlayingTeamInitialTeamRes)

    self.alertsEnabled = false
    self:SpawnInitialStructures(self.teamLocation)
    self.alertsEnabled = true
    
    self.ejectCommVoteManager:Reset()

end

function PlayingTeam:Reset()

    self:OnInit()
    
    Team.Reset(self)

end

function PlayingTeam:InitTechTree()
   
    self.techTree = TechTree()
    
    self.techTree:Initialize()
    
    self.techTree:SetTeamNumber(self:GetTeamNumber())
    
    // Menus
    self.techTree:AddMenu(kTechId.RootMenu)
    self.techTree:AddMenu(kTechId.BuildMenu)
    self.techTree:AddMenu(kTechId.AdvancedMenu)
    self.techTree:AddMenu(kTechId.AssistMenu)
    
    // Orders
    self.techTree:AddOrder(kTechId.Default)
    self.techTree:AddOrder(kTechId.Move)
    self.techTree:AddOrder(kTechId.Attack)
    self.techTree:AddOrder(kTechId.Build)
    self.techTree:AddOrder(kTechId.Construct)
    
    self.techTree:AddAction(kTechId.Cancel)
    
    self.techTree:AddOrder(kTechId.Weld)   
    
    self.techTree:AddAction(kTechId.Stop)
    
    self.techTree:AddOrder(kTechId.SetRally)
    self.techTree:AddOrder(kTechId.SetTarget)
    
end

// Returns marine or alien type
function PlayingTeam:GetTeamType()
    return self.teamType
end

function PlayingTeam:OnResearchComplete(structure, researchId)

    // Mark this tech node as researched
    local node = self.techTree:GetTechNode(researchId)
    if node == nil then
    
        Print("PlayingTeam:OnResearchComplete(): Couldn't find tech node %d", researchId)
        return false
        
    end
    
    node:SetResearched(true)
    
    // Loop through all entities on our team and tell them research was completed
    local teamEnts = GetEntitiesForTeam("ScriptActor", self:GetTeamNumber())
    for index, ent in ipairs(teamEnts) do
        ent:OnResearchComplete(structure, researchId)
    end
    
    // Tell tech tree to recompute availability next think
    self:GetTechTree():SetTechNodeChanged(node)
    
    if structure then
        self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertResearchComplete, kTechId.AlienAlertResearchComplete), structure)    
    end
    
    return true
    
end

// Returns sound name of last alert and time last alert played (for testing)
function PlayingTeam:GetLastAlert()
    return self.lastPlayedTeamAlertName, self.timeOfLastPlayedTeamAlert
end

// Play audio alert for all players, but don't trigger them too often. 
// This also allows neat tactics where players can time strikes to prevent the other team from instant notification of an alert, ala RTS.
// Returns true if the alert was played.
function PlayingTeam:TriggerAlert(techId, entity)

    ASSERT(entity ~= nil)
    ASSERT(entity:GetTechId() ~= kTechId.ReadyRoomPlayer, "Ready room entity TechId detected!")
    ASSERT(entity:GetTechId() ~= kTechId.None, "None entity TechId detected! Classname: " .. entity:GetClassName())
    ASSERT(techId ~= kTechId.None, "None TechId detected!")
    
    local triggeredAlert = false

    // Queue alert so commander can jump to it
    if techId ~= kTechId.None and techId ~= nil and entity ~= nil then
    
        if self.alertsEnabled then
        
            local location = Vector(entity:GetOrigin())
            table.insert(self.alerts, {techId, entity:GetId()})
        
            // Lookup sound name
            local soundName = LookupTechData(techId, kTechDataAlertSound, "")            
            if soundName ~= "" then
            
                local isRepeat = (self.lastPlayedTeamAlertName ~= nil and self.lastPlayedTeamAlertName == soundName)
            
                local timeElapsed = math.huge
                if self.timeOfLastPlayedTeamAlert ~= nil then
                    timeElapsed = Shared.GetTime() - self.timeOfLastPlayedTeamAlert
                end
                
                // Ignore source players for some alerts
                local ignoreSourcePlayer = ConditionalValue(LookupTechData(techId, kTechDataAlertOthersOnly, false), nil, entity)
                
                // If time elapsed > kBaseAlertInterval and not a repeat, play it OR
                // If time elapsed > kRepeatAlertInterval then play it no matter what
                if ((timeElapsed >= PlayingTeam.kBaseAlertInterval) and not isRepeat) or (timeElapsed >= PlayingTeam.kRepeatAlertInterval) then
                
                    // Play for commanders only or for the whole team
                    local commandersOnly = not LookupTechData(techId, kTechDataAlertTeam, false)
                    
                    self:PlayPrivateTeamSound(soundName, location, commandersOnly, ignoreSourcePlayer)
                    
                    self.lastPlayedTeamAlertName = soundName
                    self.timeOfLastPlayedTeamAlert = Shared.GetTime()
                    
                    triggeredAlert = true
                    
                end    
                
            end
            
            // Send minimap ping and alert notification to commanders
            for i, playerIndex in ipairs(self.playerIds) do

                local player = Shared.GetEntity(playerIndex)
                if(player ~= nil and player:isa("Commander")) then
                
                    player:TriggerAlert(techId, entity)                    
                    
                end
                
            end
            
        end
        
    else
        Print("PlayingTeam:TriggerAlert(%s, %s) called improperly.", ToString(techId), ToString(entity))
    end
    
    return triggeredAlert
    
end

function PlayingTeam:SetTeamResources(amount)

    if(amount > self.teamResources) then
    
        // Save towards victory condition
        self.totalTeamResourcesCollected = self.totalTeamResourcesCollected + (amount - self.teamResources)
        
    end
    
    self.teamResources = amount
    
    function PlayerSetTeamResources(player)
        player:SetTeamResources(self.teamResources)
    end
    
    self:ForEachPlayer(PlayerSetTeamResources)
    
end

function PlayingTeam:GetTeamResources()

    return self.teamResources
    
end

function PlayingTeam:AddTeamResources(amount)

    self:SetTeamResources(self.teamResources + amount)
    
end

function PlayingTeam:GetHasTeamLost()

    if(GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled()) then
    
        // Team can't respawn or last Command Station or Hive destroyed
        local activePlayers = self:GetHasActivePlayers()
        local abilityToRespawn = self:GetHasAbilityToRespawn()
        local numCommandStructures = self:GetNumCommandStructures()
        
        if  ( not activePlayers and not abilityToRespawn) or
            ( numCommandStructures == 0 ) or
            ( self:GetNumPlayers() == 0 ) then
            
            return true
            
        end
            
    end

    return false    

end

// Returns true if team has acheived alternate victory condition - hive releases bio-plague and marines teleport
// away and nuke station from orbit!
function PlayingTeam:GetHasTeamWon()

    if(GetGamerules():GetGameStarted() /*and not Shared.GetCheatsEnabled()*/) then
        
        // If team has collected enough resources to achieve alternate victory condition
        //if( self.totalTeamResourcesCollected >= PlayingTeam.kObliterateVictoryTeamResourcesNeeded) then
        //
        //    return true
        //    
        //end
        
    end
    
end

function PlayingTeam:SpawnInitialStructures(teamLocation)

    if(teamLocation ~= nil) then

        // Spawn tower at nearest unoccupied resource point    
        self:SpawnResourceTower(teamLocation)

        // Spawn hive/command station at team location
        self:SpawnCommandStructure(teamLocation)

    end
    
end

function PlayingTeam:GetHasAbilityToRespawn()
    return true
end

function PlayingTeam:SpawnResourceTower(teamLocation)

    local success = false
    if(teamLocation ~= nil) then
        local teamLocationOrigin = Vector(teamLocation:GetOrigin())

        local closestPoint = nil
        local closestPointDistance = 0
        
        for index, current in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do
        
            local pointOrigin = Vector(current:GetOrigin())
            local distance = (pointOrigin - teamLocationOrigin):GetLength()
            
            if((current:GetAttached() == nil) and ((closestPoint == nil) or (distance < closestPointDistance))) then
            
                closestPoint = current
                closestPointDistance = distance
                
            end
            
        end
            
        // Now spawn appropriate resource tower there
        if(closestPoint ~= nil) then
        
            local techId = ConditionalValue(self:GetIsAlienTeam(), kTechId.Harvester, kTechId.Extractor)
            success = closestPoint:SpawnResourceTowerForTeam(self, techId)
        
        end
        
    else
        Print("PlayingTeam:SpawnResourceTower() - Couldn't spawn resource tower for team, no team location.")
    end    
    
    return success
    
end

// Spawn hive or command station at nearest empty tech point to specified team location.
// Does nothing if can't find any.
function PlayingTeam:SpawnCommandStructure(teamLocation)
    
    // Look for nearest empty tech point to use instead
    local nearestTechPoint = GetNearestTechPoint(teamLocation:GetOrigin(), self:GetTeamType(), true)
    
    if(nearestTechPoint ~= nil) then
    
        local commandStructure = nearestTechPoint:SpawnCommandStructure(self:GetTeamNumber())
        if(commandStructure ~= nil) then
        
            commandStructure:SetConstructionComplete()
            return true
            
        end
        
    end    

    return false
    
end

function PlayingTeam:GetIsAlienTeam()
    return false
end

function PlayingTeam:GetIsMarineTeam()
    return false    
end

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 * Pass nil origin/angles to have spawn entity chosen.
 */
function PlayingTeam:ReplaceRespawnPlayer(player, origin, angles)

    local newPlayer = player:Replace(self.respawnEntity, self:GetTeamNumber(), false)
    
    self:RespawnPlayer(newPlayer, origin, angles)
    
    newPlayer:ClearGameEffects()
    
    return (newPlayer ~= nil), newPlayer
    
end

// Call with origin and angles, or pass nil to have them determined from team location and spawn points.
function PlayingTeam:RespawnPlayer(player, origin, angles)

    local success = false
    
    if(origin ~= nil and angles ~= nil) then
        success = Team.RespawnPlayer(self, player, origin, angles)
    else
    
        local teamLocation = self:GetTeamLocation()
        if (teamLocation ~= nil) then

            local spawnPoints = {}
            for index, spawnPoint in ipairs(Server.playerSpawnList) do
            
                if (teamLocation:GetOrigin() - spawnPoint:GetOrigin()):GetLength() < teamLocation:GetSpawnRadius() then
                    table.insert(spawnPoints, spawnPoint)
                end
                
            end
            
            if(table.maxn(spawnPoints) == 0) then
            
                Print("PlayingTeam:RespawnPlayer: Found no %s for team %s, spawning at ReadyRoomSpawn", TeamLocation.kMapName, ToString(self:GetTeamNumber()))
                spawnPoints = Server.readyRoomSpawnList

            end
            
            if(table.maxn(spawnPoints) > 0) then
        
                // Randomly choose one of the spawn points that's unobstructed to spawn the player.                
                local spawnPoint = GetRandomClearSpawnPoint(player, spawnPoints)
                
                if (spawnPoint ~= nil) then
                    success = Team.RespawnPlayer(self, player, spawnPoint:GetOrigin(), spawnPoint:GetAngles())
                else                
                    Print("PlayingTeam:RespawnPlayer: Found no free spawn points found.\n")
                end
                
            else            
                Print("PlayingTeam:RespawnPlayer: No spawn points found.\n")
            end
        
        else
            Print("PlayingTeam:RespawnPlayer(): No team location.")
        end
        
    end

    player:OnIdle()
    
    return success

end

function PlayingTeam:StructureCreated(entity)

    if(entity:isa("Structure")) then
        table.insertunique(self.structures, entity:GetId())
    end
    
end

function PlayingTeam:StructureDestroyed(entity)

    if(entity:isa("Structure")) then
        table.removevalue(self.structures, entity:GetId())
    end

end

function PlayingTeam:TechAdded(entity)

    // Tell tech tree to recompute availability next think
    if(self.techTree ~= nil) then
        self.techTree:SetTechChanged()
    end
end

function PlayingTeam:TechRemoved(entity)

    // Tell tech tree to recompute availability next think
    if(self.techTree ~= nil) then
        self.techTree:SetTechChanged()
    end
    
end

function PlayingTeam:ComputeLOS()
    PROFILE("PlayingTeam:ComputeLOS")

    local maxDistance = PlayingTeam.kStructureMinLOSDistance
    
    // Get all non-commander players on our team
    local teamBuilderName = ConditionalValue(self:GetIsAlienTeam(), "Drifter", "MAC")
    
    function IsFriendlyLOSGivingUnit(entity)    
        if(entity:GetTeamNumber() == self:GetTeamNumber()) then        
            // Scan entities are structures
            if( (entity:isa("Player") and not entity:GetIsCommander()) or 
                (entity:isa(teamBuilderName)) or 
                (entity:isa("Structure") and not entity:isa("PowerPoint") and not entity:isa("Door") and not entity:isa("Egg")) or 
                (entity:isa("ARC")) ) then            
                return true                
            end            
        end        
        return false        
    end
    
    // Get list of entities that can see (players and AI builder units). Do it this
    // way to avoid unnecessarily iterating over all the entities in the world.
    local seeingUnits = {}    
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    local enemyEnts = GetEntitiesForTeam("ScriptActor", enemyTeamNumber)
    for index, unit in ipairs(enemyEnts) do
      unit.sighted = false
      
      // For each visible entity on other team
      if not unit:GetIsVisible() then
            unit:SetExcludeRelevancyMask( 0 )      
      end
                  
      local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom) 
      if unit:GetTeamNumber() == 1 then
        mask = bit.bor(mask, kRelevantToTeam1Commander)
      elseif unit:GetTeamNumber() == 2 then
        mask = bit.bor(mask, kRelevantToTeam2Commander)
      end
      
      unit:SetExcludeRelevancyMask( mask )
    end
    
    local allScriptActors = GetEntitiesForTeam("ScriptActor", self:GetTeamNumber())
    for index, entity in ipairs(allScriptActors) do
    
        if IsFriendlyLOSGivingUnit(entity) then
            table.insert(seeingUnits, entity)
        end        
        
        // For each visible entity on other team
        if not entity:GetIsVisible() then
            entity:SetExcludeRelevancyMask( 0 )      
        end
        
    end
    
    // See if friendly buildings are near entity, with direct LOS to it (ala conventional RTS).
    // Check in 2D to detect hives above.
    for seeingIndex, seeingUnit in ipairs(seeingUnits) do
       if (seeingUnit:isa("Structure")) then
            maxDistance = PlayingTeam.kStructureMinLOSDistance
       elseif (seeingUnit:isa("Scan")) then
            maxDistance = Scan.kScanDistance
       else       
            maxDistance = PlayingTeam.kUnitMaxLOSDistance
       end
      local entities = {}    
      Shared.GetEntitiesWithinRadius(seeingUnit:GetOrigin(), maxDistance, entities)
      for entIndex, entityId in ipairs(entities) do      
        local entity = Shared.GetEntity(entityId)         
        if (entity ~= nil and entity:GetTeamNumber() == enemyTeamNumber) then            
            entity.sighted = false 
            local distance = seeingUnit:GetDistanceXZ(entity) 
            
            local isHidden = false
            local hasBeenScanned = false
                        
            if (HasMixin(entity, "Cloakable") and entity:GetIsCloaked()) or (HasMixin(entity, "Camouflage") and entity:GetIsCamouflaged()) then
               isHidden = true
            end
                        
            // Structures give LOS to other structures and infestation within range, esp. so command stations can see infestation
            if seeingUnit:isa("Structure") and seeingUnit:GetIsActive() and (entity:isa("Structure") or entity:isa("Infestation"))then                
                // Check to make sure view isn't blocked by the level or big visible entities (add in a little height in case infestation is on ground)
                local trace = Shared.TraceRay(seeingUnit:GetModelOrigin(), entity:GetModelOrigin() + Vector(0, 1, 0), PhysicsMask.AllButPCs, EntityFilterTwo(seeingUnit, entity))                
                if trace.fraction == 1 then                     
                    entity.sighted = true                        
                end
            elseif (distance <= PlayingTeam.kUnitMinLOSDistance) then                                     
                entity.sighted = true
            elseif seeingUnit:isa("Scan")then                     
            
                entity.sighted = true
                
                // Allow entities to respond
                if entity.OnScan then
                    entity:OnScan()
                end
                
                hasBeenScanned = true
                
            elseif(not seeingUnit:isa("Structure") ) then                                      
                if( seeingUnit:GetCanSeeEntity(entity) ) then
                    entity.sighted = true                        
                end
            end

            // Cloaked/camoued units aren't sighted unless they were scanned
            if (isHidden and not hasBeenScanned) then
                entity.sighted = false
            end  

            local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)        
            if entity.sighted then
                mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
            else
                if entity:GetTeamNumber() == 1 then
                    mask = bit.bor(mask, kRelevantToTeam1Commander)
                elseif entity:GetTeamNumber() == 2 then
                    mask = bit.bor(mask, kRelevantToTeam2Commander)
                end
            end            
            entity:SetExcludeRelevancyMask( mask )
        end
      end
    end
end

function PlayingTeam:UpdateLOS(timePassed)
    PROFILE("PlayingTeam:UpdateLOS")
    // Skip LOS check when debugging for perf. reasons
    if(/*not GetIsDebugging() and*/ (self.timeSinceLastLOSUpdate > PlayingTeam.kLOSUpdateInterval)) then
    
        self:ComputeLOS()
        self.timeSinceLastLOSUpdate = 0
    
    else
 
        self.timeSinceLastLOSUpdate = self.timeSinceLastLOSUpdate + timePassed
        
    end
    
end

function PlayingTeam:Update(timePassed)

    PROFILE("PlayingTeam:Update")

    // Update structure research/energy
    for index, structureId in ipairs(self.structures) do    
          local structure = Shared.GetEntity(structureId)
          if (structure ~= nil) then            
            structure:UpdateStructure(timePassed)                
          end            
    end

    // Give new players starting resources. Mark players as "having played" the game (so they don't get starting res if 
    // they join a team again, etc.)    
    local gamerules = GetGamerules()
    for index, player in ipairs(self:GetPlayers()) do
    
        local success, played = gamerules:GetUserPlayedInGame(player)
        if success and not played then
            player:SetResources( kPlayerInitialIndivRes )
        end
        
        if gamerules:GetGameStarted() then
            gamerules:SetUserPlayedInGame(player)
        end
        
    end
    
    self:UpdateHelp()
    
    // Update line of sight for other team
    self:UpdateLOS(timePassed)

    // Compute tech tree availability only so often because it's very slooow
    if self.techTree ~= nil and (self.timeOfLastTechTreeUpdate == nil or Shared.GetTime() > self.timeOfLastTechTreeUpdate + PlayingTeam.kTechTreeUpdateTime) then
    
        self.techTree:ComputeAvailability()

        // Send tech tree base line to players that just switched teams or joined the game        
        local players = self:GetPlayers()
        
        for index, player in ipairs(players) do
        
            if player:GetSendTechTreeBase() then
            
                self.techTree:SendTechTreeBase(player)
                
                player:ClearSendTechTreeBase()
                
            end
            
        end
        
        // Send research, availability, etc. tech node updates to team players
        self.techTree:SendTechTreeUpdates(players)
        
        self.timeOfLastTechTreeUpdate = Shared.GetTime()
        
    end
    
    self:UpdateGameEffects(timePassed)
    
    self:UpdateVoteToEject()
    
end

function PlayingTeam:GetTechTree()
    return self.techTree
end

function PlayingTeam:TriggerSayingAction(player, sayingActionTechId)
end

function PlayingTeam:ProcessGeneralHelp(player)

    if((GetGamerules():GetGameState() == kGameState.NotStarted) and player:AddTooltipOnce("GAME_WONT_START_TOOLTIP")) then
        return true
    elseif(GetGamerules():GetGameStarted() and player:AddTooltipOnce("GAME_STARTED_TOOLTIP")) then
        return true
    elseif(player:isa("AlienCommander") and table.count(player:GetSelection()) > 1 and player:AddTooltipOnce("CYCLE_SUB_SELECTION_TOOLTIP")) then
        return true
    elseif(player:isa("Commander") and player:AddTooltipOnce("CREATE_HOTGROUP_TOOLTIP")) then
        return true
    elseif(player:isa("Commander") and player:AddTooltipOnce("SCROLL_TOOLTIP")) then
        return true
    elseif(player:isa("Commander") and player:AddTooltipOnce("LOGOUT_TOOLTIP")) then
        return true
    elseif(not player:isa("Commander") and GetGamerules():GetGameStarted() and player:AddTooltipOnce("SAYINGS_TOOLTIP")) then
        return true
    end
        
    return false
    
end

// Look for nearby entities that generate help messages
function PlayingTeam:ProcessEntityHelp(player)
    
    // Look for entities to give help about
    local entities = GetEntitiesWithinRangeInView("ScriptActor", 4, player)
    
    local message = nil
    
    for index, entity in ipairs(entities) do
    
        local enemy = GetEnemyTeamNumber(player:GetTeamNumber()) == entity:GetTeamNumber()
        
        if entity:isa("PowerPoint") and entity:ProcessEntityHelp(player) then
            return true
        elseif not enemy and entity:isa("Structure") and not entity:GetIsBuilt() and player:isa("Marine") then
            message = "HELP_BUILD_TOOLTIP"
        elseif entity:isa("Door") then

            if entity:GetState() == Door.kState.Locked then
            
                if player:isa("Marine") then                    
                    message = "DOOR_LOCKED_MARINE_TOOLTIP"
                else
                    message = "DOOR_LOCKED_GENERAL_TOOLTIP"
                end
                
            else
                message = "DOOR_UNLOCKED_TOOLTIP"
            end
            
        elseif entity:isa("Armory") and entity:GetIsBuilt() then             
            message = "BUILT_ARMORY_TOOLTIP"
        elseif entity:isa("Hive") then        
            if enemy then
                message = "ENEMY_HIVE_TOOLTIP"                
            elseif not enemy and entity:GetIsOccupied() then
                message = "FRIENDLY_OCCUPIED_HIVE_TOOLTIP"
            elseif not enemy and not entity:GetIsOccupied() then
                message = "FRIENDLY_UNOCCUPIED_HIVE_TOOLTIP"
            end            
        elseif entity:isa("CommandStation") then

            local commander = entity:GetCommander()                               
            if not enemy and commander then
               message = string.format("%s %s", "INSIDE_COMMAND_STATION_TOOLTIP" , commander:GetName())
            elseif not enemy and not entity:GetIsOccupied() then
                message = "FRIENDLY_UNOCCUPIED_COMMAND_STATION_TOOLTIP"
            end
            
        elseif entity:isa("InfantryPortal") then
        
            if enemy then
                message = "ENEMY_IP_TOOLTIP"
            elseif not enemy then
                message = "FRIENDLY_IP_TOOLTIP"
            end
            
        elseif entity:isa("Extractor") then
            if enemy then
                message = "ENEMY_EXTRACTOR_TOOLTIP"
            elseif not enemy then
                message = "FRIENDLY_EXTRACTOR_TOOLTIP"
            end
        elseif entity:isa("Harvester") then
            if enemy then
                message = "ENEMY_HARVESTER_TOOLTIP"
            elseif not enemy then
                message = "FRIENDLY_HARVESTER_TOOLTIP"
            end
        elseif entity:isa("Egg") then
            if enemy then
                message = "ENEMY_EGG_TOOLTIP"
            elseif not enemy then
                message = "FRIENDLY_EGG_TOOLTIP"
            end
        end
        
        if (message ~= nil) then
            if (player:AddLocalizedTooltip(message, true)) then
              return true
            end            
            message = nil
        end
    end
    
    return false
    
end

function PlayingTeam:UpdateHelp()

    if(self.timeOfLastHelpCheck == nil or (Shared.GetTime() > self.timeOfLastHelpCheck + PlayingTeam.kTooltipHelpInterval)) then
    
        function ProcessPlayerHelp(player)
        
            // Only do this before the game has started
            if((GetGamerules():GetGameState() == kGameState.NotStarted) and player:AddTooltipOnce("GAME_NOT_STARTED_TOOLTIP")) then
                return true
            // Only process other help after game has started
            elseif(GetGamerules():GetGameStarted()) then
            
                if player:AddTooltipOnce("GAME_STARTED_TOOLTIP") then
                    return true
                else
        
                    if(not self:ProcessGeneralHelp(player)) then
                    
                        if not self:ProcessEntityHelp(player) then
                        
                            player:UpdateHelp()
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end

        self:ForEachPlayer(ProcessPlayerHelp)
    
        self.timeOfLastHelpCheck = Shared.GetTime()
        
    end 
    
end

// Update from alien team instead of in alien buildings think because we need to clear
// game effect flag too.
function PlayingTeam:UpdateGameEffects(timePassed)

    local time = Shared.GetTime()
    
    if not self.timeSinceLastGameEffectUpdate then
        self.timeSinceLastGameEffectUpdate = timePassed
    else
        self.timeSinceLastGameEffectUpdate = self.timeSinceLastGameEffectUpdate + timePassed
    end
    
    if self.timeSinceLastGameEffectUpdate >= PlayingTeam.kUpdateGameEffectsInterval then

        // Friendly entities that alien structures can affect
        local teamEntities = GetEntitiesForTeam("LiveScriptActor", self:GetTeamNumber())
        local enemyPlayers = GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber()))
        
        self:UpdateTeamSpecificGameEffects(teamEntities, enemyPlayers)       
        
        self.timeSinceLastGameEffectUpdate = self.timeSinceLastGameEffectUpdate - PlayingTeam.kUpdateGameEffectsInterval        
        
    end    

end

function PlayingTeam:UpdateTeamSpecificGameEffects(teamEntities, enemyPlayers)

    local catchFireEntities = {}
    
    for index, entity in ipairs(teamEntities) do
        if HasMixin(entity, "Fire") then
            entity:UpdateFire(PlayingTeam.kUpdateGameEffectsInterval)
        end
    end
    
    for index, catchFireEntity in ipairs(catchFireEntities) do
        catchFireEntity:SetGameEffectMask(kGameEffect.OnFire, true)
    end
    
end

function PlayingTeam:VoteToEjectCommander(votingPlayer, targetCommander)

    local votingPlayerSteamId = tonumber(Server.GetOwner(votingPlayer):GetUserId())
    local targetSteamId = tonumber(Server.GetOwner(targetCommander):GetUserId())
    
    if self.ejectCommVoteManager:PlayerVotesFor(votingPlayerSteamId, targetSteamId, Shared.GetTime()) then
        PrintToLog("%s cast vote to eject commander %s", votingPlayer:GetName(), targetCommander:GetName())
    end
    
end

function PlayingTeam:UpdateVoteToEject()

    // Update with latest team size
    self.ejectCommVoteManager:SetNumPlayers(self:GetNumPlayers())

    // Eject commander if enough votes cast
    if self.ejectCommVoteManager:GetVotePassed() then    
        
        local targetCommander = GetPlayerFromUserId( self.ejectCommVoteManager:GetTarget() )
        
        if targetCommander and targetCommander.Eject then
            targetCommander:Eject()
        end        
        
        self.ejectCommVoteManager:Reset()
        
    elseif self.ejectCommVoteManager:GetVoteElapsed(Shared.GetTime()) then
    
        self.ejectCommVoteManager:Reset()
            
    end
    
end


