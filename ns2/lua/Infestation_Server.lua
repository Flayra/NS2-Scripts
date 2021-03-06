// ======= Copyright � 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Infestation_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Patch of infestation created by alien commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


// a 2m radius patch will go away in 10 seconds
Infestation.kShrinkRate = -0.2
// Grows at 1m/4 seconds, roughly 20 seconds to grow to full size
Infestation.kGrowthRate = 0.25

Infestation.kHealPerSecond = 5

function Infestation:AddToInfestationMap()

    Server.infestationMap:AddInfestation(self)
    self.addedToMap = true
    
end

// Update radius of infestation according to if they are connected or not! If not connected to hive, we shrink.
// If connected to hive, we grow to our max radius. The rate at which it does either is dependent on the number 
// of connections.
function Infestation:UpdateInfestation(deltaTime)

    PROFILE("Infestation:UpdateInfestation")

    local now = Shared.GetTime()
    local newGrowthRate = 0
    local dt = deltaTime
    if not self.growthRate or now >= self.lastUpdateThinkTime + self.thinkTime then
    
        if not self.addedToMap then
            self:AddToInfestationMap()
        end
        local deltaUpdateThinkTime = now - self.lastUpdateThinkTime
        self.lastUpdateThinkTime = self.lastUpdateThinkTime + self.thinkTime
       
        // grow if we are smaller than max
        newGrowthRate = self.radius < self.maxRadius and Infestation.kGrowthRate or 0
        
        // but if we are disconnected, then shrink instead
        newGrowthRate = self.hostAlive and newGrowthRate or Infestation.kShrinkRate
        // when shifting between growthrates, don't use a long deltatime because then it looks like it jumps
        dt = self.growthRate == newGrowthRate and deltaTime or 0.01
        self.growthRate = newGrowthRate * self.growthRateScalar
        // Always regenerating (5 health/sec)
        self.health = Clamp(self.health + deltaUpdateThinkTime * Infestation.kHealPerSecond, 0, self.maxHealth)
        
    end
    

    if self.growthRate ~= 0 then
    
        // Update radius based on lifetime
        self.radius = Clamp(self.radius + dt * self.growthRate, 0, self:GetMaxRadius())
    
        // Mark as fully grown
        if self.radius == self:GetMaxRadius() then
        
            if not self.fullyGrown then
            
                self:TriggerEffects("infestation_grown")
                self.fullyGrown = true
                
            end
            
        else
            self.fullyGrown = false
        end
      
        // Kill us off when we get too small!    
        if self.growthRate < 0 and self.radius <= 0 then
        
            self:TriggerEffects("death")
            DestroyEntity(self)
            
        end
        
    end

end

// Infestation can only take damage from flames.
function Infestation:ComputeDamageOverride(attacker, damage, damageType, time) 
    // Returning nil for the damage type will cause no damage.
    return 0, nil
end