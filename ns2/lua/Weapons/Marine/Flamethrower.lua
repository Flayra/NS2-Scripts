// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Flamethrower.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/Weapons/Marine/Flame.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'Flamethrower' (ClipWeapon)

Flamethrower.kMapName                 = "flamethrower"

Flamethrower.kModelName = PrecacheAsset("models/marine/flamethrower/flamethrower.model")
Flamethrower.kViewModelName = PrecacheAsset("models/marine/flamethrower/flamethrower_view.model")

Flamethrower.kBurnBigCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_big.cinematic")
Flamethrower.kBurnHugeCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_huge.cinematic")
Flamethrower.kBurnMedCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_med.cinematic")
Flamethrower.kBurnSmallCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_small.cinematic")
Flamethrower.kBurn1PCinematic = PrecacheAsset("cinematics/marine/flamethrower/burn_1p.cinematic")
Flamethrower.kFlameCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame.cinematic")
Flamethrower.kImpactCinematic = PrecacheAsset("cinematics/marine/flamethrower/impact.cinematic")
Flamethrower.kPilotCinematic = PrecacheAsset("cinematics/marine/flamethrower/pilot.cinematic")
Flamethrower.kScorchedCinematic = PrecacheAsset("cinematics/marine/flamethrower/scorched.cinematic")

Flamethrower.kFlameFullCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_trail_full.cinematic")
Flamethrower.kFlameHalfCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_trail_half.cinematic")
Flamethrower.kFlameShortCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_trail_short.cinematic")
Flamethrower.kFlameImpactCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_impact3.cinematic")
Flamethrower.kFlameSmokeCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_trail_light.cinematic")

Flamethrower.kMuzzleNode = "fxnode_flamethrowermuzzle"

Flamethrower.kAttackDelay = kFlamethrowerFireDelay
Flamethrower.kRange = 8
Flamethrower.kDamage = kFlamethrowerDamage

Flamethrower.kParticleEffectRate = .05
Flamethrower.kSmokeEffectRate = 1.5

Flamethrower.kPilotEffectRate = 1

Flamethrower.networkVars = { 
    createParticleEffects = "boolean"
}

function Flamethrower:OnCreate()

    ClipWeapon.OnCreate(self)
    
    if Server then
        self.createParticleEffects = false
    end
    
    InitMixin(self, PickupableWeaponMixin)

end

function Flamethrower:OnInit()

    ClipWeapon.OnInit(self)
    
    if Client then
        self:AddTimedCallback(Flamethrower.UpdateClientFlameEffects, Flamethrower.kParticleEffectRate)
        self:AddTimedCallback(Flamethrower.UpdatePilotEffect, Flamethrower.kPilotEffectRate)
    end

end

function Flamethrower:GetPrimaryAttackDelay()
    return Flamethrower.kAttackDelay
end

function Flamethrower:GetWeight()
    // From NS1 
    return .1 + ((self:GetAmmo() + self:GetClip()) / self:GetClipSize()) * 0.05
end

function Flamethrower:OnHolster(player)

    ClipWeapon.OnHolster(self, player)
    
    self.createParticleEffects = false

    self:TriggerEffects("flamethrower_holster")

end

function Flamethrower:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponName)
    
    self.createParticleEffects = false
    
end

function Flamethrower:GetClipSize()
    return kFlamethrowerClipSize
end

function Flamethrower:CreatePrimaryAttackEffect(player)

    // Remember this so we can update gun_loop pose param
    self.timeOfLastPrimaryAttack = Shared.GetTime()

end

function Flamethrower:GetRange()
    return Flamethrower.kRange
end

function Flamethrower:GetWarmupTime()
    return .15
end

function Flamethrower:GetViewModelName()
    return Flamethrower.kViewModelName
end

