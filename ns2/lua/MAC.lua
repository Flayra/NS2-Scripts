// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MAC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable flying robot marine commander can control. Used to build structures
// and has other special abilities. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/EnergyMixin.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/mixins/ControllerMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/TargetMixin.lua")
Script.Load("lua/LOSMixin.lua")

class 'MAC' (LiveScriptActor)

MAC.kMapName = "mac"

MAC.kModelName = PrecacheAsset("models/marine/mac/mac.model")

MAC.kConfirmSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/confirm")
MAC.kConfirm2DSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/confirm_2d")
MAC.kStartConstructionSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/constructing")
MAC.kStartConstruction2DSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/constructing_2d")
MAC.kHelpingSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/help_build")
MAC.kPassbyMACSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/passby_mac")
MAC.kPassbyDrifterSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/passby_driffter")
MAC.kIdleSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/idle")
MAC.kUsedSoundName = PrecacheAsset("sound/ns2.fev/marine/structures/mac/use")

// Animations
MAC.kAnimAttack = "attack"

MAC.kRightJetNode = "fxnode_jet1"
MAC.kLeftJetNode = "fxnode_jet2"
MAC.kLightNode = "fxnode_light"
MAC.kWelderNode = "fxnode_welder"

// Balance
MAC.kMoveThinkInterval = .05
MAC.kConstructThinkInterval = .4
MAC.kRepairHealthPerSecond = 200
MAC.kWeldThinkInterval = .5
MAC.kHealth = kMACHealth
MAC.kArmor = kMACArmor
MAC.kMoveSpeed = 9
MAC.kHoverHeight = 1.5
MAC.kStartDistance = 3
MAC.kWeldDistance = 3
MAC.kBuildDistance = 2     // Distance at which bot can start building a structure. 
MAC.kBuildOrderDistance = 10     // Distance at which bot can start building a structure. 
MAC.kOrderScanRadius = 5
MAC.kSpeedUpgradePercent = (1 + kMACSpeedAmount)

MAC.kCapsuleHeight = .2
MAC.kCapsuleRadius = .5

// Greetings
MAC.kGreetingUpdateInterval = 1
MAC.kGreetingInterval = 10
MAC.kGreetingDistance = 5
MAC.kUseTime = 2.0

MAC.networkVars = {}

PrepareClassForMixin(MAC, EnergyMixin)
PrepareClassForMixin(MAC, ControllerMixin)
PrepareClassForMixin(MAC, GameEffectsMixin)
PrepareClassForMixin(MAC, FlinchMixin)

function MAC:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    InitMixin(self, ControllerMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, PathingMixin)
    
    if Server then
        InitMixin(self, TargetMixin)
        InitMixin(self, LOSMixin)
    end
 
    // Create the controller for doing collision detection.
    self:CreateController(PhysicsGroup.CommanderUnitGroup)
    
    self:SetUpdates(true)
    
    if Server then
        self:TriggerEffects("spawn")
    end
    
end

function MAC:OnInit()

    InitMixin(self, DoorMixin)
    InitMixin(self, EnergyMixin )
    InitMixin(self, BuildingMixin )
    
    LiveScriptActor.OnInit(self)

    self:SetModel(MAC.kModelName)

    self:SetPhysicsType(Actor.PhysicsType.Kinematic)

    if(Server) then
    
        self.justSpawned = true    
        self:SetNextThink(MAC.kMoveThinkInterval)
        self:UpdateIncludeRelevancyMask()
            
    end
    
    self:UpdateControllerFromEntity()
    
    self.timeOfLastGreeting = 0
    self.timeOfLastGreetingCheck = 0
    self.timeOfLastChatterSound = 0
    self.timeOfLastWeld = 0
    self.timeOfLastConstruct = 0
    
end

function MAC:GetExtents()
    return Vector(MAC.kCapsuleRadius, MAC.kCapsuleHeight/2, MAC.kCapsuleRadius)
end

function MAC:GetFov()
    return 120
end

