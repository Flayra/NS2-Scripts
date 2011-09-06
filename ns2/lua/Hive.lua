// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/CommandStructure.lua")
Script.Load("lua/InfestationMixin.lua")

class 'Hive' (CommandStructure)
PrepareClassForMixin(Hive, InfestationMixin)

Hive.networkVars = 
{
    upgradeTechId   = string.format("integer (0 to %d)", kTechIdMax),
}

Hive.kMapName        = "hive"

Hive.kLevel1MapName  = "hivel1"
Hive.kModelName = PrecacheAsset("models/alien/hive/hive.model")

Hive.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_wound")
// Play special sound for players on team to make it sound more dramatic or horrible
Hive.kWoundAlienSound = PrecacheAsset("sound/ns2.fev/alien/structures/hive_wound_alien")

Hive.kIdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist.cinematic")
Hive.kL2IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev2.cinematic")
Hive.kL3IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev3.cinematic")
Hive.kGlowEffect = PrecacheAsset("cinematics/alien/hive/glow.cinematic")
Hive.kSpecksEffect = PrecacheAsset("cinematics/alien/hive/specks.cinematic")

Hive.kCompleteSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_complete")
Hive.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_under_attack")
Hive.kDyingSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/hive_dying")
// Play 'hive is dying' sound when health gets to 40% or less
Hive.kHiveDyingThreshold = .4

Hive.kHealRadius = 12.7     // From NS1
Hive.kHealthPercentage = .08
Hive.kHealthUpdateTime = 1

// A little bigger than we might expect because the hive origin isn't on the ground
Hive.kHiveNumEggs = 12
Hive.kEggMinRange = 4
Hive.kEggMaxRange = 22

if Server then
    Script.Load("lua/Hive_Server.lua")
else
    Script.Load("lua/Hive_Client.lua")
end

function Hive:GetIsAlienStructure()
    return true
end

function Hive:OnTouch(player)

    if(GetEnemyTeamNumber(self:GetTeamNumber()) == player:GetTeamNumber()) then    
        self:TriggerEffects("hive_recoil")
    end
    
end

function Hive:GetInfestationRadius()
    return kHiveInfestationRadius
end

function Hive:GetCystParentRange()
    return kHiveCystParentRange
end

function Hive:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = 
        { 
            kTechId.Cyst, kTechId.Drifter, kTechId.MarkersMenu, 
            kTechId.UpgradesMenu, kTechId.SetRally, kTechId.Metabolize
        }
        
    elseif(techId == kTechId.MarkersMenu) then 
        techButtons =
        {
            kTechId.RootMenu, kTechId.ThreatMarker, kTechId.LargeThreatMarker, 
            kTechId.NeedHealingMarker, kTechId.WeakMarker, kTechId.ExpandingMarker
        }
    elseif(techId == kTechId.UpgradesMenu) then 
        techButtons = 
        {
            kTechId.RootMenu, kTechId.DrifterFlareTech, kTechId.MetabolizeTech, kTechId.None, 
            kTechId.None, kTechId.None, kTechId.None, kTechId.None
        }
    end
    
    return techButtons
    
end

function Hive:TriggerMetabolize(position)

    // Find nearest friendly entity within range and boost it's evolve/research speed
    local target = GetTriggerEntity(position, self:GetTeamNumber())
    
    if target then
    
        self:TriggerEffects("hive_metabolize")
        
        target:AddStackableGameEffect(kMetabolizeGameEffect, kMetabolizeTime, self)
        
    end
    
end

function Hive:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.Metabolize then
    
        self:TriggerMetabolize(position)
        success = true

    else        
        success = CommandStructure.PerformActivation(self, techId, position, normal, commander)
    end
    
    return success
    
end

function Hive:OnInit()
    InitMixin(self, InfestationMixin)
    
    CommandStructure.OnInit(self)
    
    if Server then
        // Set on init so first egg isn't created right away
        self.timeOfLastEgg = Shared.GetTime()
        
        // Pre-compute list of egg spawn points
        self:GenerateEggSpawns()
        
    end
    
    if (Client) then
        // Create glowy "plankton" swimming around hive, along with mist and glow
        local coords = self:GetCoords()
        self:AttachEffect(Hive.kSpecksEffect, coords)
        self:AttachEffect(Hive.kGlowEffect, coords, Cinematic.Repeat_Loop)
    
        // For mist creation
        self:SetUpdates(true)
    end        
end

// Show "Crag Hive" or "Shift Hive"
function Hive:GetDescription()

    local hiveDescription = GetDisplayNameForTechId(self:GetTechId())
    
    if self.upgradeTechId ~= kTechId.None then
        hiveDescription = string.format("%s %s", GetDisplayNameForTechId(self.upgradeTechId), hiveDescription)
    end    
    
    return hiveDescription
    
end


Shared.LinkClassToMap("Hive",    Hive.kLevel1MapName, Hive.networkVars)

