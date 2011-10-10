//======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PathingUtility.lua
//
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)
//
// Pathing-specific utility functions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

// Script based pathing flags

kLastFlag = Pathing.PolyFlag_Infestation

Pathing.PolyFlag_Infestation =  bit.lshift(Pathing.PolyFlag_NoBuild, 2)


// Global Pathing Options
local gPathingOptions = {}

function IntializeDefaultPathingOptions()
    gPathingOptions[Pathing.Option_CellSize]         = 0.26         // Grid cell size
    gPathingOptions[Pathing.Option_CellHeight]       = 0.40         // Grid cell height
    gPathingOptions[Pathing.Option_AgentHeight]      = 2.0          // Minimum height where the agent can still walk
    gPathingOptions[Pathing.Option_AgentRadius]      = 0.6          // Radius of the agent in cells
    gPathingOptions[Pathing.Option_AgentMaxClimb]    = 0.9          // Maximum height between grid cells the agent can climb
    gPathingOptions[Pathing.Option_AgentMaxSlope]    = 45.0         // Maximum walkable slope angle in degrees.
    gPathingOptions[Pathing.Option_RegionMinSize]    = 8            // Regions whose area is smaller than this threshold will be removed. 
    gPathingOptions[Pathing.Option_RegionMergeSize]  = 20           // Regions whose area is smaller than this threshold will be merged 
    gPathingOptions[Pathing.Option_EdgeMaxLen]       = 12.0         // Maximum contour edge length 
    gPathingOptions[Pathing.Option_EdgeMaxError]     = 1.3          // Maximum distance error from contour to cells 
    gPathingOptions[Pathing.Option_VertsPerPoly]     = 6.0          // Max number of vertices per polygon
    gPathingOptions[Pathing.Option_DetailSampleDist] = 6.0          // Detail mesh sample spacing.
    gPathingOptions[Pathing.Option_DetailSampleMaxError] = 1.0      // Detail mesh simplification max sample error.
    gPathingOptions[Pathing.Option_TileSize]         = 16           // Width and Height of a tile 
end

// Call this function as to make sure stuff gets intialized
IntializeDefaultPathingOptions()

function SetPathingOption(option, value)
    gPathingOptions[option] = value
end

function GetPathingOption(option)
    return gPathingOptions[option]
end

function GetPathingOptions()
    return gPathingOptions
end

// Function that does everything for the building of the mesh
function InitializePathing()
    Pathing.SetOptions(GetPathingOptions())
    Pathing.BuildMesh()
end

function ParsePathingSettings(settings)
  SetPathingOption(Pathing.Option_CellSize, settings.option_cell_size)
  SetPathingOption(Pathing.Option_CellHeight, settings.option_cell_height)
  SetPathingOption(Pathing.Option_AgentHeight, settings.option_agent_height)
  SetPathingOption(Pathing.Option_AgentRadius, settings.option_agent_radius)
  SetPathingOption(Pathing.Option_AgentMaxClimb, settings.option_agent_max_climb)
  SetPathingOption(Pathing.Option_AgentMaxSlope, settings.option_agent_max_slope)
  SetPathingOption(Pathing.Option_RegionMinSize, settings.option_region_min_size)
  SetPathingOption(Pathing.Option_RegionMergeSize, settings.option_region_merge_size)
  SetPathingOption(Pathing.Option_EdgeMaxLen, settings.option_edge_max_len)
  SetPathingOption(Pathing.Option_EdgeMaxError, settings.option_edge_max_error)
  SetPathingOption(Pathing.Option_VertsPerPoly, settings.option_verts_per_poly)
  SetPathingOption(Pathing.Option_DetailSampleDist, settings.option_detail_sample_dist)
  SetPathingOption(Pathing.Option_DetailSampleMaxError, settings.option_detail_sample_max_error)
  SetPathingOption(Pathing.Option_TileSize, settings.option_tile_size)  
end

/**
 * Adds additional points to the path to ensure that no two points are more than
 * maxDistance apart.
 */
function SplitPathPoints(points, maxDistance, maxPoints)
    PROFILE("SplitPathPoints") 
    local numPoints   = #points    
    local maxPoints   = maxPoints
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

function TraceEndPoint(src, dst, trace, skinWidth)

    local delta    = dst - src
    local distance = delta:GetLength()
    local fraction = trace.fraction
    fraction = Math.Clamp( fraction + (fraction - 1.0) * skinWidth / distance, 0.0, 1.0 )
    
    return src + delta * fraction

end

/**
 * Returns a list of point connecting two points together. If there's no path, returns nil.
 */
function GeneratePath(src, dst, doSplit, splitDist, maxSplitPoints)
    PROFILE("GeneratePath")  
    local mask = CreateGroupsFilterMask(PhysicsGroup.StructuresGroup, PhysicsGroup.PlayerControllersGroup, PhysicsGroup.PlayerGroup)    
    local climbAmount   = 0.3   // Distance to "climb" over obstacles each iteration
    local climbOffset   = Vector(0, climbAmount, 0)
    local maxIterations = 10    // Maximum number of attempts to trace to the dst
    
    local points = { }    
    
    // Query the pathing system for the path to the dst
    // if fails then fallback to the old system
    local isReachable = Pathing.GetPathPoints(src, dst, points)     
    
    if (#(points) ~= 0) then      
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