// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScriptActor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Base class for all visible entities in NS2. Players, weapons, structures, etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Globals.lua")
Script.Load("lua/BlendedActor.lua")
Script.Load("lua/MakeMapBlipMixin.lua")

class 'ScriptActor' (BlendedActor)

ScriptActor.kMapName = "scriptactor"

if (Server) then
    Script.Load("lua/ScriptActor_Server.lua", true)
else
    Script.Load("lua/ScriptActor_Client.lua", true)
end

local networkVars = 
{   
    // Team type (marine, alien, neutral)
    teamType                    = string.format("integer (0 to %d)", kRandomTeamType),
    
    // Never set this directly, call SetTeamNumber()
    teamNumber                  = string.format("integer (-1 to %d)", kSpectatorIndex),
    
    // Whether this entity is in sight of the enemy team
    sighted                     = "boolean",
            
    // The technology this object represents
    techId                      = string.format("integer (0 to %d)", kTechIdMax),
    
    // Entity that is attached to us (if we're a tech point, resource nozzle, etc.)
    attachedId                  = "entityid",
    
    // Player that "owns" this unit. Shouldn't be set for players. Gets credit
    // for kills.
    owner                       = "entityid",
    
    // Id used to look up precached string representing room location ("Marine Start")
    locationId                  = "integer",
    
    // pathing flags
    pathingFlags                = "integer"
    
}

ScriptActor.kMass = 100

// Called right after an entity is created on the client or server. This happens through Server.CreateEntity, 
// or when a server-created object is propagated to client. 
function ScriptActor:OnCreate()    

    BlendedActor.OnCreate(self)

    self.teamType = kNeutralTeamType
    
    self.sighted = false
    
    self.teamNumber = -1

    self.techId = LookupTechId(self:GetMapName(), kTechDataMapName, kTechId.None)
    
    self.attachedId = Entity.invalidId
    
    self.ownerPlayerId = Entity.invalidId
    // Stores all the entities that are owned by this ScriptActor.
    self.ownedEntities = { }
    
    self.locationId = 0
    
    self.pathingFlags = 0
    
    if(Server) then
        
        self.selectedCount   = 0
        self.hotgroupedCount = 0
    
        if not self:GetIsMapEntity() then
            self:SetTeamNumber(kTeamReadyRoom)
        end
        
    end
    
    // Remember if we've called OnInit() for entities that are propagated to the client
    if(Client) then
    
        self.clientInitedOnSynch = false
        
    end
    
end

// Called after OnCreate and before OnInit, if entity has been loaded from the map. Use it to 
// read class values from the editor_setup file. Convert parameters from strings to numbers. 
// It's safe to call Shared.PrecacheModel and Shared.PrecacheSound in this function. Team hasn't 
// been set.
function ScriptActor:OnLoad()

    BlendedActor.OnLoad(self)
    
    local teamNumber = GetAndCheckValue(self.teamNumber, 0, 3, "teamNumber", 0)
    
    self:SetTeamNumber(teamNumber)
    
end

// Called when entity is created via CreateEntity(), after OnCreate(). Team number and origin will be set properly before it's called.
// Also called on client each time the entity gets created locally, due to proximity. This won't be called on the server for 
// pre-placed map entities. Generally reset-type functionality will want to be placed in here and then called inside :Reset().
function ScriptActor:OnInit()

    local techId = self:GetTechId()
    
    if techId ~= kTechId.None then
    
        local modelName = LookupTechData(techId, kTechDataModel, nil)
        if modelName ~= nil and modelName ~= "" then
        
            self:SetModel(modelName)

        // Don't emit error message if they specified no model a
        elseif modelName ~= "" then
        
            Print("%s:OnInit() (ScriptActor): Couldn't find model name for techId %d (%s).", self:GetClassName(), techId, EnumToString(kTechId, techId))
            
        end
        
    end
    
    BlendedActor.OnInit(self)
    
    if Server then
        InitMixin(self, MakeMapBlipMixin)
    end

end

function ScriptActor:ComputeLocation()

    if Server then
    
        self:SetLocationName(GetLocationForPoint(self:GetOrigin()), true)

    end

end

// Called when the game ends and a new game begins (or when the reset command is typed in console).
function ScriptActor:Reset()
    self:ComputeLocation()  
end

function ScriptActor:SetOrigin(origin)
    BlendedActor.SetOrigin(self, origin)
    self:ComputeLocation()
end

function ScriptActor:GetTeamType()
    return self.teamType
end

function ScriptActor:GetTeamNumber()
    return self.teamNumber
end

