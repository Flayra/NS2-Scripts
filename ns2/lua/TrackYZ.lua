// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TrackYZ.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// A track between two points on a map that follows a straight XZ path, only diverging in height.
// Deals with building tracks from raw data, optimizing and packacke/unpackage it into strings.
//
// The TrackerYZ allows for a way to simply and efficiently follow a track.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================





class "TrackYZ"

// duration for dbg lines
TrackYZ.kTrace = false
TrackYZ.kTraceTrack = false
TrackYZ.kTraceDur = 30

TrackYZ.logTable = {}
TrackYZ.log = Logger("log", TrackYZ.logTable)

/**
 * initalize a track from a list of drop points, ie points dropped from a thrown object. 
 */
function TrackYZ:InitFromDropData(trackStart, trackEnd, dropPoints)
    self.trackStart = trackStart
    self.trackEnd = trackEnd
    self.points = self:Optimize(trackStart, trackEnd, dropPoints)  
    return self 
end

/**
 * Create a track from a string-encoded track and a starting point.
 */
function TrackYZ:InitFromYZEncoding(trackStart, trackEnd, encodedTrackYZ)
    self.trackStart = trackStart
    self.trackEnd = trackEnd
    self.points = self:DecodeYZ(encodedTrackYZ)
    return self
end

/**
 * Adds additional points to the path to ensure that no two points are more than
 * maxDistance apart.
 */
local function SubdividePathPoints(points, maxDistance)

    local numPoints   = #points
    
    local i = 1
    while i < numPoints do
        
        local point1 = points[i]
        local point2 = points[i + 1]

        // If the distance between two points is large, add intermediate points
        
        local delta    = point2 - point1
        local distance = delta:GetLength()
        local numNewPoints = math.floor(distance / maxDistance)

        for j=1,numNewPoints do

            local f = j / numNewPoints
            local newPoint = point1 + delta * f
            
            i = i + 1
            table.insert( points, i, newPoint )
            
        end 
        i = i + 1    
        numPoints = numPoints + numNewPoints
        
    end

end

/**
 * Returns a list of point connecting two points together. If there's no path, returns nil.
 */
local function FindConnectionPath(src, dst)
    
    local mask = CreateGroupsFilterMask(PhysicsGroup.StructuresGroup, PhysicsGroup.PlayerControllersGroup, PhysicsGroup.PlayerGroup)
    
    local climbAmount   = 0.3   // Distance to "climb" over obstacles each iteration
    local climbOffset   = Vector(0, climbAmount, 0)
    local maxIterations = 10    // Maximum number of attempts to trace to the dst
    
    local points = { } 
    
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
        
        local endPoint = GetTraceEndPoint(src, dst, trace, 0.1)
        local upPoint  = endPoint + climbOffset
        
        // Move up to the hit point and over any obstacles.
        trace = Shared.TraceRay( endPoint, upPoint, mask )
        src = GetTraceEndPoint(endPoint, upPoint, trace, 0.1)

    end
            
    return nil

end

/**
 * Create a track by iterative dropping until the endpoint is reached. Assumes that
 * the trackStart and trackEnd are not blocked. If no path found, returns nil.
 */
