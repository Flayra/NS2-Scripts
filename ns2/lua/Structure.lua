// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Structure.lua
//
// Structures are the base class for all structures in NS2.
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Balance.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/EnergyMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FuryMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/TargetMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/HiveSightBlipMixin.lua")

class 'Structure' (ScriptActor)

Structure.kMapName                  = "structure"

if (Server) then
    Script.Load("lua/Structure_Server.lua")
else
    Script.Load("lua/Structure_Client.lua")
end

// Play construction effects every time structure has built this much (faster if multiple builders)
Structure.kBuildWeldEffectsInterval = .5
Structure.kDefaultBuildTime = 8.00
Structure.kUseInterval = 0.1

// Played when structure is first created (includes tech points)
Structure.kAnimSpawn = "spawn"

// Played structure becomes fully built
Structure.kAnimDeploy = "deploy"

Structure.kAnimPowerDown = "power_down"
Structure.kAnimPowerUp = "power_up"

Structure.kRandomDamageEffectNode = "fxnode_damage"     // Looks for 1-5 to find damage points

Structure.networkVars =
{
    // Tech id of research this building is currently researching
    researchingId           = "enum kTechId",

    // 0 to 1 scalar of progress
    researchProgress        = "float",
    
    // 0-1 scalar representing build completion time. Since we use this to blend
    // animations, it must be interpolated for the animations to appear smooth
    // on the client.
    buildFraction           = "interpolated float",
    
    // true if structure finished building
    constructionComplete    = "boolean",
    
    // time that building will have "warmed up" (slight delay since building it has elapsed).
    // 0 if structure isn't built yet.
    timeWarmupComplete      = "float",
    
    powered                 = "boolean",
    
    // Allows client-effects to be triggered
    effectsActive           = "boolean",
}

PrepareClassForMixin(Structure, EnergyMixin)
PrepareClassForMixin(Structure, LiveMixin)
PrepareClassForMixin(Structure, UpgradableMixin)
PrepareClassForMixin(Structure, GameEffectsMixin)
PrepareClassForMixin(Structure, FuryMixin)
PrepareClassForMixin(Structure, FlinchMixin)
PrepareClassForMixin(Structure, OrdersMixin)
PrepareClassForMixin(Structure, FireMixin)
PrepareClassForMixin(Structure, CloakableMixin)

function Structure:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, EnergyMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FuryMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, OrdersMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, PathingMixin)
    
    if Server then
        InitMixin(self, TargetMixin)
        InitMixin(self, LOSMixin)
        InitMixin(self, WeldableMixin)
        InitMixin(self, HiveSightBlipMixin)
    end
    
    self:SetLagCompensated(true)
    
    self:SetUpdates(true)
    
    // Make the structure kinematic so that the player will collide with it.
    self:SetPhysicsType(PhysicsType.Kinematic)
    
    self.effectsActive = false
    
    self.timeWarmupComplete = 0

    if (self:GetAddToPathing()) then
      self:AddToMesh()     
    end
    
    self:SetPathingFlags(Pathing.PolyFlag_NoBuild)
    
end

function Structure:OnKill(damage, killer, doer, point, direction)

    if Server then
    
        if self:GetIsAlive() then
        
            self.buildTime = 0
            self.buildFraction = 0
            self.constructionComplete = false
        
            self:SetIsAlive(false)
       
            self:ClearAttached()
            self:AbortResearch()
     
        end        
        
    end

    self:ClearPathingFlags(Pathing.PolyFlag_NoBuild)
    
end

function Structure:GetAddToPathing()
  return true
end


/**
 * The eye position for a structure is where it "sees" other entities from for
 * purposes such as targeting.
 */
function Structure:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset()
end

function Structure:GetEffectsActive()
    return self.effectsActive
end

// Use when structure is created and when it turns into another structure
function Structure:SetTechId(techId)

    local success = true
    
    if Server then
        success = self:UpdateHealthValues(techId)
    end
    
    if success then
        success = ScriptActor.SetTechId(self, techId)
    end
    
    return success
    
end

function Structure:GetIsActive()
    return self:GetIsAlive() and (self:GetIsPowered() or not self:GetRequiresPower()) and self:GetIsWarmedUp()
end

function Structure:GetResearchingId()
    return self.researchingId
end

function Structure:GetResearchProgress()
    return self.researchProgress
end

