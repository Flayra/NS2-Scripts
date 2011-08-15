// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LoopingSoundMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//
// Allows a looping sound to be tracked by a parent entity. Makes it it stops looping
// when the parent dies or changes. Users of the mixin call PlayLoopingSound() and optionally
// StopLoopingSound(), and GetLoopingEntityId(). Must provide OnStopLoopingSound().
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

LoopingSoundMixin = { }
LoopingSoundMixin.type = "LoopingSound"

LoopingSoundMixin.expectedCallbacks =
{
    // Only called if sound was playing when StopLoopingSound() called
    OnStopLoopingSound = "Called with parent when looping sound is stopped manually, or because entity was destroyed or changed.",
}

function LoopingSoundMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "LoopingSoundMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        playingLoopingOnEntityId    = "entityid",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function LoopingSoundMixin:__initmixin()
    self.playingLoopingOnEntityId = Entity.invalidId
end

function LoopingSoundMixin:OnInit()
    self.playingLoopingOnEntityId = Entity.invalidId
end

function LoopingSoundMixin:StopLoopingSound()
    
    if self.soundName ~= nil then
    
        ASSERT(type(self.soundName) == "string")
        
        local parent = Shared.GetEntity(self.playingLoopingOnEntityId)
        if parent then
        
            Shared.StopSound(parent, self.soundName)
            
        end
        
        // This case happens when the sound effect has been stopped by StopLoopingSound on
        // the server, but was not predicted on the client (when a player dies for example).
        if Client then    
        
            // In the case where the parent no longer exists, the engine will have automatically
            // stopped the looping sound effect.
            local clientParent = Shared.GetEntity(self.clientParentId)
            if clientParent then
                Shared.StopSound(clientParent, self.soundName)
            end
            
            self.clientParentId  = nil
            
        end
        
        self:OnStopLoopingSound(parent)
        
        // This indicates if sound is playing or not
        self.soundName = nil
            
        //self.playingLoopingOnEntityId = Entity.invalidId
        
    end
    
end

// Returns boolean if sound was played. Don't play sound on same player if already playing.
// If on new player, stop old sound and start new sound.
function LoopingSoundMixin:PlayLoopingSound(parent, soundName)

    ASSERT(parent ~= nil)
    ASSERT(parent.isa)
    ASSERT(parent:isa("Player"))
    ASSERT(type(soundName) == "string")
    
    if self.soundName ~= nil then
    
        // Don't replay sound on existing
        if parent:GetId() == self.playingLoopingOnEntityId then
            return false
        else
            // Stop first if already playing
            self:StopLoopingSound()
        end
    
    end
    
    Shared.PlaySound(parent, soundName)
    
    self.playingLoopingOnEntityId = parent:GetId()
    self.soundName = soundName
    
    // Store enough information for us to stop the sound in the case where
    // the player dies.
    if Client then
        self.clientParentId = parent:GetId()
    end
    
    return true
    
end

function LoopingSoundMixin:GetLoopingEntityId()
    return self.playingLoopingOnEntityId
end

function LoopingSoundMixin:OnEntityChange(oldId, newId)

    // In case the parent is destroyed.
    if oldId == self.playingLoopingOnEntityId then
    
        self:StopLoopingSound()
        
    end

end

function LoopingSoundMixin:OnDestroy()
    self:StopLoopingSound()
end

function LoopingSoundMixin:GetIsLoopingSoundPlaying()
    return (self.soundName ~= nil)
end

function LoopingSoundMixin:OnUpdate()

    // If our parent goes away while we're playing, stop the sound
    if self:GetIsLoopingSoundPlaying() and ((self.playingLoopingOnEntityId == Entity.invalidId) or (Shared.GetEntity(self.playingLoopingOnEntityId) == nil)) then
    
        self:StopLoopingSound()
        
    end

end
