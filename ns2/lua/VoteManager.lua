// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\VoteManager.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

class 'VoteManager'

// Commander ejection
VoteManager.kMinVotesNeeded = 2
VoteManager.kTeamVotePercentage = .3

// Seconds that a vote lasts before expiring
VoteManager.kVoteDuration = 120

// Constructor
function VoteManager:Initialize()

    self.playersVoted = {}
    self:SetNumPlayers(0)
    
end

function VoteManager:PlayerVotesFor(playerId, target, time)

    if type(playerId) == "number" and target ~= nil and type(time) == "number" then
    
        if not self.target or (self.target == target) then
    
            // Make sure player hasn't voted already    
            if not table.find(self.playersVoted, playerId) then
            
                table.insert(self.playersVoted, playerId)
                self.target = target
                self.timeVoteStarted = time
                
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function VoteManager:GetVotePassed()

    // Round to nearest number of players (3.4 = 3, 3.5 = 4)
    local votesNeeded = math.max(VoteManager.kMinVotesNeeded, math.floor((self.numPlayers * VoteManager.kTeamVotePercentage) + .5))
    return table.count(self.playersVoted) >= votesNeeded

end

function VoteManager:GetTarget()
    return self.target
end

function VoteManager:GetVoteStarted()
    return (self.target ~= nil)
end

// Note - doesn't reset number of players
function VoteManager:Reset()
    self.playersVoted = {}
    self.target = nil
end

function VoteManager:SetNumPlayers(numPlayers)

    ASSERT(type(numPlayers) == "number")
    self.numPlayers = numPlayers

end

// Pass current time in, returns true if vote timed out. Typically call Reset() after it
// returns true.
function VoteManager:GetVoteElapsed(time)

    if self.timeVoteStarted and type(time) == "number" then
    
        if (time - self.timeVoteStarted) >= VoteManager.kVoteDuration then
        
            return true
            
        end
        
    end
    
    return false
    
end
