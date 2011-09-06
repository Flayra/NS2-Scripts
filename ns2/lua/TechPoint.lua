// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechPoint.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'TechPoint' (ScriptActor)

TechPoint.kMapName = "tech_point"

// Note that these need to be changed in editor_setup.xml as well
TechPoint.kModelName = PrecacheAsset("models/misc/tech_point/tech_point.model")

TechPoint.kTechPointL1Effect = PrecacheAsset("cinematics/common/techpoint.cinematic")
TechPoint.kTechPointL1LightEffect = PrecacheAsset("cinematics/common/techpoint_light.cinematic")

TechPoint.kTechPointL2Effect = PrecacheAsset("cinematics/common/techpoint_lev2.cinematic")
TechPoint.kTechPointL2LightEffect = PrecacheAsset("cinematics/common/techpoint_light_lev2.cinematic")

TechPoint.kTechPointL3Effect = PrecacheAsset("cinematics/common/techpoint_lev3.cinematic")
TechPoint.kTechPointL3LightEffect = PrecacheAsset("cinematics/common/techpoint_light_lev3.cinematic")

// Tech point animations
TechPoint.kAlienAnim = "hive_deploy_tech"
TechPoint.kMarineAnim = "spawn"

if Server then
    Script.Load("lua/TechPoint_Server.lua")
end

local networkVars = 
{
    // Used to indicate what level the structure on top is (ie, a level 1/2/3 Command Station or Hive)
    techLevel = "integer (1 to 3)"
}

function TechPoint:OnInit()

    ScriptActor.OnInit(self)
    
    self:SetModel(TechPoint.kModelName)
    
    // Anything that can be built upon should have this group
    self:SetPhysicsGroup(PhysicsGroup.AttachClassGroup)
    
    // Make the nozzle kinematic so that the player will collide with it.
    self:SetPhysicsType(PhysicsType.Kinematic)
    
    self:SetTechId(kTechId.TechPoint)
    
    if Server then
    
        self.techLevel = 1
        
    end
    
    if Client then
        self:SetUpdates(true)
    end
    
end

if Client then

function TechPoint:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    if (self.visibleTechLevel ~= self.techLevel) and (self.techLevel ~= nil) then

        self:DestroyAttachedEffects()
        
        local coords = self:GetCoords()    
        
        if self.techLevel == 1 then
        
            self:AttachEffect(TechPoint.kTechPointL1Effect, coords)
            self:AttachEffect(TechPoint.kTechPointL1LightEffect, coords, Cinematic.Repeat_Loop)
            
        elseif self.techLevel == 2 then
        
            self:AttachEffect(TechPoint.kTechPointL2Effect, coords)
            self:AttachEffect(TechPoint.kTechPointL2LightEffect, coords, Cinematic.Repeat_Loop)
            
        elseif self.techLevel == 3 then
        
            self:AttachEffect(TechPoint.kTechPointL3Effect, coords)
            self:AttachEffect(TechPoint.kTechPointL3LightEffect, coords, Cinematic.Repeat_Loop)
            
        end
        
        self.visibleTechLevel = self.techLevel
        
    end
    
end

end

Shared.LinkClassToMap("TechPoint", TechPoint.kMapName, networkVars)
