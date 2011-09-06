// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\GameEffectsMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * GameEffectsMixin keeps track of anything that has an effect on an entity and
 * provides methods to query these effects.
 */
GameEffectsMixin = { }
GameEffectsMixin.type = "GameEffects"

GameEffectsMixin.optionalCallbacks =
{
    OnGameEffectMaskChanged = "Called when a game effect is turned on or off.",
    OnAdjustAttackDelay = "Called with a table with a single time Delay field which should adjust the attack delay."
}

function GameEffectsMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "GameEffectsMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        // kGameEffectMax comes from Globals file.
        gameEffectsFlags = "integer (0 to " .. kGameEffectMax .. ")",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function GameEffectsMixin:__initmixin()

    // Flags to indicate if we're under effect of anything (but doesn't include count).
    self.gameEffectsFlags = 0
    
    if Server then
        // List of strings indicating stackable game effects.
        self.gameEffects = { }
    end
    
end

function GameEffectsMixin:OnUpdate(deltaTime)

    // Update expiring stackable game effects.
    if Server then
        self:_ExpireStackableGameEffects(deltaTime)
    end
    
end
AddFunctionContract(GameEffectsMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function GameEffectsMixin:GetGameEffectMask(effect)
    return bit.band(self.gameEffectsFlags, effect) ~= 0
end
AddFunctionContract(GameEffectsMixin.GetGameEffectMask, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

// Sets or clears a game effect flag
function GameEffectsMixin:SetGameEffectMask(effect, state)

    local startGameEffectsFlags = self.gameEffectsFlags
    
    if state then
    
        // Set game effect bit
        if self.OnGameEffectMaskChanged and not self:GetGameEffectMask(effect) then
            self:OnGameEffectMaskChanged(effect, true)
        end
        
        self.gameEffectsFlags = bit.bor(self.gameEffectsFlags, effect)
        
    else
    
        // Clear game effect bit
        if self.OnGameEffectMaskChanged and self:GetGameEffectMask(effect) then
            self:OnGameEffectMaskChanged(effect, false)
        end

        local notEffect = bit.bnot(effect)
        self.gameEffectsFlags = bit.band(self.gameEffectsFlags, notEffect)
        
    end
    
    // Return if state changed
    return startGameEffectsFlags ~= self.gameEffectsFlags
    
end
AddFunctionContract(GameEffectsMixin.SetGameEffectMask, { Arguments = { "Entity", "number", "boolean" }, Returns = { "boolean" } })

function GameEffectsMixin:ClearGameEffects()

    if self.OnGameEffectMaskChanged then
    
        if self.gameEffectsFlags then
        
            for i, effect in pairs(kGameEffect) do 

                if bit.band(self.gameEffectsFlags, effect) ~= 0 then
                    self:OnGameEffectMaskChanged(effect, false)
                end
                
            end
            
        end
        
    end
    
    self.gameEffectsFlags = 0
    
end
AddFunctionContract(GameEffectsMixin.ClearGameEffects, { Arguments = { "Entity" }, Returns = { } })

function GameEffectsMixin:OnKill()

    self:ClearGameEffects()

end
AddFunctionContract(GameEffectsMixin.OnKill, { Arguments = { "Entity" }, Returns = { } })

/**
 * Adds a stackable game effect (up to kMaxStackLevel max). Don't add one if we already have
 * this effect from this source entity.
 */
function GameEffectsMixin:AddStackableGameEffect(gameEffectName, duration, sourceEntity)

    assert(Server)

    if table.count(self.gameEffects) < kMaxStackLevel then
    
        local sourceEntityId = Entity.invalidId
        
        // Insert stackable game effect if we don't already have one from this entity
        if sourceEntity then
        
            sourceEntityId = sourceEntity:GetId()
            
            for index, elementTriple in ipairs(self.gameEffects) do
            
                if elementTriple[3] == sourceEntityId then
                    return
                end
                
            end

       end
       
       // Otherwise insert new triple (game effect, duration, id).
       table.insert(self.gameEffects, { gameEffectName, duration, sourceEntityId })
        
    end
    
end
AddFunctionContract(GameEffectsMixin.AddStackableGameEffect, { Arguments = { "Entity", "string", { "number", "nil" }, "Entity" }, Returns = { } })

function GameEffectsMixin:ClearStackableGameEffects()

    assert(Server)
    table.clear(self.gameEffects)
    
end
AddFunctionContract(GameEffectsMixin.ClearStackableGameEffects, { Arguments = { "Entity" }, Returns = { } })

function GameEffectsMixin:GetStackableGameEffectCount(gameEffectName)

    assert(Server)
    
    local count = 0
    
    for index, elementTriple in ipairs(self.gameEffects) do
    
        local effectName = elementTriple[1]
        if effectName == gameEffectName then
        
            count = count + 1
            
        end
        
    end

    return count
    
end
AddFunctionContract(GameEffectsMixin.GetStackableGameEffectCount, { Arguments = { "Entity", "string" }, Returns = { "number" } })

function GameEffectsMixin:_ExpireStackableGameEffects(deltaTime)

    assert(Server)

    function effectExpired(elemTriple) 
    
        // nil expire times last forever.
        local duration = elemTriple[2]
        if not duration then
            return false
        end
        
        duration = duration - deltaTime
        if duration <= 0 then
            return true
        end
        
        elemTriple[2] = duration
        return false
        
    end
    
    table.removeConditional(self.gameEffects, effectExpired)
    
end
AddFunctionContract(GameEffectsMixin._ExpireStackableGameEffects, { Arguments = { "Entity", "number" }, Returns = { } })

// Any game effect Mixin attached to this Entity can hook into these functions and
// adjust the passed in parameters and/or react in other ways.

/**
 * The attack delay is used to adjust how quickly an Entity can attack after a previous attack.
 */
function GameEffectsMixin:AdjustAttackDelay(attackDelay)

    if self.OnAdjustAttackDelay then
    
        local attackDelayTable = { Delay = attackDelay }
        self:OnAdjustAttackDelay(attackDelayTable)
        return attackDelayTable.Delay
        
    end
    
    return attackDelay

end