// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\UpgradableMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * UpgradableMixin handles two forms of upgrades. There are the upgrades that it owns (upgrade1 - upgrade4).
 * It can also handle upgrading the entire entity to another tech Id independent of the upgrades it owns.
 */
UpgradableMixin = { }
UpgradableMixin.type = "Upgradable"

UpgradableMixin.expectedCallbacks =
{
    SetTechId = "Sets the current tech Id of this entity.",
    GetTechId = "Returns the current tech Id of this entity."
}

UpgradableMixin.optionalCallbacks =
{
    OnPreUpgradeToTechId = "Called right before upgrading to a new tech Id.",
    OnGiveUpgrade = "Called to notify that an upgrade was given with the tech Id as the single parameter."
}

function UpgradableMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "UpgradableMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        upgrade1 = "enum kTechId",
        upgrade2 = "enum kTechId",
        upgrade3 = "enum kTechId",
        upgrade4 = "enum kTechId",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function UpgradableMixin:__initmixin()

    self.upgrade1 = kTechId.None
    self.upgrade2 = kTechId.None
    self.upgrade3 = kTechId.None
    self.upgrade4 = kTechId.None
    
end

function UpgradableMixin:UpgradeToTechId(newTechId)

    if self:GetTechId() ~= newTechId then
    
        if self.OnPreUpgradeToTechId then
            self:OnPreUpgradeToTechId(newTechId)
        end

        local healthScalar = 0
        local armorScalar = 0
        local isAlive = HasMixin(self, "Live")
        if isAlive then
            // Preserve health and armor scalars but potentially change maxHealth and maxArmor.
            healthScalar = self:GetHealthScalar()
            armorScalar = self:GetArmorScalar()
        end
        
        self:SetTechId(newTechId)
        
        if isAlive then
        
            self:SetMaxHealth(LookupTechData(newTechId, kTechDataMaxHealth, self:GetMaxHealth()))
            self:SetMaxArmor(LookupTechData(newTechId, kTechDataMaxArmor, self:GetMaxArmor()))
            
            self:SetHealth(healthScalar * self:GetMaxHealth())
            self:SetArmor(armorScalar * self:GetMaxArmor())
            
        end
        
        return true
        
    end
    
    return false
    
end
AddFunctionContract(UpgradableMixin.UpgradeToTechId, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

function UpgradableMixin:GetHasUpgrade(techId) 
    return techId ~= kTechId.None and (techId == self.upgrade1 or techId == self.upgrade2 or techId == self.upgrade3 or techId == self.upgrade4)
end
AddFunctionContract(UpgradableMixin.GetHasUpgrade, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

function UpgradableMixin:GetUpgrades()

    local upgrades = { }
    
    if self.upgrade1 ~= kTechId.None then
        table.insert(upgrades, self.upgrade1)
    end
    if self.upgrade2 ~= kTechId.None then
        table.insert(upgrades, self.upgrade2)
    end
    if self.upgrade3 ~= kTechId.None then
        table.insert(upgrades, self.upgrade3)
    end
    if self.upgrade4 ~= kTechId.None then
        table.insert(upgrades, self.upgrade4)
    end
    
    return upgrades
    
end
AddFunctionContract(UpgradableMixin.GetUpgrades, { Arguments = { "Entity" }, Returns = { "table" } })

function UpgradableMixin:GiveUpgrade(techId) 

    local upgradeGiven = false
    
    if not self:GetHasUpgrade(techId) then

        if self.upgrade1 == kTechId.None then
        
            self.upgrade1 = techId
            upgradeGiven = true
            
        elseif self.upgrade2 == kTechId.None then
        
            self.upgrade2 = techId
            upgradeGiven = true

        elseif self.upgrade3 == kTechId.None then
        
            self.upgrade3 = techId
            upgradeGiven = true
            
        elseif self.upgrade4 == kTechId.None then
        
            self.upgrade4 = techId
            upgradeGiven = true
            
        end
        
        assert(upgradeGiven, "Entity already has the max of four upgrades.")
        
    else
        error("Entity already has upgrade.")
    end
    
    if upgradeGiven and self.OnGiveUpgrade then
        self:OnGiveUpgrade(techId)
    end
    
    return upgradeGiven
    
end
AddFunctionContract(UpgradableMixin.GiveUpgrade, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

function UpgradableMixin:Reset()
    self:_ClearUpgrades()
end
AddFunctionContract(UpgradableMixin.Reset, { Arguments = { "Entity" }, Returns = { } })

function UpgradableMixin:OnKill()
    self:_ClearUpgrades()
end
AddFunctionContract(UpgradableMixin.OnKill, { Arguments = { "Entity" }, Returns = { } })

function UpgradableMixin:_ClearUpgrades()

    self.upgrade1 = kTechId.None
    self.upgrade2 = kTechId.None
    self.upgrade3 = kTechId.None
    self.upgrade4 = kTechId.None
    
end
AddFunctionContract(UpgradableMixin._ClearUpgrades, { Arguments = { "Entity" }, Returns = { } })