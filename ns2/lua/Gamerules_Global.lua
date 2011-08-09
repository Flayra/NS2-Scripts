// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gamerules.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Global gamerules accessors. When gamerules are initialized by map they should call SetGamerules(). 
local globalGamerules = nil

function GetHasGameRules()
    return globalGamerules ~= nil
end

function SetGamerules(gamerules)

    if(gamerules ~= globalGamerules) then
    
        globalGamerules = gamerules
        
    end
    
end

// Get currently installed gamerules, or build new basic gamerules if not specified in map
function GetGamerules()

    if(Server) then
    
        ASSERT(globalGamerules ~= nil)
    
        if(globalGamerules == nil) then
        
            Print("No gamerules set, using default gamerules.")
            
            local gamerules = CreateEntity(Gamerules.kMapName, nil)
            
            SetGamerules(gamerules)
            
        end
        
        return globalGamerules
        
    end
    
    return nil
    
end

///////////////////
// Default hooks //
///////////////////
function OnClientConnect(client)
    GetGamerules():OnClientConnect(client)
end

function OnClientDisconnect(client)    
    GetGamerules():OnClientDisconnect(client)    
end

function OnMapPostLoad()
end

// Game methods
Event.Hook("ClientConnect",         OnClientConnect)
Event.Hook("ClientDisconnect",      OnClientDisconnect)
Event.Hook("MapPostLoad",           OnMapPostLoad)
