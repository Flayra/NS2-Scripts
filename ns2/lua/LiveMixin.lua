// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LiveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/BalanceHealth.lua")

LiveMixin = { }
LiveMixin.type = "Live"
// Whatever uses the LiveMixin needs to implement the following callback functions.
LiveMixin.expectedCallbacks = {
    GetCanTakeDamage = "Should return false if the object cannot take damage.",
    OnTakeDamage = "A callback to alert when the object has taken damage.",
    OnKill = "A callback to alert when the object has been killed." }

LiveMixin.kHealth = 100
LiveMixin.kArmor = 0

function LiveMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "LiveMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        alive       = "boolean",

        health      = "float",
        maxHealth   = "float",
        
        armor       = "float",
        maxArmor    = "float",
        
        timeOfLastDamage        = "float",
        lastDamageAttackerId    = "entityid",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function LiveMixin:__initmixin()

    self.alive = true
    
    self.health = LookupTechData(self:GetTechId(), kTechDataMaxHealth, self:GetMixinConstants().kHealth)
    ASSERT(self.health ~= nil)
    self.maxHealth = self.health

    self.armor = LookupTechData(self:GetTechId(), kTechDataMaxArmor, self:GetMixinConstants().kArmor)
    ASSERT(self.armor ~= nil)
    self.maxArmor = self.armor
    
    self.timeOfLastDamage = nil
    self.lastDamageAttackerId = -1
    
    self.overkillHealth = 0
    
end

// Returns text and 0-1 scalar for health bar on commander HUD when selected.
function LiveMixin:GetHealthDescription()

    local armorString = ""
    
    local armor = self:GetArmor()
    local maxArmor = self:GetMaxArmor()
    
    if armor and maxArmor and armor > 0 and maxArmor > 0 then
        armorString = string.format("  Armor %s/%s", ToString(math.ceil(armor)), ToString(maxArmor))
    end
    
    return string.format("Health  %s/%s%s", ToString(math.ceil(self:GetHealth())), ToString(math.ceil(self:GetMaxHealth())), armorString), self:GetHealthScalar()
    
end
AddFunctionContract(LiveMixin.GetHealthDescription, { Arguments = { "Entity" }, Returns = { "string", "number" } })

function LiveMixin:GetHealthScalar()

    local max = self:GetMaxHealth() + self:GetMaxArmor() * kHealthPointsPerArmor
    local current = self:GetHealth() + self:GetArmor() * kHealthPointsPerArmor
    
    if max == 0 then
        return 0
    end

    return current / max
    
