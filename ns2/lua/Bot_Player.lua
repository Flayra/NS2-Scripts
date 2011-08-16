//=============================================================================
//
// lua\Bot_Player.lua
//
// AI "bot" functions for goal setting and moving (used by Bot.lua).
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

Script.Load("lua/Bot.lua")

// State machines
//  Go to nearest unbuilt nozzle or tech point, poke around a bit, ask for order, poke around a bit, build it if dropped
//  Choose a friendly player in sight, pick a point near them that they can see, move to it, wait a bit, repeat. Attack any enemies. Choose again if certain time has elapsed.
//  Go to alien hive room and pick off eggs and shoot the hive
local kBotNames = {
    "Flayra (bot)", "m4x0r (bot)", "Ooghi (bot)", "Breadman (bot)", "Squeal Like a Pig (bot)", "Chops (bot)", "Numerik (bot)",
    "Comprox (bot)", "MonsieurEvil (bot)", "Joev (bot)", "puzl (bot)", "Crispix (bot)", "Kouji_San (bot)", "TychoCelchuuu (bot)",
    "Insane (bot)", "CoolCookieCooks (bot)", "devildog (bot)", "tommyd (bot)", "Relic25 (bot)"
}

class 'BotPlayer' (Bot)

function BotPlayer:ChooseOrder()

    local player = self:GetPlayer()
    local order = player:GetCurrentOrder()
    
    // If we have no order or are attacking, acquire possible new target
    if GetGamerules():GetGameStarted() then
    
        if self.active and ( order == nil or (order:GetType() == kTechId.Attack)) then
        
            // Get nearby visible target
            self:AttackVisibleTarget()
            order = player:GetCurrentOrder()
            
        end
        
    end

    // If we aren't attacking, try something else    
    if self.active and order == nil then
    
        // Get healed at armory, pickup health/ammo on ground, move towards other player    
        if not self:GoToNearbyEntity() then
    
            // Move to random tech point or nozzle on map
            self:ChooseRandomDestination()

        end
            
    end

    // Update order values for client
    self:UpdateOrderVariables()
    
end

function BotPlayer:UpdateName()

    // Set name after a bit of time to simulate real players
    if math.random() < .01 then

        local player = self:GetPlayer()
        local name = player:GetName()
        if name and string.find(string.lower(name), string.lower(kDefaultPlayerName)) ~= nil then
    
            local numNames = table.maxn(kBotNames)
            local index = Clamp(math.ceil(math.random() * numNames), 1, numNames)
            OnCommandSetName(self.client, kBotNames[index])
            
        end
        
    end
    
end

function BotPlayer:UpdateOrderVariables()

    local player = self:GetPlayer()
    self.orderType = kTechId.None
    
    if player:GetHasOrder() then
    
        local order = player:GetCurrentOrder()
        player.orderPosition = Vector(order:GetLocation())
        player.orderType = order:GetType()

    end
    
end

function BotPlayer:AttackVisibleTarget()

    local player = self:GetPlayer()

    // Are there any visible enemy players or structures nearby?
    local success = false
    
    if not self.timeLastTargetCheck or (Shared.GetTime() - self.timeLastTargetCheck > 2) then
    
        local nearestTarget = nil
        local nearestTargetDistance = nil
        
        local targets = GetEntitiesForTeamWithinRange("LiveScriptActor", GetEnemyTeamNumber(player:GetTeamNumber()), player:GetOrigin(), 20)
        for index, target in pairs(targets) do
        
            if target:GetIsAlive() and target:GetIsVisible() and target:GetCanTakeDamage() and target ~= player then
            
                // Prioritize players over non-players
                local dist = (target:GetEngagementPoint() - player:GetModelOrigin()):GetLength()
                
                local newTarget = (not nearestTarget) or (target:isa("Player") and not nearestTarget:isa("Player"))
                if not newTarget then
                
                    if dist < nearestTargetDistance then
                        newTarget = not nearestTarget:isa("Player") or target:isa("Player")
                    end
                    
                end
                
                if newTarget then
                
                    nearestTarget = target
                    nearestTargetDistance = dist
                    
                end
                
            end
            
        end
        
        if nearestTarget then
        
            local name = SafeClassName(nearestTarget)
            if nearestTarget:isa("Player") then
                name = nearestTarget:GetName()
            end
            
            player:GiveOrder(kTechId.Attack, nearestTarget:GetId(), nearestTarget:GetEngagementPoint(), nil, true, true)
            
            success = true
        end
        
        self.timeLastTargetCheck = Shared.GetTime()
        
    end
    
    return success
    
