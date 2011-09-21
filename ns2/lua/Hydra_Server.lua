// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hydra_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Creepy plant turret the Gorge can create.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/InfestationMixin.lua")

Hydra.kThinkInterval = .5

PrepareClassForMixin(Hydra, InfestationMixin)
 
function Hydra:GetDistanceToTarget(target)
    return (target:GetEngagementPoint() - self:GetModelOrigin()):GetLength()           
end

function Hydra:AttackTarget()

    self:TriggerUncloak()

    self:CreateSpikeProjectile()
    
    self:TriggerEffects("hydra_attack")
    
    // Random rate of fire to prevent players from popping out of cover and shooting regularly
    self.timeOfNextFire = Shared.GetTime() + self:AdjustAttackDelay(.5 + NetworkRandom() * 1)
    
end

function Hydra:CreateSpikeProjectile()

    local directionToTarget = self.target:GetEngagementPoint() - self:GetEyePos()
    local targetDistanceSquared = directionToTarget:GetLengthSquared()
    local theTimeToReachEnemy = targetDistanceSquared / (Hydra.kSpikeSpeed * Hydra.kSpikeSpeed)

    local predictedEngagementPoint = self.target:GetEngagementPoint()
    if self.target.GetVelocity then
        local targetVelocity = self.target:GetVelocity()
        predictedEngagementPoint = self.target:GetEngagementPoint() + ((targetVelocity:GetLength() * Hydra.kTargetVelocityFactor * theTimeToReachEnemy) * GetNormalizedVector(targetVelocity))
    end
    
    local direction = GetNormalizedVector(predictedEngagementPoint - self:GetEyePos())
    local startPos = self:GetEyePos() + direction
    
    // Create it outside of the hydra a bit
    local spike = CreateEntity(HydraSpike.kMapName, startPos, self:GetTeamNumber())
    SetAnglesFromVector(spike, direction)
    
    local startVelocity = direction * Hydra.kSpikeSpeed
    spike:SetVelocity(startVelocity)
    
    spike:SetGravityEnabled(false)
    
    // Set spike owner so we don't collide with ourselves and so we
    // can attribute a kill to us
    spike:SetOwner(self:GetOwner())
    
    spike:SetIsVisible(true)
                
end

function Hydra:GetIsEnemyNearby()

    local enemyPlayers = GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber()))
    
    for index, player in ipairs(enemyPlayers) do                
    
        if player:GetIsVisible() and not player:isa("Commander") then
        
            local dist = self:GetDistanceToTarget(player)
            if dist < Hydra.kRange then
        
                return true
                
            end
            
        end
        
    end

    return false
    
end

function Hydra:OnThink()

    PROFILE("Hydra:OnThink")

    Structure.OnThink(self)
    
    if self:GetIsBuilt() and self:GetIsAlive() then    
    
        self.target = self.targetSelector:AcquireTarget()

        if self.target then
        
            if(self.timeOfNextFire == nil or (Shared.GetTime() > self.timeOfNextFire)) then
           
                self:AttackTarget()
                
            end

        else
        
            // Play alert animation if marines nearby and we're not targeting (ARCs?)
            if self.timeLastAlertCheck == nil or Shared.GetTime() > self.timeLastAlertCheck + Hydra.kAlertCheckInterval then
            
                if self:GetIsEnemyNearby() then
                
                    self:TriggerEffects("hydra_alert")
                    
                    self.timeLastAlertCheck = Shared.GetTime()
                
                end
                                                            
            end
            
        end
        
    end
    
    self:SetNextThink(Hydra.kThinkInterval)
    
end

function Hydra:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    // Start scanning for targets once built
    self:SetNextThink(Hydra.kThinkInterval)
        
end

function Hydra:OnInit()
    InitMixin(self, InfestationMixin)
    
    Structure.OnInit(self)
   
    self:SetNextThink(Hydra.kThinkInterval)
    
    self.targetSelector = TargetSelector():Init(
            self,
            Hydra.kRange, 
            true,
            { kAlienStaticTargets, kAlienMobileTargets })           
end

function Hydra:OnDestroy()
    self:ClearInfestation()
    Structure.OnDestroy(self)        
end



