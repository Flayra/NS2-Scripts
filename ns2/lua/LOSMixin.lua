// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LOSMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

LOSMixin = { }
LOSMixin.type = "LOS"
LOSMixin.kMinLOSRange = 5

LOSMixin.kUnitMaxLOSDistance = 30
LOSMixin.kUnitMinLOSDistance = 3.5
LOSMixin.kStructureMinLOSDistance = 10
LOSMixin.kLOSUpdateInterval = 1

function LOSMixin:__initmixin()

    self.timeSinceLastLOSUpdate = Shared.GetTime()
    self.sighted = false
    self:SetIsSighted(false)
    
end

function LOSMixin:HasVision()
    return true
end

function LOSMixin:ShowSelf()

    PROFILE("LOSMixin:ShowSelf")
   
    local entities = {}
    Shared.GetEntitiesWithinRadius(self:GetOrigin(), self:GetVisionRadius(), entities)      
    local seen = false
    for index, entityId in ipairs(entities) do
    
        local actor = Shared.GetEntity(entityId) 
        if HasMixin(actor, "LOS") then
        
            local hasVision = actor:HasVision() // If this entity provides vision
            local validCheck = actor:CheckEnableVisibilty(self) // if this entity cares about us
            
            if hasVision and validCheck then
                seen = actor:CanSee(self)
            end
       
            if seen then
                break
            end 
            
        end
        
    end
   
    // If we have been seen then we can bail
    self:SetIsSighted(seen)
    
end

function LOSMixin:CanSee(entity)

    // If we are nil then we are going to be seen
    if (entity == nil) then
        return false
    end
    
    // If the other entity is not visible then its not going to see us
    if not entity:GetIsVisible() then
        return false
    end
    
    if entity:isa("Structure") and not entity:GetIsBuilt() then
        return false
    end
    
    // If we are already too far away then we do not want to go any further
    local maxDist = self:GetVisionRadius()
    local dist = (entity:GetOrigin() - self:GetOrigin()):GetLengthSquared()
    if dist > (maxDist * maxDist) then      
        return false
    end
    
    if dist < LOSMixin.kUnitMinLOSDistance then
        return true
    end
    
     // check the FOV
     // $AS TODO: Fix this as it seems like it could save some time on the 
     // CanSee trace. As if the objects is not in the FOV regardless of the
     // Tracing why bother even running the check
   /* local sightDir = (entity:GetOrigin() - self:GetOrigin()):SafeNormal()
    local lookDir  = self:GetAngles():GetCoords().zAxis
    local fovCheck = sightDir:Or(lookDir)
    if (fovCheck < self:GetPeripheralVision()) then
      Print("Failz")
      return false
    end */

    return self:LineOfSightTo(entity)
    
end

function LOSMixin:OnUpdate(delatime)

    PROFILE("LOSMixin:OnUpdate")
    // $AS HACKS!
    if (self:isa("Infestation")) then
        return
    end
  
    if self.timeSinceLastLOSUpdate > LOSMixin.kLOSUpdateInterval then    
        self:ShowSelf()
        self.timeSinceLastLOSUpdate = 0    
    else
        self.timeSinceLastLOSUpdate = self.timeSinceLastLOSUpdate + delatime        
    end

end

function LOSMixin:GetVisionRadius()

    local value = LOSMixin.kUnitMaxLOSDistance
    if self.OverrideVisionRadius then
        value = self:OverrideVisionRadius()
    end
    return value

end

function LOSMixin:CheckEnableVisibilty(entity)

    PROFILE("LOSMixin:CheckEnableVisibilty")
    local result = true
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())

    if entity:GetTeamNumber() ~= enemyTeamNumber then    
        result = false
    end 

    if self:isa("Structure") and not self:GetIsBuilt() then
        return false
    end   

    if self.OverrideCheckvision then     
        result = self:OverrideCheckvision()
    end

    return result

end

function LOSMixin:SetIsSighted(sighted)

    PROFILE("LOSMixin:SetIsSighted")
    
    self.sighted = sighted

    local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
    if sighted then
        mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
    else
    
        if self:GetTeamNumber() == 1 then
            mask = bit.bor(mask, kRelevantToTeam1Commander)
        elseif self:GetTeamNumber() == 2 then
            mask = bit.bor(mask, kRelevantToTeam2Commander)
        end
    
    end  

    self:SetExcludeRelevancyMask( mask )
  
    if self.OnSighted then
        self:OnSighted(sighted)
    end

end

function LOSMixin:GetIsSighted()
    return self.sighted
end

function LOSMixin:GetPeripheralVision()
    return 0.0
end

function LOSMixin:LineOfSightTo(entity)

    PROFILE("LOSMixin:LineOfSightTo")
    if entity == nil then
        return false
    end

    if self.OverrideLineOfSight then   
        return self:OverrideLineOfSight(entity)
    end

    if (HasMixin(entity, "Cloakable") and entity:GetIsCloaked()) or (HasMixin(entity, "Camouflage") and entity:GetIsCamouflaged()) then    
        return false
    end  

    if self:isa("Structure") and self:GetIsActive() and (entity:isa("Structure") or entity:isa("Infestation")) then
    
        local trace = Shared.TraceRay(self:GetModelOrigin(), entity:GetModelOrigin() + Vector(0, 1, 0), PhysicsMask.AllButPCs, EntityFilterTwo(self, entity))                
        if trace.fraction ~= 1.0 then
            return false
        end
        
    elseif (not self:isa("Structure")) then
        return self:GetCanSeeEntity(entity)
    end
    
    return true

end