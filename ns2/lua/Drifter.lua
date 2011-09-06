// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Drifter.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable glowing insect that the alien commander can control. Used to build structures
// and has other special abilities. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/EnergyMixin.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/mixins/ControllerMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/AttackOrderMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FuryMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/FireMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/TargetMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/HiveSightBlipMixin.lua")

class 'Drifter' (ScriptActor)

Drifter.kMapName = "drifter"

Drifter.kModelName = PrecacheAsset("models/alien/drifter/drifter.model")

Drifter.kOrdered2DSoundName  = PrecacheAsset("sound/ns2.fev/alien/drifter/ordered_2d")
Drifter.kOrdered3DSoundName  = PrecacheAsset("sound/ns2.fev/alien/drifter/ordered")

Drifter.kAnimFly = "fly"
Drifter.kAnimLandBuild = "land_build"

Drifter.kMoveSpeed = 15
Drifter.kMoveThinkInterval = .05
Drifter.kBuildDistance = .01        // Distance at which he can start building a structure. 
Drifter.kHealth = 100
Drifter.kArmor = kDrifterArmor
Drifter.kParasiteDamage = 10
Drifter.kFlareTime = 5              // How long the flare affects a player
Drifter.kFlareMaxDistance = 15
            
Drifter.kCapsuleHeight = .05
Drifter.kCapsuleRadius = .5
Drifter.kStartDistance = 5
Drifter.kHoverHeight = 1.2

Drifter.kMoveToDistance = 1

Drifter.networkVars = {
    // 0-1 scalar used to set move_speed model parameter according to how fast we recently moved
    moveSpeed               = "float",
    timeOfLastUpdate        = "float",
    moveSpeedParam          = "compensated float",
    landed                  = "boolean"
}

PrepareClassForMixin(Drifter, EnergyMixin)
PrepareClassForMixin(Drifter, ControllerMixin)
PrepareClassForMixin(Drifter, LiveMixin)
PrepareClassForMixin(Drifter, UpgradableMixin)
PrepareClassForMixin(Drifter, GameEffectsMixin)
PrepareClassForMixin(Drifter, FuryMixin)
PrepareClassForMixin(Drifter, FlinchMixin)
PrepareClassForMixin(Drifter, OrdersMixin)
PrepareClassForMixin(Drifter, FireMixin)
PrepareClassForMixin(Drifter, CloakableMixin)

function Drifter:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, ControllerMixin)
    InitMixin(self, DoorMixin)
    InitMixin(self, EnergyMixin)
    InitMixin(self, BuildingMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, PathingMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FuryMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, OrdersMixin)
    InitMixin(self, FireMixin)
    InitMixin(self, SelectableMixin)
    
    if Server then
        InitMixin(self, AttackOrderMixin, { kMoveToDistance = Drifter.kMoveToDistance })
        InitMixin(self, TargetMixin)
        InitMixin(self, LOSMixin)
        InitMixin(self, HiveSightBlipMixin)
    end

    // Create the controller for doing collision detection.
    self:CreateController(PhysicsGroup.CommanderUnitGroup)
    
    if Server then
        self:TriggerEffects("spawn")
    end
    
end

function Drifter:OnInit()
    
    self:SetModel(Drifter.kModelName)
    
    self:SetPhysicsType(PhysicsType.Kinematic)

    ScriptActor.OnInit(self)
    
    self.moveSpeed = 0
    self.timeOfLastUpdate = 0
    self.moveSpeedParam = 0
    self.landed = false

    if(Server) then
    
        self.justSpawned = true    
        self:SetNextThink(Drifter.kMoveThinkInterval)
        
        self:SetUpdates(true)
        self:UpdateIncludeRelevancyMask()
        
    end
    
    self:UpdateControllerFromEntity()
        
end

// Required by ControllerMixin.
function Drifter:GetControllerSize()
    return Drifter.kCapsuleHeight, Drifter.kCapsuleRadius
end

// Required by ControllerMixin.
function Drifter:GetMovePhysicsMask()
    return PhysicsMask.Movement
end

function Drifter:GetExtentsOverride()
    return Vector(Drifter.kCapsuleRadius, Drifter.kCapsuleHeight / 2, Drifter.kCapsuleRadius)
end

function Drifter:GetIsFlying()
    return true
end

function Drifter:GetHoverHeight()    
    return Drifter.kHoverHeight
end

function Drifter:GetFov()
    return 120
end

function Drifter:GetIsCloakable()
    return true
end

function Drifter:GetDeathIconIndex()
    return kDeathMessageIcon.Drifter
end

