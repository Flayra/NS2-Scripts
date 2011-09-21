// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DropPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'DropPack' (ScriptActor)
DropPack.kMapName = "droppack"

DropPack.kPackDropEffect = PrecacheAsset("cinematics/marine/spawn_item.cinematic")

function DropPack:OnCreate()

    ScriptActor.OnCreate(self)
    
    self:SetPhysicsType(PhysicsType.DynamicServer)
    self:SetPhysicsGroup(PhysicsGroup.ProjectileGroup)
    
    self:UpdatePhysicsModel()
    
end

function DropPack:OnInit()

    ScriptActor.OnInit(self)

    Shared.CreateEffect(nil, DropPack.kPackDropEffect, self)

end

Shared.LinkClassToMap("DropPack", DropPack.kMapName)