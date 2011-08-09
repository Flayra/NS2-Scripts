// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Ladder.lua
//
//    Created by:   Brian Cronin (brian@unknownworlds.com)
//
// Represents a climbable ladder that is placed in the world.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'Ladder' (Trigger)

Ladder.kMapName = "ladder"

function Ladder:OnInit()

    Trigger.OnInit(self)
    
    self.physicsBody:SetCollisionEnabled(true)
    
end

function Ladder:OnTriggerEntered(enterEnt, triggerEnt)
    
    // Temporarily disabled until triggers are working consistently
    /*
    if(enterEnt.SetIsOnLadder) then
        enterEnt:SetIsOnLadder(true, self)
    end
    */
    
end

function Ladder:OnTriggerExited(exitEnt, triggerEnt)

    // Temporarily disabled until triggers are working consistently
    /*
    if(exitEnt.SetIsOnLadder) then
        exitEnt:SetIsOnLadder(false, nil)
    end
    */
    
end

Shared.LinkClassToMap("Ladder", Ladder.kMapName, {})