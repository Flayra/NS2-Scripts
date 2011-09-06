// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Hive:OnUpdate(deltaTime)

    CommandStructure.OnUpdate(self, deltaTime)
        
    // Attach mist effect if we don't have one already
    local coords = self:GetCoords()
    local effectName = Hive.kIdleMistEffect
    
    if self:GetTechId() == kTechId.Hive then
        effectName = Hive.kIdleMistEffect                
    elseif self:GetTechId() == kTechId.HiveMass then
        effectName = Hive.kL2IdleMistEffect
        self:RemoveEffect(Hive.kIdleMistEffect)                
    elseif self:GetTechId() == kTechId.HiveColony then
        effectName = Hive.kL3IdleMistEffect    
        self:RemoveEffect(Hive.kL2IdleMistEffect)
    end
    
    
    local isVisible = (not self:GetIsCloaked())
    
    self:AttachEffect(effectName, coords, Cinematic.Repeat_Loop)
    self:SetEffectVisible(effectName, isVisible)
    // Disable other stuff :P
    self:SetEffectVisible(Hive.kSpecksEffect, isVisible)
    self:SetEffectVisible(Hive.kGlowEffect, isVisible)
end
