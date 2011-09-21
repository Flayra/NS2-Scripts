// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CamouflageMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//
// Have entities disappear if they have camouflage upgrade and are still.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

CamouflageMixin = { }
CamouflageMixin.type = "Camouflage"
CamouflageMixin.kVelocityThreshold = 1
CamouflageMixin.kBreakingDelay = 3

CamouflageMixin.expectedCallbacks = {
    GetVelocity = "Return vector representing velocity.",
    GetIsAlive = "Bool returning alive/dead",
    GetHasUpgrade = "Pass bit mask indicating upgrade, return true/false if entity has it",
}

function CamouflageMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "CamouflageMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        camouflaged = "boolean",
        timeLastUncamouflageTriggered = "float",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function CamouflageMixin:__initmixin()

    self.camouflaged = false
    self.timeLastUncamouflageTriggered = nil
    
end

function CamouflageMixin:GetIsCamouflaged()
    return self.camouflaged
end

function CamouflageMixin:TriggerUncamouflage()

    if self:GetIsCamouflaged() then
    
        self.camouflaged = false
        
    end
    // any action which would have broken camo blocks you from entering camo again for 
    self.timeLastUncamouflageTriggered = Shared.GetTime()
end

function CamouflageMixin:_UpdateCamouflage()

    // Have entities disappear if they have camouflage and are still
    local velocity = self:GetVelocity():GetLength()
    local currentTime = Shared.GetTime()
    
    if self:GetIsAlive() and self:GetHasUpgrade(kTechId.Camouflage) and velocity <= CamouflageMixin.kVelocityThreshold then
    
        // Won't set camouflaged if we recently attacked
        if (currentTime > (self.timeLastUncamouflageTriggered + CamouflageMixin.kBreakingDelay)) and (not self.camouflaged) then
            self.camouflaged = true
        end
        
    elseif velocity > CamouflageMixin.kVelocityThreshold then
    
        self:TriggerUncamouflage()
        
    end

end

function CamouflageMixin:OnUpdate(deltaTime)
    self:_UpdateCamouflage()
end

if Client then

    function CamouflageMixin:OnUpdateRender()

        PROFILE("CamouflageMixin:OnSynchronized")
    
        local newHiddenState = self:GetIsCamouflaged()
        if self.clientCamoed ~= newHiddenState then
        
            local isEnemy = GetEnemyTeamNumber(self:GetTeamNumber()) == Client.GetLocalPlayer():GetTeamNumber()
            self:TriggerEffects("client_cloak_changed", {cloaked = newHiddenState, enemy = isEnemy})
            self.clientCamoed = newHiddenState
            
        end
        
    end
    
end

//self.movementModiferState
function CamouflageMixin:GetCamouflageMaxSpeed(walking)

    if walking and HasMixin(self, "Camouflage") and self:GetIsCamouflaged() then
        return true, CamouflageMixin.kVelocityThreshold * .75
    end
    
    return false, nil
    
end

function CamouflageMixin:OnScan()
    self:TriggerUncamouflage()
end

function CamouflageMixin:PrimaryAttack()
    self:TriggerUncamouflage()
end

function CamouflageMixin:SecondaryAttack()
    self:TriggerUncamouflage()
end

function CamouflageMixin:OnTakeDamage(damage, attacker, doer, point)
    self:TriggerUncamouflage()
end

function CamouflageMixin:OnGetIsVisible(visibleTable, viewerTeamNumber)

    if self:GetIsCamouflaged() and viewerTeamNumber == GetEnemyTeamNumber(self:GetTeamNumber()) then
    
        visibleTable.Visible = false
        
    end

end
