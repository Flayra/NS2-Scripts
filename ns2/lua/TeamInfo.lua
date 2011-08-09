// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/TeamInfo.lua
//
// TeamInfo is used to sync information about a team to clients.
// A client on team 1 or 2 will only receive team info regarding their
// own team while a client on the kSpectatorIndex team will receive both
// teams info.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'TeamInfo' (Entity)

TeamInfo.kMapName = "TeamInfo"

TeamInfo.networkVars =
{
    teamNumber          = "integer (" .. ToString(kTeamInvalid) .. " to " .. ToString(kSpectatorIndex) .. ")",
    teamResources       = "float",
    personalResources   = "float",
    numResourceTowers   = "integer (0 to 99)"
}

function TeamInfo:OnCreate()

    Entity.OnCreate(self)
    
    if Server then
    
        self:SetUpdates(true)
        
        self.teamNumber = kTeamInvalid
        self.teamResources = 0
        self.personalResources = 0
        self.numResourceTowers = 0
        
    end
    
end

function TeamInfo:SetWatchTeam(team)

    self.team = team
    self:_UpdateInfo()
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
end

function TeamInfo:GetTeamNumber()
    return self.teamNumber
end

function TeamInfo:GetTeamResources()
    return self.teamNumber
end

function TeamInfo:GetPersonalResources()
    return self.personalResources
end

function TeamInfo:GetNumResourceTowers()
    return self.numResourceTowers
end

function TeamInfo:UpdateRelevancy()

	self:SetRelevancyDistance(Math.infinity)
	
	local mask = 0
	
	if self.teamNumber == kTeam1Index then
		mask = bit.bor(mask, kRelevantToTeam1)
	end
	if self.teamNumber == kTeam2Index then
		mask = bit.bor(mask, kRelevantToTeam2)
	end
		
	self:SetExcludeRelevancyMask(mask)

end

function TeamInfo:OnUpdate(deltaTime)

    self:_UpdateInfo()
    
end

function TeamInfo:_UpdateInfo()

    if self.team then
    
        self.teamNumber = self.team:GetTeamNumber()
        self.teamResources = self.team:GetTeamResources()
        
        self.personalResources = 0
        for index, player in ipairs(self.team:GetPlayers()) do
            self.personalResources = self.personalResources + player:GetResources()
        end
        
        self.numResourceTowers = table.count(GetEntitiesForTeam("ResourceTower", self.teamNumber))
        
    end
    
end

Shared.LinkClassToMap( "TeamInfo", TeamInfo.kMapName, TeamInfo.networkVars )