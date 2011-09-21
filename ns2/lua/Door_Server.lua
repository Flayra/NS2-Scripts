// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Door_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Door:Reset()
    
    self:OnInit()
    
    // Restore original origin, angles, etc. as it could have been rag-dolled
    self:SetOrigin(self.savedOrigin)
    self:SetAngles(self.savedAngles)
    
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(0)

    self:SetState(Door.kState.Closed)    
    
    self.timeToRagdoll = nil
    self.timeToDestroy = nil
    
end

function Door:OnLoad()

    self.weldTime = GetAndCheckValue(self.weldTime, 1, 1000, "weldTime", Door.kDefaultWeldTime, true)
    self.weldHealth = GetAndCheckValue(self.weldHealth, 1, 2000, "weldHealth", Door.kDefaultHealth, true)
    
    // Save origin, angles, etc. so we can restore on reset
    self.savedOrigin = Vector(self:GetOrigin())
    self.savedAngles = Angles(self:GetAngles())
    
end

function Door:OnWeld(entity, elapsedTime)

    local performedWelding = false
    
    if (self.state == Door.kState.Opened) then
        
        self:SetState(Door.kState.Close)
        
    elseif (self.state == Door.kState.Close) then
    
        // Do nothing yet
        
    elseif (self.state == Door.kState.Closed or self.state == Door.kState.Welding) then

        // Add weld time by using door
        self.time = self.time + elapsedTime
        
        // Check total weld time to that specified in entity property
        if(self.time >= self.weldTime) then
        
            self:SetState(Door.kState.Welded)
            self:SetPathingFlags(Pathing.PolyFlag_Closed)
            entity:AddScoreForOwner(Door.kWeldPointValue)
        else
            self:SetState(Door.kState.Welding)
            performedWelding = true
        end

    
    
    elseif(self.state ~= Door.kState.Welded) then
    
        // Make sure there is nothing obstructing door
        local blockingEnts = GetEntitiesWithinRange("Entity", self:GetOrigin(), 1)
        
        // ...but we can't block ourselves
        table.removevalue(blockingEnts, self) 
        
        if(table.count(blockingEnts) == 0) then
            
            self:SetState(Door.kState.Close)
            
        else
        
            entity:GetTeam():TriggerAlert(kTechId.MarineAlertWeldingBlocked, self)
            
        end
            
    end
    
    return performedWelding
    
end

function Door:OnWeldCanceled(entity)
    if (self.state == Door.kState.Welding) then
        self:SetState(Door.kState.Open)
    end
end

function Door:ComputeDamageOverride(attacker, damage, damageType, time)

    if damageType ~= kDamageType.Door then
        damage = 0
    end
    
    return damage, damageType

end

function Door:OnTakeDamage(damage, attacker, doer, point)
    
    // Locked doors become unlocked when damaged
    if self:GetIsAlive() and (self:GetState() == Door.kState.Locked) then
        self:SetState(Door.kState.Unlock)
    end
    
end

function Door:OnThink()

    ScriptActor.OnThink(self)
    
    // If any players are around, have door open if possible, otherwise close it
    local state = self:GetState()
    
    if self:GetIsAlive() and (state == Door.kState.Opened or state == Door.kState.Closed) then
    
        if (self.timeLastCommanderAction == 0) or (Shared.GetTime() > self.timeLastCommanderAction + 4) then
        
            local allScriptActors = Shared.GetEntitiesWithClassname("ScriptActor")
            
            local desiredOpenState = false
            for index, actor in ientitylist(allScriptActors) do
                local opensForEntity = false
                local openDistance = 1
    
                if HasMixin(actor, "Door") then
                   opensForEntity, openDistance = actor:GetCanDoorInteract(self)
                end                                
            
                if opensForEntity then
                  local distSquared = (actor:GetOrigin() - self:GetOrigin()):GetLengthSquared()
                  if ((not HasMixin(actor, "Live")) or actor:GetIsAlive()) and actor:GetIsVisible() and (distSquared < (openDistance * openDistance)) then
                
                    desiredOpenState = true
                    break
                    
                  end
                end
            end
            
            if desiredOpenState and (self:GetState() == Door.kState.Closed) then
                self:SetState(Door.kState.Open)
            elseif not desiredOpenState and (self:GetState() == Door.kState.Opened) then
                self:SetState(Door.kState.Close)
            elseif (self.overrideUnlockTime ~= 0) and (Shared.GetTime() > self.overrideUnlockTime + 3) then
                // Close door if open
                if (self:GetState() == Door.kState.Open) then
                    self:SetState(Door.kState.Close)    
                // Lock door if closed
                elseif self:GetState() == Door.kState.Closed then
                    self:SetState(Door.kState.Lock)                      
                end
            end
            
        end
        
    end
    
    self:SetNextThink(Door.kThinkTime)
    
end

function Door:OnAnimationComplete(animationName)

    // Opening => Open
    if (animationName == Door.kStateAnim[Door.kState.Open]) then
    
        self:SetState(Door.kState.Opened)
        
    // Closing => Closed
    elseif (animationName == Door.kStateAnim[Door.kState.Close]) then    
    
        self:SetState(Door.kState.Closed) 

    // Lock => Locked
    elseif (animationName == Door.kStateAnim[Door.kState.Lock]) then    
    
        self:SetState(Door.kState.Locked) 

    // Unlock => Unlocked
    elseif (animationName == Door.kStateAnim[Door.kState.Unlock]) then    
    
        self:SetState(Door.kState.Closed) 
        
    end
    
    ScriptActor.OnAnimationComplete(self, animationName)
    
end
