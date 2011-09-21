// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MedPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DropPack.lua")
Script.Load("lua/PickupableMixin.lua")

class 'MedPack' (DropPack)

MedPack.kMapName = "medpack"

MedPack.kModelName = PrecacheAsset("models/marine/medpack/medpack.model")
MedPack.kHealthSound = PrecacheAsset("sound/ns2.fev/marine/common/health")

MedPack.kHealth = 50

function MedPack:OnCreate()

    DropPack.OnCreate(self)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })

end

function MedPack:OnInit()

    DropPack.OnInit(self)
    
    if Server then
        self:SetModel(MedPack.kModelName)
    end
    
end

function MedPack:OnTouch(recipient)

    recipient:AddHealth(MedPack.kHealth, false, true)
    recipient:SetGameEffectMask(kGameEffect.Parasite, false)
    recipient:PlaySound(MedPack.kHealthSound)
    
end

function MedPack:GetIsValidRecipient(recipient)

    return recipient:GetHealth() < recipient:GetMaxHealth() or
           recipient:GetGameEffectMask(kGameEffect.Parasite)
    
end

Shared.LinkClassToMap("MedPack", MedPack.kMapName)