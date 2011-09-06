// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Structure_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/EnergyMixin.lua")

function Structure:OnSynchronized()

    ScriptActor.OnSynchronized(self)
    
    self:_UpdateStructureEffects()
    
end

function Structure:_UpdateStructureEffects()
    
    if self.clientEffectsActive ~= nil and self.clientEffectsActive ~= self:GetEffectsActive() then
        self:TriggerEffects("client_active_changed")
    end
    
    self.clientEffectsActive = self:GetEffectsActive()

end

function Structure:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    if self:GetCanConstruct(player) and self:GetIsWarmedUp() then
    
        player:SetActivityEnd(elapsedTime)
        return true
        
    end
    
    return false
    
end
