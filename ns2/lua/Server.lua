// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Set the name of the VM for debugging
decoda_name = "Server"

Script.Load("lua/Shared.lua")
Script.Load("lua/MapEntityLoader.lua")
Script.Load("lua/Button.lua")
Script.Load("lua/TechData.lua")

Script.Load("lua/EggSpawn.lua")
Script.Load("lua/MarineTeam.lua")
Script.Load("lua/AlienTeam.lua")
Script.Load("lua/TeamJoin.lua")
Script.Load("lua/Bot.lua")
Script.Load("lua/VoteManager.lua")

Script.Load("lua/ConsoleCommands_Server.lua")
Script.Load("lua/NetworkMessages_Server.lua")

Script.Load("lua/dkjson.lua")

Script.Load("lua/DbgTracer_Server.lua")
Script.Load("lua/TargetCache.lua")
Script.Load("lua/InfestationMap.lua")
 
Server.dbgTracer = DbgTracer()
Server.dbgTracer:Init()

Server.infestationMap = InfestationMap():Init()

Server.readyRoomSpawnList = {}
Server.playerSpawnList = {}
Server.eggSpawnList = {}
Server.sortedEggSpawnList = {}
Server.playerBanList = {}

// map name, group name and values keys for all map entities loaded to
// be created on game reset
Server.mapLoadLiveEntityValues = {}

// Game entity indices created from mapLoadLiveEntityValues. They are all deleted
// on and rebuilt on map reset.
Server.mapLiveEntities = {}

// Map entities are stored here in order of their priority so they are loaded
// in the correct order (Structure assumes that Gamerules exists upon loading for example).
Server.mapPostLoadEntities = {}

/**
 * Map entities with a higher priority are loaded first.
 */
local kMapEntityLoadPriorities = { }
kMapEntityLoadPriorities[NS2Gamerules.kMapName] = 1
local function GetMapEntityLoadPriority(mapName)

    local priority = 0
    
    if kMapEntityLoadPriorities[mapName] then
        priority = kMapEntityLoadPriorities[mapName]
    end
    
    return priority

end