function Flamethrower:ApplyRadiusDamage(player, startCoords, range)

    local barrelPoint = startCoords.origin
    local ents = GetEntitiesWithMixinWithinRange("Live", barrelPoint, range)
    
    local fireDirection = startCoords.zAxis
    
    for index, ent in ipairs(ents) do
    
        if ent ~= player then
        
            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - barrelPoint)
        
            if GetGamerules():CanEntityDoDamageTo(player, ent) then

                local health = ent:GetHealth()

                // Do damage to them and catch them on fire
                ent:TakeDamage(Flamethrower.kDamage, player, self, ent:GetModelOrigin(), toEnemy)
                
                // Only light on fire if we successfully damaged them
                if ent:GetHealth() ~= health then
                
                    ent:SetOnFire(player, self)

                end
                
            end
            
        end
    
    end
    
    // create flame entity, but prevent spamming:
    local nearbyFlames = GetEntitiesForTeamWithinRange("Flame", self:GetTeamNumber(), startCoords.origin, 1.5)
    
    if table.count(nearbyFlames) == 0 then
        local flame = CreateEntity(Flame.kMapName, startCoords.origin, player:GetTeamNumber())
        flame:SetOwner(player)
    end

end

function Flamethrower:ApplyConeDamage(player, startCoords, range)
    
    local barrelPoint = startCoords.origin
    local ents = GetEntitiesWithMixinWithinRange("Live", barrelPoint, range)
    
    local fireDirection = startCoords.zAxis
    
    for index, ent in ipairs(ents) do
    
        if ent ~= player then
        
            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - barrelPoint)
            local dotProduct = Math.DotProduct(fireDirection, toEnemy)
        
            // Look for enemies in cone in front of us    
            if dotProduct > .8 then
        
                if GetGamerules():CanEntityDoDamageTo(player, ent) then

                    local health = ent:GetHealth()

                    // Do damage to them and catch them on fire
                    ent:TakeDamage(Flamethrower.kDamage, player, self, ent:GetModelOrigin(), toEnemy)
                    
                    // Only light on fire if we successfully damaged them
                    if ent:GetHealth() ~= health then
                    
                        ent:SetOnFire(player, self)
                    
                        // Impact should not be played for the player that is on fire (if it is a player).
                        local entIsPlayer = ConditionalValue(ent:isa("Player"), ent, nil)

                    end
                    
                end
                
            end
            
        end
    
    end

end

function Flamethrower:ShootFlame(player)

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    
    viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * (-0.4) + viewCoords.xAxis * (-0.2)
    local endPoint = self:GetBarrelPoint(player) + viewCoords.xAxis * (-0.2) + viewCoords.yAxis * (-0.3) + viewCoords.zAxis * Flamethrower.kRange

    local trace = Shared.TraceRay(viewCoords.origin, endPoint, PhysicsMask.Bullets, EntityFilterAll())
    
    local range = (trace.endPoint - viewCoords.origin):GetLength()
    if range < 0 then
        range = range * (-1)
    end
    
    if trace.endPoint ~= endPoint and trace.entity == nil then

        local angles = Angles(0,0,0)
        angles.yaw = GetYawFromVector(trace.normal)
        angles.pitch = GetPitchFromVector(trace.normal) + (math.pi/2)
        
        local normalCoords = angles:GetCoords()
        normalCoords.origin = trace.endPoint
        range = range - 3
        
        if Server then
            self:ApplyRadiusDamage(player, normalCoords, 2.2)
        end
        
        Shared.CreateEffect(nil, Flamethrower.kFlameImpactCinematic, nil, normalCoords)
    
    end
    
    if Server then
        self:ApplyConeDamage(player, viewCoords, range)
    end
    
end

function Flamethrower:FirePrimary(player, bullets, range, penetration)    
    self:ShootFlame(player)    
end
function Flamethrower:GetDeathIconIndex()
    return kDeathMessageIcon.Flamethrower
end

function Flamethrower:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Flamethrower:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
    
        ClipWeapon.OnPrimaryAttack(self, player)
	    
	    if Server then    
	        if self:GetClip() > 0 then
	            self.createParticleEffects = true
	        end
	        
	        if self.createParticleEffects and self:GetClip() == 0 then
	            self.createParticleEffects = false
	        end
	        
	    end
    end
    