// Required by ControllerMixin.
function MAC:GetControllerSize()
    return MAC.kCapsuleHeight, MAC.kCapsuleRadius
end

// Required by ControllerMixin.
function MAC:GetMovePhysicsMask()
    return PhysicsMask.Movement
end

function MAC:GetIsFlying()
    return true
end

function MAC:GetCanBeUsed(player)
    return true
end

function MAC:OnUse(player, elapsedTime, useAttachPoint, usePoint)
    // Play flavor sounds when using MAC
    if Server then    
        local time = Shared.GetTime()
        
        if self.timeOfLastUse == nil or (time > (self.timeOfLastUse + MAC.kUseTime)) then    
            Server.PlayPrivateSound(player, MAC.kUsedSoundName, self, 1.0, Vector(0, 0, 0))
            self.timeOfLastUse = time
        end        
    end    
    return true    
end

function MAC:GetHoverHeight()
    return MAC.kHoverHeight
end

function MAC:OnOverrideOrder(order)
    
    local orderTarget = nil
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to unbuilt friendly structures should be construct orders
    if(order:GetType() == kTechId.Default and GetOrderTargetIsConstructTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Construct)

    elseif(order:GetType() == kTechId.Default and GetOrderTargetIsWeldTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Weld)
        
    elseif(order:GetType() == kTechId.Weld and not GetOrderTargetIsWeldTarget(order, self:GetTeamNumber())) then

        // Not valid, cancel order
        order:SetType(kTechId.None)
        
    // If target is enemy, attack it
    elseif (order:GetType() == kTechId.Default) and orderTarget ~= nil and orderTarget:isa("LiveScriptActor") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() then
    
        order:SetType(kTechId.Attack)

    elseif((order:GetType() == kTechId.Default or order:GetType() == kTechId.Move) and (order:GetParam() ~= nil)) then
        
        // Convert default order (right-click) to move order
        order:SetType(kTechId.Move)
        
    end
    
end

function MAC:GetIsOrderHelpingOtherMAC(order)

    if order:GetType() == kTechId.Construct then
    
        // Look for friendly nearby MACs
        local macs = GetEntitiesForTeamWithinRange("MAC", self:GetTeamNumber(), self:GetOrigin(), 3)
        for index, mac in ipairs(macs) do
        
            if mac ~= self then
            
                local otherMacOrder = mac:GetCurrentOrder()
                if otherMacOrder ~= nil and otherMacOrder:GetType() == order:GetType() and otherMacOrder:GetParam() == order:GetParam() then
                    return true
                end
                
            end
            
        end
        
    end
    
    return false
end

function MAC:OnOrderChanged()
    local order = self:GetCurrentOrder()    
    if order then
        // Look for nearby MAC doing the same thing
        if self:GetIsOrderHelpingOtherMAC(order) then
            self:PlayChatSound(MAC.kHelpingSoundName)
        elseif order:GetType() == kTechId.Construct then
            self:PlayChatSound(MAC.kStartConstructionSoundName)
        else
            self:PlayChatSound(MAC.kConfirmSoundName)
        end
        
        local owner = self:GetOwner()
        if owner then
            Server.PlayPrivateSound(owner, MAC.kConfirm2DSoundName, owner, 1.0, Vector(0, 0, 0))
        end
        
        self:TriggerEffects("mac_set_order")
    end

end

