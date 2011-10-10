// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EvolveMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Entity.lua")

EvolveMixin = { }
EvolveMixin.type = "Evolve"

EvolveMixin.kThinkTime = .1
EvolveMixin.kBaseHealth = 50

function EvolveMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "EvolveMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        evolvePercentage = "float",
        gestationTypeTechId = "enum kTechId",
        hasEvolved          = "boolean",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function EvolveMixin:__initmixin()
    self.evolvePercentage = 0    
    self.evolveTime = 0    
    self.gestationTime = 0
    self.hasEvolved = false
    
    self.gestationTypeTechId = kTechId.Skulk
end


function EvolveMixin:SetGestationData(techIds, previousTechId, healthScalar, armorScalar)

    // Save upgrades so they can be given when spawned
    self.evolvingUpgrades = {}
    table.copy(techIds, self.evolvingUpgrades)

    self.gestationClass = nil
    
    for i, techId in ipairs(techIds) do
        self.gestationClass = LookupTechData(techId, kTechDataGestateName)
        if self.gestationClass then 
            // Remove gestation tech id from "upgrades"
            self.gestationTypeTechId = techId
            table.removevalue(self.evolvingUpgrades, self.gestationTypeTechId)
            break 
        end
    end
    
    // Upgrades don't have a gestate name, we want to gestate back into the
    // current alien type, previousTechId.
    if not self.gestationClass then
        self.gestationTypeTechId = previousTechId
        self.gestationClass = LookupTechData(previousTechId, kTechDataGestateName)
    end
    self.gestationStartTime = Shared.GetTime()
    
    local lifeformTime = ConditionalValue(self.gestationTypeTechId ~= previousTechId, LookupTechData(self.gestationTypeTechId, kTechDataGestateTime), 0)
    self.gestationTime = ConditionalValue(Shared.GetCheatsEnabled(), 2, lifeformTime + table.count(self.evolvingUpgrades) * kUpgradeGestationTime)
    self.evolveTime = 0
    
    self:SetHealth(EvolveMixin.kBaseHealth)
    self:SetMaxHealth(LookupTechData(self.gestationTypeTechId, kTechDataMaxHealth))
     
    // Use this amount of health when we're done evolving
    self.healthScalar = healthScalar
    self.armorScalar = armorScalar
    
    if self.OverrideGestationData then
        self:OverrideGestationData()
    end
end

function EvolveMixin:GetEvolutionTime()
    return self.evolveTime
end

function EvolveMixin:IsEvolving()
    return (self.evolvePercentage ~= 100 or self.evolvePercentage ~= 0)
end

function EvolveMixin:HasEvolved()
    return self.hasEvolved
end

if Server then

    function EvolveMixin:OnThink()        
        // Cannot spawn unless alive.
        if self:GetIsAlive() and self.gestationClass ~= nil then
        
            // Take into account metabolize effects
            local amount = GetAlienEvolveResearchTime(EvolveMixin.kThinkTime, self)
            self.evolveTime = self.evolveTime + amount

            self.evolvePercentage = Clamp((self.evolveTime / self.gestationTime) * 100, 0, 100)
            
            if self.evolveTime >= self.gestationTime then               
                self.hasEvolved = true
            end                                 
        end

        if (self:isa("Egg")) then
            self:SetNextThink(EvolveMixin.kThinkTime)
        end    
    end
    
    function EvolveMixin:GetGestationClass()
        return self.gestationClass
    end            
end
