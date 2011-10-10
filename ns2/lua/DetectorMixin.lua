// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DetectorMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/NS2Utility.lua")
Script.Load("lua/Entity.lua")

DetectorMixin = { }
DetectorMixin.type = "Detector"

// Should be smaller then DetectableMixin:kResetDetectionInterval
DetectorMixin.kUpdateDetectionInterval = .5

DetectorMixin.expectedCallbacks =
{
    // Returns integer for team number
    GetTeamNumber = "",
    
    // Returns 0 if not active currently
    GetDetectionRange = "",
    
    GetOrigin = "Detection origin",
}

function DetectorMixin:__initmixin()
    self.timeSinceLastDetected = 0        
end

function DetectorMixin:OnUpdate(deltaTime)

    self.timeSinceLastDetected = self.timeSinceLastDetected + deltaTime
    
    if self.timeSinceLastDetected >= DetectorMixin.kUpdateDetectionInterval then
    
        self:PerformDetection()
    
        self.timeSinceLastDetected = self.timeSinceLastDetected - DetectorMixin.kUpdateDetectionInterval
        
    end
    
end

function DetectorMixin:PerformDetection()

    // Get list of Detectables in range
    local range = self:GetDetectionRange()
    
    if range > 0 then

        local teamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local origin = self:GetOrigin()    
        local detectables = GetEntitiesWithMixinForTeamWithinRange("Detectable", teamNumber, origin, range)
        
        for index, detectable in ipairs(detectables) do
        
            // Mark them as detected
            detectable:SetDetected(true)
        
        end
        
    end
    
end

