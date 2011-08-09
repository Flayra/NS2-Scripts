// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourcePoint_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function ResourcePoint:Reset()
    
    self:OnInit()
    
    self:ClearAttached()
    
end

function ResourcePoint:SetAttached(attached)

    ScriptActor.SetAttached(self, attached)
    
    self:SetEffectState(false)    
    
end

// Call to turn on or off the effect that shows resources escaping from the nozzle
function ResourcePoint:SetEffectState(state)

    if state ~= self.playingEffect then
    
        self.playingEffect = state
                
    end
    
end

function ResourcePoint:ClearAttached()

    ScriptActor.ClearAttached(self)
    
    self:SetEffectState(true)    

end

// Create a new resource tower on this nozzle, returning false if already occupied or not enough room
function ResourcePoint:SpawnResourceTowerForTeam(team, techId)

    local success = false
    
    if(self:GetAttached() == nil) then
    
        // Force create because entity may not be cleaned up from round reset
        local tower = CreateEntityForTeam(techId, self:GetOrigin(), team:GetTeamNumber(), nil)
        
        if tower then
        
            tower:SetConstructionComplete()           
            
            self:SetAttached(tower)
            
            success = true
            
        end
       
    else
        Print("ResourcePoint:SpawnResourceTowerForTeam(%s): Entity %s already attached.", EnumToString(kTechId, techId), self:GetAttached():GetClassName()) 
    end
    
    return success
    
end


