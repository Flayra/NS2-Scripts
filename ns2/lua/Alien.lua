// ======= Copyright © 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/CamouflageMixin.lua")
Script.Load("lua/PhantomMixin.lua")

class 'Alien' (Player)
Alien.kMapName = "alien"

if (Server) then
    Script.Load("lua/Alien_Server.lua")
else
    Script.Load("lua/Alien_Client.lua")
end

Alien.kNotEnoughResourcesSound = PrecacheAsset("sound/ns2.fev/alien/voiceovers/more")
Alien.kRegenerationSound = PrecacheAsset("sound/ns2.fev/alien/common/regeneration")
Alien.kChatSound = PrecacheAsset("sound/ns2.fev/alien/common/chat")
Alien.kSpendResourcesSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")

// Representative portrait of selected units in the middle of the build button cluster
Alien.kPortraitIconsTexture = "ui/alien_portraiticons.dds"

// Multiple selection icons at bottom middle of screen
Alien.kFocusIconsTexture = "ui/alien_focusicons.dds"

// Small mono-color icons representing 1-4 upgrades that the creature or structure has
Alien.kUpgradeIconsTexture = "ui/alien_upgradeicons.dds"

Alien.kAnimOverlayAttack = "attack"

// DI regen think time
Alien.kRegenThinkInterval = 1.0
Alien.kWalkBackwardSpeedScalar = 0.75

// Percentage per DI regen
Alien.kInnateRegenerationPercentage = 0.02
Alien.kEnergyRecuperationRate = 10.0
Alien.kEnergyBreathScalar = .5

// How long our "need healing" text gets displayed under our blip
Alien.kCustomBlipDuration = 10

Alien.networkVars = 
{
    // Energy used for all alien weapons and abilities (instead of ammo).
    // Regenerates on its own over time. Not called energy because used in base class.
    abilityEnergy           = "float", // Range is (0 to Ability.kMaxEnergy)
    
    energizeLevel           = string.format("integer (0 to %d)", kMaxStackLevel),

    movementModiferState    = "boolean",
    
    twoHives                = "boolean",
    
    threeHives              = "boolean",
}

PrepareClassForMixin(Alien, CloakableMixin)
PrepareClassForMixin(Alien, CamouflageMixin)
PrepareClassForMixin(Alien, PhantomMixin)

function Alien:OnCreate()
    
    Player.OnCreate(self)
    self.energizeLevel = 0
    
    // Only used on the local client.
    self.darkVisionOn   = false
    self.darkVisionTime = 0
    self.darkVisionEndTime = 0
    
    self.twoHives = false
    self.threeHives = false

end

function Alien:OnInit()

    Player.OnInit(self)
    
    InitMixin(self, CloakableMixin)
    InitMixin(self, CamouflageMixin)
    InitMixin(self, PhantomMixin)
    
    self.abilityEnergy = Ability.kMaxEnergy

    self.armor = self:GetArmorAmount()
    self.maxArmor = self.armor

end

function Alien:GetHasTwoHives()
    return self.twoHives
end

function Alien:GetHasThreeHives()
    return self.threeHives
end

// For special ability, return an array of totalPower, minimumPower, tex x offset, tex y offset, 
// visibility (boolean), command name
function Alien:GetAbilityInterfaceData()
    return {}
end

function Alien:GetEnergy()
    return self.abilityEnergy
end

function Alien:GetIsCloakable()
    return true
end

function Alien:DeductAbilityEnergy(energyCost)

    // Reduce energy
    self.abilityEnergy = Clamp(self.abilityEnergy - energyCost, 0, Ability.kMaxEnergy)
    
    // Make us a bit more out of breath
    self.outOfBreath = self.outOfBreath + (energyCost/Ability.kMaxEnergy * Alien.kEnergyBreathScalar)*255
    self.outOfBreath = math.max(math.min(self.outOfBreath, 255), 0)
    
end

function Alien:UpdateAbilityEnergy(input)

    // Take into account any shifts giving us energy
    local energyRate = self:GetRecuperationRate() * (1 + self.energizeLevel * kEnergizeEnergyIncrease)

    // Add energy back over time, called from Player:OnProcessMove
    self.abilityEnergy = Clamp(self.abilityEnergy + energyRate * input.time, 0, Ability.kMaxEnergy)

end

function Alien:GetMaxBackwardSpeedScalar()
    return Alien.kWalkBackwardSpeedScalar
end

function Alien:UpdateSharedMisc(input)

    self:UpdateAbilityEnergy(input)    
    Player.UpdateSharedMisc(self, input)
    
end

function Alien:HandleButtons(input)

    PROFILE("Alien:HandleButtons")

    Player.HandleButtons(self, input)
    
    // Update alien movement ability
    local newMovementState = bit.band(input.commands, Move.MovementModifier) ~= 0
    if(newMovementState ~= self.movementModiferState and self.movementModiferState ~= nil) then
    
        self:MovementModifierChanged(newMovementState, input)
        
    end
    self.movementModiferState = newMovementState

    if Client and not Shared.GetIsRunningPrediction() then
        if bit.band(input.commands, Move.ToggleFlashlight) ~= 0 then
            self.darkVisionOn = not self.darkVisionOn
            if self.darkVisionOn then
                self.darkVisionTime = Client.GetTime()
                self:TriggerEffects("alien_vision_on")            
            else
                self.darkVisionEndTime = Client.GetTime()
                self:TriggerEffects("alien_vision_off")           
            end
        end
    end
    
