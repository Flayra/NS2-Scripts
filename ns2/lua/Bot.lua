//=============================================================================
//
// lua\Bot.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

if (not Server) then
    error("Bot.lua should only be included on the Server")
end

class 'Bot'

function Bot:Initialize(forceTeam, active)

    // Create a virtual client for the bot
    self.client = Server.AddVirtualClient()
    self.forceTeam = forceTeam
    self.active = active
    
end

function Bot:UpdateTeam(joinTeam)

    local player = self:GetPlayer()

    // Join random team (could force join if needed but will enter respawn queue if game already started)
    if player:GetTeamNumber() == 0 and (math.random() < .03) then
    
        if joinTeam == nil then
            joinTeam = ConditionalValue(math.random() < .5, 1, 2)
        end
        
        if GetGamerules():GetCanJoinTeamNumber(joinTeam) or Shared.GetCheatsEnabled() then
            GetGamerules():JoinTeam(player, joinTeam)
        end
        
    end
    
end


function Bot:Disconnect()
    Server.DisconnectClient(self.client)    
    self.client = nil
end

function Bot:GetPlayer()
    return self.client:GetControllingPlayer()
end

function Bot:OnThink()
    self:UpdateTeam(self.forceTeam)        
end

// Stores all of the bots
local bots = { }

function OnConsoleAddPassiveBots(client, numBotsParam, forceTeam, className)
    OnConsoleAddBots(client, numBotsParam, forceTeam, className, true)  
end

function OnConsoleAddBots(client, numBotsParam, forceTeam, className, passive)

    // Run from dedicated server or with dev or cheats on
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
    
        local class = BotPlayer
    
        if className == "test" then
            class = BotTest
        end

        local numBots = 1
        if numBotsParam then
            numBots = math.max(tonumber(numBotsParam), 1)
        end
        
        for index = 1, numBots do
        
            local bot = class()
            bot:Initialize(tonumber(forceTeam), not passive)
            table.insert( bots, bot )
       
        end
        
    end
    
end

function OnConsoleRemoveBots(client, numBotsParam)
    
    // Run from dedicated server or with dev or cheats on
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then

        local numBots = 1
        if numBotsParam then
            numBots = math.max(tonumber(numBotsParam), 1)
        end
        
        for index = 1, numBots do

            local bot = table.remove(bots)
            
            if bot then        
                bot:Disconnect()            
            end
            
        end
        
    end
    
end

function OnVirtualClientMove(client)

    // If the client corresponds to one of our bots, generate a move from it.
    for i,bot in ipairs(bots) do
    
        if bot.client == client then
        
            local player = bot:GetPlayer()
            if player then
                return bot:GenerateMove()
            end
            
        end
        
    end

end

function OnVirtualClientThink(client, deltaTime)

    // If the client corresponds to one of our bots, allow it to think.
    for i, bot in ipairs(bots) do
    
        if bot.client == client then
            local player = bot:GetPlayer()
            bot:OnThink()
        end
        
    end

    return true
    
end

Script.Load("lua/Bot_Player.lua")
Script.Load("lua/BotTest.lua")

// Register the bot console commands
Event.Hook("Console_addpassivebot",  OnConsoleAddPassiveBots)
Event.Hook("Console_addbot",         OnConsoleAddBots)
Event.Hook("Console_removebot",      OnConsoleRemoveBots)
Event.Hook("Console_addbots",        OnConsoleAddBots)
Event.Hook("Console_removebots",     OnConsoleRemoveBots)

// Register to handle when the server wants this bot to
// process orders
Event.Hook("VirtualClientThink",    OnVirtualClientThink)

// Register to handle when the server wants to generate a move
// for one of the virtual clients
Event.Hook("VirtualClientMove",     OnVirtualClientMove)