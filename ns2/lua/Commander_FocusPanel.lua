//=============================================================================
//
// lua/Commander_FocusPanel.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================
Script.Load("lua/AlienUpgrades_Client.lua")
Script.Load("lua/AlienPortrait_Client.lua")

/**
 * Return the selected item
 */
function CommanderUI_GetFocusSelectionDescriptor()
    return Client.GetLocalPlayer():GetFocusSelectionDescriptor()
end

/**
 * Return up to 2 ratio entries for display in the focus area
 * Format is {color, amount, max amount, showAsBar (boolean) ... }
 * return {16711935, 50, 150, false}
 */
function CommanderUI_GetFocusSelectionRatios()
    return Client.GetLocalPlayer():GetFocusSelectionRatios()
end

/**
 * Return image reference name for the main unit image atlas (128x128)
 */
function CommanderUI_FocusImage()
    return "alien_focusicons"
end

/**
 * Return image reference name for the unit portraits image atlas (80x80)
 */
function CommanderUI_PortraitImage()
    return "alien_portraiticons"
end

/**
 * Return an array specifying x and y offsets for the central image
 * Format is {x, y}, value is multiplied by 128 on each axis in flash
 */
function CommanderUI_GetFocusSelectionImageOffsets()

    local t = {}
    
    local player = Client.GetLocalPlayer()
    local entity = player:GetRepresentativeSelectedEntity()
    if entity ~= nil then
    
        local success, x, y = GetPortraitIconOffsetsFromTechId(entity:GetTechId())
        if success then
        
            table.insert(t, x)
            table.insert(t, y)
            
        end
        
    end
    
    return t
        
end

/**
 * Return an array specifying up to 4 x and y offsets for the icons 
 * in the focus panel
 * Format is {x, y, ....}, value is multiplied by 20 on each axis in flash
 */
function CommanderUI_GetFocusSelectionIcons()

    local iconIndices = {}
    
    local player = Client.GetLocalPlayer()
    
    local entity = player:GetRepresentativeSelectedEntity()
    
    if entity ~= nil and HasMixin(entity, "Upgradable") then
    
        // Get upgrades 
        local upgrades = entity:GetUpgrades()
        
        for index, upgradeTechId in ipairs(upgrades) do

            // For up to first four elements, return their icons
            local success, iconX, iconY = GetAlienUpgradeIconXY(upgradeTechId)
            table.insert(iconIndices, iconX)
            table.insert(iconIndices, iconY)
            
        end
        
    end
    
    return iconIndices
    
end

function Commander:GetRepresentativeSelectedEntity()

    if table.count(self.selectedSubGroupEntities) > 0 then
    
        return self.selectedSubGroupEntities[1]
        
    end
    
    return nil

end

function Commander:GetFocusSelectionDescriptor()

    local entity = Client.GetLocalPlayer():GetRepresentativeSelectedEntity()
    if entity ~= nil then
        return string.format("%s", GetDisplayNameForTechId(entity:GetTechId()))    
    else
        return ""
    end
    
end

function Commander:GetFocusSelectionRatios()

    local t = { }
    
    local entity = Client.GetLocalPlayer():GetRepresentativeSelectedEntity()
    
    if entity ~= nil and HasMixin(entity, "Live") then
    
        // Return health (colors are RBA).
        table.insert(t, ColorArrayToInt(GetHealthColor(entity:GetHealth() / entity:GetMaxHealth())))
        table.insert(t, math.ceil(entity:GetHealth()))
        table.insert(t, math.ceil(entity:GetMaxHealth()))
        table.insert(t, false)
        
        // Return energy display, if any.
        if HasMixin(entity, "Energy") and entity:GetMaxEnergy() > 0 then
        
            // White.
            local component = 127 + (entity:GetEnergy() / entity:GetMaxEnergy()) * 128
            table.insert(t, ColorArrayToInt({component, component, component}))
            table.insert(t, math.ceil(entity:GetEnergy()))
            table.insert(t, math.ceil(entity:GetMaxEnergy()))
            table.insert(t, false)
            
        end

    end

    return t
    
end