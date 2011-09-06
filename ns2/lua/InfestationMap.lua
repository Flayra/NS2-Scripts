// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfestationMap.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// The infestation map is a sparse map used to quickly find out what infestations can affect you


function UpdateInfestationMasks()

    PROFILE("InfestationManager:UpdateInfestationMasks")

    for index, entity in ientitylist(Shared.GetEntitiesWithTag("GameEffects")) do
        // Don't do this for infestations.
        if not entity:isa("Infestation") then
            UpdateInfestationMask(entity)
        end
    end
    
end

// Clear OnInfestation game effect mask on all entities, unless they are standing on infestation
function UpdateInfestationMask(forEntity)
    
    if HasMixin(forEntity, "GameEffects") then
    
        local infestationVerticalSize = GetInfestationVerticalSize(forEntity)
        local onInfestation = Server.infestationMap:GetIsOnInfestation(forEntity:GetOrigin(), infestationVerticalSize)
        
        // Update the mask.
        if forEntity:GetGameEffectMask(kGameEffect.OnInfestation) ~= onInfestation then
            forEntity:SetGameEffectMask(kGameEffect.OnInfestation, onInfestation)
        end

    end
        
end

class "InfestationMap"

InfestationMap.kCellSize = 5

function InfestationMap:Init()
    // cellPointMap is used to find if a point is on infestations
    self.cellPointMap = {}
    // cellConnectMap is used to find if you are connected to another infestation. It adds kInfestationRange to each infestations
    // influence on the cellmap, which works as the only infestation with greater reach are the 20m hive source infestations, which
    // don't need connections anyhow.
    self.cellConnectMap = {}
    
    self.logTable = {}
    self.log = Logger("log", self.logTable, false) // turn on manually when testing
    self.logPoint = Logger("logPoint", self.logTable) // turn on manually when testing
    self.logConn = Logger("logConn", self.logTable, false) // turn on manually when testing
    return self
    
end

function InfestationMap:GetIsOnInfestation(point, verticalSize)   
    local key = PointToCellKey(point)
    local cell = self.cellPointMap[key] 
    local result = cell and cell:GetIsOnInfestation(point, verticalSize) or false  
    self.logPoint("OnInfest %s -> key %s -> cell %s -> %s", point, key, cell, result)
    return result
end

function InfestationMap:GetConnections(infestation) 
    local key = PointToCellKey(infestation:GetOrigin())
    local cell = self.cellConnectMap[key]
    local result = cell and cell:GetConnections(infestation) or {} 
    self.logConn("Conn for %s, key %s, cell %s, result len %s", infestation, key, cell, table.countkeys(result))
    return result
end

function InfestationMap:_VisitCells(cellMap, infestation, radius, functor, logger)
    logger("VisitInfest %s, radius %s", infestation, radius)
    local origin = infestation:GetOrigin()
    local sx = origin.x - radius
    local sz = origin.z - radius
    local ex = sx + radius * 2
    local ez = sz + radius * 2
    local step = math.min(radius, InfestationMap.kCellSize)
    for x = sx,ex,step do
        for z = sz,ez,step do
            local dx = origin.x - x
            local dz = origin.z - z
            // This actually visits unnecessarily many cell, but its such a small
            // performance problem (its just basically for the 20m radius hive infests that it may affect
            // a few cells. 
            local point = Vector(x,0,z)
            local cellKey = PointToCellKey(point)
            local cell = cellMap[cellKey]
            if not cell then
                cell = InfestationMapCell():Init(point,logger)
                cellMap[cellKey] = cell
            end
            functor(cell, infestation, logger)
        end
    end
end 

function AddToCell(cell, infestation)
    cell:Add(infestation)
end

function RemoveFromCell(cell, infestation)
    cell:Remove(infestation)
end

function InfestationMap:AddInfestation(infestation)
    local radius = infestation:GetMaxRadius()
    Server.infestationMap.log("AddInfest %s, maxR %s", infestation, radius)
    self:_VisitCells(self.cellPointMap, infestation, radius, AddToCell, self.logPoint)
    self:_VisitCells(self.cellConnectMap, infestation, radius + kInfestationRadius, AddToCell, self.logConn)  
end 

function InfestationMap:RemoveInfestation(infestation)
    local radius = infestation:GetMaxRadius()
    Server.infestationMap.log("RemoveInfest %s, maxR %s", infestation, radius)
    self:_VisitCells(self.cellPointMap, infestation, radius, RemoveFromCell, self.logPoint)
    self:_VisitCells(self.cellConnectMap, infestation, radius + kInfestationRadius, RemoveFromCell, self.logConn)
