// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Spikes.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

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
Spikes.kSpread = Math.Radians(8)
Spikes.kNumSpikesOnSecondary = 5

// Does full damage up close then falls off over the max distance
Spikes.kMaxDamage = kSpikeMaxDamage
Spikes.kMinDamage = kSpikeMinDamage

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

    /*
    if not self.zoomedIn then
    */
    
        self:FireSpike(player)        

    /*        
    else
    
        // Snipe them!
        self:PerformZoomedAttack(player)
        
    end
    */

    player:SetActivityEnd(player:AdjustAttackDelay(self:GetPrimaryAttackDelay()))
    
    return true
end

function Spikes:FireSpike(player)

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    
    local startPoint = player:GetEyePos()
        
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
       
    if Client then
        DbgTracer.MarkClientFire(player, startPoint)
    end
    
    // Calculate spread for each shot, in case they differ    
    local randomAngle  = NetworkRandom() * math.pi * 2
    local randomRadius = NetworkRandom() * NetworkRandom() * math.tan(Spikes.kSpread)    
    local spreadDirection = (viewCoords.xAxis * math.cos(randomAngle) + viewCoords.yAxis * math.sin(randomAngle))
    local fireDirection = viewCoords.zAxis + spreadDirection * randomRadius
    fireDirection:Normalize()
   
    local endPoint = startPoint + fireDirection * 10000     
    local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.Bullets, filter)
    
    if Server then
        Server.dbgTracer:TraceBullet(player, startPoint, trace)  
    end
    
    if trace.fraction < 1 and trace.entity then
    
        if Server and HasMixin(trace.entity, "Live") and GetGamerules():CanEntityDoDamageTo(self, trace.entity) then
        
            // Do max damage for short time and then fall off over time to encourage close quarters combat instead of 
            // hanging back and sniping
            local damageScalar = ConditionalValue(player:GetHasUpgrade(kTechId.Piercing), kPiercingDamageScalar, 1)
            local distToTarget = (trace.endPoint - startPoint):GetLength()
            
            // Have damage increase to reward close combat
            local damageDistScalar = Clamp(1 - (distToTarget / kSpikeMinDamageRange), 0, 1)
            local damage = Spikes.kMinDamage + damageDistScalar * (Spikes.kMaxDamage - Spikes.kMinDamage)            
            local direction = (trace.endPoint - startPoint):GetUnit()
            trace.entity:TakeDamage(damage * damageScalar, player, self, self:GetOrigin(), direction)
            
        end


        // If we are far away from our target, trigger a private sound so we can hear we hit something
        if (trace.endPoint - player:GetOrigin()):GetLength() > 5 then
            
            player:TriggerEffects("hit_effect_local", {surface = trace.surface})
            
        end
            
    end
    
    // Play hit effects on ground, on target or in the air if it missed
    local impactPoint = trace.endPoint
    local surfaceName = trace.surface
    TriggerHitEffects(self, trace.entity, impactPoint, surfaceName)
    
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
    
    if Server and trace.fraction < 1 and trace.entity ~= nil and HasMixin(trace.entity, "Live") then
    
        local direction = GetNormalizedVector(endPoint - startPoint)
        
        local damageScalar = ConditionalValue(hasPiercing, kPiercingDamageScalar, 1)
        trace.entity:TakeDamage(Spikes.kSnipeDamage * damageScalar, player, self, endPoint, direction)
        
        if hasPiercing then
            trace.entity:TriggerEffects("spikes_snipe_hit")
        end
        
    else
        self:TriggerEffects("spikes_snipe_miss", {kEffectHostCoords = Coords.GetTranslation(trace.endPoint)})
    end
    
    player:SetActivityEnd(player:AdjustAttackDelay(Spikes.kSnipeDelay))
    
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
    
        //self:SetZoomState(player, not self.zoomedIn)
        
        // Fire a burst of bullets
        for index = 1, Spikes.kNumSpikesOnSecondary do
            self:FireSpike(player)        
        end
    
        player:SetActivityEnd(player:AdjustAttackDelay(Spikes.kZoomDelay))
        
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
    return kSpikesAltEnergyCost
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