local function LoadServerMapEntity(mapName, groupName, values)

    // Skip the classes that are not true entities and are handled separately
    // on the client.
    if ( mapName ~= "prop_static"
        and mapName ~= "light_point"
        and mapName ~= "light_spot"
        and mapName ~= "light_ambient"
        and mapName ~= "color_grading"
        and mapName ~= "cinematic"
        and mapName ~= "skybox"
        and mapName ~= "navigation_waypoint"
        and mapName ~= "pathing_settings"
        // Temporarily remove IPs placed in levels
        and mapName ~= InfantryPortal.kMapName
        and mapName ~= ReadyRoomSpawn.kMapName
        and mapName ~= PlayerSpawn.kMapName
        and mapName ~= AmbientSound.kMapName
        and mapName ~= Reverb.kMapName
        and mapName ~= Particles.kMapName) then

        local entity = Server.CreateEntity(mapName)
        if entity then

            entity:SetMapEntity()
            LoadEntityFromValues(entity, values)

            // Map Entities with LiveMixin can be destroyed during the game.
            if HasMixin(entity, "Live") then

                // Insert into table so we can re-create them all on map post load (and game reset)
                table.insert(Server.mapLoadLiveEntityValues, {mapName, groupName, values})

                // Delete it because we're going to recreate it on map reset
                table.insert(Server.mapLiveEntities, entity:GetId())

            end
            
            // $AS FIXME: We are special caasing techPoints for pathing right now :/ 
            if (mapName == "tech_point") then
              local coords = values.angles:GetCoords(values.origin)
              Pathing.CreatePathingObject(entity:GetModelName(), coords)
            end

        end

    end

    if (mapName == "prop_static") then

        local coords = values.angles:GetCoords(values.origin)

        coords.xAxis = coords.xAxis * values.scale.x
        coords.yAxis = coords.yAxis * values.scale.y
        coords.zAxis = coords.zAxis * values.scale.z

        // Create the physical representation of the prop.
        local physicsModel = Shared.CreatePhysicsModel(values.model, false, coords, CoordsArray(), nil)
        physicsModel:SetPhysicsType(CollisionObject.Static)

        // Handle commander mode properties
        local renderModelCommAlpha = GetAndCheckValue(values.commAlpha, 0, 1, "commAlpha", 1, true)

        // Make it not block selection and structure placement (GetCommanderPickTarget)
        if renderModelCommAlpha < 1 then
            physicsModel:SetGroup(PhysicsGroup.CommanderPropsGroup)
        end
        
        // Only create Pathing objects if we are told too
        /*if (values.pathInclude ~= nil) then
          if (values.pathInclude == true)then
            Pathing.CreatePathingObject(values.model, coords)
          end
        end*/
        
        Pathing.CreatePathingObject(values.model, coords)

    elseif (mapName == "navigation_waypoint") then
       
        if (groupName == "") then
            groupName = kDefaultWaypointGroup
        end
        
        // $AS - HACK: REMOVE ME!!! This is horrible not going to lie
        // right now mappers have to place down waypoints and sometimes
        // get put into the floor :/ which prevents proper connections
        // from being made; until we make uber pathing we move the ground
        // nodes up a little to make sure they are not in the ground thus
        // preventing proper pathing
        if (groupName == kDefaultWaypointGroup) then        
            values.origin.y = values.origin.y + 0.2
        end

        Server.AddNavigationWaypoint( groupName, values.origin )

    elseif (mapName == ReadyRoomSpawn.kMapName) then

        local entity = ReadyRoomSpawn()
        entity:OnCreate()
        LoadEntityFromValues(entity, values)
        table.insert(Server.readyRoomSpawnList, entity)

    elseif (mapName == EggSpawn.kMapName) then

        local entity = EggSpawn()
        entity:OnCreate()
        LoadEntityFromValues(entity, values)
        table.insert(Server.eggSpawnList, entity)

    elseif (mapName == AmbientSound.kMapName) then

        // Make sure sound index is precached but only create ambient sound object on client
        Shared.PrecacheSound(values.eventName)

    elseif (mapName == Particles.kMapName) then

        Shared.PrecacheCinematic(values.cinematicName)
    elseif (mapName == "pathing_settings") then
        ParsePathingSettings(values)
    else
    
        // Allow the MapEntityLoader to load it if all else fails.
        LoadMapEntity(mapName, groupName, values)

    end

end

/**
 * Called as the map is being loaded to create the entities.
 */
function OnMapLoadEntity(mapName, groupName, values)

    local priority = GetMapEntityLoadPriority(mapName)
    if Server.mapPostLoadEntities[priority] == nil then
        Server.mapPostLoadEntities[priority] = { }
    end
    table.insert(Server.mapPostLoadEntities[priority], { MapName = mapName, GroupName = groupName, Values = values })

end

function OnMapPreLoad()

    Shared.PreLoadSetGroupNeverVisible(kCollisionGeometryGroupName)
    Shared.PreLoadSetGroupPhysicsId(kNonCollisionGeometryGroupName, 0)

    // Any geometry in kCommanderInvisibleGroupName shouldn't interfere with selection or other commander actions
    Shared.PreLoadSetGroupPhysicsId(kCommanderInvisibleGroupName, PhysicsGroup.CommanderPropsGroup)

    // Don't have bullets collide with collision geometry
    Shared.PreLoadSetGroupPhysicsId(kCollisionGeometryGroupName, PhysicsGroup.CollisionGeometryGroup)

    // Clear spawn points
    Server.readyRoomSpawnList = {}
    Server.playerSpawnList = {}
    Server.sortedEggSpawnList = {}
    Server.eggSpawnList = {}

    Server.locationList = {}

    Server.mapLoadLiveEntityValues = {}
    Server.mapLiveEntities = {}

end

function DestroyLiveMapEntities()

    // Delete any map entities that have been created
    for index, mapEntId in ipairs(Server.mapLiveEntities) do

        local ent = Shared.GetEntity(mapEntId)
        if ent then
            DestroyEntity(ent)
        end

    end

end