end

function BotPlayer:GoToNearbyEntity(move)
    return false    
end

function BotPlayer:MoveRandomly(move)

    // Jump up and down crazily!
    if self.active and Shared.GetRandomInt(0, 100) <= 5 then
        move.commands = bit.bor(move.commands, Move.Jump)
    end
    
    return true
    
end

function BotPlayer:ChooseRandomDestination(move)

    local player = self:GetPlayer()

    // Go to nearest unbuilt tech point or nozzle
    local className = ConditionalValue(math.random() < .5, "TechPoint", "ResourcePoint")

    local ents = Shared.GetEntitiesWithClassname(className)
    
    if ents:GetSize() > 0 then 
    
        local index = math.floor(math.random() * ents:GetSize())
        
        local destination = ents:GetEntityAtIndex(index)
        
        player:GiveOrder(kTechId.Move, 0, destination:GetEngagementPoint(), nil, true, true)
        
        return true
        
    end
    
    return false
    
end

function BotPlayer:GetAttackDistance()

    local player = self:GetPlayer()
    local activeWeapon = player:GetActiveWeapon()
    
    if activeWeapon then
        return math.min(activeWeapon:GetRange(), 15)
    end
    
    return nil
    
end

function BotPlayer:UpdateWeaponMove(move)

    local player = self:GetPlayer()

    // Switch to proper weapon for target
    local order = player:GetCurrentOrder()
    if order ~= nil and (order:GetType() == kTechId.Attack) then
    
        local target = Shared.GetEntity(order:GetParam())
        if target then
        
            local activeWeapon = player:GetActiveWeapon()
        
            if player:isa("Marine") and activeWeapon then
                local outOfAmmo = (activeWeapon:isa("ClipWeapon") and (activeWeapon:GetAmmo() == 0))
            
                // Some bots switch to axe to take down structures
                if (target:isa("Structure") and self.prefersAxe and not activeWeapon:isa("Axe")) or outOfAmmo then
                    //Print("%s switching to axe to attack structure", self:GetName())
                    move.commands = bit.bor(move.commands, Move.Weapon3)
                elseif target:isa("Player") and not activeWeapon:isa("Rifle") then
                    //Print("%s switching to weapon #1", self:GetName())
                    move.commands = bit.bor(move.commands, Move.Weapon1)
                // If we're out of ammo in our primary weapon, switch to next weapon (pistol or axe)
                elseif outOfAmmo then
                    //Print("%s switching to next weapon", self:GetName())
                    move.commands = bit.bor(move.commands, Move.NextWeapon)
                end
                
            end
            
            // Attack target! TODO: We should have formal point where attack emanates from.
            local distToTarget = (target:GetEngagementPoint() - player:GetModelOrigin()):GetLength()
            local attackDist = self:GetAttackDistance()
            
            self.inAttackRange = false
            
            if activeWeapon and attackDist and (distToTarget < attackDist) then
            
                // Make sure we can see target
                local filter = EntityFilterTwo(player, activeWeapon)
                local trace = Shared.TraceRay(player:GetEyePos(), target:GetModelOrigin(), PhysicsMask.AllButPCs, filter)
                if trace.entity == target then
                
                    move.commands = bit.bor(move.commands, Move.PrimaryAttack)
                    self.inAttackRange = true
                    
                end
                
            end
        
        end        
        
    end
    
end

function BotPlayer:MoveToPoint(toPoint, move)

    local player = self:GetPlayer()
    
    // Fill in move to get to specified point
    local diff = (toPoint - player:GetEyePos())
    local direction = GetNormalizedVector(diff)
        
    // Look at target (needed for moving and attacking)
    move.yaw   = GetYawFromVector(direction) - player.baseYaw
    move.pitch = GetPitchFromVector(direction) - player.basePitch
    
    if not self.inAttackRange then
        move.move.z = 1        
    end

