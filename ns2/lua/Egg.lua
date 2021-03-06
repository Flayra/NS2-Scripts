// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Egg.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//                  Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Thing that aliens spawn out of.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/EvolveMixin.lua")

class 'Egg' (Structure)

Egg.networkVars = {}

PrepareClassForMixin(Egg, InfestationMixin)
PrepareClassForMixin(Egg, EvolveMixin)

Egg.kMapName = "egg"

Egg.kModelName = PrecacheAsset("models/alien/egg/egg.model")
Egg.kMistEffect = PrecacheAsset("cinematics/alien/egg/mist.cinematic")
Egg.kSpawnEffect = PrecacheAsset("cinematics/alien/egg/spawn.cinematic")
Egg.kGlowEffect = PrecacheAsset("cinematics/alien/egg/glow.cinematic")

Egg.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/structures/egg/spawn")

Egg.kXExtents = 1
Egg.kYExtents = 1
Egg.kZExtents = 1

Egg.kHealth = kEggHealth
Egg.kArmor = kEggArmor

Egg.kThinkInterval = .5

function Egg:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)
    InitMixin(self, EvolveMixin)
    
    self:SetModel(Egg.kModelName)
    
end

function Egg:OnInit()

    InitMixin(self, InfestationMixin)
    
    Structure.OnInit(self)
    
    self.queuedPlayerId = nil
    
    if Server then
    
        self:SetNextThink(Egg.kThinkInterval)
    
        self:PlaySound(Egg.kSpawnSoundName)
        
        Shared.CreateEffect(nil, Egg.kMistEffect, nil, self:GetCoords())
        
    end
    
end

function Egg:GetBaseArmor()
    return Egg.kArmor
end

function Egg:GetArmorFullyUpgradedAmount()
    return 0
end

function Egg:GetIsAlienStructure()
    return true
end

function Egg:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then     
        techButtons = { kTechId.Gorge, kTechId.Lerk, kTechId.Fade, kTechId.Onos }      
    end
    
    return techButtons
    
end

function Egg:GetTechAllowed(techId, techNode, player)
    if (self.gestationTypeTechId ~= kTechId.Skulk) then
        return false
    end
    
    return false
end

function Egg:PerformAction(techNode, position)
    local techId = techNode:GetTechId()
    
    local success = false    
    if techId == kTechId.Gorge or 
       techId == kTechId.Lerk  or  
       techId == kTechId.Fade  or 
       techId == kTechId.Onos then
        
        healthScalar = self:GetHealth() / self:GetMaxHealth()
        armorScalar = self:GetArmor() / self:GetMaxArmor() 
    
        self:SetGestationData({techId}, kTechId.Skulk, healthScalar, armorScalar)
        success = true
    end
    return success
    
end
function Egg:GetDescription()
    local eggDescription = GetDisplayNameForTechId(self:GetTechId())       
    eggDescription = string.format("%s %s", GetDisplayNameForTechId(self.gestationTypeTechId), eggDescription)    
    return eggDescription
end

function Egg:QueueWaitingPlayer()

    // Get team
    local success = false
    
    if(self.queuedPlayerId == nil and (self:GetId() ~= Entity.invalidId)) then

        // Remove player from team spawn queue and add here
        local team = self:GetTeam()
        local playerToSpawn = team:GetOldestQueuedPlayer()

        if(playerToSpawn ~= nil) then
            
            team:RemovePlayerFromRespawnQueue(playerToSpawn)        
            self:SetQueuedPlayerId(playerToSpawn:GetId())

        end
        
    end
    
    return success

end

// Takes the queued player from this Egg and placed them back in the
// respawn queue to be spawned elsewhere.
function Egg:RequeuePlayer()

    if self.queuedPlayerId then
    
        local player = Shared.GetEntity(self.queuedPlayerId)
        // There are cases when the player is no longer valid such as
        // when Egg:OnDestroy() is called during server shutdown.
        if player then
            local team = self:GetTeam()
            ASSERT(team ~= nil)
            team:PutPlayerInRespawnQueue(player, Shared.GetTime())
        end
        
    end
    
    // Don't spawn player
    self:SetEggFree()

end

function Egg:OnKill(damage, attacker, doer, point, direction)

    self:RequeuePlayer()

    self:TriggerEffects("egg_death")        
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)
    
end

