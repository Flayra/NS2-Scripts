// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


// send out an impulse to maintain infestations every 10 seconds
Hive.kImpulseInterval = 10 

function Hive:GetTeamType()
    return kAlienTeamType
end

// Aliens log in to hive instantly
function Hive:GetLoginTime()
    return 0
end

function Hive:OnCreate()

    CommandStructure.OnCreate(self)
    
    self.upgradeTechId = kTechId.None
    
    self:SetTechId(kTechId.Hive)
    
    self.maxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth)
    self.health = kHiveHealth
    
    self:SetModel(Hive.kModelName)
    
    self.cystChildren = {}
    
    self.lastImpulseFireTime = Shared.GetTime()
end

function Hive:OnDestroy()
    
    self:ClearInfestation()
    
    CommandStructure.OnDestroy(self)

end

// Hives building can't be sped up
function Hive:GetCanConstruct(player)
    return false
end

function Hive:OnThink()

    CommandStructure.OnThink(self)   
    
    self:UpdateEggs()
    
    self:UpdateInfestation()
    
    self:UpdateHealing()
    
    self:FireImpulses()
    
end

function Hive:GetNumEggs()

    local numEggs = 0
    local eggs = GetEntitiesForTeam("Egg", self:GetTeamNumber())    
    for index, egg in ipairs(eggs) do
        if egg:GetLocationName() == self:GetLocationName() then
            numEggs = numEggs + 1
        end
    end
    
    return numEggs
end

function Hive:GetNumDesiredEggs()
    return Hive.kHiveNumEggs
end

// Find random spot near hive that we could put an egg. Allow spawn points that are on the other side of walls
// but pathable. Returns point on ground.
function Hive:FindPotentialEggSpawn(origin, minRange, maxRange)

    PROFILE("Hive:FindPotentialEggSpawn")

    local kBigUpVector = Vector(0, 1000, 0)
    local extents = LookupTechData(kTechId.Egg, kTechDataMaxExtents)
    local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)

    // Find random spot within range, using random orientation (0 to -45 degrees)
    local randomRange = minRange + math.random() * (maxRange - minRange)
    local randomRadians = math.random() * math.pi * 2
    local randomVerticalRadians = Math.Radians(- math.random() * 45) 
    local randomPoint = Vector( origin.x + randomRange * math.cos(randomRadians), 
                                origin.y + randomRange * math.sin(randomVerticalRadians), 
                                origin.z + randomRange * math.sin(randomRadians))

    // Trace random point to ceiling and then floor, to see if it's inside the world. 
    local pointToUse = nil
    local trace = Shared.TraceCapsule(  randomPoint, randomPoint + kBigUpVector, 
                                        capsuleRadius, capsuleHeight, PhysicsMask.FilterAll, EntityFilterOne(self))
                                        
    if trace.fraction < 1 then
    
        // Trace capsule from ceiling point to ground, making sure we're not on something like a player or structure
        trace = Shared.TraceCapsule(    trace.endPoint, trace.endPoint - kBigUpVector, 
                                        capsuleRadius, capsuleHeight, PhysicsMask.FilterAll, EntityFilterOne(self))
        local success = false
        if trace.fraction < 1 and (trace.entity == nil or not trace.entity:isa("ScriptActor")) then
        
            success = true
            pointToUse = trace.endPoint
            
        end
        
    end
    
    // Otherwise trace from origin to random point and use the first collision point
    if not pointToUse then
    
        trace = Shared.TraceCapsule(    origin, randomPoint, 
                                        capsuleRadius, capsuleHeight, PhysicsMask.FilterAll, EntityFilterOne(self))
        
        if (trace.entity == nil or not trace.entity:isa("ScriptActor")) then                                
        
            pointToUse = trace.endPoint

            // Drop point down to ground if we didn't hit anything
            if trace.fraction == 1 then
            
                trace = Shared.TraceCapsule(    pointToUse, pointToUse - kBigUpVector, 
                                                capsuleRadius, capsuleHeight, PhysicsMask.FilterAll, EntityFilterOne(self))
            
                if trace.fraction ~= 1 then
                
                    pointToUse = trace.endPoint
                    
                end
                
            end
            
        end
        
    end
    
    if pointToUse then
    
        return pointToUse - Vector(0, capsuleHeight/2 + capsuleRadius, 0)
        
    end
        
    return nil
    
