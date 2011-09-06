// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sentry.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'Sentry' (Structure)

Sentry.kMapName = "sentry"

if(Server) then
    Script.Load("lua/Sentry_Server.lua")
end

Sentry.kModelName = PrecacheAsset("models/marine/sentry/sentry.model")

Sentry.kSpinUpSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_spin_up")
Sentry.kSpinDownSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_spin_down")
Sentry.kAttackSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_fire_loop")

Sentry.kSentryScanSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/sentry_scan")
Sentry.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_taking_damage")
Sentry.kFiringAlertSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_firing")
Sentry.kRicochetMaterialSound = "sound/ns2.fev/materials/%s/ricochet"

// New effects
Sentry.kFireEffect = PrecacheAsset("cinematics/marine/sentry/fire.cinematic")
Sentry.kBarrelSmokeEffect = PrecacheAsset("cinematics/marine/sentry/muzzle_smoke.cinematic")

Sentry.kFireShellEffect = PrecacheAsset("cinematics/marine/sentry/fire_shell.cinematic")
//Sentry.kTracerEffect = PrecacheAsset("cinematics/marine/tracer.cinematic")

Sentry.kRicochetEffect = "cinematics/materials/%s/ricochet.cinematic"

PrecacheMultipleAssets(Sentry.kRicochetMaterialSound, kSurfaceList)
PrecacheMultipleAssets(Sentry.kRicochetEffect, kSurfaceList)

// Balance
Sentry.kPingInterval = 4
Sentry.kFov = 160
Sentry.kMaxPitch = 45
Sentry.kMaxYaw = Sentry.kFov / 2

Sentry.kBaseROF = kSentryAttackBaseROF
Sentry.kRandROF = kSentryAttackRandROF
Sentry.kSpread = Math.Radians(3)
Sentry.kBulletsPerSalvo = kSentryAttackBulletsPerSalvo
Sentry.kDamagePerBullet = kSentryAttackDamage
Sentry.kBarrelScanRate = 60      // Degrees per second to scan back and forth with no target
Sentry.kBarrelMoveRate = 150     // Degrees per second to move sentry orientation towards target or back to flat when targeted
Sentry.kTargetCheckTime = .3
Sentry.kRange = 20
Sentry.kReorientSpeed = .05
// Don't choose new target right away, to make sure multiple attacks can overwhelm sentry
Sentry.kTargetReacquireTime = .5
Sentry.kInitialAmmo = 250
Sentry.kMaxAmmo = 250
Sentry.kAmmoPerRefill = 250

// Animations
Sentry.kDeathAnimTable = {/*{1.0, "death"},*/ {1.0, "death2"}}
Sentry.kFlinchAnim = "flinch"
Sentry.kFlinchBigAnim = "flinch_big"
Sentry.kAttackStartAnim = "attack_start"
Sentry.kAttackAnim = "attack"
Sentry.kAttackEndAnim = "attack_end"
Sentry.kYawPoseParam = "sentry_yaw" // Sentry yaw pose parameter for aiming
Sentry.kPitchPoseParam = "sentry_pitch"
Sentry.kMuzzleNode = "fxnode_sentrymuzzle"
Sentry.kEyeNode = "fxnode_eye"

Sentry.kMode = enum( {'Unbuilt', 'PoweredDown', 'PoweringUp', 'PoweringDown', 'Scanning', 'SpinningUp', 'Attacking', 'SpinningDown', 'SettingTarget'} )

local networkVars = {

    mode                        = "enum Sentry.kMode",
    desiredMode                 = "enum Sentry.kMode",

    barrelYawDegrees            = "float",
    barrelPitchDegrees          = "float",
    
    // So we can update angles and pose parameters smoothly on client
    targetDirection             = "vector",  
    
    // For debugging
    //relativeTargetDirection     = "vector",    
   
    ammo                        = string.format("integer (0 to %d", Sentry.kMaxAmmo)
    
}

