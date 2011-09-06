// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Gamerules.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScenarioHandler_Commands.lua")

class "ScenarioHandler"

ScenarioHandler.kStartTag = "--- SCENARIO START ---"
ScenarioHandler.kEndTag = "--- SCENARIO END ---"

function ScenarioHandler:Init()
    
    // aliens
    self.handlers = self:InitHandlers({}, kAlienTeamType, {
        Cyst = CystHandler(),
        MiniCyst = CystHandler(),
        Hydra = OrientedEntityHandler(),
        Whip = OrientedEntityHandler(),
        Crag = OrientedEntityHandler(),
        Hive = OrientedEntityHandler(),
        Harvester = OrientedEntityHandler(),
        Drifter = OrientedEntityHandler(),
    })
    // marines   
    self.handlers = self:InitHandlers(self.handlers, kMarineTeamType, {
        CommandStation = OrientedEntityHandler(),
        Sentry = OrientedEntityHandler(),
        Armory = OrientedEntityHandler(),
        ArmsLab = OrientedEntityHandler(),
        AdvancedArmory = OrientedEntityHandler(),
        Observatory = OrientedEntityHandler(),
        RoboticsFactory = OrientedEntityHandler(),
        PhaseGate = OrientedEntityHandler(),
        InfantryPortal = OrientedEntityHandler(),
        Extractor = OrientedEntityHandler(),
        MAC = OrientedEntityHandler()
    })

    return self
end

function ScenarioHandler:InitHandlers(result, teamType, dataTable)
    for name, value in pairs(dataTable) do
        value:Init(name, teamType)
        result[name] = value
    end
    return result
end


//
// checkpoint the state of the game. Only entites created AFTER the checkpoint will be saved. 
//
function ScenarioHandler:Checkpoint()
    self.excludeTable = {}
    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("ScriptActor")) do
        self.excludeTable["" .. entity:GetId()] = true
    end
end


//
// Save the current scenario
// This just dumps formatted strings for all structures and non-building-owned Cysts that allows
// the Load() method to easily reconstruct them
// The data is written to the server log. The user should just cut out the chunk of the log containing the
// scenario and put in on a webserver
//
function ScenarioHandler:Save()
    if not self.excludeTable then
        Log("NO CHECKPOINT HAS BEEN MADE - ALL ENTITIES WILL BE SAVED, INCLUDING MAP-CREATED ENTITIES!")
        Log("Use scencp to checkpoint the current state of the game")
    end
    Shared.Message(ScenarioHandler.kStartTag)
    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("ScriptActor")) do
        local cname = entity:GetClassName()
        local excluded = self.excludeTable and self.excludeTable["" .. entity:GetId()]
        local handler = self.handlers[cname]
        local accepted = handler and handler:Accept(entity)
        if not excluded and accepted then
            Shared.Message(string.format("%s|%s", cname,handler:Save(entity)))
        end
    end
    Shared.Message(ScenarioHandler.kEndTag)    
end

function ScenarioHandler:Load(data)
    Shared.Message("LOAD: ")
    local startTagFound, endTagFound = false, false
    local lines = data:gmatch("[^\n]+")
    // load in two stages; use the second stage to resolve references to other entities
    local createdEntities = {}
    for line in lines do
        if line == ScenarioHandler.kStartTag then
            startTagFound = true
        elseif line == ScenarioHandler.kEndTag then
            endTagFound = true
            break
        else 
            local args = line:gmatch("[^|]+")
            local cname = args()
            if self.handlers[cname] then
                table.insert(createdEntities, self.handlers[cname]:Load(args, cname))
            end
        end
    end
    // Resolve stage
    for _,entity in ipairs(createdEntities) do
        self.handlers[entity:GetClassName()]:Resolve(entity)
        Log("Loaded %s", entity)
    end
    
    // update the infestations masks as otherwise whips will unroot and stuff will take damage
    UpdateInfestationMasks()
    
    Shared.Message("END LOAD")
end

class "ScenarioEntityHandler"

function ScenarioEntityHandler:Init(name, teamType)
    self.teamType = teamType
    self.name = name
    self.techId = kTechId[self.name]
    if not self.techId then
        Log("Unable to determine techId for %s", self.name)
    end
    return self
end

// return true if this entity should be accepted for saving
function ScenarioEntityHandler:Accept(entity)
    return true
end

function ScenarioEntityHandler:Resolve(entity)
    // default do nothing
end

function ScenarioEntityHandler:WriteVector(vec)
    return string.format("%f,%f,%f", vec.x, vec.y, vec.z)
