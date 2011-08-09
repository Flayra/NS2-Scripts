//=============================================================================
//
// lua/Update.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/*
 * Update sequence
 *
 * Return true from IsUpdateAvailable, GetUpdateProgress should be 0
 * SWF calls StartUpdateDownload -> downloading starts
 * Return true from IsUpdateAvailable, GetUpdateProgress should be 0-1
 * Finish download...
 * Return false from IsUpdateAvailable, GetUpdateProgress should be 1
 * SWF calls UpdateUI_StartUpdateInstall
 */

local updateAvailable = nil
local startedDownload = false

/**
 * Return if update is available
 * returns true or false
 */
function UpdateUI_IsUpdateAvailable()
    return false    
end

/**
 * Get update download progress 
 * returns [0-1]
 */
function UpdateUI_GetUpdateProgress()
    return 0
end

/**
 * Start network download
 */
function UpdateUI_StartUpdateDownload()
    startedDownload = false
end

/**
 * Start install progress
 */
function UpdateUI_StartUpdateInstall()
end
