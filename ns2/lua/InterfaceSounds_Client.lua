// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InterfaceSounds_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/**
 * UI sounds to be triggered via FMOD, to let the sound designer tune the sounds 
 * without having to update Flash. Also means all our out-of-game .swfs use 
 * consistent sound effects. These could be used for in-game interfaces too
 * (like the Armory menu).
 */
 
 // Main menu sounds
local buttonClickSound = "sound/ns2.fev/common/button_click"
local checkboxOnSound = "sound/ns2.fev/common/checkbox_on"
local checkboxOffSound = "sound/ns2.fev/common/checkbox_off"
local buttonEnterSound = "sound/ns2.fev/common/button_enter"
local arrowSound = "sound/ns2.fev/common/arrow"

Client.PrecacheLocalSound(buttonClickSound)
Client.PrecacheLocalSound(checkboxOnSound)
Client.PrecacheLocalSound(checkboxOffSound)
Client.PrecacheLocalSound(buttonEnterSound)
Client.PrecacheLocalSound(arrowSound)

// For clicking menu buttons 
function PlayerUI_PlayButtonClickSound()
    MenuManager.PlaySound(buttonClickSound)
end

// Checkbox checked
function PlayerUI_PlayCheckboxOnSound()
    MenuManager.PlaySound(checkboxOnSound)
end

// Checkbox cleared
function PlayerUI_PlayCheckboxOffSound()
    MenuManager.PlaySound(checkboxOffSound)
end

// Arrow pressed
function PlayerUI_PlayArrowSound()
    MenuManager.PlaySound(arrowSound)
end

// Mouse enters a button (it could highlight)
function PlayerUI_PlayButtonEnterSound()
    MenuManager.PlaySound(buttonEnterSound)
end