end

function Hive:CalculateRandomEggSpawn()

    PROFILE("Hive:CalculateRandomEggSpawn")
    
    // Pick random spot on ground within range
    for i = 0, 20 do
    
        local possibleSpawn= self:FindPotentialEggSpawn(self:GetModelOrigin(), Hive.kEggMinRange, Hive.kEggMaxRange)
        if possibleSpawn then

            // See if it's a valid egg spot
            if GetIsValidEggPlacement(possibleSpawn, false) then
    
                return possibleSpawn
                
            end
                
        end
        
    end

    return nil
    
end

// Make sure there's enough room here for an egg
function Hive:SpawnEgg()

    PROFILE("Hive:SpawnEgg")
    
    for index = 1, 15 do
    
        local position = table.random(self.eggSpawnPoints)
        
        if position and GetIsValidEggPlacement(position, true) then

            local egg = CreateEntity(Egg.kMapName, position, self:GetTeamNumber())
            
            if egg ~= nil then 
                
                // Randomize starting angles
                local angles = self:GetAngles()
                angles.yaw = math.random() * math.pi * 2
                egg:SetAngles(angles)
                
                // To make sure physics model is updated without waiting a tick
                egg:UpdatePhysicsModel()
            
                self.timeOfLastEgg = Shared.GetTime()
                
                return egg
                
            end

        end
        
    end
    
    return nil
    
end

function Hive:GetEggSpawnTime()

    // Compute spawn time dynamically, depending on team size
    local numPlayers = Clamp(self:GetTeam():GetNumPlayers(), 1, kMaxPlayers)
    
    // The team should have spawn equilibrium when players live at least this long.
    // This should be higher than normal to account for the transition from early
    // game to mid/late game (where there are multiple hives).
    local eggSpawnTime = Clamp(kAlienPlayerSpawnTime / numPlayers, kAlienEggMinSpawnTime, kAlienEggMaxSpawnTime)    
    
    if Shared.GetDevMode() then
        eggSpawnTime = 3
    end
    
    return eggSpawnTime
    
end

function Hive:GenerateEggSpawns()

    PROFILE("Hive:GenerateEggSpawns")
    
    self.eggSpawnPoints = {}
    
    // Pre-generate many spawns
    for index = 1, 75 do
    
        local spawnPoint = self:CalculateRandomEggSpawn()
        
        if spawnPoint ~= nil then
        
            table.insert(self.eggSpawnPoints, spawnPoint)
            
        end
        
    end
    
    if table.count(self.eggSpawnPoints) < Hive.kHiveNumEggs then
        Print("Hive in location \"%s\" only generated %d egg spawns (needs %d). Make room more open.", GetLocationForPoint(self:GetModelOrigin()), table.count(self.eggSpawnPoints), Hive.kHiveNumEggs)
    end
        
end

function Hive:GetCanSpawnEgg()

    local canSpawnEgg = false
    
    if self:GetIsBuilt() then
    
        if (Shared.GetTime() > (self.timeOfLastEgg + self:GetEggSpawnTime())) then
        
            canSpawnEgg = true
            
        end
        
    end
    
    return canSpawnEgg
    
end

/*
function Hive:SpawnEggs()

    local numEggsSpawned = 0
    
    while ((self:GetNumEggs() < self:GetNumDesiredEggs())) do
    
        if self:SpawnEgg() ~= nil then
            numEggsSpawned = numEggsSpawned + 1
        else
            break
        end
        
    end
    
    return numEggsSpawned
    
end
*/

// Create pheromone marker
function Hive:OverrideTechTreeAction(techNode, position, orientation, commander, trace)

    local success = false
    local keepProcessing = false
    
    if techNode:GetIsSpecial() then
    
        local pheromone = CreatePheromone(techNode:GetTechId(), position, commander)
        success = (pheromone ~= nil)
        
    end
    
    return success, keepProcessing
    
end

function Hive:OnOverrideSpawnInfestation(infestation)
    infestation.hostAlive = true
    infestation:SetMaxRadius(kHiveInfestationRadius)
end

// Spawn initial eggs and infestation
function Hive:SpawnInitial()
    //self:SpawnEggs()
    self:SpawnInitialInfestation()
end

