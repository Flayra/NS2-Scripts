// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FuryMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * FuryMixin changes the attack speed of entities that are within it's effect.
 */
FuryMixin = { }
FuryMixin.type = "Fury"

FuryMixin.expectedMixins =
{
    GameEffects = "Needed for GetStackableGameEffectCount()."
}

function FuryMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "FuryMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        // Number of furys that are affecting this entity.
        furyLevel = string.format("integer (0 to %d)", kMaxStackLevel)
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function FuryMixin:__initmixin()
    self.furyLevel = 0
end

function FuryMixin:GetFuryLevel()
    return self.furyLevel
end
AddFunctionContract(FuryMixin.GetFuryLevel, { Arguments = { "Entity" }, Returns = { "number" } })

function FuryMixin:OnAdjustAttackDelay(delayTable)

    // Reduce delay between attacks by number of fury effects, but decreasing in effect.
    for i = 1, self.furyLevel do
        delayTable.Delay = delayTable.Delay * (1 - kFuryROFIncrease)
    end
    
end
AddFunctionContract(FuryMixin.OnAdjustAttackDelay, { Arguments = { "Entity", "table" }, Returns = { } })

function FuryMixin:OnUpdate(deltaTime)

    if Server then
        // Set fury level to be propagated to client so gameplay effects are predicted properly.
        self.furyLevel = self:GetStackableGameEffectCount(kFuryGameEffect)
    end
    
end
AddFunctionContract(FuryMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })