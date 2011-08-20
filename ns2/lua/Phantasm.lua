// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Phantasm.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable unit that mimics another unit. It is controlled by the Commander and does no 
// damage but appears to be real.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")

class 'Phantasm' (LiveScriptActor)

Phantasm.kMapName = "phantasm"

Phantasm.networkVars = {
    moveYaw                 = "float",
    // 0-1 scalar used to set move_speed model parameter according to how fast we recently moved
    moveSpeed               = "float",
    bodyPitch               = "float",    
    timeOfLastUpdate        = "float",
    moveSpeedParam          = "compensated float"
}

Phantasm.kMoveThinkInterval = .05

PrepareClassForMixin(Phantasm, GameEffectsMixin)
PrepareClassForMixin(Phantasm, FlinchMixin)

function Phantasm:GetTraceCapsule()
    
    local extents = self:GetExtents()
    local radius = extents.x
    
    if radius == 0 then
        Print("%s:GetTraceCapsule(): radius is 0.")
    end
    
    local height = (extents.y - radius) * 2
    
    return height, radius

end

function Phantasm:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    
    // Create the controller for doing collision detection.
    local height, radius = self:GetTraceCapsule()
    
    self:CreateController(PhysicsGroup.CommanderUnitGroup, height, radius)
    
end

function Phantasm:OnInit()
    
    self:SetPhysicsType(Actor.PhysicsType.Kinematic)

    LiveScriptActor.OnInit(self)
    
    self.moveYaw = 0
    self.moveSpeed = 0
    self.bodyPitch = 0
    
    self.timeOfLastUpdate = 0
    self.moveSpeedParam = 0

    if(Server) then
    
        self:SetNextThink(Phantasm.kMoveThinkInterval)
        
        self:SetUpdates(true)
        
    end
    
    self:UpdateControllerFromEntity()
        
end

function Phantasm:GetHoverHeight()
    return 0
end

function Phantasm:GetOrderedSoundName()
    return ""
end

function Phantasm:GetAttackSoundName()
    return ""
end

function Phantasm:OnOrderChanged()
    
    self:SetNextThink(Phantasm.kMoveThinkInterval)
    
    self:PlaySound(self:GetOrderedSoundName())
        
end

function Phantasm:OnOverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // If target is enemy, attack it
    if (order:GetType() == kTechId.Default) then

        if orderTarget ~= nil and orderTarget:isa("LiveScriptActor") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() then
            order:SetType(kTechId.Attack)
        else
            order:SetType(kTechId.Move)
        end
        
    end
    
end

function Phantasm:PlayMeleeHitEffects(target, point, direction)
    Shared.PlayWorldSound(nil, self:GetAttackSoundName(), nil, point)
end

function Phantasm:GetMoveSpeed()
    return GetDevScalar(3, 8)
end

function Phantasm:GetMaxMoveSpeed()
    return GetDevScalar(3, 8)
end

function Phantasm:GetMoveAnimation()
    return ""
end

function Phantasm:UpdatePoseParameters(deltaTime)
    
    PROFILE("Phantasm:UpdatePoseParameters")

    local currentOrder = self:GetCurrentOrder()
    if( currentOrder ~= nil ) then
    
        local moveSpeed = self:GetMoveSpeed()
        
        local currentOrigin = Vector(self:GetOrigin())
        
        if(currentOrder:GetType() == kTechId.Move) then

            self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), moveSpeed, Phantasm.kMoveThinkInterval)
            
            if(self:IsTargetReached(currentOrder:GetLocation(), kEpsilon)) then
                self:CompletedCurrentOrder()
            end
            
        elseif(currentOrder:GetType() == kTechId.Attack) then
        
            self:ProcessAttackOrder(1, 5, moveSpeed, Phantasm.kMoveThinkInterval)
            
        end                        
        
        // Check difference in location to set moveSpeed
        local distanceMoved = (self:GetOrigin() - currentOrigin):GetLength()
        
        local moveSpeed = distanceMoved / Phantasm.kMoveThinkInterval
        
        local velocity = Vector(0, 0, 0)
        if distanceMoved > .01 then
            velocity = GetNormalizedVector(self:GetOrigin() - currentOrigin) * moveSpeed
        end
        Print("Distance moved: %.2f, velocity length: %.2f, moveSpeed: %.2f", distanceMoved, velocity:GetLength(), moveSpeed)
        
        if moveSpeed == 0 then
            Print("OnIdle(%s)", self:GetMoveAnimation())
            self:OnIdle()
        else
            Print("SetAnimation(%s)", self:GetMoveAnimation())
            self:SetAnimation(self:GetMoveAnimation())
        end
        
        Print("Velocity: %s", ToString(velocity))
        local angles = Angles(self:GetAngles())
        SetPlayerPoseParameters(self, angles, velocity, self:GetMaxMoveSpeed(), Player.kWalkBackwardSpeedScalar, 0)   
        
    end
    
end

if Server then
function Phantasm:SetPoseParam(name, value)

    LiveScriptActor.SetPoseParam(self, name, value)
    
    // Propagate to client 
    if name == "move_yaw" then
        if value > 0 then
            Print("Set self.moveYaw to %.2f", value)
        end
        self.moveYaw = value
    elseif name == "move_speed" then
        Print("Set self.moveSpeed to %.2f", value)
        self.moveSpeed = value
    elseif name == "body_pitch" then
        self.bodyPitch = value
    end
    
end
end

if Client then
    function Phantasm:OnSynchronized()

        PROFILE("Phantasm:OnSynchronized")
        
        LiveScriptActor.OnSynchronized(self)
        
        self:SetPoseParam("move_yaw", self.moveYaw)
        self:SetPoseParam("move_speed", self.moveSpeed)
        self:SetPoseParam("body_pitch", self.bodyPitch)
        
    end
end

function Phantasm:OnUpdate(deltaTime)

    LiveScriptActor.OnUpdate(self, deltaTime)

    // Pose paramters calculated on server from current order
    if Server and not Shared.GetIsRunningPrediction() then
        self:UpdatePoseParameters(deltaTime)
    end
    
    self:UpdateControllerFromEntity()
    
    self.timeOfLastUpdate = Shared.GetTime()
    
end

Shared.LinkClassToMap("Phantasm", Phantasm.kMapName, Phantasm.networkVars)
