// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Observatory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'Observatory' (Structure)

Observatory.kMapName = "observatory"

Observatory.kModelName = PrecacheAsset("models/marine/observatory/observatory.model")

local kScanSound = PrecacheAsset("sound/ns2.fev/marine/structures/observatory_scan")
local kDistressBeaconSound = PrecacheAsset("sound/ns2.fev/marine/common/distress_beacon")
local kDistressBeaconSoundDistance = 100
local kPlayerDistressBeaconSound = PrecacheAsset("sound/ns2.fev/marine/common/distress_beacon_marine")

local kObservatoryTechButtons = { kTechId.Scan, kTechId.PhaseTech, kTechId.DistressBeacon, kTechId.None, 
                                  kTechId.None, kTechId.None, kTechId.None, kTechId.None }

Observatory.kDistressBeaconTime = kDistressBeaconTime
Observatory.kDistressBeaconRange = kDistressBeaconRange

function Observatory:OnCreate()

    Structure.OnCreate(self)
    
    if Server then
    
        self.distressBeaconSoundEffect = Server.CreateEntity(SoundEffect.kMapName)
        self.distressBeaconSoundEffect:SetParent(self)
        self.distressBeaconSoundEffect:SetAsset(kDistressBeaconSound)
        self.distressBeaconSoundEffect:SetRelevancyDistance(kDistressBeaconSoundDistance)
        
        self.playerDistressSounds = { }
        
    end
    
    InitMixin(self, RagdollMixin)

end

function Observatory:OnDestroy()

    Structure.OnDestroy(self)
    
    if Server then
    
        Server.DestroyEntity(self.distressBeaconSoundEffect)
        self.distressBeaconSoundEffect = nil
        
        self:DestroyDistressSounds()
    
    end

end

function Observatory:OnInit()

    self:SetModel(Observatory.kModelName)
    
    Structure.OnInit(self)
    
end

function Observatory:GetTechButtons(techId)

    if techId == kTechId.RootMenu then
        return kObservatoryTechButtons
    end
    
    return nil
    
end

function Observatory:GetRequiresPower()
    return true
end

function Observatory:TriggerScan(position)

    // Create scan entity in world at this position
    CreateEntity(Scan.kMapName, position, self:GetTeamNumber())
    
    Shared.PlayWorldSound(nil, kScanSound, nil, position)
    
end

function Observatory:CreateDistressSound(player)

    local playerDistressSound = Server.CreateEntity(SoundEffect.kMapName)
    playerDistressSound:SetParent(player)
    
    // Only this player can hear this distress sound.
    playerDistressSound:SetPropagate(Entity.Propagate_Callback)
    function playerDistressSound:OnGetIsRelevant(relPlayer)
        return playerDistressSound:GetParent() == player
    end
    
    playerDistressSound:SetAsset(kPlayerDistressBeaconSound)
    playerDistressSound:Start()
    
    table.insert(self.playerDistressSounds, playerDistressSound)

end

function Observatory:DestroyDistressSounds()

    for i, distressSound in ipairs(self.playerDistressSounds) do
        Server.DestroyEntity(distressSound)
    end
    self.playerDistressSounds = { }

end

function Observatory:TriggerDistressBeacon()

    local success = false
    
    if not self:GetIsBeaconing() then

        local beaconPlayerIds = { }
        // Trigger private sound effect for marines far from beacon, so they can hear it positionally at a distance
        for index, player in ipairs(self:GetPlayersToBeacon()) do
        
            table.insert(beaconPlayerIds, player:GetId())
            self:CreateDistressSound(player)
            
        end
        
        // Play effects at beacon so enemies and Comm can hear it.
        // The beaconing players should NOT hear it.
        self.distressBeaconSoundEffect:SetPropagate(Entity.Propagate_Callback)
        function self.distressBeaconSoundEffect:OnGetIsRelevant(relPlayer)
            return table.find(beaconPlayerIds, relPlayer:GetId()) == nil
        end
        self.distressBeaconSoundEffect:Start()
        
        // Beam all faraway players back in a few seconds!
        self.distressBeaconTime = Shared.GetTime() + Observatory.kDistressBeaconTime
        
        success = true
    
    end
    
    return success
    
