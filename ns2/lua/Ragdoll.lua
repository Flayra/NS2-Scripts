// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\RagDoll.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'Ragdoll' (ScriptActor)

Ragdoll.kMapName = "ragdoll"

Ragdoll.kPersistTime = 10

function Ragdoll:OnInit()

    ScriptActor.OnInit(self)
    
    self:SetPhysicsType(PhysicsType.Dynamic)
    self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
    
    if(Server) then
        self:SetNextThink(20)
    end
end

function Ragdoll:InitFromEntity(entity)
    self:SetAngles(entity:GetAngles())
    self:SetOrigin(entity:GetOrigin())
    self:CopyPose(entity)
end

function Ragdoll:OnThink()
    if(Server) then
        DestroyEntity(self)
    end
end

Shared.LinkClassToMap("Ragdoll", Ragdoll.kMapName, {})