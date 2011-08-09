//=============================================================================
//
// lua/ScoreDisplay.lua
// 
// Created by Henry Kropf
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

local pendingScore = 0
local pendingRes = 0

/**
 * Gets current score variable, returns it and sets var to 0. Also 
 * returns res given to player (0 to not display).
 */
function ScoreDisplayUI_GetNewScore()
    local tempScore = pendingScore
    local tempRes = pendingRes
    
    pendingScore = 0
    pendingRes = 0
    
    return tempScore, tempRes
end


/**
 * Called to set latest score
 */
function ScoreDisplayUI_SetNewScore(score, res)
    pendingScore = score
    pendingRes = res
end
