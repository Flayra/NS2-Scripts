// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStation.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/CommandStructure.lua")

class 'CommandStation' (CommandStructure)
CommandStation.kMapName               = "commandstation"

CommandStation.kLevel1MapName         = "commandstationl1"

CommandStation.kModelName = PrecacheAsset("models/marine/command_station/command_station.model")

CommandStation.kActiveSound = PrecacheAsset("sound/ns2.fev/marine/structures/command_station_active")
CommandStation.kUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/command_station_under_attack")

CommandStation.kLoginAttachPoint = "login"

if (Server) then
    Script.Load("lua/CommandStation_Server.lua")
end

local networkVars = 
{
    occupied            = "boolean"
}

function CommandStation:GetRequiresPower()
    return false
end

function CommandStation:GetUseAttachPoint()
    return CommandStation.kLoginAttachPoint
end

function CommandStation:GetPowerDownAnimation()
    return ""
end

function CommandStation:GetPowerUpAnimation()
    return ""
end

function CommandStation:OnAnimationComplete(animName)

    CommandStructure.OnAnimationComplete(self, animName)
    
    if(animName == Structure.kAnimDeploy) then
        self:SetAnimation("open")
    elseif(animName == "close") then
        self:PlaySound(CommandStation.kActiveSound)
    elseif(animName == "open") then
        self:StopSound(CommandStation.kActiveSound)
    end

end

function CommandStation:GetTechAllowed(techId, techNode, player)
    if techId == kTechId.Recycle then
        return not self:GetIsOccupied()
    end
    return Structure.GetTechAllowed(self, techId, techNode, player)
end


Shared.LinkClassToMap("CommandStation",    CommandStation.kLevel1MapName, networkVars)

// Create new classes here so L2 and L3 command stations can be created for test cases without
// create a basic hive and then upgrading it
class 'CommandStationL2' (CommandStation)

CommandStationL2.kMapName       = "commandstationl2"
Shared.LinkClassToMap("CommandStationL2", CommandStationL2.kMapName, {})

class 'CommandStationL3' (CommandStationL2)

CommandStationL3.kMapName       = "commandstationl3"
Shared.LinkClassToMap("CommandStationL3", CommandStationL3.kMapName, {})