function Drifter:GetCanTakeDamageOverride()
    return not self.landed
end

function Drifter:OnOrderChanged()

    self:SetNextThink(Drifter.kMoveThinkInterval)
    
    self:PlaySound(Drifter.kOrdered3DSoundName)
    
    local owner = self:GetOwner()
    if owner then
        Server.PlayPrivateSound(owner, Drifter.kOrdered2DSoundName, owner, 1.0, Vector(0, 0, 0))
    end
        
end

function Drifter:OverrideTechTreeAction(techNode, position, orientation, commander)

    local success = false
    local keepProcessing = true
    
    // Convert build tech actions into build orders
    if(techNode:GetIsBuild()) then
        
        self:GiveOrder(kTechId.Build, techNode:GetTechId(), position, orientation, not commander.queuingOrders, false)
        
        // If Drifter was orphaned by commander that has left chair or server, take control
        if self:GetOwner() == nil then
            self:SetOwner(commander)
        end
        
        success = true
        keepProcessing = false
        
    end
    
    return success, keepProcessing
    
end

function Drifter:OnOverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // If target is enemy, attack it
    if (order:GetType() == kTechId.Default) then
    
        if orderTarget ~= nil and HasMixin(orderTarget, "Live") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() then
            order:SetType(kTechId.Attack)
        else
            order:SetType(kTechId.Move)
        end
        
    end
    
end

function Drifter:GetPositionForEntity(hive)

    local angle = NetworkRandom() * math.pi*2
    local startPoint = self:GetOrigin() + Vector( math.cos(angle)*Drifter.kStartDistance , Drifter.kHoverHeight, math.sin(angle)*Drifter.kStartDistance )
    local direction = Vector(self:GetAngles():GetCoords().zAxis)                               
    startPoint = GetHoverAt(self, startPoint)
    
    return BuildCoords(Vector(0, 1, 0), direction, startPoint)
    
end

function Drifter:ProcessJustSpawned()

    self.justSpawned = nil
    
    // Now look for nearby hive to see if it has a rally point for us
    local ents = GetEntitiesForTeamWithinRange("Hive", self:GetTeamNumber(), self:GetOrigin(), 1)

    if(table.maxn(ents) == 1) then
    
        self:ProcessRallyOrder(ents[1])
        
    end  
    
          
    // Give move order to random location nearby
    local startPoint = self:GetPositionForEntity(ents[1])
    self:GiveOrder(kTechId.Move, Entity.invalidId, startPoint.origin, nil, false, false)

    self:OnIdle()
    
end

function Drifter:OnThink()

    ScriptActor.OnThink(self)

    if(Server and self.justSpawned) then
        self:ProcessJustSpawned()           
    end        

    if not self:GetIsAlive() then
        return 
    end
    
    // Check to see if it's time to go off. Don't process other orders while getting ready to explode.
    if self.flareExplodeTime then
    
        if Shared.GetTime() > self.flareExplodeTime then
            self:PerformFlare()
        else
            self:SetNextThink(Drifter.kMoveThinkInterval)
        end
        
        return
    
    elseif self.parasiteTime and (Shared.GetTime() > self.parasiteTime) then
    
        self:PerformParasite()
            
    end
    
    local currentOrder = self:GetCurrentOrder()
    if( currentOrder ~= nil ) then
    
        local drifterMoveSpeed = GetDevScalar(Drifter.kMoveSpeed, 8)
        
        local currentOrigin = Vector(self:GetOrigin())
        
        if(currentOrder:GetType() == kTechId.Move) then
            self:ProcessMoveOrder(drifterMoveSpeed)
        elseif(currentOrder:GetType() == kTechId.Attack) then
        
            // From AttackOrderMixin.
            self:ProcessAttackOrder(5, drifterMoveSpeed, Drifter.kMoveThinkInterval)
                        
        elseif(currentOrder:GetType() == kTechId.Build) then 
            self:ProcessBuildOrder(drifterMoveSpeed)
        end
        
        // Check difference in location to set moveSpeed
        local distanceMoved = (self:GetOrigin() - currentOrigin):GetLength()
        
        self.moveSpeed = (distanceMoved / drifterMoveSpeed) / Drifter.kMoveThinkInterval
        
        if self:GetCanNewActivityStart() then
        
            if self.moveSpeed == 0 then
                self:OnIdle()
            else
                self:SetAnimation(Drifter.kAnimFly)
            end
            
        end
        
        self:SetNextThink(Drifter.kMoveThinkInterval)

    end
    
end

