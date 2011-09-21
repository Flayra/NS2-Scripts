// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CatPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DropPack.lua")
Script.Load("lua/PickupableMixin.lua")

class 'CatPack' (DropPack)
CatPack.kMapName = "catpack"

CatPack.kModelName = PrecacheAsset("models/marine/ammopack/ammopack.model")
CatPack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_ammo")

CatPack.kDuration = 6
CatPack.kWeaponDelayModifer = .7
CatPack.kMoveSpeedScalar = 1.2

function CatPack:OnCreate()

    DropPack.OnCreate(self)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })

end

function CatPack:OnInit()

    DropPack.OnInit(self)
    
    if Server then
        self:SetModel(CatPack.kModelName)
    end
    
end

function CatPack:OnTouch(player)

    player:PlaySound(CatPack.kPickupSound)
    // Buff player.
    player:ApplyCatPack()
    
end

/**
 * Any Marine is a valid recipient.
 */
function CatPack:GetIsValidRecipient(recipient)

    return true

end

Shared.LinkClassToMap("CatPack", CatPack.kMapName)