// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineStructureEffects = 
{
    // When players or MACs build a structure
    construct =
    {
        marineConstruct =
        {
            {cinematic = "cinematics/marine/mac/build.cinematic", isalien = false},
            {sound = "sound/ns2.fev/marine/structures/mac/build", isalien = false, done = true},
        },
    },
    
    // Play when marine welds another marine's armor
    marine_welded = 
    {
        marineWelded =
        {
            {cinematic = "cinematics/marine/mac/build.cinematic", isalien = false},
            {sound = "sound/ns2.fev/marine/structures/mac/build", isalien = false, done = true},
        },
    },

    construction_complete = 
    {
    },
    
    recycle_start =
    {
        recycleStartEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/recycle"},
        },        
    },

    recycle_end =
    {
        recycleEndEffects =
        {
            {cinematic = "cinematics/marine/structures/recycle.cinematic"},
        },        
    },
    
    animation_complete =
    {
        animCompleteEffects =
        {
            {animation = "open", classname = "CommandStation", from_animation = "deploy"},            
            {animation = "active", classname = "Extractor", from_animation = "deploy", blend_time = .3, force = true},            
            {animation = "active", classname = "Extractor", from_animation = "power_up", blend_time = .3, force = true},            
            {stop_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "deploy"},
            {stop_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "power_up"},
            {parented_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "deploy"},            
            {parented_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor", from_animation = "power_up"},     
            
            {animation = "spin", classname = "InfantryPortal", from_animation = "spin_start", done = true},
        },
    },
    
    death =
    {
        marineStructureDeathCinematics =
        {
            {cinematic = "cinematics/marine/sentry/death.cinematic", classname = "Sentry", done = true},
            {cinematic = "cinematics/marine/structures/death_small.cinematic", classname = "Observatory", done = true},
            {cinematic = "cinematics/marine/infantryportal/death.cinematic", classname = "InfantryPortal", done = true},
            {cinematic = "cinematics/marine/structures/death_large.cinematic", isalien = false, classname = "Structure", done = true},
        },
        
        marineStructureDeathSounds =
        {
            {sound = "sound/ns2.fev/marine/structures/command_station_death", classname = "CommandStation", done = true},
            {sound = "sound/ns2.fev/marine/structures/extractor_death", classname = "Extractor", done = true},
            {sound = "sound/ns2.fev/marine/power_node/destroyed", classname = "PowerPoint"},
            {sound = "sound/ns2.fev/marine/power_node/destroyed_powerdown", classname = "PowerPoint", done = true},
            {sound = "sound/ns2.fev/marine/structures/generic_death", classname = "Structure", isalien = false, done = true},
        },
    },
    
    power_down =
    {
        powerDownEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/power_down"},
            {stop_sound = "sound/ns2.fev/marine/structures/extractor_active", classname = "Extractor"},
            {stop_sound = "sound/ns2.fev/marine/structures/phase_gate_active", classname = "PhaseGate"},
            // Structure power down animations handled in code ("power_down")
        },
    },

    power_up =
    {
        powerUpEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/phase_gate_active", classname = "PhaseGate", done = true},
            {sound = "sound/ns2.fev/marine/structures/power_up"},
            // Structure power down animations handled in code ("power_down")
        },
    },
    
    fixed_power_up =
    {
        fixedPowerUpEffects =
        {
            {sound = "sound/ns2.fev/marine/power_node/fixed_powerup", classname = "PowerPoint", done = true},
        },
    },

    mac_construct =
    {
        macConstructEffects =
        {
            {animation = "construct", blend_time = .2},
            {sound = "sound/ns2.fev/marine/structures/mac/weld"},
            {parented_cinematic = "cinematics/marine/mac/build.cinematic", attach_point = "fxnode_welder"},
        },
    },
    
    // TODO: "sound/ns2.fev/marine/structures/mac/weld_start" voiceover
    // TODO: "sound/ns2.fev/marine/structures/mac/welded" voiceover (complete)
    mac_weld = 
    {
        macWeldEffects =
        {
            {animation = "construct_weld", blend_time = .2},
            {sound = "sound/ns2.fev/marine/structures/mac/weld"},
            {parented_cinematic = "cinematics/marine/mac/weld.cinematic", attach_point = "fxnode_welder"},
        },
    },
    
    // When players weld power points
    player_weld = 
    {
        macWeldEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/mac/weld"},
            {cinematic = "cinematics/marine/mac/weld.cinematic", attach_point = "fxnode_welder"},
        },
    },
    
    mac_move_complete =
    {
        macMoveCompleteEffects = 
        {
            {animation = "fly_stop", blend_time = .2},
            {stop_sound = "sound/ns2.fev/marine/structures/mac/thrusters"},
        },
    },
    
    mac_move =
    {
        macMoveEffects = 
        {
            {animation = "fly", blend_time = .2},
        },
    },
    
    mac_melee_attack =
    {
        macMeleeAttackEffects =
        {
            {animation = "attack", blend_time = .2},
            {sound = "sound/ns2.fev/marine/structures/mac/attack"},
        },
    },
    
    mac_set_order =
    {
        macSetOrderEffects =
        {
            {stop_sound = "sound/ns2.fev/marine/structures/mac/thrusters"},
            {parented_sound = "sound/ns2.fev/marine/structures/mac/thrusters"},
            
            // Use parented so it follows MAC around
            {parented_cinematic = "cinematics/marine/mac/jet.cinematic", attach_point = "fxnode_jet1"},
            {parented_cinematic = "cinematics/marine/mac/jet.cinematic", attach_point = "fxnode_jet2"},
            
            // TODO: this should be attached to the siren
            {parented_cinematic = "cinematics/marine/mac/siren.cinematic", attach_point = "fxnode_light"},
        },
    },
    
    // ARC effects
    
    // Called when ARC is created out of robotics factory
    arc_built =
    {
        arcDeployEffects =
        {
            {animation = "spawn"},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic"},
        },
    },            
    
    // Switching into siege mode
    arc_deploying =
    {
        arcDeployEffects =
        {
            {sound = "sound/ns2.fev/marine/structures/arc/deploy"},
            {animation = "deploy"},
        },
    },    
    
    // Switching back to movement mode
    arc_undeploying =
    {
        arcUndeployEffects =
        {
            {stop_sound = "sound/ns2.fev/marine/structures/arc/fire"},
            {sound = "sound/ns2.fev/marine/structures/arc/undeploy"},
            {animation = "undeploy"},
        },
    },  
    
    // Repeatedly triggered while moving
    arc_moving =
    {
        arcMoveEffects =
        {
            {animation = "move"},
        },
    },
    
    arc_targeting =
    {
        arcTargetEffects = 
        {
            {animation = "target", force = true},
            {parented_sound = "sound/ns2.fev/marine/structures/arc/fire"},
            {parented_cinematic = "cinematics/marine/arc/target.cinematic", attach_point = "fxnode_arcmuzzle"},
        },
    },
    
    arc_firing =
    {
        arcFireEffects =
        {
            // "trail" like a tracer
            {animation = "fire", force = true},
            //{sound = "sound/ns2.fev/marine/structures/arc/fire"},
            {parented_cinematic = "cinematics/marine/arc/fire.cinematic", attach_point = "fxnode_arcmuzzle"},
        },
    },
    

    
    // Center of ARC blast
    arc_hit_primary =
    {
        arcHitPrimaryEffects = 
        {
            {sound = "sound/ns2.fev/marine/structures/arc/hit"},
            {cinematic = "cinematics/marine/arc/explosion.cinematic"},
        },
    },
    
    // Played for secondary targets within blast radius
    arc_hit_secondary =
    {
        arcHitSecondaryEffects = 
        {
           {cinematic = "cinematics/marine/arc/hit_small.cinematic", classname = "Egg", done = true},
            {cinematic = "cinematics/marine/arc/hit_small.cinematic", classname = "Hydra", done = true},
            {cinematic = "cinematics/marine/arc/hit_big.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/marine/arc/hit_med.cinematic"},      
        },
    },
    
    
    arc_stop_effects =
    {
        arcHitStopEffects = 
        {
            {stop_effects = ""},
        },
    },
    
    // ARC TODO:
    //ARC.kFlybySound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/flyby")
    //ARC.kScanSound = PrecacheAsset("sound/ns2.fev/marine/structures/arc/scan")
    //ARC.kScanEffect = PrecacheAsset("cinematics/marine/arc/scan.cinematic")
    //ARC.kFireEffect = PrecacheAsset("cinematics/marine/arc/fire.cinematic")
    //ARC.kFireShellEffect = PrecacheAsset("cinematics/marine/arc/fire_shell.cinematic")
    //ARC.kDamagedEffect = PrecacheAsset("cinematics/marine/arc/damaged.cinematic")
    
    extractor_collect =
    {
        extractorCollectEffect =
        {
            {sound = "sound/ns2.fev/marine/structures/extractor_harvested"},
            //{cinematic = "cinematics/marine/extractor/collection_effect.cinematic"},
        },
    },
    
    armory_health = 
    {
        armoryHealth =
        {
            {sound = "sound/ns2.fev/marine/common/health"},
            {cinematic = "cinematics/marine/spawn_item.cinematic"},
        },
    },

    armory_ammo = 
    {
        armoryAmmo =
        {
            {sound = "sound/ns2.fev/marine/common/pickup_ammo"},
            {cinematic = "cinematics/marine/spawn_item.cinematic"},
        },
    },
    
    // Not hooked up
    armory_buy = 
    {
        armoryBuy =
        {
            {cinematic = "cinematics/marine/armory/buy_item_effect.cinematic"},
        },
    },
    
    armory_open = 
    {
        armoryOpen =
        {
            {sound = "sound/ns2.fev/marine/structures/armory_open"},
        },
    },
    
    armory_close = 
    {
        armoryClose =
        {
            {sound = "sound/ns2.fev/marine/structures/armory_close"},
        },
    },

    commmand_station_login = 
    {
        commandStationLogin =
        {
            {sound = "sound/ns2.fev/marine/structures/command_station_close"},
            {animation = "close"},
        },
    },

    commmand_station_logout = 
    {
        commandStationLogout =
        {
            {sound = "sound/ns2.fev/marine/structures/command_station_open"},
            {animation = "open"},
        },
    },
    
    commmand_station_closed = 
    {
    },
    
    commmand_station_opened = 
    {
    },
    
    infantry_portal_start_spin = 
    {
        ipStartSpinEffect =
        {
            {animation = "spin_start"},
            {sound = "sound/ns2.fev/marine/structures/infantry_portal_start_spin"},
        },
    },    

    infantry_portal_stop_spin = 
    {
        ipStartSpinEffect =
        {
            {animation = "spin_stop", from_animation = "spin", done = true},
            {animation = "spin_stop", from_animation = "spin_start", done = true},
        },
    },    
    
    infantry_portal_spawn = 
    {
        ipSpawnEffect =
        {
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},
            {sound = "sound/ns2.fev/marine/structures/infantry_portal_player_spawn"},
        },
    },    

    // Played when a player enters a phase gate (at the source)
    phase_gate_player_enter = 
    {
        pgSpawnEffect =
        {
            {sound = "sound/ns2.fev/marine/structures/phase_gate_teleport"},
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},            
        },
    }, 

    // Played when a player goes through a phase gate (at the destination)
    phase_gate_player_exit = 
    {
        pgSpawnEffect =
        {
            {sound = "sound/ns2.fev/marine/structures/phase_gate_teleport"},
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},            
        },
    },
    
    // Looping cinematic played when going through phase gate will teleport you somewhere
    phase_gate_linked =
    {
        pgLinkedEffects = 
        {
            // Play spin for spinning infantry portal
            {looping_cinematic = "cinematics/marine/phasegate/phasegate.cinematic"},
            {sound = "sound/ns2.fev/marine/structures/phase_gate_active"},
        },
    },
    
    phase_gate_unlinked =
    {
        pgLinkedEffects = 
        {
            // Destroy it if not spinning
            {stop_cinematic = "cinematics/marine/phasegate/phasegate.cinematic", done = true},
            {stop_sound = "sound/ns2.fev/marine/structures/phase_gate_active"},
        },
    },
    
    robo_factory_open = 
    {
        roboOpenEffect =
        {
            {animation = "open", done = true},            
        },
    },
    
    robo_factory_close = 
    {
        roboCloseEffect =
        {
            {animation = "close", done = true},            
        },
    },
    
    robo_factory_building = 
    {
        roboBuildingEffect =
        {
            {animation = "active", done = true},
            {cinematic = "cinematics/marine/roboticsfactory/collection_effect.cinematic"},          
        },
    },

    distress_beacon_start = 
    {
        distressBeaconEffect =
        {
            {looping_cinematic = "cinematics/marine/observatory/glowing_light_effect.cinematic"},
            {sound = "sound/ns2.fev/marine/common/distress_beacon", done = true},
        },
    },    
    
    distress_beacon_spawn = 
    {
        playerSpawnEffect =
        {
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},
        },
    },    
    
    distress_beacon_end = 
    {
        distressBeaconEffect =
        {
            {stop_sound = "sound/ns2.fev/marine/common/distress_beacon"},
            {stop_cinematic = "cinematics/marine/observatory/glowing_light_effect.cinematic"},
        },
    },
    
    distress_beacon_complete =
    {
        // Play one mega-spawn sound instead of spawn sounds for each player
        distressBeaconComplete =
        {
            {sound = "sound/ns2.fev/marine/common/mega_teleport"},
        },
    },    
    
}

GetEffectManager():AddEffectData("MarineStructureEffects", kMarineStructureEffects)