end 

function InfestationMap:DumpPoints()
    for k,v in pairs(self.cellPointMap) do
        Log("%s has %s entries", k, table.countkeys(v.infestTable) )
    end
end

function InfestationMap:DumpConns()
    for k,v in pairs(self.cellConnectMap) do
        Log("%s has %s entries", k, table.countkeys(v.infestTable) )
    end
end

function InfestationMap:DumpCellPoint(point)
    local cell = self.cellPointMap[PointToCellKey(point)]
    if cell then
        cell:Dump(point)
    else
        Log("No cell at %s", point)
    end
end

function InfestationMap:DumpCellConn(point)
    local cell = self.cellConnectMap[PointToCellKey(point)]
    if cell then
        cell:Dump(point)
    else
        Log("No cell at %s", point)
    end
end

function PointToCellKey(point)
    return math.floor(point.x - point.x % InfestationMap.kCellSize) .. "," .. math.floor(point.z - point.z % InfestationMap.kCellSize)
end

class "InfestationMapCell"

function InfestationMapCell:Init(point, logger)
    self.key = PointToCellKey(point)
    self.infestTable = {}
    logger("Cell %s created", self.key)
    return self
end

function InfestationMapCell:GetIsOnInfestation(point, verticalSize)
    local removes = {}
    local result = false
    for key,data in pairs(self.infestTable) do
        local range = point:GetDistanceTo(data.origin)
        Server.infestationMap.logPoint("%s vs %s", range, data.maxRadius)
        if range <= data.maxRadius then
            // possible candidate
            local infestation = Shared.GetEntity(data.id)
            if not infestation then
                // infestation is invalid, remove this data entry from the cell. 
                // This is a backup only, infestations should remove themselves when they are destroyed
                removes[key] = true
            else
                Server.infestationMap.logPoint("radius %s vs %s", range, infestation.radius)
                if range <= infestation.radius then
                    // Check dot product
                    local toPoint = point - data.origin
                    local verticalProjection = math.abs( infestation:GetCoords().yAxis:DotProduct( toPoint ) )
                    Server.infestationMap.logPoint("vertProj %s vs %s", verticalProjection,  verticalSize)
                    result = (verticalProjection < (verticalSize + kEpsilon))
                end
                Server.infestationMap.logPoint("%s -> %s", infestation, result)
                if result then
                    break
                end                
            end
        end
    end
    
    for key,_ in pairs(removes) do
        self.infestTable[key] = nil
    end
    
    return result
end

//
// Returns all infestations in range from the point
//
function InfestationMapCell:GetConnections(infestation)
    local result = {}
    local removes = {}
    local origin = infestation:GetOrigin()
    local infestRange = infestation:GetMaxRadius()
    for key,data in pairs(self.infestTable) do
        if data.id ~= infestation:GetId() then        
            local range = origin:GetDistanceTo(data.origin)
            local connRange = infestRange + data.maxRadius
            if range <= connRange then
                // Connectionrange is always maxRadius, so we don't need to look into the infestations actual radius
                local infestation = Shared.GetEntity(data.id)
                if not infestation then
                    removes[key] = true
                else
                    Server.infestationMap.logConn("Cell %s: conn to %s, maxR %s, connR %s, r %s", self.key, data.id, data.maxRadius, connRange, range)
                    result[infestation] = true            
                end
            end
        end
    end
    
    for key,_ in pairs(removes) do
        self.infestTable[key] = nil
    end
    
    return result
end
//
// add to the cell. Adding the same infestation to the same cell works fine. 
//
function InfestationMapCell:Add(infestation)
    self.infestTable["" .. infestation:GetId()] = {
            id = infestation:GetId(), 
            origin = infestation:GetOrigin(), 
            maxRadius = infestation.maxRadius
    }
end

//
// Remove an infestation
//
function InfestationMapCell:Remove(infestation)
    self.infestTable["" .. infestation:GetId()] = nil
end

function InfestationMapCell:Dump(point)
    Log("Cell %s", self.key)
    for key,data in pairs(self.infestTable) do
        Log("Infest-%s, maxRadius %s, origin %s, dist %s", key, data.maxRadius, data.origin, (point-data.origin):GetLength())
    end
end

