// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\BileBomb.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Bomb.lua")

class 'BileBomb' (Ability)

BileBomb.kMapName = "bilebomb"
BileBomb.kBombSpeed = 15

function BileBomb:GetEnergyCost(player)
    return kBileBombEnergyCost
end

function BileBomb:GetIconOffsetY(secondary)
    return kAbilityOffset.BileBomb
end

function BileBomb:GetPrimaryAttackDelay()
    return kBileBombFireDelay
end

function BileBomb:GetDeathIconIndex()
    return kDeathMessageIcon.BileBomb
end

function BileBomb:GetHUDSlot()
    return 3
end

function BileBomb:PerformPrimaryAttack(player)

    self:FireBombProjectile(player)        
        
    player:SetActivityEnd(player:AdjustAttackDelay(self:GetPrimaryAttackDelay()))
    
    return true
end

function BileBomb:FireBombProjectile(player)

    if Server then
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 1
        
        local bomb = CreateEntity(Bomb.kMapName, startPoint, player:GetTeamNumber())
        SetAnglesFromVector(bomb, viewCoords.zAxis)
        
        bomb:SetPhysicsType(PhysicsType.Kinematic)
        
        local startVelocity = viewCoords.zAxis * BileBomb.kBombSpeed
        bomb:SetVelocity(startVelocity)
        
        bomb:SetGravityEnabled(true)
        
        // Set bombowner to player so we don't collide with ourselves and so we
        // can attribute a kill to us
        bomb:SetOwner(player)
        
    end

end

Shared.LinkClassToMap("BileBomb", BileBomb.kMapName, {} )
