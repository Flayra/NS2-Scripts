// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
kAlienStructureEffects = 
{
    construct =
    {
        alienConstruct =
        {
            {sound = "sound/ns2.fev/alien/structures/generic_build", isalien = true, done = true},
        },
    },

    construction_complete = 
    {
        alienStructureComplete =
        {
            //"cinematics/alien/harvester/glow.cinematic"?
            {parented_sound = "sound/ns2.fev/alien/structures/harvester_active", classname = "Harvester"},
            // Don't play deploy for marine structures here, that happens as part of power changing
            {animation = "deploy", isalien = true},
            {sound = "sound/ns2.fev/alien/structures/hive_idle", classname = "Hive"},
        },
    },
    
    animation_complete =
    {
        animCompleteEffects =
        {
            {animation = {{.4, "active1"}/*, {.7, "active2"}*/}, classname = "Harvester", from_animation = "deploy", blend_time = .3, force = true},            
            {stop_sound = "sound/ns2.fev/alien/structures/harvester_active", classname = "Harvester", from_animation = "deploy"},
            {parented_sound = "sound/ns2.fev/alien/structures/harvester_active", classname = "Harvester", from_animation = "deploy"},
        },
    },
    
    death =
    {
        alienStructureDeathParticleEffect =
        {        
            // Plays the first effect that evalutes to true
            {cinematic = "cinematics/alien/structures/death_hive.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Whip", done = true},
            {cinematic = "cinematics/alien/structures/death_harvester.cinematic", classname = "Harvester", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", isalien = true, classname = "Structure", done = true},
        },
        
        alienStructureDeathSounds =
        {
            
            {sound = "sound/ns2.fev/alien/structures/harvester_death", classname = "Harvester"},
            {sound = "sound/ns2.fev/alien/structures/hive_death", classname = "Hive"},
            {sound = "sound/ns2.fev/alien/structures/death_grenade", classname = "Structure", doer = "Grenade", isalien = true, done = true},
            {sound = "sound/ns2.fev/alien/structures/death_axe", classname = "Structure", doer = "Axe", isalien = true, done = true},            
            {sound = "sound/ns2.fev/alien/structures/death_small", classname = "Structure", isalien = true, done = true},
        },
        
        alienStructureDeathStopSounds =
        {
            {stop_sound = "sound/ns2.fev/alien/structures/harvester_active", classname = "Harvester", done = true},
            {stop_sound = "sound/ns2.fev/alien/structures/hive_idle", classname = "Hive", done = true},
        },        
    },
    
    drifter_melee_attack =
    {
        drifterMeleeAttackEffects =
        {
            {animation = "attack", blend_time = .2},
            {sound = "sound/ns2.fev/alien/drifter/attack"},
        },
    },
    
    drifter_flare =
    {
        drifterFlareEffects = 
        {
            {sound = "sound/ns2.fev/alien/drifter/flare"},
            {animation = "flash", blend_time = .2},
        },
    },    

    drifter_parasite =
    {
        drifterParasiteEffects = 
        {
            {sound = "sound/ns2.fev/alien/drifter/parasite"},
            {animation = "parasite", blend_time = .2},
        },
    },    
    
    drifter_parasite_hit = 
    {
        parasiteHitEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/parasite_hit"},
            {player_cinematic = "cinematics/alien/skulk/parasite_hit.cinematic"},
        },
    },
    
    // "sound/ns2.fev/alien/drifter/drift"
    // "sound/ns2.fev/alien/drifter/ordered"
    harvester_collect =
    {
        harvesterCollectEffect =
        {
            {sound = "sound/ns2.fev/alien/structures/harvester_harvested"},
            //{cinematic = "cinematics/alien/harvester/resource_collect.cinematic"},
            {animation = {{.4, "active1"}, {.7, "active2"}}, force = false},
        },
    },
    
    egg_death =
    {
        eggSpawnPlayerEffects =
        {
            // Kill egg with a sound
            {sound = "sound/ns2.fev/alien/structures/egg/death"},
            
            // ...and a splash
            {cinematic = "cinematics/alien/egg/burst.cinematic"},            

            {stop_cinematic = "cinematics/alien/egg/mist.cinematic"},
            
            {animation = ""},

        },
    },

    hydra_attack =
    {
        hydraAttackEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/hydra/attack"},
            //{cinematic = "cinematics/alien/hydra/spike_fire.cinematic"},
            {animation = "attack", blend_time = .2},
        },
    },
    
    hydra_alert =
    {
        hydraAlertEffects =
        {
            {animation = "alert", blend_time = .2},
        },
    },
    
    player_start_gestate =
    {
        playerStartGestateEffects = 
        {
            {sound = "sound/ns2.fev/alien/common/gestate"},
        },
    },

    player_end_gestate =
    {
        playerStartGestateEffects = 
        {
            {sound = "sound/ns2.fev/alien/common/hatch"},
            {stop_sound = "sound/ns2.fev/alien/common/gestate"},
        },
    },
    
    hive_login =
    {
        hiveLoginEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/hive_load"},            
            {animation = "load"},
        },
    },

    hive_logout =
    {
        hiveLogoutEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/hive_exit"},
            {animation = "unload"},            
        },
    },
    
    hive_metabolize =
    {
        hiveMetabolizeEffects =
        {
            {sound = "sound/ns2.fev/alien/healing_mound_heal"},
            
            {cinematic = "cinematics/alien/metabolize_large.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/metabolize_large.cinematic", classname = "Onos", done = true},
            {cinematic = "cinematics/alien/metabolize_small.cinematic"},
        },
    },
    
    // Hive touched by enemy player
    hive_recoil =
    {
        hiveRecoilEffects =
        {
            {animation = "scared_active", occupied = true, blend_time = .3},
            {animation = "scared_inactive", occupied = false, blend_time = .3},
        },
    },
    
    // Triggers when crag tries to heal entities
    crag_heal =
    {        
        cragTriggerHealEffects = 
        {
            {cinematic = "cinematics/alien/crag/heal.cinematic"},
            {animation = "heal"},
        },
    },
    
    // Triggered for each entity healed by crag
    crag_target_healed =
    {        
        cragTargetHealedEffects =
        {
            {sound = "sound/ns2.fev/alien/common/regeneration"},
            
            {cinematic = "cinematics/alien/heal_big.cinematic", classname = "Onos", done = true},
            {cinematic = "cinematics/alien/heal_big.cinematic", classname = "Structure", done = true},
            {cinematic = "cinematics/alien/heal.cinematic", done = true},
        },
    },
    
    // Triggered by commander
    crag_trigger_umbra =
    {
        cragUmbraEffects =
        {
            // TODO: Play as private commander sound if played
            {sound = "sound/ns2.fev/alien/structures/crag/umbra"},
            {animation = "umbra"},
            {cinematic = "cinematics/alien/crag/umbra.cinematic"},
            // TODO: Add private commander sound
        },
    },    

    // Triggered by commander
    crag_trigger_babblers =
    {
        cragBabblerEffects =
        {
        },
    },    
    
    whip_attack =
    {
        whipAttackEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/whip/attack"},
            {animation = "attack", force = true},
        },
    },
    
    whip_trigger_fury =
    {
        whipTriggerFuryEffects = 
        {
            {sound = "sound/ns2.fev/alien/structures/whip/fury"},
            {cinematic = "cinematics/alien/whip/fury.cinematic"},
            {animation = "enervate", speed = 1},
        },
    },   
    
    //Whip.kMode = enum( {'Rooted', 'Unrooting', 'UnrootedStationary', 'Rooting', 'StartMoving', 'Moving', 'EndMoving'} )
    
    // Played when root finishes
    whip_rooted =
    {
        whipRootedEffects = 
        {
            // Placeholder
            {sound = "sound/ns2.fev/alien/structures/generic_build"},
        },
    },
    
    whip_unrooting =
    {
        whipUnrootEffects = 
        {
            // Length of animation determines game effect
            {animation = "unroot", speed = 1},
        },
    },
    
    // Played after unroot finishes
    whip_unrootedstationary =
    {
        whipUnrootedEffects = 
        {
            // Placeholder
            {sound = "sound/ns2.fev/alien/structures/generic_build"},
        },
    },

    whip_rooting =
    {
        whipRootEffects = 
        {
            // Length of animation determines game effect
            {animation = "root", speed = 1},
        },
    },

    whip_startmoving = 
    {
        whipStartMoveEffects = 
        {
            // Don't force playing so it doesn't restart if we just played it
            {animation = "walk_into", speed = 1},
        },
    },
    
    whip_moving = 
    {
        whipMoveEffects = 
        {
            // Don't play a sound as this is triggered every tick
            {animation = "walk", speed = 5},
        },
    },
    
    whip_endmoving = 
    {
        whipStopMoveEffects = 
        {
            {animation = "walk_out", speed = 1},
        },
    },
    
    // "cinematics/alien/shade/blind.cinematic"
    // "cinematics/alien/shade/glow.cinematic"
    // "cinematics/alien/shade/phantasm.cinematic"
    
    // On shade when it triggers cloak ability
    shade_cloak_start =
    {
        {sound = "sound/ns2.fev/alien/structures/shade/cloak_start"},
        {animation = "phantasm"},
    },

    create_pheromone =
    {
        createPheromoneEffects =
        {
            // Play different effects for friendlies vs. enemies
            {sound = "sound/ns2.fev/alien/structures/crag/umbra"/*, sameteam = true*/},            
            {cinematic = "cinematics/alien/crag/umbra.cinematic", /*sameteam = true,*/ done = true},
            
            //{sound = "sound/ns2.fev/alien/structures/crag/umbra", sameteam = false, volume = .3, done = true},            
        },
    },    
    
}

GetEffectManager():AddEffectData("AlienStructureEffects", kAlienStructureEffects)
