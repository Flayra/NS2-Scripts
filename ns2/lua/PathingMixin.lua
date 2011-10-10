// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PathingMixin.lua    
//
// Created by: Andrew Spiering (andrew@unknownworlds.com) 
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PathingUtility.lua")

PathingMixin = { }
PathingMixin.type = "Pathing"

function PathingMixin:__initmixin()
    self.obstacleId = nil
    
    self.index = 0
    self.segment = 0
    self.length = 0
    self.segmentLengthRemaining = 1
    
    self.points = nil

    self.startTime = time
    self.currentTime = time        
    self.pathLen = 0
    self.distanceRemain = nil
    self.currentPoint = Vector()  
end

function PathingMixin:GetPoints()
    return self.points
end

function PathingMixin:GetNumPoints()
 if (self.points) then
   return #(self.points)
 end
 
 return 0  
end

function PathingMixin:AddToMesh()
   local position, radius, height = self:_GetPathingInfo()   
   self.obstacleId = Pathing.AddObstacle(position, radius, height)   
end

function PathingMixin:RemoveFromMesh()
    if (self.obstacleId ~= nil) then
      Pathing.RemoveObstacle(self.obstacleId)
    end
    
    self.obstacleId = nil
end

function PathingMixin:GetObstacleId()
    return self.obstacleId
end

function PathingMixin:_GetPathingInfo()
  local radius = 1.0
  local height = 2.0
  local position = self:GetOrigin()    
  local model = Shared.GetModel(self.modelIndex)  
  if (model ~= nil) then
    local min, max = model:GetExtents()        
    local extents = max
    radius = (extents.x + extents.z * 0.5) / 2
    height = extents.y;
  end
  
  position = position + Vector(0, -100, 0)
  
  if (self.GetPathingInfoOverride) then
    self:GetPathingInfoOverride(position, radius, height)
  end
  
  return position, radius, 1000
end

function PathingMixin:StartOnSegment(index)
    ASSERT(index <= self.pathLen)
    ASSERT(index >= 1)    
    self.index = index
    if index < self.pathLen then
        self.segment = self.points[index+1]-self.points[index]
    else
        self.segment = Vector(0, 0, 0)
    end
    self.length = self.segment:GetLength()
    self.segmentLengthRemaining = self.length
end

function PathingMixin:RestartPathing(time)
    self.startTime = time
    self.currentTime = time
    self.index = 1  
    self.pathLen = #(self.points)
    self.currentPoint = Vector()
    self.distanceBetween = 0
    self:StartOnSegment(1)
end

function PathingMixin:BuildPath(src, dst)    
    self.points = GeneratePath(src, dst, true, 0.5, 2)    
    self.distanceRemain = GetPointDistance(self.points)    
    return (self.points ~= nil)
end

function PathingMixin:GetPath(src, dst)
    return GeneratePath(src, dst)
end

function PathingMixin:DrawPath(src, dst, lifetime, r, g, b, a)

    self.points = GeneratePath(src, dst)    
    
    if self.points then
    
        DebugLine(src, self.points[1], lifetime, r, g, b, a)
        
        for index = 2, table.count(self.points) do
            DebugLine(self.points[index - 1], self.points[index], lifetime, r, g, b, a)    
        end
        
    end
    
end

