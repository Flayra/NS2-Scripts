// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kCommandStructureThinkInterval = .25

function CommandStructure:OnKill(damage, attacker, doer, point, direction)

    self:Logout()
    
    Structure.OnKill(self, damage, attacker, doer, point, direction)

end

// Children should override this
function CommandStructure:GetTeamType()
    return kNeutralTeamType
end

function CommandStructure:OnInit()

    Structure.OnInit(self)
    
    self.commander = nil
    self.commanderId = Entity.invalidId
    
    self.occupied = false
    
    self:SetNextThink(kCommandStructureThinkInterval)
    
end

function CommandStructure:FindAndMakeAttachment()

    // Attach self to nearest tech point
    local position = Vector(self:GetOrigin())
    
    local nearestTechPoint = GetNearestTechPoint(position, self:GetTeamType(), true)
    if(nearestTechPoint ~= nil) then
    
        nearestTechPoint:SetAttached(self)
        
        // Allow entities to be positioned off ground (eg, hive hovers over tech point)
        position = Vector(nearestTechPoint:GetOrigin())
    
    end
    
    local spawnHeightOffset = LookupTechData(self:GetTechId(), kTechDataSpawnHeightOffset)
    if(spawnHeightOffset ~= nil) then
        position.y = position.y + spawnHeightOffset
    end
    
    self:SetOrigin(position)

end

function CommandStructure:OnDestroy()

    if self.occupied then
        self:Logout()
    end

    Structure.OnDestroy(self)                        
            
end

function CommandStructure:GetCommanderClassName()
    return Commander.kMapName   
end

function CommandStructure:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)
    
    if success then
    
        if(structure and (structure:GetId() == self:GetId()) and (researchId == self.level1TechId or researchId == self.level2TechId or researchId == self.level3TechId)) then

            // Also changes current health and maxHealth    
            success = self:UpgradeToTechId(researchId)
            
        end
        
    end
    
    return success    
end

function CommandStructure:GetLoginTime()
    return ConditionalValue(Shared.GetDevMode(), 0, self:GetAnimationLength(self:GetCloseAnimation()))
end

function CommandStructure:GetIsPlayerValidForCommander(player)
    return true
end

function CommandStructure:UpdateCommanderLogin(force)

    if (self.occupied and self.commander == nil and (Shared.GetTime() > (self.timeStartedLogin + self:GetLoginTime())) or force) then
    
        // Don't turn player into commander until short time later
        local player = Shared.GetEntity(self.playerIdStartedLogin)
        
        if (self:GetIsPlayerValidForCommander(player) and self:GetIsActive()) or force then
        
            self:LoginPlayer(player)
            
        // Player was killed, became invalid or left the server somehow
        else
        
            self.occupied = false
            self.timeStartedLogin = nil
            self.commander = nil
                        
            self:TriggerLogout()
            
        end
        
    end
    
end

function CommandStructure:LoginPlayer(player)

    local commanderStartOrigin = Vector(player:GetOrigin())
            
    // Create Commander player
    local commanderPlayer = player:Replace( self:GetCommanderClassName(), player:GetTeamNumber(), true, commanderStartOrigin)
    
    // Set all child entities and view model invisible
    function SetInvisible(weapon) 
        weapon:SetIsVisible(false)
    end
    commanderPlayer:ForEachChild(SetInvisible)
    
    if (commanderPlayer:GetViewModelEntity()) then
        commanderPlayer:GetViewModelEntity():SetModel("")
    end
    
    // Clear game effects on player
    commanderPlayer:ClearGameEffects()    
    
    // Make this structure the first hotgroup if we don't have any yet
    if(commanderPlayer:GetNumHotkeyGroups() == 0) then
                    
        commanderPlayer:SetSelection( {self:GetId()} )
        commanderPlayer:CreateHotkeyGroup(1)
        
    end
    
    commanderPlayer:SetCommandStructure(self)
    
    // Save origin so we can restore it on logout
    commanderPlayer.lastGroundOrigin = Vector(commanderStartOrigin)
    
    self.commander = commanderPlayer
    self.commanderId = commanderPlayer:GetId()
    
    // Must reset offset angles once player becomes commander
    commanderPlayer:SetOffsetAngles(Angles(0, 0, 0))
    
    return commanderPlayer