function CreateLiveMapEntities()

    // Create new Live map entities
    for index, triple in ipairs(Server.mapLoadLiveEntityValues) do

        // {mapName, groupName, keyvalues}
        local entity = Server.CreateEntity(triple[1])
        LoadEntityFromValues(entity, triple[3], true)

        // Store so we can track it during the game and delete it on game reset if not dead yet
        table.insert(Server.mapLiveEntities, entity:GetId())

    end

end

// Use minimap extents object to create grid of waypoints throughout map
function GenerateWaypoints()

    local ents = Shared.GetEntitiesWithClassname("MinimapExtents")

    if ents:GetSize() == 1 then

        local minimapExtents = ents:GetEntityAtIndex(0)

        local kWaypointGridSizeXZ = 2
        local kWaypointGridSizeY = 1

        local worldOrigin = Vector(minimapExtents:GetOrigin())
        local worldExtents = Vector(minimapExtents:GetExtents())

        local origin = Vector()
        local numWaypoints = 0

        local y = worldOrigin.y - worldExtents.y
        while y < (worldOrigin.y + worldExtents.y) do

            origin.y = y
            local z = worldOrigin.z - worldExtents.z
            while z < (worldOrigin.z + worldExtents.z) do

                origin.z = z
                local x = worldOrigin.x - worldExtents.x
                while x < (worldOrigin.x + worldExtents.x) do

                    origin.x = x

                    // TODO: If they're close to the ground, they are ground waypoints
                    local groupName = kAirWaypointsGroup

                    Server.AddNavigationWaypoint( groupName, origin )

                    numWaypoints = numWaypoints + 1

                    x = x + kWaypointGridSizeXZ

                end

                z = z + kWaypointGridSizeXZ

            end

            y = y + kWaypointGridSizeY

        end

        // Return dimensions of waypoint grid
        local dimensions = {
                math.floor((worldExtents.x * 2)/kWaypointGridSizeXZ),
                math.floor((worldExtents.y * 2)/kWaypointGridSizeY),
                math.floor((worldExtents.z * 2)/kWaypointGridSizeXZ)
                }

        Print("Auto-generated %s waypoints (%d, %d, %d)", ToString(numWaypoints), dimensions[1], dimensions[2], dimensions[3])

        return dimensions

    elseif ents:GetSize() > 1 then
        Print("Server:GenerateWaypoints() - Error, multiple minimap extents objects found.")
    else
        Print("Server:GenerateWaypoints() - Couldn't find minimap_extents entity, no waypoints generated.")
    end

end

function SortSpawnEntities()

    for index = 1, table.count(Server.eggSpawnList) do
    
        local spawn = Server.eggSpawnList[index]
        ASSERT(spawn ~= nil)
        
        local locationName = GetLocationForPoint(spawn:GetOrigin())
        ASSERT(type(locationName) == "string")

        // Insert new entity with location name        
        if Server.sortedEggSpawnList[locationName] == nil then
            Server.sortedEggSpawnList[locationName] = {}
        end
        
        table.insert( Server.sortedEggSpawnList[locationName], spawn)
        
    end
    
    // Kill egg spawn list
    Server.eggSpawnList = nil
    
end

/**
 * Callback handler for when the map is finished loading.
 */
function OnMapPostLoad()

    // Higher priority entities are loaded first.
    local highestPriority = 0
    for k, v in pairs(kMapEntityLoadPriorities) do
        if v > highestPriority then highestPriority = v end
    end
    for i = highestPriority, 0, -1 do
        if Server.mapPostLoadEntities[i] then
            for k, entityData in ipairs(Server.mapPostLoadEntities[i]) do
                LoadServerMapEntity(entityData.MapName, entityData.GroupName, entityData.Values)
            end
        end
    end
    Server.mapPostLoadEntities = { }
    
    // Sort spawn entities by location
    SortSpawnEntities()
    
    // Build the data for pathing around the map.
    /*local dimensions = GenerateWaypoints()
    if dimensions then
        //Print("Server.BuildNavigation(%d, %d, %d)", dimensions[1], dimensions[2], dimensions[3])
        Server.BuildNavigation(dimensions[1], dimensions[2], dimensions[3])
    end*/

    InitializePathing()
    Server.BuildNavigation()

    GetGamerules():OnMapPostLoad()