function MAC:OnDestroyCurrentOrder(currentOrder)
    
    local orderTarget = nil
    if (currentOrder:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(currentOrder:GetParam())
    end
    
    if(currentOrder:GetType() == kTechId.Weld and GetOrderTargetIsWeldTarget(currentOrder, self:GetTeamNumber())) then
        orderTarget:OnWeldCanceled(self)
    end
end

function MAC:OverrideTechTreeAction(techNode, position, orientation, commander)

    local success = false
    local keepProcessing = true
    
    
    local distanceToTarget = (position - Vector(self:GetOrigin())):GetLength()    
    
    // Convert build tech actions into build orders
    if(techNode:GetIsBuild() and distanceToTarget < MAC.kBuildOrderDistance) then
        
        self:GiveOrder(kTechId.Build, techNode:GetTechId(), position, orientation, not commander.queuingOrders, false)
        
        // If MAC was orphaned by commander that has left chair or server, take control
        if self:GetOwner() == nil then
            self:SetOwner(commander)
        end
        
        success = true
        keepProcessing = false
        
    end
    
    return success, keepProcessing
    
end

function MAC:GetMoveSpeed()

    local moveSpeed = GetDevScalar(MAC.kMoveSpeed, 8)
    local techNode = self:GetTeam():GetTechTree():GetTechNode(kTechId.MACSpeedTech)

    if techNode and techNode:GetResearched() then
        moveSpeed = moveSpeed * MAC.kSpeedUpgradePercent
    end

    return moveSpeed
    
end

function MAC:ProcessWeldOrder(deltaTime)
    local time = Shared.GetTime()
    
    local setNextThink = false
    local order = self:GetCurrentOrder()
    local targetId = order:GetParam()
    local target = Shared.GetEntity(targetId)
    local canBeWeldedNow = false
    local canBeWeldedFuture = false
    
    if self.timeOfLastWeld == 0 or (time > (self.timeOfLastWeld + MAC.kWeldThinkInterval)) then
        if(target ~= nil) then    
            local targetPosition = Vector(target:GetOrigin())
            local distanceToTarget = (targetPosition - Vector(self:GetOrigin())):GetLength()
            canBeWeldedNow, canBeWeldedFuture = target:GetCanBeWelded(self)
        
            // If we're close enough to weld, weld
            if(distanceToTarget < MAC.kWeldDistance) then
            
                if( (canBeWeldedNow or canBeWeldedFuture) and target:OnWeld(self, MAC.kWeldThinkInterval)) then  
                    // Play puff of sparks
                    self:TriggerEffects("mac_weld")
                    self.timeOfLastWeld = time
                elseif not canBeWeldedNow and not canBeWeldedFuture then            
                    self:CompletedCurrentOrder()                
                end
        
            else        
                // otherwise move towards it
                local hoverAdjustedLocation = self:GetHoverAt(target:GetEngagementPoint())
                self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime)
                self.timeOfLastWeld = time
            end
        end
    
        // If door or structure is welded, complete order
        if(target == nil or (not canBeWeldedNow and not canBeWeldedFuture) ) then    
            self:CompletedCurrentOrder()        
        end    
    end
end

function MAC:ProcessJustSpawned()

    self.justSpawned = nil
    
    // Now look for nearby command station to see if it has a rally point for us
    local ents = GetEntitiesForTeamWithinRange("CommandStation", self:GetTeamNumber(), self:GetOrigin(), 1)

    if(table.maxn(ents) == 1) then
    
        self:ProcessRallyOrder(ents[1])
        
    end  

    // Move bot away from CC so he can be selected    
    local angle = NetworkRandom() * math.pi*2
    local startPoint = self:GetOrigin() + Vector( math.cos(angle)*MAC.kStartDistance , MAC.kHoverHeight, math.sin(angle)*MAC.kStartDistance )
    self:SetOrigin(startPoint)
    
    self:TriggerEffects("idle")

end

function MAC:ProcessMove(deltaTime)

    local currentOrder = self:GetCurrentOrder()
    local hoverAdjustedLocation = self:GetHoverAt(currentOrder:GetLocation())
    
    self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime)
    if(self:IsTargetReached(currentOrder:GetLocation(), kEpsilon)) then    
        self:TriggerEffects("mac_move_complete")
        self:CompletedCurrentOrder()                
    else
        self:TriggerEffects("mac_move")
    end
end

function MAC:PlayChatSound(soundName)
    if self.timeOfLastChatterSound == 0 or (Shared.GetTime() > self.timeOfLastChatterSound + 2) then
        self:PlaySound(soundName)
        self.timeOfLastChatterSound = Shared.GetTime()
    end
end