function ScriptActor:GetCanSeeEntity(targetEntity)
    return GetCanSeeEntity(self, targetEntity)
end

function ScriptActor:GetDamageType()
    return LookupTechData(self:GetTechId(), kTechDataDamageType, kDamageType.Normal)
end

// Return tech ids that represent research or actions for this entity in specified menu. Parameter is kTechId.RootMenu for
// default menu or a entity-defined menu id for a sub-menu. Return nil if this actor doesn't recognize a menu of that type.
// Used for drawing icons in selection menu and also for verifying which actions are valid for entities and when (ie, when
// a ARC can siege, or when a unit has enough energy to perform an action, etc.)
// Return list of 8 tech ids, represnting the 2nd and 3rd row of the 4x3 build icons.
function ScriptActor:GetTechButtons(techId)
    return nil
end

// Return techId that is the technology this entity represents. This is used to choose an icon to display to represent
// this entity and also to lookup max health, spawn heights, etc.
function ScriptActor:GetTechId()
    return self.techId
end

function ScriptActor:GetCost()
    return LookupTechData(self:GetTechId(), kTechDataCostKey, 0)
end

function ScriptActor:SetTechId(techId)
    self.techId = techId
    return true
end

// Allows entities to specify whether they can perform a specific research, activation, buy action, etc. If entity is
// busy deploying, researching, etc. it can return false. Pass in the player who is would be buying the tech.
// techNode could be nil for activations that aren't added to tech tree.
function ScriptActor:GetTechAllowed(techId, techNode, player)

    if(techNode == nil) then
        return false
    end

    // Allow upgrades and energy builds when we're not researching/building something else
    if techNode:GetIsUpgrade() then
    
        // Let child override this
        return self:GetUpgradeTechAllowed(techId) and (techNode:GetCost() <= player:GetTeamResources())
        
    elseif techNode:GetIsEnergyManufacture() or techNode:GetIsEnergyBuild() then
        
        local energy = 0
        if self.GetEnergy then
            energy = self:GetEnergy()
        end
        
        return self:GetUpgradeTechAllowed(techId) and (techNode:GetCost() <= energy)
    
    // If tech is research
    elseif(techNode:GetIsResearch()) then
    
        // Return false if we're researching, or if tech is being researched
        return self:GetResearchTechAllowed(techNode) and (techNode:GetCost() <= player:GetTeamResources())

    // If tech is action or buy action
    elseif(techNode:GetIsAction() or techNode:GetIsBuy()) then
    
        // Return false if we don't have enough resources
        if(player:GetResources() < techNode:GetCost()) then
            return false
        end
        
    // If tech is activation
    elseif(techNode:GetIsActivation()) then
    
        // Return false if structure doesn't have enough energy
        local energy = 0
        if self.GetEnergy then
            energy = self:GetEnergy()
        end

        if techNode:GetCost() <= energy then
            return self:GetActivationTechAllowed(techId)
        else
            return false
        end
        
    // If tech is build
    elseif(techNode:GetIsBuild() or techNode:GetIsManufacture()) then
    
        // return false if we don't have enough team resources
        return (player:GetTeamResources() >= techNode:GetCost())
        
    end
    
    return true
    
end

// Children can decide not to allow certain activations at certain times (energy cost already considered)
function ScriptActor:GetActivationTechAllowed(techId)
    return true
end

function ScriptActor:GetUpgradeTechAllowed(techId)
    return true
end

function ScriptActor:GetResearchTechAllowed(techNode)
    return true
end

function ScriptActor:GetMass()
    return ScriptActor.kMass
end

// Returns target point which AI units attack. Usually it's the model center
// but some models (open Command Station) can't be hit at the model center.
// Can also be used for units to "operate" on this unit (welding, construction, etc.)
function ScriptActor:GetEngagementPoint()
    return self:GetModelOrigin()
end

// Returns true if entity's build or health circle should be drawn (ie, if it doesn't appear to be at full health or needs building)
function ScriptActor:SetBuildHealthMaterial(entity)
    return false
end

function ScriptActor:GetViewOffset()
    return Vector(0, 0, 0)
end

function ScriptActor:GetDescription()
    return GetDisplayNameForTechId(self:GetTechId(), "<no description>")
end

function ScriptActor:GetVisualRadius ()
    return LookupTechData(self:GetTechId(), kVisualRange, nil)
end

// Something isn't working right here - has to do with references to points or vector
function ScriptActor:GetViewCoords()
    
    local viewCoords = self:GetViewAngles():GetCoords()   
    viewCoords.origin = self:GetEyePos()
    return viewCoords

end

function ScriptActor:GetCanBeUsed(player)
    return false
end

