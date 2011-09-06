// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MedPack_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function MedPack:OnInit()

    self:SetModel(MedPack.kModelName)
       
    self:SetNextThink(DropPack.kThinkInterval)
    
    self.timeSpawned = Shared.GetTime()
    
    Shared.CreateEffect(nil, DropPack.kPackDropEffect, self)
end

function MedPack:OnTouch(player)

    if( player:GetTeamNumber() == self:GetTeamNumber() ) then
    
        // If player has less than full health or is parasited
        if( (player:GetHealth() < player:GetMaxHealth()) or (player:GetArmor() < player:GetMaxArmor()) or player:GetGameEffectMask(kGameEffect.Parasite) ) then

            player:AddHealth(MedPack.kHealth, false, true)
            
            player:SetGameEffectMask(kGameEffect.Parasite, false)
            
            player:PlaySound(MedPack.kHealthSound)
            
            DestroyEntity(self)
            
        end
        
    end
    
end

function MedPack:GetPackRecipient()

    local potentialRecipients = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 1)
    
    for index, player in pairs(potentialRecipients) do
    
        if(player:GetHealth() < player:GetMaxHealth()) then
        
            return player
            
        end
    
    end

    return nil
    
end

function MedPack:OnThink()

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