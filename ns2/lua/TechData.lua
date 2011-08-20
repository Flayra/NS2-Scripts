// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechData.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A "database" of attributes for all units, abilities, structures, weapons, etc. in the game.
// Shared between client and server.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Commands
kBuildStructureCommand                  = "buildstructure"

// Set up structure data for easy use by Server.lua and model classes
// Store whatever data is necessary here and use LookupTechData to access
// Store any data that needs to used on both client and server here
// Lookup by key with LookupTechData()
kTechDataId                             = "id"
// Localizable string describing tech node
kTechDataDisplayName                    = "displayname"
kTechDataMapName                        = "mapname"
kTechDataModel                          = "model"
// TeamResources, resources or energy
kTechDataCostKey                        = "costkey"
kTechDataBuildTime                      = "buildtime"
// If an entity has this field, it's treated as a research node instead of a build node
kTechDataResearchTimeKey                = "researchTime"
kTechDataMaxHealth                      = "maxhealth"
kTechDataMaxArmor                       = "maxarmor"
kTechDataDamageType                     = "damagetype"
// Class that structure must be placed on top of (resource towers on resource points)
// If adding more attach classes, add them to GetIsAttachment()
kStructureAttachClass                   = "attachclass"
// Structure must be placed within kStructureAttachRange of this class, but it isn't actually attached.
// This can be a table of strings as well.
kStructureBuildNearClass                = "buildnearclass"
// Structure attaches to wall/roof
kStructureBuildOnWall                   = "buildonwall"
// If specified along with attach class, this entity can only be built within this range of an attach class (infantry portal near Command Station)
// If specified, you must also specify the tech id of the attach class.
// This can be a table of ids as well.
kStructureAttachRange                   = "attachrange"
// If specified, draw a range indicator for the commander when selected.
kVisualRange                            = "visualrange"
// The tech id of the attach class 
kStructureAttachId                      = "attachid"
// If specified, this tech is an alien class that can be gestated into
kTechDataGestateName                    = "gestateclass"
// If specified, how much time it takes to evolve into this class
kTechDataGestateTime                    = "gestatetime"
// If specified, object spawns this far off the ground
kTechDataSpawnHeightOffset              = "spawnheight"
// All player tech ids should have this, nothing else uses it
kTechDataMaxExtents                     = "maxextents"
// If specified, is amount of energy structure starts with
kTechDataInitialEnergy                  = "initialenergy"
// If specified, is max energy structure can have
kTechDataMaxEnergy                      = "maxenergy"
// Menu priority. If more than one techId is specified for the same spot in a menu, use the one with the higher priority.
// If a tech doesn't specify a priority, treat as 0. If all priorities are tied, show none of them. This is how Starcraft works (see siege behavior).
kTechDataMenuPriority                   = "menupriority"
// Indicates that the tech node is an upgrade of another tech node, so that the previous tech is still active (ie, if you upgrade a hive
// to an advanced hive, your team still has "hive" technology.
kTechDataUpgradeTech                    = "upgradetech"
// Set true if entity should be rotated before being placed
kTechDataSpecifyOrientation             = "specifyorientation"
// Point value for killing structure
kTechDataPointValue                     = "pointvalue"
// Set to false if not yet implemented, for displaying differently for not enabling
kTechDataImplemented                    = "implemented"
// Set to localizable string that will be added to end of description indicating date it went in. 
kTechDataNew                            = "new"
// For setting grow parameter on alien structures
kTechDataGrows                          = "grows"
// Commander hotkey. Not currently used.
kTechDataHotkey                         = "hotkey"
// Alert sound name
kTechDataAlertSound                     = "alertsound"
// Alert text for commander HUD
kTechDataAlertText                      = "alerttext"
// Alert type. These are the types in CommanderUI_GetDynamicMapBlips. "Request" alert types count as player alert requests and show up on the commander HUD as such.
kTechDataAlertType                      = "alerttype"
// Alert scope
kTechDataAlertTeam                      = "alertteam"
// Sound that plays for Comm and ordered players when given this order
kTechDataOrderSound                     = "ordersound"
// Don't send alert to originator of this alert 
kTechDataAlertOthersOnly                = "alertothers"
// Usage notes, caveats, etc. for use in commander tooltip (localizable)
kTechDataTooltipInfo                    = "tooltipinfo"
// Indicate tech id that we're replicating
// Engagement distance - how close can unit get to it before it can repair or build it
kTechDataEngagementDistance             = "engagementdist"
// Can only be built on infestation
kTechDataRequiresInfestation            = "requiresinfestation"
// Cannot be built on infestation (cannot be specified with kTechDataRequiresInfestation)
kTechDataNotOnInfestation               = "notoninfestation"
// Special ghost-guide method. Called with commander as argument, returns a map of entities with ranges to lit up.
kTechDataGhostGuidesMethod               = "ghostguidesmethod"
// Special requirements for building. Called with techId, the origin and normal for building location and the commander. Returns true if the special requirement is met.
kTechDataBuildRequiresMethod            = "buildrequiresmethod"