// Grab player out of respawn queue unless player passed in (for test framework)
function Egg:SpawnPlayer(player)

    local queuedPlayer = player
    
    if not queuedPlayer or self.queuedPlayerId ~= nil then
        queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
    end
    
    if queuedPlayer ~= nil then
    
        local queuedPlayer = player
        if not queuedPlayer then
            queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        end
    
        // Spawn player on top of egg
        local spawnOrigin = Vector(self:GetOrigin())
        
        local gestationClass = LookupTechData(self.gestationTypeTechId, kTechDataGestateName)

        local team = queuedPlayer:GetTeam()
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles(), gestationClass)                
        
        if success then
        
            self.queuedPlayerId = nil
            
            self:TriggerEffects("egg_death")
            
            DestroyEntity(self) 
            
            return true, player
            
        end
            
    end
    
    return false, nil

end

function Egg:GetCanIdle()
    return self:GetIsAlive()
end

function Egg:GetQueuedPlayerId()
    return self.queuedPlayerId
end

function Egg:SetQueuedPlayerId(playerId)

    self.queuedPlayerId = playerId
    self.timeQueuedPlayer = Shared.GetTime()
    
    local playerToSpawn = Shared.GetEntity(playerId)
    if playerToSpawn:isa("AlienSpectator") then
    
        playerToSpawn:SetEggId(self:GetId())
        success = true
        
    else
        Print("Egg:QueueWaitingPlayer(): queuing %s instead of AlienSpectator", playerToSpawn:GetClassName())
    end
    
    // set camera
    if Server then
    
        playerToSpawn.lastTargetId = playerToSpawn.specTargetId
        playerToSpawn.specTargetId = Entity.invalidId
        playerToSpawn.specMode = Spectator.kSpectatorMode.FreeLook
    
        if playerToSpawn.SetIsThirdPerson then
            playerToSpawn:SetIsThirdPerson(3)
        end
        
        if playerToSpawn.SetOrigin then
            playerToSpawn:SetOrigin(self:GetOrigin()) 
        end
    end
    
end

function Egg:SetEggFree()

    self.queuedPlayerId = nil
    self.timeQueuedPlayer = nil

end

function Egg:GetIsFree()
    return self.queuedPlayerId == nil
end

function Egg:GetTimeQueuedPlayer()
    return self.timeQueuedPlayer
end

function Egg:OverrideCheckvision()
    return false
end

if Server then

    // spawn the player automatically after some time. That's just a measure against AFK players
    function Egg:OnThink()
        
        if self:GetIsAlive() then
        
            Structure.OnThink(self)

            // If no player in queue
            if self.queuedPlayerId == nil then
                // Grab available player from team and put in queue
                self:QueueWaitingPlayer()
            end
            
        end
        
        self:SetNextThink(Egg.kThinkInterval)

    end

    // delete the egg to avoid invalid ID's and reset the player to spawn queue if one is occupying it
    function Egg:OnDestroy()

        self:ClearInfestation()
        local team = self:GetTeam()
        
        // Can be nil on map change / server shutdown.
        if team ~= nil then
            team:RemoveEgg(self:GetId())
        end
        
        // Just in case there is a player waiting to spawn in this egg.
        self:RequeuePlayer()
        
        Structure.OnDestroy(self)
        
    end

    // it's important to add the egg to the teams' table for cycling through them
    function Egg:OnConstructionComplete()

        Structure.OnConstructionComplete(self)
        local team = self:GetTeam()
        team:AddEgg(self:GetId())
        
        // disabled, it is now handled in AlienTeam.lua
        // self:SetNextThink(Egg.kThinkInterval)

    end
    
    function Egg:OnEntityChange(entityId, newEntityId)
    
        Structure.OnEntityChange(self, entityId, newEntityId)
        
        if self.queuedPlayerId == entityId then
            self:RequeuePlayer()
        end
    
    end
    
end

function Egg:OverrideGestationData()
     self:SetHealth(LookupTechData(self.gestationTypeTechId, kTechDataMaxHealth))
     
     local maxArmor = LookupTechData(self.gestationTypeTechId, kTechDataMaxArmor, self:GetMaxArmor())     
     self:SetMaxArmor(maxArmor)
     self:SetArmor(maxArmor)
end

Shared.LinkClassToMap("Egg", Egg.kMapName, Egg.networkVars)
