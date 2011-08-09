// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTree_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Send the entirety of every the tech node on team change or join. Returns true if it sent anything
function TechTree:SendTechTreeBase(player)

    local sent = false
    
    if self.complete then
    
        // Tell client to empty tech tree before adding new nodes. Send reliably
        // so players are always able to buy weapons, use commander mode, etc.
        Server.SendNetworkMessage(player, "ClearTechTree", {}, true)
    
        for index, techNode in pairs(self.nodeList) do
        
            Server.SendNetworkMessage(player, "TechNodeBase", BuildTechNodeBaseMessage(techNode), true)
            
            sent = true
        
        end
        
    end
    
    return sent
    
end

function TechTree:SendTechTreeUpdates(playerList)

    for techNodeIndex, techNode in ipairs(self.techNodesChanged) do
    
        local techNodeUpdateTable = BuildTechNodeUpdateMessage(techNode)
        
        for playerIndex, player in ipairs(playerList) do    
        
            Server.SendNetworkMessage(player, "TechNodeUpdate", techNodeUpdateTable, true)
            
        end
        
    end
    
    table.clear(self.techNodesChanged)
    
end

function TechTree:AddOrder(techId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Order, kTechId.None, kTechId.None)
    techNode.requiresTarget = true
    
    self:AddNode(techNode)    
    
end

// Contains a bunch of tech nodes
function TechTree:AddBuildNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Build, prereq1, prereq2)
    techNode.requiresTarget = true
    
    self:AddNode(techNode)    
    
end

// Contains a bunch of tech nodes
function TechTree:AddEnergyBuildNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.EnergyBuild, prereq1, prereq2)
    techNode.requiresTarget = true
    
    self:AddNode(techNode)    
    
end

function TechTree:AddManufactureNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Manufacture, prereq1, prereq2)
    
    local buildTime = LookupTechData(techId, kTechDataBuildTime, Structure.kDefaultBuildTime)
    techNode.time = ConditionalValue(buildTime ~= nil, buildTime, 0)
    
    self:AddNode(techNode)  

end


function TechTree:AddBuyNode(techId, prereq1, prereq2, addOnTechId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Buy, prereq1, prereq2)
    
    if addOnTechId ~= nil then
        techNode.addOnTechId = addOnTechId
    end
    
    self:AddNode(techNode)    
    
end

function TechTree:AddTargetedBuyNode(techId, prereq1, prereq2, addOnTechId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Buy, prereq1, prereq2)
    
    if addOnTechId ~= nil then
        techNode.addOnTechId = addOnTechId
    end
    
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)    

end

function TechTree:AddTargetedEnergyNode(techId, prereq1, prereq2, addOnTechId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.ActionEnergy, prereq1, prereq2)
    
    if addOnTechId ~= nil then
        techNode.addOnTechId = addOnTechId
    end
    
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)    

end

function TechTree:AddResearchNode(techId, prereq1, prereq2, addOnTechId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Research, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)
    
    if addOnTechId ~= nil then
        techNode.addOnTechId = addOnTechId
    end

    self:AddNode(techNode)    
    
end

// Same as research but can be triggered multiple times and concurrently
function TechTree:AddUpgradeNode(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Upgrade, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)

    self:AddNode(techNode)    
    
end

function TechTree:AddAction(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Action, prereq1, prereq2)
    
    self:AddNode(techNode)  

end

function TechTree:AddTargetedAction(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Action, prereq1, prereq2)
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)
    
end

// If there's a cost, it's energy
function TechTree:AddActivation(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Activation, prereq1, prereq2)
    
    self:AddNode(techNode)  
    
end

// If there's a cost, it's energy
function TechTree:AddTargetedActivation(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Activation, prereq1, prereq2)
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)  
    
end

function TechTree:AddMenu(techId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Menu, kTechId.None, kTechId.None)
    
    self:AddNode(techNode)  

end

function TechTree:AddEnergyManufactureNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.EnergyManufacture, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)
    
    self:AddNode(techNode)    
    
end

function TechTree:AddPlasmaManufactureNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.PlasmaManufacture, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)
    
    self:AddNode(techNode)    
    
end

function TechTree:AddSpecial(techId, requiresTarget)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Special, kTechId.None, kTechId.None)
    techNode.requiresTarget = ConditionalValue(requiresTarget, true, false)
    
    self:AddNode(techNode)  

end

function TechTree:SetTechChanged()
    self.techChanged = true
end

// Pre-compute stuff
function TechTree:SetComplete(complete)

    if not self.complete then
        
        self:ComputeUpgradedTechIdsSupporting()
        
        self.complete = true
        
    end
    
end

function TechTree:SetTeamNumber(teamNumber)
    self.teamNumber = teamNumber
end

function TechTree:GiveUpgrade(techId)

    local node = self:GetTechNode(techId)
    if(node ~= nil) then
    
        if(node:GetIsResearch()) then
        
            local newResearchState = not node.researched
            node:SetResearched(newResearchState)
            
            self:SetTechNodeChanged(node)
            
            if(newResearchState) then
                local team = GetGamerules():GetTeam(self:GetTeamNumber())
                if team ~= nil then
                    team:OnResearchComplete(nil, techId)
                else
                    Print("TechTree:GiveUpgrade(%d): Couldn't find team to call OnResearchComplete() on.", techId)
                end
            end
            
            return true

        end
        
    else
        Print("TechTree:GiveUpgrade(%d): Couldn't lookup tech node.", techId)
    end
    
    return false
    
end

