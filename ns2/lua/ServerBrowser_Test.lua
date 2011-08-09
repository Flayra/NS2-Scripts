//=============================================================================
//
// lua/ServerBrowser_Test.lua
// 
// Created by Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

local kTimeRefreshed = 0
local kNumServers = 0

function GetNumServers()
    // Add fake refresh
    local timePassed = (Shared.GetTime() - kTimeRefreshed)
    return math.min(timePassed*25, kNumServers)
end

local kNameFormat = {
    "%s's House of Pain",
    "24/7 NS2 BETA TESTING | %s",
    "%s Unofficial Gaming Community",
    "Armenians for Life [%s]",
    "%s Random WP All Welcome{100 Tick {Streaming Music}",
    "Peruvian Mafia %s Clan Pub",
    "#%s Match Server | Provided by LegionServers.com",
    "%s.net 1000FPS Hyper Performance - Order Today!",
    "%s's Scrim Server",
    "Newbie/Pubbers welcome (run by %s)",
    "%s Man's Cheats Enabled NS2DM:S :)"
}
local kNames = { "Flayra", "WazzGame.com", "Old Fogies", ".=random=.", "Ooghi", "m4x0r", "LegionServers", "sLudgeWorks", "Puzzle Maniacs", "Reddit", "Bob", "n00bsalad.com", "GPG", "Gnome-Bombsquad" }

function GetRandomServerName()

    local index = math.floor(math.random()*table.maxn(kNameFormat))
    local nameFormat = kNameFormat[math.min(math.max(1, index), table.maxn(kNameFormat))]
    
    local nameIndex = math.floor(math.random()*table.maxn(kNames))
    local name = kNames[math.min(math.max(1, nameIndex), table.maxn(kNames))]
    
    local serverName = string.format(nameFormat, name)
    return serverName
    
end

function GetRandomGameDesc()
    local r = math.random()
    if(r < .3) then return "ns2" elseif(r < .6) then return "combat" else return "siege" end
end

function GetRandomMapName()
    local r = math.random()
    if(r < .2) then return "ns2_tram" elseif(r < .4) then return "ns2_lavafalls" elseif(r < .8) then return "ns2_refinery" else return "siegemap01" end
end

function GetRandomPlayers() return math.floor(math.random() * 20) end
function GetRandomPing() return math.floor(30 + math.random()*700) end

function GetRandomIP() 
    return string.format("%d.%d.%d.%d", math.floor(math.random()*255), math.floor(math.random()*255), math.floor(math.random()*255), math.floor(math.random()*255))
end

local kFakeServerData = {}

// Starts at 0 instead of 1
function GetServerRecord(serverIndex)
    return kFakeServerData[serverIndex + 1]
end

function RefreshServerList()

    kNumServers = math.floor(100 + math.random() * 500)
    kTimeRefreshed = Shared.GetTime()
    
    kFakeServerData = {}
    
    for i=1,kNumServers do
        local serverData = {GetRandomServerName(), GetRandomGameDesc(), GetRandomMapName(), GetRandomPlayers(), GetRandomPing(), GetRandomIP() }
        table.insert(kFakeServerData, serverData)
    end
    
end