// Look for other MACs and Drifters to greet as we fly by 
function MAC:UpdateGreetings()

    local time = Shared.GetTime()
    if self.timeOfLastGreetingCheck == 0 or (time > (self.timeOfLastGreetingCheck + MAC.kGreetingUpdateInterval)) then
    
        if self.timeOfLastGreeting == 0 or (time > (self.timeOfLastGreeting + MAC.kGreetingInterval)) then
        
            local ents = GetEntitiesMatchAnyTypes({"MAC", "Drifter"})
            for index, ent in ipairs(ents) do
            
                if (ent ~= self) and (self:GetOrigin() - ent:GetOrigin()):GetLength() < MAC.kGreetingDistance then
                
                    if GetCanSeeEntity(self, ent) then
                        if ent:isa("MAC") then
                            self:PlayChatSound(MAC.kPassbyMACSoundName)
                        elseif ent:isa("Drifter") then
                            self:PlayChatSound(MAC.kPassbyDrifterSoundName)
                        end
                        
                        self.timeOfLastGreeting = time
                        break
                        
                    end
                    
                end                    
                    
            end                
                            
        end
        
        self.timeOfLastGreetingCheck = time
        
    end

end

function MAC:ProcessBuildConstruct(deltaTime)
    local time = Shared.GetTime()
    
    local currentOrder = self:GetCurrentOrder()
    
    local distToTarget = (currentOrder:GetLocation() - self:GetOrigin()):GetLengthXZ()
    if self.timeOfLastConstruct == 0 or (time > (self.timeOfLastConstruct + MAC.kConstructThinkInterval)) then
    local engagementDist = ConditionalValue(currentOrder:GetType() == kTechId.Build, GetEngagementDistance(currentOrder:GetParam(), true), GetEngagementDistance(currentOrder:GetParam()))
    if distToTarget < engagementDist then
           
        // Create structure here
        if(currentOrder:GetType() == kTechId.Build) then
        
            local commander = self:GetOwner()
            if commander then            
                local techId = currentOrder:GetParam()
                local techNode = commander:GetTechTree():GetTechNode(techId)
                local cost = (techNode and techNode:GetCost()) or nil
                local team = commander:GetTeam()
                
                if(cost == nil) then                
                    Print("Cost for techId %d is not defined.", tostring(techId))
                    return                    
                end
                
                if(team:GetTeamResources() >= cost) then              
                    local success, createdStructureId = self:AttemptToBuild(techId, currentOrder:GetLocation(), Vector(0, 1, 0), currentOrder:GetOrientation(), nil, nil, self)
                    
                    // Now construct it
                    if(success) then                    
                        self:CompletedCurrentOrder()                    
                        team:AddTeamResources(-cost)                                                       
                        self:GiveOrder(kTechId.Construct, createdStructureId, nil, nil, false, true)                                            
                    else                    
                        // Issue alert to commander that way was blocked?
                        self:GetTeam():TriggerAlert(kTechId.MarineAlertMACBlocked, self)                        
                    end                    
                else                
                    self:GetTeam():TriggerAlert(kTechId.MarineAlertNotEnoughResources, self)
                    
                    // Cancel build bots orders so he doesn't move away
                    self:ClearOrders()                    
                end                        
            else
                self:ClearOrders()
            end                            
        else        
            // Construct structure
            local constructTarget = GetOrderTargetIsConstructTarget(self:GetCurrentOrder(), self:GetTeamNumber())            
            if constructTarget then            
                // Otherwise, add build time to structure
                constructTarget:Construct(MAC.kConstructThinkInterval * kMACConstructEfficacy)                
                self:TriggerEffects("mac_construct")
                self.timeOfLastConstruct = time
            else            
                self:CompletedCurrentOrder()                
            end            
        end                
    else    
        local hoverAdjustedLocation = self:GetHoverAt(currentOrder:GetLocation())
        self:MoveToTarget(PhysicsMask.AIMovement, hoverAdjustedLocation, self:GetMoveSpeed(), deltaTime)        
    end
    end
end