function TrackYZ:CreateBetween(trackStart, startNormal, trackEnd, endNormal)

    // This method is currently too slow.
    /*
    // move trackStart/trackEnd up 1cm 
    trackStart = trackStart + startNormal * 0.01
    trackEnd = trackEnd + endNormal * 0.01
    local finder = TrackFinder():Init(trackStart, startNormal, trackEnd, endNormal)
    if finder == nil then
        TrackYZ.log("CreateBetween, no finder")
        return nil
    end
    self.trackStart = trackStart
    self.trackEnd = trackEnd
    
    local dropPoints = finder.points
    if dropPoints then
        _DebugTrack(dropPoints, 60, 0, 1, 1, 1)
    end
    local gt = GroundTracker():Init(finder, dropPoints)
    if gt ==  nil then
       TrackYZ.log("CreateBetween, groundtrack failed")
        return nil
    end
    self.points = self:Optimize(trackStart, trackEnd, gt.groundTrack)
    if self.points == nil then
       TrackYZ.log("CreateBetween, optimize failed")
        return nil
    end
    _DebugTrack(self.points, 60, 1, 0, 1, 1)
    return self  
    */
    
    trackStart = trackStart + Vector(0, 0.25, 0)
    trackEnd   = trackEnd
    
    local points = FindConnectionPath(trackStart, trackEnd)
    
    if points then
        self.trackStart = trackStart
        self.trackEnd   = trackEnd
        self.points = points
        return self
    end
    
    return nil
    
end

function _DebugTrack(points, dur, r, g, b, a, force)
    if force or TrackYZ.kTraceTrack then
        local prevP = nil
        for _,p in ipairs(points) do
            if prevP then
                DebugLine(prevP, p,dur, r, g, b, a)
                DebugLine(p, p + Vector.yAxis , dur, r, g, b, a)
            end
            prevP = p
        end
    end
end

/**
 * Draw the track using the given color/dur (defaults to 30/green)
 */
function TrackYZ:Debug(dur, color)
    dur = dur or 30
    color = color or { 0, 1, 0, 1 }
    
    local r,g,b,a = unpack(color)
    
    _DebugTrack(self.points, dur,r,g,b,a, true)
end

// 
// Reverse the direction of the track. Modified in place.
//
function TrackYZ:Reverse()
    local rp = {}
    for i=#self.points, 1, -1 do
        table.insert(rp, self.points[i])
    end
    self.points = rp
    local tmp = self.trackStart
    self.trackStart = self.trackEnd
    self.trackEnd = tmp
end


//
// encoding/decoding block
// Right now we use YZ encoding, which means that all points are on the start/end plane, only varying in height. Extending the
// track to support free moving 
//

/**
 * Decode an YZ path, ie a path with the first byte encoding the change in y-value and the second byte the change along the
 * XZ vector from trackStart to trackEnd. 
 */
function TrackYZ:DecodeYZ(encodedTrackYZ) 
    local result = {}
    local vecXZ = GetNormalizedVectorXZ(self.trackEnd - self.trackStart)
    local p = self.trackStart
    local len = string.len(encodedTrackYZ)
    for i = 1,len,2 do
        table.insert(result, p)
        // unpack the encoded byte values. 128 offset distances in centimetres
        local yDist = (string.byte(encodedTrackYZ,i) - 128) / 100
        local zDist = (string.byte(encodedTrackYZ,i+1) - 128) / 100
        local v = vecXZ * zDist
        v.y = v.y + yDist
        p = p + v
    end
    table.insert(result, p)
    return result
end


/**
 * Encode the track as a string.
 * This can be used to create a copy of the track using InitFromPacked(),
 */
function TrackYZ:EncodeYZ()
    local result = ""
    local lastP = nil
    local vecXZ = GetNormalizedVectorXZ(self.trackEnd - self.trackStart)
    for _, p in ipairs(self.points) do
        if lastP then
            result = result .. self:CreateTrackSegmentYZ(vecXZ, lastP, p)
        end
        lastP = p
    end
    return result
end


// Create a track segment with the first byte encoding change in y and the second change along the XZ plane.
function TrackYZ:CreateTrackSegmentYZ(vecXZ, p1, p2)
    local vec = p2 - p1
    
    local zDist = math.round(vecXZ:DotProduct(vec) * 100)
    local yDist = math.round(vec.y * 100)
    // only allow +-127 (not -128; zero is not good to store in a string)
    assert(math.abs(zDist) < 128 and math.abs(yDist) < 128, string.format("zD %f, yD %f, vec %s", zDist, yDist, ToString(vec)))
    return string.char(128 + yDist, 128 + zDist)
