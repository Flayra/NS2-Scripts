// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DetectableMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

DetectableMixin = { }
DetectableMixin.type = "Detectable"

DetectableMixin.expectedCallbacks =
{
    // Returns integer for team number
    GetTeamNumber = "",    
    OnDetectedChange = "Called when entering or entering range of detector, passing bool of new state",
    GetOrigin = "Entity origin (used to determine if near detector)",
}

// Should be bigger then DetectorMixin:kUpdateDetectionInterval
DetectableMixin.kResetDetectionInterval = .6

function DetectableMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "DetectableMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        // Used for limiting frequency of abilities
        detected                  = "boolean",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function DetectableMixin:GetIsDetected()
    return self.detected
end

function DetectableMixin:SetDetected(state)

    if state ~= self.detected then
    
        self.detected = state
        
        self:OnDetectedChange(state)

        if state then
            self.timeSinceDetection = 0
        end
        
    end
    
end

function DetectableMixin:__initmixin()

    self.detected = false
    self.timeSinceDetection = nil
    
end

function DetectableMixin:OnUpdate(deltaTime)

    if self.timeSinceDetection then
    
        self.timeSinceDetection = self.timeSinceDetection + deltaTime
        
        if self.timeSinceDetection >= DetectableMixin.kResetDetectionInterval then
        
            self:SetDetected(false)
            
        end
        
    end
    
end
