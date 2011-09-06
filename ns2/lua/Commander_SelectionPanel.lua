//=============================================================================
//
// lua/Commander_SelectionPanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

/**
 * Return the number of entities currently selected by a commander
 */
function CommanderUI_GetSelectedEntitiesCount()

    return table.count(Client.GetLocalPlayer():GetSelection())

end

/**
 * Return a list of entities selected by a commander
 */
function CommanderUI_GetSelectedEntities()

    local player = Client.GetLocalPlayer()
    if player.GetSelection then
        return player:GetSelection()
    end
    
    return { }
        
end

/**
 * Player is selecting all active players. Sets local selection and sends command to server.
 */
function CommanderUI_ClickedSelectAllPlayers()
    
    local player = Client.GetLocalPlayer()
    if player and player.SelectAllPlayers then
    
        player:SelectAllPlayers()        
        Client.ConsoleCommand("selectallplayers")
        
    end
        
end

/**
 * Get up to 2 <text>,[0-1] pairs in linear array for bargraphs on the commander selection
 */
function CommanderUI_GetCommandBargraphs()

    local selectedEnts = Client.GetLocalPlayer():GetSelection()
    
    if (table.count(selectedEnts) == 1) then
    
        local entId = selectedEnts[1]
        return CommanderUI_GetSelectedBargraphs(entityId)
        
    end

    return {}
    
end

/**
 * Get a string that describes the entity
 */
function CommanderUI_GetSelectedDescriptor(entityId)
    local player = Client.GetLocalPlayer()
    
    local descriptor = "Unknown"
    local ent = Shared.GetEntity(entityId)
    if(ent ~= nil) then
        descriptor = GetSelectionText(ent, player:GetTeamNumber())
    end
    
    return descriptor
    
end

/**
 * Returns color to draw unit portrait in, and whether it's part of the currently selected sub-group, and 
 * the x/y offsets into the portrait icons image. 
 * For example: {16711935, true, 0, 1}
 */
function CommanderUI_GetPortraitStatus(entityId)

    local healthScalar = 1
    
    local entity = Shared.GetEntity(entityId)
    if entity ~= nil and HasMixin(entity, "Live") then
        healthScalar = entity:GetHealthScalar()
    end
    
    local color = ColorArrayToInt(GetHealthColor(healthScalar))
    
    local inSelectedSubGroup = Client.GetLocalPlayer():GetIsEntityInSelectedSubGroup(entity)
    
    if entity then
    
        local success, x, y = GetPortraitIconOffsetsFromTechId(entity:GetTechId())
        if not success then
            //Print("CommanderUI_GetPortraitStatus(): Couldn't find portrait icon offsets for entity %s", entity:GetClassName())
        end
        
    end
    
    return {color, inSelectedSubGroup, x, y}
    
end

/**
 * Get a string that describes the entity location
 */
function CommanderUI_GetSelectedLocation(entityId)

    local locationText = ""
    local ent = Shared.GetEntity(entityId)
    if (ent ~= nil) and ent.GetLocationName then
        locationText = locationText .. ent:GetLocationName()
    else
        Print("CommanderUI_GetSelectedLocation(): Entity %d is nil.", entityId)
    end
        
    return locationText

end

function CommanderUI_GetSelectedHealth(entityId)

    local ent = Shared.GetEntity(entityId)
    if ent and ent.GetHealth and ent.GetMaxHealth then
        return string.format("%d/%d", math.floor(ent:GetHealth()), math.ceil(ent:GetMaxHealth()))
    end
    
    return ""

end

function CommanderUI_GetSelectedArmor(entityId)

    local ent = Shared.GetEntity(entityId)
    if ent and ent.GetArmor and ent.GetMaxArmor then
        return string.format("%d/%d", math.floor(ent:GetArmor()), math.ceil(ent:GetMaxArmor()))
    end
    
    return ""

end

function CommanderUI_GetSelectedEnergy(entityId)

    local ent = Shared.GetEntity(entityId)
    if ent and ent.GetEnergy and ent.GetMaxEnergy then
        return string.format("%d/%d", math.floor(ent:GetEnergy()), math.ceil(ent:GetMaxEnergy()))
    end
    
    return ""

end

function GetSquadForEntity(entityId)

    local entity = Shared.GetEntity(entityId)
    
    if (entity ~= nil and entity:isa("Marine")) then
    
        local squad = entity:GetSquad()
       
        if (squad > 0 and squad <= kNumSquads) then
        
            return squad
            
        end
        
    end
    
    return nil
        
end

/**
 * Get a string that describes the entity's squad
 */
function CommanderUI_GetSelectedSquad(entityId)

    local squad = GetSquadForEntity(entityId)
    
    if (squad ~= nil) then
       
        return GetNameForSquad(squad)
            
    end
    
    return ""
    
end

/**
 * Get a number that is the RGB value for the color of the squad
 */
function CommanderUI_GetSelectedSquadColor(entityId)

    local colorInt = 0
    local squadIndex = GetSquadForEntity(entityId)
    
    if (squadIndex ~= nil) then
    
        colorInt = ColorArrayToInt(GetColorForSquad(squadIndex))
    
    end

    return colorInt

end

/**
 * Get up to 2 <text>,[0-1] pairs in linear array for bargraphs on the selected entity
 */
function CommanderUI_GetSelectedBargraphs(entityId)

    local t = {}
    
    local ent = Shared.GetEntity(entityId)
    
    if (ent ~= nil) then

        // Health bar with current and max health
        local healthText, healthScalar = ent:GetHealthDescription()
        table.insert(t, healthText)
        table.insert(t, healthScalar)
        
        // Returns text and 0-1 scalar for status bar on commander HUD when selected. Returns nil to display nothing.
        if ent.GetStatusDescription then
        
            // Build, upgrade or research bar
            local statusText, statusScalar = ent:GetStatusDescription()
            
            if statusText ~= nil then
                table.insert(t, statusText)
                table.insert(t, statusScalar)
            end
            
        end
    
    end
        
    return t
    
end

/**
 * Return pixel coordinates to the selected entity icon
 */
function CommanderUI_GetSelectedIconOffset(entityId)
    
    local isaMarine = Client.GetLocalPlayer():isa("MarineCommander")
    return GetPixelCoordsForIcon(entityId, isaMarine)
    
end

/**
 * Indicates the entity selected from a multiple-selection panel.
 */
function CommanderUI_ClickedSelectedEntity(entityId)
end


/**
 * Get custom rightside selection text for the commander selection pane
 */
function CommanderUI_GetCommanderSelectionCustomText()
    // Return description of what we have selected
    return "Energy 50/200"
end

function CommanderUI_GetCommandStationDescriptor()
end

function CommanderUI_GetCommandStationLocation()
end

function CommanderUI_GetCommandIconOffset()
end

/**
 * Get custom rightside selection text for a single selection
 */
function CommanderUI_GetSingleSelectionCustomText(entId)

    local customText = ""
    
    if entId ~= nil then
    
        local ent = Shared.GetEntity(entId)    
        if ent ~= nil and ent.GetCustomSelectionText then
            customText = ent:GetCustomSelectionText()
        end
        
    end
    
    return customText
    
end