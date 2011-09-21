// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Embryo.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
// 
// Aliens change into this while evolving into a new lifeform. Looks like an egg.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

class 'Embryo' (Alien)

Embryo.kMapName = "embryo"
Embryo.kModelName = PrecacheAsset("models/alien/egg/egg.model")
Embryo.kBaseHealth = 50
Embryo.kThinkTime = .1
Embryo.kXExtents = .25
Embryo.kYExtents = .25
Embryo.kZExtents = .25
Embryo.kEvolveSpawnOffset = 0.2

Embryo.networkVars = 
{
    evolvePercentage = "float"
}

PrepareClassForMixin(Embryo, GroundMoveMixin)
PrepareClassForMixin(Embryo, CameraHolderMixin)

function Embryo:OnInit()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Skulk.kFov })
    
    Alien.OnInit(self)
    
    self:SetModel(Embryo.kModelName)
    
    self:TriggerEffects("player_start_gestate")
    
    self.lastThinkTime = Shared.GetTime()
    
    self:SetNextThink(Embryo.kThinkTime)
    
    self:SetViewOffsetHeight(.2)
    
    self:SetDesiredCameraDistance(2)
    
    self.originalAngles = Angles(self:GetAngles())
    
    self.evolvePercentage = 0
    
    self.evolveTime = 0
    
    self.gestationTime = 0
    
end

function Embryo:GetBaseArmor()
    return 0
end

function Embryo:GetArmorFullyUpgradedAmount()
    return 0
end

function Embryo:OnInitLocalClient()

    Alien.OnInitLocalClient(self)
    
    self.embryoHUD = GetGUIManager():CreateGUIScript("GUIEmbryoHUD")
    
end

function Embryo:OnDestroyClient()

    Alien.OnDestroyClient(self)
    
    if self.embryoHUD then
        GetGUIManager():DestroyGUIScript(self.embryoHUD)
        self.embryoHUD = nil
    end
    
end

function Embryo:GetMaxViewOffsetHeight()
    return .2
end

function Embryo:SetGestationData(techIds, previousTechId, healthScalar, armorScalar)

    // Save upgrades so they can be given when spawned
    self.evolvingUpgrades = {}
    table.copy(techIds, self.evolvingUpgrades)

    self.gestationClass = nil
    
    for i, techId in ipairs(techIds) do
        self.gestationClass = LookupTechData(techId, kTechDataGestateName)
        if self.gestationClass then 
            // Remove gestation tech id from "upgrades"
            self.gestationTypeTechId = techId
            table.removevalue(self.evolvingUpgrades, self.gestationTypeTechId)
            break 
        end
    end
    
    // Upgrades don't have a gestate name, we want to gestate back into the
    // current alien type, previousTechId.
    if not self.gestationClass then
        self.gestationTypeTechId = previousTechId
        self.gestationClass = LookupTechData(previousTechId, kTechDataGestateName)
    end
    self.gestationStartTime = Shared.GetTime()
    
    local lifeformTime = ConditionalValue(self.gestationTypeTechId ~= previousTechId, LookupTechData(self.gestationTypeTechId, kTechDataGestateTime), 0)
    self.gestationTime = ConditionalValue(Shared.GetCheatsEnabled(), 2, lifeformTime + table.count(self.evolvingUpgrades) * kUpgradeGestationTime)
    self.evolveTime = 0
    
    self:SetHealth(Embryo.kBaseHealth)
    self.maxHealth = LookupTechData(self.gestationTypeTechId, kTechDataMaxHealth)
    
    // Use this amount of health when we're done evolving
    self.healthScalar = healthScalar
    self.armorScalar = armorScalar
    
end

function Embryo:GetEvolutionTime()
    return self.evolveTime
end

// Allow players to rotate view, chat, scoreboard, etc. but not move
function Embryo:OverrideInput(input)

    self:_CheckInputInversion(input)
    
    // Completely override movement and commands
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0

    // Only allow some actions like going to menu, chatting and Scoreboard (not jump, use, etc.)
    input.commands = bit.band(input.commands, Move.Exit) + bit.band(input.commands, Move.TeamChat) + bit.band(input.commands, Move.TextChat) + bit.band(input.commands, Move.Scoreboard) + bit.band(input.commands, Move.ShowMap)
    
    return input

end

function Embryo:ConstrainMoveVelocity(moveVelocity)

    // Embryos can't move    
    moveVelocity.x = 0
    moveVelocity.y = 0
    moveVelocity.z = 0
    
end

function Embryo:PostUpdateMove(input, runningPrediction)
    self:SetAngles(self.originalAngles)
end

if Server then

    function Embryo:OnThink()

        Alien.OnThink(self)
        
        // Cannot spawn unless alive.
        if self:GetIsAlive() and self.gestationClass ~= nil then
        
            // Take into account metabolize effects
            local amount = GetAlienEvolveResearchTime(Embryo.kThinkTime, self)
            self.evolveTime = self.evolveTime + amount

            self.evolvePercentage = Clamp((self.evolveTime / self.gestationTime) * 100, 0, 100)
            
            if self.evolveTime >= self.gestationTime then
                
                // Move up slightly so that if we gestated on a sloped surface we don't get stuck
                self:SetOrigin( self:GetOrigin() + Vector(0, Embryo.kEvolveSpawnOffset, 0) )
            
                // Replace player with new player
                local newPlayer = self:Replace(self.gestationClass)
                
                newPlayer:DropToFloor()
                
                self:TriggerEffects("player_end_gestate")
                
                self:TriggerEffects("egg_death")
                
                // Now give new player all the upgrades they purchased
                for index, upgradeId in ipairs(self.evolvingUpgrades) do                
                    newPlayer:GiveUpgrade(upgradeId)
                end    

                newPlayer:SetHealth( self.healthScalar * LookupTechData(self.gestationTypeTechId, kTechDataMaxHealth) )
                newPlayer:SetArmor( self.armorScalar * LookupTechData(self.gestationTypeTechId, kTechDataMaxArmor) )

            end
            
            self.lastThinkTime = Shared.GetTime()
            
        end
        
        self:SetNextThink(Embryo.kThinkTime)
        
    end
    
    function Embryo:OnKill(damage, attacker, doer, point, direction)

        Alien.OnKill(self, damage, attacker, doer, point, direction)
        
        self:TriggerEffects("egg_death")
        
        self:SetModel("")
        
    end
    
end

Shared.LinkClassToMap("Embryo", Embryo.kMapName, Embryo.networkVars)