// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourceTower.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Generic resource structure that marine and alien structures inherit from.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'ResourceTower' (Structure)

ResourceTower.kMapName = "resourcetower"

ResourceTower.kResourcesInjection = kPlayerResPerInterval
ResourceTower.kTeamResourcesInjection = 1
ResourceTower.kMaxUpgradeLevel = 3

// Don't start generating resources right away, wait a short time
// (but not too long or it will feel like a bug). This is to 
// make it less advantageous for a team to build every nozzle
// they find. Same as in NS1.
ResourceTower.kBuildDelay = 4

ResourceTower.networkVars = 
{
    upgradeLevel = string.format("integer (0 to %d)", ResourceTower.kMaxUpgradeLevel)
}

if (Server) then
    Script.Load("lua/ResourceTower_Server.lua")
end

function ResourceTower:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function ResourceTower:OnInit()

    Structure.OnInit(self)
    
    self.playingSound = false
    self.upgradeLevel = 0
    
end

function ResourceTower:GetUpgradeLevel()
    return self.upgradeLevel
end

function ResourceTower:SetUpgradeLevel(upgradeLevel)
    self.upgradeLevel = Clamp(upgradeLevel, 0, ResourceTower.kMaxUpgradeLevel)
end

function ResourceTower:GiveResourcesToTeam(player)

    local resources = ResourceTower.kResourcesInjection * (1 + self:GetUpgradeLevel() * kResourceUpgradeAmount)
    player:AddResources(resources, true)

end

Shared.LinkClassToMap("ResourceTower", ResourceTower.kMapName, ResourceTower.networkVars)
