// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PathingMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * Adds additional points to the path to ensure that no two points are more than
 * maxDistance apart.
 */
local function SplitPathPoints(points, maxDistance)
    PROFILE("SplitPathPoints") 
    local numPoints   = #points    
    local maxPoints   = 2
    numPoints = math.min(maxPoints, numPoints)    
    local i = 1
    while i < numPoints do
        
        local point1 = points[i]
        local point2 = points[i + 1]

        // If the distance between two points is large, add intermediate points
        
        local delta    = point2 - point1
        local distance = delta:GetLength()
        local numNewPoints = math.floor(distance / maxDistance)
        local p = 0
        for j=1,numNewPoints do

            local f = j / numNewPoints
            local newPoint = point1 + delta * f
            if (table.find(points, newPoint) == nil) then
                i = i + 1
                table.insert( points, i, newPoint )
                p = p + 1
            end                     
        end 
        i = i + 1    
        numPoints = numPoints + p        
    end    
end

local function TraceEndPoint(src, dst, trace, skinWidth)

    local delta    = dst - src
    local distance = delta:GetLength()
    local fraction = trace.fraction
    fraction = Math.Clamp( fraction + (fraction - 1.0) * skinWidth / distance, 0.0, 1.0 )
    
    return src + delta * fraction

end

/**
 * Returns a list of point connecting two points together. If there's no path, returns nil.
 */
local function GeneratePath(src, dst)
    PROFILE("GeneratePath")  
    local mask = CreateGroupsFilterMask(PhysicsGroup.StructuresGroup, PhysicsGroup.PlayerControllersGroup, PhysicsGroup.PlayerGroup)    
    local climbAmount   = 0.3   // Distance to "climb" over obstacles each iteration
    local climbOffset   = Vector(0, climbAmount, 0)
    local maxIterations = 10    // Maximum number of attempts to trace to the dst
    
    local points = { }    
    
    // Query the pathing system for the path to the dst
    // if fails then fallback to the old system
    Pathing.GetPathPoints(src, dst, points)

    // HACKS
    if (#(points) > 0) then
        table.insert( points, #(points) - 1, dst )    
    end
    
    if (#(points) ~= 0 ) then        
        SplitPathPoints( points, 0.5 )        
        return points
    end        
    
    for i=1,maxIterations do

        local trace = Shared.TraceRay(src, dst, mask)
        table.insert( points, src )
        
        if trace.fraction == 1 or trace.endPoint:GetDistanceSquared(dst) < (0.25 * 0.25) then
            table.insert( points, dst )
            SubdividePathPoints( points, 0.5 )
            return points
        elseif trace.fraction == 0 then
            return nil
        end
        
        local endPoint = TraceEndPoint(src, dst, trace, 0.1)
        local upPoint  = endPoint + climbOffset
        
        // Move up to the hit point and over any obstacles.
        trace = Shared.TraceRay( endPoint, upPoint, mask )
        src = TraceEndPoint(endPoint, upPoint, trace, 0.1)

    end
            
    return nil

end

function GetPointDistance(points)
    if (points == nil) then
      return 0
    end
    local numPoints   = #points
    local distance = 0
    local i = 1
    while i < numPoints do
      if (i > 1) then    
        distance = distance + (points[i - 1] - points[i]):GetLength()
      end
      i = i + 1
    end
    
    distance = math.max(0.0, distance)
    return distance
end

PathingMixin = { }
PathingMixin.type = "Pathing"

function PathingMixin.__prepareclass(toClass)      
end

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
    self.points = GeneratePath(src, dst)    
    self.distanceRemain = GetPointDistance(self.points)    
    return (self.points ~= nil)
end

function PathingMixin:GetPath(src, dst)
    return GeneratePath(src, dst)
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
     self.distanceRemain = (dst - self:GetOrigin()):GetLength()
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