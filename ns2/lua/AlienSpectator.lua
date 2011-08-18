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
    
    if (Server) then
    
        self.evolveTechIds = { kTechId.Skulk }
        
    end

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

function AlienSpectator:SpawnPlayerOnAttack()

    local egg = self:GetHostEgg()
    
    if egg ~= nil then
    
        local startTime = egg:GetTimeQueuedPlayer()
        
        if startTime ~= nil and (Shared.GetTime() > (startTime + kAlienSpawnTime)) then
            return egg:SpawnPlayer()
        end
        
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

Shared.LinkClassToMap( "AlienSpectator", AlienSpectator.kMapName, AlienSpectator.networkVars )