end


//
// path optimization block
//

TrackYZ.kFilter = EntityFilterAll()

/**
 * Optimize an unoptimized list of points. 
 * Right now we don't optimize much at all - we ignore any non-los between points on the path.
 */
function TrackYZ:Optimize(firstPoint, lastPoint, dropPoints)

    local result = { firstPoint }
    // lastP is the last added point added to dropPoints. 
    // prevP is the the candidate to be added. It will be added if the current tp isn't on the
    // prevP - lastP vector, otherwise, if the current tp is on the vector, the current tp becomes the
    // prev and the prevP is skipped
    local lastP, prevP, points = firstPoint,nil, nil
    for _,dp in ipairs(dropPoints) do
        // make sure the segments we add are short enough to be compressed (1.2m or shorter)
        local segs = self:SplitIntoShortSegments(prevP or lastP, dp)
        for _,p1 in ipairs(segs) do
            if prevP then
                points, prevP = self:FindPath(lastP, prevP, p1)
                if points then
                    for _,p2 in ipairs(points) do
                        table.insert(result, p2) 
                        lastP = p2
                    end
                end
            else
                prevP = p1
            end
        end
    end
    table.insert(result, prevP)
    local segs = self:SplitIntoShortSegments(prevP, lastPoint)
    for _,p1 in ipairs(segs) do
        table.insert(result, p1)
    end
    return result     
end


/**
 * Split the track into short, 1.2m long segments
 */
function TrackYZ:SplitIntoShortSegments(p1, p2)
    local vec = p2 - p1
    local dist = vec:GetLength()
    local result = {}
    vec:Normalize()
    while dist > 1.2 do
        local p = p1 + vec * 1.2
        table.insert(result, p)
        dist = dist - 1.2
        p1 = p        
    end
    table.insert(result, p2)
    
    return result
end


/**
 * Find a path from prevP to dp, returning added points and the next prevP.
 * 
 * Skip points that are on the same vector or close to the vector.
 * 
 * TODO: use tracing and trace.normal analysies to ensure that points are in LOS from each other, adding
 * more points if necessary.
 */
function TrackYZ:FindPath(lastP, prevP, p)
    // check if 
    local v1 = (prevP - lastP)
    local v2 = (p - lastP)
    // each segment must be < 1.2 m due to path compression (+-127cm, one signed byte)
    if v2:GetLength() < 1.2 then
        local scale = v1:DotProduct(v2) / v2:GetLength()
        // as we are often so close to zero here, the contents of the root may round off into negative values ... abs stops that
        local rootV = v1:GetLengthSquared() - scale*scale
        local dist = v1:GetLength() * math.sqrt(math.abs(rootV))
        // Log("scale %s, dist %s, v1 len %s, v2 len %s, rootV %s", scale, dist, v1:GetLength(), v2:GetLength(), rootV)
        if dist < 0.01 then
            // practially on it, so skip it
            return nil, p
        end
        if dist < 0.05 then
            // skip it if we have a LOS between the lastP and the p
           local trace = Shared.TraceRay(lastP, p, PhysicsMask.Bullets, TrackYZ.kFilter)
           if trace.fraction > 0.99 then
               return nil, p
           end
       end 
    end
    return { prevP }, p
end



class "TrackerYZ"

/**
 * A tracker follows a track until its end. Advance it with a deltaTime to get
 * the point it has advanced to, or until it returns nil indicating end of track.
 */
function TrackerYZ:Init(startTime, speed, trackYZ)
    self.speed = speed
    self.track = trackYZ
    self.pathLen = #(trackYZ.points)
    self:Restart(startTime)
    return self
end

function TrackerYZ:Restart(startTime)
    self.startTime = startTime
    self.currentTime = startTime
    self:StartOnSegment(1)
end