end

-- Begin server webAPI by Marc (marc@unitedworlds.co.uk)
-- TODO:    add to ServerDisconnect a reason message after main menu is recoded in luaGUI
--            add server local or remote storage of pernament banlist support

function OnConnectCheckBan(player)
    local steamid = tonumber(player:GetUserId())
    Shared.Message(string.format('Client Authed. Steam ID: %s',steamid))
    for i,row in pairs(Server.playerBanList) do
        Shared.Message(string.format('%s : %s : %s',row.name,steamid,row.duration))
        if(steamid == tonumber(row.steamid)) then
            if row.duration == 0 then
                Server.DisconnectClient(player)
                Shared.Message(string.format('Kicked %s because they are pernamently banned form the server.',row.name))
            else
                if math.floor(Shared.GetTime()) > ( tonumber(row.timeOfBan) + (tonumber(row.duration) * 60)) then
                    Shared.Message(string.format('Temporary ban expired: Unbanning %s',row.name))
                    table.remove(Server.playerBanList,i)
                else
                    Server.DisconnectClient(player)
                    Shared.Message(string.format('Kicked %s because they have a temporary ban form the server.',row.name))
                end
            end
            break
        end
    end
end

function webServerUpTime(datatype)
    local unit = {
       year        = 29030400,
       month    = 2419200,
       week        = 604800,
       day        = 86400,
       hour        = 3600,
       minute    = 60
    }
    local totalSeconds = math.floor(Shared.GetTime()) or 0
    if(datatype == 'json') then
        return totalSeconds
    else
        local days = math.floor(totalSeconds / unit.day) or 0
        local hours = math.floor((totalSeconds / unit.hour) - (24 * days)) or 0
        local mins = math.floor((totalSeconds / unit.minute) - (60 * (hours + (24 * days)))) or 0
        local seconds = ((totalSeconds / 60) * 60) - (60 * (mins + (60 * hours)))
        return days .. ' day(s), ' .. hours .. ' hour(s), ' .. mins .. ' minute(s), ' .. seconds .. ' second(s) '
    end
end

function webIsCommander(player, datatype)
    local data = ''
    if (player:GetIsCommander()) then
        if (datatype == 'json') then data = 1 else data = '(Commanding)' end
    else
        if (datatype == 'json') then data = 0 else data = '' end
    end
    return data
end

function webGetTeam(player, datatype)
    local team = { 'Joining Server','Ready Room','Marine','Alien','Spectator' }
    local teamid = tonumber(player:GetTeamNumber()) or -1
    if (datatype == 'json') then
        return teamid
    else
        teamid = teamid + 2
        return team[teamid]
    end
end

function webFindPlayer(steamid)
    for list, victim in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        if Server.GetOwner(victim):GetUserId() == tonumber(steamid) then
            return victim
        end
    end
    return false
end

function webKickPlayer(steamid, reason)
    if not steamid == nil or 0 then
        local kickthis = webFindPlayer(steamid) or false
        if kickthis ~= false then
            local kickent = Server.GetOwner(kickthis)
            local kickname = ''
            if kickent:GetIsVirtual() == false then
                kickname = kickthis:GetName()
                Server.DisconnectClient(kickent)
                Shared.Message(string.format('Server: %s was kicked from the server', kickname))
            else
                OnConsoleRemoveBots()
                kickname = 'bot'
            end
            return 'Kicking ' .. kickname
        end
    end
    return 'Cant kick player'
end

function webBanPlayer(steamid,duration)
    if not steamid == nil or 0 then
        local banthis = webFindPlayer(steamid) or false
        if banthis ~= false then
            local banent = Server.GetOwner(banthis)
            local banname = ''
            if banent:GetIsVirtual() == false then
                banname = banthis:GetName()
                duration = tonumber(duration) or 0
                local playerData = {
                    name = banname,
                    steamid = steamid,
                    duration = duration,
                    timeOfBan = math.floor(tonumber(Shared.GetTime()))
                }
                local doBan = true
                for _, v in pairs(Server.playerBanList) do
                    if v.steamid == steamid then
                        doBan = false
                        break
                    end
                end
                if doBan == true then
                    table.insert(Server.playerBanList,playerData)
                    return banname .. ' banned from server'
                end
                return 'Player already banned'
            end
        end
    end
    return 'Cant ban player'
