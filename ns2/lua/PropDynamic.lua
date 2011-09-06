// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PropDynamic.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'PropDynamic' (ScriptActor)

if (Server) then

    function PropDynamic:OnInit()

        ScriptActor.OnInit(self)
        
        self.modelName = self.model
        self.animationName = self.animation
        self.propScale = self.scale
        
        Shared.PrecacheModel(self.modelName)    
    
        if (self.modelName ~= nil) then
            self:SetModel(self.modelName)
        end
        
        if (self.animationName ~= nil) then
            self:SetAnimation(self.animationName)
        end
        
        if self.dynamic and self.animationName ~= "" and self.animationName ~= nil then
            self:SetPhysicsType(PhysicsType.DynamicServer)
            self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
        else
            self:SetPhysicsType(PhysicsType.Kinematic)
        end
        
        // Don't collide when commanding if not full alpha
        self.commAlpha = GetAndCheckValue(self.commAlpha, 0, 1, "commAlpha", 1, true)
        
        // Make it not block selection and structure placement (GetCommanderPickTarget)
        if self.commAlpha < 1 then
            self:SetPhysicsGroup(PhysicsGroup.CommanderPropsGroup)
        end
      
        self:SetUpdates(true)
      
        self:SetIsVisible(true)
    
        self:SetPropagate(Entity.Propagate_Mask)
        self:UpdateRelevancyMask()

    end
    
    function PropDynamic:UpdateRelevancyMask()
    
        local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        if self.commAlpha == 1 then
            mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
        end
        
        self:SetExcludeRelevancyMask( mask )
        self:SetRelevancyDistance( kMaxRelevancyDistance )
        
    end
    
end

Shared.LinkClassToMap( "PropDynamic", "prop_dynamic", {} )