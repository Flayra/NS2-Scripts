// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\OnosPhantasm.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Phantasm.lua")
Script.Load("lua/Onos.lua")

class 'OnosPhantasm' (Phantasm)

OnosPhantasm.kMapName = "onosphantasm"

function OnosPhantasm:GetExtents()
    return LookupTechData(kTechId.Onos, kTechDataMaxExtents)
end

function OnosPhantasm:GetOrderedSoundName()
    return Onos.kGoreSound
end

function OnosPhantasm:GetMoveAnimation()
    return "run"
end

function Onos:GetMaxMoveSpeed()
    return Onos.kMaxSpeed
end

function OnosPhantasm:GetAttackSoundName()
    return Onos.kGoreSound
end

function OnosPhantasm:GetMoveSpeed()
    return GetDevScalar(Onos.kMaxSpeed, 8)
end

Shared.LinkClassToMap("OnosPhantasm", OnosPhantasm.kMapName, {})
