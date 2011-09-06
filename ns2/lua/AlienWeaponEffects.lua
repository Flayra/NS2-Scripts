// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Debug with: {player_cinematic = "cinematics/locateorigin.cinematic"},

kAlienWeaponEffects =
{
    hit_effect =
    {
        // For hit effects, classname is the target
        generalHitEffects =
        {
            //{viewmodel_cinematic = "cinematics/locateorigin.cinematic", classname = "Marine", doer = "BiteLeap", attach_point = "Root", done = true},
            {player_cinematic = "cinematics/materials/%s/bash.cinematic", doer = "BiteLeap", done = true}, 
            {player_cinematic = "cinematics/alien/skulk/parasite_hit.cinematic", doer = "Parasite", done = true},
            {player_cinematic = "cinematics/alien/gorge/spit_impact.cinematic", doer = "Spit", done = true},        
            
            // Brian TODO: Change to something cooler
            {player_cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic", doer = "Bomb", done = true},        
            
            {cinematic = "cinematics/alien/lerk/spike_impact.cinematic", doer = "Spikes", done = true},            
            //{player_cinematic = "cinematics/alien/hydra/spike_impact.cinematic", doer = "HydraSpike", done = true},
            
            {player_cinematic = "cinematics/materials/%s/scrape.cinematic", doer = "SwipeBlink", done = true},
            {player_cinematic = "cinematics/materials/%s/scrape.cinematic", doer = "StabBlink", done = true},

        },
        generalHitSounds = 
        {
            //{sound = "sound/ns2.fev/alien/common/spike_hit_marine", world_space = true, doer = "HydraSpike", classname = "Marine", done = true},
            //{sound = "sound/ns2.fev/alien/common/spike_hit_marine", world_space = true, doer = "Spike", classname = "Marine", done = true},
            {sound = "sound/ns2.fev/alien/skulk/bite_hit_marine", doer = "BiteLeap", world_space = true, classname = "Marine", done = true},
            {sound = "sound/ns2.fev/alien/skulk/bite_hit_%s", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/ns2.fev/alien/skulk/parasite_hit", doer = "Parasite", done = true},
            {sound = "sound/ns2.fev/alien/gorge/spit_hit", doer = "Spit", done = true},
            {sound = "sound/ns2.fev/alien/gorge/bilebomb_hit", doer = "Bomb", done = true},
            //{sound = "sound/ns2.fev/materials/%s/spike_ricochet", doer = "Spike", done = true},
            //{sound = "sound/ns2.fev/materials/%s/spike_ricochet", doer = "Spikes", done = true},
            //{sound = "sound/ns2.fev/materials/%s/spikes_ricochet", doer = "HydraSpike", done = true},
            {sound = "sound/ns2.fev/materials/%s/scrape", doer = "SwipeBlink", done = true},
            {sound = "sound/ns2.fev/materials/%s/scrape", doer = "StabBlink", done = true},
        }
    },

    // Play ricochet sound for player locally for feedback (triggered if target > 5 meters away, play additional 30% volume sound)
    hit_effect_local =
    {
        hitEffectLocalEffects =
        {
            {private_sound = "sound/ns2.fev/alien/gorge/spit_hit", doer = "Spit", volume = .3, done = true},
            {private_sound = "sound/ns2.fev/alien/gorge/bilebomb_hit", doer = "Bomb", volume = .3, done = true},
            {private_sound = "sound/ns2.fev/alien/common/spikes_ricochet", doer = "Spike", volume = .3, done = true},
        },
    },
    
    idle = 
    {
        // Use weapon names for view model 
        alienViewModelIdleAnims = 
        {
            // Skulk
            // "fxnode_bitesaliva"
            {viewmodel_animation = {{1, "bite_idle"}, {.5, "bite_idle3"}}, classname = "BiteLeap", done = true},
            {viewmodel_animation = {{1, "bite_idle4"}/*, {.1, "bite_idle2"}, {.5, "bite_idle3"}, {.4, "bite_idle4"}*/}, classname = "Parasite", done = true},
            
            // Gorge
            {viewmodel_animation = { {1, "idle"}, {.3, "idle2"}, {.05, "idle3"} }, classname = "SpitSpray", done = true},            
            {viewmodel_animation = { {1, "idle"}/*, {.3, "idle2"}, {.05, "idle3"}*/ }, classname = "HydraAbility", done = true},
            
            // Lerk
            {viewmodel_animation = {{1, "idle"}, {.1, "idle2"}, {.5, "idle3"} }, classname = "Spikes", done = true},
            {viewmodel_animation = {{1, "idle"}, {.1, "idle2"}, {.5, "idle3"} }, classname = "Spores", done = true},
            
            // Fade
            {viewmodel_animation = {{1, "swipe_idle"}, {.1, "swipe_idle2"}}, classname = "SwipeBlink", done = true},
            {viewmodel_animation = {{1, "stab_idle"}, {.1, "stab_idle2"}}, classname = "StabBlink", done = true},
            
            // Onos
            {viewmodel_animation = {{1, "gore_idle"}/*, {.1, "gore_idle2"}, {.5, "gore_idle3"}*/}, classname = "Gore", done = true},
            
        },
        
        alienViewModelIdleCinematics =
        {
            //{viewmodel_cinematic = "cinematics/alien/lerk/spore_view_idle.cinematic", classname = "Spores", attach_point = "fxnode_hole_left"},
            //{viewmodel_cinematic = "cinematics/alien/lerk/spore_view_idle.cinematic", classname = "Spores", attach_point = "fxnode_hole_right"},
        },

    },
    
    draw = 
    {
        // Different draw animations for 
        alienDrawAnims = {
        
            {viewmodel_animation = "swipe_from_stab", classname = "SwipeBlink", speed = 2, from = "StabBlink", done = true},
            {viewmodel_animation = "stab_from_swipe", classname = "StabBlink", speed = 2, from = "SwipeBlink", done = true},
            
            {viewmodel_animation = "spore_draw", classname = "Spores", speed = 1, from = "Spikes", done = true},
            {viewmodel_animation = "spike_draw", classname = "Spikes", speed = 1, from = "Spores", done = true},
            
            // Aliens have no draw animations by default - will try to cover this with a "sploosh" from the egg.
            {viewmodel_animation = "", classname = "Ability"},
        },
    },
    
    bite_attack =
    {
        biteAttackSounds =
        {
            {sound = "sound/ns2.fev/alien/skulk/bite_structure", attach_point = "Bip01_Head", surface = "structure", done = true},
            {sound = "sound/ns2.fev/alien/skulk/bite", attach_point = "Bip01_Head"},
        },
        
        biteAttackAnims = 
        {
            {
            viewmodel_animation = 
              {
              {1, "bite_attack"},
              //{.5, "bite_attack2"},
              //{.5, "bite_attack3"},
              //{.5, "bite_attack4"},
              },
              force = true
            },
            {overlay_animation = "bite", force = true},
        },
    },
    
    // Leap
    bite_alt_attack =
    {
        biteAltAttackEffects = 
        {
            // TODO: Take volume or hasLeap
            {sound = "sound/ns2.fev/alien/skulk/bite_alt"},
            {viewmodel_animation = "bite_leap", force = true},
            {animation = "leap"},
        },
    },   

    parasite_attack =
    {
        parasiteAttackEffects = 
        {
            {viewmodel_animation = "parasite_attack", force = true},
            {sound = "sound/ns2.fev/alien/skulk/parasite"},
            {player_cinematic = "cinematics/alien/skulk/parasite_fire.cinematic"},
            {viewmodel_cinematic = "cinematics/alien/skulk/parasite_view.cinematic", attach_point = "Tongue_01", done = true},
         },
    },   
    
    // When a target is parasited - played on target
    parasite_hit = 
    {
        parasiteHitEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/parasite_hit", world_space = true},
            {player_cinematic = "cinematics/alien/skulk/parasite_hit.cinematic"},
        },
    },
    
    spitspray_attack =
    {
        spitFireEffects = 
        {
            {sound = "sound/ns2.fev/alien/gorge/spit"},
            {viewmodel_animation = "spit_attack", blend_time = .2, force = true},
            //{cinematic = "cinematics/alien/gorge/spit_fire.cinematic"},
            {overlay_animation = "spit", force = true},
        },
    },

    // When healed by Gorge    
    sprayed =
    {
        sprayedEffects =
        {   
            {player_cinematic = "cinematics/alien/heal.cinematic"},
            {sound = "sound/ns2.fev/alien/common/regeneration", world_space = true},
        },
    },

    spitspray_alt_attack = 
    {
        sprayFireEffects = 
        {
            // Use player_cinematic because at world position, not attach_point
            {player_cinematic = "cinematics/alien/gorge/healthspray.cinematic"},
            {viewmodel_cinematic = "cinematics/alien/gorge/healthspray_view.cinematic", attach_point = "gorge_view_root"},
            {sound = "sound/ns2.fev/alien/gorge/heal_spray"},            
            {viewmodel_animation = "spray_attack", force = true},         
            {overlay_animation = "healthspray", force = true},        
        },
    },
    
    bilebomb_attack =
    {
        bilebombFireEffects = 
        {
            {sound = "sound/ns2.fev/alien/gorge/bilebomb"},
            {viewmodel_animation = "spit_attack", blend_time = .2, force = true},
            //{cinematic = "cinematics/alien/gorge/spit_fire.cinematic"},
            {overlay_animation = "spit", force = true},
        },
    },

    bilebomb_hit =
    {
        bilebombHitEffects = 
        {
            {sound = "sound/ns2.fev/alien/gorge/bilebomb_hit"},
            // TODO: Change to something else
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic", done = true},
        },
    },
    
    // When creating a structure
    gorge_create =
    {
        gorgeCreateEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/spawn_small"},
        },
    },
    
    // Called for player immediately when creating infestation as gorge
    start_create_infestation =
    {
        gorgeCreateInfestationEffects =
        {
            {player_cinematic = "cinematics/alien/gorge/infestationspray.cinematic"},
            //{viewmodel_cinematic = "cinematics/alien/gorge/healthspray_view.cinematic"},
            {viewmodel_animation = "spray_attack"},         
            {overlay_animation = "healthspray"}        
        },
    },
    
    // Called for player after short delay when creating infestation as gorge
    create_infestation =
    {
        gorgeCreateInfestationEffects =
        {
            {sound = "sound/ns2.fev/alien/structures/spawn_small"},
        },
    },
    
    // For Commander
    create_infestation_local = 
    {
        createInfestationLocalEffects =
        {
            {sound = "sound/ns2.fev/alien/commander/DI_drop_2D"},
        },
    },
    
    // Gorge starts creating hydra. A short time later, it will actually spawn and trigger "create_hydra" below.
    start_create_hydra =
    {
        startHydraCreate = 
        {
            {sound = "sound/ns2.fev/alien/gorge/create_structure_start"},
            {viewmodel_animation = "chamber_attack"},
            {player_cinematic = "cinematics/alien/gorge/create.cinematic", attach_point = "Head"},
            {viewmodel_cinematic = "cinematics/alien/gorge/create_view.cinematic", attach_point = ""},
        },
    },
    
    // Gorge creating hydra
    create_hydra =
    {
        hydraEffects =
        {   
        },
    },
    
    start_create_cyst =
    {
        startCystCreate = 
        {
            {sound = "sound/ns2.fev/alien/gorge/create_structure_start"},
            {viewmodel_animation = "chamber_attack"},
            {player_cinematic = "cinematics/alien/gorge/create.cinematic", attach_point = "Head"},
            {viewmodel_cinematic = "cinematics/alien/gorge/create_view.cinematic", attach_point = ""},
        },
    },
    
    create_cyst =
    {
        cystEffects =
        {   
        },
    },

    spikes_attack =
    {
        spikeAttackAnims = 
        {
            //{overlay_animation = "snipe"}, 
            //{viewmodel_animation = "spikes_snipe", done = true},
            {overlay_animation = "spike"},     
            {viewmodel_animation = "spikes_attack_l", left = true, done = true},
            {viewmodel_animation = "spikes_attack_r", left = false, done = true},
        },
        
        spikeAttackSounds = 
        {
            // Choose spike sound depending if we're zoomed and if we have piercing upgrade
            {sound = "sound/ns2.fev/alien/lerk/spikes", upgraded = false, done = true},
            {sound = "sound/ns2.fev/alien/lerk/spikes_pierce", upgraded = true, done = true},
        },
        
    },
    
    spikes_alt_attack =
    {
        spikeSpray = 
        {
            {overlay_animation = "spike"},     
            {viewmodel_animation = "spikes_snipe"},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoom"},            
            /*{sound = "sound/ns2.fev/alien/lerk/spikes_zoomed_pierce", upgraded = true, done = true},*/
        },
    },
    
    // Play snipe sound where it hits so players know what's going on (played at spot in world where spike hits - not for a target)
    spikes_snipe_miss =
    {
        spikesSnipeEffects =
        {
            {player_cinematic = "cinematics/alien/lerk/snipe_impact.cinematic"},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed", upgraded = false, done = true},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed_pierce", upgraded = true, done = true},           
        },
    },
    
    // Played for unit that is hit with sniped lerk
    spikes_snipe_hit =
    {
        spikesSnipedEffects =
        {
            {player_cinematic = "cinematics/alien/lerk/snipe_impact.cinematic"},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed", upgraded = false, done = true},
            {sound = "sound/ns2.fev/alien/lerk/spikes_zoomed_pierce", upgraded = true, done = true},           
        },
    },

    spores_attack =
    {
        sporesAttackEffects = 
        {
            {overlay_animation = "spore"},
            {viewmodel_animation = "spores_attack"},
            {sound = "sound/ns2.fev/alien/lerk/spore_spray"},
            {viewmodel_cinematic = "cinematics/alien/lerk/spore_view_fire.cinematic", attach_point = "fxnode_hole_left"},
            {viewmodel_cinematic = "cinematics/alien/lerk/spore_view_fire.cinematic", attach_point = "fxnode_hole_right"},
        },
    },
    
    spores_attack_end =
    {
        sporesAttackEndEffects = 
        {
            {stop_sound = "sound/ns2.fev/alien/lerk/spore_spray"},
        },
    },
    
    spores_alt_attack =
    {
        sporesAttackEffects = 
        {
            {sound = "sound/ns2.fev/alien/lerk/spores_shoot"},
            {viewmodel_animation = "spores_attack"},
            {overlay_animation = "spore"},
            
            //{viewmodel_cinematic = "cinematics/alien/lerk/spore_view_fire.cinematic", attach_point = "?"},
            //{weapon_cinematic = "cinematics/alien/lerk/spores.cinematic", attach_point = "?"},
        },
    },
    
    swipe_attack = 
    {
        swipeAttackSounds =
        {
            {sound = "sound/ns2.fev/alien/fade/swipe_structure", surface = "structure", done = true},
            {sound = "sound/ns2.fev/alien/fade/swipe"},
        },
        
        swipeAttackAnims =
        {
            {viewmodel_animation = {{1, "swipe_attack"}, {1, "swipe_attack2"}, {1, "swipe_attack3"}, {1, "swipe_attack4"}, {1, "swipe_attack5"}, {1, "swipe_attack6"}}, force = true},            
            {overlay_animation = { {1, "swipe"}, {1, "swipe2"}, {1, "swipe3"}, {1, "swipe4"}, {1, "swipe5"}, {1, "swipe6"} }, force = true},
        },
    },

    stab_attack = 
    {
        stabAttackEffects =
        {
            {viewmodel_animation = {{1, "stab_attack1"}}},
            {sound = "sound/ns2.fev/alien/fade/stab"},
            // TODO: SetAnimAndMode()
            {overlay_animation = { {1, "stab"}, {1, "stab2"}}},
        },
    },

    blink_out =
    {
        blinkOutEffects =
        {        
            {cinematic = "cinematics/alien/fade/blink_out.cinematic"},
            
            // Play sound with randomized positional offset (in sound) at place we're leaving
            {sound = "sound/ns2.fev/alien/fade/blink"},
        },
    },
    
    blink_out_local =
    {
        blinkOutEffects =
        {        
            {viewmodel_cinematic = "cinematics/alien/fade/blink_view.cinematic", attach_point = ""},
            {viewmodel_animation = "swipe_blink", classname = "SwipeBlink"},
            {viewmodel_animation = "stab_blink", classname = "StabBlink"},
            
            {looping_sound = "sound/ns2.fev/alien/fade/blink_loop"},
        },
    },

    blink_in =
    {
        blinkInEffects =
        {
            {cinematic = "cinematics/alien/fade/blink_in.cinematic"},
            
            // Play sound with randomized positional offset (in sound) at place we're leaving
            {sound = "sound/ns2.fev/alien/fade/blink_end"},            
            {stop_sound = "sound/ns2.fev/alien/fade/blink_loop"},            
        },
    },    
    
    // double-tap to quickly jump in a direction. Played at position before blink.
    quick_blink =
    {
        blinkOutEffects = {
        
            // Animated ghost that plays blinkin or blinkout is handled as a special case
            //{cinematic = "cinematics/alien/fade/blink_out.cinematic"},
            //{viewmodel_cinematic = "cinematics/alien/fade/blink_view.cinematic", attach_point = ""},
            
            // Play sound with randomized positional offset (in sound) at place we're leaving
            //{sound = "sound/ns2.fev/alien/fade/blink"},
            {sound = "sound/ns2.fev/alien/common/vision_on"}
        },

    },
    
    blink_ghost =
    {
        blinkGhostEffects = {        
            {sound = "sound/ns2.fev/alien/common/select"},            
        },

    }, 
    
    // Alien vision mode effects
    alien_vision_on = 
    {
        visionModeOnEffects = 
        {
            {sound = "sound/ns2.fev/alien/common/vision_on"},
        },
    },
    
    alien_vision_off = 
    {
        visionModeOnEffects = 
        {
            {sound = "sound/ns2.fev/alien/common/vision_off"},
        },
    },
    
    swarm =
    {
        swarmEffects =
        {
            {sound = "sound/ns2.fev/alien/common/swarm", world_space = true},
        },
    },
    
    frenzy =
    {
        frenzyEffects =
        {
            {sound = "sound/ns2.fev/alien/common/frenzy", world_space = true},
        },
    },
}

// "false" means play all effects in each block
GetEffectManager():AddEffectData("AlienWeaponEffects", kAlienWeaponEffects)