end

function CommandStructure:GetCommander()
    return self.commander
end

function CommandStructure:OnThink()

    Structure.OnThink(self)

    self:UpdateCommanderLogin()

    self:SetNextThink(kCommandStructureThinkInterval)
    
end

function CommandStructure:GetOpenAnimation()
    return "open"
end

function CommandStructure:GetCloseAnimation()
    return "close"
end

// Put player into Commander mode
function CommandStructure:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    local teamNum = self:GetTeamNumber()
    
    if( (teamNum == 0) or (teamNum == player:GetTeamNumber()) ) then
    
        if(not Structure.OnUse(self, player, elapsedTime, useAttachPoint, usePoint)) then
        
            // Make sure player wasn't ejected early in the game from either team's command
            local playerSteamId = Server.GetOwner(player):GetUserId()
            if not GetGamerules():GetPlayerBannedFromCommand(playerSteamId) then
        
                // Must use attach point if specified (Command Station)            
                if self:GetIsBuilt() and (not self.occupied) and (useAttachPoint or (self:GetUseAttachPoint() == "")) then

                    self.timeStartedLogin = Shared.GetTime()
                    
                    self.playerIdStartedLogin = player:GetId()
                    
                    self.occupied = true
               
                    if not self:GetIsAlienStructure() then
                        self:TriggerEffects("commmand_station_login")
                    else
                        self:TriggerEffects("hive_login")
                    end
                    
                    return true
                        
                end

            else
                player:AddTooltip("You were ejected as Commander so you won't be able to command again this game.")
            end
            
        else
            return true            
        end

    end
    
    return false
    
end

function CommandStructure:TriggerLogout()

    if not self:GetIsAlienStructure() then
        self:TriggerEffects("commmand_station_logout")
    else
        self:TriggerEffects("hive_logout")
    end

end

function CommandStructure:OnEntityChange(oldEntityId, newEntityId)

    Structure.OnEntityChange(self, oldEntityId, newEntityId)

    if self.commander and self.commander:GetId() == oldEntityId then
    
        self.commander = nil
        
        self.occupied = false
        
        self:TriggerLogout()        
        
    end
    
end

// Returns new player 
function CommandStructure:Logout()

    // Change commander back to player
    if self.commander then
    
        local previousWeaponMapName = self.commander.previousWeaponMapName
        local previousOrigin = self.commander.lastGroundOrigin
        local previousAngles = self.commander.previousAngles
        local previousHealth = self.commander.previousHealth
        local previousArmor = self.commander.previousArmor
        local previousAlienEnergy = self.commander.previousAlienEnergy
        local timeStartedCommanderMode = self.commander.timeStartedCommanderMode
        
        local player = self.commander:Replace(self.commander.previousMapName, self.commander:GetTeamNumber(), true, previousOrigin)    

        // Switch to weapon player was using before becoming Commander
        player:InitViewModel()
        player:SetActiveWeapon(previousWeaponMapName)
        player:SetOrigin(previousOrigin)
        player:SetAngles(previousAngles)
        player:SetHealth(previousHealth)
        player:SetArmor(previousArmor)
        player.frozen = false
        
        // Restore previous alien energy, but let us recuperate at the regular rate while we're in the hive
        if previousAlienEnergy and player.SetEnergy and timeStartedCommanderMode then
            local timePassedSinceStartedComm = Shared.GetTime() - timeStartedCommanderMode
            player:SetEnergy(previousAlienEnergy + Alien.kEnergyRecuperationRate * timePassedSinceStartedComm)
        end

        self.commander = nil
        self.commanderId = Entity.invalidId
        self.playerIdStartedLogin = nil
        
        self.occupied = false
        
        self:TriggerLogout()                
        
        return player
        
    end
    
    return nil
    
end

function CommandStructure:OnOverrideOrder(order)

    // Convert default to set rally point
    if(order:GetType() == kTechId.Default) then
    
        order:SetType(kTechId.SetRally)
        
    end

end
