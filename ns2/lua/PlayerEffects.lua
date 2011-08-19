// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PlayerEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kPlayerEffectData = 
{
    jump =
    {
        jumpSoundEffects =
        {        
            // Use private_sounds (ie, don't send network message) because this is generated on the client 
            // when animation plays and conserves bandwidth
            {sound = "sound/ns2.fev/alien/skulk/jump", classname = "Skulk", done = true},
            {sound = "sound/ns2.fev/alien/gorge/jump", classname = "Gorge", done = true},
            //{private_sound = "sound/ns2.fev/alien/lerk/jump", classname = "Lerk", done = true},
            {sound = "sound/ns2.fev/alien/fade/jump", classname = "Fade", done = true},
            //{private_sound = "sound/ns2.fev/alien/onos/jump", classname = "Onos", done = true},
            {sound = "sound/ns2.fev/marine/common/jump", classname = "Marine", done = true},                        
        },
    },
    
    footstep =
    {
        footstepSoundEffects =
        {
            // Use private_sounds (ie, don't send network message) because this is generated on the client 
            // when animation plays and conserves bandwidth
            // TODO: Add looping metal layer ("sound/ns2.fev/materials/metal/skulk_layer")        
           //skulk
            {sound = "sound/ns2.fev/materials/metal/skulk_step_left", left = true, classname = "Skulk", surface = "metal", done = true},                        
            {sound = "sound/ns2.fev/materials/metal/skulk_step_right", left = false, classname = "Skulk", surface = "metal", done = true},                        
            {sound = "sound/ns2.fev/alien/skulk/footstep_left", left = true, classname = "Skulk", done = true},                        
            {sound = "sound/ns2.fev/alien/skulk/footstep_right", left = false, classname = "Skulk", done = true}, 
           //gorge
            {sound = "sound/ns2.fev/alien/gorge/footstep_left", left = true, classname = "Gorge", done = true},                        
            {sound = "sound/ns2.fev/alien/gorge/footstep_right", left = false, classname = "Gorge", done = true},                        
           //lerk
            {sound = "sound/ns2.fev/alien/lerk/footstep_left", left = true, classname = "Lerk", done = true},                        
            {sound = "sound/ns2.fev/alien/lerk/footstep_right", left = false, classname = "Lerk", done = true},        
           //onos
            {sound = "sound/ns2.fev/materials/%s/onos_step", classname = "Onos", done = true},
           //fade
            {sound = "", classname = "Fade", done = true},       
           //marine
            {sound = "sound/ns2.fev/materials/%s/footstep_left", left = true, done = true},                        
            {sound = "sound/ns2.fev/materials/%s/footstep_right", left = false, done = true},                        
        },
    },
    
    fall = 
    {
        fallSoundEffects = 
        {
            {sound = "sound/ns2.fev/alien/skulk/land", classname = "Skulk", done = true},
            {sound = "sound/ns2.fev/alien/lerk/land", classname = "Lerk", done = true},
            {sound = "sound/ns2.fev/alien/gorge/land", classname = "Gorge", done = true},
            {sound = "sound/ns2.fev/alien/fade/land", classname = "Fade", done = true},
            {sound = "sound/ns2.fev/alien/onos/land", classname = "Onos", done = true},
            {sound = "sound/ns2.fev/materials/%s/fall"},
        },
    },
    
    // Triggered Clientside when the player is notified they caused damage to something.
    give_damage =
    {
        giveDamageEffects =
        {
            {private_sound = "sound/ns2.fev/marine/common/hit", classname = "Marine", done = true}
        }
    },
    
    // Played for on alien when frenzy kicks in
    frenzy =
    {
        frenzyEffects =
        {
            {sound = "sound/ns2.fev/alien/skulk/land"},
        }
    },
    
    // Played on player
    distress_beacon_player_start =
    {
        distressBeaconPlayerStart =
        {
            // Play different sound effect for each player so aliens only hear it nearby, but marines
            // hear it directionally from far away
            {private_sound = "sound/ns2.fev/marine/common/distress_beacon_marine", ismarine = true, done = true},            
        },
    },

    // Triggered for local player
    disorient_loop =
    {
        disorientFX =
        {
            {looping_sound = "sound/ns2.fev/alien/structures/shade/disorientate", active = true, done = true},
            {stop_sound = "sound/ns2.fev/alien/structures/shade/disorientate", active = false, done = true},
        },
    },
    
    cloak_loop =
    {
        cloakFX =
        {
            {looping_sound = "sound/ns2.fev/alien/structures/shade/cloak_loop", active = true, done = true},
            {stop_sound = "sound/ns2.fev/alien/structures/shade/cloak_loop", active = false, done = true},
        },
    },        
}

GetEffectManager():AddEffectData("PlayerEffectData", kPlayerEffectData)