// To require that the entity needs to be used a certain point, return the name
// of an attach point here
function ScriptActor:GetUseAttachPoint()
    return ""
end

// Used by player. Returns true if entity was affected by use, false otherwise.
function ScriptActor:OnUse(player, elapsedTime, useAttachPoint, usePoint)
    return false
end

function ScriptActor:OnTouch(player)
end

function ScriptActor:ForEachChild(functor)

    local childEntities = GetChildEntities(self)
    if(table.maxn(childEntities) > 0) then    
        for index, entity in ipairs(childEntities) do
            functor(entity)
        end
    end

end

// Returns true if seen visible by the enemy
function ScriptActor:GetIsSighted()
    return self.sighted
end

function ScriptActor:GetAttached()

    local attached = nil
    
    if(self.attachedId ~= Entity.invalidId) then
        attached = Shared.GetEntity(self.attachedId)
    end
    
    return attached
    
end

function ScriptActor:GetAttachPointOrigin(attachPointName)

    local attachPointIndex = self:GetAttachPointIndex(attachPointName)
    local origin  = nil
    local success = false
    
    if attachPointIndex ~= -1 then
        origin = self:GetAttachPointCoords(attachPointIndex).origin
        success = true
    else
        Print("ScriptActor:GetAttachPointOrigin(%s, %s): Attach point not found.", self:GetMapName(), attachPointName)
        origin = Vector(0, 0, 0)
    end
    
    return origin, success
    
end

function ScriptActor:GetDeathIconIndex()
    return kDeathMessageIcon.None
end

// Called when a entity changes into another entity (players changing classes) or
// when an entity is destroyed. See GetEntityChange(). When an entity is destroyed,
// newId will be nil.
function ScriptActor:OnEntityChange(oldId, newId)

    if Server then
        // Update our owner if it has changed.
        if self.ownerPlayerId == oldId then
            if newId then
                self:SetOwner(nil)
                self:SetOwner(Shared.GetEntity(newId))
            else
                self:SetOwner(nil)
            end
        end
    end

end

// Create a particle effect parented to this object and positioned and oriented with us, using 
// the specified attach point name. If called on a player, it's expected to also be called on the 
// player's client, as it won't be propagated to them.
function ScriptActor:CreateAttachedEffect(effectName, entityAttachPointName)
    Shared.CreateAttachedEffect(nil, effectName, self, self:GetCoords(), entityAttachPointName, false, false)
end

// Pass entity and proposed location, returns true if entity can go there without colliding with something
function ScriptActor:SpaceClearForEntity(location)
    // TODO: Collide model with world when model collision working
    return true
end

// Called when a player does a trace capsule and hits a script actor. Players don't have physics
// data currently, only hitboxes and trace capsules. If they did have physics data, they would 
// collide with themselves, so we have this instead. 
function ScriptActor:OnCapsuleTraceHit(entity)
end

function ScriptActor:GetLocationName()

    local locationName = ""
    
    if self.locationId ~= 0 then
        locationName = Shared.GetString(self.locationId)
    end
    
    return locationName
    
end

// Hooks into effect manager
function ScriptActor:GetEffectParams(tableParams)

    BlendedActor.GetEffectParams(self, tableParams)

    // Only override if not specified    
    if not tableParams[kEffectFilterClassName] and self.GetClassName then
        tableParams[kEffectFilterClassName] = self:GetClassName()
    end
    
    if not tableParams[kEffectHostCoords] and self.GetCoords then
        tableParams[kEffectHostCoords] = self:GetCoords()
    end
    
    if not tableParams[kEffectFilterIsMarine] then
        tableParams[kEffectFilterIsMarine] = (self.teamType == kMarineTeamType)
    end
    
    if not tableParams[kEffectFilterIsAlien] then
        tableParams[kEffectFilterIsAlien] = (self.teamType == kAlienTeamType)
    end
    
    if not tableParams[kEffectFilterFromAnimation] and self.GetAnimation then
        tableParams[kEffectFilterFromAnimation] = self:GetAnimation()
    end
    
end

function ScriptActor:SetPathingFlag (flag)  
  self.pathingFlags = bit.bor(self.pathingFlags, bit.lshift(1, flag))
end

function ScriptActor:GetHasPathingFlag (flag)
    return (bit.band(self.pathingFlags, bit.lshift(1, flag)) ~= 0)
end

function ScriptActor:ClearPathingFlag (flag)
  self.pathingFlags = bit.band(self.pathingFlags, bit.bnot(bit.lshift(1, flag)))
end

Shared.LinkClassToMap("ScriptActor", ScriptActor.kMapName, networkVars )