end

/**
 * Responsible for generating the "input" for the bot. This is equivalent to
 * what a client sends across the network.
 */
function BotPlayer:GenerateMove()

    local player = self:GetPlayer()
    local move = Move()
    
    // keep the current yaw/pitch as default
    move.yaw = player:GetAngles().yaw
    move.pitch = player:GetAngles().pitch


    self.inAttackRange = false
    
    // If we're inside an egg, hatch
    if player:isa("AlienSpectator") then
        move.commands = Move.PrimaryAttack
    else
    
        local order = player:GetCurrentOrder()

        // Look at order and generate move for it
        if order then
        
            self:UpdateWeaponMove(move)
        
            local orderLocation = order:GetLocation()
            
            // Check for moving targets. This isn't done inside Order:GetLocation
            // so that human players don't have special information about invisible
            // targets just because they have an order to them.
            if (order:GetType() == kTechId.Attack) then
                local target = Shared.GetEntity(order:GetParam())
                if (target ~= nil) then
                    orderLocation = target:GetEngagementPoint()
                end
            end
            
            local moved = false            
            
            if self.pathingEnabled then
            
                Server.MoveToTarget(PhysicsMask.AIMovement, player, player:GetWaypointGroupName(), orderLocation, 1.5)
                
                if self:GetNumPoints() ~= 0 then
                    self:MoveToPoint(player:GetCurrentPathPoint(), move)
                    moved = true
                end
                
            end
            
            if not moved then
                // Generate naive move towards point
                self:MoveToPoint(orderLocation, move)
            end
            
        else
        
            // If no goal, hop around randomly
            self:MoveRandomly(move) 
            
        end
        
        // Trigger request when marine need them (health, ammo, orders)
        self:TriggerAlerts()
        
    end
    
    return move

end

function BotPlayer:TriggerAlerts()

    local player = self:GetPlayer()
    
    local team = player:GetTeam()
    if player:isa("Marine") and team and team.TriggerAlert then
    
        local primaryWeapon = nil
        local weapons = player:GetHUDOrderedWeaponList()        
        if table.count(weapons) > 0 then
            primaryWeapon = weapons[1]
        end
        
        // Don't ask for stuff too often
        if not self.timeOfLastRequest or (Shared.GetTime() > self.timeOfLastRequest + 9) then
        
            // Ask for health if we need it
            if player:GetHealthScalar() < .4 and (math.random() < .3) then
            
                player:PlaySound(marineRequestSayingsSounds[2])
                team:TriggerAlert(kTechId.MarineAlertNeedMedpack, player)
                self.timeOfLastRequest = Shared.GetTime()
                
            // Ask for ammo if we need it            
            elseif primaryWeapon and primaryWeapon:isa("ClipWeapon") and (primaryWeapon:GetAmmo() < primaryWeapon:GetMaxAmmo()*.4) and (math.random() < .25) then
            
                player:PlaySound(marineRequestSayingsSounds[3])
                team:TriggerAlert(kTechId.MarineAlertNeedAmmo, player)
                self.timeOfLastRequest = Shared.GetTime()
                
            elseif (not player:GetHasOrder()) and (math.random() < .2) then
            
                player:PlaySound(marineRequestSayingsSounds[4])
                team:TriggerAlert(kTechId.MarineAlertNeedOrder, player)
                self.timeOfLastRequest = Shared.GetTime()
                
            end
            
        end
        
    end
    
end


function BotPlayer:OnThink()

    Bot.OnThink(self)

    local player = self:GetPlayer()

    if not self.initializedBot then
        self.prefersAxe = (math.random() < .5)
        self.inAttackRange = false
        self.initializedBot = true
    end
        
    self:UpdateName()
    
    // Orders update and completed in Player:UpdateOrder()
    // Don't give orders to bots that are waiting to spawn.
    if not player:isa("Spectator") then
        self:ChooseOrder()
    end

    player:UpdateOrder()
    
end