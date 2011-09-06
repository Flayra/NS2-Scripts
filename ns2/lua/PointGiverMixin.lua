// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PointGiverMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * PointGiverMixin handles awarding points on kills and other events.
 */
PointGiverMixin = { }
PointGiverMixin.type = "PointGiver"

local kDefaultPointValue = 10

PointGiverMixin.expectedCallbacks =
{
    GetTeamNumber = "Returns the team number this PointGiver is on.",
    GetTechId = "Returns the tech Id of this PointGiver."
}

function PointGiverMixin:__initmixin()
end

function PointGiverMixin:GetPointValue()
    return LookupTechData(self:GetTechId(), kTechDataPointValue, kDefaultPointValue)
end

/**
 * If a AwardResForKill() function is defined on the attacker then it will be called
 * passing in self to check how many resources should be awarded for killing self.
 */
function PointGiverMixin:OnKill(damage, attacker, doer, point, direction)

    // Give points to killer.
    local pointOwner = attacker
    
    // If the pointOwner is not a player, award it's points to it's owner.
    if pointOwner ~= nil and not HasMixin(pointOwner, "Scoring") then
        pointOwner = pointOwner:GetOwner()
    end
    
    // Points not awarded for entities on the same team.
    if pointOwner ~= nil and HasMixin(pointOwner, "Scoring") and pointOwner:GetTeamNumber() ~= self:GetTeamNumber() then
    
        local resAwarded = 0
        
        // Only killing players increases the kill count and awards resources for kills.
        if self:isa("Player") then
        
            pointOwner:AddKill()
            
            if pointOwner.AwardResForKill then
                resAwarded = pointOwner:AwardResForKill(self)
            end
            
        end
        
        pointOwner:AddScore(self:GetPointValue(), resAwarded)
        
    end
    
end