end
AddFunctionContract(LiveMixin.GetHealthScalar, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:GetHealth()
    return self.health
end
AddFunctionContract(LiveMixin.GetHealth, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetHealth(health)
    self.health = math.min(self:GetMaxHealth(), health)
end
AddFunctionContract(LiveMixin.SetHealth, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:GetMaxHealth()
    return self.maxHealth
end
AddFunctionContract(LiveMixin.GetMaxHealth, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetMaxHealth(setMax)
    self.maxHealth = setMax
end
AddFunctionContract(LiveMixin.SetMaxHealth, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:GetArmorScalar()
    if self:GetMaxArmor() == 0 then
        return 0
    end
    return self:GetArmor() / self:GetMaxArmor()
end
AddFunctionContract(LiveMixin.GetArmorScalar, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:GetArmor()
    return self.armor
end
AddFunctionContract(LiveMixin.GetArmor, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetArmor(armor)
    self.armor = math.min(self:GetMaxArmor(), armor)
end
AddFunctionContract(LiveMixin.SetArmor, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:GetMaxArmor()
    return self.maxArmor
end
AddFunctionContract(LiveMixin.GetMaxArmor, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetMaxArmor(setMax)
    self.maxArmor = setMax
end
AddFunctionContract(LiveMixin.SetMaxArmor, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:SetOverkillHealth(health)
    self.overkillHealth = health
end
AddFunctionContract(LiveMixin.SetOverkillHealth, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:GetOverkillHealth()
    return self.overkillHealth
end
AddFunctionContract(LiveMixin.GetOverkillHealth, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:Heal(amount)

    local healed = false
    
    local newHealth = math.min( math.max(0, self.health + amount), self:GetMaxHealth() )
    if(self.alive and self.health ~= newHealth) then
    
        self.health = newHealth
        healed = true
        
    end    
    
    return healed
    
end
AddFunctionContract(LiveMixin.Heal, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

function LiveMixin:GetIsAlive()

    if (self.GetIsAliveOverride) then
        return self:GetIsAliveOverride()
    end
    return self.alive
    
end
AddFunctionContract(LiveMixin.GetIsAlive, { Arguments = { "Entity" }, Returns = { "boolean" } })

function LiveMixin:SetIsAlive(state)

    ASSERT(type(state) == "boolean")
    self.alive = state
    
end
AddFunctionContract(LiveMixin.SetIsAlive, { Arguments = { "Entity", "boolean" }, Returns = { } })

function LiveMixin:GetHealthPerArmor(damageType)

    local healthPerArmor = kHealthPointsPerArmor
    
    if damageType == kDamageType.Light then
        healthPerArmor = kHealthPointsPerArmorLight
    elseif damageType == kDamageType.Heavy then
        healthPerArmor = kHealthPointsPerArmorHeavy
    end
    
    if self.GetHealthPerArmorOverride then
        return self:GetHealthPerArmorOverride(damageType, healthPerArmor)
    end
    
    return healthPerArmor
    
end
AddFunctionContract(LiveMixin.GetHealthPerArmor, { Arguments = { "Entity", "number" }, Returns = { "number" } })

/**
 * Damage to marine armor could show sparks and debris and castings for aliens
 * Damage to health shows blood and the player makes grunting/squealing/pain noises
 * Armor is best at absorbing melee damage, less against projectiles and not effective for gas/breathing damage
 * (the TSA designed their armor to deal best against skulks!)
 */
function LiveMixin:GetArmorAbsorbPercentage(damageType)

    local armorAbsorbPercentage = kBaseArmorAbsorption
    
    if(damageType == kDamageType.Falling or damageType == kDamageType.Gas) then
    
        armorAbsorbPercentage = 0
        
    end
    
    if self.GetArmorAbsorbPercentageOverride then
        armorAbsorbPercentage = self:GetArmorAbsorbPercentageOverride(damageType, armorAbsorbPercentage)
    end
    
    return armorAbsorbPercentage
    
end
AddFunctionContract(LiveMixin.GetArmorAbsorbPercentage, { Arguments = { "Entity", "number" }, Returns = { "number" } })

function LiveMixin:ComputeDamageFromUpgrades(attacker, damage, damageType, time)

    if time == nil then
        time = Shared.GetTime()
    end
    
    // Give damage bonus if someone else hit us recently
    if attacker and attacker.GetHasUpgrade and attacker:GetHasUpgrade(kTechId.Swarm) then
    
        if self.timeOfLastDamage ~= nil and (time <= (self.timeOfLastDamage + kSwarmInterval)) then
        
            if attacker and attacker.GetId and (self.lastDamageAttackerId ~= attacker:GetId()) then
            
                damage = damage * kSwarmDamageBonus
                
                attacker:TriggerEffects("swarm")
                
            end
            
        end
        
    end
    
    return damage, damageType

end
AddFunctionContract(LiveMixin.ComputeDamageFromUpgrades, { Arguments = { "Entity", "Entity", "number", "number", { "number", "nil" } }, Returns = { "number", "number" } })

function LiveMixin:ComputeDamageFromType(damage, damageType, entity)

    // StructuresOnly damage
    if (damageType == kDamageType.StructuresOnly and not entity:isa("Structure") and not entity:isa("ARC")) then
    
        damage = 0
        
    // Extra damage to structures
    elseif damageType == kDamageType.Structural and (entity:isa("Structure") or entity:isa("ARC")) then
    
        damage = damage * kStructuralDamageScalar 

    elseif damageType ==  kDamageType.Puncture and entity:isa("Player") then
    
       damage = damage * kPuncturePlayerDamageScalar

    // Breathing targets only - not exosuits
    elseif damageType == kDamageType.Gas and (not entity:isa("Player") or entity:isa("Heavy")) then
    
        damage = 0

    elseif damageType == kDamageType.Biological then
    
        // Hurt non-mechanical players and alien structures only
        if ( (entity:isa("Player") and not entity:isa("Heavy")) or (entity:isa("Structure") and (entity:GetTeamType() == kAlienTeamType)) or entity:isa("ARC")) then

        else
            damage = 0
        end

    elseif damageType == kDamageType.Falling then
    
        if entity:isa("Skulk") then
            damage = 0
        end        
        
    end
    
    return damage
    
end

function LiveMixin:ComputeDamage(attacker, damage, damageType, time)

    // The host can provide an override for this function.
    if self.ComputeDamageOverride then
        damage, damageType = self:ComputeDamageOverride(attacker, damage, damageType, time)
    end
    
    local armorPointsUsed = 0
    local healthPointsUsed = 0    

    if damageType then
        damage = self:ComputeDamageFromType(damage, damageType, self)
    end

    if damage > 0 then
    
        // Compute extra damage from upgrades
        damage, damageType = self:ComputeDamageFromUpgrades(attacker, damage, damageType, time)
    
        // Calculate damage absorbed by armor according to damage type
        local absorbPercentage = self:GetArmorAbsorbPercentage(damageType)
        
        // Each point of armor blocks a point of health but is only destroyed at half that rate (like NS1)
        // Thanks Harimau!
        healthPointsBlocked = math.min(self:GetHealthPerArmor(damageType) * self.armor, absorbPercentage * damage)
        armorPointsUsed = healthPointsBlocked / self:GetHealthPerArmor(damageType)
        
        // Anything left over comes off of health
        healthPointsUsed = damage - healthPointsBlocked
    
    end
    
    return damage, armorPointsUsed, healthPointsUsed

end
AddFunctionContract(LiveMixin.ComputeDamage, { Arguments = { "Entity", "Entity", "number", "number", { "number", "nil" } }, Returns = { "number", "number", "number" } })

function LiveMixin:GetLastDamage()

    return self.timeOfLastDamage, self.lastDamageAttackerId

end
AddFunctionContract(LiveMixin.GetLastDamage, { Arguments = { "Entity" }, Returns = { { "number", "nil" }, "number" } })

function LiveMixin:SetLastDamage(time, attacker)

    if attacker and attacker.GetId then
        self.timeOfLastDamage = time
        self.lastDamageAttackerId = attacker:GetId()
    end
    
end
AddFunctionContract(LiveMixin.SetLastDamage, { Arguments = { "Entity", "number", { "Entity", "nil" } }, Returns = { } })

/**
 * Returns true if the damage has killed the entity.
 */
function LiveMixin:TakeDamage(damage, attacker, doer, point, direction)

    // Use AddHealth to give health.
    ASSERT(damage >= 0)
    
    local killed = false
    
    if self:GetCanTakeDamage() then
    
        if Client then
            killed = self:TakeDamageClient(damage, attacker, doer, point, direction)
        else
            killed = self:TakeDamageServer(damage, attacker, doer, point, direction)
        end
    end
    
    return killed
    
end
AddFunctionContract(LiveMixin.TakeDamage, { Arguments = { "Entity", "number", "Entity", "Entity", { "Vector", "nil" }, { "Vector", "nil" } }, Returns = { "boolean" } })

/**
 * Client version just calls OnTakeDamage() for pushing around ragdolls and such.
 */
function LiveMixin:TakeDamageClient(damage, attacker, doer, point, direction)
    
    if self:GetIsAlive() then
    
        self:OnTakeDamage(damage, attacker, doer, point)
        
    end
    
    // Client is not authoritative over death.
    return false
    
end
AddFunctionContract(LiveMixin.TakeDamageClient, { Arguments = { "Entity", "number", "Entity", "Entity", { "Vector", "nil" }, { "Vector", "nil" } }, Returns = { "boolean" } })

function LiveMixin:TakeDamageServer(damage, attacker, doer, point, direction)

    if (self:GetIsAlive() and GetGamerules():CanEntityDoDamageTo(attacker, self)) then

        // Get damage type from source    
        local damageType = kDamageType.Normal
        if doer ~= nil then 
            damageType = doer:GetDamageType()
        end

        // Take into account upgrades on attacker (armor1, weapons1, etc.)        
        damage = GetGamerules():GetUpgradedDamage(attacker, doer, damage, damageType)

        // highdamage cheat speeds things up for testing
        damage = damage * GetGamerules():GetDamageMultiplier()
        
        // Children can override to change damage according to player mode, damage type, etc.
        local armorUsed, healthUsed
        damage, armorUsed, healthUsed = self:ComputeDamage(attacker, damage, damageType)
        
        local oldHealth = self:GetHealth()
        
        self:SetArmor(self:GetArmor() - armorUsed)
        self:SetHealth(math.max(self:GetHealth() - healthUsed, 0))
        
        if self:GetHealth() == 0 then
            self:SetOverkillHealth(healthUsed - oldHealth)
        end
        
        if damage > 0 then
        
            self:OnTakeDamage(damage, attacker, doer, point)

            // Remember time we were last hurt for Swarm upgrade
            self:SetLastDamage(Shared.GetTime(), attacker)
            
            // Notify the doer they are giving out damage.
            local doerPlayer = doer
            if doer and doer:GetParent() and doer:GetParent():isa("Player") then
                doerPlayer = doer:GetParent()
            end
            if doerPlayer and doerPlayer:isa("Player") then
                // Not sent reliably as this notification is just an added bonus.
                // GetDeathIconIndex used to identify the attack type.
                Server.SendNetworkMessage(doerPlayer, "GiveDamageIndicator", BuildGiveDamageIndicatorMessage(damage, doer:GetDeathIconIndex(), self:isa("Player"), self:GetTeamNumber()), false)
            end
                
            if (oldHealth > 0 and self:GetHealth() == 0) then
            
                // Do this first to make sure death message is sent
                GetGamerules():OnKill(self, damage, attacker, doer, point, direction)
        
                self:OnKill(damage, attacker, doer, point, direction)
                
                self:ProcessFrenzy(attacker, self)

                self.justKilled = true
                
            end
            
        end
        
    end
    
    return (self.justKilled == true)
    
end
AddFunctionContract(LiveMixin.TakeDamageServer, { Arguments = { "Entity", "number", "Entity", "Entity", { "Vector", "nil" }, { "Vector", "nil" } }, Returns = { "boolean" } })

//
// How damaged this entity is, ie how much healing it can receive.
//
function LiveMixin:AmountDamaged() 
    return (self:GetMaxHealth() - self:GetHealth()) + (self:GetMaxArmor() - self:GetArmor())
end
AddFunctionContract(LiveMixin.AmountDamaged, { Arguments = { "Entity" }, Returns = { "number" } })

// Return the amount of health we added 
function LiveMixin:AddHealth(health, playSound, noArmor)

    // TakeDamage should be used for negative values.
    ASSERT( health >= 0 )

    local total = 0
    
    if self:GetIsAlive() and self:AmountDamaged() > 0 then
    
        // Add health first, then armor if we're full
        local healthAdded = math.min(health, self:GetMaxHealth() - self:GetHealth())
        self:SetHealth(math.min(math.max(0, self:GetHealth() + healthAdded), self:GetMaxHealth()))

        local healthToAddToArmor = 0
        if not noArmor then
        
            healthToAddToArmor = health - healthAdded
            if(healthToAddToArmor > 0) then
                local armorMultiplier = self:GetHealthPerArmor(kDamageType.Normal)
                local armorPoints = healthToAddToArmor / armorMultiplier            
                self:SetArmor(math.min(math.max(0, self:GetArmor() + armorPoints), self:GetMaxArmor()))
            end
            
        end
        
        total = healthAdded + healthToAddToArmor
        
        if total > 0 and playSound and (self:GetTeamType() == kAlienTeamType) then
            self:TriggerEffects("regenerate")
        end
        
    end
    
    return total
    
end
AddFunctionContract(LiveMixin.AddHealth, { Arguments = { "Entity", "number", "boolean" }, Returns = { "number" } })

function LiveMixin:ProcessFrenzy(attacker, targetEntity)

    // Process Frenzy - give health back according to the amount of extra damage we did
    if attacker and attacker.GetHasUpgrade and attacker:GetHasUpgrade(kTechId.Frenzy) and targetEntity and targetEntity.GetOverkillHealth then
    
        attacker:TriggerEffects("frenzy")
        
        local overkillHealth = targetEntity:GetOverkillHealth()        
        local healthToGiveBack = math.max(overkillHealth, kFrenzyMinHealth)
        attacker:AddHealth(healthToGiveBack, false)
        
    end
    
end
AddFunctionContract(LiveMixin.ProcessFrenzy, { Arguments = { "Entity", "Entity", "Entity" }, Returns = { } })