function TechTree:ComputeUpgradedTechIdsSupporting()

    self.upgradedTechIdsSupporting = {}
    
    for index, techId in pairs(kTechId) do
    
        local t = self:ComputeUpgradedTechIdsSupportingId(techId)
        
        if table.maxn(t) > 0 then
        
            table.insert(self.upgradedTechIdsSupporting, {techId, t})
            
        end
        
    end
    
end

function TechTree:GetUpgradedTechIdsSupporting(techId)

    for index, idTablePair in ipairs(self.upgradedTechIdsSupporting) do
    
        if idTablePair[1] == techId then
        
            return idTablePair[2]
            
        end
        
    end
    
    return {}
    
end

// Compute if active structures on our team that support this technology. Do this in batches for efficiency.
function TechTree:UpdateTeamStructureData()

    local structures = GetEntitiesForTeam("Structure", self:GetTeamNumber())
    
    for index, node in pairs(self.nodeList) do

        local techId = node:GetTechId()
        
        local hasTech = false
    
        if(self:GetTechSpecial(techId)) then
        
            hasTech = self:GetSpecialTechSupported(techId, structures)

        // If it's research, see if it's researched
        
        // else            
        else
    
            // Also look for tech that replaces this tech but counts towards it (upgraded Armories, Infantry Portals, etc.)        
            local supportingTechIds = self:GetUpgradedTechIdsSupporting(techId)
            
            table.insert(supportingTechIds, techId)
            
            for index, entity in pairs(structures) do
            
                if(table.find(supportingTechIds, entity:GetTechId())) then
                
                    if(not entity:isa("Structure") or entity:GetIsBuilt()) then
                    
                        hasTech = true
                        
                        break
                        
                    end
                
                end
               
            end
            
        end 
        
        // Update node
        node.hasTech = hasTech
       
    end
        
end

// Check if active structures on our team that support this technology. These are
// are computed during ComputeAvailability().
function TechTree:GetHasTech(techId)
    
    local node = GetTechNode(techId)    
    if node ~= nil then
    
        return node.hasTech
        
    end

    return false

end

// TwoCommandStations and ThreeCommandStations not currently used
function TechTree:GetTechSpecial(techId)
    return (techId == kTechId.TwoCommandStations) or (techId == kTechId.ThreeCommandStations) or (techId == kTechId.TwoHives) or (techId == kTechId.ThreeHives)
end

function TechTree:GetSpecialTechSupported(techId, structures)

    local className = nil
    
    if( (techId == kTechId.TwoCommandStations) or (techId == kTechId.ThreeCommandStations) ) then
        className = "CommandStation"
    elseif( (techId == kTechId.TwoHives) or (techId == kTechId.ThreeHives) ) then
        className = "Hive"
    end
    
    local numBuiltSpecials = 0
    
    if(className ~= nil) then
    
        for index, structure in ipairs(structures) do
            if(structure:isa(className) and structure:GetIsBuilt()) then
                numBuiltSpecials = numBuiltSpecials + 1
            end
        end
        
    else
        Print("GetSpecialTechSupported(%d): Called using non-special tech", techId)
    end
    
    if(techId == kTechId.TwoCommandStations or techId == kTechId.TwoHives) then
        return (numBuiltSpecials >= 2)
    else    
        return (numBuiltSpecials >= 3)
    end
    
end

// Compute "available" field for all nodes in tech tree. Should be called whenever a structure
// is added or removed, and whenever global research starts or is canceled.
function TechTree:ComputeAvailability()

    // Only compute if needed
    if(self.techChanged) then
    
        // Compute structure availability so we don't have to keep computing it below 
        self:UpdateTeamStructureData()
        
        // Now enable or disable aney nodes with this as a prereq
        for index, node in pairs(self.nodeList) do
        
            local newAvailableState = false
            
            // Don't allow researching items that are currently being researched (unless multiples allowed)
            if ( (node:GetIsResearch() or node:GetIsPlasmaManufacture()) and (self:GetTechSupported(node.prereq1) and self:GetTechSupported(node.prereq2)) ) then
            
                newAvailableState = node:GetCanResearch()
            
            // Disable anything with this as a prereq if no longer available                
            elseif( self:GetTechSupported(node.prereq1) and self:GetTechSupported(node.prereq2) ) then
            
                newAvailableState = true

            end
            
            // Check for "alltech" cheat
            if(GetGamerules():GetAllTech()) then
                newAvailableState = true
            end
            
            // Don't allow use of stuff that's unavailable
            if (LookupTechData(node.techId, kTechDataImplemented) == false and not Shared.GetDevMode()) then
                newAvailableState = false
            end
            
            if(node.available ~= newAvailableState) then
            
                node.available = newAvailableState
                
                // Queue tech node update to clients
                self:SetTechNodeChanged(node)
                
            end
            
        end
        
        self.techChanged = false
        
    end
    
end

// TODO: Call this when structure is powered down or up
function TechTree:SetTechNodeChanged(node)

    if table.insertunique(self.techNodesChanged, node) then
    
        self.techChanged = true
        
    end
    
end

// Utility functions
function GetTechSupported(callingEntity, techId, silenceError)

    if callingEntity ~= nil then
    
        local team = GetGamerules():GetTeam(callingEntity:GetTeamNumber())
        
        if team ~= nil and team:isa("PlayingTeam") then
       
            local techTree = team:GetTechTree()
            
            if techTree ~= nil then
                return techTree:GetTechSupported(techId, silenceError)
            end
            
        end
        
    end
    
    return false
    
end
