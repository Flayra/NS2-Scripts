// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTree.lua
//
// Tracks state of a team's technology. Contains tech nodes and functions for building, unlocking 
// and manipulating them.
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/TechData.lua")

class 'TechTree'

if(Server) then
    Script.Load("lua/TechTree_Server.lua")
else
    Script.Load("lua/TechTree_Client.lua")
end

// Constructor
function TechTree:Initialize()

    self.nodeList = {}
    
    self.techChanged = false
    self.complete = false
    
    // No need to add to team
    self.teamNumber = kTeamReadyRoom
    
    if Server then
        self.techNodesChanged = {}
    end
        
end

function TechTree:AddNode(node)

    local nodeEntityId = node:GetTechId()
    
    if self.nodeList[nodeEntityId] == nil then
        self.nodeList[nodeEntityId] = node
    else
        Print("TechTree:AddNode(): Element already exists at index %s", ToString(nodeEntityId))
    end
    
end

function TechTree:GetTechNode(techId)
    return self.nodeList[techId]
end

function TechTree:GetTechSupported(techId, silenceError)
    
    if techId == kTechId.None then
        return true
    else
    
        local techNode = self:GetTechNode(techId)
        if(techNode == nil) then
        
            if not silenceError then
                Print("TechTree:GetTechSupported(kTechId.%s): Couldn't find tech node (%s)", EnumToString(kTechId, techId), GetDisplayNameForTechId(techId))
            end
            
            return false
        end
        
        return techNode.hasTech or (techNode:GetIsResearch() and techNode.researched)
        
    end

end

// Returns string describing tech node 
function TechTree:GetDescriptionText(techId)

    local techNode = self:GetTechNode(techId)
    local text = GetDisplayNameForTechId(techId)
    if(techNode == nil or text == nil) then
        return ""
    end
    
    return text

end

function TechTree:GetRequiresText(techId)

    local text = ""

    if techId ~= kTechId.None then    
    
        local techNode = self:GetTechNode(techId)
        if(techNode ~= nil and not techNode.available) then
        
            local addedPrereq1 = false
            local addedPrereq2 = false
            if(techNode.prereq1 ~= kTechId.None) then
                local missingDisplayText = string.format("<missing display for %s", EnumToString(kTechId, techNode.prereq1))
                text = string.format("%s%s", text, GetDisplayNameForTechId(techNode.prereq1, missingDisplayText))
                addedPrereq1 = true
            end
            
            if(techNode.prereq2 ~= kTechId.None) then        
                local missingDisplayText = string.format("<missing display for %s>", EnumToString(kTechId, techNode.prereq2))
                text = string.format("%s%s%s", text, ConditionalValue(addedPrereq1, ", ", ""), GetDisplayNameForTechId(techNode.prereq2, missingDisplayText))
                addedPrereq2 = true
            end
            
            if(techNode.addOnTechId ~= kTechId.None) then
                local missingDisplayText = string.format("<missing display for %s>", EnumToString(kTechId, techNode.addOnTechId))
                text = string.format("%s%s%s", text, ConditionalValue(addedPrereq1 or addedPrereq2, " on ", ""), GetDisplayNameForTechId(techNode.addOnTechId, missingDisplayText))
            end
            
        end
        
    end
    
    return text

end

// Return text description of other unavailable tech nodes that directly depend on this one
function TechTree:GetEnablesText(techId)

    local text = ""

    for index, techNode in pairs(self.nodeList) do

        if not techNode.available and ( (techNode:GetPrereq1() == techId) or (techNode:GetPrereq2() == techId) ) then

            if text ~= "" then
                text = text .. ", "
            end
            
            local missingDisplayText = string.format("<missing display for %s>", EnumToString(kTechId, techNode:GetTechId()))
            text = string.format("%s%s", text, GetDisplayNameForTechId(techNode:GetTechId(), missingDisplayText))
            
        end        
        
    end
    
    return text

end

// Get the 0-1 research progress for a buy node. Assumes that it only has one prerequisite and that the
// prerequisite is research. For instance, check the research process for Shotgun, which has its
// prerequisite1 as ShotgunTech. Used for displaying research in progress at the marine and alien
// buy menus. Returns 1 if tech is available or if there is no prerequisite.
function TechTree:GetResearchProgressForBuyNode(buyTechId)

    local researchAmount = 1
    local techNode = self:GetTechNode(buyTechId)
    if techNode and not techNode:GetAvailable() then

        researchAmount = 0
        
        local prereq1 = techNode:GetPrereq1()
        if prereq1 ~= kTechId.None then
        
            local prereqNode = self:GetTechNode(prereq1)
            if prereqNode ~= nil and prereqNode:GetResearching() then
            
                researchProgress = prereqNode:GetResearchProgress()
                
            end
            
        end
        
    end
    
    return researchAmount
    
end

// Return array of tech ids that are addons for specified tech id
function TechTree:GetAddOnsForTechId(techId)

    local addons = {}
    
    for index, techNode in pairs(self.nodeList) do    
        
        if techNode ~= nil and techNode:isa("TechNode") then
        
            if techNode:GetAddOnTechId() == techId then
            
                table.insert(addons, techNode:GetTechId())
                
            end
            
        else
        
            Print("TechTree:GetAddOnsForTechId(%d) - Couldn't find tech node with id %d (%s)", techId, id, SafeClassName(techNode))
            
        end
        
    end
    
    return addons
    
end

function TechTree:GetTeamNumber()
    return self.teamNumber
end

function GetTechUpgradesFromTech(upgradeTechId, techId)

    local upgradeTechId = LookupTechData(upgradeTechId, kTechDataUpgradeTech, kTechId.None)
    
    if(upgradeTechId ~= nil and upgradeTechId ~= kTechId.None) then
    
        if(upgradeTechId == techId) then
        
            return true
            
        else
        
            return GetTechUpgradesFromTech(upgradeTechId, techId)
            
        end
        
    end
    
    return false
    
end

function TechTree:ComputeUpgradedTechIdsSupportingId(techId)

    local techIds = {}
    
    // Find all tech that supports techId through an upgrade
    for index, techNode in pairs(self.nodeList) do
    
        local currentTechId = techNode:GetTechId()
        
        if(GetTechUpgradesFromTech(currentTechId, techId)) then
        
            table.insert(techIds, currentTechId)
            
        end
        
    end
    
    return techIds
    
end

Shared.RegisterNetworkMessage( "ClearTechTree", {} )