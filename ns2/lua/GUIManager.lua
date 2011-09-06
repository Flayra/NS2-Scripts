// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIManager.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages animation and other state of GUIItems in the GUISystem.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kGUILayerDebugText = 0
kGUILayerPlayerHUDBackground = 1
kGUILayerPlayerHUD = 2
kGUILayerPlayerHUDForeground1 = 3
kGUILayerPlayerHUDForeground2 = 4
kGUILayerPlayerHUDForeground3 = 5
kGUILayerPlayerHUDForeground4 = 6
kGUILayerCommanderAlerts = 7
kGUILayerCommanderHUD = 8
kGUILayerLocationText = 9
kGUILayerMinimap = 10

Script.Load("lua/GUIScript.lua")
Script.Load("lua/GUIUtility.lua")

class 'GUIManager'

// Animation flags
kAnimFlagSin = 0x00000001   // Animates time with sin instead of linearly (starts fast, eases in slow)
kAnimFlagCos = 0x00000002   // Animates time with cos instead of linearly (starts slow, ends fast)

// Animation stats.
kAnimStarted = 1
kAnimWaiting = 2

// TODO: Add time delay

function GUIManager:Initialize()

    self.scripts = { }
    self.scriptsSingle = { }
    self.animations = { }
    
    self.animationId = 1

end

function GUIManager:GetNumberScripts()

    return table.count(self.scripts) + table.count(self.scriptsSingle)

end

// Do not call from public interface.
function GUIManager:_SharedCreate(scriptName)

    Script.Load("lua/" .. scriptName .. ".lua")
    
    local creationFunction = _G[scriptName]
    if creationFunction == nil then
        Shared.Message("Error: Failed to load GUI script named " .. scriptName)
        return nil
    else
        local newScript = creationFunction()
        newScript._scriptName = scriptName
        newScript:Initialize()
        return newScript
    end
    
end

function GUIManager:CreateGUIScript(scriptName)

    local createdScript = self:_SharedCreate(scriptName)
    if createdScript ~= nil then
        table.insert(self.scripts, createdScript)
    end
    return createdScript

end

// Only ever create one of this named script.
// Just return the already created one if it already exists.
function GUIManager:CreateGUIScriptSingle(scriptName)
    
    // Check if it already exists
    for index, script in ipairs(self.scriptsSingle) do
        if script[2] == scriptName then
            return script[1]
        end
    end
    
    // Not found, create the single instance.
    local createdScript = self:_SharedCreate(scriptName)
    if createdScript ~= nil then
        table.insert(self.scriptsSingle, { createdScript, scriptName })
        return createdScript
    end
    return nil
    
end

function GUIManager:DestroyGUIScript(scriptInstance)

    // Only uninitialize it if the manager has a reference to it.
    local success = false
    if table.removevalue(self.scripts, scriptInstance) then
        scriptInstance:Uninitialize()
        success = true
    end
    return success

end

// Destroy a previously created single named script.
// Nothing will happen if it hasn't been created yet.
function GUIManager:DestroyGUIScriptSingle(scriptName)

    for index, script in ipairs(self.scriptsSingle) do
        if script[2] == scriptName then
            if table.removevalue(self.scriptsSingle, script) then
                script[1]:Uninitialize()
                break
            end
        end
    end
    
end

function GUIManager:GetGUIScriptSingle(scriptName)

    for index, script in ipairs(self.scriptsSingle) do
        if script[2] == scriptName then
            return script[1]
        end
    end
    return nil

end

function GUIManager:NotifyGUIItemDestroyed(destroyedItem)

    // Remove all animations that reference the destroyed item.
    for i = table.count(self.animations), 1, -1 do
        if self.animations[i].Item == destroyedItem then
            table.remove(self.animations, i)
        end
    end

end

// Should not be called by anything but GUIManager.
function GUIManager:_InternalCreateAnimation(state, animatingItem, operation, startValue, endValue, animationTime, flags)

    ASSERT(animatingItem ~= nil)
    ASSERT(operation ~= nil and type(operation) == "function")
    ASSERT(type(startValue) ~= "nil")
    ASSERT(type(endValue) ~= "nil")
    ASSERT(type(animationTime) == "number" and animationTime >= 0)
    
    local newAnimation = { Item = animatingItem, Operation = operation,
                           StartValue = startValue, EndValue = endValue,
                           AnimationTime = animationTime, Time = 0, Flags = flags,
                           Id = self.animationId, Chained = { }, State = state }
    table.insert(self.animations, newAnimation)
    self.animationId = self.animationId + 1
    
    return newAnimation.Id

end

function GUIManager:_InternalGetAnimation(byId)

    for index, animation in ipairs(self.animations) do
        if animation.Id == byId then
            return animation
        end
    end
    return nil

end

