// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AmmoPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/DropPack.lua")
class 'AmmoPack' (DropPack)
AmmoPack.kMapName = "ammopack"

AmmoPack.kModelName = PrecacheAsset("models/marine/ammopack/ammopack.model")

AmmoPack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")

AmmoPack.kNumBullets = 100

AmmoPack.kNumClips = 1

function AmmoPack:OnInit()

    if(Server) then
    
        self:SetModel(AmmoPack.kModelName)
        
        self:SetNextThink(DropPack.kThinkInterval)
        
        self.timeSpawned = Shared.GetTime()
        
    end
    
    Shared.CreateEffect(nil, DropPack.kPackDropEffect, self)    
end

function AmmoPack:OnTouch(player)

    if( player:GetTeamNumber() == self:GetTeamNumber() ) then
    
        local weapon = player:GetActiveWeapon()
        
        if(weapon ~= nil and weapon:isa("ClipWeapon") and weapon:GetNeedsAmmo() ) then
        
            if(weapon:GiveAmmo(AmmoPack.kNumClips)) then

                player:PlaySound(AmmoPack.kPickupSound)
                
                DestroyEntity(self)
                
            end
            
        end        
        
    end
    
end

function AmmoPack:GetPackRecipient()

    local potentialRecipients = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 1)
    
    for index, player in pairs(potentialRecipients) do
    
        local weapon = player:GetActiveWeapon()
        
        if(weapon ~= nil and weapon:isa("ClipWeapon") and weapon:GetNeedsAmmo() ) then
        
            return player
            
        end
    
    end

    return nil
    
end

if(Server) then
function AmmoPack:OnThink()

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
end

Shared.LinkClassToMap("AmmoPack", AmmoPack.kMapName)