function TrackerYZ:StartOnSegment(index)
    ASSERT(index < table.count(self.track.points))
    ASSERT(index >= 1)    
    self.index = index
    self.segment = self.track.points[index+1]-self.track.points[index]
    self.length = self.segment:GetLength()
    self.segmentLengthRemaining = self.length
end

/**
 * Advance to the given time, returning the new point or nil 
 * if end of track reached
 */
function TrackerYZ:AdvanceTo(time)
    if self.index == self.pathLen then
        return nil
    end
    local deltaTime = time - self.currentTime
    self.currentTime = time
    
    local length = self.speed * deltaTime
    
    while length > self.segmentLengthRemaining do
        self.index = self.index + 1
        if self.index == self.pathLen then
            return nil
        end
        length = length - self.segmentLengthRemaining
        self:StartOnSegment(self.index)        
    end
    self.segmentLengthRemaining = self.segmentLengthRemaining - length
    local fraction = (self.length - self.segmentLengthRemaining) / self.length
    return self.track.points[self.index] + self.segment * fraction
end



class "TrackFinder"

TrackFinder.kStepLength = 0.3

// no backing geometry below techpoints?
function TrackEntityFilter()
    return function(test) return not test:isa("TechPoint") end
end

function TrackFinder:Init(trackStart, startNormal, trackEnd, endNormal)

    PROFILE("TrackFinder:Init")

    self.mask = PhysicsMask.Bullets
    self.filter = TrackEntityFilter()

    // this is the axis along which we will draw the track. 
    local v = trackEnd - trackStart
    self.axisXZ = GetNormalizedVectorXZ(v)
    // calculate the wedge extents (the wedge is the box used to see if we can move in space)
    // to make the length of the world-axis aligned box kStepLength
    local len1 = self.axisXZ.x * TrackFinder.kStepLength
    local len2 = self.axisXZ.z * TrackFinder.kStepLength
    local len = math.sqrt(len1 * len1 + len2 * len2)

    ASSERT(len > 0)
    ASSERT(TrackFinder.kStepLength > 0)

    self.wedgeExtents = Vector(len, TrackFinder.kStepLength, len) * 0.5
    
    self.trackStart = self:FindTrackTerminal(trackStart, self.axisXZ)
    self.trackEnd = self:FindTrackTerminal(trackEnd, -self.axisXZ)
    
    if self.trackStart == nil or self.trackEnd == nil then 
        TrackYZ.log("Failed finding terminal, %s/%s", self.trackStart, self.trackEnd)
        return nil
    end
    
    self.endX = math.floor(self.axisXZ:DotProduct(v) / TrackFinder.kStepLength)
    self.endY = math.floor(math.abs(self.trackEnd.y - self.trackStart.y)) / TrackFinder.kStepLength
    if self.trackEnd.y < self.trackStart.y then
        self.endY = -self.endY
    end

    //Log("TrackFind %s to %s(%s), axis %s", self.trackStart, self.trackEnd, trackEnd, self.axisXZ)
    

    self.points = self:FloodFillPath()
    if self.points then
        table.insert( self.points , 1, trackStart)
        table.insert( self.points, trackEnd)
        return self
    end
    return nil
end


/**
 * Find the terminal for a track starting at the given point p and moving along the xzAxis
 */
function TrackFinder:FindTrackTerminal(p, xzAxis)
    // we track from a starting point 3 (or 1) step lengths from it along the xz axis, with five different
    // y-axis origins, returning the first one that manages to move a bit. The point returned is the point of
    // impact, moved 0.01m back towards the trace origin.
    for _,y in ipairs({0,1,2,-1,-2}) do
        local startPoint, trace = self:TerminalTrace(p, xzAxis, 3, y)
        TrackYZ.log("trace %s, f %s", y, trace.fraction)
        if trace.fraction == 0 then
            // try again, closer this time
            startPoint, trace = self:TerminalTrace(p, xzAxis, 1, y)      
            TrackYZ.log("trace2 %s, f %s", y, trace.fraction)
        end
        if trace.fraction > 0 then
            local v = GetNormalizedVector(trace.endPoint - startPoint)
            local endPoint = trace.endPoint - v * 0.01 // move back a little from the hit point  
            // make sure that the point is visible using a standard thin ray 
            local thinTrace = Shared.TraceRay(endPoint, p, self.mask, self.filter)
            if thinTrace.fraction > 0.99 then 
                return endPoint
            end
            TrackYZ.log("Failed thinTrace, f %s, e %s, p %s, ep %s, adj ep %s", thinTrace.fraction, thinTrace.entity, p, trace.endPoint, endPoint)          
        end
    end
    return nil
