// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Armory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'Armory' (Structure)
Armory.kMapName = "armory"

Armory.kModelName = PrecacheAsset("models/marine/armory/armory.model")

// Looping sound while using the armory
Armory.kResupplySound = PrecacheAsset("sound/ns2.fev/marine/structures/armory_resupply")

Armory.kArmoryBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
Armory.kAttachPoint = "Root"

Armory.kAdvancedArmoryChildModel = PrecacheAsset("models/marine/advanced_armory/advanced_armory.model")

Armory.kBuyMenuFlash = "ui/marine_buy.swf"
Armory.kBuyMenuTexture = "ui/marine_buymenu.dds"
Armory.kBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
Armory.kThinkTime = .3
Armory.kHealAmount = 20
Armory.kResupplyInterval = .9

// Players can use menu and be supplied by armor inside this range
Armory.kResupplyUseRange = 2.5

if (Server) then
    Script.Load("lua/Armory_Server.lua")
else
    Script.Load("lua/Armory_Client.lua")
end
    
Armory.networkVars =
    {
        // How far out the arms are for animation (0-1)
        loggedInEast     = "boolean",
        loggedInNorth    = "boolean",
        loggedInSouth    = "boolean",
        loggedInWest     = "boolean",
    }

function GetArmory(entity)

    local teamArmories = GetEntitiesForTeamWithinRange("Armory", entity:GetTeamNumber(), entity:GetOrigin(), Armory.kResupplyUseRange)
    
    if table.count(teamArmories) > 0 then
    
        // TODO: Check facing to make sure player wants to use armory
        return teamArmories[1]
            
    end
    
    return nil

end

function Armory:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function Armory:OnInit()

    self:SetModel(Armory.kModelName)
    
    Structure.OnInit(self)
    
    // False if the player that's logged into a side is only nearby, true if
    // the pressed their key to open the menu to buy something. A player
    // must use the armory once "logged in" to be able to buy anything.
    
    self.loginEastAmount = 0
    self.loginNorthAmount = 0
    self.loginWestAmount = 0
    self.loginSouthAmount = 0
    
    self.timeScannedEast = 0
    self.timeScannedNorth = 0
    self.timeScannedWest = 0
    self.timeScannedSouth = 0

    self.loginNorthAmount = 0
    self.loginEastAmount = 0
    self.loginSouthAmount = 0
    self.loginWestAmount = 0

    if Server then    
    
        self.loggedInArray = {false, false, false, false}
        
        // Use entityId as index, store time last resupplied
        self.resuppliedPlayers = {}

        self:SetNextThink(Armory.kThinkTime)
        
        self:SetAnimation(Structure.kAnimSpawn)
        
    end
    
end

function Armory:GetRequiresPower()
    return true
end

function Armory:GetTechIfResearched(buildId, researchId)

    local techTree = nil
    if Server then
        techTree = self:GetTeam():GetTechTree()
    else
        techTree = GetTechTree()
    end
    ASSERT(techTree ~= nil)
    
    // If we don't have the research, return it, otherwise return buildId
    local researchNode = techTree:GetTechNode(researchId)
    ASSERT(researchNode ~= nil)
    ASSERT(researchNode:GetIsResearch())
    return ConditionalValue(researchNode:GetResearched(), buildId, researchId)
    
end

function Armory:GetTechButtons(techId)

    local techButtons = nil
    
    if(techId == kTechId.RootMenu) then 
    
        techButtons = { kTechId.ShotgunTech, kTechId.GrenadeLauncherTech, kTechId.FlamethrowerTech, kTechId.None,
                        kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    
        // Show button to upgraded to advanced armory
        if(self:GetTechId() == kTechId.Armory) then        
        
            techButtons[kMarineUpgradeButtonIndex] = kTechId.AdvancedArmoryUpgrade
            
        end
        
    end
    
    return techButtons
    
end

function Armory:UpdateArmoryAnim(extension, loggedIn, scanTime, timePassed)

    local loggedInName = "log_" .. extension
    local loggedInParamValue = ConditionalValue(loggedIn, 1, 0)

    if extension == "n" then
        self.loginNorthAmount = Clamp(Slerp(self.loginNorthAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginNorthAmount)
    elseif extension == "s" then
        self.loginSouthAmount = Clamp(Slerp(self.loginSouthAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginSouthAmount)
    elseif extension == "e" then
        self.loginEastAmount = Clamp(Slerp(self.loginEastAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginEastAmount)
    elseif extension == "w" then
        self.loginWestAmount = Clamp(Slerp(self.loginWestAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginWestAmount)
    end
    
    local scannedName = "scan_" .. extension
    local scannedParamValue = ConditionalValue(scanTime == 0 or (Shared.GetTime() > scanTime + 3), 0, 1)
    self:SetPoseParam(scannedName, scannedParamValue)
    
end

function Armory:UpdatePoseParams(childModels)

    local researching = self.researchingId ~= kTechId.None
    
    local children = GetChildEntities(self, "ScriptActor")
    
    // Get child model and set "spawn" progress according to research time
    for index, child in ipairs(children) do
    
        if table.contains(childModels, child:GetModelName()) then
        
            local spawnValue = 1
            if researching then
                spawnValue = self.researchProgress
            end
            child:SetPoseParam("spawn", spawnValue)
            
        end
        
    end
    
end

function Armory:OnUpdate(deltaTime)

    if self:GetIsBuilt() then
    
        // Update animation for add-on modules as they're being built.
        self:UpdatePoseParams({ Armory.kAdvancedArmoryChildModel })
        
        // Set pose parameters according to if we're logged in or not
        self:UpdateArmoryAnim("e", self.loggedInEast, self.timeScannedEast, deltaTime)
        self:UpdateArmoryAnim("n", self.loggedInNorth, self.timeScannedNorth, deltaTime)
        self:UpdateArmoryAnim("w", self.loggedInWest, self.timeScannedWest, deltaTime)
        self:UpdateArmoryAnim("s", self.loggedInSouth, self.timeScannedSouth, deltaTime)
        
    end
    
    Structure.OnUpdate(self, deltaTime)
    
end

Shared.LinkClassToMap("Armory", Armory.kMapName, Armory.networkVars)

class 'AdvancedArmory' (Armory)

AdvancedArmory.kMapName = "advancedarmory"

Shared.LinkClassToMap("AdvancedArmory", AdvancedArmory.kMapName, {})

class 'ArmoryAddon' (ScriptActor)

ArmoryAddon.kMapName = "ArmoryAddon"

if Server then

    PrepareClassForMixin(ArmoryAddon, LOSMixin)

    function ArmoryAddon:OnCreate()
        ScriptActor.OnCreate(self)
        InitMixin(self, LOSMixin)
    end
    
    function ArmoryAddon:OverrideVisionRadius()
        return LOSMixin.kStructureMinLOSDistance
    end
    
end

Shared.LinkClassToMap("ArmoryAddon", ArmoryAddon.kMapName)