function BuildTechData()
    
    local techData = { 

        // Orders
        { [kTechDataId] = kTechId.Move,                  [kTechDataDisplayName] = "MOVE", [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "MOVE_TOOLTIP", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.Attack,                [kTechDataDisplayName] = "ATTACK", [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "ATTACK_TOOLTIP", [kTechDataOrderSound] = MarineCommander.kAttackOrderSoundName},
        { [kTechDataId] = kTechId.Build,                 [kTechDataDisplayName] = "BUILD", [kTechDataTooltipInfo] = "BUILD_TOOLTIP"},
        { [kTechDataId] = kTechId.Construct,             [kTechDataDisplayName] = "CONSTRUCT", [kTechDataOrderSound] = MarineCommander.kBuildStructureSound},
        { [kTechDataId] = kTechId.Cancel,                [kTechDataDisplayName] = "CANCEL", [kTechDataHotkey] = Move.ESC},
        { [kTechDataId] = kTechId.Weld,                  [kTechDataDisplayName] = "WELD", [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "WELD_TOOLTIP"},
        { [kTechDataId] = kTechId.Stop,                  [kTechDataDisplayName] = "STOP", [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "STOP_TOOLTIP"},
        { [kTechDataId] = kTechId.SetRally,              [kTechDataDisplayName] = "SET_RALLY_POINT", [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "RALLY_POINT_TOOLTIP"},
        { [kTechDataId] = kTechId.SetTarget,             [kTechDataDisplayName] = "SET_TARGET", [kTechDataHotkey] = Move.T, [kTechDataTooltipInfo] = "SET_TARGET_TOOLTIP"},
        
        // Ready room player is the default player, hence the ReadyRoomPlayer.kMapName
        { [kTechDataId] = kTechId.ReadyRoomPlayer,        [kTechDataDisplayName] = "READY_ROOM_PLAYER", [kTechDataMapName] = ReadyRoomPlayer.kMapName, [kTechDataModel] = Marine.kModelName },
        
        // Spectators classes.
        { [kTechDataId] = kTechId.Spectator,              [kTechDataModel] = "" },
        { [kTechDataId] = kTechId.AlienSpectator,         [kTechDataModel] = "" },
        
        // Marine classes
        { [kTechDataId] = kTechId.Marine,              [kTechDataDisplayName] = "MARINE", [kTechDataMapName] = Marine.kMapName, [kTechDataModel] = Marine.kModelName, [kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents), [kTechDataMaxHealth] = Marine.kHealth, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataPointValue] = kMarinePointValue},
        { [kTechDataId] = kTechId.Heavy,               [kTechDataDisplayName] = "HEAVY", [kTechDataMapName] = Heavy.kMapName, [kTechDataModel] = Heavy.kModelName, [kTechDataMaxExtents] = Vector(Heavy.kXZExtents, Heavy.kYExtents, Heavy.kXZExtents), [kTechDataMaxHealth] = Heavy.kHealth, [kTechDataEngagementDistance] = kHeavyEngagementDistance, [kTechDataPointValue] = kExosuitPointValue},
        { [kTechDataId] = kTechId.MarineCommander,     [kTechDataDisplayName] = "MARINE_COMMANDER", [kTechDataMapName] = MarineCommander.kMapName, [kTechDataModel] = ""},

        // Squads
        { [kTechDataId] = kTechId.SelectRedSquad,              [kTechDataDisplayName] = "RED_SQUAD", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectBlueSquad,             [kTechDataDisplayName] = "BLUE_SQUAD", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectGreenSquad,            [kTechDataDisplayName] = "GREEN_SQUAD", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectYellowSquad,           [kTechDataDisplayName] = "YELLOW_SQUAD", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SelectOrangeSquad,           [kTechDataDisplayName] = "ORANGE_SQUAD", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        
        // Marine orders
        { [kTechDataId] = kTechId.SquadMove,               [kTechDataDisplayName] = "MOVE", [kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName},
        { [kTechDataId] = kTechId.SquadAttack,             [kTechDataDisplayName] = "ATTACK", [kTechDataOrderSound] = MarineCommander.kAttackOrderSoundName},
        { [kTechDataId] = kTechId.SquadDefend,             [kTechDataDisplayName] = "DEFEND", [kTechDataOrderSound] = MarineCommander.kDefendTargetSound},
        { [kTechDataId] = kTechId.SquadSeekAndDestroy,     [kTechDataDisplayName] = "SEEK AND DESTROY", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.SquadHarass,             [kTechDataDisplayName] = "HARASS", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.SquadRegroup,            [kTechDataDisplayName] = "REGROUP", [kTechDataImplemented] = false},

        // Menus
        { [kTechDataId] = kTechId.RootMenu,              [kTechDataDisplayName] = "SELECT", [kTechDataHotkey] = Move.B, [kTechDataTooltipInfo] = "SELECT_TOOLTIP"},
        { [kTechDataId] = kTechId.BuildMenu,             [kTechDataDisplayName] = "BUILD", [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "BUILD_TOOLTIP"},
        { [kTechDataId] = kTechId.AdvancedMenu,          [kTechDataDisplayName] = "ADVANCED", [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "ADVANCED_TOOLTIP"},
        { [kTechDataId] = kTechId.AssistMenu,            [kTechDataDisplayName] = "ASSIST", [kTechDataHotkey] = Move.R, [kTechDataTooltipInfo] = "ASSIST_TOOLTIP"},
        { [kTechDataId] = kTechId.MarkersMenu,           [kTechDataDisplayName] = "MARKERS", [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "PHEROMONE_TOOLTIP", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.UpgradesMenu,          [kTechDataDisplayName] = "UPGRADES", [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "TEAM_UPGRADES_TOOLTIP"},

        // Marine menus
        { [kTechDataId] = kTechId.CommandStationUpgradesMenu,           [kTechDataDisplayName] = "COMMAND_STATION_UPGRADES", [kTechDataHotkey] = Move.C},
        { [kTechDataId] = kTechId.ArmsLabUpgradesMenu,                  [kTechDataDisplayName] = "PLAYER_UPGRADES", [kTechDataHotkey] = Move.U},
        //{ [kTechDataId] = kTechId.ArmoryEquipmentMenu,            [kTechDataDisplayName] = "EQUIPMENT_UPGRADES", [kTechDataHotkey] = Move.P},
        { [kTechDataId] = kTechId.RoboticsFactoryARCUpgradesMenu,            [kTechDataDisplayName] = "ARC_UPGRADES", [kTechDataHotkey] = Move.P},
        { [kTechDataId] = kTechId.RoboticsFactoryMACUpgradesMenu,            [kTechDataDisplayName] = "MAC_UPGRADES", [kTechDataHotkey] = Move.P},
        { [kTechDataId] = kTechId.PrototypeLabUpgradesMenu,            [kTechDataDisplayName] = "PROTOTYPE_LAB_UPGRADES", [kTechDataHotkey] = Move.P},
        
        // Misc.        
        { [kTechDataId] = kTechId.PowerPoint,            [kTechDataMapName] = PowerPoint.kMapName,            [kTechDataDisplayName] = "POWER_NODE",  [kTechDataCostKey] = 0,   [kTechDataMaxHealth] = PowerPoint.kHealth, [kTechDataMaxArmor] = PowerPoint.kArmor, [kTechDataBuildTime] = kPowerPointBuildTime, [kTechDataModel] = PowerPoint.kOnModelName, [kTechDataPointValue] = kPowerPointPointValue},        
        { [kTechDataId] = kTechId.ResourcePoint,         [kTechDataMapName] = ResourcePoint.kPointMapName,    [kTechDataDisplayName] = "RESOURCE_NOZZLE", [kTechDataModel] = ResourcePoint.kModelName},
        { [kTechDataId] = kTechId.TechPoint,             [kTechDataMapName] = TechPoint.kMapName,             [kTechDataDisplayName] = "TECH_POINT", [kTechDataModel] = TechPoint.kModelName},
        { [kTechDataId] = kTechId.Door,                  [kTechDataDisplayName] = "DOOR", [kTechDataMapName] = Door.kMapName, [kTechDataModel] = Door.kModelName},
        { [kTechDataId] = kTechId.DoorOpen,              [kTechDataDisplayName] = "OPEN_DOOR", [kTechDataHotkey] = Move.O, [kTechDataTooltipInfo] = "OPEN_DOOR_TOOLTIP"},
        { [kTechDataId] = kTechId.DoorClose,             [kTechDataDisplayName] = "CLOSE_DOOR", [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "CLOSE_DOOR_TOOLTIP"},
        { [kTechDataId] = kTechId.DoorLock,              [kTechDataDisplayName] = "LOCK_DOOR", [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "LOCKED_DOOR_TOOLTIP"},
        { [kTechDataId] = kTechId.DoorUnlock,            [kTechDataDisplayName] = "UNLOCK_DOOR", [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "UNLOCK_DOOR_TOOLTIP"},
        
        // Commander abilities
        { [kTechDataId] = kTechId.NanoDefense,           [kTechDataDisplayName] = "NANO_GRID_DEFNSE", [kTechDataCostKey] = kCommandCenterNanoGridCost, [kTechDataImplemented] = false, [kTechDataTooltipInfo] = "NANO_GRID_DEFNSE_TOOLTIP"},        
        
        // Command station and its buildables
        { [kTechDataId] = kTechId.CommandStation,  [kTechDataMapName] = CommandStation.kLevel1MapName,     [kTechDataDisplayName] = "COMMAND_STATION",     [kTechDataBuildTime] = kCommandStationBuildTime, [kTechDataCostKey] = kCommandStationCost, [kTechDataModel] = CommandStation.kModelName,             [kTechDataMaxHealth] = kCommandStationHealth, [kTechDataMaxArmor] = kCommandStationArmor,            [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 0, [kTechDataEngagementDistance] = kCommandStationEngagementDistance, [kTechDataInitialEnergy] = kCommandStationInitialEnergy,      [kTechDataMaxEnergy] = kCommandStationMaxEnergy, [kTechDataPointValue] = kCommandStationPointValue, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "COMMAND_STATION_TOOLTIP"},
        //{ [kTechDataId] = kTechId.TwoCommandStations,  [kTechDataDisplayName] = "TWO_COMMAND_STATIONS" },        
        //{ [kTechDataId] = kTechId.ThreeCommandStations,  [kTechDataDisplayName] = "THREE_COMMAND_STATIONS" },        

        { [kTechDataId] = kTechId.Recycle,               [kTechDataDisplayName] = "RECYCLE", [kTechDataCostKey] = 0,          [kTechDataResearchTimeKey] = kRecycleTime, [kTechDataHotkey] = Move.R, [kTechDataTooltipInfo] =  "RECYCLE_TOOLTIP"},
        { [kTechDataId] = kTechId.MAC,                   [kTechDataMapName] = MAC.kMapName,                      [kTechDataDisplayName] = "MAC",  [kTechDataMaxHealth] = MAC.kHealth, [kTechDataMaxArmor] = MAC.kArmor, [kTechDataCostKey] = kMACCost,            [kTechDataResearchTimeKey] = kMACBuildTime, [kTechDataModel] = MAC.kModelName,            [kTechDataDamageType] = kMACAttackDamageType,      [kTechDataMenuPriority] = 1, [kTechDataPointValue] = kMACPointValue, [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "MAC_TOOLTIP"},
        { [kTechDataId] = kTechId.AmmoPack,              [kTechDataMapName] = AmmoPack.kMapName,                 [kTechDataDisplayName] = "AMMO_PACK",           [kTechDataCostKey] = kAmmoPackCost,            [kTechDataModel] = AmmoPack.kModelName, [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "AMMO_PACK_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight },
        { [kTechDataId] = kTechId.MedPack,               [kTechDataMapName] = MedPack.kMapName,                  [kTechDataDisplayName] = "MED_PACK",            [kTechDataCostKey] = kMedPackCost,             [kTechDataModel] = MedPack.kModelName, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "MED_PACK_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight},
        { [kTechDataId] = kTechId.CatPack,               [kTechDataMapName] = CatPack.kMapName,                  [kTechDataDisplayName] = "CAT_PACK", [kTechDataImplemented] = false,            [kTechDataCostKey] = kCatPackCost,             [kTechDataModel] = CatPack.kModelName, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "CAT_PACK_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight},
        { [kTechDataId] = kTechId.CatPackTech,           [kTechDataCostKey] = kCatPackTechResearchCost,          [kTechDataResearchTimeKey] = kCatPackTechResearchTime, [kTechDataDisplayName] = "CAT_PACKS", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "CAT_PACK_TECH_TOOLTIP"},

        // Marine base structures
        { [kTechDataId] = kTechId.Extractor,             [kTechDataMapName] = Extractor.kMapName,                [kTechDataDisplayName] = "EXTRACTOR",           [kTechDataCostKey] = kExtractorCost,       [kTechDataBuildTime] = kExtractorBuildTime, [kTechDataEngagementDistance] = kExtractorEngagementDistance, [kTechDataModel] = Extractor.kModelName,            [kTechDataMaxHealth] = kExtractorHealth, [kTechDataMaxArmor] = kExtractorArmor, [kStructureAttachClass] = "ResourcePoint", [kTechDataPointValue] = kExtractorPointValue, [kTechDataHotkey] = Move.E, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] =  "EXTRACTOR_TOOLTIP"},
        { [kTechDataId] = kTechId.InfantryPortal,        [kTechDataMapName] = InfantryPortal.kMapName,           [kTechDataDisplayName] = "INFANTRY_PORTAL",     [kTechDataCostKey] = kInfantryPortalCost,   [kTechDataPointValue] = kInfantryPortalPointValue,   [kTechDataBuildTime] = kInfantryPortalBuildTime, [kTechDataMaxHealth] = kInfantryPortalHealth, [kTechDataMaxArmor] = kInfantryPortalArmor, [kTechDataModel] = InfantryPortal.kModelName, [kStructureBuildNearClass] = "CommandStation", [kStructureAttachId] = kTechId.CommandStation, [kStructureAttachRange] = kInfantryPortalAttachRange, [kTechDataEngagementDistance] = kInfantryPortalEngagementDistance, [kTechDataHotkey] = Move.P, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "INFANTRY_PORTAL_TOOLTIP"},
        //{ [kTechDataId] = kTechId.InfantryPortalTransponder,        [kTechDataMapName] = InfantryPortal.kMapName,           [kTechDataDisplayName] = "Infantry Portal with Transponder",     [kTechDataPointValue] = InfantryPortal.kTransponderPointValue,   [kTechDataMaxHealth] = kInfantryPortalTransponderHealth, [kTechDataMaxArmor] = kInfantryPortalTransponderArmor, [kTechDataModel] = InfantryPortal.kModelName, [kStructureBuildNearClass] = "CommandStation", [kStructureAttachId] = kTechId.CommandStation, [kStructureAttachRange] = kInfantryPortalAttachRange, [kTechDataHotkey] = Move.P, [kTechDataTooltipInfo] = string.format("Respawns marines and allows them to squad spawn")},
        { [kTechDataId] = kTechId.Armory,                [kTechDataMapName] = Armory.kMapName,                   [kTechDataDisplayName] = "ARMORY",              [kTechDataCostKey] = kArmoryCost,              [kTechDataBuildTime] = kArmoryBuildTime, [kTechDataMaxHealth] = kArmoryHealth, [kTechDataMaxArmor] = kArmoryArmor, [kTechDataEngagementDistance] = kArmoryEngagementDistance, [kTechDataModel] = Armory.kModelName, [kTechDataPointValue] = kArmoryPointValue, [kTechDataHotkey] = Move.A, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "ARMORY_TOOLTIP"},
        { [kTechDataId] = kTechId.ArmsLab,                [kTechDataMapName] = ArmsLab.kMapName,                 [kTechDataDisplayName] = "ARMS_LAB",             [kTechDataCostKey] = kArmsLabCost,              [kTechDataBuildTime] = kArmsLabBuildTime, [kTechDataMaxHealth] = kArmsLabHealth, [kTechDataMaxArmor] = kArmsLabArmor, [kTechDataEngagementDistance] = kArmsLabEngagementDistance, [kTechDataModel] = ArmsLab.kModelName, [kTechDataPointValue] = kArmsLabPointValue, [kTechDataHotkey] = Move.A, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "ARMS_LAB_TOOLTIP"},
        //{ [kTechDataId] = kTechId.SentryTech,            [kTechDataDisplayName] = "SENTRY TECH",                 [kTechDataCostKey] = kSentryTechCost,           [kTechDataResearchTimeKey] = kSentryTechResearchTime, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "Allows sentry turrets"},
        { [kTechDataId] = kTechId.Sentry,                [kTechDataMapName] = "sentry",                          [kTechDataDisplayName] = "SENTRY_TURRET",       [kTechDataCostKey] = kSentryCost,         [kTechDataPointValue] = kSentryPointValue, [kTechDataModel] = Sentry.kModelName,            [kTechDataBuildTime] = kSentryBuildTime, [kTechDataMaxHealth] = kSentryHealth,  [kTechDataMaxArmor] = kSentryArmor, [kTechDataDamageType] = kSentryAttackDamageType, [kTechDataSpecifyOrientation] = true, [kTechDataHotkey] = Move.S, [kTechDataInitialEnergy] = kSentryInitialEnergy,      [kTechDataMaxEnergy] = kSentryMaxEnergy, [kTechDataNotOnInfestation] = true, [kTechDataEngagementDistance] = kSentryEngagementDistance, [kTechDataTooltipInfo] = "SENTRY_TOOLTIP"},
        { [kTechDataId] = kTechId.SentryRefill,          [kTechDataDisplayName] = "SENTRY_REFILL",               [kTechDataCostKey] = kSentryRefillCost,         [kTechDataTooltipInfo] = "SENTRY_REFILL_TOOLTIP"},
        { [kTechDataId] = kTechId.PowerPack,             [kTechDataMapName] = "powerpack",                       [kTechDataDisplayName] = "POWER_PACK",          [kTechDataCostKey] = kPowerPackCost,      [kTechDataPointValue] = kPowerPackPointValue, [kTechDataModel] = PowerPack.kModelName,            [kTechDataBuildTime] = kPowerPackBuildTime, [kTechDataMaxHealth] = kPowerPackHealth,  [kTechDataMaxArmor] = kPowerPackArmor, [kTechDataTooltipInfo] = "POWER_PACK_TOOLTIP", [kTechDataHotkey] = Move.S, [kTechDataNotOnInfestation] = true, [kVisualRange] = PowerPack.kRange },

        // MACs 
        { [kTechDataId] = kTechId.MACMine,          [kTechDataMapName] = "mac_mine",             [kTechDataDisplayName] = "LAY_MINE", [kTechDataImplemented] = false,        [kTechDataCostKey] = kMACMineCost,         [kTechDataHotkey] = Move.I},
        { [kTechDataId] = kTechId.MACMinesTech,     [kTechDataCostKey] = kTechMinesResearchCost,             [kTechDataImplemented] = false, [kTechDataResearchTimeKey] = kTechMinesResearchTime, [kTechDataDisplayName] = "MAC_MINES"},
        { [kTechDataId] = kTechId.MACEMP,           [kTechDataDisplayName] = "EMP_BLAST", [kTechDataHotkey] = Move.E, [kTechDataImplemented] = false },        
        { [kTechDataId] = kTechId.MACEMPTech,       [kTechDataCostKey] = kTechEMPResearchCost,             [kTechDataResearchTimeKey] = kTechEMPResearchTime, [kTechDataDisplayName] = "EMP_ABILITY", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.MACSpeedTech,     [kTechDataDisplayName] = "MAC_SPEED",  [kTechDataCostKey] = kTechMACSpeedResearchCost,  [kTechDataResearchTimeKey] = kTechMACSpeedResearchTime, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "MAC_SPEED_TOOLTIP"},
        { [kTechDataId] = kTechId.AmmoPack,              [kTechDataMapName] = AmmoPack.kMapName,                 [kTechDataDisplayName] = "AMMO_PACK",           [kTechDataCostKey] = kAmmoPackCost,            [kTechDataModel] = AmmoPack.kModelName},        
        
        // Marine advanced structures
        { [kTechDataId] = kTechId.AdvancedArmory,        [kTechDataMapName] = AdvancedArmory.kMapName,                   [kTechDataDisplayName] = "ADVANCED_ARMORY",     [kTechDataCostKey] = kAdvancedArmoryUpgradeCost,  [kTechDataModel] = Armory.kModelName,                     [kTechDataMaxHealth] = kAdvancedArmoryHealth,   [kTechDataMaxArmor] = kAdvancedArmoryArmor,  [kTechDataEngagementDistance] = kArmoryEngagementDistance,  [kTechDataUpgradeTech] = kTechId.Armory, [kTechDataPointValue] = kAdvancedArmoryPointValue},
        { [kTechDataId] = kTechId.Observatory,           [kTechDataMapName] = Observatory.kMapName,    [kTechDataDisplayName] = "OBSERVATORY",  [kTechDataCostKey] = kObservatoryCost,       [kTechDataModel] = Observatory.kModelName,            [kTechDataBuildTime] = kObservatoryBuildTime, [kTechDataMaxHealth] = kObservatoryHealth,   [kTechDataEngagementDistance] = kObservatoryEngagementDistance, [kTechDataMaxArmor] = kObservatoryArmor,   [kTechDataInitialEnergy] = kObservatoryInitialEnergy,      [kTechDataMaxEnergy] = kObservatoryMaxEnergy, [kTechDataPointValue] = kObservatoryPointValue, [kTechDataHotkey] = Move.O, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "OBSERVATORY_TOOLTIP"},
        { [kTechDataId] = kTechId.Scan,                  [kTechDataMapName] = Scan.kMapName,           [kTechDataModel] = "", [kTechDataDisplayName] = "SCAN",      [kTechDataHotkey] = Move.S,   [kTechDataCostKey] = kObservatoryScanCost, [kTechDataTooltipInfo] = "SCAN_TOOLTIP"},
        { [kTechDataId] = kTechId.DistressBeacon,        [kTechDataDisplayName] = "DISTRESS_BEACON",   [kTechDataHotkey] = Move.B, [kTechDataCostKey] = kObservatoryDistressBeaconCost, [kTechDataTooltipInfo] =  "DISTRESS_BEACON_TOOLTIP"},
        { [kTechDataId] = kTechId.RoboticsFactory,       [kTechDataDisplayName] = "ROBOTICS_FACTORY",  [kTechDataMapName] = RoboticsFactory.kMapName, [kTechDataCostKey] = kRoboticsFactoryCost,       [kTechDataModel] = RoboticsFactory.kModelName,    [kTechDataEngagementDistance] = kRoboticsFactorEngagementDistance,        [kTechDataSpecifyOrientation] = true, [kTechDataBuildTime] = kRoboticsFactoryBuildTime, [kTechDataMaxHealth] = kRoboticsFactoryHealth,    [kTechDataMaxArmor] = kRoboticsFactoryArmor, [kTechDataPointValue] = kRoboticsFactoryPointValue, [kTechDataHotkey] = Move.R, [kTechDataNotOnInfestation] = true, [kTechDataTooltipInfo] = "ROBOTICS_FACTORY_TOOLTIP"},        
        { [kTechDataId] = kTechId.ARC,                   [kTechDataDisplayName] = "ARC",               [kTechDataMapName] = ARC.kMapName,   [kTechDataCostKey] = kARCCost,       [kTechDataDamageType] = kARCDamageType,  [kTechDataBuildTime] = kARCBuildTime, [kTechDataMaxHealth] = kARCHealth, [kTechDataEngagementDistance] = kARCEngagementDistance, [kVisualRange] = ARC.kFireRange, [kTechDataMaxArmor] = kARCArmor, [kTechDataModel] = ARC.kModelName, [kTechDataMaxHealth] = kARCHealth, [kTechDataPointValue] = kARCPointValue, [kTechDataHotkey] = Move.T},
        { [kTechDataId] = kTechId.ARCSplashTech,        [kTechDataCostKey] = kARCSplashTechResearchCost,             [kTechDataResearchTimeKey] = kARCSplashTechResearchTime, [kTechDataDisplayName] = "ARC_SPLASH", [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.ARCArmorTech,         [kTechDataCostKey] = kARCArmorTechResearchCost,             [kTechDataResearchTimeKey] = kARCArmorTechResearchTime, [kTechDataDisplayName] = "ARC_ARMOR", [kTechDataImplemented] = false },
        
        // Upgrades
        { [kTechDataId] = kTechId.ExtractorUpgrade,       [kTechDataCostKey] = kResourceUpgradeResearchCost,          [kTechDataResearchTimeKey] = kResourceUpgradeResearchTime, [kTechDataDisplayName] = string.format("Upgrade player resource production by %d%%", math.floor(kResourceUpgradeAmount*100)), [kTechDataHotkey] = Move.U },
        //{ [kTechDataId] = kTechId.InfantryPortalTransponderTech, [kTechDataCostKey] = kInfantryPortalTransponderTechResearchCost,            [kTechDataResearchTimeKey] = kInfantryPortalTransponderTechResearchTime, [kTechDataDisplayName] = "Transponder technology", [kTechDataTooltipInfo] = "Allows squad spawning from infantry portals", [kTechDataHotkey] = Move.T },
        //{ [kTechDataId] = kTechId.InfantryPortalTransponderUpgrade, [kTechDataCostKey] = kInfantryPortalTransponderUpgradeCost,            [kTechDataResearchTimeKey] = kInfantryPortalTransponderUpgradeTime, [kTechDataDisplayName] = "Add transponder", [kTechDataTooltipInfo] = "Allows marines to spawn with their squad", [kTechDataHotkey] = Move.T },
        { [kTechDataId] = kTechId.PhaseTech,             [kTechDataCostKey] = kPhaseTechResearchCost,                [kTechDataDisplayName] = "PHASE_TECH", [kTechDataResearchTimeKey] = kPhaseTechResearchTime, [kTechDataTooltipInfo] = "PHASE_TECH_TOOLTIP" },
        { [kTechDataId] = kTechId.PhaseGate,             [kTechDataMapName] = PhaseGate.kMapName,                    [kTechDataDisplayName] = "PHASE_GATE",  [kTechDataCostKey] = kPhaseGateCost,       [kTechDataModel] = PhaseGate.kModelName, [kTechDataBuildTime] = kPhaseGateBuildTime, [kTechDataMaxHealth] = kPhaseGateHealth,   [kTechDataEngagementDistance] = kPhaseGateEngagementDistance, [kTechDataMaxArmor] = kPhaseGateArmor,   [kTechDataPointValue] = kPhaseGatePointValue, [kTechDataHotkey] = Move.P, [kTechDataNotOnInfestation] = true, [kTechDataSpecifyOrientation] = true, [kTechDataTooltipInfo] = "PHASE_GATE_TOOLTIP"},
        { [kTechDataId] = kTechId.AdvancedArmoryUpgrade, [kTechDataCostKey] = kAdvancedArmoryUpgradeCost,            [kTechDataResearchTimeKey] = kAdvancedArmoryResearchTime,  [kTechDataHotkey] = Move.U, [kTechDataDisplayName] = "ADVANCED_ARMORY_UPGRADE", [kTechDataTooltipInfo] =  "ADVANCED_ARMORY_TOOLTIP"},
        //{ [kTechDataId] = kTechId.WeaponsModule,         [kTechDataCostKey] = kWeaponsModuleAddonCost,               [kTechDataResearchTimeKey] = kWeaponsModuleAddonTime,      [kTechDataDisplayName] = "Armory with Weapons module", [kTechDataMaxHealth] = kAdvancedArmoryHealth, [kTechDataUpgradeTech] = kTechId.AdvancedArmory, [kTechDataHotkey] = Move.W, [kTechDataTooltipInfo] = "Allows access to advanced weaponry", [kTechDataModel] = Armory.kModelName},
        { [kTechDataId] = kTechId.PrototypeLab,          [kTechDataCostKey] = kPrototypeLabCost,                     [kTechDataResearchTimeKey] = kPrototypeLabBuildTime,       [kTechDataDisplayName] = "PROTOTYPE_LAB", [kTechDataModel] = PrototypeLab.kModelName, [kTechDataMaxHealth] = kPrototypeLabHealth, [kTechDataPointValue] = kPrototypeLabPointValue, [kTechDataImplemented] = false, [kTechDataHotkey] = Move.P, [kTechDataTooltipInfo] = "PROTOTYPE_LAB_TOOLTIP"},
       
        // Weapons
        { [kTechDataId] = kTechId.Rifle,                 [kTechDataMapName] = Rifle.kMapName,                    [kTechDataDisplayName] = "RIFLE",         [kTechDataModel] = Rifle.kModelName, [kTechDataDamageType] = kRifleDamageType, [kTechDataCostKey] = kRifleCost,                                     },
        { [kTechDataId] = kTechId.Pistol,                [kTechDataMapName] = Pistol.kMapName,                   [kTechDataDisplayName] = "PISTOL",         [kTechDataModel] = Pistol.kModelName, [kTechDataDamageType] = kPistolDamageType, [kTechDataCostKey] = kPistolCost,                                     },
        { [kTechDataId] = kTechId.Axe,                   [kTechDataMapName] = Axe.kMapName,                      [kTechDataDisplayName] = "SWITCH_AX",         [kTechDataModel] = Axe.kModelName, [kTechDataDamageType] = kAxeDamageType, [kTechDataCostKey] = kAxeCost,                                     },
        { [kTechDataId] = kTechId.RifleUpgrade,          [kTechDataMapName] = Rifle.kMapName,                    [kTechDataDisplayName] = "RIFLE_UPGRADE", [kTechDataImplemented] = false, [kTechDataCostKey] = kRifleUpgradeCost,                       },
        { [kTechDataId] = kTechId.Shotgun,               [kTechDataMapName] = Shotgun.kMapName,                  [kTechDataDisplayName] = "SHOTGUN",             [kTechDataTooltipInfo] =  "SHOTGUN_TOOLTIP", [kTechDataModel] = Shotgun.kModelName, [kTechDataDamageType] = kShotgunDamageType, [kTechDataCostKey] = kShotgunCost, [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight, [kStructureBuildNearClass] = "Armory", [kStructureAttachId] = kTechId.Armory, [kStructureAttachRange] = kArmoryWeaponAttachRange },
        
        { [kTechDataId] = kTechId.FlamethrowerTech,      [kTechDataCostKey] = kFlamethrowerTechResearchCost,     [kTechDataResearchTimeKey] = kFlamethrowerTechResearchTime, [kTechDataDisplayName] = "RESEARCH_FLAMETHROWERS", [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] =  "FLAMETHROWER_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.FlamethrowerAltTech,   [kTechDataCostKey] = kFlamethrowerAltTechResearchCost,  [kTechDataResearchTimeKey] = kFlamethrowerAltTechResearchTime, [kTechDataDisplayName] = "RESEARCH_FLAMETHROWER_ALT", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.A, [kTechDataTooltipInfo] = "FLAMETHROWER_ALT_TOOLTIP"},
        { [kTechDataId] = kTechId.Flamethrower,          [kTechDataMapName] = Flamethrower.kMapName,             [kTechDataDisplayName] = "FLAMETHROWER", [kTechDataTooltipInfo] = "FLAMETHROWER_TOOLTIP", [kTechDataModel] = Flamethrower.kModelName,  [kTechDataDamageType] = kFlamethrowerDamageType, [kTechDataCostKey] = kFlamethrowerCost, [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight, [kStructureBuildNearClass] = "Armory", [kStructureAttachId] = kTechId.Armory, [kStructureAttachRange] = kArmoryWeaponAttachRange},
        { [kTechDataId] = kTechId.DualMinigunTech,       [kTechDataCostKey] = kDualMinigunTechResearchCost,      [kTechDataResearchTimeKey] = kDualMinigunTechResearchTime, [kTechDataDisplayName] = "RESEARCH_DUAL_MINIGUNS", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "DUAL_MINIGUN_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.Minigun,               [kTechDataMapName] = Minigun.kMapName,                  [kTechDataDisplayName] = "MINIGUN", [kTechDataImplemented] = false,        [kTechDataDamageType] = kMinigunDamageType,         [kTechDataCostKey] = kMinigunCost, [kTechDataModel] = Minigun.kModelName},
        { [kTechDataId] = kTechId.GrenadeLauncher,       [kTechDataMapName] = GrenadeLauncher.kMapName,          [kTechDataDisplayName] = "GRENADE_LAUNCHER",  [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_TOOLTIP",   [kTechDataModel] = GrenadeLauncher.kModelName,   [kTechDataDamageType] = kRifleDamageType,    [kTechDataCostKey] = kGrenadeLauncherCost, [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight, [kStructureBuildNearClass] = "Armory", [kStructureAttachId] = kTechId.Armory, [kStructureAttachRange] = kArmoryWeaponAttachRange},
        { [kTechDataId] = kTechId.NerveGasTech,          [kTechDataCostKey] = kNerveGasTechResearchCost,             [kTechDataResearchTimeKey] = kNerveGasTechResearchTime, [kTechDataDisplayName] = "RESEARCH_NERVE_GAS", [kTechDataTooltipInfo] = "NERVE_GAS_TOOLTIP", [kTechDataImplemented] = false },
        
        // Marine upgrades
        { [kTechDataId] = kTechId.NerveGas,              [kTechDataDisplayName] = "NERVE_GAS",  [kTechDataCostKey] = kNerveGasCost, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "NERVE_GAS_TOOLTIP"},        
        { [kTechDataId] = kTechId.FlamethrowerAlt,       [kTechDataDisplayName] = "FLAMETHROWER_ALT",  [kTechDataCostKey] = kFlamethrowerAltCost },        
        
        // Armor and upgrades
        { [kTechDataId] = kTechId.Jetpack,               [kTechDataMapName] = "jetpack",                   [kTechDataDisplayName] = "JETPACK", [kTechDataModel] = Jetpack.kModelName, [kTechDataCostKey] = kJetpackCost, [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight },
        { [kTechDataId] = kTechId.JetpackTech,           [kTechDataCostKey] = kJetpackTechResearchCost,               [kTechDataResearchTimeKey] = kJetpackTechResearchTime,     [kTechDataDisplayName] = "JETPACK_TECH" },
        { [kTechDataId] = kTechId.JetpackFuelTech,       [kTechDataCostKey] = kJetpackFuelTechResearchCost,           [kTechDataResearchTimeKey] = kJetpackFuelTechResearchTime,     [kTechDataDisplayName] = "JETPACK_FUEL_TECH", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.F, [kTechDataTooltipInfo] =  "JETPACK_FUEL_TOOLTIP"},
        { [kTechDataId] = kTechId.JetpackArmorTech,       [kTechDataCostKey] = kJetpackArmorTechResearchCost,         [kTechDataResearchTimeKey] = kJetpackArmorTechResearchTime,     [kTechDataDisplayName] = "JETPACK_ARMOR_TECH", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] = "JETPACK_ARMOR_TOOLTIP"},

        
        { [kTechDataId] = kTechId.Exoskeleton,           [kTechDataDisplayName] = "EXOSUIT", [kTechDataMapName] = "Exoskeleton", [kTechDataImplemented] = false,               [kTechDataCostKey] = kExoskeletonCost, [kTechDataHotkey] = Move.E, [kTechDataTooltipInfo] = "EXOSUIT_TECH_TOOLTIP", [kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight},
        { [kTechDataId] = kTechId.ExoskeletonTech,          [kTechDataDisplayName] = "RESEARCH_EXOSUITS", [kTechDataImplemented] = false, [kTechDataCostKey] = kExoskeletonTechResearchCost,  [kTechDataResearchTimeKey] = kExoskeletonTechResearchTime},
        { [kTechDataId] = kTechId.ExoskeletonLockdownTech,  [kTechDataCostKey] = kExoskeletonLockdownTechResearchCost,               [kTechDataResearchTimeKey] = kExoskeletonLockdownTechResearchTime,     [kTechDataDisplayName] = "EXOSUIT_LOCKDOWN_TECH", [kTechDataImplemented] = false, [kTechDataHotkey] = Move.L, [kTechDataTooltipInfo] = "EXOSUIT_LOCKDOWN_TOOLTIP"},
        { [kTechDataId] = kTechId.ExoskeletonUpgradeTech,  [kTechDataCostKey] = kExoskeletonUpgradeTechResearchCost,               [kTechDataResearchTimeKey] = kExoskeletonUpgradeTechResearchTime,     [kTechDataDisplayName] = "EXOSUIT_UPGRADE_TECH", [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.Armor1,                [kTechDataCostKey] = kArmor1ResearchCost,                   [kTechDataResearchTimeKey] = kArmor1ResearchTime,     [kTechDataDisplayName] = "MARINE_ARMOR1", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_ARMOR1_TOOLTIP"},
        { [kTechDataId] = kTechId.Armor2,                [kTechDataCostKey] = kArmor2ResearchCost,                   [kTechDataResearchTimeKey] = kArmor2ResearchTime,     [kTechDataDisplayName] = "MARINE_ARMOR2", [kTechDataHotkey] = Move.X, [kTechDataTooltipInfo] = "MARINE_ARMOR2_TOOLTIP"},
        { [kTechDataId] = kTechId.Armor3,                [kTechDataCostKey] = kArmor3ResearchCost,                   [kTechDataResearchTimeKey] = kArmor3ResearchTime,     [kTechDataDisplayName] = "MARINE_ARMOR3", [kTechDataHotkey] = Move.C, [kTechDataTooltipInfo] = "MARINE_ARMOR3_TOOLTIP"},

        // Weapons research
        { [kTechDataId] = kTechId.Weapons1,              [kTechDataCostKey] = kWeapons1ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons1ResearchTime,     [kTechDataDisplayName] = "MARINE_WEAPONS1", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_WEAPONS1_TOOLTIP"},
        { [kTechDataId] = kTechId.Weapons2,              [kTechDataCostKey] = kWeapons2ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons2ResearchTime,     [kTechDataDisplayName] = "MARINE_WEAPONS2", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_WEAPONS2_TOOLTIP"},
        { [kTechDataId] = kTechId.Weapons3,              [kTechDataCostKey] = kWeapons3ResearchCost,                 [kTechDataResearchTimeKey] = kWeapons3ResearchTime,     [kTechDataDisplayName] = "MARINE_WEAPONS3", [kTechDataHotkey] = Move.Z, [kTechDataTooltipInfo] = "MARINE_WEAPONS3_TOOLTIP"},
        { [kTechDataId] = kTechId.RifleUpgradeTech,      [kTechDataCostKey] = kRifleUpgradeTechResearchCost,         [kTechDataResearchTimeKey] = kRifleUpgradeTechResearchTime, [kTechDataDisplayName] = "RIFLE_UPGRADE", [kTechDataHotkey] = Move.U, [kTechDataImplemented] = false },
        { [kTechDataId] = kTechId.ShotgunTech,           [kTechDataCostKey] = kShotgunTechResearchCost,              [kTechDataResearchTimeKey] = kShotgunTechResearchTime, [kTechDataDisplayName] = "RESEARCH_SHOTGUNS", [kTechDataHotkey] = Move.S, [kTechDataTooltipInfo] =  "SHOTGUN_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.GrenadeLauncherTech,   [kTechDataCostKey] = kGrenadeLauncherTechResearchCost,      [kTechDataResearchTimeKey] = kGrenadeLauncherTechResearchTime, [kTechDataDisplayName] = "RESEARCH_GRENADE_LAUNCHERS", [kTechDataHotkey] = Move.G, [kTechDataTooltipInfo] = "GRENADE_LAUNCHER_TECH_TOOLTIP"},
        
        // ARC abilities
        { [kTechDataId] = kTechId.ARCDeploy,            [kTechDataCostKey] = 0,                                         [kTechDataResearchTimeKey] = kARCDeployTime, [kTechDataDisplayName] = "ARC_DEPLOY",                     [kTechDataMenuPriority] = 1, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "ARC_DEPLOY_TOOLTIP"},
        { [kTechDataId] = kTechId.ARCUndeploy,          [kTechDataCostKey] = 0,                                         [kTechDataResearchTimeKey] = kARCUndeployTime, [kTechDataDisplayName] = "ARC_UNDEPLOY",                    [kTechDataMenuPriority] = 2, [kTechDataHotkey] = Move.D, [kTechDataTooltipInfo] = "ARC_UNDEPLOY_TOOLTIP"},

        // Alien abilities for damage types
        { [kTechDataId] = kTechId.Bite,                  [kTechDataMapName] = BiteLeap.kMapName,        [kTechDataDamageType] = kBiteDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "BITE"},
        { [kTechDataId] = kTechId.Parasite,              [kTechDataMapName] = Parasite.kMapName,        [kTechDataDamageType] = kParasiteDamageType,    [kTechDataModel] = "", [kTechDataDisplayName] = "PARASITE"},
        { [kTechDataId] = kTechId.Spit,                  [kTechDataMapName] = SpitSpray.kMapName,       [kTechDataDamageType] = kSpitDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "SPIT"},
        { [kTechDataId] = kTechId.Spray,                 [kTechDataMapName] = SpitSpray.kMapName,       [kTechDataDamageType] = kHealsprayDamageType,   [kTechDataModel] = "", [kTechDataDisplayName] = "SPRAY"},
        { [kTechDataId] = kTechId.BileBomb,              [kTechDataMapName] = BileBomb.kMapName,        [kTechDataDamageType] = kBileBombDamageType,    [kTechDataModel] = "", [kTechDataDisplayName] = "BILEBOMB", [kTechDataCostKey] = kBileBombCost },
        { [kTechDataId] = kTechId.Spikes,                [kTechDataMapName] = Spikes.kMapName,          [kTechDataDamageType] = kSpikeDamageType,       [kTechDataModel] = "", [kTechDataDisplayName] = "SPIKES"},
        { [kTechDataId] = kTechId.SpikesAlt,             [kTechDataMapName] = Spikes.kMapName,          [kTechDataDamageType] = kSpikesAltDamageType,   [kTechDataModel] = "", [kTechDataDisplayName] = "SPIKES_ALT"},
        { [kTechDataId] = kTechId.Spores,                [kTechDataMapName] = Spores.kMapName,          [kTechDataDamageType] = kSporesDamageType,      [kTechDataModel] = "", [kTechDataDisplayName] = "SPORES"},
        { [kTechDataId] = kTechId.HydraSpike,            [kTechDataMapName] = HydraSpike.kMapName,      [kTechDataDamageType] = kHydraSpikeDamageType,  [kTechDataModel] = "", [kTechDataDisplayName] = "HYDRA_SPIKE"},
        { [kTechDataId] = kTechId.SwipeBlink,            [kTechDataMapName] = SwipeBlink.kMapName,      [kTechDataDamageType] = kSwipeDamageType,       [kTechDataModel] = "", [kTechDataDisplayName] = "SWIPE_BLINK"},
        { [kTechDataId] = kTechId.StabBlink,             [kTechDataMapName] = StabBlink.kMapName,       [kTechDataDamageType] = kStabDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "STAB_BLINK"},
        { [kTechDataId] = kTechId.Gore,                  [kTechDataMapName] = Gore.kMapName,            [kTechDataDamageType] = kGoreDamageType,        [kTechDataModel] = "", [kTechDataDisplayName] = "GORE"},
        
        // Alien structures (spawn hive at 110 units off ground = 2.794 meters)
        { [kTechDataId] = kTechId.Hive,                [kTechDataMapName] = Hive.kLevel1MapName,                   [kTechDataDisplayName] = "HIVE", [kTechDataCostKey] = kHiveCost,                     [kTechDataBuildTime] = kHiveBuildTime, [kTechDataModel] = Hive.kModelName,  [kTechDataHotkey] = Move.V,                [kTechDataMaxHealth] = kHiveHealth,  [kTechDataMaxArmor] = kHiveArmor,              [kStructureAttachClass] = "TechPoint",         [kTechDataSpawnHeightOffset] = 2.494,    [kTechDataInitialEnergy] = kHiveInitialEnergy,      [kTechDataMaxEnergy] = kHiveMaxEnergy, [kTechDataPointValue] = kHivePointValue, [kTechDataTooltipInfo] = "HIVE_TOOLTIP"},
        { [kTechDataId] = kTechId.TwoHives,            [kTechDataDisplayName] = "TWO_HIVES" },        
        { [kTechDataId] = kTechId.ThreeHives,          [kTechDataDisplayName] = "THREE_HIVES" },        
        
        // Drifter and tech
        { [kTechDataId] = kTechId.Drifter,               [kTechDataMapName] = Drifter.kMapName,                      [kTechDataDisplayName] = "DRIFTER",       [kTechDataCostKey] = kDrifterCost,              [kTechDataResearchTimeKey] = kDrifterBuildTime,     [kTechDataHotkey] = Move.D, [kTechDataMaxHealth] = Drifter.kHealth, [kTechDataMaxArmor] = kDrifterArmor, [kTechDataMaxArmor] = Drifter.kArmor, [kTechDataModel] = Drifter.kModelName, [kTechDataDamageType] = kDrifterAttackDamageType, [kTechDataPointValue] = kDrifterPointValue, [kTechDataTooltipInfo] = "DRIFTER_TOOLTIP"},   
        { [kTechDataId] = kTechId.DrifterFlareTech,      [kTechDataDisplayName] = "FLARE_RESEARCH",   [kTechDataTooltipInfo] = "DRIFTER_FLARE_TOOLTIP",        [kTechDataCostKey] = kDrifterFlareTechResearchCost,                                           [kTechDataResearchTimeKey] = kDrifterFlareTechResearchTime},
        { [kTechDataId] = kTechId.DrifterFlare,          [kTechDataDisplayName] = "FLARE", [kTechDataHotkey] = Move.F,                         [kTechDataCostKey] = 0, [kTechDataTooltipInfo] = "DRIFTER_FLARE_TOOLTIP"},
        { [kTechDataId] = kTechId.DrifterParasiteTech,   [kTechDataDisplayName] = "PARASITE_RESEARCH", [kTechDataTooltipInfo] = "DRIFTER_PARASITE_TECH_TOOLTIP",  [kTechDataHotkey] = Move.A, [kTechDataImplemented] = false,                               [kTechDataCostKey] = 10, [kTechDataTooltipInfo] = "DRIFTER_PARASITE_TECH_TOOLTIP"},        
        { [kTechDataId] = kTechId.DrifterParasite,       [kTechDataDisplayName] = "PARASITE", [kTechDataHotkey] = Move.P, [kTechDataImplemented] = false,                               [kTechDataCostKey] = 0, [kTechDataTooltipInfo] = "DRIFTER_PARASITE_TOOLTIP"},        
        
        // Alien buildables
        { [kTechDataId] = kTechId.Egg,                   [kTechDataMapName] = Egg.kMapName,                         [kTechDataDisplayName] = "EGG",       [kTechDataMaxHealth] = Egg.kHealth, [kTechDataMaxArmor] = Egg.kArmor, [kTechDataModel] = Egg.kModelName, [kTechDataPointValue] = kEggPointValue, [kTechDataBuildTime] = 1, [kTechDataCostKey] = 1, [kTechDataMaxExtents] = Vector(Skulk.kXExtents, Skulk.kYExtents, Skulk.kZExtents) }, 
        { [kTechDataId] = kTechId.Cocoon,                [kTechDataMapName] = Cocoon.kMapName,                         [kTechDataDisplayName] = "COCOON", [kTechDataImplemented] = false,       [kTechDataMaxHealth] = Cocoon.kHealth, [kTechDataMaxArmor] = Cocoon.kArmor, [kTechDataModel] = Cocoon.kModelName, [kTechDataBuildTime] = 1, [kTechDataCostKey] = 1}, 
        { [kTechDataId] = kTechId.Harvester,             [kTechDataMapName] = Harvester.kMapName,                    [kTechDataDisplayName] = "HARVESTER",  [kTechDataRequiresInfestation] = true,   [kTechDataCostKey] = kHarvesterCost,            [kTechDataBuildTime] = kHarvesterBuildTime, [kTechDataHotkey] = Move.H, [kTechDataMaxHealth] = kHarvesterHealth, [kTechDataMaxArmor] = kHarvesterArmor, [kTechDataModel] = Harvester.kModelName,           [kStructureAttachClass] = "ResourcePoint", [kTechDataPointValue] = kHarvesterPointValue, [kTechDataTooltipInfo] = "HARVESTER_TOOLTIP"},
        { [kTechDataId] = kTechId.HarvesterUpgrade,      [kTechDataCostKey] = kResourceUpgradeResearchCost,          [kTechDataResearchTimeKey] = kResourceUpgradeResearchTime, [kTechDataDisplayName] = string.format("Upgrade player resource production by %d%%", math.floor(kResourceUpgradeAmount*100)), [kTechDataHotkey] = Move.U },

        // Infestation
        { [kTechDataId] = kTechId.Infestation,           [kTechDataDisplayName] = "INFESTATION", [kTechDataModel] = "", [kTechDataMaxHealth] = Infestation.kMaxHealth },

        // Upgrade structures and research
        { [kTechDataId] = kTechId.Crag,                  [kTechDataMapName] = Crag.kMapName,                         [kTechDataDisplayName] = "CRAG",  [kTechDataCostKey] = kCragCost,     [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.C,       [kTechDataBuildTime] = kCragBuildTime, [kTechDataModel] = Crag.kModelName,           [kTechDataMaxHealth] = kCragHealth, [kTechDataMaxArmor] = kCragArmor,   [kTechDataInitialEnergy] = kCragInitialEnergy,      [kTechDataMaxEnergy] = kCragMaxEnergy, [kTechDataPointValue] = kCragPointValue, [kVisualRange] = Crag.kHealRadius, [kTechDataTooltipInfo] = "CRAG_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeCrag,           [kTechDataMapName] = Crag.kMapName,                         [kTechDataDisplayName] = "MATURE_CRAG_UPGRADE",  [kTechDataCostKey] = kMatureCragCost, [kTechDataResearchTimeKey] = kMatureCragResearchTime, [kTechDataHotkey] = Move.U, [kTechDataModel] = Crag.kModelName,  [kTechDataMaxHealth] = kMatureCragHealth, [kTechDataMaxArmor] = kMatureCragArmor,[kTechDataTooltipInfo] = "UPGRADE_CRAG_TOOLTIP", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.MatureCrag,            [kTechDataMapName] = MatureCrag.kMapName,                   [kTechDataDisplayName] = "MATURE_CRAG",             [kTechDataModel] = Crag.kModelName, [kTechDataCostKey] = kMatureCragCost, [kTechDataRequiresInfestation] = true, [kTechDataBuildTime] = kMatureCragBuildTime, [kTechDataMaxHealth] = kMatureCragHealth, [kTechDataInitialEnergy] = kCragInitialEnergy, [kTechDataMaxEnergy] = kMatureCragMaxEnergy, [kTechDataPointValue] = kMatureCragPointValue, [kVisualRange] = Crag.kHealRadius, [kTechDataTooltipInfo] = "MATURE_CRAG_TOOLTIP", [kTechDataGrows] = true, [kTechDataUpgradeTech] = kTechId.Crag},         
         
        { [kTechDataId] = kTechId.Whip,                  [kTechDataMapName] = Whip.kMapName,                         [kTechDataDisplayName] = "WHIP",  [kTechDataCostKey] = kWhipCost,    [kTechDataRequiresInfestation] = true, [kTechDataHotkey] = Move.W,        [kTechDataBuildTime] = kWhipBuildTime, [kTechDataModel] = Whip.kModelName,           [kTechDataMaxHealth] = kWhipHealth, [kTechDataMaxArmor] = kWhipArmor,   [kTechDataDamageType] = kDamageType.Structural, [kTechDataInitialEnergy] = kWhipInitialEnergy,      [kTechDataMaxEnergy] = kWhipMaxEnergy, [kVisualRange] = Whip.kRange, [kTechDataPointValue] = kWhipPointValue, [kTechDataTooltipInfo] = "WHIP_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.UpgradeWhip,           [kTechDataMapName] = Whip.kMapName,                         [kTechDataDisplayName] = "MATURE_WHIP_UPGRADE",  [kTechDataCostKey] = kMatureWhipCost, [kTechDataResearchTimeKey] = kMatureWhipResearchTime, [kTechDataHotkey] = Move.U, [kTechDataModel] = Whip.kModelName, [kTechDataTooltipInfo] = "UPGRADE_WHIP_TOOLTIP", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.MatureWhip,            [kTechDataMapName] = MatureWhip.kMapName,                   [kTechDataDisplayName] = "MATURE_WHIP",  [kTechDataModel] = Whip.kModelName, [kTechDataCostKey] = kMatureWhipCost, [kTechDataRequiresInfestation] = true, [kTechDataBuildTime] = kMatureWhipBuildTime,       [kTechDataMaxHealth] = kMatureWhipHealth,  [kTechDataMaxArmor] = kMatureWhipArmor,  [kTechDataInitialEnergy] = kMatureWhipInitialEnergy,      [kTechDataMaxEnergy] = kMatureWhipMaxEnergy, [kTechDataPointValue] = kMatureWhipPointValue, [kVisualRange] = Whip.kRange, [kTechDataTooltipInfo] = "MATURE_WHIP_TOOLTIP", [kTechDataGrows] = true, [kTechDataUpgradeTech] = kTechId.Whip },
        
        { [kTechDataId] = kTechId.Shift,                 [kTechDataMapName] = Shift.kMapName,                        [kTechDataDisplayName] = "SHIFT", [kTechDataImplemented] = false,   [kTechDataRequiresInfestation] = true, [kTechDataCostKey] = kShiftCost,    [kTechDataHotkey] = Move.S,        [kTechDataBuildTime] = kShiftBuildTime, [kTechDataModel] = Shift.kModelName,           [kTechDataMaxHealth] = kShiftHealth,  [kTechDataMaxArmor] = kShiftArmor,  [kTechDataInitialEnergy] = kShiftInitialEnergy,      [kTechDataMaxEnergy] = kShiftMaxEnergy, [kTechDataPointValue] = kShiftPointValue, [kVisualRange] = kEnergizeRange, [kTechDataTooltipInfo] = "SHIFT_TOOLTIP", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.UpgradeShift,          [kTechDataMapName] = Shift.kMapName,                        [kTechDataDisplayName] = "MATURE_SHIFT_UPGRADE", [kTechDataImplemented] = false, [kTechDataCostKey] = kMatureShiftCost, [kTechDataResearchTimeKey] = kMatureShiftResearchTime, [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "UPGRADE_SHIFT_TOOLTIP", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.MatureShift,           [kTechDataMapName] = MatureShift.kMapName,                  [kTechDataDisplayName] = "MATURE_SHIFT", [kTechDataImplemented] = false, [kTechDataCostKey] = kMatureShiftCost, [kTechDataModel] = Shift.kModelName,     [kTechDataBuildTime] = kMatureShiftBuildTime,      [kTechDataMaxHealth] = kMatureShiftHealth, [kTechDataMaxArmor] = kMatureShiftArmor,   [kTechDataMaxEnergy] = kMatureShiftMaxEnergy,      [kTechDataMaxEnergy] = kMatureShiftMaxEnergy, [kTechDataPointValue] = kMatureShiftPointValue, [kTechDataTooltipInfo] = "MATURE_SHIFT_TOOLTIP", [kTechDataGrows] = true },
        
        { [kTechDataId] = kTechId.Shade,                 [kTechDataMapName] = Shade.kMapName,                        [kTechDataDisplayName] = "SHADE",  [kTechDataCostKey] = kShadeCost,      [kTechDataRequiresInfestation] = true,     [kTechDataBuildTime] = kShadeBuildTime, [kTechDataHotkey] = Move.D, [kTechDataModel] = Shade.kModelName,           [kTechDataMaxHealth] = kShadeHealth, [kTechDataMaxArmor] = kShadeArmor,   [kTechDataInitialEnergy] = kShadeInitialEnergy,      [kTechDataMaxEnergy] = kShadeMaxEnergy, [kTechDataPointValue] = kShadePointValue, [kVisualRange] = Shade.kCloakRadius, [kTechDataMaxExtents] = Vector(1, 1.3, .4), [kTechDataTooltipInfo] = "SHADE_TOOLTIP", [kTechDataGrows] = true },
        { [kTechDataId] = kTechId.UpgradeShade,          [kTechDataMapName] = Shade.kMapName,                        [kTechDataDisplayName] = "MATURE_SHADE_UPGRADE",  [kTechDataCostKey] = kMatureShadeCost, [kTechDataImplemented] = false, [kTechDataResearchTimeKey] = kMatureShadeResearchTime, [kTechDataModel] = Shade.kModelName, [kTechDataHotkey] = Move.U, [kTechDataTooltipInfo] = "UPGRADE_SHADE_TOOLTIP", [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.MatureShade,           [kTechDataMapName] = MatureShade.kMapName,                  [kTechDataDisplayName] = "MATURE_SHADE",  [kTechDataModel] = Shade.kModelName,  [kTechDataCostKey] = kMatureShadeCost, [kTechDataImplemented] = false,   [kTechDataBuildTime] = kMatureShadeBuildTime,      [kTechDataMaxHealth] = kMatureShadeHealth,  [kTechDataMaxArmor] = kMatureShadeArmor,  [kTechDataInitialEnergy] = kMatureShadeInitialEnergy,      [kTechDataMaxEnergy] = kMatureShadeMaxEnergy, [kTechDataPointValue] = kMatureShadePointValue, [kTechDataHotkey] = Move.M, [kTechDataTooltipInfo] = "MATURE_SHADE_TOOLTIP", [kTechDataGrows] = true },
        
        { [kTechDataId] = kTechId.Hydra,                 [kTechDataMapName] = Hydra.kMapName,                        [kTechDataDisplayName] = "HYDRA",           [kTechDataCostKey] = kHydraCost,       [kTechDataBuildTime] = kHydraBuildTime, [kTechDataMaxHealth] = kHydraHealth, [kTechDataMaxArmor] = kHydraArmor, [kTechDataModel] = Hydra.kModelName, [kVisualRange] = Hydra.kRange, [kTechDataRequiresInfestation] = true, [kTechDataPointValue] = kHydraPointValue, [kTechDataGrows] = true},
        { [kTechDataId] = kTechId.Cyst,                 [kTechDataMapName] = Cyst.kMapName,                      [kTechDataDisplayName] = "CYST",     [kTechDataTooltipInfo] = "CYST_TOOLTIP",    [kTechDataCostKey] = kCystCost,       [kTechDataBuildTime] = kCystBuildTime, [kTechDataMaxHealth] = kCystHealth, [kTechDataMaxArmor] = kCystArmor, [kTechDataModel] = Cyst.kModelName, [kVisualRange] = Cyst.kInfestRadius, [kTechDataRequiresInfestation] = false, [kTechDataPointValue] = kCystPointValue, [kTechDataGrows] = false,  [kTechDataBuildRequiresMethod]=GetCystParentAvailable, [kTechDataGhostGuidesMethod]=GetCystGhostGuides, /* [kStructureBuildNearClass] = {"Hive", "Cyst"},  [kStructureAttachId] = {kTechId.Hive, kTechId.Cyst}, [kStructureAttachRange] = kHiveCystParentRange */} ,
        { [kTechDataId] = kTechId.MiniCyst,           [kTechDataMapName] = MiniCyst.kMapName,                  [kTechDataDisplayName] = "MINI_CYST",    [kTechDataCostKey] = kMiniCystCost,   [kTechDataBuildTime] = kMiniCystBuildTime, [kTechDataMaxHealth] = kMiniCystHealth, [kTechDataMaxArmor] = kMiniCystArmor, [kTechDataModel] = MiniCyst.kModelName, [kVisualRange] = MiniCyst.kInfestRadius, [kTechDataRequiresInfestation] = false, [kTechDataPointValue] = kMiniCystPointValue, [kTechDataGrows] = false},

        // Alien structure abilities and their energy costs
        { [kTechDataId] = kTechId.CragHeal,              [kTechDataDisplayName] = "HEAL",    [kTechDataHotkey] = Move.H,                       [kTechDataCostKey] = kCragHealCost, [kTechDataTooltipInfo] = "CRAG_HEAL_TOOLTIP"},
        { [kTechDataId] = kTechId.CragUmbra,             [kTechDataDisplayName] = "UMBRA",    [kTechDataHotkey] = Move.M,                      [kTechDataCostKey] = kCragUmbraCost, [kVisualRange] = Crag.kHealRadius, [kTechDataTooltipInfo] = "CRAG_UMBRA_TOOLTIP"},
        { [kTechDataId] = kTechId.CragBabblers,          [kTechDataDisplayName] = "BABBLERS",   [kTechDataHotkey] = Move.B,                    [kTechDataCostKey] = kCragBabblersCost },

        { [kTechDataId] = kTechId.WhipFury,              [kTechDataDisplayName] = "FURY",       [kTechDataTooltipInfo] = "WHIP_FURY_TOOLTIP", [kTechDataHotkey] = Move.F,                   [kTechDataCostKey] = kWhipFuryCost },
        { [kTechDataId] = kTechId.WhipBombard,           [kTechDataDisplayName] = "LOB",         [kTechDataTooltipInfo] = "WHIP_LOB_TOOLTIP", [kTechDataHotkey] = Move.L,                       [kTechDataCostKey] = kWhipBombardCost },

        { [kTechDataId] = kTechId.ShiftEcho,             [kTechDataDisplayName] = "ECHO",        [kTechDataHotkey] = Move.E,                    [kTechDataCostKey] = kShiftEchoCost, [kTechDataTooltipInfo] = "SHIFT_ECHO_TOOLTIP"},
        { [kTechDataId] = kTechId.ShiftRecall,           [kTechDataDisplayName] = "RECALL",      [kTechDataTooltipInfo] = "SHIFT_RECALL_TOOLTIP"},
        { [kTechDataId] = kTechId.ShiftEnergize,         [kTechDataDisplayName] = "ENERGIZE",    [kTechDataCostKey] = kShiftEnergizeCost},

        { [kTechDataId] = kTechId.ShadeDisorient,         [kTechDataDisplayName] = "DISORIENT",      [kTechDataHotkey] = Move.D,  [kTechDataTooltipInfo] = "SHADE_DISORIENT_TOOLTIP"},        
        { [kTechDataId] = kTechId.ShadeCloak,             [kTechDataDisplayName] = "CLOAK",      [kTechDataHotkey] = Move.C,                    [kTechDataCostKey] = kShadeCloakCost },        
        { [kTechDataId] = kTechId.ShadePhantasmMenu,      [kTechDataDisplayName] = "PHANTASM",     [kTechDataHotkey] = Move.P },
        //{ [kTechDataId] = kTechId.ShadePhantasmFade,      [kTechDataDisplayName] = "PHANTASM FADE",  [kTechDataModel] = Fade.kModelName,  [kTechDataMapName] = FadePhantasm.kMapName,  [kTechDataHotkey] = Move.F,                  [kTechDataCostKey] = kShadePhantasmFadeEnergyCost },
        // { [kTechDataId] = kTechId.ShadePhantasmOnos,      [kTechDataDisplayName] = "PHANTASM ONOS",  [kTechDataModel] = Onos.kModelName,  [kTechDataMapName] = OnosPhantasm.kMapName,  [kTechDataHotkey] = Move.O,                  [kTechDataCostKey] = kShadePhantasmOnosEnergyCost },
        //{ [kTechDataId] = kTechId.ShadePhantasmHive,      [kTechDataDisplayName] = "PHANTASM HIVE",  [kTechDataModel] = Hive.kModelName,  [kTechDataMapName] = HivePhantasm.kMapName,  [kTechDataHotkey] = Move.H,                  [kTechDataCostKey] = kShadePhantasmHiveEnergyCost,  [kStructureAttachClass] = "TechPoint", },
        
        { [kTechDataId] = kTechId.WhipUnroot,           [kTechDataDisplayName] = "UNROOT_WHIP",     [kTechDataTooltipInfo] = "UNROOT_WHIP_TOOLTIP"},
        { [kTechDataId] = kTechId.WhipRoot,             [kTechDataDisplayName] = "ROOT_WHIP",       [kTechDataTooltipInfo] = "ROOT_WHIP_TOOLTIP"},

        // Alien lifeforms
        { [kTechDataId] = kTechId.Skulk,                 [kTechDataMapName] = Skulk.kMapName, [kTechDataGestateName] = Skulk.kMapName,                      [kTechDataGestateTime] = kSkulkGestateTime, [kTechDataDisplayName] = "SKULK",           [kTechDataModel] = Skulk.kModelName, [kTechDataCostKey] = kSkulkCost, [kTechDataMaxHealth] = Skulk.kHealth, [kTechDataMaxArmor] = Skulk.kArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Skulk.kXExtents, Skulk.kYExtents, Skulk.kZExtents), [kTechDataPointValue] = kSkulkPointValue},
        { [kTechDataId] = kTechId.Gorge,                 [kTechDataMapName] = Gorge.kMapName, [kTechDataGestateName] = Gorge.kMapName,                      [kTechDataGestateTime] = kGorgeGestateTime, [kTechDataDisplayName] = "GORGE",           [kTechDataModel] = Gorge.kModelName,[kTechDataCostKey] = kGorgeCost, [kTechDataMaxHealth] = Gorge.kHealth, [kTechDataMaxArmor] = Gorge.kArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Gorge.kXZExtents, Gorge.kYExtents, Gorge.kXZExtents), [kTechDataPointValue] = kGorgePointValue},
        { [kTechDataId] = kTechId.Lerk,                  [kTechDataMapName] = Lerk.kMapName, [kTechDataGestateName] = Lerk.kMapName,                       [kTechDataGestateTime] = kLerkGestateTime, [kTechDataDisplayName] = "LERK",            [kTechDataModel] = Lerk.kModelName,[kTechDataCostKey] = kLerkCost, [kTechDataMaxHealth] = Lerk.kHealth, [kTechDataMaxArmor] = Lerk.kArmor, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxExtents] = Vector(Lerk.XZExtents, Lerk.YExtents, Lerk.XZExtents), [kTechDataPointValue] = kLerkPointValue},
        { [kTechDataId] = kTechId.Fade,                  [kTechDataMapName] = Fade.kMapName, [kTechDataGestateName] = Fade.kMapName,                       [kTechDataGestateTime] = kFadeGestateTime, [kTechDataDisplayName] = "FADE",            [kTechDataModel] = Fade.kModelName,[kTechDataCostKey] = kFadeCost, [kTechDataMaxHealth] = Fade.kHealth, [kTechDataEngagementDistance] = kPlayerEngagementDistance, [kTechDataMaxArmor] = Fade.kArmor, [kTechDataMaxExtents] = Vector(Fade.XZExtents, Fade.YExtents, Fade.XZExtents), [kTechDataPointValue] = kFadePointValue},        
        { [kTechDataId] = kTechId.Onos,                  [kTechDataMapName] = Onos.kMapName, [kTechDataGestateName] = Onos.kMapName,                       [kTechDataGestateTime] = kOnosGestateTime, [kTechDataDisplayName] = "ONOS", [kTechDataImplemented] = false,            [kTechDataModel] = Onos.kModelName,[kTechDataCostKey] = kOnosCost, [kTechDataMaxHealth] = Onos.kHealth, [kTechDataEngagementDistance] = kOnosEngagementDistance, [kTechDataMaxArmor] = Onos.kArmor, [kTechDataMaxExtents] = Vector(Onos.XExtents, Onos.YExtents, Onos.ZExtents), [kTechDataPointValue] = kOnosPointValue},
        { [kTechDataId] = kTechId.Embryo,                [kTechDataMapName] = Embryo.kMapName, [kTechDataGestateName] = Embryo.kMapName,                     [kTechDataDisplayName] = "EMBRYO", [kTechDataModel] = Embryo.kModelName, [kTechDataMaxExtents] = Vector(Embryo.kXExtents, Embryo.kYExtents, Embryo.kZExtents)},
        { [kTechDataId] = kTechId.AlienCommander,        [kTechDataMapName] = AlienCommander.kMapName, [kTechDataDisplayName] = "ALIEN COMMANDER", [kTechDataModel] = ""},
        
        // General alien upgrades
        { [kTechDataId] = kTechId.Melee1Tech,                  [kTechDataDisplayName] = "ALIEN_MELEE1", [kTechDataHotkey] = Move.M, [kTechDataCostKey] = kMelee1ResearchCost, [kTechDataResearchTimeKey] = kMelee1ResearchTime},        
        { [kTechDataId] = kTechId.Melee2Tech,                  [kTechDataDisplayName] = "ALIEN_MELEE2", [kTechDataCostKey] = kMelee2ResearchCost, [kTechDataResearchTimeKey] =  kMelee2ResearchTime},        
        { [kTechDataId] = kTechId.Melee3Tech,                  [kTechDataDisplayName] = "ALIEN_MELEE3", [kTechDataHotkey] = Move.M, [kTechDataCostKey] = kMelee3ResearchCost, [kTechDataResearchTimeKey] =  kMelee3ResearchTime},        
        { [kTechDataId] = kTechId.AlienArmor1Tech,             [kTechDataDisplayName] = "ALIEN_ARMOR1", [kTechDataHotkey] = Move.A, [kTechDataCostKey] = kAlienArmor1ResearchCost, [kTechDataResearchTimeKey] = kAlienArmor1ResearchTime},        
        { [kTechDataId] = kTechId.AlienArmor2Tech,             [kTechDataDisplayName] = "ALIEN_ARMOR2", [kTechDataHotkey] = Move.A, [kTechDataCostKey] = kAlienArmor2ResearchCost, [kTechDataResearchTimeKey] =  kAlienArmor2ResearchTime},        
        { [kTechDataId] = kTechId.AlienArmor3Tech,             [kTechDataDisplayName] = "ALIEN_ARMOR3", [kTechDataHotkey] = Move.A, [kTechDataCostKey] = kAlienArmor3ResearchCost, [kTechDataResearchTimeKey] =  kAlienArmor3ResearchTime},
        
        { [kTechDataId] = kTechId.FrenzyTech,             [kTechDataDisplayName] = "FRENZY", [kTechDataCostKey] = kFrenzyResearchCost, [kTechDataResearchTimeKey] =  kFrenzyResearchTime},
        { [kTechDataId] = kTechId.SwarmTech,             [kTechDataDisplayName] = "SWARM", [kTechDataCostKey] = kSwarmResearchCost, [kTechDataResearchTimeKey] =  kSwarmResearchTime},
        
        { [kTechDataId] = kTechId.CarapaceTech,                   [kTechDataDisplayName] = "CARAPACE", [kTechDataImplemented] = false,  [kTechDataCostKey] = kCarapaceResearchCost, [kTechDataResearchTimeKey] = kCarapaceResearchTime },                
        { [kTechDataId] = kTechId.RegenerationTech,               [kTechDataDisplayName] = "REGENERATION", [kTechDataImplemented] = false,  [kTechDataCostKey] = kRegenerationResearchCost, [kTechDataResearchTimeKey] = kRegenerationResearchTime },                
        
        { [kTechDataId] = kTechId.CamouflageTech,             [kTechDataDisplayName] = "CAMOUFLAGE", [kTechDataCostKey] = kCamouflageResearchCost, [kTechDataResearchTimeKey] =  kCamouflageResearchTime},

        // Lifeform research
        { [kTechDataId] = kTechId.BileBombTech,                 [kTechDataDisplayName] = "BILEBOMB_GORGE", [kTechDataCostKey] = kBileBombResearchCost, [kTechDataResearchTimeKey] = kBileBombResearchTime },                
        { [kTechDataId] = kTechId.LeapTech,                 [kTechDataDisplayName] = "LEAP_SKULK", [kTechDataCostKey] = kLeapResearchCost, [kTechDataResearchTimeKey] = kLeapResearchTime },                
        { [kTechDataId] = kTechId.AdrenalineTech,                 [kTechDataDisplayName] = "ADRENALINE", [kTechDataImplemented] = false,  [kTechDataCostKey] = kAdrenalineResearchCost, [kTechDataResearchTimeKey] = kAdrenalineResearchTime },                
        { [kTechDataId] = kTechId.PiercingTech,                 [kTechDataDisplayName] = "PIERCING", [kTechDataImplemented] = false,  [kTechDataCostKey] = kPiercingResearchCost, [kTechDataResearchTimeKey] = kPiercingResearchTime },        
        
        { [kTechDataId] = kTechId.FeintTech,                 [kTechDataDisplayName] = "FEINT", [kTechDataImplemented] = false,  [kTechDataCostKey] = kFeintResearchCost, [kTechDataResearchTimeKey] = kFeintResearchTime },                
        { [kTechDataId] = kTechId.SapTech,                 [kTechDataDisplayName] = "SAP", [kTechDataImplemented] = false,  [kTechDataCostKey] = kSapResearchCost, [kTechDataResearchTimeKey] = kSapResearchTime },                
        
        { [kTechDataId] = kTechId.BoneShieldTech,                 [kTechDataDisplayName] = "BONE_SHIELD", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBoneShieldResearchCost, [kTechDataResearchTimeKey] = kBoneShieldResearchTime },                
        { [kTechDataId] = kTechId.StompTech,                 [kTechDataDisplayName] = "STOMP", [kTechDataImplemented] = false,  [kTechDataCostKey] = kStompResearchCost, [kTechDataResearchTimeKey] = kStompResearchTime },                
        
        // Lifeform purchases
        { [kTechDataId] = kTechId.Carapace,                  [kTechDataDisplayName] = "CARAPACE",  [kTechDataCostKey] = kCarapaceCost },        
        { [kTechDataId] = kTechId.Regeneration,              [kTechDataDisplayName] = "REGENERATION",  [kTechDataCostKey] = kRegenerationCost },        
        { [kTechDataId] = kTechId.Leap,                  [kTechDataDisplayName] = "LEAP", [kTechDataCostKey] = kLeapCost },        
        { [kTechDataId] = kTechId.BileBomb,                  [kTechDataDisplayName] = "BILEBOMB", [kTechDataCostKey] = kBileBombCost },        
        { [kTechDataId] = kTechId.HydraAbility,                  [kTechDataDisplayName] = "BUILD_HYDRA",  [kTechDataCostKey] = kHydraAbilityCost /* cost for purchasing ability */ },        
        { [kTechDataId] = kTechId.Piercing,                  [kTechDataDisplayName] = "PIERCING ", [kTechDataTooltipInfo] = "PIERCING_TOOLTIP", [kTechDataCostKey] = kPiercingCost },        
        { [kTechDataId] = kTechId.Adrenaline,                  [kTechDataDisplayName] = "ADRENALINE", [kTechDataImplemented] = false,  [kTechDataCostKey] = kAdrenalineCost },        
        { [kTechDataId] = kTechId.Feint,                  [kTechDataDisplayName] = "FEINT", [kTechDataImplemented] = false,  [kTechDataCostKey] = kFeintCost },        
        { [kTechDataId] = kTechId.Sap,                  [kTechDataDisplayName] = "SAP", [kTechDataImplemented] = false,  [kTechDataCostKey] = kSapCost },        
        { [kTechDataId] = kTechId.Gore,                  [kTechDataDisplayName] = "GORE", [kTechDataDamageType] = kDamageType.Door, [kTechDataModel] = Onos.kViewModelName },        
        { [kTechDataId] = kTechId.Stomp,                  [kTechDataDisplayName] = "STOMP", [kTechDataImplemented] = false,  [kTechDataCostKey] = kStompCost },        
        { [kTechDataId] = kTechId.BoneShield,                  [kTechDataDisplayName] = "BONE_SHIELD", [kTechDataImplemented] = false,  [kTechDataCostKey] = kBoneShieldCost },        
        { [kTechDataId] = kTechId.Swarm,                  [kTechDataDisplayName] = "SWARM", [kTechDataTooltipInfo] = "SWARM_TOOLTIP", [kTechDataCostKey] = kSwarmCost },
        { [kTechDataId] = kTechId.Frenzy,                  [kTechDataDisplayName] = "FRENZY", [kTechDataTooltipInfo] = "FRENZY_TOOLTIP", [kTechDataCostKey] = kFrenzyCost },
        { [kTechDataId] = kTechId.Camouflage,                  [kTechDataDisplayName] = "CAMOUFLAGE", [kTechDataTooltipInfo] = "CAMOUFLAGE_TOOLTIP", [kTechDataCostKey] = kCamouflageCost },
        
        // Alien markers
        { [kTechDataId] = kTechId.ThreatMarker,                  [kTechDataDisplayName] = "MARK_THREAT", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.LargeThreatMarker,             [kTechDataDisplayName] = "MARK_THREAT_LARGE", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.NeedHealingMarker,             [kTechDataDisplayName] = "NEED_HEALING_HERE", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.WeakMarker,                    [kTechDataDisplayName] = "WEAK_HERE", [kTechDataImplemented] = false},
        { [kTechDataId] = kTechId.ExpandingMarker,               [kTechDataDisplayName] = "EXPANDING_HERE", [kTechDataImplemented] = false},

        { [kTechDataId] = kTechId.MetabolizeTech,   [kTechDataDisplayName] = "RESEARCH_METABOLIZE", [kTechDataCostKey] = kMetabolizeTechCost, [kTechDataImplemented] = false, [kTechDataResearchTimeKey] = kMetabolizeTechResearchTime, [kTechDataTooltipInfo] = "METABOLIZE_TECH_TOOLTIP"},
        { [kTechDataId] = kTechId.Metabolize,       [kTechDataDisplayName] = "METABOLIZE", [kTechDataCostKey] = kHiveMetabolizeCost, [kTechDataTooltipInfo] =  "METABOLIZE_TOOLTIP"},     
        
        // Alerts
        { [kTechDataId] = kTechId.MarineAlertSentryUnderAttack,                 [kTechDataAlertSound] = MarineCommander.kSentryTakingDamageSoundName,       [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "MARINE_ALERT_SENTRY_UNDERATTACK"},
        { [kTechDataId] = kTechId.MarineAlertSentryFiring,                      [kTechDataAlertSound] = MarineCommander.kSentryFiringSoundName,             [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_SENTRY_FIRING"},
        { [kTechDataId] = kTechId.MarineAlertSentryLowAmmo,                     [kTechDataAlertSound] = MarineCommander.kSentryLowAmmoSoundName,            [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_SENTRY_LOWAMMO"},
        { [kTechDataId] = kTechId.MarineAlertSentryNoAmmo,                      [kTechDataAlertSound] = MarineCommander.kSentryNoAmmoSoundName,             [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_SENTRY_NOAMMO"},
        { [kTechDataId] = kTechId.MarineAlertSoldierLost,                       [kTechDataAlertSound] = MarineCommander.kSoldierLostSoundName,              [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "MARINE_ALERT_SOLDIER_LOST",                  [kTechDataAlertOthersOnly] = true},
        { [kTechDataId] = kTechId.MarineAlertNeedAmmo,                          [kTechDataAlertSound] = MarineCommander.kSoldierNeedsAmmoSoundName,         [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "MARINE_ALERT_NEED_AMMO"},
        { [kTechDataId] = kTechId.MarineAlertNeedMedpack,                       [kTechDataAlertSound] = MarineCommander.kSoldierNeedsHealthSoundName,       [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "MARINE_ALERT_NEED_MEDPACK"},
        { [kTechDataId] = kTechId.MarineAlertNeedOrder,                         [kTechDataAlertSound] = MarineCommander.kSoldierNeedsOrderSoundName,        [kTechDataAlertType] = kAlertType.Request,  [kTechDataAlertText] = "MARINE_ALERT_NEED_ORDER"},
        { [kTechDataId] = kTechId.MarineAlertUpgradeComplete,                   [kTechDataAlertSound] = MarineCommander.kUpgradeCompleteSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_UPGRADE_COMPLETE"},
        { [kTechDataId] = kTechId.MarineAlertResearchComplete,                  [kTechDataAlertSound] = MarineCommander.kResearchCompleteSoundName,         [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_RESEARCH_COMPLETE"},
        { [kTechDataId] = kTechId.MarineAlertNotEnoughResources,                [kTechDataAlertSound] = Player.kNotEnoughResourcesSound,                    [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_NOT_ENOUGH_RESOURCES"},
        { [kTechDataId] = kTechId.MarineAlertMACBlocked,                        [kTechDataAlertType]  = kAlertType.Info,                                     [kTechDataAlertText] = "MARINE_ALERT_MAC_BLOCKED"},
        { [kTechDataId] = kTechId.MarineAlertOrderComplete,                     [kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,       [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_ORDER_COMPLETE"},        
        { [kTechDataId] = kTechId.MarineAlertStructureUnderAttack,              [kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,         [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "MARINE_ALERT_STRUCTURE_UNDERATTACK"},
        { [kTechDataId] = kTechId.MarineAlertExtractorUnderAttack,              [kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,         [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "MARINE_ALERT_EXTRACTOR_UNDERATTACK"},    
        { [kTechDataId] = kTechId.MarineAlertConstructionComplete,              [kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,       [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_CONSTRUCTION_COMPLETE"},        
        { [kTechDataId] = kTechId.MarineAlertCommandStationUnderAttack,         [kTechDataAlertSound] = CommandStation.kUnderAttackSound,                   [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "MARINE_ALERT_COMMANDSTATION_UNDERAT",  [kTechDataAlertTeam] = true},        
        { [kTechDataId] = kTechId.MarineAlertInfantryPortalUnderAttack,         [kTechDataAlertSound] = InfantryPortal.kUnderAttackSound,                   [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "MARINE_ALERT_INFANTRYPORTAL_UNDERAT",  [kTechDataAlertTeam] = true},        
        { [kTechDataId] = kTechId.MarineCommanderEjected,                       [kTechDataAlertSound] = MarineCommander.kCommanderEjectedSoundName,         [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "MARINE_ALERT_COMMANDER_EJECTED",    [kTechDataAlertTeam] = true},        
                
        { [kTechDataId] = kTechId.AlienAlertHiveUnderAttack,                    [kTechDataAlertSound] = Hive.kUnderAttackSound,                             [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "ALIEN_ALERT_HIVE_UNDERATTACK",             [kTechDataAlertTeam] = true},        
        { [kTechDataId] = kTechId.AlienAlertHiveDying,                          [kTechDataAlertSound] = Hive.kDyingSound,                                   [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "ALIEN_ALERT_HIVE_DYING",                 [kTechDataAlertTeam] = true},        
        { [kTechDataId] = kTechId.AlienAlertHiveComplete,                       [kTechDataAlertSound] = Hive.kCompleteSound,                                [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_HIVE_COMPLETE",    [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.AlienAlertUpgradeComplete,                    [kTechDataAlertSound] = AlienCommander.kUpgradeCompleteSoundName,           [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_UPGRADE_COMPLETE"},
        { [kTechDataId] = kTechId.AlienAlertResearchComplete,                   [kTechDataAlertSound] = AlienCommander.kResearchCompleteSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_RESEARCH_COMPLETE"},
        { [kTechDataId] = kTechId.AlienAlertStructureUnderAttack,               [kTechDataAlertSound] = AlienCommander.kStructureUnderAttackSound,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_STRUCTURE_UNDERATTACK",        [kTechDataAlertTeam] = true, [kTechDataAlertOthersOnly] = true},
        { [kTechDataId] = kTechId.AlienAlertHarvesterUnderAttack,               [kTechDataAlertSound] = AlienCommander.kHarvesterUnderAttackSound,          [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "ALIEN_ALERT_HARVESTER_UNDERATTACK",        [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.AlienAlertLifeformUnderAttack,                [kTechDataAlertSound] = AlienCommander.kLifeformUnderAttackSound,           [kTechDataAlertType] = kAlertType.Attack,   [kTechDataAlertText] = "ALIEN_ALERT_LIFEFORM_UNDERATTACK",         [kTechDataAlertTeam] = true},
        { [kTechDataId] = kTechId.AlienAlertGorgeBuiltHarvester,                [kTechDataAlertType] = kAlertType.Info,                                                                                 [kTechDataAlertText] = "ALIEN_ALERT_GORGEBUILT_HARVESTER"},
        { [kTechDataId] = kTechId.AlienAlertNotEnoughResources,                 [kTechDataAlertSound] = Alien.kNotEnoughResourcesSound,                     [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_NOTENOUGH_RESOURCES"},
        { [kTechDataId] = kTechId.AlienCommanderEjected,                        [kTechDataAlertSound] = AlienCommander.kCommanderEjectedSoundName,          [kTechDataAlertType] = kAlertType.Info,     [kTechDataAlertText] = "ALIEN_ALERT_COMMANDER_EJECTED",    [kTechDataAlertTeam] = true},        

    }

    return techData

end

kTechData = nil

function LookupTechId(fieldData, fieldName)

    // Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if fieldName == nil or fieldName == "" then
    
        Print("LookupTechId(%s, %s) called improperly.", tostring(fieldData), tostring(fieldName))
        return kTechId.None
        
    end

    for index,record in ipairs(kTechData) do 
    
        local currentField = record[fieldName]
        
        if(fieldData == currentField) then
        
            return record[kTechDataId]
            
        end

    end
    
    //Print("LookupTechId(%s, %s) returned kTechId.None", fieldData, fieldName)
    
    return kTechId.None

end

// Table of fieldName tables. Each fieldName table is indexed by techId and returns data.
local cachedTechData = {}

function ClearCachedTechData()
    cachedTechData = {}
end

// Returns true or false. If true, return output in "data"
function GetCachedTechData(techId, fieldName)
    
    local entry = cachedTechData[fieldName]
    
    if entry ~= nil then
    
        return entry[techId]
        
    end
        
    return nil
    
end

function SetCachedTechData(techId, fieldName, data)

    local inserted = false
    
    local entry = cachedTechData[fieldName]
    
    if entry == nil then
    
        cachedTechData[fieldName] = {}
        entry = cachedTechData[fieldName]
        
    end
    
    if entry[techId] == nil then
    
        entry[techId] = data
        inserted = true
        
    end
    
    return inserted
    
end

// Call with techId and fieldname (returns nil if field not found). Pass optional
// third parameter to use as default if not found.
function LookupTechData(techId, fieldName, default)

    // Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if techId == nil or techId == 0 or fieldName == nil or fieldName == "" then
    
        local techIdString = ""
        if type(tonumber(techId)) == "number" then            
            techIdString = EnumToString(kTechId, techId)
        end
        
        Print("LookupTechData(%s, %s, %s) called improperly.", tostring(techIdString), tostring(fieldName), tostring(default))
        return default
        
    end

    local data = GetCachedTechData(techId, fieldName)
    
    if data == nil then
    
        for index,record in ipairs(kTechData) do 
        
            local currentid = record[kTechDataId]

            if(techId == currentid and record[fieldName] ~= nil) then
            
                data = record[fieldName]
                
                break
                
            end
            
        end        
        
        if data == nil then
            data = default
        end
        
        if not SetCachedTechData(techId, fieldName, data) then
            //Print("Didn't insert anything when calling SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        else
            //Print("Inserted new field with SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        end
    
    end
    
    return data

end

// Returns true if specified class name is used to attach objects to
function GetIsAttachment(className)
    return (className == "TechPoint") or (className == "ResourcePoint")
end

function GetRecycleAmount(techId, upgradeLevel)

    local amount = GetCachedTechData(techId, kTechDataCostKey)
    if upgradeLevel == nil then
        upgradeLevel = 0
    end
    
    if techId == kTechId.Extractor then
        amount = GetCachedTechData(kTechId.Extractor, kTechDataCostKey) + upgradeLevel * GetCachedTechData(kTechId.ExtractorUpgrade, kTechDataCostKey)
    elseif techId == kTechId.Harvester then
        amount = GetCachedTechData(kTechId.Harvester, kTechDataCostKey) + upgradeLevel * GetCachedTechData(kTechId.HarvesterUpgrade, kTechDataCostKey)
        
    elseif techId == kTechId.AdvancedArmory then
        amount = GetCachedTechData(kTechId.Armory, kTechDataCostKey) + GetCachedTechData(kTechId.AdvancedArmoryUpgrade, kTechDataCostKey)
    end

    return amount
    
end