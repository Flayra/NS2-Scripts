//=============================================================================
//
// lua/Commander_HotkeyPanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Return the number of hotkeys
 */
function CommanderUI_GetTotalHotkeys()

    return Client.GetLocalPlayer():GetNumHotkeyGroups()
    
end

/**
 * Return name for hotkey at index
 */
function CommanderUI_GetHotkeyName(idx)

    return string.format("%d", idx)
    
end

/**
 * Return icon offsets as {x, y} pixel array
 */
function CommanderUI_GetHotkeyIconOffset(idx)

    local player = Client.GetLocalPlayer()
    local hotgroups = player:GetHotkeyGroups()
    local group = hotgroups[idx]
    
    // Use first ent id in group as icon
    local entId = group[1]
    if entId ~= nil then
    
        local entity = Shared.GetEntity(entId)
        if entity ~= nil then
        
            local xOffset, yOffset = GetMaterialXYOffset(entity:GetTechId(), player:isa("MarineCommander"))
            if xOffset ~= nil and yOffset ~= nil then
                return {xOffset, yOffset}
            end
            
        end
        
    end
    
    return nil
    
end

/**
 * Indicates hotkey that user has clicked on
 */
function CommanderUI_SelectHotkey(idx)

    // The server won't know about this selection, we need to manually tell it.
    Client.GetLocalPlayer():SendSelectHotkeyGroupMessage(idx)
    Client.GetLocalPlayer():SelectHotkeyGroup(idx)
    
end

/**
 * Return subicons for the indexed hotkey in linear {x, y} array
 * Return empty array for nothing 
 */
function CommanderUI_GetHotkeySubIcons(idx)
    return {}
end

/**
 * Return bargraph color and percentage in linear array [0-1]
 * Return empty array for nothing
 */
function CommanderUI_GetHotkeyBargraph(idx)
    return {}
end

/**
 * Hotkey tooltip text
 */
function CommanderUI_GetHotkeyTooltip(idx)
    return "Hot group #" .. idx
end