end


function TrackFinder:TerminalTrace(p, xzAxis, xz, y)
    
    PROFILE("TrackFinder:TerminalTrace")

    local startP = p + (xzAxis * xz + Vector.yAxis * y) * TrackFinder.kStepLength
    local trace = Shared.TraceBox(self.wedgeExtents, startP, p, self.mask, self.filter)
    if TrackYZ.kTraceTrack then
        DebugTraceBox(self.wedgeExtents, startP, trace.endPoint, 30, 1,0,0,1)
    end
    return startP,trace
end

/**
 * Another attempt. Instead of following the surface, we coarsen the world into cubes. Every
 * trace we do go directly from one cube to one of its direct neighbours. All traces are vertical or
 * horizontal, and always just one step. We always choose to move towards our goal as directly as possible.  
 * Thinking of the movement only in two dimensions, with x moving horizontally towards the goal and y vertically
 * (so dx to goal is always > 0, while dy can be < 0). 
 * default direction is always along the x axis, (dir 0). 
 * Snake towards the goal. Turn left or right, fail if we turn 360 degrees
 */
function TrackFinder:FloodFillPath()
    
    PROFILE("TrackFinder:FloodFillPath")

    self.floodFillTable = {}
    self.planHeap = PriorityQueue():Init(function(p1,p2) return p1.cost < p2.cost end)
    self.traceCount = 0 
    
    local e = FFEntry():InitReachable(self, 0, 0, nil, 0)
    self.floodFillTable[e:GetKey()] = e
    e:Expand()
    
    // Log("Floodfill to %s,%s", self.endX, self.endY)
    
    local maxTraces = 50
    
    local minDistance = TrackFinder.kStepLength * 2
    minDistance = minDistance * minDistance 

    local px,py = 0,0
    local count = 0
    while self.planHeap.size > 0 and self.traceCount < maxTraces do
        count = count + 1
      
        local plan = self.planHeap:Dequeue()
        
         // execute the plan
        local point = plan.ffe:GetPoint()
        local dist = self.trackEnd:GetDistanceSquared(point)
        // Log("%s (tc %s): plan %s, dist %s", count, self.traceCount, plan:tostring(), dist)
      
        // if distance to trackEnd is short enough, try a direct trace
        if dist < minDistance then
            local endTrace = Shared.TraceRay(point, self.trackEnd, self.mask, self.filter)
            //Log("EndCheck, trace %s/%s vs %s", endTrace.fraction, endTrace.endPoint, self.trackEnd)
            if endTrace.fraction > 0.999 then
                //Log("Found %s in %s steps", endTrace.endPoint, self.traceCount )
                local e = plan.ffe
                local t = { self.trackEnd }
                while e do
                    table.insert(t, e:GetPoint())
                    e = e.parent
                end
                local result = { self.trackStart }
                local len = #t
                for i,p in ipairs(t) do
                    table.insert(result, t[len - i + 1])
                end
                return result
            end
        end
        plan:Execute()
    end

    return nil
end

function TrackFinder:GetPointFromXY(x,y)
    return self.trackStart + (self.axisXZ * x + Vector.yAxis * y) * TrackFinder.kStepLength
end


TrackFinder.kDirX = { 1,1,0,-1,-1,-1,0,1 }
TrackFinder.kDirY = { 0, -1,-1,-1,0,1,1,1 } 

