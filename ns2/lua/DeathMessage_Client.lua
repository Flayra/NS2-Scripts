// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DeathMessage_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kSubImageWidth = 128
local kSubImageHeight = 64

local queuedDeathMessages = {}

// Can't have multi-dimensional arrays so return potentially very long array [color, name, color, name, doerid, ....]
function DeathMsgUI_GetMessages()

    local returnArray = {}
    local arrayIndex = 1
    
    // return list of recent death messages
    for index, deathMsg in ipairs(queuedDeathMessages) do
    
        for deathMessageIndex, element in ipairs(deathMsg) do
            table.insert(returnArray, element)
        end
        
    end
    
    // Clear current death messages
    table.clear(queuedDeathMessages)
    
    return returnArray
    
end

function DeathMsgUI_MenuImage()
    return "death_messages"
end

function DeathMsgUI_GetTechOffsetX(doerId)
    return 0
end

function DeathMsgUI_GetTechOffsetY(iconIndex)

    if not iconIndex then
        iconIndex = 1
    end
    
    return (iconIndex - 1)*kSubImageHeight
    
end

function DeathMsgUI_GetTechWidth(doerId)
    return kSubImageWidth
end

function DeathMsgUI_GetTechHeight(doerId)
    return kSubImageHeight
end

function InitDeathMessages(player)

    queuedDeathMessages = {}
    
end

// Pass 1 for isPlayer if coming from a player (look it up from scoreboard data), otherwise it's a tech id
function GetDeathMessageEntityName(isPlayer, clientIndex)

    local name = ""

    if isPlayer == 1 then
        name = Scoreboard_GetPlayerData(clientIndex, "Name")
    elseif clientIndex ~= -1 then
        name = GetDisplayNameForTechId(clientIndex)
    end
    
    if not name then
        name = ""
    end
    
    return name
    
end

function AddDeathMessage(killerIsPlayer, killerIndex, killerTeamNumber, iconIndex, targetIsPlayer, targetIndex, targetTeamNumber)

    local killerName = GetDeathMessageEntityName(killerIsPlayer, killerIndex)
    local targetName = GetDeathMessageEntityName(targetIsPlayer, targetIndex)
    
    // Just display attacker and icon when we kill ourselves
    if killerName == targetName then
        targetName = ""
    end
    
    local deathMessage = {GetColorForTeamNumber(killerTeamNumber), killerName, GetColorForTeamNumber(targetTeamNumber), targetName, iconIndex}
    
    table.insertunique(queuedDeathMessages, deathMessage)
    
end