// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Flamethrower.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Weapon.lua")

class 'Flamethrower' (ClipWeapon)

if Client then
    Script.Load("lua/Weapons/Marine/Flamethrower_Client.lua")
end

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

Flamethrower.kAttackDelay = kFlamethrowerFireDelay
Flamethrower.kRange = 8
Flamethrower.kDamage = kFlamethrowerDamage

local networkVars = { }

function Flamethrower:OnInit()

    ClipWeapon.OnInit(self)

    if Client then
        self.pilotLightState = false
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

    self:SetPilotLightState(false)

end

function Flamethrower:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponName)
    
    self:SetPilotLightState(true)
    
end

function Flamethrower:GetClipSize()
    return kFlamethrowerClipSize
end

function Flamethrower:GetIsDroppable()
    return true
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

function Flamethrower:FirePrimary(player)

    if Server then
    
    local barrelPoint = self:GetBarrelPoint(player)
    local ents = GetEntitiesWithMixinWithinRange("Live", barrelPoint, self:GetRange())
    
    local fireDirection = player:GetViewAngles():GetCoords().zAxis
    
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
                        // Play on fire cinematic
                        Shared.CreateEffect(entIsPlayer, Flamethrower.kImpactCinematic, ent, Coords.GetIdentity())

                    end
                    
                end
                
            end
            
        end
        
    end    
    
    end
    
end

function Flamethrower:GetDeathIconIndex()
    return kDeathMessageIcon.Flamethrower
end

function Flamethrower:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Flamethrower:OnPrimaryAttack(player)

    ClipWeapon.OnPrimaryAttack(self, player)
    
    self:SetPilotLightState(false)
    
end

function Flamethrower:OnPrimaryAttackEnd(player)

    ClipWeapon.OnPrimaryAttackEnd(self, player)

    self:SetPilotLightState(true)
    
end

function Flamethrower:GetSwingSensitivity()
    return .8
end

if Server then
function Flamethrower:SetPilotLightState(state)
end
end

function Flamethrower:Dropped(prevOwner)

    ClipWeapon.Dropped(self, prevOwner)
    self:SetPilotLightState(false)
    
end

Shared.LinkClassToMap("Flamethrower", Flamethrower.kMapName, networkVars)