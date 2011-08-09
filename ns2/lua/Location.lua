// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Location.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Represents a named location in a map, so players can see where they are.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Trigger.lua")

class 'Location' (Trigger)

Location.kMapName = "location"

Shared.PrecacheString("")

function Location:OnInit()

    self.teamNumber = 0
    // Default to show.
    if self.showOnMinimap == nil then
        self.showOnMinimap = true
    end

    Trigger.OnInit(self)
    
    self.physicsBody:SetCollisionEnabled(true)
    
    self:SetPropagate(Entity.Propagate_Always)
    
end

function Location:GetShowOnMinimap()

    return self.showOnMinimap

end

function Location:OnLoad()

    // Precache name so we can use string index in entities
    Shared.PrecacheString(self.name)

end

function Location:OnTriggerEntered(enterEnt, triggerEnt)

    //Print("Location:OnTriggerEntered(%s, %s)", enterEnt:GetClassName(), triggerEnt:GetName())
    
    if enterEnt.SetLocationName then
        enterEnt:SetLocationName(triggerEnt:GetName())
    end
    
end

Shared.LinkClassToMap("Location", Location.kMapName, {})