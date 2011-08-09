// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Build.lua
//
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)
//
// A request for an entity to build something.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Build' (Entity)

Build.kMapName = "build"

Build.networkVars =
{    
    buildType           = "enum kTechType",
    buildTechId         = "integer",
    buildLocation       = "vector",
    buildOrientation    = "float",
    buildProgress       = "float"
    buildCompleted      = "boolean"
}

function Build:OnCreate()
    self.buildType          = Build.kBuildType
    self.buildTechId        = -1
    self.buildLocation      = Vector(0, 0, 0)
    self.buildOrientation   = 0 
    self.buildProgress      = 0
    self.buildCompleted     = false

    self.buildPlayerId      = Entity.invalidId
    self.buildEntity        = Entity.invalidId
end

function Build:Initialize(buildType, buildTechId, position, orientation, playerId)

    self.buildType = buildType
    self.buildTechId = buildTechId
    
    if orientation then
        self.buildOrientation = orientation
    end
    
    if position then
        self.buildLocation = position    
    end
    
    self.buildPlayer = playerId    
end

function Build:GetBuildType()
    return self.buildType
end

function Build:SetBuildType(buildType)
    self.buildType = buildType
end

function Build:GetTechId()
    return self.buildTechId
end

function Build:GetPlayerId()
    return self.buildPlayerId
end

function Build:GetLocation()

    local location = self.buildLocation        
    return location
    
end

function Build:SetLocation(position)
    if self.buildLocation == nil then
        self.buildLocation = Vector()
    end
    self.buildLocation = position
end

function Build:GetOrientation()
    return self.buildOrientation
end

function Build:GetBuildTime()
    local owner = Shared.GetEntity(self.buildPlayer)
    local buildNode = owner:GetTeam():GetTechTree():GetTechNode(self.buildTechId)
    
    if (buildNode ~= nil) then
        return buildNode.time
    end
    
    return 0
end

function Build:_SetBuildProgress(progress)
    progress = math.max(math.min(progress, 1), 0)
    
    if(progress ~= self.buildProgress) then
    
        self.buildProgress = progress
        
        local owner = Shared.GetEntity(self.buildPlayer)
        
        local buildNode = owner:GetTeam():GetTechTree():GetTechNode(self.buildTechId)
        if buildNode ~= nil then
        
            buildNode:SetResearchProgress(self.buildProgress)
            
            owner:GetTeam():GetTechTree():SetTechNodeChanged(buildNode)            
        end
        
    end
    
    if (self.buildProgess == 1) then
        self.buildCompleted = true
    end
end

function Build:_EvalBuildIsLegal(techId, origin, ignoreEntity, pickVec, radius)
    local legalBuildPosition = false
    local position = nil
    local attachEntity = nil

    if pickVec == nil then
    
        // When Drifters and MACs build, or untargeted build/buy actions, no pickVec. Trace from order point down to see
        // if they're trying to build on top of anything and if that's OK.
        local trace = Shared.TraceRay(Vector(origin.x, origin.y + .1, origin.z), Vector(origin.x, origin.y - .2, origin.z), PhysicsMask.CommanderBuild, EntityFilterOne(builderEntity))
        legalBuildPosition, position, attachEntity = GetIsBuildLegal(techId, trace.endPoint, radius, self, ignoreEntity)

    else
    
        // Make sure entity is near enough to attach class if required (snap to it as well)
        legalBuildPosition, position, attachEntity = GetIsBuildLegal(techId, origin, radius, self, ignoreEntity)
        
    end
    
    return legalBuildPosition, position, attachEntity
end

function Build:_AttemptToBuild(pickVec, ignoreEntity, radius)
    local legalBuildPosition = false
    local position = nil
    local attachEntity = nil
    
    legalBuildPosition, position, attachEntity = self:EvalBuildIsLegal(self:GetTechId(), self:GetLocation(), ignoreEntity, pickVec, radius)
    local owner = Shared.GetEntity(self:GetPlayerId())
    
    if legalBuildPosition and owner then
    
        local newEnt = CreateEntityForCommander(self:GetTechId(), position, owner)
        
        if newEnt ~= nil then
        
            // Use attach entity orientation 
            if attachEntity then
                orientation = attachEntity:GetAngles().yaw
            end
            
            // If orientation yaw specified, set it
            if orientation then
                local angles = Angles(0, self:GetOrientation(), 0)
                local coords = BuildCoordsFromDirection(angles:GetCoords().zAxis, newEnt:GetOrigin())
                newEnt:SetCoords(coords)                
            end
            
            local isAlien = false
            if newEnt.GetIsAlienStructure then
                isalien = newEnt:GetIsAlienStructure()
            end
            
            newEnt:TriggerEffects("commander_create", {isalien = isAlien})
            
            owner:TriggerEffects("commander_create_local")
            
            return true, newEnt:GetId()
                        
        end
        
    end
    
    return false, -1
end

function Build:GetIsComplete ()
    return (self.buildCompleted == true)
end

function Build:GetBuildEntity()
    return self.buildEntity
end

function Build:UpdateProgress ()

  // Builds do not have progress they should just complete
  // $AS FIXME: right now I am passing in nil and 4 to these values
  if (self:GetBuildType() == kTechType.Build) then
    self.buildCompleted, self.buildEntity = self:_AttemptToBuild(nil, 4, nil)
    return    
  end
  
  local timePassed = Shared.GetTime() - self.timeBuildStarted
        
  // Adjust for metabolize effects
  // $AS FIXME: I do not like this here REMOVE!!!!
  if self:GetTeam():GetTeamType() == kAlienTeamType then
    timePassed = GetAlienEvolveResearchTime(timePassed, self)
  end
        
  local buildTime = ConditionalValue(Shared.GetCheatsEnabled(), 2, self:GetBuildTime())
  self:_SetBuildProgress( timePassed / buildTime )
end

function CreateBuild(buildType, buildTechId, position, orientation, playerId)

    local newBuild = CreateEntity(Build.kMapName)
       
    newBuild:Initialize(buildType, buildTechId, position, tonumber(orientation), playerId)
    
    return newBuild
    
end

Shared.LinkClassToMap( "Build", Build.kMapName, Build.networkVars )