// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")

function OnCommandTooltip(tooltipText)
    local player = Client.GetLocalPlayer()
    if (player ~= nil) then
        player:AddTooltip(tooltipText)
    end
end

function OnCommandRoundReset()
end

function OnCommandDeathMsg(killerIsPlayer, killerId, killerTeamNumber, iconIndex, targetIsPlayer, targetId, targetTeamNumber)
    AddDeathMessage(tonumber(killerIsPlayer), tonumber(killerId), tonumber(killerTeamNumber), tonumber(iconIndex), tonumber(targetIsPlayer), tonumber(targetId), tonumber(targetTeamNumber))
end

function OnCommandOnResetGame()

    Scoreboard_OnResetGame()

    ResetLights()
    
end

function OnCommandOnClientDisconnect(clientIndexString)
    Scoreboard_OnClientDisconnect(tonumber(clientIndexString))
end

function OnCommandScores(scoreTable)
    Scoreboard_SetPlayerData(scoreTable.clientId, scoreTable.entityId, scoreTable.playerName, scoreTable.teamNumber, scoreTable.score, scoreTable.kills, scoreTable.deaths, math.floor(scoreTable.resources), scoreTable.isCommander, scoreTable.status, scoreTable.isSpectator)
end

// Notify scoreboard and anything else when a player changes into a new player
function OnCommandEntityChanged(entityChangedTable)

    local newId = ConditionalValue(entityChangedTable.newEntityId == -1, nil, entityChangedTable.newEntityId)
    
    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("ScriptActor")) do
    
        // Allow player to update selection, etc. with entity replacement
        entity:OnEntityChange(entityChangedTable.oldEntityId, newId)
        
    end
       
end

// Called when player receives points from an action
function OnCommandPoints(pointsString, resString)
    local points = tonumber(pointsString)
    local res = tonumber(resString)
    ScoreDisplayUI_SetNewScore(points, res)
end

function OnCommandSoundGeometry(enabled)

    enabled = enabled ~= "false"
    Shared.Message("Sound geometry occlusion enabled: " .. tostring(enabled))
    Client.SetSoundGeometryEnabled(enabled)
    
end

function OnCommandReloadSoundGeometry(soundOcclusionFactor, reverbOcclusionFactor)

    if soundOcclusionFactor == nil or reverbOcclusionFactor == nil then
        Shared.Message("A sound occlusion factor and reverb occlusion factor (between 0-1) must be passed in.")
        return
    end
    Client.LoadSoundGeometry(tonumber(soundOcclusionFactor), tonumber(reverbOcclusionFactor))

end

function OnCommandPing(pingTable)
    local clientIndex, ping = ParsePingMessage(pingTable)    
    Scoreboard_SetPing(clientIndex, ping)   
end

function OnCommandClearTechTree()
    ClearTechTree()
end

function OnCommandTechNodeBase(techNodeBaseTable)
    GetTechTree():CreateTechNodeFromNetwork(techNodeBaseTable)
end

function OnCommandTechNodeUpdate(techNodeUpdateTable)
    GetTechTree():UpdateTechNodeFromNetwork(techNodeUpdateTable)
end

function OnCommandResetMouse()
    Client.SetYaw(0)
    Client.SetPitch(0)
end

function OnCommandAnimDebug(className)

    // Messages printed by server
    if Shared.GetDevMode() then
    
        if className then
            gActorAnimDebugClass = className
        elseif gActorAnimDebugClass ~= "" then
            gActorAnimDebugClass = ""
        end
    end
    
end

function OnCommandEffectDebug(className)

    Print("OnCommandEffectDebug(\"%s\")", ToString(className))
    if Shared.GetDevMode() then
    
        if className and className ~= "" then
            gEffectDebugClass = className
        elseif gEffectDebugClass ~= nil then
            gEffectDebugClass = nil
        else
            gEffectDebugClass = ""
        end
    end
    
end

function OnCommandDebugText(debugText, worldOriginString, entIdString)

    if Shared.GetDevMode() then
    
        local success, origin = DecodePointFromString(worldOriginString)
        if success then
        
            local ent = nil
            if entIdString then
                local id = tonumber(entIdString)
                if id and (id >= 0) then
                    ent = Shared.GetEntity(id)
                end
            end
            
            GetEffectManager():AddDebugText(debugText, origin, ent)
            
        else
            Print("OnCommandDebugText(%s, %s): Couldn't decode point.", debugText, worldOriginString)
        end
        
    end
    
end

function OnCommandLocate()

    local player = Client.GetLocalPlayer()
    
    if (player ~= nil) then
        local origin = player:GetOrigin()
        Shared.Message( string.format("Player is located at %f %f %f", origin.x, origin.y, origin.z) )
    end

