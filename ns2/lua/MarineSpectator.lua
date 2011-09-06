// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineSpectator.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Alien spectators can choose their upgrades and lifeform while dead.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Spectator.lua")

class 'MarineSpectator' (Spectator)

MarineSpectator.kMapName = "marinespectator"

// just a placeholder in case we might want to add something
MarineSpectator.networkVars =
{
}

// Allow players to rotate view, chat, scoreboard, etc. but not move
function MarineSpectator:OverrideInput(input)

    self:_CheckInputInversion(input)
    
    // Completely override movement and commands
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0
   
    return input
    
end

Shared.LinkClassToMap( "MarineSpectator", MarineSpectator.kMapName, MarineSpectator.networkVars )