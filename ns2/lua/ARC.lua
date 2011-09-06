// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ARC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/mixins/ControllerMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FuryMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/TargetMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/HiveSightBlipMixin.lua")

class 'ARC' (ScriptActor)

ARC.kMapName = "arc"

ARC.kModelName = PrecacheAsset("models/marine/arc/arc.model")

// Animations
ARC.kMoveParam              = "move_speed"
ARC.kArcPitchParam          = "arc_pitch"
ARC.kArcYawParam            = "arc_yaw"
ARC.kMuzzleNode             = "fxnode_arcmuzzle"

// Balance
ARC.kHealth                 = kARCHealth
ARC.kStartDistance          = 4
ARC.kAttackInterval         = 8.0               // Must be greater than fireToHitInterval
ARC.kFireToHitInterval      = kARCFireDelay     // How long ARC must be on target before firing
ARC.kAttackDamage           = kARCDamage
ARC.kFireRange              = kARCRange         // From NS1
ARC.kSplashRadius           = 10
ARC.kUpgradedSplashRadius   = 13
ARC.kMoveSpeed              = 5.0               // units per second
ARC.kFov                    = 160    
ARC.kBarrelMoveRate         = 100
ARC.kMaxPitch               = 45
ARC.kMaxYaw                 = ARC.kFov/2
ARC.kCapsuleHeight = .05
ARC.kCapsuleRadius = .5
 

ARC.kMode = enum( {'UndeployedStationary', 'Moving', 'Deploying', 'Deployed', 'Targeting', 'Firing', 'FireCooldown', 'Undeploying', 'Destroyed'} )

if Server then
    Script.Load("lua/ARC_Server.lua")
end

ARC.networkVars =
{
    // ARCs can only fire when deployed and can only move when not deployed
    mode            = "enum ARC.kMode",
    desiredMode     = "enum ARC.kMode",
    
    barrelYawDegrees            = "compensated float",
    barrelPitchDegrees          = "compensated float",
    
    // So we can update angles and pose parameters smoothly on client
    targetDirection             = "vector",
}

PrepareClassForMixin(ARC, ControllerMixin)
PrepareClassForMixin(ARC, LiveMixin)
PrepareClassForMixin(ARC, UpgradableMixin)
PrepareClassForMixin(ARC, GameEffectsMixin)
PrepareClassForMixin(ARC, FuryMixin)
PrepareClassForMixin(ARC, FlinchMixin)
PrepareClassForMixin(ARC, OrdersMixin)
PrepareClassForMixin(ARC, FireMixin)

function ARC:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, ControllerMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FuryMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, OrdersMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, SelectableMixin)
    if Server then
        InitMixin(self, WeldableMixin)
        InitMixin(self, TargetMixin)
        InitMixin(self, LOSMixin)
        InitMixin(self, HiveSightBlipMixin)
    end
    
    // Create the controller for doing collision detection.
    self:CreateController(PhysicsGroup.CommanderUnitGroup)
    
end

function ARC:OnInit()

    ScriptActor.OnInit(self)
    
    
    self:SetModel(ARC.kModelName)
    
    if Server then
    
        self.targetSelector = TargetSelector():Init(
                self,
                ARC.kFireRange,
                false, 
                { kMarineStaticTargets, kMarineMobileTargets },
                { self.FilterTarget(self) })
                
        self:SetPhysicsType(PhysicsType.Kinematic)
                
        // Cannons start out mobile
        self:SetDesiredMode(ARC.kMode.UndeployedStationary)
        self:SetMode(ARC.kMode.UndeployedStationary)
     
    end
    
    self:SetUpdates(true)
    
end

// Required by ControllerMixin.
function ARC:GetControllerSize()
    return ARC.kCapsuleHeight, ARC.kCapsuleRadius
end

// Required by ControllerMixin.
function ARC:GetMovePhysicsMask()
    return PhysicsMask.Movement
end


function ARC:GetDeathIconIndex()
    return kDeathMessageIcon.ARC
end

function ARC:GetDeathIconIndex()
    return kDeathMessageIcon.ARC
end


/**
 * Put the eye up 1 m.
 */
function ARC:GetViewOffset()
    return self:GetCoords().yAxis * 1.0
end

function ARC:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset()
end

function ARC:PerformActivation(techId, position, normal, commander)

    if techId == kTechId.ARCDeploy then

        self:SetDesiredMode(ARC.kMode.Deployed)
        
        return true

    elseif techId == kTechId.ARCUndeploy then

        if self:GetTarget() ~= nil then
            self:CompletedCurrentOrder()
        end

        self.timeOfNextHit = nil
        
        self:SetDesiredMode(ARC.kMode.UndeployedStationary)

        return true

    end

    return false

end

function ARC:GetActivationTechAllowed(techId)

    if(techId == kTechId.ARCDeploy or techId == kTechId.Move) then
        return self.mode == ARC.kMode.UndeployedStationary or self.mode == ARC.kMode.Moving
    elseif(techId == kTechId.ARCUndeploy or techId == kTechId.Attack) then
        return self:GetInAttackMode()   
    elseif(techId == kTechId.Stop) then
        return self.mode == ARC.kMode.Moving or self.mode == ARC.kMode.Firing
    end

    return true

end