function Drifter:ResetOrders(resetOrigin)
     self.landed = false
     self:SetIgnoreOrders(false)    
     self:ClearOrders()
     
     if resetOrigin then
        self:SetAnimationWithBlending(Drifter.kAnimFly, nil, true)         
        self:SetOrigin(self:GetOrigin() + Vector(0, self:GetHoverHeight(), 0))
     end     
end

function Drifter:ProcessBuildOrder(moveSpeed)
    local currentOrder = self:GetCurrentOrder()    
    local distToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLengthXZ()
    local reset = (self:GetCanNewActivityStart() and self.landed)
    local engagementDist = ConditionalValue(currentOrder:GetType() == kTechId.Build, GetEngagementDistance(currentOrder:GetParam(), true), GetEngagementDistance(currentOrder:GetParam()))
    if (distToTarget < engagementDist) then        
        // the location we move to is always at the correct height to move to.
        // the place we are going to build on is located on the ground though, so
        // drop the order location to the ground location

        // The current order location is already snapped to the ground.
        local groundLocation = currentOrder:GetLocation()
        local techId = currentOrder:GetParam()
        
        // Create structure here
        local commander = self:GetOwner()
        if (not commander) then
            self:ResetOrders(false)            
            return
        end
        
        local legalBuildPosition = false
        local position = nil
        local attachEntity = nil
        
        // We want to Eval the build even before we do this animation it seems wasteful to do the animation if we already
        // know its going to fail and to be honest we should never get to this point anyways
        legalBuildPosition, position, attachEntity = self:EvalBuildIsLegal(techId, groundLocation, self, Vector(0, 1, 0))
        if (not legalBuildPosition) then
            self:ResetOrders(false)
            return
        end
             
        // Play land_build animation, then build it
        if not self.landed then
            self:SetOrigin(groundLocation)
            self:SetAnimationWithBlending(Drifter.kAnimLandBuild, nil, true)
            local length = self:GetAnimationLength(Drifter.kAnimLandBuild)
            self:SetActivityEnd(length)
            self.landed = true  
            
            self:SetIgnoreOrders(true)
               
        elseif self:GetCanNewActivityStart() then

            // whatever else happens, we reset our landed state
            self.landed = false
            
            local techNode = commander:GetTechTree():GetTechNode(techId)
            
            if techNode == nil then
                Print("Drifter:OnThink(): Couldn't find tech node for build id %s (%s)", EnumToString(kTechId, techId), ToString(techId))
            else
                        
                local cost = techNode:GetCost()
                local team = commander:GetTeam()

                if(team:GetTeamResources() >= cost) then
                            
                    local success = false
                    local createdStructureId = -1
                    success, createdStructureId = self:AttemptToBuild(techId, groundLocation, Vector(0, 1, 0), currentOrder:GetOrientation(), nil, nil, self)
                                    
                    if(success) then
                        team:AddTeamResources(-cost)
                        self:CompletedCurrentOrder()
                        self:SendEntityChanged(createdStructureId)
                                    
                        // Now remove Drifter - we're morphing into structure
                        DestroyEntity(self)
                                    
                    else
                        // TODO: Issue alert to commander that way was blocked?
                        self:ResetOrders(true)
                    end
                                
                else
                    // Play more resources required
                    self:GetTeam():TriggerAlert(kTechId.AlienAlertNotEnoughResources, self)
                                    
                    // Cancel build bots orders so he doesn't move away
                    self:ResetOrders(true)
                                    
                end 
            end                    
        end
    else
        if not self:GetIgnoreOrders() then
          self:ProcessMoveOrder(moveSpeed)
        end
    end
    
end

function Drifter:ProcessMoveOrder(moveSpeed)
    local currentOrder = self:GetCurrentOrder()
    
    if (currentOrder ~= nil) then
        local isBuild = (currentOrder:GetType() == kTechId.Build)
        local hoverAdjustedLocation = currentOrder:GetLocation()
        self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, moveSpeed, Drifter.kMoveThinkInterval)
        if(not isBuild and self:IsTargetReached(hoverAdjustedLocation, kEpsilon, true)) then
            self:CompletedCurrentOrder()
        end
    end
end

function Drifter:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    self:UpdateControllerFromEntity()
    
    if self.timeOfLastUpdate ~= 0 then
    
        // Blend smoothly towards target value
        self.moveSpeedParam = Clamp(Slerp(self.moveSpeedParam, self.moveSpeed, (Shared.GetTime() - self.timeOfLastUpdate)*1), 0, 1)
        self:SetPoseParam("move_speed", self.moveSpeedParam)
        
    end
    
    if Server then    
        self:UpdateEnergy(deltaTime)
    end
    
    self.timeOfLastUpdate = Shared.GetTime()
    