// flood-fill plan. a flood-fill entry + direction + the potential least cost if the plan is followed

class "FFPlan"

function FFPlan:Init(ffe, dir)
    self.ffe = ffe
    self.dir = dir
    // figure out how close to the target we can using this direction
    local distX,distY = ffe.finder.endX - ffe.x, ffe.finder.endY - ffe.y
    local dx,dy = TrackFinder.kDirX[dir],TrackFinder.kDirY[dir]
    local ddX,ddY = distX - dx, distY - dy
    local xIncreasing = math.abs(ddX) > math.abs(distX)         
    local yIncreasing = math.abs(ddY) > math.abs(distY)
    
    // if either x or y increases the distance to the target, we only step one
    self.len = 1
    local directStepCost = math.sqrt(dx*dx + dy*dy)
    local directCost = directStepCost

    if not xIncreasing and not yIncreasing then
        // otherwise, we step until one of dx,dy hits zero
        self.len = dx == 0 and math.abs(distY) or (dy == 0 and math.abs(distX) or math.min(math.abs(distY), math.abs(distX)))
        // figure out the cost
        ddX = distX - dx * self.len
        ddY = distY - dy * self.len
        directCost = directStepCost * self.len
    end
    local remainingCost = math.sqrt(ddX * ddX + ddY * ddY)
    // balance costs. Already paid-for costs are 1.0, direct costs add 10%, remaining costs are double
    // so we will always try plans that are closer to the target
    self.cost = ffe.cost + directCost * 1.1 + remainingCost * 2
    return self
end

function FFPlan:Execute()
    PROFILE("FFPlan:Execute")
    self.ffe:TraceDir(self.dir, self.len)
end

function FFPlan:tostring()
    return string.format("%s[dir=%d,len=%d,cost=%f]", self.ffe:tostring(), self.dir, self.len, self.cost)
end

// FloodFillEntry. Entries into the floodFillTable
class "FFEntry"

function FFEntry:InitReachable(finder, x, y, parent, cost)
    self.finder = finder
    self.x = x
    self.y = y
    self.parent = parent
    self.blocked = false 
    self.cost = cost
    self.tried = false
    return self
end

function FFEntry:InitBlocked(finder, x,y)
    self.finder = finder
    self.x = x
    self.y = y
    self.blocked = true
    self.cost = 10000000
    return self
end

function FFEntry:tostring()
    return string.format("FFE[%d,%d/%s]", self.x, self.y, self.blocked and "#" or string.format("%s", self.cost))
end


function FFEntry:Expand()   
    // add plans in all plausible directions from here
    for dir = 1,8 do
        local dx,dy = TrackFinder.kDirX[dir],TrackFinder.kDirY[dir]
        local nx = self.x + dx
        local ny = self.y + dy
        local key = self:GetKey(nx,ny)
        local cost = self.cost + math.sqrt(dx * dx + dy * dy)
        local te = self.finder.floodFillTable[key]
        // if someone else has already been there cheaper, or its unreachable, we skip it
        if not te or (te.cost > cost and not te.blocked) then
            self.finder.planHeap:Enqueue(FFPlan():Init(self, dir))
        else
            // Log("%s: block plan to expand in dir %s, found %s", self:tostring(), dir, te:tostring())
        end
   end
   self.tried = true
end


function FFEntry:GetKey(x,y)
    x = x or self.x
    y = y or self.y
    return string.format("%s,%d", x, y)
end


function FFEntry:GetPoint(x, y)
    x = x or self.x
    y = y or self.y
    return self.finder:GetPointFromXY(x, y)
end


