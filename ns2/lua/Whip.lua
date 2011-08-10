// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Whip.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides attacks nearby players with area of effect ballistic attack.
// Also gives attack/hurt capabilities to the commander. Range should be just shorter than 
// marine sentries.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/InfestationMixin.lua")

class 'Whip' (Structure)

PrepareClassForMixin(Whip, InfestationMixin)

Whip.kMapName = "whip"

Whip.kModelName = PrecacheAsset("models/alien/whip/whip.model")

Whip.kScanThinkInterval = .3
Whip.kROF = 2.0
Whip.kFov = 360
Whip.kTargetCheckTime = .3
Whip.kRange = 6
Whip.kAreaEffectRadius = 3
Whip.kDamage = 50
Whip.kMoveSpeed = 1.2

// Fury
Whip.kFuryRadius = 6
Whip.kFuryDuration = 6
Whip.kFuryDamageBoost = .1          // 10% extra damage

// Movement state - for uprooting and moving!
Whip.kMode = enum( {'Rooted', 'Unrooting', 'UnrootedStationary', 'Rooting', 'StartMoving', 'Moving', 'EndMoving'} )

local networkVars =
{
    attackYaw = "integer (0 to 360)",
    
    mode = "enum Whip.kMode",
    desiredMode = "enum Whip.kMode",
}

if Server then
    Script.Load("lua/Whip_Server.lua")
end

function Whip:OnCreate()

    Structure.OnCreate(self)
    
    self.attackYaw = 0
    
    self.mode = Whip.kMode.Rooted
    self.desiredMode = Whip.kMode.Rooted
    self.modeAnimation = ""
    
end

function Whip:OnInit()

    InitMixin(self, DoorMixin)
    InitMixin(self, InfestationMixin)   
    
    Structure.OnInit(self)
    self:SetUpdates(true)
 
    if Server then    
        self.targetSelector = TargetSelector():Init(
                self,
                Whip.kRange,
                true, 
                { kAlienStaticTargets, kAlienMobileTargets })      
    end
   
end

// Used for targeting
function Whip:GetFov()
    return Whip.kFov
end
/**
 * Put the eye up roughly 180 cm.
 */
function Whip:GetViewOffset()
    return self:GetCoords().yAxis * 1.8
end

function Whip:GetIsAlienStructure()
    return true
end

function Whip:GetDeathIconIndex()
    return kDeathMessageIcon.Whip
end

function Whip:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.UpgradesMenu, kTechId.WhipFury, kTechId.None, kTechId.Attack }
        
        // Allow structure to be ugpraded to mature version
        local upgradeIndex = table.maxn(techButtons) + 1
        
        if(self:GetTechId() == kTechId.Whip) then
            techButtons[upgradeIndex] = kTechId.UpgradeWhip
        else
            techButtons[upgradeIndex] = kTechId.WhipBombard
        end
        
        local rootActionIndex = table.maxn(techButtons) + 1
        if self.mode == Whip.kMode.Rooted then
            techButtons[rootActionIndex] = kTechId.WhipUnroot
        elseif self.mode == Whip.kMode.UnrootedStationary or self.mode == Whip.kMode.StartMoving or self.mode == Whip.kMode.Moving or self.mode == Whip.kMode.EndMoving then
            techButtons[rootActionIndex] = kTechId.WhipRoot
        end
       
    elseif(techId == kTechId.UpgradesMenu) then 
        techButtons = {kTechId.Melee1Tech, kTechId.Melee2Tech, kTechId.Melee3Tech, kTechId.None, kTechId.FrenzyTech, kTechId.SwarmTech, kTechId.BileBombTech }
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
    end
    
    return techButtons
    
end

function Whip:GetActivationTechAllowed(techId)

    if techId == kTechId.WhipRoot then
        return self:GetIsBuilt() and self:GetGameEffectMask(kGameEffect.OnInfestation)
    elseif techId == kTechId.WhipUnroot then
        return self:GetIsBuilt() and (self.mode == Whip.kMode.Rooted)
    elseif techId == kTechId.UpgradeWhip then
        return self:GetIsBuilt() and not self:isa("MatureWhip") and (self.mode == Whip.kMode.Rooted)
    end

    return true
        
end

function Whip:UpdatePoseParameters(deltaTime)

    Structure.UpdatePoseParameters(self, deltaTime)
    
    self:SetPoseParam("attack_yaw", self.attackYaw)
    
end

function Whip:GetCanDoDamage()
    return true
end

function Whip:GetIsRooted()
    return self.mode == Whip.kMode.Rooted
end

function Whip:OnOverrideDoorInteraction(inEntity)
    // Do not open doors when rooted.
    if (self:GetIsRooted()) then
        return false, 0
    end
    return true, 4
end

Shared.LinkClassToMap("Whip", Whip.kMapName, networkVars)

class 'MatureWhip' (Whip)

MatureWhip.kMapName = "maturewhip"


Shared.LinkClassToMap("MatureWhip", MatureWhip.kMapName, networkVars)