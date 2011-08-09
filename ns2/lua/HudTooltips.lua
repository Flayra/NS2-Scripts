//=============================================================================
//
// lua/HudTooltips.lua
// 
// Created by Henry Kropf
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

local tooltipMessage = ""
local tooltipSet = false

/**
* Return "" when nothing to set, otherwise put message string in for one frame
*/
function HudTooltipUI_GetMessage()

    if(tooltipSet) then
        tooltipSet = false
        return tooltipMessage
    end
    
    return ""
    
end

function HudTooltip_SetMessage(message)
    tooltipSet = true
    tooltipMessage = message
end