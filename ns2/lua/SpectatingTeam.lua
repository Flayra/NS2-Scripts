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
Script.Load("lua/TeamDeathMessageMixin.lua")

class 'SpectatingTeam' (Team)

function SpectatingTeam:Initialize(teamName, teamNumber)

    InitMixin(self, TeamDeathMessageMixin)
    
    Team.Initialize(self, teamName, teamNumber)
    
end

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 */
function SpectatingTeam:ReplaceRespawnPlayer(player, origin, angles)

    local spectatorPlayer = player:Replace(Spectator.kMapName, self:GetTeamNumber(), false, origin)
    
    spectatorPlayer:ClearGameEffects()
   
    return true, spectatorPlayer

end

function SpectatingTeam:GetSupportsOrders()
    return false
end