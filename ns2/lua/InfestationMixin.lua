// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\InfestationMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

InfestationMixin = { }
InfestationMixin.type = "Infestation"

// Whatever uses the InfestationMixin needs to implement the following callback functions.
InfestationMixin.expectedCallbacks = 
{
    GetInfestationRadius = "How far infestation should spread from entity." 
}

function InfestationMixin.__prepareclass(toClass)

    ASSERT(toClass.networkVars ~= nil, "InfestationMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        timeLastHadInfestation    = "float"        
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function InfestationMixin:__initmixin()
    self.timeLastHadInfestation = 0
    self.infestationId = Entity.invalidId
end

function InfestationMixin:OverrideSpawnInfestation(infestation)
    if self.OnOverrideSpawnInfestation then
        self:OnOverrideSpawnInfestation(infestation)    
    end
end

function InfestationMixin:SpawnInfestation(percent)
    if self:GetTeamType() ~= kAlienTeamType then
        return
    end
    
    if self.infestationId == Entity.invalidId then
    
        local coords = self:GetCoords()
        local attached = self:GetAttached()
        if attached then
            coords = attached:GetCoords()
        end
        
        local radius = self:GetInfestationRadius()
        local infestation = CreateStructureInfestation(coords, self:GetTeamNumber(), radius, percent)
        self.infestationId = infestation:GetId()
        
        self:OverrideSpawnInfestation(infestation)
    end
end

function InfestationMixin:SpawnInitialInfestation()
    local infestation = Shared.GetEntity(self.infestationId)
    ASSERT(infestation ~= nil)
    infestation:SetRadiusPercent(1)
end

function InfestationMixin:UpdateInfestation()

    PROFILE("InfestationMixin:UpdateInfestation")
    
    // No update if we are not built!
    if not self:GetIsBuilt() then
        return
    end        
        
    local infestation = Shared.GetEntity(self.infestationId)
    if (self.infestationId == Entity.invalidId) or (infestation == nil) or (not infestation:isa("Infestation")) then    
        if self.timeLastHadInfestation == nil or (Shared.GetTime() > self.timeLastHadInfestation + 5) then
            self:SpawnInfestation(.1)
        end
    elseif infestation then
        self.timeLastHadInfestation = Shared.GetTime()
    end       
end

function InfestationMixin:ClearInfestation()
    local infestation = Shared.GetEntity(self.infestationId)
    if infestation and infestation:isa("Infestation") then
        Server.DestroyEntity(infestation)
        self.infestationId = Entity.invalidId
    end
end

function InfestationMixin:OnSighted(sighted)
  local infestation = Shared.GetEntity(self.infestationId)
  if (infestation ~= nil) then    
    infestation:SetIsSighted(sighted)
  end
  
end

