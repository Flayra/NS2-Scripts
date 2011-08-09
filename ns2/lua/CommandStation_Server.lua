// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStation_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function CommandStation:OnCreate()

    CommandStructure.OnCreate(self)    
    
    self:SetTechId(kTechId.CommandStation)
    
    self:SetModel(CommandStation.kModelName)
    
end

function CommandStation:OnPoweredChange(newPoweredState)

    CommandStructure.OnPoweredChange(self, newPoweredState)
    
    // Logout active commander on power down
    if not newPoweredState then
        self:Logout()
    end
    
end

function CommandStation:GetTeamType()
    return kMarineTeamType
end

function CommandStation:GetCommanderClassName()
    return MarineCommander.kMapName   
end

function CommandStation:GetIsPlayerInside(player)
    local vecDiff = (player:GetModelOrigin() - self:GetModelOrigin())
    return vecDiff:GetLength() < self:GetExtents():GetLength()
end

function CommandStation:GetIsPlayerValidForCommander(player)
    return player ~= nil and player:isa("Marine") and player:GetIsAlive() and player:GetTeamNumber() == self:GetTeamNumber() and self:GetIsPlayerInside(player)
end

function CommandStation:KillPlayersInside()

    // Now kill any other players that are still inside the command station so they're not stuck!
    for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
    
        if not player:isa("Commander") and not player:isa("Spectator") then
        
            if self:GetIsPlayerInside(player) and player:GetId() ~= self.playerIdStartedLogin then
        
                player:Kill(self, self, self:GetOrigin())
                
            end
            
        end
    
    end

end

function CommandStation:LoginPlayer(player)

    local commander = CommandStructure.LoginPlayer(self, player)
    
    self:KillPlayersInside()  

    if not self.hasBeenOccupied then
    
        // Create some initial MACs
        for i = 1, kInitialMACs do
            local mac = CreateEntity(MAC.kMapName, self:GetOrigin(), self:GetTeamNumber())
            mac:SetOwner(commander)
        end
        
        self.hasBeenOccupied = true

    end  
    
end

function CommandStation:GetDamagedAlertId()
    return kTechId.MarineAlertCommandStationUnderAttack
end

