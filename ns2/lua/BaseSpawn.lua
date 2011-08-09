// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BaseSpawn.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Spawn points are stored in global server list so they don't need the overhead of entities.
// 
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'BaseSpawn'

BaseSpawn.kBaseSpawnMapName = "base_start"

function BaseSpawn:OnCreate()

    self.origin = Vector(0, 0, 0)
    self.angles = Angles(0, 0, 0)
    self.isMapEntity = false
    
end

function BaseSpawn:GetOrigin()
    return self.origin
end

function BaseSpawn:SetOrigin( origin )
    self.origin = origin
end

function BaseSpawn:GetAngles()
    return self.angles
end

function BaseSpawn:SetAngles( angles )
    self.angles.yaw = angles.yaw
    self.angles.pitch = angles.pitch
    self.angles.roll = angles.roll
end

function BaseSpawn:OnLoad()
end

function BaseSpawn:SetMapEntity()
    self.isMapEntity = true
end

function BaseSpawn:GetIsMapEntity()
    return self.isMapEntity
end

