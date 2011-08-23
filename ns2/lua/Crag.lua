// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Crag.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that gives the commander defense and protection abilities.
//
// Passive ability - heals nearby players and structures
// Triggered ability - emit defensive umbra (8 seconds)
// Active ability - stream Babblers out towards target, hampering their ability to attack
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/RagdollMixin.lua")

class 'Crag' (Structure)

PrepareClassForMixin(Crag, InfestationMixin)

Crag.kMapName = "crag"

Crag.kModelName = PrecacheAsset("models/alien/crag/crag.model")

// Same as NS1
Crag.kHealRadius = 10
Crag.kHealAmount = 10
Crag.kMaxTargets = 3
Crag.kThinkInterval = .25
Crag.kHealInterval = 2.0
Crag.kUmbraDuration = 12
Crag.kUmbraRadius = 10

// Umbra blocks 1 out of this many bullet
Crag.kUmbraBulletChance = 2

function Crag:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function Crag:OnConstructionComplete()

    Structure.OnConstructionComplete(self)
    
    self:SetNextThink(Crag.kThinkInterval)
    
end

function Crag:GetIsAlienStructure()
    return true
end

function Crag:PerformHealing()

    // acquire up to kMaxTargets healable targets inside range, players first
    local targets = self.targetSelector:AcquireTargets(Crag.kMaxTargets)
    local entsHealed = 0
    
    for _,target in ipairs(targets) do
        local healAmount = self:TryHeal(target, sqRange) 
        // Log("%s healed %s for %s", self, target, healAmount)
        entsHealed = entsHealed + ((healAmount > 0 and 1) or 0)
    end
    
   // if entsHealed ~= #targets then
   //     // should never happen
   //     Log("WARNING! UNHEALABLE TARGETS FOUND! %s", targets)
   // end

    if entsHealed > 0 then   
        local energyCost = LookupTechData(kTechId.CragHeal, kTechDataCostKey, 0)  
        self:AddEnergy(-energyCost)        
        self:TriggerEffects("crag_heal")       
    end
    
end

function Crag:TryHeal(target, sqRange)
    local amountHealed = target:AddHealth(Crag.kHealAmount)
    if amountHealed > 0 then
        target:TriggerEffects("crag_target_healed")           
    end
    return amountHealed
end

function Crag:UpdateHealing()

    local time = Shared.GetTime()
    
    if self.timeOfLastHeal == nil or (time > self.timeOfLastHeal + Crag.kHealInterval) then
    
        // Only heal if it has the energy to do so
        local energyCost = LookupTechData(kTechId.CragHeal, kTechDataCostKey, 0)
        
        if self:GetEnergy() >= energyCost then
    
            self:PerformHealing()

            self.timeOfLastHeal = time
            
        end
        
    end
    
end

// Look for nearby friendlies to heal
function Crag:OnThink()

    Structure.OnThink(self)
    
    if self:GetIsBuilt() then
    
        self:UpdateHealing()
        
    end
        
    self:SetNextThink(Crag.kThinkInterval)
    
end

function Crag:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success then
    
        // Transform into mature crag
        if structure and (structure:GetId() == self:GetId()) and (researchId == kTechId.UpgradeCrag) then
        
            success = self:UpgradeToTechId(kTechId.MatureCrag)
            
        end
        
    end
    
    return success    
    
end

function Crag:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.UpgradesMenu, kTechId.CragHeal, kTechId.CragUmbra }
        
        // Allow structure to be ugpraded to mature version
        local upgradeIndex = table.maxn(techButtons) + 1
        
        if(self:GetTechId() == kTechId.Crag) then
            techButtons[upgradeIndex] = kTechId.UpgradeCrag
        elseif(self:GetTechId() == kTechId.MatureCrag) then
            techButtons[upgradeIndex] = kTechId.CragBabblers
        end
       
    elseif(techId == kTechId.UpgradesMenu) then 
    
        techButtons = {kTechId.AlienArmor1Tech, kTechId.AlienArmor2Tech, kTechId.AlienArmor3Tech, kTechId.None, kTechId.CarapaceTech, kTechId.RegenerationTech, kTechId.None}
        techButtons[kAlienBackButtonIndex] = kTechId.RootMenu
        
    end
    
    return techButtons
    
end

function Crag:GetIsUmbraActive()
    return self:GetIsAlive() and self:GetIsBuilt() and (self.timeOfLastUmbra ~= nil) and (Shared.GetTime() < (self.timeOfLastUmbra + Crag.kUmbraDuration))
end

function Crag:TriggerUmbra(commander)

    self:TriggerEffects("crag_trigger_umbra")

    // Think immediately instead of waiting up to Crag.kThinkInterval
    self.timeOfLastUmbra = Shared.GetTime()
    
    return true
    
end

function Crag:TargetBabblers(position)

    self:TriggerEffects("crag_trigger_babblers")
    return true
    
end

function Crag:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if techId == kTechId.CragUmbra then
        success = self:TriggerUmbra(commander)
    elseif techId == kTechId.CragBabblers then
        success = self:TargetBabblers(position)
    end
    
    return success
    
end

function Crag:OnInit()
    InitMixin(self, InfestationMixin)    
    Structure.OnInit(self) 

    if Server then 
        self.targetSelector = TargetSelector():Init(
                self,
                Crag.kHealRadius, 
                false, // we heal targets we don't have a los to
                { kAlienStaticHealTargets, kAlienMobileHealTargets },
                { HealableTargetFilter() }, // filter away unhurt targets
                { IsaPrioritizer("Player") }) // and prioritize players
    end
end

if Server then
 function Crag:OnDestroy()
    self:ClearInfestation()
    Structure.OnDestroy(self)
 end
end

Shared.LinkClassToMap("Crag", Crag.kMapName, {})

class 'MatureCrag' (Crag)

MatureCrag.kMapName = "maturecrag"

Shared.LinkClassToMap("MatureCrag", MatureCrag.kMapName, {})
