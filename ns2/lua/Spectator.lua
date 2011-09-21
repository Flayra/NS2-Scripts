// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Spectator.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/SpectatorMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

class 'Spectator' (Player)

Spectator.kMapName = "spectator"
Spectator.kMaxSpeed = Player.kWalkMaxSpeed * 5
Spectator.kAcceleration = 100

Spectator.kDeadSound = PrecacheAsset("sound/ns2.fev/common/dead")
Spectator.kSpectatorMode = enum( {'FreeLook', 'Following'} )

Spectator.networkVars =
{
    specMode = "enum Spectator.kSpectatorMode",
    
    // When in follow mode, this is the player to follow
    specTargetId = "entityid",
    
    timeOfLastInput = "float"
}

PrepareClassForMixin(Spectator, SpectatorMoveMixin)
PrepareClassForMixin(Spectator, CameraHolderMixin)

if Client then
    Script.Load("lua/Spectator_Client.lua")
end

function Spectator:OnCreate()

    Player.OnCreate(self)
    
    InitMixin(self, SpectatorMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = Player.kFov })

end

function Spectator:OnInit()

    Player.OnInit(self)
    
    // Spectator cannot have orders.
    // Todo: Move OrdersMixin out of Player and into leaf classes.
    // Don't include the OrdersMixin on Spectators.
    self:SetIgnoreOrders(true)
    
    self.lastTargetId = Entity.invalidId
    self.specTargetId = Entity.invalidId
    self.timeOfLastInput = 0
    
    if Server then
        
        self:SetIsVisible(false)
        
        self:SetIsAlive(false)
        
        self:SetSpectatorMode(Spectator.kSpectatorMode.FreeLook)

    else
              
        // Play ambient "you are dead" sound
        if Client.GetLocalPlayer() == self then
        
            if self:GetTeamNumber() == kTeam1Index or self:GetTeamNumber() == kTeam2Index then
                Shared.PlaySound(self, Spectator.kDeadSound)
            end
            
        end
 
    end
    
    self:DestroyController()

    // Don't propagate spectators to any other players
    self:SetPropagate(Entity.Propagate_Never)

end

function Spectator:OnDestroy()

    if Client then
        Shared.StopSound(self, Spectator.kDeadSound)
    end
    Player.OnDestroy(self)
    
end

function Spectator:GetTechId()
    return kTechId.Spectator
end

function Spectator:GetPlayFootsteps()
    return false
end

function Spectator:GetMovePhysicsMask()
    return PhysicsMask.FilterAll
end

function Spectator:AdjustGravityForce(input, gravity)
    return 0
end

// Return 0, 0 to indicate no collision
function Spectator:GetTraceCapsule()
    return 0, 0
end

function Spectator:GetMaxSpeed()
    return Spectator.kMaxSpeed
end

function Spectator:GetAcceleration()
    return Spectator.kAcceleration
end

function Spectator:UpdateHelp()

    if self:AddTooltipOncePer("SPECTATING_TOOLTIP", 90) then
        return true
    end

    return false
    
end

// Handle player transitions to egg, new lifeforms, etc.
function Spectator:OnEntityChange(oldEntityId, newEntityId)

    if oldEntityId ~= Entity.invalidId and oldEntityId ~= nil then
    
        if oldEntityId == self.specTargetId then
            self.specTargetId = newEntityId
        end
        
        if oldEntityId == self.lastTargetId then
            self.lastTargetId = newEntityId
        end
       
    end
    
end

function Spectator:UpdateFromSpecTarget(input)

    // Set our position, angles, fov, viewangles to those of our spec target
    local entity = Shared.GetEntity(self.specTargetId)
    if self:GetIsValidTarget(entity) then
    
        self:SetOrigin(entity:GetOrigin())

    elseif Server then
        // Switch to next target
        self:CycleTarget()        
    end
    
    // So we can rotate around target
    local viewAngles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    self:SetViewAngles(viewAngles)
    
end

