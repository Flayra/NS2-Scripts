//=============================================================================
//
// lua/BindingsDialog.lua
// 
// Populate and manage key bindings in options screen.
//
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// Default key bindings if not saved in options
// When changing values in the right-hand column, make sure to change BindingsUI_GetBindingsText() below.
local defaults = {
    {"MoveForward", "W"},
    {"MoveLeft", "A"},
    {"MoveBackward", "S"},
    {"MoveRight", "D"},
    {"Jump", "Space"},
    {"MovementModifier", "LeftShift"},
    {"Crouch", "LeftControl"},
    {"PrimaryAttack", "MouseButton0"},
    {"SecondaryAttack", "MouseButton1"},
    {"Reload", "R"},
    {"Use", "E"},
    {"Drop", "G"},
    {"Taunt", "Q"},
    {"VoiceChat", "LeftAlt"},
    {"TextChat", "Return"},
    {"TeamChat", "Y"},
    {"ToggleSayings1", "Z"},
    {"ToggleSayings2", "X"},
    {"ShowMap", "C"},
    {"ToggleVoteMenu", "V"},
    {"Weapon1", "1"},
    {"Weapon2", "2"},
    {"Weapon3", "3"},
    {"Weapon4", "4"},
    {"Weapon5", "5"},
    {"Scoreboard", "Tab"},
    {"ToggleConsole", "Grave"},
    {"ToggleFlashlight", "F"},
}

// Order, names, description of keys in menu
local globalControlBindings = {
    "Movement", "title", "Movement", "",
    "MoveForward", "input", "Move forward", "W",
    "MoveLeft", "input", "Move left", "A",
    "MoveBackward", "input", "Move backward", "S",
    "MoveRight", "input", "Move right", "D",
    "Jump", "input", "Jump", "Space",
    "MovementModifier", "input", "Movement special", "LeftShift",
    "Crouch", "input", "Crouch", "LeftControl",
    "Scoreboard", "input", "Scoreboard", "Tab",
    "Action", "title", "Action", "",
    "PrimaryAttack", "input", "Primary attack", "MouseButton0",
    "SecondaryAttack", "input", "Secondary attack", "MouseButton1",
    "Reload", "input", "Reload", "R",
    "Use", "input", "Use", "E",
    "Drop", "input", "Drop weapon", "G",
    "Buy", "input", "Buy/evolve menu", "B",
    "Taunt", "input", "Taunt", "Q",
    "ToggleSayings1", "input", "Sayings #1", "Z",
    "ToggleSayings2", "input", "Sayings #2", "X",
    "ShowMap", "input", "Show Map", "C",
    "ToggleVoteMenu", "input", "Vote menu", "V",
    "VoiceChat", "input", "Use microphone", "LeftAlt",
    "TextChat", "input", "Public chat", "Y",
    "TeamChat", "input", "Team chat", "Return",
    "Weapon1", "input", "Weapon #1", "1",
    "Weapon2", "input", "Weapon #2", "2",
    "Weapon3", "input", "Weapon #3", "3",
    "Weapon4", "input", "Weapon #4", "4",
    "Weapon5", "input", "Weapon #5", "5",
    "ToggleConsole", "input", "Toggle Console", "Grave",
    "ToggleFlashlight", "input", "Flashlight", "F",
}

local specialKeys = {
    [" "] = "SPACE"
}

function GetDefaultInputValue(controlId)

    local rc = nil

    for index, pair in ipairs(defaults) do
        if(pair[1] == controlId) then
            rc = pair[2]
            break
        end
    end    
        
    return rc
    
end

/**
 * Get the value of the input control
 */
function BindingsUI_GetInputValue(controlId)

    local value = Client.GetOptionString( "input/" .. controlId, "" )

    local rc = nil
    
    if(value ~= "") then
        rc = value
    else
        rc = GetDefaultInputValue(controlId)
        if (rc ~= nil) then
            Client.SetOptionString( "input/" .. controlId, rc )
        end
        
    end
    
    return rc
    
end

/**
 * Set the value of the input control
 */
function BindingsUI_SetInputValue(controlId, controlValue)

    if(controlId ~= nil) then
        Client.SetOptionString( "input/" .. controlId, controlValue )
    end
    
end

/**
 * Return data in linear array of config elements
 * controlId, "input", name, value
 * controlId, "title", name, instructions
 * controlId, "separator", unused, unused
 */
function BindingsUI_GetBindingsData()
    return globalControlBindings   
end

/**
 * Returns list of control ids and text to display for each.
 */
function BindingsUI_GetBindingsTranslationData()

    local bindingsTranslationData = {}

    for i = 0, 255 do
    
        local text = string.upper(string.char(i))
        
        // Add special values (must match any values in 'defaults' above)
        for j = 1, table.count(specialKeys) do
        
            if(specialKeys[j][1] == text) then
            
                text = specialKeys[j][2]
                
            end
            
        end
        
        table.insert(bindingsTranslationData, {i, text})
        
    end
    
    local tableData = table.tostring(bindingsTranslationData)
    
    return bindingsTranslationData
    
end

/**
 * Called when bindings is exited and something was changed.
 */
function BindingsUI_ExitDialog()
    
    Client.ReloadKeyOptions()
    
end

local bindingsData = BindingsUI_GetBindingsTranslationData()
local a = 0
