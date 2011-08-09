// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk_Client.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Skulk.kCameraRollSpeedModifier = 0.5
Skulk.kCameraRollTiltModifier = 0.05

function Skulk:UpdateMisc(input)

    Alien.UpdateMisc(self, input)
    
    if self.currentCameraRoll == nil then
        self.currentCameraRoll = 0
    end
    if self.goalCameraRoll == nil then
        self.goalCameraRoll = 0
    end
    
    self.currentCameraRoll = LerpGeneric(self.currentCameraRoll, self.goalCameraRoll, math.min(1, input.time * Skulk.kCameraRollSpeedModifier))

end

local gEnableTilt = true

// Tilt the camera based on the wall the Skulk is attached to.
function Skulk:PlayerCameraCoordsAdjustment(cameraCoords)

    if self.wallWalkingNormalCurrent and gEnableTilt then
        local viewModelTiltAngles = Angles()
        viewModelTiltAngles:BuildFromCoords(cameraCoords)
        // Don't rotate if too close to upside down (on ceiling).
        if math.abs(self.wallWalkingNormalCurrent:DotProduct(Vector.yAxis)) > 0.9 then
            self.goalCameraRoll = 0
        else
            local wallWalkingNormalCoords = BuildCoords(self.wallWalkingNormalCurrent, cameraCoords.zAxis)
            local wallWalkingRoll = Angles()
            wallWalkingRoll:BuildFromCoords(wallWalkingNormalCoords)
            wallWalkingRoll = wallWalkingRoll.roll
            self.goalCameraRoll = (wallWalkingRoll * Skulk.kCameraRollTiltModifier)
        end
        if self.currentCameraRoll then
            viewModelTiltAngles.roll = viewModelTiltAngles.roll + self.currentCameraRoll
        end
        local viewModelTiltCoords = viewModelTiltAngles:GetCoords()
        viewModelTiltCoords.origin = cameraCoords.origin
        return viewModelTiltCoords
    end
    return cameraCoords

end

function OnCommandSkulkViewTilt(enableTilt)

    gEnableTilt = enableTilt ~= "false"

end

Event.Hook("Console_skulk_view_tilt",   OnCommandSkulkViewTilt)