// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerMixin.lua
//
//    Created by: Andrew Spiering (andrew@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PowerManager.lua")

PowerMixin = { }
PowerMixin.type = "Power"


// This is needed so alien structures can be cloaked, but not marine structures
PowerMixin.expectedCallbacks = {
    GetRequiresPower = "Return true/false if this object requires power",    
}

function PowerMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "PowerMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        powered = "boolean",
        powerSource  = "boolean",            
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function PowerMixin:__initmixin()
    self.powered = false
    self.powerSource = false  
end

function PowerMixin:OnInit()
    
    // On the server we register this object to care about these two power events which they will 
    // get callbacks for.
    if Server and self:GetRequiresPower() then
        GetPowerManager():RegisterPowerEvent(self, PowerManager.kPowerOffEvent)
        GetPowerManager():RegisterPowerEvent(self, PowerManager.kPowerOnEvent)
    end
      
end

function PowerMixin:OnDestroy()
        // On the server we register this object to care about these two power events which they will 
    // get callbacks for.
    if Server and self:GetRequiresPower() then
        GetPowerManager():UnRegisterPowerEvent(self, PowerManager.kPowerOffEvent)
        GetPowerManager():UnRegisterPowerEvent(self, PowerManager.kPowerOnEvent)
    end

end

function PowerMixin:UpdatePowerState()
    if Server then
        if (self.GetUpdatePower and self:GetUpdatePower()) then
            // Check if the location has power the second param is whether to send a
            // power event or not. 
            GetPowerManager():GetIsLocationPowered(self, true)        
        end
    end
end

function PowerMixin:SetPowerState(state)
    self.powered = state
end

function PowerMixin:GetIsPowered()
    local isPowered = true
    
    if (self.GetIsPoweredOverride) then
        isPowered = self:GetIsPoweredOverride()
    end
    
    return (self.powered and isPowered) or self:GetIsPowerSource()
end

function PowerMixin:SetIsPowerSource(source)
    self.powerSource = source
 
    if Server then
        // Update the PowerCells in the PowerManager and send events based on source status
        GetPowerManager():UpdatePowerCells(self, source, self:GetOrigin(), self.powerRadius, true)
    end
end

function PowerMixin:OnConstructionComplete()    
    if (self:GetRequiresPower()) then
        self:UpdatePowerState()
    end        
end

function PowerMixin:GetIsPowerSource()
    return self.powerSource
end

function PowerMixin:OnPowerOnEvent(event)
    local setPower = true
   
    if (self.SetPowerOn and (not self:GetIsPowered())) then
        setPower = self:SetPowerOn()
    end
    
    if setPower then
        self:SetPowerState(true)
    end    
end

function PowerMixin:OnPowerOffEvent(event)
    local setPower = true
    
    if (self.SetPowerOff and self:GetIsPowered()) then
       setPower = self:SetPowerOff()
    end
    
    if setPower then
       self:SetPowerState(false)
    end    
end