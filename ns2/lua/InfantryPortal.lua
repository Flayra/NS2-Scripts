// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfantryPortal.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'InfantryPortal' (Structure)

InfantryPortal.kMapName = "infantryportal"

InfantryPortal.kModelName = PrecacheAsset("models/marine/infantry_portal/infantry_portal.model")

InfantryPortal.kAnimSpinStart = "spin_start"
InfantryPortal.kAnimSpinContinuous = "spin"

InfantryPortal.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/infantry_portal_under_attack")

InfantryPortal.kLoopSound = PrecacheAsset("sound/ns2.fev/marine/structures/infantry_portal_active")

InfantryPortal.kSquadSpawnFailureSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn_fail")
InfantryPortal.kSquadSpawnSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn")

InfantryPortal.kIdleLightEffect = PrecacheAsset("cinematics/marine/infantryportal/idle_light.cinematic")

InfantryPortal.kTransponderUseTime = .5
InfantryPortal.kThinkInterval = 0.25
InfantryPortal.kTransponderPointValue = 15
InfantryPortal.kLoginAttachPoint = "keypad"

function InfantryPortal:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function InfantryPortal:OnInit()

    Structure.OnInit(self)

    self:SetModel(InfantryPortal.kModelName)
    
    self.queuedPlayerId = nil
    
    // For both client and server
    self:SetNextThink(InfantryPortal.kThinkInterval)
    
end

function InfantryPortal:OnDestroy()

    Structure.OnDestroy(self)
    
    // Put the player back in queue if there was one hoping to spawn at this now destroyed IP.
    self:RequeuePlayer()

end

function InfantryPortal:GetRequiresPower()
    return true
end

function InfantryPortal:GetUseAttachPoint()
    if self:GetIsBuilt() then
        return InfantryPortal.kLoginAttachPoint
    end
    return ""
end

function InfantryPortal:QueueWaitingPlayer()

    if(self:GetIsAlive() and self.queuedPlayerId == nil) then

        // Remove player from team spawn queue and add here
        local team = self:GetTeam()
        local playerToSpawn = team:GetOldestQueuedPlayer()

        if(playerToSpawn ~= nil) then
            
            team:RemovePlayerFromRespawnQueue(playerToSpawn)
            
            self.queuedPlayerId = playerToSpawn:GetId()
            self.queuedPlayerStartTime = Shared.GetTime()

            self:StartSpinning()            
            
            playerToSpawn:AddTooltipOncePer("SPAWNING_PORTAL_TOOLTIP") 
            
        end
        
    end

end

function InfantryPortal:GetSpawnTime()
    return kMarineRespawnTime
end

function InfantryPortal:OnReplace(newStructure)

    Structure.OnReplace(self, newStructure)
    
    newStructure.queuedPlayerId = self.queuedPlayerId
    
    newStructure:SetNextThink(InfantryPortal.kThinkInterval)

end

if(Server) then

function InfantryPortal:OnUse(player, elapsedTime, useAttachPoint, usePoint)
    
    if(not Structure.OnUse(self, player, elapsedTime, useAttachPoint, usePoint)) then

        local success = false
    
        if(self:GetIsBuilt() and self:GetTeamNumber() == player:GetTeamNumber()) then
        
            // Also functions as "transponder" which allows marines to spawn with their squad by using IP
            if self:GetTechId() == kTechId.InfantryPortalTransponder /*and useAttachPoint*/ then

                local currentTime = Shared.GetTime()
                
                if(self.timeOfLastUse == nil or currentTime > self.timeOfLastUse + InfantryPortal.kTransponderUseTime) then
            
                    if player:SpawnInSquad() then
                    
                        // Play squad spawn sound where you end up
                        Shared.PlayWorldSound(nil, InfantryPortal.kSquadSpawnSound, nil, self:GetOrigin())
                        
                        success = true
                        
                    end
                    
                    self.timeOfLastUse = currentTime
                    
                end
                
                // Play invalid sound
                if not success then
                    Shared.PlayWorldSound(nil, InfantryPortal.kSquadSpawnFailureSound, nil, self:GetOrigin())
                end
                
            end
        
        end
        
        return success
        
    else
        return true
    end
    
end

end

function InfantryPortal:SpawnTimeElapsed()

    local elapsed = false
    
    if self.queuedPlayerId then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        if queuedPlayer then
            elapsed = (Shared.GetTime() >= (self.queuedPlayerStartTime + self:GetSpawnTime()))
        else
            self.queuedPlayerId = nil
            self.queuedPlayerStartTime = nil
        end        
    end
    
    return elapsed

end

