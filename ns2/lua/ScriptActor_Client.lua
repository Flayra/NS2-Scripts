// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScriptActor_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Base class for all visible entities that aren't players. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function ScriptActor:OnSynchronized()

    PROFILE("ScriptActor:OnSynchronized")

    // Make sure to call OnInit() for client entities that have been propagated by the server
    if(not self.clientInitedOnSynch) then
    
        self:OnInit()
        
        self.clientInitedOnSynch = true
        
    end
    
    BlendedActor.OnSynchronized(self)
    
end

function ScriptActor:OnDestroy()

    // Only call OnDestroyClient() for entities that are on the Client
    // Note: It isn't possible to check if this entity is the local player
    // at this point because there are cases where the local player entity
    // has changed before OnDestroy() is called
    if(Client) then
        self:OnDestroyClient()
    end
    
    self:DestroyAttachedEffects()

    BlendedActor.OnDestroy(self)
    
end

// Called on the Client only, after children OnDestroy() functions.
function ScriptActor:OnDestroyClient()
end

function ScriptActor:DestroyAttachedEffects()

    if self.attachedEffects ~= nil then
    
        for index, attachedEffect in ipairs(self.attachedEffects) do
        
            Client.DestroyCinematic(attachedEffect[1])
            
        end
        
        self.attachedEffects = nil
        
    end
    
end

function ScriptActor:RemoveEffect(effectName)
    
    if self.attachedEffects then
    
        for index, attachedEffect in ipairs(self.attachedEffects) do
        
            if attachedEffect[2] == effectName then
            
                Client.DestroyCinematic(attachedEffect[1])
                
                local success = table.removevalue(self.attachedEffects, attachedEffect)
                
                return true
                
            end
            
        end
        
    end
    
    return false

end

function ScriptActor:SetEffectVisible(effectName, visible)
    if self.attachedEffects ~= nil then
    
        for index, attachedEffect in ipairs(self.attachedEffects) do
            
            if attachedEffect[2] == effectName then               
                attachedEffect[1]:SetIsVisible(visible)                                                
                return true
                
            end
            
        end
        
    end
    
    return false
end

function ScriptActor:HideAllEffects()
   if self.attachedEffects ~= nil then    
        for index, attachedEffect in ipairs(self.attachedEffects) do
            attachedEffect[1]:SetIsVisible(false)                                                
        end        
    end
end

function ScriptActor:ShowAllEffects()
    if self.attachedEffects ~= nil then    
        for index, attachedEffect in ipairs(self.attachedEffects) do
            attachedEffect[1]:SetIsVisible(true)
        end        
    end
end

// Uses loopmode endless by default
function ScriptActor:AttachEffect(effectName, coords, loopMode)

    if self.attachedEffects == nil then
        self.attachedEffects = {}
    end

    // Don't create it if already created    
    for index, attachedEffect in ipairs(self.attachedEffects) do
        if attachedEffect[2] == effectName then
            return false
        end
    end

    local cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
    
    cinematic:SetCinematic( effectName )
    cinematic:SetCoords( coords )
    
    if loopMode == nil then
        loopMode = Cinematic.Repeat_Endless
    end
    
    cinematic:SetRepeatStyle(loopMode)

    table.insert(self.attachedEffects, {cinematic, effectName})
    
    return true
    
end

function ScriptActor:AddClientEffect(effectName)

    self:SetUpdates(true)
    
    if not self.clientEffects then
        self.clientEffects = {}
    end
    
    // Create trailing spit that is attached to projectile
    local clientEffect = Client.CreateCinematic(RenderScene.Zone_Default)
    clientEffect:SetCinematic(effectName)
    clientEffect:SetRepeatStyle(Cinematic.Repeat_Endless)  
    
    table.insert(self.clientEffects, clientEffect)
    
end

function ScriptActor:UpdateAttachedEffects()

    if self.attachedEffects then

        for index, effectPair in ipairs(self.attachedEffects) do
    
            local coords = self:GetAngles():GetCoords()
            coords.origin = self:GetOrigin()
            effectPair[1]:SetCoords(coords)
            
        end
        
    end
    
end

function ScriptActor:OnUpdate(deltaTime)

    PROFILE("ScriptActor_Client:OnUpdate")

    BlendedActor.OnUpdate(self, deltaTime)
    
    self:UpdateAttachedEffects()
    
end

function ScriptActor:GetIsVisible()

    local visible = Actor.GetIsVisible(self)
    local localPlayer = Client.GetLocalPlayer()
    
    if self.OnGetIsVisible and localPlayer ~= nil then    
        
        local visibleTable = {Visible = visible}    
        self:OnGetIsVisible(visibleTable, localPlayer:GetTeamNumber())
        return visibleTable.Visible
        
    end
    
    return visible
            
end


