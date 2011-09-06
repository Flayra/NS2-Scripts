// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPoint_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Power node that powers nearby marines structures. Starts with full health and built, then if
// it takes too much damage it is "killed". It is still there and still built, but needs to be
// repaired before it becomes powered again.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

function PowerPoint:OnKill(damage, attacker, doer, point, direction)

    // Don't destroy it, just require it to be built again
    if self.powered then
    
        self:SetAnimation(PowerPoint.kAnimOff)
        
        self:SetModel(PowerPoint.kOffModelName)
        
        self:StopDamagedSound()
        
        self.powered = false
        
        self:SetLightMode(kLightMode.NoPower)
        
        self:UpdatePoweredStructures()
        
        // Remove effects such as parasite when destroyed.
        self:ClearGameEffects()
        
        if attacker and attacker:isa("Player") and GetEnemyTeamNumber(self:GetTeamNumber()) == attacker:GetTeamNumber() then
            attacker:AddScore(self:GetPointValue())
        end
        
        // A few seconds later, switch on aux. power
        self:SetNextThink(4)
        
    end
    
end

function PowerPoint:OnLoad()

    Structure.OnLoad(self)
    
    self:SetNextThink(.1)
    
end

function PowerPoint:OnThink()

    if self.powered then
        // Update after load finishes to make sure pre-placed structures are present
        self:UpdatePoweredStructures()
    else
        self:PlaySound(PowerPoint.kAuxPowerBackupSound)
    end    
end

function PowerPoint:Reset()

    Structure.Reset(self)
    
    self:StopSound(PowerPoint.kAuxPowerBackupSound)
    
    self:SetLightMode(kLightMode.Normal)

end

function PowerPoint:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetAnimation(PowerPoint.kAnimOn)
    
    self:SetModel(PowerPoint.kOnModelName)
    
    self:StopDamagedSound()
    
    self.health = PowerPoint.kHealth
    self.armor = PowerPoint.kArmor
    
    self.maxHealth = PowerPoint.kHealth
    self.maxArmor = PowerPoint.kArmor
    
    self:SetLightMode(kLightMode.Normal)
    
    self.powered = true
    
    self:UpdatePoweredStructures()
    
end

// Can be repaired by friendly players
function PowerPoint:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    if self:GetCanBeWelded(player) then
        return self:OnWeld(player, elapsedTime)
    end
    
    return false
    
end

// Repaired by marine or MAC 
function PowerPoint:OnWeld(entity, elapsedTime)

    local welded = false
    
    // Marines can repair power points
    if entity:isa("Marine") then
    
        welded = (self:AddHealth(kMarineRepairHealthPerSecond * elapsedTime) > 0)        
        
        // Play puff of sparks every so often
        local time = Shared.GetTime()
        if welded and (time >= self.timeOfNextBuildWeldEffects) then        
            
            self:TriggerEffects("player_weld")
            
            self.timeOfNextBuildWeldEffects = time + Structure.kBuildWeldEffectsInterval
            
        end
        
    else    
        welded = Structure.OnWeld(self, entity, elapsedTime)    
    end
    
    if self:GetHealthScalar() > PowerPoint.kDamagedPercentage then

        self:StopDamagedSound()
        
        if self:GetLightMode() == kLightMode.LowPower and self.powered then
        
            self:SetLightMode(kLightMode.Normal)
            
        end
        
    end
    
    if not self.powered and self:GetHealthScalar() == 1 then
    
        self.powered = true
        
        self:SetLightMode(kLightMode.Normal)
        
        self:SetModel(PowerPoint.kOnModelName)
        
        self:StopSound(PowerPoint.kAuxPowerBackupSound)
        
        self:UpdatePoweredStructures()
        
        self:TriggerEffects("fixed_power_up")
        
    end
    
    if (welded) then
      self:AddAttackTime(-0.1)
    end
    
    return welded
    
end

function PowerPoint:StopDamagedSound()

    if self.playingLoopedDamaged then
    
        self:StopSound(PowerPoint.kDamagedSound)
        
        self.playingLoopedDamaged = false
        
    end

end

function PowerPoint:OnTakeDamage(damage, attacker, doer, point)

    Structure.OnTakeDamage(self, damage, attacker, doer, point)
    
    if self.powered then
    
        self:PlaySound(PowerPoint.kTakeDamageSound)
        
        local healthScalar = self:GetHealthScalar()
        
        if healthScalar < PowerPoint.kDamagedPercentage then
        
            self:SetLightMode(kLightMode.LowPower)
            
            if not self.playingLoopedDamaged then
            
                self:PlaySound(PowerPoint.kDamagedSound)
                
                self.playingLoopedDamaged = true
                
            end
            
        else
            self:SetLightMode(kLightMode.Damaged)
        end
        
    end
    
    self:AddAttackTime(0.9)
    
end

// Use nearby structures to determine which one we should be powering. Counts number of
// structures for each team and returns the max. If tied, returns world team (power point
// will work for both teams). This will support the future possibility of marine vs. marine.
function PowerPoint:DetermineTeamNumber(nearbyStructures)

    local team1Number = 0
    local team2Number = 0
    
    for index, structure in ipairs(nearbyStructures) do
    
        local team = structure:GetTeam()
        if team.GetTeamType then
        
            local teamType = team:GetTeamType()
            if teamType == kMarineTeamType then
                        
                local teamNumber = structure:GetTeamNumber()
                
                if teamNumber == kTeam1Index then
                    team1Number = team1Number + 1
                elseif teamNumber == kTeam2Index then
                    team2Number = team2Number + 1
                end
                
            end
            
        end
        
    end
    
    if team1Number > team2Number then
        return kTeam1Index
    elseif team2Number > team1Number then
        return kTeam2Index
    end
    
    return kTeamReadyRoom

end

function PowerPoint:UpdatePoweredStructures()

    local structures = EntityListToTable(Shared.GetEntitiesWithClassname("Structure"))
    
    table.removevalue(structures, self)
    
    self:SetTeamNumber(self:DetermineTeamNumber(structures))
    
    for index, structure in ipairs(structures) do
    
        structure:UpdatePoweredState()
        
    end
    
end

function PowerPoint:GetSendDeathMessageOverride()
    return self.powered
end

function PowerPoint:AddAttackTime(value)
  self.attackTime =  math.max(self.attackTime + value, 0)
end