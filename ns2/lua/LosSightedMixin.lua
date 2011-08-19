// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LosSightedMixin.lua    
//    
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// Mixin for units that can be sighed by LOS
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

LosSightedMixin = { }
LosSightedMixin.type = "LosSighted"
// interval to next check depending on if this check was successful or not
LosSightedMixin.kPlayerCheckInterval = { [true]=4, [false]=0.5 }
LosSightedMixin.kOtherCheckInterval = { [true]=10, [false]=2 }
LosSightedMixin.expectedCallbacks = {
    SetSighted = "Called to set the sighted state of the unit"
}


LosSightedMixin.updateTable = {}
LosSightedMixin.nextUpdate = 0
// debugging; toggle by the "los" command in cheats mode. Makes it possible to see how
// much the los-calculations actually cost (hard to see when they are spread out)
LosSightedMixin.stopLosCalc = false

function LosSightedMixin:__initmixin()
    LosSightedMixin.updateTable[self:GetId()] = Shared.GetTime()
end

function LosSightedMixin:UpdateSighted()
    PROFILE("LosSightedMixin:UpdateSighted")
    if not self.losSelector then
        local alienTargetTypes = { kAlienStaticTargets, kAlienMobileTargets }
        local marineTargetTypes = { kMarineStaticTargets, kMarineMobileTargets }
        // this doesn't really work for Res/Tech/Power points
        local targetTypes = self:GetTeamType() == kAlienTeamType and alienTargetTypes or marineTargetTypes 
        self.losSelector = LosSelector():Init(self, targetTypes)
    end
    local sighted = self.losSelector:CheckIfSighted()
    self:SetSighted(sighted)  
end


function LosSightedMixin:SetSighted(sighted)
    local timeToNextCheck = self:isa("Player") and LosSightedMixin.kPlayerCheckInterval[sighted] or LosSightedMixin.kOtherCheckInterval[sighted]
    LosSightedMixin.updateTable[self:GetId()] = Shared.GetTime() + timeToNextCheck + math.random() * 0.5
end


function LosSightedMixin.OnUpdateServer()
    if not LosSightedMixin.stopLosCalc then
        PROFILE("LosSightedMixin.OnUpdateServer")
        local now = Shared.GetTime()
        // we check every time in order to spread the los-load out as much as possible
        // Log("Update %s", LosSightedMixin.updateTable)
        for id, time in pairs(LosSightedMixin.updateTable) do
            if now >= time then
                local entity = Shared.GetEntity(id)
                if entity then
                    entity:UpdateSighted()
                else
                    LosSightedMixin.updateTable[id] = nil
                end 
            end
        end
    end
end


Event.Hook("UpdateServer", LosSightedMixin.OnUpdateServer)

