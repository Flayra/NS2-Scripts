
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIScript.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// GUIScript is the base class for scripts created and managed by GUIManager.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIManager.lua")

class 'GUIScript'

function GUIScript:Initialize()

end

// This function should be overridden. Children should not call it.
function GUIScript:Uninitialize()

    Shared.Message("Warning: GUIScript:Uninitialize() called for " .. self._scriptName .. "! The child script should override this!")
    
end

function GUIScript:Update(deltaTime)

end

function GUIScript:SendKeyEvent(key, down)

    return false
    
end

function GUIScript:SendCharacterEvent(character)

    return false
    
end

function GUIScript:OnResolutionChanged(oldX, oldY, newX, newY)
end