end

function OnCommandSetSoundVolume(volume)
    if(volume == nil) then
        Print("Sound volume is (0-100): %s",  OptionsDialogUI_GetSoundVolume())
    else
        OptionsDialogUI_SetSoundVolume( tonumber(volume) )
    end
end

function OnCommandSetMusicVolume(volume)
    if(volume == nil) then
        Print("Music volume is (0-100): %s",  OptionsDialogUI_GetMusicVolume())
    else
        OptionsDialogUI_SetMusicVolume( tonumber(volume) )
    end
end

function OnCommandSetVoiceVolume(volume)
    if(volume == nil) then
        Print("Voice volume is (0-100): %s",  OptionsDialogUI_GetVoiceVolume())
    else
        OptionsDialogUI_SetVoiceVolume( tonumber(volume) )
    end
end

function OnCommandSetMouseSensitivity(sensitivity)
    if(sensitivity == nil) then
        Print("Mouse sensitivity is (0-100): %s",  OptionsDialogUI_GetMouseSensitivity())
    else
        OptionsDialogUI_SetMouseSensitivity( tonumber(sensitivity) )
    end
end

// Save this setting if we set it via a console command
function OnCommandSetName(nickname)
    local player = Client.GetLocalPlayer()
    nickname = StringTrim(nickname)
    
    if (nickname == nil) then
        return
    end
    
    if (player ~= nil) then        
        if (nickname == player:GetName()) or (nickname == kDefaultPlayerName) or string.len(nickname) < 0 then                    
            return
        end      
    end
    
    Client.SetOptionString( kNicknameOptionsKey, nickname )     
end

local function OnCommandFunctionContractsEnabled(enabled)

    SetFunctionContractsEnabled(enabled == "true")

end

function OnLocalizedTooltip(once, isTech, message, ...)
  local arg = {n=select('#',...),...}
  
  local localizedMessage = Locale.ResolveString(message)
  if (isTech == "true") then        
    localizedMessage = string.format(localizedMessage, GetDisplayNameForTechId(tonumber(arg[1])))
  else
    localizedMessage = string.format(localizedMessage, ...)
  end
  
  local player = Client.GetLocalPlayer()
  if (player ~= nil) then
    player:AddLocalizedTooltip(localizedMessage, once)
  end
end

Event.Hook("Console_tooltip",                   OnCommandTooltip)
Event.Hook("Console_localizedtooltip",          OnLocalizedTooltip)
Event.Hook("Console_reset",                     OnCommandRoundReset)
Event.Hook("Console_deathmsg",                  OnCommandDeathMsg)
Event.Hook("Console_clientdisconnect",          OnCommandOnClientDisconnect)
Event.Hook("Console_points",                    OnCommandPoints)
Event.Hook("Console_soundgeometry",             OnCommandSoundGeometry)
Event.Hook("Console_reloadsoundgeometry",       OnCommandReloadSoundGeometry)
Event.Hook("Console_onanimdebug",               OnCommandAnimDebug)
Event.Hook("Console_oneffectdebug",             OnCommandEffectDebug)
Event.Hook("Console_debugtext",                 OnCommandDebugText)
Event.Hook("Console_locate",                    OnCommandLocate)
Event.Hook("Console_name",                      OnCommandSetName)
Event.Hook("Console_functioncontractsenabled",  OnCommandFunctionContractsEnabled)

// Options Console Commands
Event.Hook("Console_setsoundvolume",            OnCommandSetSoundVolume)
// Just a shortcut.
Event.Hook("Console_ssv",                       OnCommandSetSoundVolume)
Event.Hook("Console_setmusicvolume",            OnCommandSetMusicVolume)
Event.Hook("Console_setvoicevolume",            OnCommandSetVoiceVolume)
Event.Hook("Console_setvv",                     OnCommandSetVoiceVolume)
Event.Hook("Console_setsensitivity",            OnCommandSetMouseSensitivity)

Client.HookNetworkMessage("Ping",               OnCommandPing)
Client.HookNetworkMessage("Scores",             OnCommandScores)
Client.HookNetworkMessage("EntityChanged",      OnCommandEntityChanged)

Client.HookNetworkMessage("ClearTechTree",      OnCommandClearTechTree)
Client.HookNetworkMessage("TechNodeBase",       OnCommandTechNodeBase)
Client.HookNetworkMessage("TechNodeUpdate",     OnCommandTechNodeUpdate)

Client.HookNetworkMessage("ResetMouse",         OnCommandResetMouse)
Client.HookNetworkMessage("ResetGame",          OnCommandOnResetGame)
