// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/TechData.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/PlayingTeam.lua")
Script.Load("lua/UpgradeStructureManager.lua")

class 'AlienTeam' (PlayingTeam)

// Innate alien regeneration
AlienTeam.kAutoHealInterval = 2
AlienTeam.kOrganicStructureHealRate = 5     // Health per second
AlienTeam.kInfestationUpdateRate = 2
AlienTeam.kInfestationHurtInterval = 2

AlienTeam.kSupportingStructureClassNames = {[kTechId.Hive] = {"Hive"} }
AlienTeam.kUpgradeStructureClassNames = {[kTechId.Crag] = {"Crag", "MatureCrag"}, [kTechId.Shift] = {"Shift", "MatureShift"}, [kTechId.Shade] = {"Shade", "MatureShift"} }
AlienTeam.kUpgradedStructureTechTable = {[kTechId.Crag] = {kTechId.MatureCrag}, [kTechId.Shift] = {kTechId.MatureShift}, [kTechId.Shade] = {kTechId.MatureShade}}

AlienTeam.kTechTreeIdsToUpdate = {kTechId.Crag, kTechId.MatureCrag, kTechId.Shift, kTechId.MatureShift, kTechId.Shade, kTechId.MatureShade}

function AlienTeam:GetTeamType()
    return kAlienTeamType
end

function AlienTeam:GetIsAlienTeam()
    return true
end

function AlienTeam:Initialize(teamName, teamNumber)

    PlayingTeam.Initialize(self, teamName, teamNumber)
    
    self.respawnEntity = Skulk.kMapName
    
    self.upgradeStructureManager = UpgradeStructureManager()
    self.upgradeStructureManager:Initialize(AlienTeam.kSupportingStructureClassNames, AlienTeam.kUpgradeStructureClassNames, AlienTeam.kUpgradedStructureTechTable)
    
    self.eggList = {}
    
end

function AlienTeam:OnInit()

    // (re)create upgrade structure manager before OnInit(), so AddStructure(Hive) is called
    self.upgradeStructureManager = UpgradeStructureManager()
    self.upgradeStructureManager:Initialize(AlienTeam.kSupportingStructureClassNames, AlienTeam.kUpgradeStructureClassNames, AlienTeam.kUpgradedStructureTechTable)

    PlayingTeam.OnInit(self)    

end

function AlienTeam:SpawnInitialStructures(teamLocation)

    PlayingTeam.SpawnInitialStructures(self, teamLocation)
    
    // Aliens start the game with all their eggs
    local nearestTechPoint = GetNearestTechPoint(teamLocation:GetOrigin(), self:GetTeamType(), false)
    if(nearestTechPoint ~= nil) then
    
        local attached = nearestTechPoint:GetAttached()
        if(attached ~= nil) then

            if attached:isa("Hive") then
                attached:SpawnInitial()
            else
                Print("AlienTeam:SpawnInitialStructures(): Hive not attached to tech point, %s instead.", attached:GetClassName())
            end
            
        end
        
    end
    
end

function AlienTeam:GetHasAbilityToRespawn()
    
    local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
    return table.count(hives) > 0
    
end

function AlienTeam:Update(timePassed)

    PROFILE("AlienTeam:Update")

    PlayingTeam.Update(self, timePassed)

    self:UpdateAutoBuild(timePassed)
    
    self:UpdateTeamAutoHeal(timePassed)
    
    self:UpdateAlienResearchProgress()
    
end

