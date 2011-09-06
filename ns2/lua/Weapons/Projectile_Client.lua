// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Projectile_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
 
function Projectile:OnUpdateRender()

    PROFILE("Projectile:OnUpdateRender")

    ScriptActor.OnUpdateRender(self)
    self:UpdateRenderModel()
    
end

/** 
 * Creates the rendering representation of the model if it doesn't match
 * the currently set model index and update's it state to match the actor.
 */
function Projectile:UpdateRenderModel()

    if (self.oldModelIndex ~= self.modelIndex) then

        // Create/destroy the model as necessary.
        if (self.modelIndex == 0) then
            Client.DestroyRenderModel(self.renderModel)
            self.renderModel = nil
        else
            self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
            self.renderModel:SetModel(self.modelIndex)
        end
    
        // Save off the model index so we can detect when it changes.
        self.oldModelIndex = self.modelIndex
        
    end
    
    if (self.renderModel ~= nil) then
        self.renderModel:SetCoords( self:GetCoords() )
    end

end

