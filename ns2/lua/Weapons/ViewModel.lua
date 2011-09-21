//=============================================================================
//
// lua/Weapons/ViewModel.lua
//
// Created by Max McGuire (max@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

/**
 * ViewModel is the class which handles rendering and animating the view model
 * (i.e. weapon model) for a player. To use this class, create a 'view_model'
 * entity and set its parent to the player that it will belong to. There should
 * be one view model entity per player (the same view model entity is used for
 * all of the weapons).
 */
Script.Load("lua/Globals.lua")
Script.Load("lua/FunctionContracts.lua")

class 'ViewModel' (BlendedActor)

ViewModel.mapName = "view_model"

ViewModel.networkVars =
{
    weaponId = "entityid"
}

function ViewModel:OnCreate()
    
    self.weaponId = Entity.invalidId

    BlendedActor.OnCreate(self)
    
    // Use a custom propagation callback to only propagate to the owning player.
    self:SetPropagate(Entity.Propagate_Callback)
    
    self:SetUpdates(true)
    
    self:ResetAnimState()

end

if Client then

function ViewModel:OnSynchronized()

    PROFILE("ViewModel:OnSynchronized")

    // Make sure to call OnInit() for client ViewModels that have been propagated by the server
    if(not self.clientInitedOnSynch) then
    
        self:OnInit()
        
        self.clientInitedOnSynch = true
        
    end
    
    BlendedActor.OnSynchronized(self)
    
end

end

function ViewModel:GetModelIndex()
    return self.modelIndex
end

function ViewModel:SetWeapon(weapon)

    if weapon ~= nil then
        self.weaponId = weapon:GetId()
    else
        self.weaponId = Entity.invalidId
    end
    
end
AddFunctionContract(ViewModel.SetWeapon, { Arguments = { "ViewModel", { "Weapon", "nil" } }, Returns = { } })

/**
 * Assigns the model for the view model. modelName is a string specifying the
 * file name of the model, which should have been precached by calling
 * Shared.PrecacheModel during load time.
 */
function ViewModel:SetModel(modelName)

    if BlendedActor.SetModel(self, modelName) then
        self:ResetAnimState()
    end
    
    if Client then
        self:UpdateRenderModel()
    end
    
end

function ViewModel:GetCanIdle()
    local parent = self:GetParent()
    if parent and parent.GetCanViewModelIdle then
        return parent:GetCanViewModelIdle()
    else
        return BlendedActor.GetCanIdle(self)
    end
end

function ViewModel:GetOverlayAnimation()

    local overlayAnimName = ""
    
    if(self.overlayAnimationSequence ~= Model.invalidSequence) then
        overlayAnimName = self:GetAnimation(self.overlayAnimationSequence)
    end
    
    return overlayAnimName

end

function ViewModel:OnGetIsRelevant(player)
    
    // Only propagate the view model if it belongs to the player (since they're
    // the only one that can see it)
    return self:GetParent() == player
    
end

function ViewModel:GetBlendTime()
    return .15
end

function ViewModel:GetCameraCoords()

    local model = Shared.GetModel(self.modelIndex)
    
    if model ~= nil then
           
        // If the view model has a camera embedded in it, use that as
        // the camera for rendering the view model.
        if (model:GetNumCameras() > 0) then
            local camera = model:GetCamera(0, self.boneCoords)
            return true, camera:GetCoords()
        end
        
    end

    return false, nil
    
end

/**
 * Overriden from Actor.
 */
function ViewModel:GetAttachPointCoords(attachPoint)

    PROFILE("ViewModel:GetAttachPointCoords")

    local attachPointIndex = attachPoint
    if type(attachPointIndex) == "string" then
        attachPointIndex = self:GetAttachPointIndex(attachPoint)
    end

    if attachPointIndex ~= -1 then
    
        local model = Shared.GetModel(self.modelIndex)
    
        if model ~= nil then
        
            local coords = self:GetCoords()
            
            if model:GetAttachPointExists(attachPointIndex) and model:GetAttachPointBoneExists(attachPointIndex, self.boneCoords) then
                coords = coords * model:GetAttachPointCoords(attachPointIndex, self.boneCoords)
            end
            
            return coords
            
        end

    end
    
    Print("%s:GetAttachPointCoords(%s): Returning identity coords for ViewModel.", self:GetClassName(), ToString(attachPoint))
    
    return Coords.GetIdentity()
    
