//=============================================================================
//
// lua/OptionsDialog.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

function BuildDisplayModesList()

    local modes = { }
    local numModes = Client.GetNumDisplayModes()
    
    for modeIndex = 1, numModes do
        modes[modeIndex] = Client.GetDisplayMode(modeIndex)
    end

    return modes
    
end

/**
 * Get player nickname. Use previously set name if available, otherwise use Steam name, otherwise use "NSPlayer"
 */
function OptionsDialogUI_GetNickname()

    local playerName = Client.GetUserName()
    
    if(playerName == "") then
        playerName = "NsPlayer"
    end
    
    return Client.GetOptionString( kNicknameOptionsKey, playerName )
    
end

/**
 * Get mouse sensitivity
 * 0 = min sensitivity
 * 100 = max sensitivity
 */
function OptionsDialogUI_GetMouseSensitivity()
    return Client.GetMouseSensitivity() * kMouseSensitivityScalar
end

function OptionsDialogUI_SetMouseSensitivity(sensitivity)
    Client.SetMouseSensitivity( sensitivity / kMouseSensitivityScalar )
end

/**
 * Get linear array of screen resolutions (strings)
 */
function OptionsDialogUI_GetScreenResolutions()

    // Determine the aspect ratio of the monitor based on the startup resolution.
    // We use this to flag modes that have the same aspect ratio.
    
    local mode = Client.GetStartupDisplayMode()
    local nativeAspect = mode.xResolution / mode.yResolution

    local resolutions = { }
    
    for modeIndex = 1, table.maxn(displayModes) do
    
        local mode = displayModes[modeIndex]
        local aspect = mode.xResolution / mode.yResolution
        
        local resolution = string.format('%dx%d', mode.xResolution, mode.yResolution)
        
        if (aspect == nativeAspect) then
            resolution = resolution .. " *"
        end
        
        resolutions[modeIndex] = resolution
        
    end

    return resolutions
    
end

/**
 * Get current index for screen res (assuming lua indexing for script convenience)
 */
function OptionsDialogUI_GetScreenResolutionsIndex()

    local xResolution = Client.GetOptionInteger( kGraphicsXResolutionOptionsKey, 1280 )
    local yResolution = Client.GetOptionInteger( kGraphicsYResolutionOptionsKey, 800 )

    for modeIndex = 1, table.maxn(displayModes) do
    
        local mode = displayModes[modeIndex]
        
        if (mode.xResolution == xResolution and mode.yResolution == yResolution) then
            return modeIndex
        end
    
    end
    
    return 1

end

/**
 * Get linear array of visual detail settings (strings)
 */
function OptionsDialogUI_GetVisualDetailSettings()
    return { "Ridiculously Awful", "Medium", "High" }
end

/**
 * Get current index for detail settings (assuming lua indexing for script convenience)
 */
function OptionsDialogUI_GetVisualDetailSettingsIndex()
    return 1 + Client.GetOptionInteger(kDisplayQualityOptionsKey, 0)
end


/**
 * Get sound volume
 * 0 = min volume
 * 100 = max volume
 */
function OptionsDialogUI_GetSoundVolume()
    // Defaulting sound and music to 90% as requested by Simon on 10/26/10.
    // If too loud as a default, we can go back to 75% and 65%.
    return Client.GetOptionInteger( kSoundVolumeOptionsKey, 90 )
end

function OptionsDialogUI_SetSoundVolume(volume)
    Client.SetOptionInteger( kSoundVolumeOptionsKey, volume )
    Client.SetSoundVolume( volume / 100 )
end

/**
 * Get music volume
 * 0 = min volume
 * 100 = max volume
 */
function OptionsDialogUI_GetMusicVolume()
    return Client.GetOptionInteger( kMusicVolumeOptionsKey, 90 )
end

function OptionsDialogUI_SetMusicVolume(volume)
    Client.SetOptionInteger( kMusicVolumeOptionsKey, volume )
    Client.SetMusicVolume( volume / 100 )
end

function OptionsDialogUI_SetVoiceVolume(volume)
    Client.SetOptionInteger( kVoiceVolumeOptionsKey, volume )
    Client.SetVoiceVolume( volume / 100 )
end

function OptionsDialogUI_GetVoiceVolume()
    return Client.GetOptionInteger( kVoiceVolumeOptionsKey, 90 )
end


/**
 * Get all the values from the form
 * nickname - string for nick
 * mouseSens - 0 - 100
 * screenResIdx - 1 - ? index of choice
 * visualDetailIdx - 1 - ? index of choice
 * soundVol - 0 - 100 - sound volume
 * musicVol - 0 - 100 - music volume
 * windowed - true/false run in windowed mode
 * invMouse - true/false (true == mouse is inverted)
 */
function OptionsDialogUI_SetValues(nickname, mouseSens, screenResIdx, visualDetailIdx, soundVol, musicVol, windowed, invMouse, voiceVol)

    Client.SetOptionString( kNicknameOptionsKey, nickname )
    
    OptionsDialogUI_SetMouseSensitivity( mouseSens )
    
    // Save screen res and visual detail
    Client.SetOptionInteger( kGraphicsXResolutionOptionsKey, displayModes[screenResIdx].xResolution )
    Client.SetOptionInteger( kGraphicsYResolutionOptionsKey, displayModes[screenResIdx].yResolution )
    Client.SetOptionInteger( kDisplayQualityOptionsKey, visualDetailIdx - 1 )     // set the value as 0-based index

    // Save sound and music options 
    OptionsDialogUI_SetSoundVolume( soundVol )
    OptionsDialogUI_SetMusicVolume( musicVol )
    OptionsDialogUI_SetVoiceVolume( voiceVol )
    
    Client.SetOptionBoolean ( kFullscreenOptionsKey, not windowed )
    
    // Handle invMouse
    Client.SetOptionBoolean ( kInvertedMouseOptionsKey, invMouse )
    
end

function OptionsDialogUI_OnInit()

    local soundVol = OptionsDialogUI_GetSoundVolume()
    local musicVol = OptionsDialogUI_GetMusicVolume()
    
    // Set current levels (0-1)
    Client.SetSoundVolume( soundVol/100 )
    Client.SetMusicVolume( musicVol/100 )

end


/**
 * Get windowed or not
 */
function OptionsDialogUI_GetWindowed()
    return not Client.GetOptionBoolean( kFullscreenOptionsKey, false )    
end

/**
 * Get mouse inversion
 */
function OptionsDialogUI_GetMouseInverted()
    return Client.GetOptionBoolean ( kInvertedMouseOptionsKey, false )
end

/**
 * Signal that the user has exited the options dialog with display options changed
 */
function OptionsDialogUI_ExitDialog()
    
    Client.ReloadGraphicsOptions()
    
end


displayModes = BuildDisplayModesList()

// Load and set default sound levels
OptionsDialogUI_OnInit()

