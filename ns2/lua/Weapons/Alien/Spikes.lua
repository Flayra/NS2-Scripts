// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Spikes.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spike.lua")

class 'Spikes' (Ability)

Spikes.kMapName = "spikes"

Spikes.kModelName = PrecacheAsset("models/alien/lerk/lerk_view_spike.model")

// Lerk spikes (view model)
Spikes.kPlayerAnimAttack = "spikes"

Spikes.kDelay = kSpikeFireDelay
Spikes.kSnipeDelay = kSpikesAltFireDelay
Spikes.kZoomDelay = .3
Spikes.kZoomedFov = 45
Spikes.kZoomedSensScalar = 0.25
Spikes.kSpikeEnergy = kSpikeEnergyCost
Spikes.kSnipeEnergy = kSpikesAltEnergyCost
Spikes.kSnipeDamage = kSpikesAltDamage
Spikes.kSpread2Degrees = Vector( 0.01745, 0.01745, 0.01745 )

local networkVars =
{
    zoomedIn            = "boolean",
    fireLeftNext        = "boolean",
    timeZoomedIn        = "float",
    sporePoseParam      = "float"
}

function Spikes:OnCreate()

    Ability.OnCreate(self)

    self.zoomedIn = false
    self.fireLeftNext = true
    self.timeZoomedIn = 0
    self.sporePoseParam = 0
    
end

function Spikes:OnDestroy()

    // Make sure the player doesn't get stuck with scaled sensitivity.
    // Only change this if clientZoomedIn is true (we don't want other
    // Lerks dying causing the local client's Lerk to lose their zoomed
    // in sensitivity).
    if Client and self.clientZoomedIn then
        Client.SetMouseSensitivityScalar(1)
    end
    
    Ability.OnDestroy(self)
    
end

function Spikes:GetEnergyCost(player)
    return ConditionalValue(self.zoomedIn, Spikes.kSnipeEnergy, Spikes.kSpikeEnergy)
end

function Spikes:GetHasSecondary(player)
    return true
end

function Spikes:GetIconOffsetY(secondary)
    return ConditionalValue(not self.zoomedIn, kAbilityOffset.Spikes, kAbilityOffset.Sniper)
end

function Spikes:OnHolster(player)
    self:SetZoomState(player, false)
    Ability.OnHolster(self, player)
end

function Spikes:GetPrimaryAttackDelay()
    return ConditionalValue(self.zoomedIn, Spikes.kSnipeDelay, Spikes.kDelay)
end

function Spikes:GetDeathIconIndex()
    return ConditionalValue(self.zoomedIn, kDeathMessageIcon.SpikesAlt, kDeathMessageIcon.Spikes)
end

function Spikes:GetHUDSlot()
    return 1
end

function Spikes:PerformPrimaryAttack(player)

    // Alternate view model animation to fire left then right
    self.fireLeftNext = not self.fireLeftNext

    if not self.zoomedIn then
    
        self:FireSpikeProjectile(player)        
        
    else
    
        // Snipe them!
        self:PerformZoomedAttack(player)
        
    end

    player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))
    
    return true
end

function Spikes:FireSpikeProjectile(player)

    // On server, create projectile
    if(Server) then
    
        // trace using view coords, but back off the given distance to make sure we don't miss any walls
        local backOffDist = 0.5
        // fire from one meter in front of the lerk, to avoid the lerk flying into his own projectils (the projectile
        // will only start moving on the NEXT tick, and the lerk might be updated before the projectile. considering that
        // a lerk has a topspeed of 5-10m/sec, and a slow server update might be 100ms, you are looking at a lerk movement
        // per tick of 0.5-1m ... 1m should be good enough.
        local firePointOffs = 1.0
        // seems to be a bug in trace; make sure any entity indicate as hit are inside this range. 
        local maxTraceLen = backOffDist + firePointOffs
        
        local viewCoords = player:GetViewAngles():GetCoords()
        local alternate = (self.fireLeftNext and -.1) or .1
        local firePoint = player:GetEyePos() + viewCoords.zAxis * firePointOffs - viewCoords.yAxis * .1 + viewCoords.xAxis * alternate
        
        // To avoid the lerk butting his face against a wall and shooting blindly, trace and move back the firepoint
        // if hitting a wall
        local startTracePoint = player:GetEyePos() - viewCoords.zAxis * backOffDist + viewCoords.xAxis * alternate
        local trace = Shared.TraceRay(startTracePoint, firePoint, PhysicsMask.Bullets, EntityFilterOne(player))
        if trace.fraction ~= 1 and (trace.entity == nil or (trace.entity:GetOrigin() - startTracePoint):GetLength() < maxTraceLen) then
            local offset = math.max(backOffDist, trace.fraction * maxTraceLen)
            firePoint = startTracePoint + (viewCoords.zAxis * offset)
        end
        
        local spike = CreateEntity(Spike.kMapName, firePoint, player:GetTeamNumber())
        
        // Add slight randomness to start direction. Gaussian distribution.
        local x = (NetworkRandom() - .5) + (NetworkRandom() - .5)
        local y = (NetworkRandom() - .5) + (NetworkRandom() - .5)
        
        local spread = Spikes.kSpread2Degrees 
        local direction = viewCoords.zAxis + x * spread.x * viewCoords.xAxis + y * spread.y * viewCoords.yAxis

        spike:SetVelocity(direction * 20)
        
        spike:SetOrientationFromVelocity()
        
        spike:SetGravityEnabled(true)
        
        // Set spike parent to player so we don't collide with ourselves and so we
        // can attribute a kill to us
        spike:SetOwner(player)
        
        spike:SetIsVisible(true)
        
        spike:SetUpdates(true)
        
        spike:SetDeathIconIndex(self:GetDeathIconIndex())
                
    end