function Spectator:GetIsValidTarget(entity)

    // Check player name here too so we don't spectate oureselves (can happen due to timing when creating spectator and old player still around)
    local teamNumber = self:GetTeamNumber()
    local targetTeamNumber = ConditionalValue((teamNumber == kTeamReadyRoom or teamNumber == kSpectatorIndex), -1, teamNumber)    
    return (entity and entity:isa("Player") and not entity:isa("Commander") and not entity:isa("Spectator") and entity ~= self and entity:GetIsAlive() and (entity:GetTeamNumber() == targetTeamNumber or targetTeamNumber == -1) and entity:GetName() ~= self:GetName())

end

if Server then
    
    function Spectator:SetSpectatorMode(mode)
    
        if mode == Spectator.kSpectatorMode.Following then

            // Try to follow last target
            if self.lastTargetId ~= Entity.invalidId and self.lastTargetId and Shared.GetEntity(self.lastTargetId) and self:GetIsValidTarget(Shared.GetEntity(self.lastTargetId)) then
            
                self.specTargetId = self.lastTargetId
                
            else
            
                self.specTargetId = Entity.invalidId
                self:CycleTarget()
                
            end
            
            if self.specTargetId ~= Entity.invalidId then
            
                self:SetIsThirdPerson(3)
                self.specMode = mode
                
            end
            
        elseif mode == Spectator.kSpectatorMode.FreeLook then
        
            // Remember last target so we can start following them again if we switch back to following
            if self.specTargetId ~= nil and self.specTargetId ~= Entity.invalidId then
                self.lastTargetId = self.specTargetId
            end
            
            self.specMode = mode
            
            self:SetIsThirdPerson(0)
            
        end
        
        self:DisplayModeTooltip()
        
    end
    
    function Spectator:GetValidSpectatorTargets()
    
        local potentialTargets = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
        
        local targets = {}
        for index, target in ipairs(potentialTargets) do
        
            if self:GetIsValidTarget(target) then
                table.insert(targets, target)
            end
            
        end
        
        return targets
        
    end
    
    function Spectator:DisplayModeTooltip()
    
        if self.specMode == Spectator.kSpectatorMode.Following then
            local target = Shared.GetEntity(self.specTargetId)
            if target then
                local followingText = string.format("%s %s", "FOLLOWING", ConditionalValue(target:isa("Player"), target:GetStatusDescription(), target:GetClassName()))                
                self:AddLocalizedTooltip(followingText, false, false) 
            end
        else
            self:AddTooltip("Free look mode")    
        end
        
    end
    
    function Spectator:GetFollowingPlayerId()
    
        local playerId = Entity.invalidId
        
        if (self.specMode == Spectator.kSpectatorMode.Following) then
            playerId = self.specTargetId
        end
        
        return playerId
        
    end
    
    // Go to next player on team if we're playing, or next player in world if we're not
    function Spectator:CycleTarget(reverse)

        // Get list of active targets
        local targets = self:GetValidSpectatorTargets()
        
        // Find next target in list
        local newTarget = nil
        local numTargets = table.count(targets)
        
        if numTargets == 1 then
            newTarget = targets[1]
        elseif numTargets > 1 then
        
            // Get starting point
            local currentTarget = nil
            if self.specTargetId ~= Entity.invalidId then
                currentTarget = Shared.GetEntity(self.specTargetId)
            end

            local index = table.find(targets, currentTarget)
            if not index then 
                newTarget = targets[1]
            else
            
                // Count forward or backward through list
                index = ConditionalValue(reverse, index - 1, index + 1)
                
                // Ensure value is from 1 to numTargets (wrap around)
                if index < 1 then
                    index = numTargets
                elseif index > numTargets then
                    index = index - numTargets
                end
                ASSERT(index >= 1)
                ASSERT(index <= numTargets)
                
                newTarget = targets[index]
                
            end
            
        end
        
        if newTarget then
        
            // Set target
            self.lastTargetId = self.specTargetId
            self.specTargetId = newTarget:GetId()
            
            self:DisplayModeTooltip()
            
        else
            self:AddTooltip("No targets found.")
        end
        
    end
    
