// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Buttons.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Commander_Hotkeys.lua")
Script.Load("lua/TechTreeButtons.lua")

// Maps tech buttons to keys in "grid" system
kGridHotkeys =
{
    Move.Q, Move.W, Move.E, Move.R,
    Move.A, Move.S, Move.D, Move.F,
    Move.Z, Move.X, Move.C, Move.V,
}

/**
 * Called by Flash when the user presses the "Logout" button.
 */
function CommanderUI_Logout()

    local commanderPlayer = Client.GetLocalPlayer()
    commanderPlayer:Logout()
        
end

function CommanderUI_MenuButtonWidth()
    return 80
end

function CommanderUI_MenuButtonHeight()
    return 80
end

/*
    Return linear array consisting of:    
    tooltipText (String)
    tooltipHotkey (String)
    tooltipCost (Number)
    tooltipRequires (String) - optional, specify "" or nil if not used
    tooltipEnables (String) - optional, specify "" or nil if not used
    tooltipInfo (String)
    tooltipType (Number) - 0 = team resources, 1 = individual resources, 2 = energy
*/
function CommanderUI_MenuButtonTooltip(index)

    local player = Client.GetLocalPlayer()

    local techId = nil
    local tooltipText = nil
    local hotkey = nil
    local cost = nil
    local requiresText = nil
    local enablesText = nil
    local tooltipInfo = nil
    local resourceType = 0
    
    if(index <= table.count(player.menuTechButtons)) then
    
        local techTree = GetTechTree()
        techId = player.menuTechButtons[index]        
        
        tooltipText = techTree:GetDescriptionText(techId)
        hotkey = kGridHotkeys[index]
        
        if hotkey ~= "" then
            hotkey = gHotkeyDescriptions[hotkey]
        end
        
        cost = LookupTechData(techId, kTechDataCostKey, 0)
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            resourceType = techNode:GetResourceType()
        end
        requiresText = techTree:GetRequiresText(techId)
        enablesText = techTree:GetEnablesText(techId)
        tooltipInfo = GetTooltipInfoText(techId)
        
    end
    
    return {tooltipText, hotkey, cost, requiresText, enablesText, tooltipInfo, resourceType}    
    
end

/** 
 * Returns the current status of the button. 
 * 0 = button or tech not found, or currently researching, don't display
 * 1 = available and ready, display as pressable
 * 2 = available but not currently, display in red
 * 3 = not available, display grayed out (also for invalid actions, ie Recycle)
 */
function CommanderUI_MenuButtonStatus(index)

    local player = Client.GetLocalPlayer()
    local buttonStatus = 0
    local techId = 0
    
    if(index <= table.count(player.menuTechButtons)) then
    
        techId = player.menuTechButtons[index]
        
        if(techId ~= kTechId.None) then
        
            local techNode = GetTechTree():GetTechNode(techId)
            
            if(techNode ~= nil) then
            
                if techNode:GetResearching() then
                    // Don't display
                    buttonStatus = 0
                elseif not techNode:GetAvailable() then
                    // Greyed out
                    buttonStatus = 3
                // menuTechButtonsAllowed[] contains results of appropriate team resources, individual resources or energy check
                elseif not player.menuTechButtonsAllowed[index] then                
                    // Show activations with cost and buys in red, actions in gray
                    if techNode:GetIsActivation() then
                        buttonStatus = ConditionalValue(techNode:GetCost() > 0, 3, 2)
                    else
                        buttonStatus = ConditionalValue(techNode:GetIsAction(), 3, 2)
                    end                    
                else
                    // Available
                    buttonStatus = 1
                end

            else
                Print("CommanderUI_MenuButtonStatus(%s): Tech node for id %s not found (%s)", tostring(index), EnumToString(kTechId, techId), table.tostring(player.menuTechButtons))
            end
            
        end
        
    end    
    
    return buttonStatus

end

function CommanderUI_MenuButtonAction(index)

    local player = Client.GetLocalPlayer()
    
    if(index <= table.count(player.menuTechButtons)) then

        // Trigger button press (open menu, build tech, etc.)    
        player:SetCurrentTech(player.menuTechButtons[index])
        
    end
    
end

function CommanderUI_MenuButtonXOffset(index)

    local player = Client.GetLocalPlayer()
    if(index <= table.count(player.menuTechButtons)) then
    
        local techId = player.menuTechButtons[index]
        local xOffset, yOffset = GetMaterialXYOffset(techId, player:isa("MarineCommander"))
        return xOffset
        
    end
    
    return -1
    
end

function CommanderUI_MenuButtonYOffset(index)

    local player = Client.GetLocalPlayer()
    if(index <= table.count(player.menuTechButtons)) then
    
        local techId = player.menuTechButtons[index]
        if(techId ~= kTechId.None) then
            local xOffset, yOffset = GetMaterialXYOffset(techId, player:isa("MarineCommander"))
            return yOffset
        end
    end
    
    return -1
    