function MAC:OnThink()

    LiveScriptActor.OnThink(self)

    if(Server and self.justSpawned) then    
        self:ProcessJustSpawned()        
    end        
    
    if not self:GetIsAlive() then
        return 
    end
    
    local setNextThink = false        
    if not setNextThink then
        self:SetNextThink(MAC.kMoveThinkInterval)
    end

end

function MAC:UpdateOrders(deltaTime)
    local currentOrder = self:GetCurrentOrder()    
    if( currentOrder ~= nil ) then            
        if(currentOrder:GetType() == kTechId.Move) then
            self:ProcessMove(deltaTime)            
            self:UpdateGreetings()            
        elseif(currentOrder:GetType() == kTechId.Attack) then        
            self:ProcessAttackOrder(1, GetDevScalar(MAC.kMoveSpeed, 8), deltaTime)            
        elseif(currentOrder:GetType() == kTechId.Weld) then        
            setNextThink = self:ProcessWeldOrder(deltaTime)                    
        elseif((currentOrder:GetType() == kTechId.Build) or (currentOrder:GetType() == kTechId.Construct)) then         
            setNextThink = self:ProcessBuildConstruct(deltaTime)
        end        
    end
end

function MAC:OnUpdate(deltaTime)

    LiveScriptActor.OnUpdate(self, deltaTime)
    
    if Server then
        if (not self:GetHasOrder()) then
            self:FindSomethingToDo()
        else
            self:UpdateOrders(deltaTime)
        end
    end
    
    self:UpdateControllerFromEntity()
    
    self:UpdateEnergy(deltaTime)
    
end

function MAC:FindSomethingToDo()

    // If there's a friendly structure nearby that needs building, build it
    if self.timeOfLastFindSomethingTime == nil or Shared.GetTime() > self.timeOfLastFindSomethingTime + 1 then

        self.timeOfLastFindSomethingTime = Shared.GetTime()
        
        local ents = GetEntitiesForTeamWithinRange("Structure", self:GetTeamNumber(), self:GetOrigin(), MAC.kOrderScanRadius)
        
        for index, structure in ipairs(ents) do
        
            if(not structure:GetIsBuilt()) and structure:GetIsVisible() then
            
                local acceptedOrder = self:GiveOrder(kTechId.Construct, structure:GetId(), structure:GetOrigin(), nil, false, false) ~= kTechId.None
                return acceptedOrder
                
            end
            
        end
        
    end
    
    return false
    
end

function MAC:GetDeathIconIndex()
    return kDeathMessageIcon.MAC
end

function MAC:PerformAction(techNode, position)

    if(techNode:GetTechId() == kTechId.MACMine) then
    
        // TODO: 
        return true
        
    end

    return LiveScriptActor.PerformAction(self, techNode, position)
    
end

function MAC:GetMeleeAttackOrigin()
    return self:GetAttachPointOrigin("fxnode_welder")
end

function MAC:GetMeleeAttackDamage()
    return kMACAttackDamage
end

function MAC:GetMeleeAttackInterval()
    return kMACAttackFireDelay 
end

function MAC:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then return 
            {   kTechId.Attack, kTechId.Stop, kTechId.Move, kTechId.Weld,
                kTechId.MACMine, kTechId.MACEMP, kTechId.None, kTechId.None }

    else return nil end
    
end

function MAC:GetWaypointGroupName()
    return kAirWaypointsGroup
end

function MAC:OnOverrideDoorInteraction(inEntity)
    // MACs will not open the door if they are currently
    // welding it shut
    if self:GetHasOrder() then
        local order = self:GetCurrentOrder()
        local targetId = order:GetParam()
        local target = Shared.GetEntity(targetId)
        if (target ~= nil) then
            if (target == inEntity) then
               return false, 0
            end
        end
    end
    return true, 4
end

function MAC:UpdateIncludeRelevancyMask()
    self:SetAlwaysRelevantToCommander(true)
end

Shared.LinkClassToMap("MAC", MAC.kMapName, MAC.networkVars)
