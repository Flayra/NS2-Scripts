// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourceTower_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Generic resource structure that marine and alien structures inherit from.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function ResourceTower:GetUpdateInterval()
    return kResourceTowerResourceInterval
end

function ResourceTower:UpdateOnThink()

    // Give resources to all players on team
    local team = self:GetTeam()
    team:ForEachPlayer( function (player) self:GiveResourcesToTeam(player) end )

    // Give resources to team (upgrades don't add to amount)
    local team = self:GetTeam()
    if(team ~= nil) then
        team:AddTeamResources(ResourceTower.kTeamResourcesInjection)        
    end
    
    if self:isa("Extractor") then
       self:TriggerEffects("extractor_collect")
    else
        self:TriggerEffects("harvester_collect")
    end
    
end

function ResourceTower:OnThink()

    if self:GetIsBuilt() and self:GetIsAlive() and (self:GetAttached() ~= nil) and self:GetIsActive() and (self:GetAttached():GetAttached() == self) and GetGamerules():GetGameStarted() then

        self:UpdateOnThink()
            
    end

    Structure.OnThink(self)
    
    self:SetNextThink(self:GetUpdateInterval())

end

function ResourceTower:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetNextThink(ResourceTower.kBuildDelay)
    
end


