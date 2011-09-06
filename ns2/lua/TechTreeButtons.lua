// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTreeButtons.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Hard-coded data which maps tech tree constants to indices into a texture. Used to display
// icons in the commander build menu and alien buy menu.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// These are the icons that appear next to alerts or as hotkey icons.
// Icon size should be 20x20. Also used for the alien buy menu.
function CommanderUI_Icons()

    local player = Client.GetLocalPlayer()
    if(player and (player:isa("Alien") or player:isa("AlienCommander"))) then
        return "alien_upgradeicons"
    end
    
    return "marine_upgradeicons"

end

function CommanderUI_MenuImage()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return "alien_buildmenu"
    end
    
    return "marine_buildmenu"
    
end

function CommanderUI_MenuImageSize()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return 640, 1040
    end
    
    return 960, 960
    
end

// Init marine offsets
kMarineTechIdToMaterialOffset = {}

// Init alien offsets
kAlienTechIdToMaterialOffset = {}

// Create arrays that convert between tech ids and the offsets within
// the button images used to display their buttons. Look in marine_buildmenu.psd 
// and alien_buildmenu.psd to understand these indices.
function InitTechTreeMaterialOffsets()

    // Init marine offsets
    kMarineTechIdToMaterialOffset = {}

    // Init alien offsets
    kAlienTechIdToMaterialOffset = {}

    // First row
    kMarineTechIdToMaterialOffset[kTechId.CommandStation] = 0
    kMarineTechIdToMaterialOffset[kTechId.CommandStationUpgradesMenu] = 68
    
    kMarineTechIdToMaterialOffset[kTechId.Armory] = 1
    kMarineTechIdToMaterialOffset[kTechId.RifleUpgradeTech] = 66
    kMarineTechIdToMaterialOffset[kTechId.MAC] = 2
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing extractor
    kMarineTechIdToMaterialOffset[kTechId.Extractor] = 3
    kMarineTechIdToMaterialOffset[kTechId.InfantryPortal] = 4
    kMarineTechIdToMaterialOffset[kTechId.Sentry] = 5
    kMarineTechIdToMaterialOffset[kTechId.RoboticsFactory] = 6
    kMarineTechIdToMaterialOffset[kTechId.Observatory] = 7
    kMarineTechIdToMaterialOffset[kTechId.PrototypeLab] = 9
    kMarineTechIdToMaterialOffset[kTechId.PowerPoint] = 10    
    // TODO: Change this
    kMarineTechIdToMaterialOffset[kTechId.PowerPack] = 10
    kMarineTechIdToMaterialOffset[kTechId.ArmsLab] = 11
    
    // Second row - Non-player orders
    kMarineTechIdToMaterialOffset[kTechId.Recycle] = 12
    kMarineTechIdToMaterialOffset[kTechId.Move] = 13
    kMarineTechIdToMaterialOffset[kTechId.Stop] = 14
    kMarineTechIdToMaterialOffset[kTechId.RootMenu] = 15
    kMarineTechIdToMaterialOffset[kTechId.Cancel] = 16
    //kMarineTechIdToMaterialOffset[kTechId.] = 17 // MAC build
    
    kMarineTechIdToMaterialOffset[kTechId.Attack] = 18
    kMarineTechIdToMaterialOffset[kTechId.SetRally] = 19
    kMarineTechIdToMaterialOffset[kTechId.SetTarget] = 28
    kMarineTechIdToMaterialOffset[kTechId.Weld] = 21
    kMarineTechIdToMaterialOffset[kTechId.BuildMenu] = 22
    kMarineTechIdToMaterialOffset[kTechId.AdvancedMenu] = 23    
    
    // Third row - Player/squad orders
    kMarineTechIdToMaterialOffset[kTechId.SquadMove] = 24
    kMarineTechIdToMaterialOffset[kTechId.SquadAttack] = 25
    // nothing for 26
    kMarineTechIdToMaterialOffset[kTechId.SquadDefend] = 27
    kMarineTechIdToMaterialOffset[kTechId.SquadHarass] = 28
    // "converge" for 29
    // "alert" for 30
    kMarineTechIdToMaterialOffset[kTechId.SquadRegroup] = 31
    kMarineTechIdToMaterialOffset[kTechId.SquadSeekAndDestroy] = 32    
    kMarineTechIdToMaterialOffset[kTechId.AssistMenu] = 33
    
    // Fourth row - droppables, research
    kMarineTechIdToMaterialOffset[kTechId.AmmoPack] = 36
    kMarineTechIdToMaterialOffset[kTechId.MedPack] = 37
    kMarineTechIdToMaterialOffset[kTechId.JetpackTech] = 40
    kMarineTechIdToMaterialOffset[kTechId.Jetpack] = 40
    kMarineTechIdToMaterialOffset[kTechId.Scan] = 41
    kMarineTechIdToMaterialOffset[kTechId.FlamethrowerTech] = 42
    kMarineTechIdToMaterialOffset[kTechId.Flamethrower] = 42
    kMarineTechIdToMaterialOffset[kTechId.FlamethrowerAltTech] = 42
    kMarineTechIdToMaterialOffset[kTechId.SentryTech] = 43
    kMarineTechIdToMaterialOffset[kTechId.SentryRefill] = 36
    kMarineTechIdToMaterialOffset[kTechId.ARC] = 44
    kMarineTechIdToMaterialOffset[kTechId.CatPack] = 45
    kMarineTechIdToMaterialOffset[kTechId.CatPackTech] = 45
    kMarineTechIdToMaterialOffset[kTechId.NerveGasTech] = 46
    kMarineTechIdToMaterialOffset[kTechId.DualMinigunTech] = 47
    
    // Fifth row 
    kMarineTechIdToMaterialOffset[kTechId.ShotgunTech] = 48
    kMarineTechIdToMaterialOffset[kTechId.Shotgun] = 48
    kMarineTechIdToMaterialOffset[kTechId.Armor1] = 49
    kMarineTechIdToMaterialOffset[kTechId.Armor2] = 50
    kMarineTechIdToMaterialOffset[kTechId.Armor3] = 51
    kMarineTechIdToMaterialOffset[kTechId.NanoDefense] = 52
    
    // upgrades
    kMarineTechIdToMaterialOffset[kTechId.Weapons1] = 55
    kMarineTechIdToMaterialOffset[kTechId.Weapons2] = 56
    kMarineTechIdToMaterialOffset[kTechId.Weapons3] = 57
    kMarineTechIdToMaterialOffset[kTechId.CommandStationUpgradesMenu] = 58
    //kMarineTechIdToMaterialOffset[kTechId.ArmoryEquipmentMenu] = 59
    kMarineTechIdToMaterialOffset[kTechId.ArmsLabUpgradesMenu] = 59
    
    kMarineTechIdToMaterialOffset[kTechId.Marine] = 60
    kMarineTechIdToMaterialOffset[kTechId.Heavy] = 61
    kMarineTechIdToMaterialOffset[kTechId.MACEMPTech] = 62
    kMarineTechIdToMaterialOffset[kTechId.MACEMP] = 62
    kMarineTechIdToMaterialOffset[kTechId.DistressBeacon] = 63
    kMarineTechIdToMaterialOffset[kTechId.ExtractorUpgrade] = 64
    kMarineTechIdToMaterialOffset[kTechId.AdvancedArmory] = 65
    kMarineTechIdToMaterialOffset[kTechId.AdvancedArmoryUpgrade] = 65
    kMarineTechIdToMaterialOffset[kTechId.RifleUpgradeTech] = 66
    kMarineTechIdToMaterialOffset[kTechId.PhaseGate] = 67
    kMarineTechIdToMaterialOffset[kTechId.PhaseTech] = 68
    kMarineTechIdToMaterialOffset[kTechId.ARCSplashTech] = 69
    kMarineTechIdToMaterialOffset[kTechId.ARCArmorTech] = 70

    kMarineTechIdToMaterialOffset[kTechId.GrenadeLauncherTech] = 72
    kMarineTechIdToMaterialOffset[kTechId.GrenadeLauncher] = 72
    kMarineTechIdToMaterialOffset[kTechId.JetpackFuelTech] = 73      
    kMarineTechIdToMaterialOffset[kTechId.JetpackArmorTech] = 74
    kMarineTechIdToMaterialOffset[kTechId.ExoskeletonTech] = 75
    kMarineTechIdToMaterialOffset[kTechId.Exoskeleton] = 76
    kMarineTechIdToMaterialOffset[kTechId.ExoskeletonLockdownTech] = 77    
    kMarineTechIdToMaterialOffset[kTechId.ARCDeploy] = 78     
    kMarineTechIdToMaterialOffset[kTechId.ARCUndeploy] = 79
    
    kMarineTechIdToMaterialOffset[kTechId.MACMinesTech] = 80
    kMarineTechIdToMaterialOffset[kTechId.MACMine] = 81
    kMarineTechIdToMaterialOffset[kTechId.MACSpeedTech] = 82
        
    // Doors
    kMarineTechIdToMaterialOffset[kTechId.Door] = 84
    kMarineTechIdToMaterialOffset[kTechId.DoorOpen] = 85
    kMarineTechIdToMaterialOffset[kTechId.DoorClose] = 86
    kMarineTechIdToMaterialOffset[kTechId.DoorLock] = 87
    kMarineTechIdToMaterialOffset[kTechId.DoorUnlock] = 88
    // 89 = nozzle
    // 90 = tech point
    
    // Robotics factory menus
    kMarineTechIdToMaterialOffset[kTechId.RoboticsFactoryARCUpgradesMenu] = 91
    kMarineTechIdToMaterialOffset[kTechId.RoboticsFactoryMACUpgradesMenu] = 93
    kMarineTechIdToMaterialOffset[kTechId.PrototypeLab] = 93
    kMarineTechIdToMaterialOffset[kTechId.PrototypeLabUpgradesMenu] = 94        
    
    kMarineTechIdToMaterialOffset[kTechId.SelectRedSquad] = 96
    kMarineTechIdToMaterialOffset[kTechId.SelectBlueSquad] = 97
    kMarineTechIdToMaterialOffset[kTechId.SelectGreenSquad] = 98
    kMarineTechIdToMaterialOffset[kTechId.SelectYellowSquad] = 99
    kMarineTechIdToMaterialOffset[kTechId.SelectOrangeSquad] = 100

    
    // Generic orders 
    kAlienTechIdToMaterialOffset[kTechId.Default] = 0
    kAlienTechIdToMaterialOffset[kTechId.Move] = 1
    kAlienTechIdToMaterialOffset[kTechId.Attack] = 2
    kAlienTechIdToMaterialOffset[kTechId.Build] = 3
    kAlienTechIdToMaterialOffset[kTechId.Construct] = 4
    kAlienTechIdToMaterialOffset[kTechId.Stop] = 5
    kAlienTechIdToMaterialOffset[kTechId.SetRally] = 6
    kAlienTechIdToMaterialOffset[kTechId.SetTarget] = 7
    
    // Menus
    kAlienTechIdToMaterialOffset[kTechId.BuildMenu] = 8
    kAlienTechIdToMaterialOffset[kTechId.RootMenu] = 9
    kAlienTechIdToMaterialOffset[kTechId.MarkersMenu] = 11
    kAlienTechIdToMaterialOffset[kTechId.UpgradesMenu] = 12
    kAlienTechIdToMaterialOffset[kTechId.Cyst] = 23
    kAlienTechIdToMaterialOffset[kTechId.MiniCyst] = 23
    kAlienTechIdToMaterialOffset[kTechId.Infestation] = 23
    kAlienTechIdToMaterialOffset[kTechId.MetabolizeTech] = 14
    kAlienTechIdToMaterialOffset[kTechId.Metabolize] = 15
       
    // Lifeforms
    kAlienTechIdToMaterialOffset[kTechId.Skulk] = 16
    kAlienTechIdToMaterialOffset[kTechId.Gorge] = 17
    kAlienTechIdToMaterialOffset[kTechId.Lerk] = 18
    kAlienTechIdToMaterialOffset[kTechId.Fade] = 19
    kAlienTechIdToMaterialOffset[kTechId.Onos] = 20
    kAlienTechIdToMaterialOffset[kTechId.Cancel] = 21
    
    // Structures
    kAlienTechIdToMaterialOffset[kTechId.Hive] = 24
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing harvester
    kAlienTechIdToMaterialOffset[kTechId.Harvester] = 27
    kAlienTechIdToMaterialOffset[kTechId.Drifter] = 28
    kAlienTechIdToMaterialOffset[kTechId.HarvesterUpgrade] = 12
    kAlienTechIdToMaterialOffset[kTechId.Egg] = 30
    kAlienTechIdToMaterialOffset[kTechId.Cocoon] = 31
    
    // $AS - Right now we do not have an icon for power nodes for aliens
    // so we are going to use the question mark until we get something
    kAlienTechIdToMaterialOffset[kTechId.PowerPoint] = 22
    
    // Doors
    // $AS - Aliens can select doors if an onos can potential break a door
    // the alien commander should be able to see its health I would think
    // we do not have any art for doors on aliens so we once again use the
    // question mark 
    kAlienTechIdToMaterialOffset[kTechId.Door] = 22
    kAlienTechIdToMaterialOffset[kTechId.DoorOpen] =22
    kAlienTechIdToMaterialOffset[kTechId.DoorClose] = 22
    kAlienTechIdToMaterialOffset[kTechId.DoorLock] = 22
    kAlienTechIdToMaterialOffset[kTechId.DoorUnlock] = 22
    
    // Hive upgrades and markers
    kAlienTechIdToMaterialOffset[kTechId.ThreatMarker] = 35
    kAlienTechIdToMaterialOffset[kTechId.LargeThreatMarker] = 36
    kAlienTechIdToMaterialOffset[kTechId.NeedHealingMarker] = 37
    kAlienTechIdToMaterialOffset[kTechId.WeakMarker] = 38
    kAlienTechIdToMaterialOffset[kTechId.ExpandingMarker] = 39
   
    // Crag
    kAlienTechIdToMaterialOffset[kTechId.Crag] = 40
    kAlienTechIdToMaterialOffset[kTechId.UpgradeCrag] = 41
    kAlienTechIdToMaterialOffset[kTechId.MatureCrag] = 42
    kAlienTechIdToMaterialOffset[kTechId.CragHeal] = 43
    kAlienTechIdToMaterialOffset[kTechId.CragUmbra] = 44
    kAlienTechIdToMaterialOffset[kTechId.CragBabblers] = 45 
    kAlienTechIdToMaterialOffset[kTechId.BabblerTech] = 46
    
    // Whip
    kAlienTechIdToMaterialOffset[kTechId.Whip] = 48
    kAlienTechIdToMaterialOffset[kTechId.UpgradeWhip] = 49
    kAlienTechIdToMaterialOffset[kTechId.MatureWhip] = 50
    kAlienTechIdToMaterialOffset[kTechId.WhipAcidStrike] = 51
    kAlienTechIdToMaterialOffset[kTechId.WhipFury] = 52
    kAlienTechIdToMaterialOffset[kTechId.WhipBombard] = 53 
    kAlienTechIdToMaterialOffset[kTechId.SwarmTech] = 54
    kAlienTechIdToMaterialOffset[kTechId.Swarm] = 54
    kAlienTechIdToMaterialOffset[kTechId.FrenzyTech] = 55
    kAlienTechIdToMaterialOffset[kTechId.Frenzy] = 55
    kAlienTechIdToMaterialOffset[kTechId.BileBombTech] = 55
    kAlienTechIdToMaterialOffset[kTechId.BileBomb] = 55

    // Shift
    kAlienTechIdToMaterialOffset[kTechId.Shift] = 56
    kAlienTechIdToMaterialOffset[kTechId.UpgradeShift] = 57
    kAlienTechIdToMaterialOffset[kTechId.MatureShift] = 58
    kAlienTechIdToMaterialOffset[kTechId.ShiftRecall] = 59
    kAlienTechIdToMaterialOffset[kTechId.ShiftEcho] = 60
    kAlienTechIdToMaterialOffset[kTechId.ShiftEnergize] = 61
    kAlienTechIdToMaterialOffset[kTechId.EchoTech] = 62
    kAlienTechIdToMaterialOffset[kTechId.LeapTech] = 16
    kAlienTechIdToMaterialOffset[kTechId.Leap] = 16
    
    // Shade
    kAlienTechIdToMaterialOffset[kTechId.Shade] = 64
    kAlienTechIdToMaterialOffset[kTechId.UpgradeShade] = 65
    kAlienTechIdToMaterialOffset[kTechId.MatureShade] = 66
    kAlienTechIdToMaterialOffset[kTechId.ShadeCloak] = 67
    kAlienTechIdToMaterialOffset[kTechId.ShadeDisorient] = 68
    kAlienTechIdToMaterialOffset[kTechId.ShadePhantomMenu] = 69
    kAlienTechIdToMaterialOffset[kTechId.ShadePhantomFade] = 69
    kAlienTechIdToMaterialOffset[kTechId.ShadePhantomOnos] = 69
    kAlienTechIdToMaterialOffset[kTechId.PhantomTech] = 70
    kAlienTechIdToMaterialOffset[kTechId.CamouflageTech] = 71
    kAlienTechIdToMaterialOffset[kTechId.Camouflage] = 71

    // Drifter
    kAlienTechIdToMaterialOffset[kTechId.DrifterFlareTech] = 72
    kAlienTechIdToMaterialOffset[kTechId.DrifterFlare] = 73
    kAlienTechIdToMaterialOffset[kTechId.DrifterParasiteTech] = 74
    kAlienTechIdToMaterialOffset[kTechId.DrifterParasite] = 75
    kAlienTechIdToMaterialOffset[kTechId.PiercingTech] = 76
    
    //Hydra
    kAlienTechIdToMaterialOffset[kTechId.Hydra] = 88
    
    kAlienTechIdToMaterialOffset[kTechId.AlienArmor3Tech] = 77
    
    // Whip movement
    kAlienTechIdToMaterialOffset[kTechId.WhipUnroot] = 78
    kAlienTechIdToMaterialOffset[kTechId.WhipRoot] = 79
    
    // Upgrades #1
    kAlienTechIdToMaterialOffset[kTechId.AdrenalineTech] = 80
    kAlienTechIdToMaterialOffset[kTechId.CarapaceTech] = 81
    kAlienTechIdToMaterialOffset[kTechId.Carapace] = 81
    kAlienTechIdToMaterialOffset[kTechId.RegenerationTech] = 82
    kAlienTechIdToMaterialOffset[kTechId.Regeneration] = 82
    kAlienTechIdToMaterialOffset[kTechId.FeintTech] = 83
    kAlienTechIdToMaterialOffset[kTechId.SapTech] = 84
    kAlienTechIdToMaterialOffset[kTechId.StompTech] = 85
    kAlienTechIdToMaterialOffset[kTechId.BoneShieldTech] = 86    
    
    // Upgrades #2
    kAlienTechIdToMaterialOffset[kTechId.Melee1Tech] = 91
    kAlienTechIdToMaterialOffset[kTechId.Melee2Tech] = 92
    kAlienTechIdToMaterialOffset[kTechId.Melee3Tech] = 93
    kAlienTechIdToMaterialOffset[kTechId.AlienArmor1Tech] = 94
    kAlienTechIdToMaterialOffset[kTechId.AlienArmor2Tech] = 95   
    
end

function GetMaterialXYOffset(techId, isaMarine)

    local index = nil
    
    local columns = 12
    if isaMarine then
        index = kMarineTechIdToMaterialOffset[techId]
    else
        index = kAlienTechIdToMaterialOffset[techId]
        columns = 8
    end

    if(index ~= nil) then
    
        local x = index % columns
        local y = math.floor(index / columns)
        return x, y
        
    end
    
    return nil, nil
    
end

function GetPixelCoordsForIcon(entityId, forMarine)

    local ent = Shared.GetEntity(entityId)
    
    if (ent ~= nil and ent:isa("ScriptActor")) then
    
        local techId = ent:GetTechId()
        
        if (techId ~= kTechId.None) then
            
            local xOffset, yOffset = GetMaterialXYOffset(techId, forMarine)
            
            return {xOffset, yOffset}
            
        end
                    
    end
    
    return nil
    
end
