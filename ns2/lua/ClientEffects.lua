// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommonEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Use this file to set up looping effects that are always playing on specific units in the game.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kClientEffectData = 
{
    on_init =
    {
        initEffects =
        {
            {looping_cinematic = "cinematics/alien/gorge/spit.cinematic", classname = "Spit", done = true},
            
            // Play spin for spinning infantry portal
            {looping_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = true, done = true},
            
            // Destroy it if not spinning
            {stop_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = false, done = true},
            
            // Create dust trail (alt-mode true for alt-fire spore cloud, false for trail)
            {cinematic = "cinematics/alien/lerk/spore_trail.cinematic", classname = "SporeCloud", alt_mode = false, done = true},
            
            // Fire spore cloud
            {sound = "sound/ns2.fev/alien/lerk/spores_hit", classname = "SporeCloud", alt_mode = true},
            {cinematic = "cinematics/alien/lerk/spore_impact.cinematic", classname = "SporeCloud", alt_mode = true, done = true},
        },
    },  
    
    on_destroy =
    {
        destroyEffects = 
        {
            // Dust trail
            {stop_cinematic = "cinematics/alien/lerk/spore_trail.cinematic", classname = "SporeCloud", alt_mode = false, done = true},
            
            // Spore cloud
            {stop_cinematic = "cinematics/alien/lerk/spore_impact.cinematic", classname = "SporeCloud", alt_mode = true, done = true},

        },
    },

    // Called on client only, whenever the "active" state of a structure is changed (currently only the IP)
    client_active_changed =
    {
        activeChanged =
        {
            // Play spin for spinning infantry portal
            {looping_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = true, done = true},
            
            // Destroy it if not spinning
            {stop_cinematic = "cinematics/marine/infantryportal/spin.cinematic", classname = "InfantryPortal", active = false, done = true},
        },
    },
    
    client_cloak_changed =
    {
        cloakChanged =
        {   
            // cloak
            {sound = "sound/ns2.fev/alien/structures/shade/cloak_start", volume = .5, cloaked = true},            
            {looping_cinematic = "cinematics/alien/metabolize_large.cinematic", classname = "Hive", cloaked = true, enemy = false, done = true},
            {looping_cinematic = "cinematics/alien/metabolize_small.cinematic", cloaked = true, enemy = false, done = true},
                       
            // uncloak
            {sound = "sound/ns2.fev/alien/structures/shade/cloak_end", volume = .5, cloaked = false},
            {stop_cinematic = "cinematics/alien/metabolize_large.cinematic", classname = "Hive", enemy = false, done = true},
            {stop_cinematic = "cinematics/alien/metabolize_small.cinematic", cloaked = false, done = true},
        },
    },
    
    /*
    client_spore_trail_create =
    {
        sporeCloudEffects =
        {
            {cinematic = "cinematics/alien/lerk/spore_trail.cinematic"},
        }
    },
    
    client_spore_trail_destroy =
    {
        sporeCloudEffects =
        {
            {stop_cinematic = "cinematics/alien/lerk/spore_trail.cinematic"},
        }
    },*/

}

GetEffectManager():AddEffectData("ClientEffectData", kClientEffectData)