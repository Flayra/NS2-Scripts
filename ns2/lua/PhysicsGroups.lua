//=============================================================================
//
// RifleRange/PhysicsGroups.lua
// 
// Created by Max McGuire (max@unknownworlds.com)
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Returns a bit mask with the specified groups filtered out.
 */
function CreateGroupsFilterMask(...)
  
    local mask = 0xFFFFFFFF
    local args = {...}
    
    for i,v in ipairs(args) do
        mask = bit.band( mask, bit.bnot(bit.lshift(1,v)) )
    end
  
    return mask
    
end

/**
 * Returns a bit mask with everything but the specified groups filtered out.
 */
function CreateGroupsAllowedMask(...)

    local mask = 0x0
    local args = {...}
    
    for i,v in ipairs(args) do
        mask = bit.bor( mask, bit.lshift(1,v) )
    end
  
    return mask

end

// Different groups that physics objects can be assigned to.
// Physics models and controllers can only be in ONE group (SetGroup()).
PhysicsGroup = enum
    { 
        'DefaultGroup',             // Default Group Entities are created with
        'StructuresGroup',          // All of the commander built structures.
        'RagdollGroup',             // Ragdolls are in this group
        'PlayerControllersGroup',   // Bullets will not collide with this group.
        'PlayerGroup',              // Ignored for movement
        'WeaponGroup',
        'ProjectileGroup',
        'CommanderPropsGroup',
        'CommanderUnitGroup',       // Macs, Drifters, doors, etc.
        'AttachClassGroup',         // Nozzles, tech points, etc.
        'InfestationGroup',         // Infestation only
        'CollisionGeometryGroup',   // Used so players walk smoothly gratings and skulks wall-run on railings, etc.
        'DroppedWeaponGroup'
    }

// Pre-defined physics group masks.
PhysicsMask = enum
    {
        // Don't filter out anything
        FilterNone = 0,
        
        // Don't collide with anything
        FilterAll = 0xFFFFFFFF,
        
        // Filters anything that should not be collided with for player movement.
        Movement = CreateGroupsFilterMask(PhysicsGroup.RagdollGroup, PhysicsGroup.PlayerGroup, PhysicsGroup.ProjectileGroup, PhysicsGroup.WeaponGroup),
        
        // For Drifters, MACs
        AIMovement = CreateGroupsFilterMask(PhysicsGroup.RagdollGroup, PhysicsGroup.PlayerGroup, PhysicsGroup.AttachClassGroup, PhysicsGroup.WeaponGroup),
        
        // Use these with trace functions to determine which entities we collide with. Use the filter to then
        // ignore specific entities. 
        AllButPCs = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup),
        
        // For building
        AllButPCsAndInfestation = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.InfestationGroup),

        // Used for all types of prediction
        AllButPCsAndRagdolls = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup),
        
        // Shooting and hive sight
        Bullets = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup, PhysicsGroup.CollisionGeometryGroup, PhysicsGroup.WeaponGroup),

        // Melee attacks
        Melee = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup, PhysicsGroup.CollisionGeometryGroup, PhysicsGroup.WeaponGroup),

        // Allows us to mark props as non interfering for commander selection (culls out any props with commAlpha < 1)
        CommanderSelect = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup, PhysicsGroup.CommanderPropsGroup),

        // The same as commander select mask, minus player entities and structures
        CommanderBuild = CreateGroupsFilterMask(PhysicsGroup.PlayerControllersGroup, PhysicsGroup.RagdollGroup, PhysicsGroup.CommanderPropsGroup, PhysicsGroup.CommanderUnitGroup),
        
        // When Onos charges, players don't stop our movement
        Charge = CreateGroupsFilterMask(PhysicsGroup.RagdollGroup, PhysicsGroup.PlayerGroup, PhysicsGroup.PlayerControllersGroup),
        
        // Exclude everything except infestation
        OnlyInfestation = CreateGroupsAllowedMask(PhysicsGroup.InfestationGroup)
    }

PhysicsType = enum
    {
        'None',             // No physics representation.
        'Dynamic',          // Bones are driven by physics simulation (client-side only)
        'DynamicServer',    // Bones are driven by physics simulation (synced with server)
        'Kinematic'         // Physics model is updated by animation
    }