function ARC:GetTechButtons(techId)
    if techId == kTechId.RootMenu then
        if self:GetInAttackMode() then
            return  {   kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.ARCUndeploy, kTechId.None, kTechId.None, kTechId.None }
        else
            return  {   
                        kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.None,
                        kTechId.ARCDeploy, kTechId.None, kTechId.None, kTechId.None }
        end
    else
        return nil
    end
end

function ARC:GetStatusDescription()

    local desc = EnumToString(ARC.kMode, self.mode)
    
    return string.format("ARC - %s", desc), nil
    
end

function ARC:GetInAttackMode()
    return (self.mode == ARC.kMode.Deployed or self.mode == ARC.kMode.Firing or self.mode == ARC.kMode.Targeting or self.mode == ARC.kMode.FireCooldown) and self.desiredMode ~= ARC.kMode.UndeployedStationary
end

function ARC:GetCanGiveDamageOverride()
    return true
end

function ARC:GetFov()
    return ARC.kFov
end

function ARC:OnOverrideDoorInteraction(inEntity)   
    return true, 4
end

function ARC:GetCanIdle()
  if ((self.mode == ARC.kMode.Deployed or self.mode == ARC.kMode.UndeployedStationary) and self:GetIsAlive()) then    
    return true
  end
  
  return false
end

function ARC:GetEffectParams(tableParams)

    ScriptActor.GetEffectParams(self, tableParams)   
    tableParams[kEffectFilterDeployed] = (self.mode == ARC.kMode.Deployed)
    
end

function ARC:FilterTarget()
    local attacker = self
    return function (target, targetPosition) return attacker:GetCanFireAtTarget(target, targetPosition) end
end

function ARC:GetCanFireAtTarget(target, targetPoint)    

    if target == nil then        
        return false
    end
    
    if not target:GetIsAlive() then
        return false
    end
    
    if not (GetEnemyTeamNumber(self:GetTeamNumber()) == target:GetTeamNumber()) then        
        return false
    end
    
    if not target:isa("Structure") then      
        return false
    end
    
    if not target:GetIsSighted() then
        return false
    end
                    
    if (((target:GetOrigin() - self:GetOrigin()):GetLengthXZ() > ARC.kFireRange)) then        
        return false
    end
            
    return true
end

function ARC:UpdateAngles(deltaTime)
    if not self:GetInAttackMode() or (not self:GetIsAlive()) then
        return
    end
         
    if (self.mode == ARC.kMode.Firing or self.mode == ARC.kMode.Targeting or self.mode == ARC.kMode.FireCooldown) then        
        if self.targetDirection then
            local yawDiffRadians = GetAnglesDifference(GetYawFromVector(self.targetDirection), self:GetAngles().yaw)
            local yawDegrees = DegreesTo360(math.deg(yawDiffRadians))        
            self.desiredYawDegrees = Clamp(yawDegrees, -ARC.kMaxYaw, ARC.kMaxYaw)
            
            local pitchDiffRadians = GetAnglesDifference(GetPitchFromVector(self.targetDirection), self:GetAngles().pitch)
            local pitchDegrees = DegreesTo360(math.deg(pitchDiffRadians))
            self.desiredPitchDegrees = -Clamp(pitchDegrees, -ARC.kMaxPitch, ARC.kMaxPitch)       
            
            self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, ARC.kBarrelMoveRate*deltaTime)
        end
    elseif self.mode == ARC.kMode.Deployed or self.mode == ARC.kMode.Targeting then
        self.desiredYawDegrees = 0
        self.desiredPitchDegrees = 0
        
        self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, ARC.kBarrelMoveRate*deltaTime)
    end
    
        
    self.barrelPitchDegrees = Slerp(self.barrelPitchDegrees, self.desiredPitchDegrees, ARC.kBarrelMoveRate*deltaTime)
end

function ARC:UpdatePoseParameters(deltaTime)

    PROFILE("ARC:UpdatePoseParameters")
    
    self:SetPoseParam(ARC.kArcPitchParam, self.barrelPitchDegrees)
    self:SetPoseParam(ARC.kArcYawParam , self.barrelYawDegrees)
    
end

function ARC:OnUpdate(deltaTime)

   ScriptActor.OnUpdate(self, deltaTime)
   
   if Server then 
    self:UpdateOrders(deltaTime)    
    self:UpdateMode()
   end
   
   if self.mode ~= ARC.kMode.UndeployedStationary and self.mode ~= ARC.kMode.Moving and self.mode ~= ARC.kMode.Deploying and self.mode ~= ARC.kMode.Undeploying and self.mode ~= ARC.kMode.Destroyed then
    
    self:UpdateAngles(deltaTime)
   end
   
   self:UpdatePoseParameters(deltaTime)
   
end

function ARC:OnKill(damage, attacker, doer, point, direction)

    // HACK!
    self:TriggerEffects("arc_stop_effects")
    
    if Server then
    
        self:ClearTargetDirection()
        self:ClearOrders()
        
        self:SetDesiredMode(ARC.kMode.Destroyed)
        self:SetMode(ARC.kMode.Destroyed)
        
    end 
  
end

function ARC:GetVisualRadius()

    if self.mode == ARC.kMode.UndeployedStationary or self.mode == ARC.kMode.Moving then
        return nil
    end
    
    return ScriptActor.GetVisualRadius(self)
    
end

Shared.LinkClassToMap("ARC", ARC.kMapName, ARC.networkVars)
