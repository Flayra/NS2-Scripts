// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CloakableMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

CloakableMixin = { }
CloakableMixin.type = "Cloakable"

// This is needed so alien structures can be cloaked, but not marine structures
CloakableMixin.expectedCallbacks = {
    GetIsCloakable = "Return true/false if this object can be cloaked.",
    GetTeamNumber = "Gets team number",
}

function CloakableMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "CloakableMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        cloaked = "boolean",
        timeOfCloak = "float",
        cloakChargeTime = "float",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function CloakableMixin:__initmixin()
    self.cloaked = false
    self.timeOfCloak = nil
    self.cloakChargeTime = 0
    self.cloakTime = nil
end

function CloakableMixin:SetIsCloaked(state, cloakTime, force)

    ASSERT(type(state) == "boolean")
    ASSERT(not state or type(cloakTime) == "number")
    ASSERT(not state or (cloakTime > 0))
    
    if self:GetIsCloakable() and self.cloaked ~= state then        
        // Can't cloak if we recently attacked, unless forced
        if (not state or self:GetChargeTime() == 0 or force) then
        
            self.cloaked = state
            
            if self.cloaked then
            
                self.timeOfCloak = Shared.GetTime()
                if cloakTime then
                    self.cloakTime = cloakTime
                end
                
            else
            
                self.timeOfCloak = nil
                self.cloakTime = nil
                
            end
            
        end
            
    end
    
end

function CloakableMixin:_UpdateCloakState()

    local currentTime = Shared.GetTime()
    if self.cloaked and (self.cloakTime ~= nil and (currentTime > self.timeOfCloak + self.cloakTime)) then
    
        self:SetIsCloaked(false)
        
    end
    
end

function CloakableMixin:GetIsCloaked()
    ASSERT(type(self.cloaked) == "boolean")
    return self.cloaked
end

function CloakableMixin:GetTimeOfCloak()
    return self.timeOfCloak
end

function CloakableMixin:TriggerUncloak()

    if self:GetIsCloaked() then
        self:SetIsCloaked(false)                
    end

    // Whenever we Trigger and Uncloak we are charged a little time
    self:AddCloakChargeTime(3)
end

function CloakableMixin:GetChargeTime()
  return self.cloakChargeTime
end

function CloakableMixin:AddCloakChargeTime(value)
  self.cloakChargeTime = math.max(self.cloakChargeTime + value, 0)   
end

function CloakableMixin:OnUpdate(deltaTime)
    self:_UpdateCloakState()
    
    self:AddCloakChargeTime(-1)    
end

if Client then

    function CloakableMixin:OnUpdateRender()

        PROFILE("CloakableMixin:OnUpdateRender")
    
        local newHiddenState = self:GetIsCloaked()
        if self.clientCloaked ~= newHiddenState then
        
            if self.clientCloaked ~= nil then
                local isEnemy = GetEnemyTeamNumber(self:GetTeamNumber()) == Client.GetLocalPlayer():GetTeamNumber()
                self:TriggerEffects("client_cloak_changed", {cloaked = newHiddenState, enemy = isEnemy})
            end
            self.clientCloaked = newHiddenState
            
        end
        
    end
    
end

function CloakableMixin:OnScan()
    self:TriggerUncloak()
end

function CloakableMixin:OnGetIsVisible(visibleTable, viewerTeamNumber)

    if self:GetIsCloaked() and viewerTeamNumber == GetEnemyTeamNumber(self:GetTeamNumber()) then
    
        visibleTable.Visible = false
        
    end

end

function CloakableMixin:PrimaryAttack()
    self:TriggerUncloak()
end

function CloakableMixin:SecondaryAttack()
    self:TriggerUncloak()
end

function CloakableMixin:OnTakeDamage(damage, attacker, doer, point)
    self:TriggerUncloak()
end