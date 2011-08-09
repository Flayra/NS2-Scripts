// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TeamJoin.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'TeamJoin' (Trigger)

TeamJoin.kMapName = "team_join"

function TeamJoin:OnInit()

    Trigger.OnInit(self)
    
    self.physicsBody:SetCollisionEnabled(true)
    
end

function TeamJoin:OnTriggerEntered(enterEnt, triggerEnt)

    if enterEnt:isa("Player") then
    
        if (self:GetTeamNumber() == kTeamReadyRoom) then
        
            // Join observers
            Server.ClientCommand(enterEnt, "spectate")
            
        elseif (self:GetTeamNumber() == kTeam1Index) then
        
            Server.ClientCommand(enterEnt, "jointeamone")
            
        elseif (self:GetTeamNumber() == kTeam2Index) then    
        
            Server.ClientCommand(enterEnt, "jointeamtwo")
            
        elseif (self:GetTeamNumber() == kRandomTeamType) then
        
            // Join team with less players or random
            local team1Players = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
            local team2Players = GetGamerules():GetTeam(kTeam2Index):GetNumPlayers()
            
            // Join team with least
            if(team1Players < team2Players) then
            
                Server.ClientCommand(enterEnt, "jointeamone")
                
            elseif(team2Players < team1Players) then
            
                Server.ClientCommand(enterEnt, "jointeamtwo")
                
            else
            
                // Join random
                if(NetworkRandom() < .5) then
                
                    Server.ClientCommand(enterEnt, "jointeamone")
                    
                else
                
                    Server.ClientCommand(enterEnt, "jointeamtwo")
                    
                end

            end
            
        end
        
    end
        
end

function TeamJoin:OnCreate()

    Trigger.OnCreate(self)
    
    self:SetPropagate(Actor.Propagate_Never)
    
    self:SetIsVisible(false)
    
end

Shared.LinkClassToMap("TeamJoin", TeamJoin.kMapName, {})
