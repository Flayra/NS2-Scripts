// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MedPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/DropPack.lua")

class 'MedPack' (DropPack)

if Server then
    Script.Load("lua/MedPack_Server.lua")
end

MedPack.kMapName = "medpack"

MedPack.kModelName = PrecacheAsset("models/marine/medpack/medpack.model")
MedPack.kHealthSound = PrecacheAsset("sound/ns2.fev/marine/common/health")

MedPack.kHealth = 50

Shared.LinkClassToMap("MedPack", MedPack.kMapName)