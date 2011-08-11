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