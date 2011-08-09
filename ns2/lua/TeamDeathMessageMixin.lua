// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TeamDeathMessageMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// Adds support to send a death message to clients on a team when something dies.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

TeamDeathMessageMixin = { }
TeamDeathMessageMixin.type = "TeamDeathMessage"

TeamDeathMessageMixin.expectedCallbacks =
{
    SendCommand = "Send the passed in console command to all the players on the team."
}

function TeamDeathMessageMixin:__initmixin()
end

function TeamDeathMessageMixin:OnKill(targetEntity, damage, killer, doer, point, direction)

    if not targetEntity or targetEntity:GetSendDeathMessage() then
    
        local index = 0
        
        if doer and doer:GetDeathIconIndex() then
            index = doer:GetDeathIconIndex()
        end
        
        self:SendCommand( self:GetDeathMessage(killer, index, targetEntity) )
        
    end
    
end

// Create death message string with following format:
//
// deathmsg killingPlayerIndex killerTeamNumber doerIconIndex targetPlayerIndex targetTeamNumber
//
// Note: Client indices are used here as entity Ids aren't always valid on the client
// due to relevance. If the killer or target is not a player, the entity techId is used.
function TeamDeathMessageMixin:GetDeathMessage(killer, doerIconIndex, targetEntity)

    local killerIsPlayer = 0    
    local killerIndex = -1
    
    if killer then
    
        killerIsPlayer = ConditionalValue(killer:isa("Player"), 1, 0)
        if killerIsPlayer == 1 then
            killerIndex = killer:GetClientIndex()
        else
        
            if killer:GetOwner() and killer:GetOwner():isa("Player") then
                killerIsPlayer = 1
                killerIndex = killer:GetOwner():GetClientIndex()
            else
                killerIndex = killer:GetTechId()
            end
            
        end
        
    end
    
    local targetIsPlayer = ConditionalValue(targetEntity:isa("Player"), 1, 0)
    local targetIndex = -1
    if targetIsPlayer == 1 then
        targetIndex = targetEntity:GetClientIndex()
    else
        targetIndex = targetEntity:GetTechId()
    end
    
    local targetTeamNumber = targetEntity:GetTeamNumber()
    local killerTeamNumber = targetTeamNumber
    if killer then
        killerTeamNumber = killer:GetTeamNumber()
    end
    
    return string.format("deathmsg %d %d %d %d %d %d %d", killerIsPlayer, killerIndex, killerTeamNumber, doerIconIndex, targetIsPlayer, targetIndex, targetTeamNumber)

end