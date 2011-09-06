// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FlinchMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

FlinchMixin = { }
FlinchMixin.type = "Flinch"

FlinchMixin.expectedCallbacks =
{
    TriggerEffects = "The flinch effect will be triggered through this callback.",
    GetMaxHealth = "Returns the maximum amount of health this entity can have.",
    StopOverlayAnimation = "Stop the overlay animation currently playing with the passed in name.",
    SetPoseParam = "Set the named pose parameter to the passed in value."
}

FlinchMixin.kAnimFlinch = "flinch"

// Takes this much time to reduce flinch completely.
FlinchMixin.kFlinchIntensityReduceRate = .4

function FlinchMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "FlinchMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        // 0 to 1 value indicating how much pain we're in.
        flinchIntensity = "float"
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function FlinchMixin:__initmixin()

    self.flinchIntensity = 0
    
end

function FlinchMixin:OnTakeDamage(damage, attacker, doer, point)

    local damageType = kDamageType.Normal
    if doer then
        damageType = doer:GetDamageType()
    end
    
    // Don't flinch too often.
    local time = Shared.GetTime()
    if self.lastFlinchEffectTime == nil or (time > (self.lastFlinchEffectTime + 1)) then
    
        local flinchParams = { damagetype = damageType, flinch_severe = ConditionalValue(damage > 20, true, false) }
        if point then
            flinchParams[kEffectHostCoords] = Coords.GetTranslation(point)
        end
        
        if doer then
            flinchParams[kEffectFilterDoerName] = doer:GetClassName()
        end
        
        self:TriggerEffects("flinch", flinchParams)
        self.lastFlinchEffectTime = time
        
    end

    // Once entity has taken this much damage in a second, it is flinching at it's maximum amount
    local maxFlinchDamage = self:GetMaxHealth() * .20
    
    local flinchAmount = damage / maxFlinchDamage
    self.flinchIntensity = Clamp(self.flinchIntensity + flinchAmount, .25, 1)

    // Make sure new flinch intensity is big enough to be visible, but don't add too much from a bunch of small hits
    // Flamethrower make Harvester go wild   
    if doer and (doer:GetDamageType() == kDamageType.Flame) then
        self.flinchIntensity = self.flinchIntensity + .1
    end
    
end
AddFunctionContract(FlinchMixin.OnTakeDamage, { Arguments = { "Entity", "number", "Entity", { "Entity", "nil" }, "Vector" }, Returns = { } })

function FlinchMixin:OnUpdate(deltaTime)

    self.flinchIntensity = Clamp(self.flinchIntensity - deltaTime * FlinchMixin.kFlinchIntensityReduceRate, 0, 1)
    
    // Stop overlaying basic looping flinch animation when not needed
    if self.flinchIntensity == 0 then
        self:StopOverlayAnimation(FlinchMixin.kAnimFlinch)
    end
    
    self:_UpdateFlinchPoseParams()

end
AddFunctionContract(FlinchMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function FlinchMixin:OnSynchronized()
    PROFILE("FlinchMixin:OnSynchronized")
    self:_UpdateFlinchPoseParams()
end
AddFunctionContract(FlinchMixin.OnSynchronized, { Arguments = { "Entity" }, Returns = { } })

function FlinchMixin:_UpdateFlinchPoseParams()
    self:SetPoseParam("intensity", self.flinchIntensity)
end
AddFunctionContract(FlinchMixin._UpdateFlinchPoseParams, { Arguments = { "Entity" }, Returns = { } })