end

function ScenarioEntityHandler:ReadVector(text)
    local p = text:gmatch("[^, ]+")
    local x,y,z = tonumber(p()),tonumber(p()),tonumber(p())
    return Vector(x,y,z)
end

function ScenarioEntityHandler:WriteAngles(angles)
    return string.format("%f,%f,%f", angles.pitch, angles.yaw, angles.roll)
end

function ScenarioEntityHandler:ReadAngles(text)
    local p = text:gmatch("[^, ]+")
    local pitch,yaw,roll = tonumber(p()),tonumber(p()),tonumber(p())
    return Angles(pitch,yaw,roll)
end

//
// Oriented entity handlers have an origin and an angles
//
class "OrientedEntityHandler" (ScenarioEntityHandler)

function OrientedEntityHandler:Save(entity)
    // re-offset the extra spawn height added to it... otherwise our hives will stick up in the roof, and all other things will float
    // 5cm off the ground..
    local spawnOffset = LookupTechData(self.techId, kTechDataSpawnHeightOffset, .05)
    local origin = entity:GetOrigin() - Vector(0, spawnOffset, 0)
    return self:WriteVector(origin) .. "|" .. self:WriteAngles(entity:GetAngles())
end

function OrientedEntityHandler:Load(args, classname)
    local origin = self:ReadVector(args())
    local angles = self:ReadAngles(args())

    // Log("For %s(%s), team %s at %s, %s", classname, self.techId, self.teamType, origin, angles)
    local result = self:Create(origin)
    result:SetAngles(angles)
    // if we can complete the construction, do so
    if result.SetConstructionComplete then
        result:SetConstructionComplete()
    end
    // special hack for cyst/hives; spawn infestations and maximize it right away
    if result:isa("Hive") or result:isa("Cyst") then
        // spawn the infestations
        result:SpawnInfestation()
        // and maximize the size
        local inf = Shared.GetEntity(result.infestationId)
        if inf then
            inf.radius = inf.maxRadius
            inf:AddToInfestationMap()
        end        
    end
    if result:isa("Whip") then
        result.mode = Whip.kMode.Rooted
        result.desiredMode = Whip.kMode.Rooted
    end
    // fix to spread out the target acquisition for sentries; randomize lastTargetAcquisitionTime
    if result:isa("Sentry") then
        // buildtime means that we need to add a hefty offset to timeOLT
        result.timeOfLastTargetAcquisition = Shared.GetTime() + 5 + math.random()
    end

    // spread out the thinktime for hydras
    if result:isa("Hydra") then
        result:SetNextThink(5 + math.random() * Hydra.kThinkInterval)
    end
    
    if result:isa("Drifter") or result:isa("MAC") then
        // *sigh* - positioning an entity in its first OnUpdate? Really?
        result.justSpawned = false
    end
    
    
    
    return result
end


function OrientedEntityHandler:Create(origin)
    return CreateEntityForTeam( self.techId, origin, self.teamType, nil )
end 

//
// Special case Cysts. They have a parent and needs to initalize the track
//
class "CystHandler" (OrientedEntityHandler)

// use the LOCATION of the parent to identify it across saves/loads
function CystHandler:Save(entity)
    local parent = Shared.GetEntity(entity.parentId)
    ASSERT(parent)
    local parentLoc = parent:GetOrigin()
    return string.format("%s|%s", OrientedEntityHandler.Save(self, entity), self:WriteVector(parentLoc))
end

// read off and save the parent id until the resolve phase
function CystHandler:Load(args, classname)
    local cyst = OrientedEntityHandler.Load(self, args, classname)
    cyst.savedParentLoc = self:ReadVector(args())
    return cyst
end

// resolve the parent and make a track from it to us
function CystHandler:Resolve(cyst)

    local targets = GetEntitiesWithinRange("Entity", cyst.savedParentLoc, 0.01)
    local numTargets = #targets

    // Filter out anything that's not a valid parent for a cyst (could be map blips, etc.)
    local parent = nil
    for i=1,numTargets do
        local target = targets[i]
        if target:isa("Hive") or target:isa("Cyst") then
            parent = target
        end
    end
    ASSERT(parent ~= nil)

    cyst.savedParentLoc = nil // remove the variable
    
    local path = CreateBetween(parent:GetOrigin(), cyst:GetOrigin())
    if path then
        cyst:SetCystParent(parent)
    end
end


// create the singleton instance
ScenarioHandler.instance = ScenarioHandler():Init()