end

function Alien:GetCustomAnimationName(animName)
    return animName
end

function Alien:PlayInvalidSound()
    Shared.PlaySound(self, Player.kInvalidSound)
end

function Alien:GetNotEnoughResourcesSound()
    return Alien.kNotEnoughResourcesSound
end

// Return true if creature has an energy powered special ability
// that shows up on the HUD (blink)
function Alien:GetHasSpecialAbility()
    return false
end

// Returns true when players are selecting new abilities. When true, draw small icons
// next to your current weapon and force all abilities to draw.
function Alien:GetInactiveVisible()
    return self.timeOfLastWeaponSwitch ~= nil and (Shared.GetTime() < self.timeOfLastWeaponSwitch + kDisplayWeaponTime)
end

function Alien:OnUpdate(deltaTime)
    
    Player.OnUpdate(self, deltaTime)
    
    // Propagate count to client so energy is predicted
    if Server then
        self.energizeLevel = self:GetStackableGameEffectCount(kEnergizeGameEffect)

        // Calculate two and three hives so abilities for abilities        
        self:UpdateNumHives()
    end
    
end

function Alien:GetBaseArmor()
    // Must override.
    ASSERT(false)
    return 0
end

function Alien:GetArmorFullyUpgradedAmount()
    // Must override.
    ASSERT(false)
    return 0
end

function Alien:GetArmorAmount()

    local extraUpgradedArmor = 0
    
    if(GetTechSupported(self, kTechId.AlienArmor3Tech, true)) then
    
        extraUpgradedArmor = self:GetArmorFullyUpgradedAmount()
    
    elseif(GetTechSupported(self, kTechId.AlienArmor2Tech, true)) then
    
        extraUpgradedArmor = (self:GetArmorFullyUpgradedAmount() / 3) * 2
    
    elseif(GetTechSupported(self, kTechId.AlienArmor1Tech, true)) then
    
        extraUpgradedArmor = self:GetArmorFullyUpgradedAmount() / 3
    
    end

    return self:GetBaseArmor() + extraUpgradedArmor
   
end

function Alien:GetRecuperationRate()
    local scalar = ConditionalValue(self:GetGameEffectMask(kGameEffect.OnFire), kOnFireEnergyRecuperationScalar, 1)
    return scalar * Alien.kEnergyRecuperationRate
end

function Alien:MovementModifierChanged(newMovementModifierState, input)
end

function Alien:GetHasSayings()
    return true
end

function Alien:GetSayings()

    if(self.showSayings) then
        if(self.showSayingsMenu == 1) then
            return alienGroupSayingsText    
        end
        if(self.showSayingsMenu == 2) then
            return GetVoteActionsText(self:GetTeamNumber())
        end

        return 
    end
    
    return nil
    
end

function Alien:ExecuteSaying(index, menu)

    Player.ExecuteSaying(self, index, menu)

    if(Server) then
    
        // Handle voting
        if self.showSayingsMenu == 2 then
            GetGamerules():CastVoteByPlayer( voteActionsActions[index], self )
        else

            self:PlaySound(alienGroupSayingsSounds[index])
            
            local techId = alienRequestActions[index]
            if techId ~= kTechId.None then
                self:GetTeam():TriggerAlert(techId, self)
            end
            
            // Remember this as a custom blip type so we can display 
            // appropriate text ("needs healing")
            self:SetCustomBlip( alienBlipTypes[index] )
            
        end
        
    end
        
end

function Alien:SetCustomBlip(blipType)

    self.customBlipType = blipType
    
    if blipType ~= kBlipType.Undefined then
        self.customBlipTime = Shared.GetTime()
    else
        self.customBlipTime = nil
    end

end

function Alien:GetCustomBlip()

    if self.customBlipType ~= nil and self.customBlipType ~= kBlipType.Undefined then
    
        if self.customBlipTime and Shared.GetTime() < (self.customBlipTime + Alien.kCustomBlipDuration) then
        
            return self.customBlipType
            
        end
        
    end
    
    return kBlipType.Undefined
    
end

function Alien:GetChatSound()
    return Alien.kChatSound
end

function Alien:GetDeathMapName()
    return AlienSpectator.kMapName
end

// Returns the name of the player's lifeform
function Alien:GetPlayerStatusDesc()

    local status = ""
    
    if (self:GetIsAlive() == false) then
        status = "Dead"
    else
        if (self:isa("Embryo")) then
            status = "Evolving"
        else
            status = self:GetClassName()
        end
    end
    
    return status

end

Shared.LinkClassToMap( "Alien", Alien.kMapName, Alien.networkVars )