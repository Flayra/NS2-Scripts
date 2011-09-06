// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PhantomMixin.lua    
//    
// Manages a "phantom" version of a player or structure. The alien commander can use the Shade
// to allow players to become phantom versions of other aliens. These can be killed but can't
// do damage. Phantom structures can also be created, which look and act like real versions of
// the structures, but without being functional in any way (don't contribute to tech tree, don't
// have abilities, etc.).
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

PhantomMixin = { }
PhantomMixin.type = "Phantom"

PhantomMixin.expectedCallbacks =
{
    GetTechId = "Used for?",
    GetId = "",
    OnKill = "",
}

function PhantomMixin.__prepareclass(toClass)   

    ASSERT(toClass.networkVars ~= nil, "PhantomMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        // 0 when not active, > 0 when object is a phantom
        phantomLifetime = "float",
        expired = "boolean",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function PhantomMixin:__initmixin()   
    self.phantomLifetime = 0 
    self.expired = false
    self.hostPlayerId = Entity.invalidId
    self.phantomPlayerId = Entity.invalidId
end

// Set duration after which we will expire
function PhantomMixin:SetPhantomLifetime(lifetime)

    ASSERT(type(lifetime) == "number")
    ASSERT(lifetime >= 0)
    
    self.phantomLifetime = lifetime
    self.expired = false
    
end

function PhantomMixin:GetPhantomLifetime()
    return self.phantomLifetime
end

function PhantomMixin:GetIsExpired()
    return self.expired
end

function PhantomMixin:OnUpdate(deltaTime)

    if self:GetIsPhantom() then
    
        self.phantomLifetime = math.max(self.phantomLifetime - deltaTime, 0)
        
        if not self.expired and self.phantomLifetime == 0 then
        
            self:OnKill(0, nil, nil, nil, nil)
            self.expired = true
            
        end
        
    end
    
end

function PhantomMixin:GetIsPhantom()
    return (self.phantomLifetime > 0)
end

function PhantomMixin:SetHostPlayer(player)
    self.hostPlayerId = player:GetId()
end

function PhantomMixin:SetPhantomPlayer(newPlayer)
    self.phantomPlayerId = newPlayer:GetId()
end

function PhantomMixin:OnKill(damage, attacker, doer, point, direction)

    if self:GetIsPhantom() then
        
        self:RestoreToHostPlayer()
        
    else
    
        self:KillPhantom(damage, attacker, doer, point, direction)
        
    end 
   
end

function PhantomMixin:KillPhantom(damage, attacker, doer, point, direction)

    // Destroy phantom also, in the same way we are destroyed
    if self.phantomPlayerId ~= Entity.invalidId then
    
        local phantomPlayer = Shared.GetEntity(self.phantomPlayerId)
        if phantomPlayer ~= nil and phantomPlayer:isa("Player") then
        
            // Set before calling OnKill() to avoid recursive issues when calling OnKill() again
            self.phantomPlayerId = Entity.invalidId
            
            phantomPlayer:OnKill(damage, attacker, doer, point, direction)
            
            return true
        
        end
        
    end
    
    return false
        
end

function PhantomMixin:RestoreToHostPlayer()

    if self:GetIsPhantom() and (self.hostPlayerId ~= Entity.invalidId) then
    
        local hostPlayer = Shared.GetEntity(self.hostPlayerId)
        if hostPlayer ~= nil and hostPlayer:isa("Player") then
        
            local playerId = self:GetId()
            local killedPlayer = Shared.GetEntity(playerId)
            
            ASSERT(killedPlayer ~= nil)
            ASSERT(killedPlayer:isa("Player"))
        
            // Player now controls original again
            local owner = Server.GetOwner(killedPlayer)
            ASSERT(owner ~= nil)
            hostPlayer:SetControllingPlayer(owner)
            
            // Notify others of the change     
            killedPlayer:SendEntityChanged(hostPlayer:GetId())
            
            // No longer in phantom mode
            self.phantomLifetime = 0
            self.hostPlayerId = Entity.invalidId
            
            return true
        
        else
            Print("PhantomMixin:OnKill(): Couldn't find host player (%s)", ToString(self.hostPlayerId))
        end
    end
    
    return false
    
end

function PhantomMixin:GetPhantom()
    if self.phantomPlayerId ~= Entity.invalidId then
        return Shared.GetEntity(self.phantomPlayerId)
    end
    return nil
end

function PhantomMixin:GetHost()
    if self.hostPlayerId ~= Entity.invalidId then
        return Shared.GetEntity(self.hostPlayerId)
    end
    return nil
end

function StartPhantomMode(player, mapName, origin)

    // Transform them into the alien type represented by this effigy
    local owner = Server.GetOwner(player)
    local newPlayer = CreateEntity(mapName, origin, player:GetTeamNumber())        
    newPlayer:SetControllingPlayer(owner)
    newPlayer:SetName(player:GetName())
    
    // Notify others of the change     
    player:SendEntityChanged(newPlayer:GetId())
    
    // Set their PhantomMixin() active        
    ASSERT(HasMixin(newPlayer, "Phantom"))
    newPlayer:SetPhantomLifetime(kPhantomLifetime)
    player:SetPhantomPlayer(newPlayer)
    newPlayer:SetHostPlayer(player)
    
    player:SetScoreboardChanged(true)
    newPlayer:SetScoreboardChanged(true)
    
    newPlayer:TriggerEffects("phantom_effigy_start")

end