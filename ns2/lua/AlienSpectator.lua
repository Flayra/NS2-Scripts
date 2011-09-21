// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienSpectator.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Alien spectators can choose their upgrades and lifeform while dead.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Spectator.lua")

class 'AlienSpectator' (Spectator)

AlienSpectator.kMapName = "alienspectator"

AlienSpectator.networkVars =
{
    eggId = "entityid"
}

function AlienSpectator:OnInit()

    Spectator.OnInit(self)
    
    self.eggId = 0
    self.movedToEgg = false
    
    // maybe find a better place for that
    self:AddTooltipOncePer("HOWTO_HATCH_TOOLTIP")
    
    if (Server) then
    
        self.evolveTechIds = { kTechId.Skulk }
        
    end

end

// seems not to get called
function AlienSpectator:UpdateHelp()

    if self:AddTooltipOncePer("HOWTO_HATCH_TOOLTIP") then
        return true
    end

    return false
    
end

function AlienSpectator:GetTechId()
    return kTechId.AlienSpectator
end

// Returns egg we're currently spawning in or nil if none
function AlienSpectator:GetHostEgg()

    if self.eggId ~= 0 then
        return Shared.GetEntity(self.eggId)
    end
    
    return nil
    
end

function AlienSpectator:SetEggId(id)
    self.eggId = id
end

function AlienSpectator:GetEggId()
    return self.eggId
end

// more accurate name for that function would be now "SpawnPlayerOnJump()"
function AlienSpectator:SpawnPlayerOnAttack()

    local egg = self:GetHostEgg()
    
    if egg ~= nil then
    
        local startTime = egg:GetTimeQueuedPlayer()
        
        return egg:SpawnPlayer()
        
    elseif Shared.GetCheatsEnabled() then
        return self:GetTeam():ReplaceRespawnPlayer(self)
    end
    
    // Play gentle "not yet" sound
    Shared.PlayPrivateSound(self, Player.kInvalidSound, self, .5, Vector(0, 0, 0))
    
    return false, nil
    
end

// Same as Skulk so his view height is right when spawning in
function AlienSpectator:GetMaxViewOffsetHeight()
    return Skulk.kViewOffsetHeight
end

function AlienSpectator:SetOriginAnglesVelocity(input)

    local egg = self:GetHostEgg()
    if egg ~= nil then
    
        // If we're not near the egg, rise player up out of the ground to make it feel cool
        local eggOrigin = egg:GetOrigin()
        
        if not self.movedToEgg then
        
            self:SetOrigin(Vector(eggOrigin.x, eggOrigin.y - 1, eggOrigin.z))
            self:SetAngles(egg:GetAngles())
            self:SetVelocity(Vector(0, 0, 0))
            
            self.movedToEgg = true
            
        end
        
        // Update position with friction so we slow to final resting position
        local playerOrigin = self:GetOrigin()
        local yDiff = eggOrigin.y - playerOrigin.y 
        local moveAmount = math.sin(yDiff * 2) * input.time
        self:SetOrigin(Vector(playerOrigin.x, playerOrigin.y + moveAmount, playerOrigin.z))
        
        // Let player look around
        Spectator.UpdateViewAngles(self, input)  
        
    else
        Spectator.SetOriginAnglesVelocity(self, input)
    end
    
end

// Allow players to rotate view, chat, scoreboard, etc. but not move
function AlienSpectator:OverrideInput(input)
    
    self:_CheckInputInversion(input)
    
    // Completely override movement and commands
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0

    // Only allow some actions like going to menu, chatting and Scoreboard (not jump, use, etc.)
    input.commands = bit.band(input.commands, Move.PrimaryAttack) + bit.band(input.commands, Move.SecondaryAttack) + bit.band(input.commands, Move.Jump) + bit.band(input.commands, Move.Exit) + bit.band(input.commands, Move.TeamChat) + bit.band(input.commands, Move.TextChat) + bit.band(input.commands, Move.Scoreboard) + bit.band(input.commands, Move.ShowMap)
    
    return input
    
end



function AlienSpectator:_HandleSpectatorButtons(input)

    //exlude attack and jump get not proccessed
    local cycleLeft = bit.band(input.commands, Move.PrimaryAttack) ~= 0
    local cycleRight = bit.band(input.commands, Move.SecondaryAttack) ~= 0
    local hatch = bit.band(input.commands, Move.Jump) ~= 0

    local time = Shared.GetTime()
    
    if (self:GetHostEgg() ~= nil) then
    
        // filter PrimaryAttack and Jump, so Spectator would not trigger spawning or change spectator mode when already having an egg assigned
        input.commands = bit.band(input.commands, Move.Exit) + bit.band(input.commands, Move.TeamChat) + bit.band(input.commands, Move.TextChat) + bit.band(input.commands, Move.Scoreboard) + bit.band(input.commands, Move.ShowMap) 
    
        if time > (self.timeOfLastInput + .3) then
        
	        // find next or previous free egg
	        if Server then
	            
	            if cycleLeft then
	            
	                local team = self:GetTeam()
	                team:QueuePlayerForAnotherEgg(self:GetEggId(), self:GetId(), true)
	                self.timeOfLastInput = Shared.GetTime()
	                
	            elseif cycleRight then
	            
	                local team = self:GetTeam()
	                team:QueuePlayerForAnotherEgg(self:GetEggId(), self:GetId(), false)             
	                self.timeOfLastInput = Shared.GetTime()
	                
	            elseif hatch then
	            
	                self:SpawnPlayerOnAttack()
	                self.timeOfLastInput = Shared.GetTime()
	            
	            end
	            
	        end
	        
        end
    
    end
    
    Spectator._HandleSpectatorButtons(self, input)

end

Shared.LinkClassToMap( "AlienSpectator", AlienSpectator.kMapName, AlienSpectator.networkVars )