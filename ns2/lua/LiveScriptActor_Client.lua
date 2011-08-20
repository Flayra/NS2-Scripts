// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function LiveScriptActor:OnTakeDamage(damage, attacker, doer, point)
end

function LiveScriptActor:OnKill(damage, attacker, doer, point, direction)
end

function LiveScriptActor:OnSynchronized()

    PROFILE("LiveScriptActor:OnSynchronized")

    ScriptActor.OnSynchronized(self)
    self:UpdateEffects()
    
end

// Display text when selected
function LiveScriptActor:GetCustomSelectionText()
    return ""
end
    
function LiveScriptActor:UpdateEffects()

    // Play on-fire cinematic every so often if we're on fire
    if self:GetGameEffectMask(kGameEffect.OnFire) and self:GetIsAlive() and self:GetIsVisible() then
    
        // If we haven't played effect for a bit
        local time = Shared.GetTime()
        
        if not self.timeOfLastFireEffect or (time > (self.timeOfLastFireEffect + .5)) then
        
            local firstPerson = (Client.GetLocalPlayer() == self)
            local cinematicName = GetOnFireCinematic(self, firstPerson)
            
            if firstPerson then
                local viewModel = self:GetViewModelEntity()
                if viewModel then
                    Shared.CreateAttachedEffect(self, cinematicName, viewModel, Coords.GetTranslation(Vector(0, 0, 0)), "", true, false)
                end
            else
                Shared.CreateEffect(self, cinematicName, self, self:GetAngles():GetCoords())
            end
            
            self.timeOfLastFireEffect = time
            
        end
        
    end
    
    // If our cloak state changes, all effects to change
    if HasMixin(self, "Cloakable") or HasMixin(self, "Camouflage") then
    
        if self.clientCloaked == nil then
            self.clientCloaked = false
        end
    
        local newHiddenState = (HasMixin(self, "Cloakable") and self:GetIsCloaked()) or (HasMixin(self, "Camouflage") and self:GetIsCamouflaged())
        if self.clientCloaked ~= newHiddenState then
        
            local isEnemy = GetEnemyTeamNumber(self:GetTeamNumber()) == Client.GetLocalPlayer():GetTeamNumber()
            self:TriggerEffects("client_cloak_changed", {cloaked = newHiddenState, enemy = isEnemy})
            self.clientCloaked = newHiddenState
            
        end
        
    end
    
end