end

function webUnbanPlayer(steamid)
    if not steamid == nil or 0 then
        for i,player in pairs(Server.playerBanList) do
            if tonumber(player.steamid) == tonumber(steamid) then
                table.remove(Server.playerBanList,i)
                Shared.Message(string.format('%s with Steam ID: %s has been unbanned from server',player.name,steamid))
                return 'Unbanned ' .. player.name
            end
        end
    end
    return 'Cant unban player'
end

function ProcessConsoleCommand(command)
    Shared.ConsoleCommand(command)
    return command
end

-- Returns web api with type requested (json string or HTML Page (Default))
function getWebApi(datatype, command, kickedId)
    local dlcList = {
        specialEdition = kSpecialEditionProductId or false
    }
    local playerRecords = Shared.GetEntitiesWithClassname("Player")
    local entity = nil
    local stats = {
        cheats = tostring(Shared.GetCheatsEnabled()),
        devmode = tostring(Shared.GetDevMode()),
        map = tostring(Shared.GetMapName()),
        uptime = webServerUpTime(datatype),
        players = playerRecords:GetSize(),
        playersMarine = GetGamerules():GetTeam1():GetNumPlayers(),
        playersAlien = GetGamerules():GetTeam2():GetNumPlayers(),
        marineTeamResources = nil,
        alienTeamResources = nil
    }
    local result = ''
    if datatype == 'json' then
        if not command then command = false end
        local playerData = {}
        local playerDlc = {}
        local playerList = {}
        for index,player in ientitylist(playerRecords) do
            local entity = Server.GetOwner(player)
            // The ServerClient may be nil if this player was just removed from the server
            // right before this function was called.
            if entity then
            
                for dlcKey,dlcValue in pairs(dlcList) do
                    playerDlc[dlcKey] = tostring(Server.GetIsDlcAuthorized(entity, dlcValue))
                end
                playerData = {
                    name    = player:GetName(),
                    steamid    = entity:GetUserId(),
                    isbot    = tostring(entity:GetIsVirtual()),
                    team    = webGetTeam(player, datatype),
                    iscomm    = webIsCommander(player, datatype),
                    score    = player:GetScore(),
                    kills    = player:GetKills(),
                    deaths    = player:GetDeaths(),
                    resources    = player:GetResources(),
                    ping    = entity:GetPing(),
                    dlc        = playerDlc
                }
                table.insert(playerList,playerData)
                
            end
        end
        local data = {
            webdomain        = '[[webdomain]]',
            webport            = '[[webport]]',
            command            = tostring(command),
            cheats            = stats['cheats'],
            devmode            = stats['devmode'],
            map                = stats['map'],
            players_online    = stats['players'],
            marines            = stats['playersMarine'],
            aliens            = stats['playersAlien'],
            uptime            = stats['uptime'],
            player_list        = playerList,
            player_banlist    = Server.playerBanList
                    }
        result = json.encode(data)
    else
    --If no header type is specified then return the standard webform
        result = result .. '<html><head>'.."\n"
            .. '<title>Spark Web API</title>'.."\n"
            .. '<style type="text/css">'.."\n"
            .. '.bb {border-bottom:1px dashed #C8C8C8;background-color:#EBEBEB;}'.."\n"
            .. 'body, td, div { font-size:11px;font-family: Arial, Helvetica; }'.."\n"
            .. '.t {margin:auto;border:2px solid #1e1e1e;}'.."\n"
            .. 'div {width:800;margin:auto;}'.."\n"
            .. ' input {padding:1px;margin:1px;line-height:10px;}'.."\n"
            .. '</style>'.."\n"
            .. '</head><body>'.."\n"
            .. '<div><h1><a href="http://[[webdomain]]:[[webport]]/" target="_self">NS2 Server Manager</a></h1></div><br clear="all" />'.."\n"
            .. '<table width="800" cellspacing="2" cellpadding="2" class="t">'.."\n"
            .. '<tr><td colspan="2"><b>Server Uptime:</b> ' .. stats['uptime'] .. '</td></tr>'.."\n"
            .. '<tr><td class="bb" width="100"><b>Currently Playing:</td><td class="bb">' .. stats['map'] .. '</td></tr>'.."\n"
            .. '<tr><td class="bb"><b>Players Online:</b></td><td class="bb"><b>' .. stats['players'] .. '</b> &nbsp; &nbsp; &nbsp; Marine: <b>' .. stats['playersMarine'] .. '</b> | Alien: <b>' .. stats['playersAlien'] .. '</b></td></tr>'.."\n"
            .. '<tr><td class="bb"><b>Developer Mode:</b></td><td class="bb">' .. stats['devmode'] .. '</td></tr>'.."\n"
            .. '<tr><td class="bb"><b>Cheats Enabled:</b></td><td class="bb">' .. stats['cheats'] .. '</td></tr>'.."\n"
            .. '<tr><td colspan="2"><form name="send_rcon" action="http://[[webdomain]]:[[webport]]/" method="post">'
            .. '<p>'
            .. '<label for="command"><b>Console Command:</b> </label>'
            .. '<input type="text" name="rcon" size="24"> '
            .. '<input type="submit" name="command" value="Send">'
            .. ' <input type="submit" name="addbot" value="Add Bot" /> '
            .. ' <input type="submit" name="removebot" value="Remove Bot" /> '
            .. '</p>'
            .. '</form></td></tr>'
        if command then
            result = result .. '<tr><td><b>Command Sent:</b></td><td>' .. command .. '</td></tr>'.."\n"
        end
        result = result    .. '</table><br clear="all"/>'.."\n"
            .. '<table width="800" class="t" cellspacing="4" cellpadding="2">'.."\n"
            .. '<tr>'
            .. '<td><b>Player Name</b></td>'
            .. '<td><b>Team</b></td>'
            .. '<td align="center"><b>Score</b></td>'
            .. '<td align="center"><b>Kills</b></td>'
            .. '<td align="center"><b>Deaths</b></td>'
            .. '<td align="center"><b>Resources</b></td>'
            .. '<td><b>Steam ID</b></td>'
            .. '<td align="center"><b>Ping</b></td>'
            .. '<td></td>'
            .. '</tr>'

        local kickbutton = ''
        local kickbtext = ''
        local steamid = 0

        for index, player in ientitylist(playerRecords) do

            local entity = Server.GetOwner(player)
            // The ServerClient may be nil if this player was just removed from the server
            // right before this function was called.
            if entity then
            
                steamid = entity:GetUserId()

                if (entity:GetIsVirtual() == true) then
                    kickbtext = 'Bot'
                    kickbutton = 'disabled'
                elseif (tonumber(kickedId) == tonumber(steamid)) then
                    kickbtext = 'Kicked...'
                    kickbutton = 'disabled'
                else
                    kickbtext = 'Kick'
                    kickbutton = ''
                end

                result = result .. '<tr>'
                                .. '<td valign="middle" class="bb"><b>' .. player:GetName() .. '</b> ' .. webIsCommander(player, datatype) .. '</td>'
                                .. '<td valign="middle" class="bb">' .. webGetTeam(player, datatype) .. '</td>'
                                .. '<td valign="middle" align="center" class="bb">' .. player:GetScore() .. '</td>'
                                .. '<td valign="middle" align="center" class="bb">' .. player:GetKills() .. '</td>'
                                .. '<td valign="middle" align="center" class="bb">' .. player:GetDeaths() .. '</td>'
                                .. '<td valign="middle" align="center" class="bb">' .. player:GetResources() .. '</td>'
                                .. '<td valign="middle" class="bb">' .. steamid .. '</td>'
                                .. '<td valign="middle" align="center" class="bb">' .. entity:GetPing() .. '</td>'
                                .. '<td valign="middle"><form name="' .. steamid .. '_playerlist" action="http://[[webdomain]]:[[webport]]/" method="post" style="display:inline;"><input type="hidden" name="steamid" value="' .. steamid .. '" /><input type="submit" name="kick" value="' .. kickbtext .. '" ' .. kickbutton .. ' /> <input type="submit" name="ban" value="Ban" ' .. kickbutton .. ' /><input type="submit" name="kickban" value="Kick &amp; Ban" ' .. kickbutton .. ' /> <b>Duration:</b> <select name="ban_duration" ' .. kickbutton .. '><option value="-1" disabled="disabled">Forever (TODO)</option><option value="0" selected>This server session</option><option value="30">30 Minuets</option><option value="120">2 Hours</option><option value="480">8 Hours</option><option value="960">16 hours</option><option value="1440">1 Day</option><option value="2880">2 Days</option><option value="5760">4 Days</option></select></form></td>'
                                .. '</tr>'.."\n"
                                
            end
        end
        result = result    .. '</table><br clear="all"/>'.."\n"
            .. '<table width="800" class="t" cellspacing="4" cellpadding="2">'.."\n"
            .. '<tr>'
            .. '<td><b>Player Name</b></td>'
            .. '<td><b>Steam ID</td>'
            .. '<td><b>Ban Duration</b></td>'
            .. '<td></td>'
            .. '</tr>'
        for i,banned in pairs(Server.playerBanList) do
            banduration = 'Server Session'
            if banned.duration > 0 then
                local banclock = math.floor((((math.floor(Shared.GetTime()) - banned.timeOfBan) * 60) / 60) / 60)
                banduration = banclock .. ' / ' .. banned.duration .. ' Minuet(s)'
                if banclock >= banned.duration then
                    Shared.Message(string.format('Temporary ban expired: Unbanning %s',banned.name))
                    table.remove(Server.playerBanList,i)
                end
            end
            result = result .. '<tr><td valign="middle" class="bb">' .. banned.name .. '</td><td valign="middle" class="bb">' .. banned.steamid .. '</td><td valign="middle" class="bb">' .. banduration .. '</td><td valign="middle"><form name="ban_' .. steamid .. '" method="post" action="http://[[webdomain]]:[[webport]]/" style="display:inline;"><input type="hidden" name="steamid" value="' .. banned.steamid .. '"><input type="submit" name="unban" value="Unban" /></form></td>'
        end
        result = result .. '</table>'.."\n"
                        .. '</body></html>'

    end

    return result