end

function Commander:UpdateMenu(deltaTime)

    if(self.menuTechId == nil) then
        self.menuTechId = kTechId.RootMenu
    end    
    
    self:UpdateSharedTechButtons()
    self:ComputeMenuTechAvailability()
    
end

// Look at current selection and our current menu (self.menuTechId) and build a list of tech
// buttons that represents valid orders for the Commander. Store in self.menuTechButtons.
// Allow nothing to be selected too.
function Commander:UpdateSharedTechButtons()

    self.menuTechButtons = {}
    
    if(table.count(self.selectedSubGroupEntityIds) > 0) then
    
        // Loop through all entities and get their tech buttons
        local selectedTechButtons = {}
        local maxTechButtons = 0
        for selectedEntityIndex, entityId in ipairs(self.selectedSubGroupEntityIds) do
        
            local entity = Shared.GetEntity(entityId)        
            if(entity ~= nil) then

                local techButtons = self:GetCurrentTechButtons(self.menuTechId, entity)
                
                if(techButtons ~= nil) then
                    table.insert(selectedTechButtons, techButtons)
                    maxTechButtons = math.max(maxTechButtons, table.count(techButtons))
                end
                
            end
        
        end
        
        // Now loop through tech button lists and use only the tech that doesn't conflict. These will generally be the same
        // tech id, but could also be a techid that not all selected units have, so long as the others don't specify a button
        // in the same position (ie, it is kTechId.None).
        local techButtonIndex = 1
        for techButtonIndex = 1, maxTechButtons do

            local buttonConflicts = false
            local buttonTechId = kTechId.None
            local highestButtonPriority = 0
            
            for index, techButtons in pairs(selectedTechButtons) do
            
                local currentButtonTechId = techButtons[techButtonIndex]
                
                // Lookup tech id priority. If not specified, treat as 0.
                local currentButtonPriority = LookupTechData(currentButtonTechId, kTechDataMenuPriority, 0)

                if(buttonTechId == kTechId.None) then
                
                    buttonTechId = currentButtonTechId
                    highestButtonPriority = currentButtonPriority
                    
                elseif((currentButtonTechId ~= buttonTechId) and (currentButtonTechId ~= kTechId.None)) then
                    
                    if(currentButtonPriority > highestButtonPriority) then
                        
                        highestButtonPriority = currentButtonPriority
                        buttonTechId = currentButtonTechId
                        buttonConflicts = false                            
                    
                    elseif(currentButtonPriority == highestButtonPriority) then
                    
                        buttonConflicts = true
                        
                    end
                    
                end
                
            end     
            
            if(not buttonConflicts) then
                table.insert(self.menuTechButtons, buttonTechId)
            end
            
        end
        
    else
    
        // Populate with regular tech button menu when nothing selected (ie, marine quick menu)
        local techButtons = self:GetCurrentTechButtons(self.menuTechId, nil)                
        if techButtons then
            for techButtonIndex = 1, table.count(techButtons) do
                local buttonTechId = techButtons[techButtonIndex]
                table.insert(self.menuTechButtons, buttonTechId)
            end
        end
        
    end

end

function Commander:IsTabSelected (techId)
    if (self.buttonsScript == nil) then
        return false
    end        
    
    return self.buttonsScript:IsTab(techId), self.buttonsScript:IsTabSelected(kTechId.RootMenu)
end

function Commander:ComputeMenuTechAvailability()

    self.menuTechButtonsAllowed = {}
    
    local techTree = GetTechTree()

    for index, techId in ipairs(self.menuTechButtons) do
    
        local techNode = techTree:GetTechNode(techId)
        local menuTechButtonAllowed = false
        
        if table.count(self.selectedSubGroupEntityIds) == 0 then
        
            menuTechButtonAllowed = true
            
        // Loop through all selected entities. If any of them allow this tech, then the button is enabled
        else
            local isTab = false
            local isSelect = true
            // $AS - FIXME: Find a better way to do this
            if not CommanderUI_IsAlienCommander() then
                isTab, isSelect = self:IsTabSelected(techId)
            end
            
            if isTab then
                menuTechButtonAllowed = true
            else
            
                for index, entityId in ipairs(self.selectedSubGroupEntityIds) do
                
                    local entity = Shared.GetEntity(entityId)
                    local isTechAllowed = false
                    
                    if entity then
                        if isSelect then
                            isTechAllowed = entity:GetTechAllowed(techId, techNode, self)
                        else
                            isTechAllowed = self:GetTechAllowed(techId, techNode, self)
                        end
                        
                        menuTechButtonAllowed = isTechAllowed
                        break
                    
                    end
                end
            end
        end       
        
        table.insert(self.menuTechButtonsAllowed, menuTechButtonAllowed)
    
    end
        
end