// Operation should be a function that takes a GUIItem and a value to set.
function GUIManager:StartAnimation(animatingItem, operation, startValue, endValue, animationTime, flags)

    return self:_InternalCreateAnimation(kAnimStarted, animatingItem, operation, startValue, endValue, animationTime, flags)

end

// The chain animation will start after the passed in offOfAnimationId is atTime or finishes completely.
function GUIManager:ChainAnimation(offOfAnimationId, atTime, animatingItem, operation, startValue, endValue, animationTime, flags)

    local offOfAnimation = self:_InternalGetAnimation(offOfAnimationId)
    if offOfAnimation then
        local chainedAnimationId = self:_InternalCreateAnimation(kAnimWaiting, animatingItem, operation, startValue, endValue, animationTime, flags)
        table.insert(offOfAnimation.Chained, { AtTime = atTime, Id = chainedAnimationId })
        return chainedAnimationId
    end
    return nil

end

function GUIManager:GetIsAnimating(animatingItem)

    for index, animation in ipairs(self.animations) do
        if animation.Item == animatingItem and animation.State == kAnimStarted then
            return true
        end
    end
    
    return false
    
end

function GUIManager:Update(deltaTime)

    PROFILE("GUIManager:Update")

    self:UpdateAnimations(deltaTime)
    
    for index, script in ipairs(self.scripts) do
        script:Update(deltaTime)
    end
    for index, script in ipairs(self.scriptsSingle) do
        script[1]:Update(deltaTime)
    end
    
end

function GUIManager:UpdateAnimations(deltaTime)

    local removeAnimations = { }
    for i, animation in ipairs(self.animations) do
    
        // Only update started animations.
        if animation.State == kAnimStarted then
        
            // Ensure the time never goes past the final animation time.
            animation.Time = math.min(animation.Time + deltaTime, animation.AnimationTime)
            
            // Lerp values generically (handles tables, numbers, Vectors, etc.)
            local timePercent = animation.Time / animation.AnimationTime
            
            if animation.Flags and bit.band(animation.Flags, kAnimFlagSin) then
                timePercent = math.sin(timePercent * math.pi/2)
            end
            
            local lerpedValue = LerpGeneric(animation.StartValue, animation.EndValue, timePercent)
            
            animation.Operation(animation.Item, lerpedValue)
            if animation.Time >= animation.AnimationTime then
                table.insert(removeAnimations, animation)
            end
            
            // Check if any chained animations should start.
            self:_CheckChainedAnimations(animation)
            
        end
    
    end
    
    for i, removeAnimation in ipairs(removeAnimations) do
        table.removevalue(self.animations, removeAnimation)
    end

end

function GUIManager:_CheckChainedAnimations(animation)

    local removeChainedAnimations = { }
    for i, chainedAnimation in ipairs(animation.Chained) do
        // Check if it is time for this chained animation to begin (or if
        // the base animation is done).
        if chainedAnimation.AtTime <= animation.Time or animation.Time >= animation.AnimationTime then
            table.insert(removeChainedAnimations, chainedAnimation)
            local chainedAnimation = self:_InternalGetAnimation(chainedAnimation.Id)
            if chainedAnimation then
                chainedAnimation.State = kAnimStarted
            end
        end
    end
    
    for i, removeAnimation in ipairs(removeChainedAnimations) do
        table.removevalue(animation.Chained, removeAnimation)
    end

end

function GUIManager:SendKeyEvent(key, down)

    for index, script in ipairs(self.scripts) do
        if script:SendKeyEvent(key, down) then
            return true
        end
    end
    for index, script in ipairs(self.scriptsSingle) do
        if script[1]:SendKeyEvent(key, down) then
            return true
        end
    end
    return false
    
end

function GUIManager:SendCharacterEvent(character)

    for index, script in ipairs(self.scripts) do
        if script:SendCharacterEvent(character) then
            return true
        end
    end
    for index, script in ipairs(self.scriptsSingle) do
        if script[1]:SendCharacterEvent(character) then
            return true
        end
    end
    return false
    
end

function GUIManager:OnResolutionChanged(oldX, oldY, newX, newY)

    for index, script in ipairs(self.scripts) do
        script:OnResolutionChanged(oldX, oldY, newX, newY)
    end
    for index, script in ipairs(self.scriptsSingle) do
        script[1]:OnResolutionChanged(oldX, oldY, newX, newY)
    end

end

function GUIManager:CreateGraphicItem()
    return GUI.CreateItem()
end

function GUIManager:CreateTextItem()

    local item = GUI.CreateItem()

    // Text items always manage their own rendering.
    item:SetOptionFlag(GUIItem.ManageRender)

    return item

end 

function GUIManager:CreateLinesItem()

    local item = GUI.CreateItem()

    // Lines items always manage their own rendering.
    item:SetOptionFlag(GUIItem.ManageRender)

    return item
    
end