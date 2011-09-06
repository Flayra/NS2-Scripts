// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EnergyMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

EnergyMixin = { }
EnergyMixin.type = "Energy"
EnergyMixin.kMaxEnergy = 300

EnergyMixin.expectedCallbacks = {
    GetTechId = "Should return the tech id of the object." }

function EnergyMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "EnergyMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        // Used for limiting frequency of abilities
        energy                  = "float",
        maxEnergy               = string.format("integer (0 to %s)", EnergyMixin.kMaxEnergy),
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function EnergyMixin:__initmixin()

    self.energy = LookupTechData(self:GetTechId(), kTechDataInitialEnergy, 0)
    self.maxEnergy = LookupTechData(self:GetTechId(), kTechDataMaxEnergy, EnergyMixin.kMaxEnergy)
    
end

function EnergyMixin:GetEnergy()
    return self.energy
end
AddFunctionContract(EnergyMixin.GetEnergy, { Arguments = { "Entity" }, Returns = { "number" } })

function EnergyMixin:SetEnergy(newEnergy)
    self.energy = math.max(math.min(newEnergy, self:GetMaxEnergy()), 0)
end
AddFunctionContract(EnergyMixin.SetEnergy, { Arguments = { "Entity", "number" }, Returns = { } })

function EnergyMixin:AddEnergy(amount)

    self.energy = self.energy + amount
    self.energy = math.max(math.min(self.energy, self.maxEnergy), 0)
    
end
AddFunctionContract(EnergyMixin.AddEnergy, { Arguments = { "Entity", "number" }, Returns = { } })

function EnergyMixin:GetMaxEnergy()
    return self.maxEnergy
end
AddFunctionContract(EnergyMixin.GetMaxEnergy, { Arguments = { "Entity" }, Returns = { "number" } })

function EnergyMixin:UpdateEnergy(timePassed)

    assert(Server)
    
    local scalar = ConditionalValue(self:GetGameEffectMask(kGameEffect.OnFire), kOnFireEnergyRecuperationScalar, 1)

    // Increase energy for entities that are affected by energize (not PowerPoints)
    local count = 0
    if self.GetStackableGameEffectCount then
        count = self:GetStackableGameEffectCount(kEnergizeGameEffect)
    end
    
    local energyRate = (kEnergyUpdateRate * scalar) + kEnergyUpdateRate * count * kEnergizeEnergyIncrease
    
    if(timePassed > 0 and self.maxEnergy ~= nil and self.maxEnergy > 0) then
        self.energy = math.min(self.energy + timePassed * energyRate, self.maxEnergy)
    end
    
end
AddFunctionContract(EnergyMixin.UpdateEnergy, { Arguments = { "Entity", "number" }, Returns = { } })