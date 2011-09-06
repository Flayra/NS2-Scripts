// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CameraHolderMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

// The CameraHolderMixin provides first person camera controls and camera setup.

// The mixin will also register a "thirdperson" console command which can be used when cheats are
// enabled to switch to a third person camera. 

Script.Load("lua/Vector.lua")
Script.Load("lua/Utility.lua")

CameraHolderMixin = { }
CameraHolderMixin.type = "CameraHolder"

CameraHolderMixin.expectedCallbacks = {
    GetViewOffset = "Should return a Vector object representing where the camera is attached in relation to the Entity's Origin.",
    GetMaxViewOffsetHeight = "Should return the distance above the origin where the view is located", }

CameraHolderMixin.optionalCallbacks = {
    GetCameraViewCoordsOverride = "Overrides the GetCameraViewCoords() function completely." }

CameraHolderMixin.expectedConstants = {
    kFov = "The default field of view." }

function CameraHolderMixin.__prepareclass(toClass)

    ASSERT(toClass.networkVars ~= nil, "BaseMoveMixin expects the class to have network fields")
    
    local addNetworkFields =
    {

        fov             = "integer (0 to 180)", // In degrees.
        
        viewYaw         = "compensated interpolated angle",
        viewPitch       = "compensated interpolated angle",
        viewRoll        = "compensated interpolated angle",
        
        // Player prediction relies on these, so we network at full precision
        // so that the server and client don't have slightly different values
        // due to quantization.
        basePitch       = "compensated float",
        baseRoll        = "compensated float",
        baseYaw         = "compensated float",
        
        // Third person support
        cameraDistance          = "float",
        desiredCameraDistance   = "float",
        thirdPerson             = "boolean",   
     
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function CameraHolderMixin:__initmixin()

    self.fov = self:GetMixinConstants().kFov

    self.cameraDistance         = 0
    self.desiredCameraDistance  = 0
    self.thirdPerson            = false

end

function CameraHolderMixin:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset()
end
AddFunctionContract(CameraHolderMixin.GetEyePos, { Arguments = { "Entity" }, Returns = { "Vector" } })

function CameraHolderMixin:GetCameraViewCoords()

    local viewCoords = self:GetViewAngles():GetCoords()
    viewCoords.origin = self:GetEyePos()

    // Adjust for third person
    if self.cameraDistance ~= 0 then
        viewCoords.origin = viewCoords.origin - viewCoords.zAxis * self.cameraDistance
    end
    
    if self.GetCameraViewCoordsOverride then
        return self:GetCameraViewCoordsOverride(viewCoords)
    end
    
    return viewCoords
    
end
AddFunctionContract(CameraHolderMixin.GetCameraViewCoords, { Arguments = { "Entity" }, Returns = { "Coords" } })

function CameraHolderMixin:GetRenderFov()

    // Convert degree to radians.
    return math.rad(self:GetFov())

end
AddFunctionContract(CameraHolderMixin.GetRenderFov, { Arguments = { "Entity" }, Returns = { "number" } })

function CameraHolderMixin:SetFov(fov)
    self.fov = fov
end
AddFunctionContract(CameraHolderMixin.SetFov, { Arguments = { "Entity", "number" }, Returns = { } })

function CameraHolderMixin:GetFov()
    return self.fov
end
AddFunctionContract(CameraHolderMixin.GetFov, { Arguments = { "Entity" }, Returns = { "number" } })

function CameraHolderMixin:GetViewAngles()
    return Angles(self.viewPitch, self.viewYaw, self.viewRoll)
end
AddFunctionContract(CameraHolderMixin.GetViewAngles, { Arguments = { "Entity" }, Returns = { "Angles" } })

/**
 * Sets the view angles for the player. Note that setting the yaw of the
 * view will also adjust the player's yaw.
 */
function CameraHolderMixin:SetViewAngles(viewAngles)

    self.viewYaw   = viewAngles.yaw + self.baseYaw
    self.viewPitch = viewAngles.pitch + self.basePitch
    self.viewRoll  = viewAngles.roll + self.baseRoll

    local angles = Angles(self:GetAngles())
    angles.yaw  = self.viewYaw

    self:SetAngles(angles)

end

function CameraHolderMixin:SetOffsetAngles(offsetAngles)

    self:SetBaseViewAngles(offsetAngles)       
    self:SetViewAngles(Angles(0, 0, 0))
    self:SetAngles(Angles(0, offsetAngles.yaw, 0))

    if Server then
        Server.SendNetworkMessage(self, "ResetMouse", {}, true)
    else
        Client.SetPitch(0)
        Client.SetYaw(0)
    end

end

function CameraHolderMixin:SetBaseViewAngles(viewAngles)

    self.baseYaw = viewAngles.yaw
    // Adjusting the base pitch and roll is not desirable.
    // It ends up putting the player into a state where their camera goes upside
    // down and rolls around at weird angles relative to their mouse input.
    // I can't imagine a case where this would be wanted.
    self.basePitch = 0
    self.baseRoll = 0
    
end

/**
 * Whenever view angles are needed this function must be called
 * to compute them.
 */
function CameraHolderMixin:ConvertToViewAngles(forPitch, forYaw, forRoll)
    return Angles(forPitch + self.basePitch, forYaw + self.baseYaw, forRoll + self.baseRoll)
end

function CameraHolderMixin:SetDesiredCameraDistance(distance)
    self.desiredCameraDistance = math.max(distance, 0)
    self.thirdPerson = ((self.desiredCameraDistance > 0) or (self.cameraDistance > 0))
end

function CameraHolderMixin:SetCameraDistance(distance)
    self.cameraDistance = math.max(distance, 0)
    self.thirdPerson = ((self.desiredCameraDistance > 0) or (self.cameraDistance > 0))
end

function CameraHolderMixin:GetCameraDistance()
    return self.cameraDistance
end

function CameraHolderMixin:GetIsThirdPerson()
    return self.thirdPerson
end

// Set to 0 to get out of third person
function CameraHolderMixin:SetIsThirdPerson(distance)
    self:SetDesiredCameraDistance(distance)
end

function CameraHolderMixin:UpdateCamera(timePassed)
    
    if self.cameraDistance ~= self.desiredCameraDistance then
    
        local diff = (self.desiredCameraDistance - self.cameraDistance)
        local change = ConditionalValue(GetSign(diff) > 0, 10 * timePassed, -16 * timePassed)
        
        local newCameraDistance = self.cameraDistance + change
        
        if math.abs(diff) < math.abs(change) then
            newCameraDistance = self.desiredCameraDistance
        end

        self:SetCameraDistance(newCameraDistance)
        
    end
    
end

function CameraHolderMixin:OnProcessMove(input)
    self:UpdateCamera(input.time)
end

if Server then

    local function OnCommandThirdperson(client, distance)

        if client ~= nil and Shared.GetCheatsEnabled() then
        
            local player = client:GetControllingPlayer()
            
            if player ~= nil and HasMixin(player, "CameraHolder") then
        
                local numericDistance = 3
                if distance ~= nil then
                    numericDistance = tonumber(distance)
                elseif player:GetIsThirdPerson() then
                    numericDistance = 0
                end
                
                player:SetIsThirdPerson(numericDistance)
            
            end
            
        end
        
    end

    Event.Hook("Console_thirdperson", OnCommandThirdperson)
    
end