function Sentry:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)
    
    self.desiredYawDegrees = 0
    self.desiredPitchDegrees = 0    
    self.barrelYawDegrees = 0
    self.barrelPitchDegrees = 0
    self.playingAttackSound = false
    
    self.timeLastScanSound = 0
    
    self.scanStartDegrees = 0
    
    self.timeOfLastTargetAcquisition = 0
    
    self.scanTime = nil
    
    self.mode = Sentry.kMode.Unbuilt
    self.desiredMode = Sentry.kMode.Unbuilt
    
    self.timeOfLastUpdate = Shared.GetTime()
    
    // Ammo and max ammo
    self.ammo = Sentry.kInitialAmmo
    
end

function Sentry:GetAmmo()
    return self.ammo
end

function Sentry:GetMaxAmmo()
    return Sentry.kMaxAmmo
end

if (Client) then

    function Sentry:OnDestroy()
        self:StopSound(Sentry.kAttackSoundName)
        Structure.OnDestroy(self)
    end
    
end

function Sentry:OnInit()
    Structure.OnInit(self)
    self:SetUpdates(true)
    
    if Server then 
        // configure how targets are selected and validated
        self.targetSelector = TargetSelector():Init(
            self,
            Sentry.kRange, 
            true,
            { kMarineStaticTargets, kMarineMobileTargets },
            { PitchTargetFilter(self,  -Sentry.kMaxPitch, Sentry.kMaxPitch), CloakTargetFilter(), CamouflageTargetFilter() })
    end
end

function Sentry:GetSentryMode()
    return self.mode
end

function Sentry:GetFov()
    return Sentry.kFov
end

function Sentry:GetEyePos()
    return self:GetAttachPointCoords(Sentry.kMuzzleNode).origin
end

// Show ammo in commander HUD if active
function Sentry:GetStatusDescription()
    local text, scalar = Structure.GetStatusDescription(self)
    if text == nil then
        text = string.format("%d / %d rounds", self.ammo, Sentry.kMaxAmmo)
        scalar = self.ammo / Sentry.kMaxAmmo
    end
    return text, scalar
end

/**
 * Fire out out muzzle attach point.
 */
function Sentry:GetViewOffset()

    // Great idea .. but it doesn't quite work - the eyepos being offset from the
    // center of the scan means that sometimes the sensor will see a target and
    // sometimes not. An alien placing itself at the edge of the fov would be a valid 
    // target when the barrel faces in the middle, but become invalid when it faces
    // the alien. To solve it would reqire the introduction of a field-of-fire for the
    // gun itself, while the field-of-view belonged to the sensor.
    // Too much work, and the simple fix is to move the eye to the center of rotation. 
    // return self:GetAttachPointOrigin(Sentry.kEyeNode)
    // ... and this doesn't work either ... the height of the eyenode drops down when the barrel elevates, thus
    // lowering the sentry eyepos.
    // lets go for a hack: manually measusured; height of muzzle when at zero pitch is at 1.0162.
    // note: the caching here assumes that you don't change the origin of the sentry
    return Vector(0, 1.0162, 0)
    
end

function Sentry:GetDeathIconIndex()
    return kDeathMessageIcon.Sentry
end

function Sentry:GetRequiresPower()
    return true
end

function Sentry:GetCanIdle()
    return self:GetSentryMode() == Sentry.kMode.Scanning
end

function Sentry:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then 

        return { 
            kTechId.Attack, kTechId.Stop, kTechId.SetTarget, kTechId.None,
            kTechId.SentryRefill, kTechId.None, kTechId.None, kTechId.None 
            }
    end
    
    return nil
    
end

function Sentry:GetTechAllowed(techId, techNode, player)
    if techId == kTechId.SentryRefill then
        return self.ammo < Sentry.kMaxAmmo
    // Don't allow sentry refilling to be cancelled (add this later if it stays, but Structure:AbortResearch() assumes team resources refund)
    elseif techId == kTechId.Cancel then
        return false
    end
    return Structure.GetTechAllowed(self, techId, techNode, player)
end

