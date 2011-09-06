// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FrenzyMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * FrenzyMixin awards a player health based on how much damage they do beyond killing another entity.
 */
FrenzyMixin = { }
FrenzyMixin.type = "Frenzy"

FrenzyMixin.expectedMixins =
{
    Live = "Needed for GetOverkillHealth()."
}

function FrenzyMixin:__initmixin()
end

function FrenzyMixin:OnKill(damage, attacker, doer, point, direction)

    if attacker then
    
        local needsHealth = HasMixin(attacker, "Live") and attacker:GetHealthScalar() < 1
        local hasFrenzy = HasMixin(attacker, "Upgradable") and attacker:GetHasUpgrade(kTechId.Frenzy)
        
        if needsHealth and hasFrenzy then
            
            attacker:TriggerEffects("frenzy")
            
            // Give health back to the attacker according to the amount of extra damage the attacker did to this Entity.
            local overkillHealth = self:GetOverkillHealth()
            local healthToGiveBack = math.max(overkillHealth, kFrenzyMinHealth)
            attacker:AddHealth(healthToGiveBack, false)
            
        end
        
    end
    
end
AddFunctionContract(FrenzyMixin.OnKill, { Arguments = { "Entity", "number", "Entity", { "Entity", "nil" }, "Vector", "Vector" }, Returns = { } })