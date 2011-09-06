// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DSPEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// From FMOD documentation:
//
// DSP_Mixer        This unit does nothing but take inputs and mix them together then feed the result to the soundcard unit.
// DSP_Oscillator   This unit generates sine/square/saw/triangle or noise tones.
// DSP_LowPass      This unit filters sound using a high quality, resonant lowpass filter algorithm but consumes more CPU time.
// DSP_ITLowPass    This unit filters sound using a resonant lowpass filter algorithm that is used in Impulse Tracker, but with limited cutoff range (0 to 8060hz).
// DSP_HighPass     This unit filters sound using a resonant highpass filter algorithm.
// DSP_Echo         This unit produces an echo on the sound and fades out at the desired rate.
// DSP_Flange       This unit produces a flange effect on the sound.
// DSP_Distortion   This unit distorts the sound.
// DSP_Normalize    This unit normalizes or amplifies the sound to a certain level.
// DSP_ParamEQ      This unit attenuates or amplifies a selected frequency range.
// DSP_PitchShift   This unit bends the pitch of a sound without changing the speed of playback.
// DSP_Chorus       This unit produces a chorus effect on the sound.
// DSP_Reverb       This unit produces a reverb effect on the sound.
// DSP_VSTPlugin    This unit allows the use of Steinberg VST plugins.
// DSP_WinampPlugin This unit allows the use of Nullsoft Winamp plugins.
// DSP_ITEcho       This unit produces an echo on the sound and fades out at the desired rate as is used in Impulse Tracker.
// DSP_Compressor   This unit implements dynamic compression (linked multichannel, wideband).
// DSP_SFXReverb    This unit implements SFX reverb.
// DSP_LowPassSimple This unit filters sound using a simple lowpass with no resonance, but has flexible cutoff and is fast.
// DSP_Delay            This unit produces different delays on individual channels of the sound.
// DSP_Tremolo      This unit produces a tremolo/chopper effect on the sound.
//            
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Look at kDSPType
function CreateDSPs()

    // "NearDeath"
    // Simon - Near-death effect low-pass filter
    local dspId = Client.CreateDSP(SoundSystem.DSP_LowPassSimple)    
    Client.SetDSPFloatParameter(dspId, 0, 2738)
    if dspId ~= kDSPType.NearDeath then
        Print("CreateDSPs(): NearDeath DSP id is %d instead of %d", dspId, kDSPType.NearDeath)
    end    
    
    // "ShadeDisorientFlange"
    /*
    dspId = Client.CreateDSP(SoundSystem.DSP_Flange)    
    if dspId ~= kDSPType.ShadeDisorientFlange then
        Print("CreateDSPs(): ShadeDisorientFlange DSP id is %d instead of %d", dspId, kDSPType.ShadeDisorientFlange)
    end    

    // "ShadeDisorientLoPass"
    dspId = Client.CreateDSP(SoundSystem.DSP_LowPassSimple)    
    if dspId ~= kDSPType.ShadeDisorientLoPass then
        Print("CreateDSPs(): ShadeDisorientLoPass DSP id is %d instead of %d", dspId, kDSPType.ShadeDisorientLoPass)
    end*/
    
    // "master"
    dspId = Client.CreateDSP(SoundSystem.DSP_Compressor)
    //             threshold
    Client.SetDSPFloatParameter(dspId, 0, .320)
    //               attack
    Client.SetDSPFloatParameter(dspId, 1, .320)
    //               release
    Client.SetDSPFloatParameter(dspId, 2, .320)
    //            make up gain
    Client.SetDSPFloatParameter(dspId, 4, .320)
    
end

// Set to 0 to disable
function UpdateShadeDSPs()

    local scalar = 0    
    
    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "Disorientable") then
        scalar = player:GetDisorientedAmount()
    end

    // Simon - Shade disorient drymix
    Client.SetDSPFloatParameter(kDSPType.ShadeDisorientFlange, 0, .922)
    // Simon - Shade disorient wetmix
    Client.SetDSPFloatParameter(kDSPType.ShadeDisorientFlange, 1, .766)
    // Simon - Shade disorient depth
    Client.SetDSPFloatParameter(kDSPType.ShadeDisorientFlange, 2, .550)
    // Simon - Shade disorient rate
    Client.SetDSPFloatParameter(kDSPType.ShadeDisorientFlange, 3,  0.6)
    
    // Simon - Shade disorient low-pass filter
    local kMinFrequencyValue = 10
    Client.SetDSPFloatParameter(kDSPType.ShadeDisorientLoPass, 0, kMinFrequencyValue + 523)
    
    local active = (scalar > 0)
    Client.SetDSPActive(kDSPType.ShadeDisorientFlange, active)
    Client.SetDSPActive(kDSPType.ShadeDisorientLoPass, active)

end

function UpdateDSPEffects()

    local player = Client.GetLocalPlayer()
    
    // Near death
    Client.SetDSPActive(kDSPType.NearDeath, player:GetGameEffectMask(kGameEffect.NearDeath))
    
    // Removed because of over the top right now
    //UpdateShadeDSPs()
    
end