function FFEntry:TraceDir(dir, len)
    
    PROFILE("FFEntry:TraceDir")

    local fft = self.finder.floodFillTable
    local dx,dy = TrackFinder.kDirX[dir],TrackFinder.kDirY[dir]
    local nx,ny = self.x + dx, self.y + dy
    
    // check if we first square we are thinking of expanding into has already been checked
    local te = fft[self:GetKey(nx,ny)]
    if te and (te.blocked or te.cost <= self.cost + math.sqrt(dx*dx + dy * dy)) then
        // Log("Bad plan to expand from %s dir %s len %s", self:tostring(), dir, len)
        return 
    end 
    
    local point = self:GetPoint()

    local targetP = self:GetPoint(self.x + dx * len, self.y + dy * len)
    local trace = Shared.TraceBox(self.finder.wedgeExtents, point, targetP, self.finder.mask, self.finder.filter)
    self.finder.traceCount = self.finder.traceCount + 1
    // Print("[%d,%d], dir %d [%d,%d], len %d, frac %f: %s -> %s", self.x, self.y, dir, dx, dy, len, trace.fraction, ToString(point), ToString(targetP))
    self.finder:DbgTrace(point,trace.endPoint,0,0,1)

    local parent = self
    local costPerStep = math.sqrt(dx*dx + dy*dy)
    for i = 1, len do
        local x = self.x + dx * i
        local y = self.y + dy * i
        local f = i / len // need to add a little here?
        local key = self:GetKey(x,y)
        if f <= trace.fraction then
            local cost = parent.cost + costPerStep
            local te = fft[key]
            if not te or te.cost > cost then
                fft[key] = FFEntry():InitReachable(self.finder, x, y, parent, cost)
                fft[key]:Expand()    
            end                            
            parent = fft[key] 
        else
            // block x,y
            fft[key] = FFEntry:InitBlocked(self.finder, x, y)
            //Log("Block %s", fft[key]:tostring())
            local p = self.finder:GetPointFromXY(x, y)
            self.finder:DbgTrace(p,p,1,0,0)
            // and stop
            break
        end
    end
end


function TrackFinder:DbgTrace(p1,p2,r,g,b)
    if TrackYZ.kTrace then
        local offs = Vector.yAxis * self.wedgeExtents.y
        DebugTraceBox(self.wedgeExtents, p1, p2, TrackYZ.kTraceDur, r, g, b, 1) 
    end
end


class "GroundTracker"

GroundTracker.kSegmentLength = 0.2

function GroundTracker:Init(trackFinder,overheadPoints)
    self.trackFinder = trackFinder
    self.overheadPath = self:SplitIntoSegments(overheadPoints)   
    self.groundTrack = {}
    local lastPoint = self.overheadPath[1] // starting and ending points of overhead is trackstart/trackend
    local extraPoints = nil
    for i = 2,#self.overheadPath do
        extraPoints, lastPoint = self:BuildTrack(i, lastPoint)
        if extraPoints == nil then
            return nil
        end
        for _,p in ipairs(extraPoints) do
            table.insert(self.groundTrack,p)
        end
        table.insert(self.groundTrack,lastPoint)
    end

    _DebugTrack(self.groundTrack, 20, 0, 0, 1, 1)
    
    return self
end

/**
 * Use the overhead path to make a ground-based path. We use a segment/los based approach, dropping a point
 * every segment1 length and checking LOS between them. If no LOS, we spam the whole segment with tight drops
 * without bothering to check LOS. The Track optimizer will remove any extra points.
 */
