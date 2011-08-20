// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPoint.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Every room has a power point in it, which starts built. It is placed on the wall, around
// head height. When a power point is taking damage, lights nearby flicker. When a power point 
// is at 35% health or lower, the lights cycle dramatically. When a power point is destroyed, 
// the lights go completely black and all marine structures power down 5 long seconds later, the 
// aux. power comes on, fading the lights back up to ~%35. When down, the power point has 
// ambient electricity flowing around it intermittently, hinting at function. Marines can build 
// the power point by +using it, MACs can build it as well. When it comes back on, all 
// structures power back up and start functioning again and lights fade back up.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'PowerPoint' (Structure)

if Server then
    Script.Load("lua/PowerPoint_Server.lua")
else
    Script.Load("lua/PowerPoint_Client.lua")
end

PowerPoint.kMapName = "power_point"

PowerPoint.kOnModelName = PrecacheAsset("models/system/editor/power_node_on.model")
PowerPoint.kOffModelName = PrecacheAsset("models/system/editor/power_node_off.model")

PowerPoint.kDamagedEffect = PrecacheAsset("cinematics/common/powerpoint_damaged.cinematic")
PowerPoint.kOfflineEffect = PrecacheAsset("cinematics/common/powerpoint_offline.cinematic")

PowerPoint.kTakeDamageSound = PrecacheAsset("sound/ns2.fev/marine/power_node/take_damage")
PowerPoint.kDamagedSound = PrecacheAsset("sound/ns2.fev/marine/power_node/damaged")
PowerPoint.kAuxPowerBackupSound = PrecacheAsset("sound/ns2.fev/marine/power_node/backup")

PowerPoint.kHealth = kPowerPointHealth
PowerPoint.kArmor = kPowerPointArmor
PowerPoint.kAnimOn = "on"
PowerPoint.kAnimOff = "off"
PowerPoint.kDamagedPercentage = .4

PowerPoint.kPowerOnTime = .5
PowerPoint.kPowerDownTime = 1
PowerPoint.kOffTime = 10
PowerPoint.kPowerRecoveryTime = 5
PowerPoint.kPowerDownMaxIntensity = .7
PowerPoint.kLowPowerCycleTime = 1
PowerPoint.kLowPowerMinIntensity = .4
PowerPoint.kDamagedCycleTime = .8
PowerPoint.kDamagedMinIntensity = .7
PowerPoint.kAuxPowerCycleTime = 3
PowerPoint.kAuxPowerMinIntensity = 0

local networkVars =
{
    lightMode               = "enum kLightMode",
    timeOfLightModeChange   = "float",
    triggerName             = string.format("string (%d)", kMaxEntityStringLength)
}

// No spawn animation
function PowerPoint:GetSpawnAnimation()
    return ""
end

function PowerPoint:OnInit()

    self:SetModel(PowerPoint.kOnModelName)
    
    Structure.OnInit(self)
    
    self.lightMode = kLightMode.Normal
    
    self:SetAnimation(PowerPoint.kAnimOn)
    
    if Server then
    
        self.startsBuilt = true
        
        self:SetTeamNumber(kTeamReadyRoom)
    
        self:SetConstructionComplete()
        
        self:SetNextThink(.1)

    else 
    
        self.unchangingLights = {}
        
        self.lightFlickers = {}
        
    end
    
end

function PowerPoint:Reset()

    self:OnInit()  
    
    Structure.Reset(self)
    
end

function PowerPoint:GetCanTakeDamage()
    return self.powered
end

function PowerPoint:GetIsBuilt()
    return true
end

function PowerPoint:GetIsPowered()
    return self.powered
end


function PowerPoint:SetLightMode(lightMode)

    // Don't change light mode too often or lights will change too much
    if self.lightMode ~= lightMode or (not self.timeOfLightModeChange or (Shared.GetTime() > (self.timeOfLightModeChange + 1.0))) then
    
        self.lightMode = lightMode
        self.timeOfLightModeChange = Shared.GetTime()
        
    end
    
end

function PowerPoint:GetIsMapEntity()
    return true
end

function PowerPoint:GetLightMode()
    return self.lightMode
end

function PowerPoint:GetIsBlipValid()
    return self.lightMode == kLightMode.NoPower
end

function PowerPoint:GetTimeOfLightModeChange()
    return self.timeOfLightModeChange
end

function PowerPoint:ProcessEntityHelp(player)

    if self:GetIsPowered() then
        if self:GetHealthScalar() < PowerPoint.kDamagedPercentage then
            return player:AddTooltipOncePer("POWER_NEAR_DEATH_TOOLTIP")
        else
            if player:isa("Marine") then
                return player:AddTooltipOncePer("FRIENDLY_POWER_NODE_TOOLTIP")
            elseif player:isa("Alien") then
                return player:AddTooltipOncePer("ENEMY_POWER_NODE_TOOLTIP")
            end
        end
    else
        if player:isa("Marine") then
            return player:AddTooltipOncePer("FRIENDLY_DESTROYED_POWER_NODE_TOOLTIP")
        elseif player:isa("Alien") then
            return player:AddTooltipOncePer("ENEMY_DESTROYED_POWER_NODE_TOOLTIP")
        end
    end
    
    return false
    
end

function PowerPoint:GetCanBeUsed(player)
    return true
end

/**
 * Power points never die, which is what allows them to be repaired even
 * when they have 0 health.
 */
function PowerPoint:GetIsAliveOverride()
    return true
end

function PowerPoint:OverrideVisionRadius()
  return 2
end

Shared.LinkClassToMap("PowerPoint", PowerPoint.kMapName, networkVars)