function InfantryPortal:SpinUpTimeElapsed()

    local elapsed = false
    
    if(self.timeSpinUpStarted ~= nil) then
    
        elapsed = (Shared.GetTime() > self.timeSpinUpStarted + self:GetAnimationLength(InfantryPortal.kAnimSpinStart))
        
    end
    
    return elapsed
    
end

// Spawn player on top of IP. Returns true if it was able to, false if way was blocked.
function InfantryPortal:SpawnPlayer()

    if(self.queuedPlayerId ~= nil) then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        local team = queuedPlayer:GetTeam()
    
        // Spawn player on top of IP
        local spawnOrigin = Vector(self:GetOrigin())
        
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, self:GetAngles())
        if(success) then
        
            self.queuedPlayerId = nil
            self.queuedPlayerStartTime = nil
            
            spawnOrigin.y = spawnOrigin.y + player:GetExtents().y
            player:SetOrigin(spawnOrigin)       

            self:TriggerEffects("infantry_portal_spawn")            
            
            return true
            
        end
            
    end
    
    return false

end

// Takes the queued player from this IP and placed them back in the
// respawn queue to be spawned elsewhere.
function InfantryPortal:RequeuePlayer()

    if self.queuedPlayerId then
        local team = self:GetTeam()
        team:PutPlayerInRespawnQueue(Shared.GetEntity(self.queuedPlayerId), Shared.GetTime())
    end
    
    // Don't spawn player
    self.queuedPlayerId = nil
    self.queuedPlayerStartTime = nil

end

if Server then
function InfantryPortal:OnEntityChange(entityId, newEntityId)
    
    Structure.OnEntityChange(self, entityId, newEntityId)
    
    if(self.queuedPlayerId == entityId) then
    
        // Player left or was replaced, either way 
        // they're not in the queue anymore
        self.queuedPlayerId = nil
        self.queuedPlayerStartTime = nil
        
    end
    
end
end

function InfantryPortal:OnKill(damage, attacker, doer, point, direction)
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)

    // Put the player back in queue if there was one hoping to spawn at this now dead IP.
    self:RequeuePlayer()
    
end

function InfantryPortal:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:PlaySound(InfantryPortal.kLoopSound)
    
end

function InfantryPortal:OnThink()

    Structure.OnThink(self)
    
    // If built and active 
    if Server then
    
        if self:GetIsBuilt() and self:GetIsActive() then
        
            // If no player in queue
            if(self.queuedPlayerId == nil) then
            
                // Grab available player from team and put in queue
                self:QueueWaitingPlayer()
               
            // else if time has elapsed to spawn player
            elseif(self:SpawnTimeElapsed()) then
            
                self:SpawnPlayer()
                //self:SetAnimation(InfantryPortal.kAnimSpinStop)
                self:StopSpinning()
                self.timeSpinUpStarted = nil
                
            elseif(self:SpinUpTimeElapsed()) then
            
                self:SetAnimation(InfantryPortal.kAnimSpinContinuous)
                self.timeSpinUpStarted = nil
                
            end

            // Stop spinning if player left server, switched teams, etc.            
            if self.queuedPlayerId == nil then
            
                self:StopSpinning()
                
            end
            
        end
        
    end
    
    self:SetNextThink(InfantryPortal.kThinkInterval)

end

function InfantryPortal:StopSpinning()

    self:TriggerEffects("infantry_portal_stop_spin")
    
    self:SetEffectsActive(false)
    
    self.timeSpinUpStarted = nil
        
end

function InfantryPortal:StartSpinning()

    if self.timeSpinUpStarted == nil then
    
        self:TriggerEffects("infantry_portal_start_spin")
        
        self:SetEffectsActive(true)
        
        self.timeSpinUpStarted = Shared.GetTime()
        
    end
    
end

function InfantryPortal:GetCanIdle()
    return (self.timeSpinUpStarted == nil)
end

function InfantryPortal:OnPoweredChange(newPoweredState)

    Structure.OnPoweredChange(self, newPoweredState)
    
    if not self.powered then
    
        self:StopSpinning()
        // Put the player back in queue if there was one hoping to spawn at this IP.
        self:RequeuePlayer()
        
    elseif (self.queuedPlayerId ~= nil) then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        
        if queuedPlayer then
        
            queuedPlayer:SetRespawnQueueEntryTime(Shared.GetTime())
            
            self:StartSpinning()
            
        end
        
    end
    
end

function InfantryPortal:GetDamagedAlertId()
    return kTechId.MarineAlertInfantryPortalUnderAttack
end


Shared.LinkClassToMap("InfantryPortal", InfantryPortal.kMapName)