function GroundTracker:SplitIntoSegments(points)
    local prevP = points[1]
    local result = { prevP }
    local distLeft = GroundTracker.kSegmentLength
    for i=2,#points do
        local p = points[i]
        while true do
            local vec = p - prevP
            local distXZ = vec:GetLengthXZ()
            local frac = distLeft / distXZ
            if frac < 1 then
                // insert a point before p
                local overheadPoint = prevP + vec * frac
                table.insert(result, overheadPoint)
                distLeft = GroundTracker.kSegmentLength
                prevP = overheadPoint
            else
                // consume the rest of the distance and grab the next point
                distLeft = distLeft - distXZ
                break
            end 
        end            
    end
    table.insert(result, points[#points])
    return result
end

/**
 * Drop a point from the overhead point. If the dropped-to point is out of los from the last dp, we 
 * try dropping a point in between.
 */
function GroundTracker:BuildTrack(index, lastDp)
    local result = {}
    local overheadPoint = self.overheadPath[index]
    local baseOHP = self.overheadPath[index-1]
    local vector = overheadPoint - baseOHP
    local frac = 1
    local split = 1   
    //Print("GT start %d, vector %s, lastDp %s", index, ToString(vector), ToString(lastDp))
    // we will move the lastDp forward, so we keep track of how much fraction we have managed to move it forward
    local lastDpFrac = 0 
    local count = 0
    while count < 200 do
        count = count + 1
        local dp, losFrac = self:DropPoint(baseOHP + vector * frac, lastDp)
        if losFrac > 0.999 then
            if frac > 0.999 then
                // done!
                //Print("GT %d, #extra %d, dp %s", index, #result, ToString(dp))
                return result, dp
            end
            //Print("GT inter %d, frac %f, losFrac %f, dp %s", index, frac, losFrac, ToString(dp))
            // intermediate result. We can see dp from lastDp, so add it to extra points
            table.insert(result, dp)
            lastDp = dp
            lastDpFrac = frac;
            // try going for the target point again
            frac = 1
            split = 1
        else
            // try to move part of the way there
            split = split + 1
            frac = lastDpFrac + (1 - lastDpFrac) / split           
        end 
    end
    
    return nil
end

/**
 * Drop the overheadpoint, returning its dropped-to point and the line of sight trace fraction from the lastDp to the dropped-to point
 */
function GroundTracker:DropPoint(ohp, lastDp)

    PROFILE("GroundTracker:DropPoint")

    local tf = self.trackFinder
    local trace = Shared.TraceBox(tf.wedgeExtents, ohp, ohp - Vector.yAxis * 10, tf.mask, tf.filter)
    local ep = trace.endPoint
    local losTrace = Shared.TraceRay(lastDp, ep, tf.mask, tf.filter)
    if TrackYZ.kTrace then
        DebugLine(ohp, ep, TrackYZ.kTraceDur, 1, 1, 1, 1)
    end
    return ep, losTrace.fraction
end


/**
 * Implement a priority queue (or priority heap). The topmost entry is always the smallest.
 */
class "PriorityQueue"
 
function PriorityQueue:Init(compareTo)
    self.heap = {}
    self.size = 0
    self.compareTo = compareTo
    return self
end
 
function PriorityQueue:Enqueue(value)
    local hole = self.size
    self.size = self.size + 1
    local h2 = math.floor(hole / 2)
    while hole > 0 and self.compareTo(value,self.heap[h2]) do
        self.heap[hole] = self.heap[h2]
        hole = h2
        h2 = math.floor(h2 / 2)
    end 
    self.heap[hole] = value
end

function PriorityQueue:Dequeue()
    local result = self.heap[0]
    self.size = self.size - 1
    if self.size > 0 then
        // move the last element in to replace the top, then percolate them...
        self.heap[0] = self.heap[self.size]
        self.heap[self.size] = nil
        local hole = 0
        while true do
            local ci = (hole + 1) * 2
            local child1 = self.heap[ci-1]
            local child2 = self.heap[ci]
            local child = child2 or child1
            if not child then
                break
            end         
            child = child1 and child2 and (self.compareTo(child2,child1) and child2 or child1) or child
            ci = ci - (child == child1 and 1 or 0)
            self.heap[ci] = self.heap[hole]
            self.heap[hole] = child
            hole = ci
        end
    end
    return result
end

function PriorityQueue:Dump()
    for i = 0, self.size-1 do
        Log("%s: %s", i, self.heap[i] and self.heap[i]:tostring() or "nil")
    end
end 
 
