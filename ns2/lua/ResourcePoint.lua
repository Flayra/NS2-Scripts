// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourceNozzle.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'ResourcePoint' (ScriptActor)

ResourcePoint.kPointMapName = "resource_point"

ResourcePoint.kEffect = PrecacheAsset("cinematics/common/resnode.cinematic")

ResourcePoint.kModelName = PrecacheAsset("models/misc/resource_nozzle/resource_nozzle.model")

local networkVars = {
    playingEffect = "boolean"
}
    
if Server then
    Script.Load("lua/ResourcePoint_Server.lua")
end

function ResourcePoint:OnInit()

    ScriptActor.OnInit(self)
    
    self:SetModel(ResourcePoint.kModelName)
    
    // Anything that can be built upon should have this group
    self:SetPhysicsGroup(PhysicsGroup.AttachClassGroup)
    
    // Make the nozzle kinematic so that the player will collide with it.
    self:SetPhysicsType(PhysicsType.Kinematic)
    
    self:SetTechId(kTechId.ResourcePoint)
    
    self.playingEffect = false

end

function ResourcePoint:Reset()
    
    self:OnInit()
    
    self:ClearAttached()
    
end

if Client then

    function ResourcePoint:OnUpdate(deltaTime)
    
        ScriptActor.OnUpdate(self, deltaTime)
        
        if not self.playingEffect and self.attachedEffects ~= nil then
            self:DestroyAttachedEffects()
        elseif self.playingEffect and self.attachedEffects == nil then
            self:AttachEffect(ResourcePoint.kEffect, self:GetCoords())
        end
        
    end
    
end

Shared.LinkClassToMap("ResourcePoint", ResourcePoint.kPointMapName, networkVars)