end

function Observatory:CancelDistressBeacon()

    self.distressBeaconTime = nil
    self.distressBeaconSoundEffect:Stop()
    
    self:DestroyDistressSounds()

end

function Observatory:GetIsPlayerNearby(player)
    return (player:GetOrigin() - self:GetOrigin()):GetLength() < Observatory.kDistressBeaconRange
end

function Observatory:GetPlayersToBeacon()

    local players = { }
    
    for index, player in ipairs(self:GetTeam():GetPlayers()) do
    
        // Don't affect Commanders or Heavies
        if (player:GetIsAlive() and player:isa("Marine")) or not player:GetIsAlive() then
        
            // Don't respawn players that are already nearby unless they are spectators.
            if not player:GetIsAlive() or not self:GetIsPlayerNearby(player) then
                table.insert(players, player)
            end
            
        end
        
    end
    
    return players
    
end

function Observatory:PerformDistressBeacon()

    self.distressBeaconSoundEffect:Stop()

    for index, player in ipairs(self:GetPlayersToBeacon()) do
        self:RespawnPlayer(player)
    end
    
    self:DestroyDistressSounds()
    
    // Play mega-spawn sound
    self:TriggerEffects("distress_beacon_complete")    
    
end

// Spawn players near Observatory - not initial marine start like in NS1. Allows relocations and more versatile tactics.
function Observatory:RespawnPlayer(player)

    // Always marine capsule (player could be dead/spectator)
    local extents = LookupTechData(kTechId.Marine, kTechDataMaxExtents)
    local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
    local range = Observatory.kDistressBeaconRange
    local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius,
                                                self:GetModelOrigin(), 2, range, EntityFilterAll())
    
    if spawnPoint then
    
        local success = true
    
        // Respawn dead players
        if not player:GetIsAlive() then
            success, player = player:GetTeam():ReplaceRespawnPlayer(player, spawnPoint, Angles())
        else
            player:SetOrigin(spawnPoint)
        end
        
        if success then
            player:TriggerEffects("distress_beacon_spawn")
        end
        
    else
        Print("Observatory:RespawnPlayer(): Couldn't find space to respawn player.")
    end
    
end

function Observatory:OnPoweredChange(newPoweredState)

    Structure.OnPoweredChange(self, newPoweredState)
    
    // Cancel distress beacon on power down
    if not newPoweredState and self:GetIsBeaconing() then
    
        self:CancelDistressBeacon()
        
    end
    
end

function Observatory:OnUpdate(deltaTime)

    Structure.OnUpdate(self, deltaTime)

    if self:GetIsBeaconing() and (Shared.GetTime() >= self.distressBeaconTime) then
    
        self:PerformDistressBeacon()
        
        self.distressBeaconTime = nil
            
    end
    
end

function Observatory:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if self:GetIsBuilt() and self:GetIsActive() then
    
        if techId == kTechId.Scan then
        
            self:TriggerScan(position)
            success = true

        elseif techId == kTechId.DistressBeacon then
        
            success = self:TriggerDistressBeacon()
            
        else        
            success = Structure.PerformActivation(self, techId, position, normal, commander)
        end
    
    end
    
    return success
    
end

function Observatory:GetIsBeaconing()
    return (self.distressBeaconTime ~= nil)
end

function Observatory:OnKill(damage, killer, doer, point, direction)

    if self:GetIsBeaconing() then
        self:CancelDistressBeacon()
    end
    
    Structure.OnKill(self, damage, killer, doer, point, direction)
    
end

Shared.LinkClassToMap("Observatory", Observatory.kMapName, {})

if Server then

    function OnConsoleDistress()
    
        if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
            local beacons = Shared.GetEntitiesWithClassname("Observatory")
            for i, beacon in ientitylist(beacons) do
                beacon:TriggerDistressBeacon()
            end
        end
        
    end
    
    Event.Hook("Console_distress", OnConsoleDistress)
end