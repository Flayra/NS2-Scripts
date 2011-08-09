// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CatPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/DropPack.lua")

class 'CatPack' (DropPack)
CatPack.kMapName = "catpack"

CatPack.kModelName = PrecacheAsset("models/marine/ammopack/ammopack.model")

CatPack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")

CatPack.kDuration = 6
CatPack.kWeaponDelayModifer = .7
CatPack.kMoveSpeedScalar = 1.2

function CatPack:OnInit()

    if(Server) then
    
        self:SetModel(CatPack.kModelName)
        
        self:SetNextThink(DropPack.kThinkInterval)
        
        self.timeSpawned = Shared.GetTime()
        
    end
    
    Shared.CreateEffect(nil, DropPack.kPackDropEffect, self)
    
end

function CatPack:OnTouch(player)

    if( player:GetTeamNumber() == self:GetTeamNumber() ) then
    
        player:PlaySound(CatPack.kPickupSound)
        
        // Buff player
        player:ApplyCatPack()
        
        DestroyEntity(self)
        
    end
    
end

function CatPack:GetPackRecipient()

    local potentialRecipients = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 1)
    
    for index, player in pairs(potentialRecipients) do
    
        return player
    
    end

    return nil
    
end

function CatPack:OnThink()

    DropPack.OnThink(self)
    
    // Scan for nearby friendly players that need medpacks because we don't have collision detection yet
    local player = self:GetPackRecipient()

    if(player ~= nil) then
    
        self:OnTouch(player)
        
    end

    if( Shared.GetTime() > (self.timeSpawned + DropPack.kLifetime) ) then
    
        // Go away after a time
        DestroyEntity(self)

    else
    
        self:SetNextThink(DropPack.kThinkInterval)
        
    end
    
end

Shared.LinkClassToMap("CatPack", CatPack.kMapName)