end

function Drifter:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then 
        return { kTechId.BuildMenu, kTechId.Move, kTechId.Stop, kTechId.DrifterParasite, kTechId.DrifterFlare }
    elseif(techId == kTechId.BuildMenu) then 
        return { kTechId.RootMenu, kTechId.Hive, kTechId.Harvester, kTechId.Whip, kTechId.Crag, kTechId.Shift, kTechId.Shade }
    end
    
    return nil
    
end

function Drifter:GetActivationTechAllowed(techId)

    if techId == kTechId.DrifterParasite or techId == kTechId.DrifterFlare then
        return (self.flareExplodeTime == nil) and (self.parasiteTime == nil)
    end
    
    return true
    
end

function Drifter:PerformActivation(techId, position, normal, commander)

    if(techId == kTechId.DrifterFlare) then
    
        self:TriggerEffects("drifter_flare")
        
        self.flareExplodeTime = Shared.GetTime() + 2
        
        return true

    elseif (techId == kTechId.DrifterParasite) then

        self:TriggerEffects("drifter_parasite")
        
        if Server then
        
            local parasiteTarget = GetActivationTarget( GetEnemyTeamNumber(self:GetTeamNumber()), position )
            
            if parasiteTarget then
            
                self.parasiteTargetId = parasiteTarget:GetId()
                self.parasiteTime = Shared.GetTime() + 1
                self:SetActivityEnd(1)
                
            end
            
        end
        
    else

        return ScriptActor.PerformActivation(self, techId, position, normal, commander)
        
    end
    
end

function Drifter:OnEntityChange(oldId, newId)

    if oldId == self.parasiteTargetId and oldId ~= nil then
        self.parasiteTargetId = newId
    end
    
    ScriptActor.OnEntityChange(self, oldId, newId)
    
end

function Drifter:PerformFlare()

    // Look for enemy non-Commanders that can see drifter
    local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
    local time = Shared.GetTime()
    
    // Blind enemies them temporarily. Show effect for friendly players too, but very mild.
    local score = 0
    for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
    
        local scalar = 0
        local canSee = player:GetCanSeeEntity(self)
        local isEnemy = (enemyTeamNumber == player:GetTeamNumber())
        
        // Scalar is 1 if player is enemy, and can see drifter
        if isEnemy and canSee then
            scalar = 1
            
        // Scalar is lower if player isn't enemy and can see drifter
        elseif canSee then
            scalar = .25
            
        // Scalar is low if player can't see it and is nearby
        else
            
            local dist = (player:GetOrigin() - self:GetOrigin()):GetLength()
            if dist < Drifter.kFlareMaxDistance then
            
                // Make sure we're in the same room
                scalar = .2
                
            end
            
        end
        
        if scalar > 0 then
            player:SetFlare(time, time + Drifter.kFlareTime, scalar)
            score = score + 1
        end
        
    end
    
    self:AddScoreForOwner(score)
    
    // Kill self
    self:Kill(self, self)
    
    self.flareExplodeTime = nil
    self.parasiteTime = nil

end

function Drifter:PerformParasite()

    if self.parasiteTargetId and self.parasiteTargetId ~= Entity.invalidId then
    
        local target = Shared.GetEntity(self.parasiteTargetId)
        assert(target ~= nil)
        
        local commander = self:GetOwner()
        local direction = GetNormalizedVector(target:GetModelOrigin() - self:GetOrigin())
        target:TakeDamage(Parasite.kDamage, commander, self, target:GetModelOrigin(), direction)
                
        target:TriggerEffects("drifter_parasite_hit")
                
        // Mark player or structure 
        if not target:GetGameEffectMask(kGameEffect.Parasite) then
        
            target:SetGameEffectMask(kGameEffect.Parasite, true)
            
        end
        
    end

    self.parasiteTargetId = nil
    self.parasiteTime = nil
    
end

function Drifter:GetMeleeAttackDamage()
    return kDrifterAttackDamage
end

function Drifter:GetMeleeAttackInterval()
    return kDrifterAttackFireDelay
end

function Drifter:GetMeleeAttackOrigin()
    return self:GetOrigin()
end

function Drifter:OnOverrideDoorInteraction(inEntity)
    return true, 4
end

function Drifter:UpdateIncludeRelevancyMask()
    self:SetAlwaysRelevantToCommander(true)
end

Shared.LinkClassToMap("Drifter", Drifter.kMapName, Drifter.networkVars)
