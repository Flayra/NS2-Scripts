// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AmmoPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DropPack.lua")
Script.Load("lua/PickupableMixin.lua")

class 'AmmoPack' (DropPack)

AmmoPack.kMapName = "ammopack"

AmmoPack.kModelName = PrecacheAsset("models/marine/ammopack/ammopack.model")

AmmoPack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")

AmmoPack.kNumClips = 1

function AmmoPack:OnCreate()

    DropPack.OnCreate(self)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })

end

function AmmoPack:OnInit()

    DropPack.OnInit(self)
    
    if Server then
        self:SetModel(AmmoPack.kModelName)
    end
    
end

function AmmoPack:OnTouch(recipient)

    local weapon = recipient:GetActiveWeapon()
    if weapon and weapon:GiveAmmo(AmmoPack.kNumClips) then
        recipient:PlaySound(AmmoPack.kPickupSound)
    end
    
end

function AmmoPack:GetIsValidRecipient(recipient)

    local weapon = recipient:GetActiveWeapon()
    return weapon ~= nil and weapon:isa("ClipWeapon") and weapon:GetNeedsAmmo()
    
end

Shared.LinkClassToMap("AmmoPack", AmmoPack.kMapName)