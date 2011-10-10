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
    if self:GetIsPowered() then
    
        self:SetAnimation(PowerPoint.kAnimOff)
        
        self:SetModel(PowerPoint.kOffModelName)
        
        self:StopDamagedSound()
        
        self:PlaySound(PowerPoint.kDestroyedSound)
        self:PlaySound(PowerPoint.kDestroyedPowerDownSound)
                       
        self:SetIsPowerSource(false)
        
        self:SetLightMode(kLightMode.NoPower)                
        
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

    if not self:GetIsPowered() then
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
            
    self:SetIsPowerSource(true)

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

        local amount = kMarineRepairHealthPerSecond * elapsedTime
        
        // highdamage cheat speeds things up for testing    
        amount = amount * GetGamerules():GetDamageMultiplier()
        
        welded = (self:AddHealth(amount) > 0)        
        
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
        
        if self:GetLightMode() == kLightMode.LowPower and self:GetIsPowered() then
        
            self:SetLightMode(kLightMode.Normal)
            
        end
        
    end
    
    if not self:GetIsPowered() and self:GetHealthScalar() == 1 then
    
        self:SetIsPowerSource(true)
        
        self:SetLightMode(kLightMode.Normal)
        
        self:SetModel(PowerPoint.kOnModelName)
        
        self:StopSound(PowerPoint.kAuxPowerBackupSound)               
        
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
    
    if self:GetIsPowered() then
    
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

function PowerPoint:GetSendDeathMessageOverride()
    return self:GetIsPowered()
end

function PowerPoint:AddAttackTime(value)
  self.attackTime =  math.max(self.attackTime + value, 0)
end