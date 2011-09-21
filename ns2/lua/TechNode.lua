// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechNode.lua
//
// Represents one item in the tech tree. They also characterize the behavior when triggering that kind of action.
// Tech nodes are of the following types:
//
//   Order (Move, Default) - No cost, requires positional
//   Research (eg, research siege) - Costs team resources, queued from a structure, non-positional
//   Upgrade (eg, upgrade command station) - Like research but can be performed more than once
//   Action (eg, medpack, drifter flare) - Optionally costs energy, optional position, optionally must be researched
//   Buy (eg, create siege cannon from factory, player buy weapon) - Costs resources, position implied from buyer 
//      or originating structure (unless targeted). Requires target for commander. Can be built on entities.
//   Build (eg, build structure from drifter) - Costs team resources, requires position
//   EnergyManufacture (add to manufacture queue, create unit when done) - Costs energy, takes time to complete, no 
//      position (MACs, Drifters). Only use for AI units that don't need a position.
//   PlasmaManufacture (add to manufacture queue, create unit when done) - Costs player resources, takes time to 
//      complete, no position (MACs, Drifters). Only use for AI units that don't need a position.
//   Manufacture (add to manufacture queue, create unit when done) - Costs resources, takes time to complete, no 
//      position (ARCs)
//   Activation (eg, deploy/undeploy siege) - Optionally costs energy, optional position
//   Menu - No cost, no position
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
//Script.Load("lua/TechData.lua")

class 'TechNode'
TechNode.kMapName = "technode"

function TechNode:Initialize(techId, techType, prereq1, prereq2)

    if(techId == nil) then
        local formatString = "TechNode:Initialize(%s, %s, %s, %s): techId is nil"
        Print(formatString, tostring(techId), tostring(techType), tostring(prereq1), tostring(prereq2))
    end
    
    self.techId = techId
    
    self.techType = techType
    
    if prereq1 == nil then
        prereq1 = kTechId.None
    end
    
    if prereq2 == nil then
        prereq2 = kTechId.None
    end
    
    self.prereq1 = prereq1
    self.prereq2 = prereq2
    
    ASSERT(self.techId ~= prereq1)
    ASSERT(self.techId ~= prereq2)

    self.addOnTechId = kTechId.None
    
    self.cost = LookupTechData(self.techId, kTechDataCostKey, 0)
    
    self.available = false
    
    self.time = 0
    
    self.researchProgress = 0
    
    self.prereqResearchProgress = 0
    
    self.researched = false
    
    self.hasTech = false
    
    self.researching = false
    
    self.requiresTarget = false
    
end

function TechNode:GetResearched()
    return self.researched
end

function TechNode:GetIsOrder()
    return self.techType == kTechType.Order
end

function TechNode:GetIsResearch()
    return self.techType == kTechType.Research
end

function TechNode:GetIsUpgrade()
    return self.techType == kTechType.Upgrade
end

function TechNode:GetIsSpecial()
    return self.techType == kTechType.Special
end

// Returns: 0 = team resources, 1 = individual resources, 2 = energy (from CommanderUI_MenuButtonTooltip). Returns nil if none required.
function TechNode:GetResourceType()

    // Team resources
    if self.techType == kTechType.Research or self.techType == kTechType.Upgrade or self.techType == kTechType.Build or self.techType == kTechType.Manufacture then
        return 0
    // Personal Resources
    elseif self.techType == kTechType.Buy or self.techType == kTechType.PlasmaManufacture then
        return 1
    // Energy
    elseif self.techType == kTechType.Action or self.techType == kTechType.EnergyBuild or self.techType == kTechType.EnergyManufacture or self.techType == kTechType.Activation then
        return 2
    end
    
    return nil
    
end

function TechNode:GetIsAction()
    return self.techType == kTechType.Action
end

function TechNode:GetIsBuy()
    return self.techType == kTechType.Buy
end

function TechNode:GetAddOnTechId()
    return self.addOnTechId
end

function TechNode:GetIsBuild()
    return self.techType == kTechType.Build
end

function TechNode:GetIsEnergyBuild()
    return self.techType == kTechType.EnergyBuild
end

function TechNode:GetIsActivation()
    return self.techType == kTechType.Activation
end

function TechNode:GetIsManufacture()
    return self.techType == kTechType.Manufacture
end

function TechNode:GetIsMenu()
    return self.techType == kTechType.Menu
end

function TechNode:GetRequiresTarget()
    return self.requiresTarget
end

function TechNode:GetIsEnergyManufacture()
    return self.techType == kTechType.EnergyManufacture
end

function TechNode:GetIsPlasmaManufacture()
    return self.techType == kTechType.PlasmaManufacture
end

function TechNode:GetTechId()
    return self.techId
end

function TechNode:GetPrereq1()
    return self.prereq1
end

function TechNode:GetPrereq2()
    return self.prereq2
end

function TechNode:SetPrereq1(prereq1)
    self.prereq1 = prereq1
end

function TechNode:SetPrereq2(prereq2)
    self.prereq2 = prereq2
end

function TechNode:GetCost()
    return self.cost
end

// Nodes that have been researched and will never be allowed again this game
function TechNode:GetIsForeverUnavailable()

    return (self.techType == kTechType.Research) and self.researched

end

function TechNode:SetResearchProgress(progress)
    self.researchProgress = progress
end

function TechNode:GetResearchProgress()
    return self.researchProgress
end

function TechNode:SetPrereqResearchProgress(progress)
    self.prereqResearchProgress = progress
end

function TechNode:GetPrereqResearchProgress()
    return self.prereqResearchProgress
end

// Indicates if we this tech node can be bought, researched, etc.
function TechNode:GetAvailable()
    return self.available
end

function TechNode:GetCanResearch()

    return ((self.techType == kTechType.Research) and not self.researched and not self.researching) or (self.techType == kTechType.Upgrade) or (self.techType == kTechType.EnergyManufacture) or (self.techType == kTechType.PlasmaManufacture)
    
end

// True if this is tech node represents a structure that is built or if the tech is satisfied (Hive, TwoCommandStations, etc.)
function TechNode:GetHasTech()
    return self.hasTech    
end

function TechNode:SetHasTech(hasTech)
    self.hasTech = hasTech
end

function TechNode:GetResearching()
    return self.researching
end

function TechNode:SetResearching()

    if(self:GetCanResearch()) then
    
        self.researching = true
        
    end

end

function TechNode:ClearResearching()

    self.researching = false
    self.researchProgress = 0
        
end

// Make sure to call TechTree:ComputeAvailability() after making a change here.
function TechNode:SetResearched(state)

    ASSERT(state ~= nil)
    
    if(self.techType == kTechType.Research) then
        self.researched = state
        self.researchProgress = 1
    end    
    
end



