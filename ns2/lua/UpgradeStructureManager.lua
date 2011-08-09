// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\UpgradeStructureManager.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

class 'UpgradeStructureManager'

// Pass in table of ids matched to classnames for each like:
// {[kTechId.Hive] = {"Hive"} }  (supporting structures)
// {[kTechId.Crag] = {"Crag", "MatureCrag"}, [kTechId.Shift] = {"Shift", "MatureShift"}, [kTechId.Shade] = {"Shade", "MatureShift"} }  (upgrade structures)
// {[kTechId.Crag] = {kTechId.MatureCrag}, [kTechId.Shift] = {kTechId.MatureShift}, [kTechId.Shade] = {kTechId.MatureShade}}
// This allows us to have upgraded structures function identically to base structures
function UpgradeStructureManager:Initialize(supportingStructureClassNameTable, upgradeStructureClassNameTable, upgradedStructureTechTable)

    ASSERT(supportingStructureClassNameTable)
    ASSERT(upgradeStructureClassNameTable)
    ASSERT(upgradedStructureTechTable)
    
    self.kSupportingStructureClassNameTable = supportingStructureClassNameTable
    self.kUpgradeStructureClassNameTable = upgradeStructureClassNameTable
    self.kUpgradedStructureTechTable = upgradedStructureTechTable
    
    // List of {entity id, supporting tech id} pairs. kTechId.None
    self.supportingIds = {}
    
    // List of {entity id, tech id} pairs
    self.upgradeStructureIds = {}
    
    self.updateSupport = false
    
end

// Called when structures are created and when they finish building
function UpgradeStructureManager:AddStructure(entity)

    if self:_GetIsSupportingStructure(entity) then
    
        if table.insertunique(self.supportingIds, {entity:GetId(), kTechId.None}) then
        
            self.updateSupport = true
            
            return true
            
        end
        
    elseif self:_GetIsUpgradeStructure(entity) then
    
        if table.insertunique(self.upgradeStructureIds, {entity:GetId(), entity:GetTechId()}) then
        
            self.updateSupport = true
            
            return true
            
        end
        
    end
    
    return false
    
end

function UpgradeStructureManager:RemoveStructure(entity)

    if self:_GetIsSupportingStructure(entity) then
    
        // Get pair that matches and remove it
        for index, pair in ipairs(self.supportingIds) do
        
            if pair[1] == entity:GetId()and table.removevalue(self.supportingIds, pair) then
            
                self.updateSupport = true
                
                return true
                
            end
            
        end        
        
    elseif self:_GetIsUpgradeStructure(entity) then
    
        for index, pair in ipairs(self.upgradeStructureIds) do
        
            if pair[1] == entity:GetId() and table.removevalue(self.upgradeStructureIds, pair) then
            
                self.updateSupport = true
                
                return true
                
            end
            
        end        

    end
    
    return false
    
end

function _GetIsInStructureTable(structureTable, entity)

    for techId in pairs(structureTable) do
    
        local classNames = structureTable[techId]
        
        for classIndex, className in ipairs(classNames) do
        
            if entity:isa(className) then
            
                return true, techId
                
            end
            
        end
        
    end

    return false, kTechId.None
    
end

// Translate upgraded versions of tech as base tech in terms of support
// (ie, a particular hive supports kTechId.Shade technology, which includes kTechId.MatureShade
function UpgradeStructureManager:_GetBaseTechIdFromTable(incomingTechId)

    for baseTechId, upgradedTechTable in pairs(self.kUpgradedStructureTechTable) do
        for index, id in ipairs(upgradedTechTable) do
            if id == incomingTechId then
                return baseTechId
            end
        end
    end

    return incomingTechId
    
end

function UpgradeStructureManager:_GetIsSupportingStructure(entity)
    return _GetIsInStructureTable(self.kSupportingStructureClassNameTable, entity) and entity:GetIsBuilt()
end

function UpgradeStructureManager:_GetIsUpgradeStructure(entity)
    return _GetIsInStructureTable(self.kUpgradeStructureClassNameTable, entity) // don't check for built or active - they count even before they are built
end

// Returns true and entityId if true, false and nil otherwise
function UpgradeStructureManager:GetTechIdSupported(techId)

    // Update support when we need it, if it changed 
    if self.updateSupport then    
    
        self:_UpdateSupport()
        self.updateSupport = false        
        
    end

    // Translate techId to most base form 
    local baseTechId = self:_GetBaseTechIdFromTable(techId)

    // Get techId associated with class name   
    for index, pair in ipairs(self.supportingIds) do
    
        if pair[2] == baseTechId then
        
            return true, pair[1]
            
        end
        
    end
    
    return false, nil
    
end

// Return number of supporting structures who are actually being used
function UpgradeStructureManager:GetNumSupportingStructures()
    
    local num = 0
    
    for index, pair in ipairs(self.supportingIds) do
        if pair[2] ~= kTechId.None then
            num = num + 1
        end
    end
    
    return num
    
end

function UpgradeStructureManager:GetSupportingStructures()
    return self.supportingIds
end

function UpgradeStructureManager:_GetFreeSupportingStructures()

    for index, pair in ipairs(self.supportingIds) do
        if pair[2] == kTechId.None then
            return true
        end
    end
    
    return false
    
end

function UpgradeStructureManager:GetNumSupportingStructuresNeeded(techId)

    // If already supported, or if any supporting structures are free, we just need the number we have
    if self:GetTechIdSupported(techId) then
        return self:GetNumSupportingStructures()
    else
        // If not supported, look at current number 
        return self:GetNumSupportingStructures() + 1
    end
    
end

function UpgradeStructureManager:GetPrereqForTech(techId)

    local prereq = kTechId.Hive
    local numHivesNeeded = self:GetNumSupportingStructuresNeeded(techId)

    ASSERT(numHivesNeeded >= 0)
    ASSERT(numHivesNeeded <= 3)
    
    if numHivesNeeded == 1 then
        prereq = kTechId.Hive
    elseif numHivesNeeded == 2 then
        prereq = kTechId.TwoHives
    elseif numHivesNeeded == 3 then
        prereq = kTechId.ThreeHives
    end
    
    return prereq
    
end

function UpgradeStructureManager:_UpdateSupport()

    // Get list of unique class names that are looking for support
    local techIds = self:_GetTechIdsNeedingSupport()
    
    // Clear techIds entries from supportingIds that are no longer needed
    for index, pair in ipairs(self.supportingIds) do
    
        if pair[2] ~= kTechId.None then
        
            if not table.find(techIds, pair[2]) then
                pair[2] = kTechId.None            
            else       
                // Remove any techIds that are already supported
                table.removevalue(techIds, pair[2])
            end
            
        end
        
    end
    
    // Now have any empty supporting structures support these remaining tech ids
    for index, techId in ipairs(techIds) do
    
        for index2, pair in ipairs(self.supportingIds) do    
        
            if pair[2] == kTechId.None then
            
                pair[2] = techId
                break
                
            end
            
        end
        
    end

end

function UpgradeStructureManager:_GetTechIdsNeedingSupport()

    local techIdsNeedingSupport = {}
    
    for index, pair in ipairs(self.upgradeStructureIds) do
    
        local techId = pair[2]    
        if techId ~= kTechId.None then
        
            table.insertunique(techIdsNeedingSupport, techId)
            
        end
        
    end
    
    return techIdsNeedingSupport 
    
end
