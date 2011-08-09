//=============================================================================
//
// lua/Target.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================
Script.Load("lua/LiveScriptActor.lua")

class 'Target' (LiveScriptActor)

function Target:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    self:SetPhysicsType(Actor.PhysicsType.Kinematic)    

end

function Target:OnLoad()

    LiveScriptActor.OnLoad(self)

    if(self.model ~= nil) then
        Shared.PrecacheModel(self.model)
        self:SetModel( self.model )
    end

    // Team number set by LiveScriptActor:OnLoad

    self.health = tonumber(self.health)    
    self.initialHealth = self.health

    if(self.deathSoundName ~= nil) then
        Shared.PrecacheSound(self.deathSoundName)
    end

    self.popupAnimation = tostring(self.popupAnimation)
    if self.popupAnimation == "" or self.popupAnimation == nil then
        self.popupAnimation = "popup"
    end
    
    if(self.popupSoundName ~= nil) then
        Shared.PrecacheSound(self.popupSoundName)
    end

    self.popupRadius = tonumber(self.popupRadius)
    
    self.popupDelay = tonumber(self.popupDelay)
    
    self:Reset()
        
end

function Target:GetCanIdle()
    return false
end

if (Server) then

    function Target:Reset()
    
        self:SetIsVisible(true)
        
        // Reset the model and change to kinematic so if
        // model was ragdolled before it will work on reset
        self:SetPhysicsType(Actor.PhysicsType.None)
        
        self:UpdatePhysicsModelSimulation()
        
        self:SetPhysicsType(Actor.PhysicsType.Kinematic)
        
        if(self.spawnAnimation ~= nil and self.spawnAnimation ~= "") then
            self:SetAnimation( self.spawnAnimation )
        end
    
        self.detectedPlayer = false
        
        self:SetIsAlive(true)
        
        self.health = self.initialHealth
        
        self:SetNextThink(.1)
        
    end
    
    function Target:OnKill(damage, attacker, doer, point, direction)
    
        // Create a rag doll.
        self:SetPhysicsType(Actor.PhysicsType.Dynamic)
        self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
            
        self:SetNextThink(4)
        
        self:SetIsAlive(false)

    end
            
    // Create new target here
    function Target:OnThink()
    
        if self:GetIsAlive() then
        
            if not self.detectedPlayer then
            
                // Check for players in range
                local nextThink = .4
                
                // If in range, set next think
                for index, entity in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                
                    local dist = (entity:GetOrigin() - self:GetOrigin()):GetLength()
                    if dist <= self.popupRadius then
                    
                        self.detectedPlayer = true
                    
                        nextThink = NetworkRandom()*self.popupDelay
                        
                        break

                    end
                    
                end
                
                if nextThink > 0 then            
                    self:SetNextThink(nextThink)
                end
                
            else
            
                self:SetAnimation(self.popupAnimation, true)
                    
                self:PlaySound(self.popupSoundName)
                
            end
            
        else
        
            // Don't destroy map entities
            self:SetIsVisible(false)
            
        end
        
    end
   
end


if (Client) then

    function Target:OnTakeDamage(damage, attacker, doer, point)
     
        LiveScriptActor.OnTakeDamage(self, damage, attacker, doer, point)
        
        // Push the physics model around on the client when we shoot it.
        // This won't affect the model on other clients, but it's just for
        // show anyway (doesn't affect player movement).
        if (self.physicsModel ~= nil) then
            local direction = Vector(0, 1, 0)
            if doer and point then
                direction = doer:GetOrigin() - point
            end
            self.physicsModel:AddImpulse(point, direction * 0.01)
        end
        
    end

end

Shared.LinkClassToMap("Target", "target", {} )
