// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PhantomEffigy.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Additive entity that is created by Alien Commander via the Shade. Looks like an alien life 
// form, which can be +used by friendly players to morph into a PhantomMixin version of that
// lifeform. Invisible to enemies, dissipates if unused after a couple minutes.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'PhantomEffigy' (ScriptActor)

PhantomEffigy.kMapName = "phantom"
PhantomEffigy.kLifetime = kPhantomEffigyLifetime

PhantomEffigy.kNetworkVars = {}

function PhantomEffigy:OnInit()

    ScriptActor.OnInit(self)
    
    self.createTime = Shared.GetTime()
       
end

if Server then
function PhantomEffigy:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if Shared.GetTime() > (self.createTime + PhantomEffigy.kLifetime) then
    
        self:TriggerEffects("phantom_effigy_expire")
        
        DestroyEntity(self)
        
    end
    
end
end

function PhantomEffigy:GetCanBeUsed(player)
    // Make sure effigy hasn't been destroyed this frame already. Phantoms can't use effigies of course.
    return player and (player:GetTeamNumber() == self:GetTeamNumber()) and (self:GetId() ~= Entity.invalidId) and (not HasMixin(player, "Phantom") or not player:GetIsPhantom())
end

function PhantomEffigy:GetEffigyMorphToMapName()
    if self:GetTechId() == kTechId.ShadePhantomOnos then
        return Onos.kMapName
    end
    return Fade.kMapName
end

function PhantomEffigy:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    if Server then
    
        StartPhantomMode(player, self:GetEffigyMorphToMapName(), self:GetOrigin())
        
        DestroyEntity(self)
    
        // TODO: Animate their camera towards viewpoint
    
    end
    
end

Shared.LinkClassToMap("PhantomEffigy", PhantomEffigy.kMapName, PhantomEffigy.kNetworkVars)
