// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DeathTrigger.lua
//
//    Created by:   Brian Cronin (brian@unknownworlds.com)
//
// Kill entity that touches this.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'DeathTrigger' (Trigger)

DeathTrigger.kMapName = "death_trigger"

function DeathTrigger:OnInit()

    Trigger.OnInit(self)
    
    self.physicsBody:SetCollisionEnabled(true)
    
end

function DeathTrigger:OnTriggerEntered(enterEnt, triggerEnt)

    if HasMixin(enterEnt, "Live") and enterEnt:GetIsAlive() then
    
        local direction = GetNormalizedVector(enterEnt:GetModelOrigin() - self:GetOrigin())
        
        enterEnt:Kill(self, self, self:GetOrigin(), direction)
        
    end
    
end

Shared.LinkClassToMap("DeathTrigger", DeathTrigger.kMapName, {})