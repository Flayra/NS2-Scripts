// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\FireMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

FireMixin = { }
FireMixin.type = "Fire"

function FireMixin.__prepareclass(toClass)

     ASSERT(toClass.networkVars ~= nil, "FireMixin expects the class to have network fields")
    
    local addNetworkFields =
    {        
        stopChance                      = "float",
        timeLastUpdateStopChance        = "float"          
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function FireMixin:__initmixin()

    self.fireAttackerId             = Entity.invalidId
    self.fireDoerId                 = Entity.invalidId
    
    self.stopChance                 = 0
    self.timeLastUpdateStopChance   = 0
    
end

function FireMixin:SetOnFire(attacker, doer)

    if not self:GetCanBeSetOnFire() then
        return
    end
    
    self:SetGameEffectMask(kGameEffect.OnFire, true)
    
    self.fireAttackerId = attacker:GetId()
    self.fireDoerId = doer:GetId()
    
end

function FireMixin:ClearFire()

    self:SetGameEffectMask(kGameEffect.OnFire, false)
    
    self.fireAttackerId             = Entity.invalidId
    self.fireDoerId                 = Entity.invalidId
    
    self.stopChance                 = 0
    self.timeLastUpdateStopChance   = nil
    
end

function FireMixin:GetIsOnFire() 
    return self:GetGameEffectMask(kGameEffect.OnFire)
end

function FireMixin:_GetStopChance()

    if self.timeLastUpdateStopChance == nil or (Shared.GetTime() > self.timeLastUpdateStopChance + 10) then
        self.stopChance = self.stopChance + kStopFireProbability        
        self.timeLastUpdateStopChance = Shared.GetTime()
    end
    return self.stopChance
    
end

function FireMixin:GetCanBeSetOnFire()

  if self.OnOverrideCanSetFire then
    return self:OnOverrideCanSetFire(attacker, doer)
  else
    return true
  end
  
end

function FireMixin:OnUpdate(deltaTime)   
 
    if not self:GetIsOnFire() then
        return
    end
    
    if Server then
    
        // Do damage over time
        self:TakeDamage(kBurnDamagePerSecond * deltaTime, Shared.GetEntity(self.fireAttackerId), Shared.GetEntity(self.fireDoerId))
        
        // See if we put ourselves out
        local stopFireChance = deltaTime * self:_GetStopChance()
        if (NetworkRandom() < stopFireChance) then
            self:ClearFire()
        end
        
    elseif Client then
    
        if self.updateClientSideFireEffects == true then
            self:_UpdateClientFireEffects()
            self.updateClientSideFireEffects = false
        end
        
    end
    
end

function FireMixin:OnSynchronized()

    PROFILE("FireMixin:OnSynchronized")
    
    if Client then
        self.updateClientSideFireEffects = true
    end
    
end

function FireMixin:OnEntityChange(entityId, newEntityId)
    
    if entityId == self.fireAttackerId then
        self.fireAttackerId = newEntityId
    end
    
end

function FireMixin:_UpdateClientFireEffects()

    // Play on-fire cinematic every so often if we're on fire
    if self:GetGameEffectMask(kGameEffect.OnFire) and self:GetIsAlive() and self:GetIsVisible() then
    
        // If we haven't played effect for a bit
        local time = Shared.GetTime()
        
        if not self.timeOfLastFireEffect or (time > (self.timeOfLastFireEffect + .5)) then
        
            local firstPerson = (Client.GetLocalPlayer() == self)
            local cinematicName = GetOnFireCinematic(self, firstPerson)
            
            if firstPerson then
                local viewModel = self:GetViewModelEntity()
                if viewModel then
                    Shared.CreateAttachedEffect(self, cinematicName, viewModel, Coords.GetTranslation(Vector(0, 0, 0)), "", true, false)
                end
            else
                Shared.CreateEffect(self, cinematicName, self, self:GetAngles():GetCoords())
            end
            
            self.timeOfLastFireEffect = time
            
        end
        
    end
    
end

function FireMixin:OnGameEffectMaskChanged(effect, state)
    
    if effect == kGameEffect.OnFire and state then
        self:TriggerEffects("fire_start")
    elseif effect == kGameEffect.OnFire and not state then
        self:TriggerEffects("fire_stop")
    end
    
end