end

function Spikes:PerformZoomedAttack(player)

    // Trace line to attack
    local viewCoords = player:GetViewAngles():GetCoords()    
    local startPoint = player:GetEyePos()
    local endPoint = startPoint + viewCoords.zAxis * 1000

    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
        
    local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCs, filter)
    
    local hasPiercing = player:GetHasUpgrade(kTechId.Piercing)
    
    if Server and trace.fraction < 1 and trace.entity ~= nil and trace.entity:isa("LiveScriptActor")then
    
        local direction = GetNormalizedVector(endPoint - startPoint)
        
        local damageScalar = ConditionalValue(hasPiercing, kPiercingDamageScalar, 1)
        trace.entity:TakeDamage(Spikes.kSnipeDamage * damageScalar, player, self, endPoint, direction)
        
        if hasPiercing then
            trace.entity:TriggerEffects("spikes_snipe_hit")
        end
        
    else
        self:TriggerEffects("spikes_snipe_miss", {kEffectHostCoords = Coords.GetTranslation(trace.endPoint)})
    end
    
    player:SetActivityEnd(player:AdjustFuryFireDelay(Spikes.kSnipeDelay))
    
    
    
end

function Spikes:SetZoomState(player, zoomedIn)

    if zoomedIn ~= self.zoomedIn then
    
        self.zoomedIn = zoomedIn
        self.timeZoomedIn = Shared.GetTime()
        
        if Client and player == Client.GetLocalPlayer() then
        
            // Keep track of the zoomed state here just for the client.
            self.clientZoomedIn = self.zoomedIn
            // Lower mouse sensitivity when zoomed in, only affects the local player.
            Client.SetMouseSensitivityScalar(ConditionalValue(self.zoomedIn, Spikes.kZoomedSensScalar, 1))
            
        end
    end
    
end

// Toggle zoom
function Spikes:PerformSecondaryAttack(player)

    if(player:GetCanNewActivityStart()) then
    
        self:SetZoomState(player, not self.zoomedIn)
                
        player:SetActivityEnd(player:AdjustFuryFireDelay(Spikes.kZoomDelay))
        
        return true
        
    end
    
    return false
    
end

function Spikes:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)
    
    self.sporePoseParam = Clamp(Slerp(self.sporePoseParam, 0, (1 / kLerkWeaponSwitchTime) * input.time), 0, 1)
    
    viewModel:SetPoseParam("spore", self.sporePoseParam)
    
end

function Spikes:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    // Update fov smoothly but quickly
    local timePassed = Shared.GetTime() - self.timeZoomedIn
    local timeScalar = Clamp(timePassed/.12, 0, 1)
    local transitionScalar = Clamp(math.sin( timeScalar * math.pi / 2 ), 0, 1)
    local player = self:GetParent()

    if player then
    
        if self.zoomedIn then
            player:SetFov( Lerk.kFov + transitionScalar * (Spikes.kZoomedFov - Lerk.kFov))
        else
            player:SetFov( Spikes.kZoomedFov + transitionScalar * (Lerk.kFov - Spikes.kZoomedFov))
        end
        
    end
    
end

function Spikes:GetSecondaryAttackRequiresPress()
    return true
end

function Spikes:GetSecondaryEnergyCost(player)
    return 0
end

function Spikes:GetEffectParams(tableParams)

    Ability.GetEffectParams(self, tableParams)
    
    local player = self:GetParent()
    
    // Player may be nil when the spikes are first created.
    if (player ~= nil) then
        tableParams[kEffectFilterFrom] = player:GetHasUpgrade(kTechId.Piercing)
    end    
    
    tableParams[kEffectFilterLeft] = not self.fireLeftNext
    
end

Shared.LinkClassToMap("Spikes", Spikes.kMapName, networkVars )