function AlienTeam:UpdateAutoBuild(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoBuild")

    // Update build fraction every tick to be smooth
    for index, structureId in ipairs(self.structures) do
        local structure = Shared.GetEntity(structureId)          
        if (structure ~= nil) and (not structure:GetIsBuilt()) then        
            // Account for metabolize game effects
            local autoBuildTime = GetAlienEvolveResearchTime(timePassed, structure)
            structure:Construct(autoBuildTime)
        
        end
        
    end
    
end

// Small and silent innate health and armor regeneration for all alien players, similar to the 
// innate regeneration of all alien structures. NS1 healed 2% of alien max health every 2 seconds.
function AlienTeam:UpdateTeamAutoHeal(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoHeal")

    local time = Shared.GetTime()
    
    if self.timeOfLastAutoHeal == nil or (time > (self.timeOfLastAutoHeal + AlienTeam.kAutoHealInterval)) then
    
        // Heal everything on infestation by this amount
        local teamEnts = GetEntitiesWithMixinForTeam("Live", self:GetTeamNumber())
        
        local intervalLength = AlienTeam.kAutoHealInterval
        if self.timeOfLastAutoHeal ~= nil then
            intervalLength = time - self.timeOfLastAutoHeal
        end
        
        for index, entity in ipairs(teamEnts) do
        
            // This affects drifters and hives too, even though they aren't on infestation
            if entity:GetIsAlive() and entity:GetGameEffectMask(kGameEffect.OnInfestation) then
            
                // Cap health back at 2%/sec
                local healthBack = AlienTeam.kOrganicStructureHealRate * intervalLength
                healthBack = math.min(healthBack, 0.02*entity:GetMaxHealth())
                //Print("%s OnInfestation, healed %.2f", entity:GetClassName(), healthBack)
                entity:AddHealth(healthBack, true)
                
            end
            
        end
        
        self.timeOfLastAutoHeal = time
        
    end
    
    // Hurt structures if they require infestation and aren't on it
    if self.timeOfLastInfestationHurt == nil or (time > (self.timeOfLastInfestationHurt + AlienTeam.kInfestationHurtInterval)) then
    
        for index, structureId in ipairs(self.structures) do
            local structure = Shared.GetEntity(structureId)
            if (structure ~= nil) then
              if LookupTechData(structure:GetTechId(), kTechDataRequiresInfestation) and not structure:GetGameEffectMask(kGameEffect.OnInfestation) then            
                // Take damage!
                local damage = structure:GetMaxHealth() * kBalanceInfestationHurtPercentPerSecond/100 * AlienTeam.kInfestationHurtInterval               
                structure:TakeDamage(damage, nil, nil, structure:GetOrigin(), nil)
              end
            end         
        end
        
        self.timeOfLastInfestationHurt = time
        
    end
    
end

/**
 * Compute the research precent based on the research percent of all prerequisites for all the alien types.
 */
function AlienTeam:UpdateAlienResearchProgress()

    PROFILE("AlienTeam:UpdateAlienResearchProgress")
    
    // Skulk doesn't need to be researched. Onos will need to be added.
    local aliensTechUpgradeData = { { TechId = kTechId.Fade, UpgradeNode = kTechId.TwoHives },
                                    { TechId = kTechId.Gorge, UpgradeNode = kTechId.Crag },
                                    { TechId = kTechId.Lerk, UpgradeNode = kTechId.Whip } }
    
    for index, alienTechUpgradeData in pairs(aliensTechUpgradeData) do
    
        local alienTechNode = self.techTree:GetTechNode(alienTechUpgradeData.TechId)
        if alienTechNode then
        
            local previousPrereqResearchProgress = alienTechNode:GetPrereqResearchProgress()
            local prereqNode = self.techTree:GetTechNode(alienTechUpgradeData.UpgradeNode)
            if prereqNode /*and prereqNode:GetAvailable()*/ then

                local progress = 0
                
                if prereqNode:GetIsResearch() or prereqNode:GetIsBuy() or prereqNode:GetIsUpgrade() then
                    progress = prereqNode:GetResearchProgress()
                elseif prereqNode:GetIsBuild() then
                    local buildTechId = prereqNode:GetTechId()
                    local entsMatchingTechId = GetEntitiesWithFilter(Shared.GetEntitiesWithClassname("Structure"), function(entity) return entity:GetTechId() == buildTechId end)
                    local highestBuiltFraction = 0
                    for k, ent in ipairs(entsMatchingTechId) do
                        highestBuiltFraction = (ent:GetBuiltFraction() > highestBuiltFraction and ent:GetBuiltFraction()) or highestBuiltFraction
                    end
                    progress = highestBuiltFraction
                end
                
                if progress ~= previousPrereqResearchProgress then
                    alienTechNode:SetPrereqResearchProgress(progress)
                    self.techTree:SetTechNodeChanged(alienTechNode)
                end
                
            end
            
        end
        
    end

end


function AlienTeam:GetUmbraCrags()

    local crags = GetEntitiesForTeam("Crag", self:GetTeamNumber())
    
    local umbraCrags = {}    
    
    // Get umbraing crags
    for index, crag in ipairs(crags) do
    
        if crag:GetIsUmbraActive() then
        
            table.insert(umbraCrags, crag)
            
        end
        
    end
    
    return umbraCrags

end

function AlienTeam:GetFuryWhips()

    local whips = GetEntitiesForTeam("Whip", self:GetTeamNumber())
    
    local furyWhips = {}    
    
    // Get furying whips
    for index, whip in ipairs(whips) do
    
        if whip:GetIsFuryActive() then
        
            table.insert(furyWhips, whip)
            
        end
        
    end
    
    return furyWhips

end

function AlienTeam:GetShades()
    return GetEntitiesForTeam("Shade", self:GetTeamNumber())
end

// Adds the InUmbra game effect to all specified entities within range of active crags. Returns
// the number of entities affected.
function AlienTeam:UpdateUmbraGameEffects(entities)

    local umbraCrags = self:GetUmbraCrags()
    
    if table.count(umbraCrags) > 0 then
    
        for index, entity in ipairs(entities) do
        
            // Get distance to crag
            for cragIndex, crag in ipairs(umbraCrags) do
            
                if (entity:GetOrigin() - crag:GetOrigin()):GetLengthSquared() < Crag.kUmbraRadius*Crag.kUmbraRadius then
                
                    entity:SetGameEffectMask(kGameEffect.InUmbra, true)
                
                end
                
            end
            
        end
    
    end

end

function AlienTeam:UpdateFuryGameEffects(entities)

    local furyWhips = self:GetFuryWhips()
    
    if table.count(furyWhips) > 0 then
    
        for index, entity in ipairs(entities) do
        
            if HasMixin(entity, "Fury") then

                // Get distance to whip
                for index, whip in ipairs(furyWhips) do
                
                    if (entity:GetOrigin() - whip:GetOrigin()):GetLengthSquared() < Whip.kFuryRadius*Whip.kFuryRadius then
                    
                        entity:SetGameEffectMask(kGameEffect.Fury, true)
                    
                        entity:AddStackableGameEffect(kFuryGameEffect, kFuryTime, whip)
                        
                    end
                    
                end
                
            end
            
        end
    
    end

end

// Update cloaking for friendlies and disorientation for enemies
function AlienTeam:UpdateShadeEffects(teamEntities, enemyPlayers)

    local shades = self:GetShades()
    local time = Shared.GetTime()
    
    if self.lastUpdateShadeTime == nil or (Shared.GetTime() > self.lastUpdateShadeTime + .3) then
    
        // Update disoriented effects
        for index, entity in ipairs(enemyPlayers) do
            
            if HasMixin(entity, "Disorientable") then
            
                local disorientedMinDistance = math.huge
    
                if table.count(shades) > 0 then
            
                    for index, shade in ipairs(shades) do
                        if (shade:GetIsActive() and shade:GetIsBuilt()) then
                            local distance = (entity:GetOrigin() - shade:GetOrigin()):GetLength()
                        
                            if (distance < Shade.kCloakRadius) and (distance < disorientedMinDistance) then
                            
                                disorientedMinDistance = distance
                        
                            end
                        end                        
                    end
                        
                end
                
                local disorientedAmount = Clamp(ConditionalValue(disorientedMinDistance < math.huge, 1 - (disorientedMinDistance / Shade.kCloakRadius), 0), 0, 1)
                entity:SetDisorientedAmount(disorientedAmount)
                
            end
            
        end
        
        self.lastUpdateShadeTime = time
        
    end
    
end



function AlienTeam:InitTechTree()
   
    PlayingTeam.InitTechTree(self)
    
    // Add special alien menus
    self.techTree:AddMenu(kTechId.MarkersMenu)
    self.techTree:AddMenu(kTechId.UpgradesMenu)
    self.techTree:AddMenu(kTechId.ShadePhantomMenu)
    
    // Add markers (orders)
    self.techTree:AddSpecial(kTechId.ThreatMarker, true)
    self.techTree:AddSpecial(kTechId.LargeThreatMarker, true)
    self.techTree:AddSpecial(kTechId.NeedHealingMarker, true)
    self.techTree:AddSpecial(kTechId.WeakMarker, true)
    self.techTree:AddSpecial(kTechId.ExpandingMarker, true)
    
    // Commander abilities
    self.techTree:AddEnergyBuildNode(kTechId.Cyst,           kTechId.None,           kTechId.None)
    self.techTree:AddResearchNode(kTechId.MetabolizeTech,       kTechId.TwoHives,       kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Metabolize,     kTechId.MetabolizeTech, kTechId.None)
           
    // Tier 1
    self.techTree:AddBuildNode(kTechId.Hive,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Harvester,                 kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.HarvesterUpgrade,        kTechId.Harvester,           kTechId.None)
    self.techTree:AddEnergyManufactureNode(kTechId.Drifter,       kTechId.None,                kTechId.None)
    
    // Drifter tech
    self.techTree:AddResearchNode(kTechId.DrifterFlareTech,       kTechId.TwoHives,                kTechId.None)
    self.techTree:AddActivation(kTechId.DrifterFlare,                 kTechId.DrifterFlareTech)
    
    self.techTree:AddResearchNode(kTechId.DrifterParasiteTech,    kTechId.None,                kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.DrifterParasite,      kTechId.DrifterParasiteTech, kTechId.None)

    // Whips
    self.techTree:AddBuildNode(kTechId.Whip,                      kTechId.None,                kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeWhip,             kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureWhip,                 kTechId.TwoHives,                kTechId.None)
    self.techTree:AddActivation(kTechId.WhipAcidStrike,            kTechId.None,                kTechId.None)    
    self.techTree:AddActivation(kTechId.WhipFury,                 kTechId.None,          kTechId.None)
    
    self.techTree:AddActivation(kTechId.WhipUnroot)
    self.techTree:AddActivation(kTechId.WhipRoot)
    
    self.techTree:AddResearchNode(kTechId.Melee1Tech,             kTechId.Whip,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.Melee2Tech,             kTechId.Melee1Tech,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.Melee3Tech,             kTechId.Melee2Tech,                kTechId.None)
    
    self.techTree:AddTargetedActivation(kTechId.WhipBombard,                  kTechId.MatureWhip, kTechId.None)
    
    // Tier 1 lifeforms
    self.techTree:AddBuyNode(kTechId.Skulk,                     kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Gorge,                     kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Lerk,                      kTechId.None,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Fade,                      kTechId.TwoHives,            kTechId.None)
    self.techTree:AddBuyNode(kTechId.Onos,                      kTechId.ThreeHives,          kTechId.None)
    
    // Special alien upgrade structures. These tech nodes are modified at run-time, depending when they are built, so don't modify prereqs.
    self.techTree:AddBuildNode(kTechId.Crag,                      kTechId.None,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.Shift,                     kTechId.None,          kTechId.None)
    self.techTree:AddBuildNode(kTechId.Shade,                     kTechId.None,          kTechId.None)
    
    // Crag
    self.techTree:AddUpgradeNode(kTechId.UpgradeCrag,            kTechId.Crag,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureCrag,                kTechId.TwoHives,                kTechId.None)
    self.techTree:AddActivation(kTechId.CragHeal,                    kTechId.None,          kTechId.None)
    self.techTree:AddActivation(kTechId.CragUmbra,                    kTechId.Crag,          kTechId.None)
    self.techTree:AddResearchNode(kTechId.BabblerTech,            kTechId.MatureCrag,          kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.CragBabblers,     kTechId.BabblerTech,         kTechId.MatureCrag)

    // Shift    
    self.techTree:AddUpgradeNode(kTechId.UpgradeShift,            kTechId.Shift,               kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureShift,               kTechId.TwoHives,          kTechId.None)
    self.techTree:AddActivation(kTechId.ShiftRecall,              kTechId.None, kTechId.None)
    self.techTree:AddResearchNode(kTechId.EchoTech,               kTechId.MatureShift,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.ShiftEcho,        kTechId.EchoTech,            kTechId.MatureShift)    
    self.techTree:AddActivation(kTechId.ShiftEnergize,            kTechId.None,         kTechId.None)

    // Shade
    self.techTree:AddUpgradeNode(kTechId.UpgradeShade,           kTechId.Shade,               kTechId.None)
    self.techTree:AddBuildNode(kTechId.MatureShade,               kTechId.TwoHives,          kTechId.None)
    self.techTree:AddActivation(kTechId.ShadeDisorient,               kTechId.None,         kTechId.None)
    self.techTree:AddActivation(kTechId.ShadeCloak,                   kTechId.None,         kTechId.None)
    
    // Shade targeted abilities - treat Phantoms as build nodes so we show ghost and attach points for fake hive
    self.techTree:AddResearchNode(kTechId.PhantomTech,             kTechId.MatureShade,         kTechId.None)
    self.techTree:AddBuildNode(kTechId.ShadePhantomFade,           kTechId.PhantomTech,         kTechId.MatureShade)
    self.techTree:AddBuildNode(kTechId.ShadePhantomOnos,           kTechId.PhantomTech,         kTechId.None)

    // Crag upgrades
    self.techTree:AddResearchNode(kTechId.AlienArmor1Tech,        kTechId.Crag,                kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor2Tech,        kTechId.AlienArmor1Tech,          kTechId.None)
    self.techTree:AddResearchNode(kTechId.AlienArmor3Tech,        kTechId.AlienArmor2Tech,          kTechId.None)
    
    // Tier 2
    self.techTree:AddSpecial(kTechId.TwoHives)
    self.techTree:AddResearchNode(kTechId.BileBombTech,           kTechId.TwoHives,                kTechId.None,    kTechId.MatureWhip)
    self.techTree:AddResearchNode(kTechId.LeapTech,               kTechId.TwoHives,                kTechId.None)
    
    // Tier 3
    self.techTree:AddSpecial(kTechId.ThreeHives)    
    
    // Global alien upgrades. Make sure the first prerequisite is the main tech required for it, as this is 
    // what is used to display research % in the alien evolve menu.
    self.techTree:AddResearchNode(kTechId.CarapaceTech, kTechId.Crag, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Carapace, kTechId.CarapaceTech, kTechId.None, kTechId.AllAliens)    
    
    self.techTree:AddResearchNode(kTechId.RegenerationTech, kTechId.Crag, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Regeneration, kTechId.RegenerationTech, kTechId.None, kTechId.AllAliens)

    self.techTree:AddResearchNode(kTechId.FrenzyTech,             kTechId.Whip,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Frenzy,             kTechId.FrenzyTech,                kTechId.None,     kTechId.AllAliens)
    
    self.techTree:AddResearchNode(kTechId.SwarmTech,              kTechId.Whip,                kTechId.None)   
    self.techTree:AddBuyNode(kTechId.Swarm,              kTechId.SwarmTech,                kTechId.None,     kTechId.AllAliens)

    self.techTree:AddResearchNode(kTechId.CamouflageTech,             kTechId.Shade,                kTechId.None)
    self.techTree:AddBuyNode(kTechId.Camouflage,             kTechId.CamouflageTech,                kTechId.None,     kTechId.AllAliens)

    // Specific alien upgrades
    self.techTree:AddBuildNode(kTechId.Hydra,               kTechId.None,               kTechId.None)
    self.techTree:AddBuyNode(kTechId.BileBomb,              kTechId.BileBombTech,       kTechId.TwoHives,               kTechId.Gorge)
    self.techTree:AddBuyNode(kTechId.Leap,                  kTechId.LeapTech,           kTechId.TwoHives,               kTechId.Skulk)
    
    // Alien upgrades   
    self.techTree:AddResearchNode(kTechId.AdrenalineTech, kTechId.TwoHives, kTechId.Shift)
    self.techTree:AddBuyNode(kTechId.Adrenaline, kTechId.AdrenalineTech, kTechId.None, kTechId.AllAliens)
    
    self.techTree:AddResearchNode(kTechId.FeintTech, kTechId.TwoHives, kTechId.Shift)
    self.techTree:AddBuyNode(kTechId.Feint, kTechId.FeintTech, kTechId.TwoHives, kTechId.Fade)
    self.techTree:AddResearchNode(kTechId.SapTech, kTechId.TwoHives, kTechId.Shift)
    self.techTree:AddBuyNode(kTechId.Sap, kTechId.SapTech, kTechId.TwoHives, kTechId.Fade)
    
    self.techTree:AddResearchNode(kTechId.BoneShieldTech, kTechId.Crag, kTechId.TwoHives)
    self.techTree:AddBuyNode(kTechId.BoneShield, kTechId.BoneShieldTech, kTechId.None, kTechId.Onos)
    self.techTree:AddResearchNode(kTechId.StompTech, kTechId.ThreeHives, kTechId.None)
    self.techTree:AddBuyNode(kTechId.Stomp, kTechId.StompTech, kTechId.None, kTechId.Onos)

    self.techTree:SetComplete()
    
end

function AlienTeam:StructureCreated(entity)

    PlayingTeam.StructureCreated(self, entity)
    
    // When creating a new upgrade structure, assign it to a hive.
    if self.upgradeStructureManager:AddStructure(entity) then
        self.updateTechTreeAndHives = true        
    end
    
end

function AlienTeam:TechAdded(entity)

    PlayingTeam.TechAdded(self, entity)
    
    // When creating a new upgrade structure, assign it to a hive.
    if self.upgradeStructureManager:AddStructure(entity) then
        self.updateTechTreeAndHives = true        
    end
    
end

function AlienTeam:TechRemoved(entity)

    PlayingTeam.TechRemoved(self, entity)

    // When deleting an upgrade structure, remove it from hive if it was the last one
    if self.upgradeStructureManager:RemoveStructure(entity) then
        self.updateTechTreeAndHives = true
    end
    
end

// As upgrade structure and hives are created and destroyed, modify alien tech tree on the fly. Ie, if a Crag is built when we have 1 hive,
// Shifts and Shades now require 2 hives as a prereq. 
function AlienTeam:UpdateTechTreeAndHives()

    // For each tech in AlienTeam.kTechTreeIdsToUpdate, if not supported already, change it to be supported 
    // with 1 more hive than we currently hive
    for index, techId in pairs(AlienTeam.kTechTreeIdsToUpdate) do

        // Get prereq
        local prereq = self.upgradeStructureManager:GetPrereqForTech(techId)
        
        // Update tech tree
        local node = self.techTree:GetTechNode(techId)
        ASSERT(node)        

        if node:GetPrereq1() ~= prereq then
        
            node:SetPrereq1(prereq)        
            self.techTree:SetTechNodeChanged(node)
            
        end 
       
    end
    
    // Assign upgrade structures to hives so players can see what they support
    // {entity id, supporting tech id} pairs. kTechId.None when supporting nothing.
    for index, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
    
        if hive:GetIsBuilt() and hive:GetIsAlive() then
        
            local supportingTechId = kTechId.None
            
            for index, pair in ipairs(self.upgradeStructureManager:GetSupportingStructures()) do
            
                if hive:GetId() == pair[1] then
                
                    supportingTechId = pair[2]
                    break
                    
                end
                
            end
            
            hive:SetSupportingUpgradeTechId(supportingTechId)
            
        end
        
    end
    
end

function AlienTeam:ProcessGeneralHelp(player)

    if(GetGamerules():GetGameStarted() and player:AddTooltipOncePer("HOWTO_EVOLVE_TOOLTIP", 45)) then
        return true
    end
    
    return PlayingTeam.ProcessGeneralHelp(self, player)
    
end

function AlienTeam:UpdateTeamSpecificGameEffects(teamEntities, enemyPlayers)

    PROFILE("AlienTeam:UpdateTeamSpecificGameEffects")
    
    PlayingTeam.UpdateTeamSpecificGameEffects(self, teamEntities, enemyPlayers)

    // Update tech tree and hives from main loop, after entity lists 
    // have been updated.   
    if self.updateTechTreeAndHives then
    
        self:UpdateTechTreeAndHives()
        self.updateTechTreeAndHives = false
        
    end
    
    // Clear gameplay effect we're processing
    for index, entity in ipairs(teamEntities) do
    
        entity:SetGameEffectMask(kGameEffect.InUmbra, false)
        entity:SetGameEffectMask(kGameEffect.Cloaked, false)
                    
    end
    
    // Update umbra
    self:UpdateUmbraGameEffects(teamEntities)
    
    // Update Fury
    self:UpdateFuryGameEffects(teamEntities)
    
    // Update shades
    self:UpdateShadeEffects(teamEntities, enemyPlayers)

end

function AlienTeam:AddEgg(eggId)    
    table.insertunique(self.eggList, eggId)
end

function AlienTeam:RemoveEgg(eggId)
    table.removevalue(self.eggList, eggId)
end

// tries to find another available egg for a player
function AlienTeam:QueuePlayerForAnotherEgg(currentEggId, playerId, reverse)

    if self.eggList == nil then
        return false
    end
    
    local success = false       
    local eggCount = table.count(self.eggList)
    
    if eggCount > 0 then
    
        local takeNext = false
        // start with index 1 if player has no egg assigned
        local eggIndex = 1
        local listedEggId = 0
        
        if currentEggId then
            eggIndex = table.find(self.eggList, currentEggId)
        end
        
        ASSERT(eggIndex ~= nil, "Player used an invalid eggId.")
        
        for index = 1, eggCount do
            
            if reverse then
                eggIndex = eggIndex - 1         
            else
                eggIndex = eggIndex + 1
            end
            
            if eggIndex < 1 then
                eggIndex = table.count(self.eggList)
            elseif eggIndex > table.count(self.eggList) then
                eggIndex = 1
            end             
            
            listedEggId = self.eggList[eggIndex]            
            //Print("check egg (%s)", tostring(listedEggId))
            
            if self:QueuePlayerToEgg(listedEggId, playerId) then
            
                if currentEggId then // that should actually never be nil
                    Shared.GetEntity(currentEggId):SetEggFree()
                end
                
                successs = true
                break           
                
            end         
            
        end
            
    end
    
    return success

end

function AlienTeam:QueuePlayerToEgg(eggId, playerId)

    local success = false
    
    // made here another check, because I'm not sure if I will call the function from somewhere else where I don't check for that
    if Shared.GetEntity(eggId):GetIsFree() then
        Shared.GetEntity(eggId):SetQueuedPlayerId(playerId)
        success = true
    end
    
    return success

end