function Structure:GetResearchTechAllowed(techNode)

    // Return true unless it's it's specified that it can only be triggered for specific tech id (ie, an upgraded version of a structure)
    local addOnRequirementMet = true
    local addOnTechId = techNode:GetAddOnTechId()
    if addOnTechId ~= kTechId.None then        
        addOnRequirementMet = (self:GetTechId() == addOnTechId)
    end

    // Return false if we're researching, or if tech is being researched
    return not (self.researchingId ~= kTechId.None or techNode.researched or techNode.researching or not addOnRequirementMet)
    
end

// Children should override this when they have upgrade tech attached to them. Allow upgrading
// if we're not busy researching something.
function Structure:GetUpgradeTechAllowed(techId)
    return not self:GetIsResearching()
end

function Structure:GetCanBeUsed(player)
    ASSERT(player ~= nil)
    return player:GetTeamNumber() == self:GetTeamNumber()
end

function Structure:GetIsCloakable()
    return self:GetIsAlienStructure()
end

// Assumes all structures are marine or alien
function Structure:GetIsAlienStructure()
    return false
end

function Structure:GetInfestationRadius()
    return kStructureInfestationRadius
end

function Structure:GetDeployAnimation()
    return Structure.kAnimDeploy
end

function Structure:GetPowerDownAnimation()
    return Structure.kAnimPowerDown
end

function Structure:GetPowerUpAnimation()
    return Structure.kAnimPowerUp
end

function Structure:GetCanIdle()
    return self:GetIsBuilt() and self:GetIsActive()
end

function Structure:GetIsResearching()
    return self:GetResearchProgress() ~= 0
end

function Structure:GetTechAllowed(techId, techNode, player)
    if techId == kTechId.Recycle or techId == kTechId.Cancel then
        return (self:GetTeamType() == kMarineTeamType)
    end
    
    if not self:GetIsBuilt() then
        return false
    end
    
    if not self:GetIsActive() then
        return false
    end
    
    return ScriptActor.GetTechAllowed(self, techId, techNode, player)
end
   
function Structure:GetStatusDescription()
    if (self:GetRecycleActive()) then
        return Locale.ResolveString("RECYCLING") .. "...", self:GetResearchProgress()
    elseif (not self:GetIsBuilt() ) then
    
        return Locale.ResolveString("CONSTRUCTING") .. "...", self:GetBuiltFraction()
        
    elseif (self:GetResearchProgress() ~= 0) then
    
        return string.format("%s %s...", Locale.ResolveString("RESEARCHING"), GetDisplayNameForTechId(self:GetResearchingId())), self:GetResearchProgress()
    
    end
    
    return nil, nil
    
end

function Structure:GetBuiltFraction()
    return self.buildFraction
end

function Structure:GetCanConstruct(player)

    if not self:GetIsBuilt() and (player:GetTeamNumber() ~= GetEnemyTeamNumber(self:GetTeamNumber())) then
    
        if (player:isa("Marine") or player:isa("Gorge")) and player:GetCanNewActivityStart() then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Structure:GetIsBuilt()
    return self.constructionComplete and self:GetIsAlive()
end

function Structure:GetSpawnAnimation()
    return Structure.kAnimSpawn
end

function Structure:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    // Pose parameters calculated on server from current order
    self:UpdatePoseParameters(deltaTime)
    
end

function Structure:UpdatePoseParameters(deltaTime)

    if LookupTechData(self:GetTechId(), kTechDataGrows, false) then
    
        // This should depend on time passed
        local buildFraction = Slerp(self:GetPoseParam("grow"), self.buildFraction, deltaTime * .5)
        self:SetPoseParam("grow", buildFraction)    
        
    end
    
end

function Structure:GetRequiresPower()
    return false
end

function Structure:GetIsPowered()
    return self.powered
end

function Structure:GetEngagementPoint()

    local attachPoint, success = self:GetAttachPointOrigin("target")
    if not success then
        return ScriptActor.GetEngagementPoint(self)
    end
    return attachPoint
    
end

function Structure:GetEffectParams(tableParams)

    ScriptActor.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterBuilt] = self:GetIsBuilt()
    tableParams[kEffectFilterActive] = self:GetEffectsActive()
        
end

function Structure:GetIsWarmedUp()
    return (self.timeWarmupComplete ~= 0) and (Shared.GetTime() >= self.timeWarmupComplete)
end

function Structure:OverrideVisionRadius()
    return LOSMixin.kStructureMinLOSDistance
end

function Structure:GetRecycleActive()
    return self.researchingId == kTechId.Recycle
end

Shared.LinkClassToMap("Structure", Structure.kMapName, Structure.networkVars)