end

function Flamethrower:OnPrimaryAttackEnd(player)

    if not self:GetIsReloading() then
    
        ClipWeapon.OnPrimaryAttackEnd(self, player)
	    
	    if Server then
	        self.createParticleEffects = false
	    end
    
    end
    
end

function Flamethrower:GetSwingSensitivity()
    return .8
end

function Flamethrower:Dropped(prevOwner)

    ClipWeapon.Dropped(self, prevOwner)

    if Server then
        self.createParticleEffects = false
    end
    
end

// client side only effects:

if Client then

	function Flamethrower:UpdateClientFlameEffects(deltaTime)

	    if self.createParticleEffects then

            self:CreateParticleEffect(self:GetParent())
            self:CreateSmokeEffect(self:GetParent())
        
        end
        
        return true

    end

	function Flamethrower:CreateParticleEffect(player)
	
	    local viewAngles = player:GetViewAngles()
	    local viewCoords = viewAngles:GetCoords()
	    
	    local yOffset = -0.1
	    local zOffset = 0.7
	    
	    if Client.GetLocalPlayer() == player then
	        yOffset = 0.2
	        zOffset = 1
	    end
	    
	    viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * zOffset + viewCoords.xAxis * (-0.4) + viewCoords.yAxis * yOffset
	    local endPoint = self:GetBarrelPoint(player) + viewCoords.xAxis * (-0.2) + viewCoords.yAxis * (-0.3) + viewCoords.zAxis * Flamethrower.kRange
	
	    local trace = Shared.TraceRay(self:GetBarrelPoint(player) + viewCoords.zAxis * (-.4), endPoint, PhysicsMask.Bullets, EntityFilterAll())
	    
	    local cinematic = nil
	    
	    if trace.fraction >= 0.9 then
	        cinematic = Flamethrower.kFlameFullCinematic
	    elseif trace.fraction >= 0.5 then
	        cinematic = Flamethrower.kFlameHalfCinematic
	    else
	        cinematic = Flamethrower.kFlameShortCinematic
	    end  
	
	    if cinematic ~= nil then
	    
	        local effect = Client.CreateCinematic(RenderScene.Zone_Default)    
	        effect:SetCinematic(cinematic)
	        effect:SetCoords(viewCoords)
	        
	    end
	
	end
	
	function Flamethrower:CreateSmokeEffect(player)
	
	    if not self.timeLastLightningEffect or self.timeLastLightningEffect + Flamethrower.kSmokeEffectRate < Shared.GetTime() then
	    
	        self.timeLastLightningEffect = Shared.GetTime()
	
	        local viewAngles = player:GetViewAngles()
	        local viewCoords = viewAngles:GetCoords()
	        
	        viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * 1 + viewCoords.xAxis * (-0.4) + viewCoords.yAxis * (-0.3)
	        
	        local cinematic = Flamethrower.kFlameSmokeCinematic
	
	        local effect = Client.CreateCinematic(RenderScene.Zone_Default)    
	        effect:SetCinematic(cinematic)
	        effect:SetCoords(viewCoords)
	
	    end
	
	end
	
	function Flamethrower:TriggerImpactCinematic(coords)
	
	    local cinematic = Flamethrower.kFlameImpactCinematic
	
	    local effect = Client.CreateCinematic(RenderScene.Zone_Default)    
	    effect:SetCinematic(cinematic)    
	    effect:SetCoords(coords)
	
	end
	
	function Flamethrower:UpdatePilotEffect(deltaTime)
	
	   if self:GetIsActive() and self:GetClip() > 0 then
            self:TriggerEffects("flamethrower_pilot")
       end
       
       return true
	
	end

end

Shared.LinkClassToMap("Flamethrower", Flamethrower.kMapName, Flamethrower.networkVars)