end

local function OnWebRequest(actions)
    local datatype = 'html'
    local command = false
    local kickedId = false
    if actions.request == 'json' then datatype = 'json' end
    if actions.command then command = ProcessConsoleCommand(actions.rcon) end
    if actions.addbot then command = ProcessConsoleCommand('addbot') end
    if actions.removebot then command = ProcessConsoleCommand('removebot') end
    if actions.unban then command = webUnbanPlayer(actions.steamid) end
    if actions.kick then
        command = webKickPlayer(actions.steamid)
        kickedId = tonumber(actions.steamid) or 0
    end
    if actions.ban or actions.kickban then
        command = webBanPlayer(actions.steamid, actions.ban_duration)
        if actions.kickban then
            kickedId = tonumber(actions.steamid) or 0
            webKickPlayer(kickedId)
        end
    end
    return getWebApi(datatype,command,kickedId)
end

function GetTechTree(teamNumber)
    return GetGamerules():GetTeam(teamNumber):GetTechTree()
end

/**
 * Called by the engine to test if a player (represented by the entity they are
 * controlling) can hear another player for the purposes of voice chat.
 */
local function OnCanPlayerHearPlayer(listener, speaker)
    return GetGamerules():GetCanPlayerHearPlayer(listener, speaker)
end

local function OnUpdateServer(deltaTime)
end

Event.Hook("ClientConnect",            OnConnectCheckBan)
Event.Hook("MapPreLoad",            OnMapPreLoad)
Event.Hook("MapPostLoad",            OnMapPostLoad)
Event.Hook("MapLoadEntity",            OnMapLoadEntity)
Event.Hook("WebRequest",            OnWebRequest)
Event.Hook("CanPlayerHearPlayer",   OnCanPlayerHearPlayer)
Event.Hook("UpdateServer",          OnUpdateServer)