// Spawn a new egg around the hive if needed. Returns true if it did.
function Hive:UpdateEggs()

    local createdEgg = false

    // Count number of eggs nearby and see if we need to create more, but only every so often
    if self:GetCanSpawnEgg() and (self:GetNumEggs() < self:GetNumDesiredEggs()) then
    
        createdEgg = (self:SpawnEgg() ~= nil)
        
    end 

    // So we don't create a new egg instantly when an egg is killed (still takes build time)
    if self:GetNumEggs() == self:GetNumDesiredEggs() then
        self.timeOfLastEgg = Shared.GetTime()
    end   

    return createdEgg
    
end

function Hive:UpdateHealing()

    if self:GetIsBuilt() then
    
        if self.timeOfLastHeal == nil or Shared.GetTime() > (self.timeOfLastHeal + Hive.kHealthUpdateTime) then
            
            local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
            
            for index, player in ipairs(players) do
            
                if player:GetIsAlive() and ((player:GetOrigin() - self:GetOrigin()):GetLength() < Hive.kHealRadius) then
                
                    player:AddHealth( player:GetMaxHealth() * Hive.kHealthPercentage, true )
                
                end
                
            end
            
            self.timeOfLastHeal = Shared.GetTime()
            
        end
        
    end
    
end

function Hive:GetDamagedAlertId()

    // Trigger "hive dying" on less than 40% health, otherwise trigger "hive under attack" alert every so often
    if self:GetHealth() / self:GetMaxHealth() < Hive.kHiveDyingThreshold then
        return kTechId.AlienAlertHiveDying
    else
        return kTechId.AlienAlertHiveUnderAttack
    end
    
end

function Hive:OnTakeDamage(damage, attacker, doer, point)

    CommandStructure.OnTakeDamage(self, damage, attacker, doer, point)
    
    if(self:GetIsAlive()) then

        // Play freaky sound for team mates
        local team = self:GetTeam()
        team:PlayPrivateTeamSound(Hive.kWoundAlienSound, self:GetModelOrigin())
        
        // ...and a different sound for enemies
        local enemyTeamNumber = GetEnemyTeamNumber(team:GetTeamNumber())    
        local enemyTeam = GetGamerules():GetTeam(enemyTeamNumber)
        if enemyTeam ~= nil then
            enemyTeam:PlayPrivateTeamSound(Hive.kWoundSound, self:GetModelOrigin())
        end
        
        // Trigger alert for Commander 
        team:TriggerAlert(kTechId.AlienAlertHiveUnderAttack, self)
        
    end
    
end

function Hive:OnConstructionComplete()

    CommandStructure.OnConstructionComplete(self)
    
    // Play special tech point animation at same time so it appears that we bash through it
    local attachedTechPoint = self:GetAttached()
    if attachedTechPoint then
        attachedTechPoint:SetAnimation(TechPoint.kAlienAnim, true)
    else
        Print("Hive not attached to tech point")
    end
    
    self:GetTeam():TriggerAlert(kTechId.AlienAlertHiveComplete, self)    
    
    self:SpawnInfestation()
end

function Hive:GetIsPlayerValidForCommander(player)
    return player ~= nil and player:isa("Alien") and player:GetTeamNumber() == self:GetTeamNumber()
end

function Hive:GetCommanderClassName()
    return AlienCommander.kMapName   
end

function Hive:LoginPlayer(player)

    local commander = CommandStructure.LoginPlayer(self, player)

    if not self.hasBeenOccupied then
    
        // Create some initial Drifters
        for i = 1, kInitialDrifters do
            local drifter = CreateEntity(Drifter.kMapName, self:GetOrigin(), self:GetTeamNumber())
            drifter:SetOwner(commander)
        end
        
        self.hasBeenOccupied = true

    end  

end

function Hive:SetSupportingUpgradeTechId(techId)
    self.upgradeTechId = techId
end


function Hive:FireImpulses() 

    local now = Shared.GetTime()
    if now - self.lastImpulseFireTime > Hive.kImpulseInterval then
        local removals = {}
        for key,id in pairs(self.cystChildren) do
            local child = Shared.GetEntity(id)
            if child == nil then
                removals[key] = true
            else
                child:TriggerImpulse(now)
            end
        end
        for key,_ in pairs(removals) do
            self.cystChildren[key] = nil
        end
        self.lastImpulseFireTime = now
    end
end

function Hive:AddChildCyst(child)
    self.cystChildren["" .. child:GetId()] = child:GetId()
end