end

// Pass along to weapon so melee attacks can be triggered at exact time of impact.
function ViewModel:OnTag(tagHit)

    BlendedActor.OnTag(self, tagHit)
    
    local weapon = self:GetWeapon()
    if weapon ~= nil then
        weapon:OnTag(tagHit)
    end

end

if (Client) then

    function ViewModel:OnUpdateRender()

        PROFILE("ViewModel:OnUpdateRender")
        
        BlendedActor.OnUpdateRender(self)

        local model = Shared.GetModel(self.modelIndex)
        if (model ~= nil and self.model ~= nil) then
               
            // Update the bones based on the currently playing animation.
            self.model:SetBoneCoords( self.boneCoords )
            
            // If the view model has a camera embedded in it, use that as
            // the camera for rendering the view model.
            if (model:GetNumCameras() > 0) then

                local camera = model:GetCamera(0, self.boneCoords)

                self.model:SetCoords( camera:GetCoords():GetInverse() )
                
                if self:GetParent() == Client.GetLocalPlayer() then
                    Client.SetZoneFov(RenderScene.Zone_ViewModel, camera:GetFov())
                end
                
            else
            
                self.model:SetCoords( Coords.GetIdentity() )
                if self:GetParent() == Client.GetLocalPlayer() then
                    Client.SetZoneFov(RenderScene.Zone_ViewModel, math.rad(65))
                end
                
            end
            
        end
        
    end

    /** 
     * Creates the rendering representation of the model if it doesn't match
     * the currently set model index and update's it state to match the actor.
     */
    function ViewModel:UpdateRenderModel()
    
        if self.modelIndex ~= self.oldModelIndex then
    
            // Create/destroy the model as necessary.
            if self.modelIndex == 0 then
                Client.DestroyRenderModel(self.model)
                self.model = nil
            else
                if self.model == nil then
                    self.model = Client.CreateRenderModel(RenderScene.Zone_ViewModel)
                end
                self.model:SetModel(self.modelIndex)
            end
        
            // Save off the model index so we can detect when it changes.
            self.oldModelIndex = self.modelIndex
            
        end
        
        if self.model ~= nil then
            // Show or hide the view model depending on whether or not the
            // entity is visible. This allows the owner to show or hide it
            // as needed.
            self.model:SetIsVisible(self:GetIsVisible())
        end
        
    end
    
    /**
     * Updates the GUI elements in the view model.
     */
    function ViewModel:UpdateGUI()

        if self.model ~= nil then
            self.model:SetMaterialParameter("weaponAmmo", PlayerUI_GetWeaponAmmo())
            self.model:SetMaterialParameter("weaponClip", PlayerUI_GetWeaponClip())
            self.model:SetMaterialParameter("weaponAuxClip", PlayerUI_GetAuxWeaponClip())
        end
    
    end
        
end

function ViewModel:GetEffectParams(tableParams)
    
    BlendedActor.GetEffectParams(self, tableParams)
    
    tableParams[kEffectFilterClassName] = self:GetClassName()
    
    // Override classname with class of weapon we represent
    local weapon = self:GetWeapon()
    if weapon ~= nil then
        tableParams[kEffectFilterClassName] = weapon:GetClassName()
        weapon:GetEffectParams(tableParams)
    end
    
end

function ViewModel:GetWeapon()
    return Shared.GetEntity(self.weaponId)
end

Shared.LinkClassToMap( "ViewModel", ViewModel.mapName, ViewModel.networkVars )  