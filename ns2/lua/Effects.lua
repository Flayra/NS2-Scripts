// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Effects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Sound, effect and animation data to be used by the effect manager.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/EffectManager.lua")

// TODO: Add stop sound, cinematics
// TODO: Add camara shake?

//
// All effect entries should be one of these basic types:
//
kCinematicType                      = "cinematic"               // Server-side world cinematic at kEffectHostCoords
kWeaponCinematicType                = "weapon_cinematic"        // Needs attach_point specified
kViewModelCinematicType             = "viewmodel_cinematic"     // Needs attach_point specified. 
kPlayerCinematicType                = "player_cinematic"        // Shared world cinematic (like weapon_cinematic or view_model cinematic but played at world pos kEffectHostCoords)
kParentedCinematicType              = "parented_cinematic"      // Parented to entity generating event (optional attach_point)
kLoopingCinematicType               = "looping_cinematic"       // Looping client-side cinematic
kStopCinematicType                  = "stop_cinematic"          // Stops a world cinematic

kAnimationType                      = "animation"               // Optional blend time, animation speed
kViewModelAnimationType             = "viewmodel_animation"     // Optional blend time, animation speed, Plays on parent's view model if supported. TODO: add "blocking" for reload?. 
kOverlayAnimationType               = "overlay_animation"       // Optional blend time, animation speed not supported. Plays on parent if supported by default (useful for weapons).

kSoundType                          = "sound"                   // Server-side world sound
kParentedSoundType                  = "parented_sound"          // For looping entity sounds, you'll want to use parented_sound so they are stopped when entity goes away
kLoopingSoundType                   = "looping_sound"           // TODO: Change name to one_sound? This currently plays relative to player.
kPrivateSoundType                   = "private_sound"           // TODO: Change name to one_sound? This currently plays relative to player.
kStopSoundType                      = "stop_sound"              

kStopEffectsType                    = "stop_effects"            // Stops all looping or parented sounds and particles for this object (pass "")

kDecalType                          = "decal"                   // Creates a decal at position of effect (only works when triggered from client events)

kRagdollType                        = "ragdoll"                 // Turns the model into a ragdoll (there's no way to come back currently). Needs death_time specified.

// Also add to EffectManager:InternalTriggerEffect()
kEffectTypes =
{
    kCinematicType, kWeaponCinematicType, kViewModelCinematicType, kPlayerCinematicType, kParentedCinematicType, kLoopingCinematicType, kStopCinematicType, 
    kAnimationType, kViewModelAnimationType, kOverlayAnimationType,
    kSoundType, kParentedSoundType, kLoopingSoundType, kPrivateSoundType, kStopSoundType, 
    kStopEffectsType,
    kDecalType,
    kRagdollType,
}

// For cinematics and sounds, you can specify the asset names like this:
// Set to "cinematics/marine/rifle/shell.cinematic" or use a table like this to control probability:
// { {1, "cinematics/marine/rifle/shell.cinematic"}, {.5, "cinematics/marine/rifle/shell2.cinematic"} } // shell2 triggers 1/3 of the time
// TODO: Account for GetRicochetEffectFrequency
// TODO: Sentry:OnAnimationComplete
// TODO: Add hooks for sound parameter changes so they can be applied to specific sound effects here
// TODO: system for IP spin.cinematic (and MAC "fxnode_light" - "cinematics/marine/mac/light.cinematic")
kEffectParamAttachPoint             = "attach_point"
kEffectParamBlendTime               = "blend_time"
kEffectParamAnimationSpeed          = "speed"
kEffectParamForce                   = "force"
kEffectParamSilent                  = "silent"
kEffectParamVolume                  = "volume"
kEffectParamDeathTime               = "death_time"  
kEffectParamLifetime                = "lifetime"        // Lifetime for decals (default is 5)
kEffectParamScale                   = "scale"           // Scale for decals (default is 5)
kEffectSoundParameter               = "sound_param"     // Not working yet
kEffectParamDone                    = "done"
kEffectParamWorldSpace              = "world_space"     // If true, the cinematic will emit particles into world space.
kEffectParamWorldSpaceExceptPlayer  = "world_space_except_player" // Emit into world space but don't send to the triggering player.

// General effects. Chooses one effect from each block. Name of block is unused except for debugging/clarity. Add to InternalGetEffectMatches().
kEffectFilterClassName              = "classname"
kEffectFilterDoerName               = "doer"
kEffectFilterDamageType             = "damagetype"
kEffectFilterIsAlien                = "isalien"
kEffectFilterIsMarine               = "ismarine"
kEffectFilterBuilt                  = "built"
kEffectFilterFlinchSevere           = "flinch_severe"
kEffectFilterInAltMode              = "alt_mode"
kEffectFilterOccupied               = "occupied"
kEffectFilterEmpty                  = "empty"
kEffectFilterVariant                = "variant"
kEffectFilterFrom                   = "from"
kEffectFilterFromAnimation          = "from_animation"      // The current animation, or the animation just finished during animation_complete
kEffectFilterFrom                   = "upgraded"
kEffectFilterLeft                   = "left"
kEffectFilterActive                 = "active"              // Generic "active" tag to denote change of state. Used for infantry portal spinning effects.
kEffectFilterHitSurface             = "surface"             // Set in events that hit something
kEffectFilterDeployed               = "deployed"            // When entity is in a deployed state
kEffectFilterCloaked                = "cloaked"
kEffectFilterEnemy                  = "enemy"

kEffectFilters =
{
    kEffectFilterClassName, kEffectFilterDoerName, kEffectFilterDamageType, kEffectFilterIsAlien, kEffectFilterIsMarine, kEffectFilterBuilt, kEffectFilterFlinchSevere,
    kEffectFilterInAltMode, kEffectFilterOccupied, kEffectFilterEmpty, kEffectFilterVariant, kEffectFilterFrom, kEffectFilterFromAnimation, 
    kEffectFilterFrom, kEffectFilterLeft, kEffectFilterActive, kEffectFilterHitSurface, kEffectFilterDeployed, kEffectFilterCloaked, kEffectFilterEnemy
}

// Load effect data, adding to effect manager
Script.Load("lua/GeneralEffects.lua")
Script.Load("lua/ClientEffects.lua")
Script.Load("lua/PlayerEffects.lua")
Script.Load("lua/MarineStructureEffects.lua")
Script.Load("lua/MarineWeaponEffects.lua")
Script.Load("lua/AlienStructureEffects.lua")
Script.Load("lua/AlienWeaponEffects.lua")

// Pre-cache effect assets
GetEffectManager():PrecacheEffects()