end

function Spectator:_HandleSpectatorButtons(input)

    // Don't switch between targets or take input too quickly
    local time = Shared.GetTime()
    
    if time > self.timeOfLastInput + .3 then
    
        // If attack pressed, spawn player if possible (cannot spawn them into the spectator or ready room team)
        local validTeam = self:GetTeamNumber() ~= kSpectatorIndex and self:GetTeamNumber() ~= kTeamReadyRoom
        if bit.band(input.commands, Move.PrimaryAttack) ~= 0 and Server and validTeam then
            self:SpawnPlayerOnAttack()
            self.timeOfLastInput = time
        end

        if bit.band(input.commands, Move.Jump) ~= 0 and Server then
        
            // Switch modes
            if self.specMode == Spectator.kSpectatorMode.FreeLook then
                self:SetSpectatorMode(Spectator.kSpectatorMode.Following)
            else
                self:SetSpectatorMode(Spectator.kSpectatorMode.FreeLook)
            end
            
            self.timeOfLastInput = time
            
        end
        
        if Server and self.specMode == Spectator.kSpectatorMode.Following then
        
            if bit.band(input.commands, Move.PrimaryAttack) ~= 0 or bit.band(input.commands, Move.SecondaryAttack) ~= 0 then
            
                // Cycle targets (forward or backward).
                self:CycleTarget(bit.band(input.commands, Move.SecondaryAttack) ~= 0)
                self.timeOfLastInput = time
                
            end
        end
        
        // When exit hit, bring up menu.
        if (bit.band(input.commands, Move.Exit) ~= 0) and (Client ~= nil) then
            ShowInGameMenu()
            self.timeOfLastInput = time
        end
    
    end
    
    self:UpdateScoreboard(input)
    self:UpdateShowMap(input)

end

function Spectator:OnProcessMove(input)

    // Don't allow setting of animations during OnProcessMove() as they will get reverted
    SetRunningProcessMove(self)
  
    // Update from target.
    if self.specMode == Spectator.kSpectatorMode.Following and self.specTargetId ~= Entity.invalidId then
        self:UpdateFromSpecTarget(input)
    else
        // Let them float around with SpectatorMoveMixin.
        self:UpdateMove(input)
    end
    
    // Update player angles and view angles smoothly from desired angles if set. 
    // But visual effects should only be calculated when not predicting.
    self:UpdateViewAngles(input)
    
    self:_HandleSpectatorButtons(input)
    
    self:UpdateCamera(input.time)
    
    if Client and not Shared.GetIsRunningPrediction() then
        self:UpdateCrossHairText()
        self:UpdateChat(input)
    end
    
    SetRunningProcessMove(nil)
    
end

// Overwrite to get player status description
function Spectator:GetPlayerStatusDesc()

    if self:GetTeamNumber() ~= kSpectatorIndex then
        return "Dead"
    end
    return "Spectator"
    
end

if Server then

// Marines spawn at predetermined time at IP but allow them to spawn manually if cheats are on
function Spectator:SpawnPlayerOnAttack()

    if (Shared.GetCheatsEnabled() or not GetGamerules():GetGameStarted()) and ((self.timeOfDeath == nil) or (Shared.GetTime() > self.timeOfDeath + kFadeToBlackTime)) then
        return self:GetTeam():ReplaceRespawnPlayer(self)
    end
    
    return false, nil
    
end

end

if Client then

// Don't change visibility on client
function Spectator:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    self:SetIsVisible(false)
    
    local activeWeapon = self:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        activeWeapon:SetIsVisible( false )
    end
    
    local viewModel = self:GetViewModelEntity()    
    if(viewModel ~= nil) then
        viewModel:SetIsVisible( false )
    end

end

end

Shared.LinkClassToMap( "Spectator", Spectator.kMapName, Spectator.networkVars )