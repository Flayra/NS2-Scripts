// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MiniCyst.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A small version of the cyst created by the Gorge.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'MiniCyst' (Cyst)

MiniCyst.kModelName = PrecacheAsset("models/alien/small_pustule/small_pustule.model")
MiniCyst.kOffModelName = PrecacheAsset("models/alien/small_pustule/small_pustule_off.model")

MiniCyst.kMapName = "minicyst"

MiniCyst.kImpulseLightRadius = 1

MiniCyst.kMiniCystParentRange = kMiniCystParentRange

// the minicyst have same same infestation radius as the normal cyst
MiniCyst.kInfestationRadius = kInfestationRadius


MiniCyst.kExtents = Vector(0.1, 0.05, 0.1)

function MiniCyst:GetInfestationRadius()
    return MiniCyst.kInfestationRadius
end

function MiniCyst:GetCystParentRange()
    return MiniCyst.kMiniCystParentRange
end

function MiniCyst:GetCystModelName(connected)
    return ConditionalValue(connected, MiniCyst.kModelName, MiniCyst.kOffModelName)
end


Shared.LinkClassToMap("MiniCyst", MiniCyst.kMapName, {})