function Sentry:UpdateAngles(deltaTime)
    
    // Swing barrel yaw towards target        
    if (self:GetSentryMode() == Sentry.kMode.Attacking) then
    
        if self.targetDirection then
        
            local invSentryCoords = self:GetAngles():GetCoords():GetInverse()
            self.relativeTargetDirection = GetNormalizedVector( invSentryCoords:TransformVector( self.targetDirection ) )
            self.desiredYawDegrees = Clamp( math.asin(-self.relativeTargetDirection.x) * 180 / math.pi, -Sentry.kMaxYaw, Sentry.kMaxYaw)            
            self.desiredPitchDegrees = Clamp( math.asin(self.relativeTargetDirection.y) * 180 / math.pi, -Sentry.kMaxPitch, Sentry.kMaxPitch)       

            self.scanTime = nil
            self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, Sentry.kBarrelMoveRate*deltaTime)
            
        end
        
    // Else when we have no target, swing it back and forth looking for targets
    else
    
        if(self.scanTime == nil) then
            self.scanStartDegrees = 0
            self.barrelYawDegrees = self:GetPoseParam(Sentry.kYawPoseParam)                
            self.scanTime = 0
        else
            self.scanTime = self.scanTime + deltaTime
        end
        
        local sin = math.sin(math.rad(self.scanStartDegrees + self.scanTime*Sentry.kBarrelScanRate))
        self.barrelYawDegrees = sin * self:GetFov() / 2
        
        // Swing barrel pitch back to flat
        self.desiredPitchDegrees = 0
    
    end
    
    // No matter what, swing barrel pitch towards desired pitch
    self.barrelPitchDegrees = Slerp(self.barrelPitchDegrees, self.desiredPitchDegrees, Sentry.kBarrelMoveRate*deltaTime)    
    
end

function Sentry:GetIsFunctioning()
    return self:GetIsAlive() and self:GetIsBuilt() and self:GetIsActive() and self:GetAmmo() > 0
end

function Sentry:GetAttackOrigin()
    return self:GetAttachPointOrigin(Sentry.kMuzzleNode)    
end

function Sentry:OnUpdate(deltaTime)

    PROFILE("Sentry:OnUpdate")

    Structure.OnUpdate(self, deltaTime)
    
    if self:GetIsFunctioning() then
    
        if Server then
        
            // Handle sentry state changes
            self:UpdateMode(deltaTime)

            self:UpdateAttack(deltaTime)    
            
        end

        // Update barrel position    
        local mode = self:GetSentryMode()
        
        if mode == Sentry.kMode.Scanning or mode == Sentry.kMode.SpinningUp or mode == Sentry.kMode.SpinningDown or mode == Sentry.kMode.Attacking then
            self:UpdateAngles(deltaTime)
        end
        
        /* Draw direction we're shooting */
        /*
        if Client then
        
            local direction = self:GetAttachPointCoords(Sentry.kMuzzleNode).xAxis 
            DebugLine(self:GetAttackOrigin(), self:GetAttackOrigin() + direction * 10, .1, 1, 0, 0, 1)
            
            if self.targetDirection then
                DebugLine(self:GetAttackOrigin(), self:GetAttackOrigin() + self.targetDirection * 10, .1, 1, 1, 1, 1)
            end

            if self.relativeTargetDirection then
                local worldRelativeTargetDirection = self:GetAngles():GetCoords():TransformVector(self.relativeTargetDirection)
                DebugLine(self:GetAttackOrigin(), self:GetAttackOrigin() + worldRelativeTargetDirection* 15, .1, 0, 1, 0, 1)
            end
            
        end
        */
        
    end
    
    self:UpdatePoseParameters(deltaTime)
    
    self.timeOfLastUpdate = self.timeOfLastUpdate + deltaTime
    
end

function Sentry:UpdatePoseParameters(deltaTime)

    PROFILE("Sentry:UpdatePoseParameters")
    
    self:SetPoseParam(Sentry.kPitchPoseParam, self.barrelPitchDegrees)
    self:SetPoseParam(Sentry.kYawPoseParam, self.barrelYawDegrees)
    
end

function Sentry:GetCanGiveDamageOverride()
    return true
end


Shared.LinkClassToMap("Sentry", Sentry.kMapName, networkVars)