function PathingMixin:IsPathValid(src, dst)
    if self.points == nil or #(self.points) == 0 then
      return false
    end        
    
    local endPoint = self.points[#(self.points) - 1]
    if (endPoint == nil) then
      return false
    end
    
    local diff = VectorAbs(dst - src);

    local targetEpsilon = 0.01

    // if the target has changed, the path needs recomputation;
    if ((diff.x > targetEpsilon) or (diff.y > targetEpsilon) or (diff.z > targetEpsilon)) then
        return false
    end    
    return true
end

function PathingMixin:IsPathBlock(src, dst)
    return Pathing.IsBlocked(src, dst)
end

function PathingMixin:IsTargetReached(dst, withIn, clearValue)
   if (self.distanceRemain  == nil) then
     self.distanceRemain = (dst - self:GetOrigin()):GetLengthXZ()
   end
   
   local result = false
   
   local diff = self.distanceRemain
   if (diff < withIn) then
     result = true     
   end
   
   if (clearValue == true and result == true) then
    self.distanceRemain = nil
   end
   
   return result
end

function PathingMixin:GetPathDirection()
  local direction = Vector(self:GetAngles():GetCoords().zAxis)
  local numPoints = #(self.points)
  local curPt = self.points[self.index]
  if (curPt ~= nil) then  
    local diff = (curPt - self:GetOrigin()):GetLength()    
    if (diff > 0) then
        direction = curPt - self:GetOrigin()        
        direction = direction:GetUnit()    
    end    
  end 
  
  return direction
end

function PathingMixin:GetNextPoint(time, speed)
    self.currentPoint = self:AdvanceToNextPoint(time, speed)    
    return self.currentPoint
end

function PathingMixin:GetCurrentPathPoint()
    return self.currentPoint
end

function PathingMixin:AdvanceToNextPoint(deltaTime, speed) 
    PROFILE("PathingMixin:AdvanceToNextPoint")
    
    // $AS - if we get here something has gone wrong
    if (self.distanceRemain == nil) then
      return self:GetOrigin()
    end
    
    local amount = deltaTime * speed     
    local currPt = self:GetOrigin()
    local nextPt = self.points[self.index]
    
    local ptDir = nextPt - currPt
    local ptLength = ptDir:GetLength()
    
    local moveAmount = 0
    if (ptLength > (self.distanceBetween + amount)) then
      moveAmount = amount
    else
      local remainder = (self.distanceBetween + amount) - ptLength
      while self.index + 1 < self.pathLen - 1 do
        currPt =  self.points[self.index]
        nextPt =  self.points[self.index + 1]     
        ptDir  =  nextPt - currPt
        ptLength = ptDir:GetLength()
        if (remainder < ptLength) then
          moveAmount = remainder
          break
        end       
        remainder = remainder - ptLength
        self.index = self.index + 1
        
        self:StartOnSegment(self.index)        
       end
    end 
    
    local outLocation = currPt + ptDir * moveAmount
    self.distanceBetween = moveAmount
    self.distanceRemain = math.max(0.0, self.distanceRemain - amount)    
    
    return outLocation
    
    
end

function PathingMixin:SetPathingFlags(flags)
  local model = Shared.GetModel(self.modelIndex) 
  local extents = nil
  local position = self:GetOrigin()
  
  if (model ~= nil) then
    local min, max = model:GetExtents()
    extents = max
  end
  
  if (self.GetPathingFlagOverride) then
    position, extents, flags = self:GetPathingFlagOverride(position, extents, flags)
  end
  
  if (extents ~= nil) then
    Pathing.SetPolyFlags(position, extents, flags)
  end  
end

function PathingMixin:ClearPathingFlags(flags)
  local model = Shared.GetModel(self.modelIndex) 
  local extents = nil
  local position = self:GetOrigin()

  
  if (model ~= nil) then
    local min, max = model:GetExtents()
    extents = max
  end
  
  if (self.GetPathingFlagOverride) then
    position, extents, flags = self.GetPathingFlagOverride(position, extents, flags)
  end
  
  if (extents ~= nil) then
    Pathing.ClearPolyFlags(position, extents, flags)
  end  

end

function PathingMixin:GetAddToPathing()
  if (self.GetAddToPathingOverride) then
    return self:GetAddToPathingOverride()
  end
  
  return false
end

function PathingMixin:OnInit()
    if (self:GetAddToPathing()) then
      self:AddToMesh()     
    end
end

function PathingMixin:OnDestroy()
    self:RemoveFromMesh()
end

/**
 * This is the bread and butter of PathingMixin.
 */
function PathingMixin:MoveToTarget(physicsGroupMask, location, movespeed, time)

    PROFILE("PathingMixin:MoveToTarget")
    
    local movement = nil
    local newLocation = self:GetOrigin()
    local now = Shared.GetTime()
    local hasReachedLocation = false//self:IsTargetReached(location, 0.01, true)
    
    local direction = (location - self:GetOrigin()):GetUnit()
    if not (hasReachedLocation) then
        if not self:IsPathValid(self:GetOrigin(), location) then
            if not (self:BuildPath(self:GetOrigin(), location)) then
              return
            end
        end
        
        if (self:GetCurrentPathPoint() ~= nil and self:GetNumPoints() >= 1) then
            self:RestartPathing(now)
            local point = self:GetNextPoint(time, movespeed)
            if (point ~= nil) then
                newLocation = point
                direction = self:GetPathDirection()
                SetAnglesFromVector(self, direction)
            end
        end
    end
       
    // $AS FIXME: This is a hack for the whip since its a "structure"
    // and not reall an AI unit like the other units it does not 
    // have all the other controller parts. 
    if (self.AdjustPathingLocation) then
        newLocation = self:AdjustPathingLocation(newLocation)
    end

        
    if self:GetIsFlying() then        
        newLocation = GetHoverAt(self, newLocation)
    end
    
    
    
    self:SetOrigin(newLocation)
    
    
    if self.controller then    
        self:UpdateControllerFromEntity()
        
        local movementVector = newLocation         
        if not self:GetIsFlying() then
            local movementVector = Vector(0, -1000, 0)
            self:PerformMovement(movementVector, 1)   
        end         
    end
    
end

local function FindClosetWaypoint(points, location)

    local closestIndex = -1
    local closestPointSqDist = 999999999
    
    if points == nil or #points == 0 then
        return closestIndex
    end
    
    for index, point in ipairs(points) do
    
        local point = points[index]
        local dir = location - point
        local length = dir:GetLengthSquared()
        
        if length < closestPointSqDist then
        
            closestIndex = index
            closestPointSqDist = length
            
        end
        
    end
    
    return closestIndex
    
end

function PathingMixin:GetNextWayPoint(physicsGroupMask, location)

    local points = GeneratePath(self:GetOrigin(), location, true, 15.0)
    local closestPoint = FindClosetWaypoint(points, self:GetOrigin())
    
    if points == nil then
        return Vector(0, 0, 0)
    end
    
    if #points > 1 then
    
        if closestPoint + 1 >= #points then           
            return points[closestPoint]
        end
        
        return points[closestPoint + 1]
        
    end
    
    return Vector(0, 0, 0)
 
end