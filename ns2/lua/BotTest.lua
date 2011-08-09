//=============================================================================
//
// lua/BotTest.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
// This class is a simple bot that runs back and forth along a line for testing.
//
//=============================================================================

Script.Load("lua/Bot.lua")

class 'BotTest' (Bot)

function BotTest:GenerateMove()

    local move = Move()
    
    if self.switchTime == nil then
        self.switchTime = Shared.GetTime() + 2
        self.direction = Vector(1, 0, 0)
    end
    
    if Shared.GetTime() >= self.switchTime then
        self.switchTime = Shared.GetTime() + 2
        self.direction = -self.direction
    end
    
    move:Clear()

    move.yaw   = 0
    move.pitch = 0
    move.move  = self.direction
    
    return move

end