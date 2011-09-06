// To integrate the mixin, you should add the following calls in your class:
//
// Inside OnUpdateRender:
//   self:UpdateBoneCoords()
//   self:UpdateRenderModel()

ModelMixin = { }
ModelMixin.type = "Model"

// Maximum number of animations we support on in a model. This is limited for
// the sake of reducing the size of the network field.
ModelMixin.maxAnimations = 72
ModelMixin.maxGraphNodes = 511

function ModelMixin.__prepareclass(toClass)

    ASSERT(toClass.networkVars ~= nil, "ModelMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
    
        modelIndex          = "resource",
        animationGraphIndex = "compensated resource",
        
        // Base Layer:
        // ------------------------------
        animationGraphNode  = "compensated integer (-1 to " .. ModelMixin.maxGraphNodes .. ")",
        // Primary animation.
        animationSequence   = "compensated integer (-1 to " .. ModelMixin.maxAnimations .. ")",
        animationStart      = "compensated float",
        animationBlend      = "compensated float",
        // Blended animation.
        animationSequence2  = "compensated integer (-1 to " .. ModelMixin.maxAnimations .. ")",
        animationStart2     = "compensated float",
        
        // Layer 1:
        // ------------------------------
        layer1AnimationGraphNode  = "compensated integer (-1 to " .. ModelMixin.maxGraphNodes .. ")",
        // Primary animation.
        layer1AnimationSequence   = "compensated integer (-1 to " .. ModelMixin.maxAnimations .. ")",
        layer1AnimationStart      = "compensated float",
        layer1AnimationBlend      = "compensated float",
        // Blended animation.
        layer1AnimationSequence2  = "compensated integer (-1 to " .. ModelMixin.maxAnimations .. ")",
        layer1AnimationStart2     = "compensated float",
        
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function ModelMixin:__initmixin()

    self.boneCoords         = CoordsArray()
    self.poseParams         = PoseParams()
    self.animationState     = AnimationGraphState()

    self.animationGraphNode = -1
    self.animationSequence  = -1
    self.animationSequence2 = -1

    self.layer1AnimationGraphNode = -1
    self.layer1AnimationSequence  = -1
    self.layer1AnimationSequence2 = -1

end

function ModelMixin:OnDestroy()
    self:DestroyModel()
end

function ModelMixin:OnSynchronized()
    PROFILE("ModelMixin:OnSynchronized")
    self:SynchronizeAnimation()
end

function ModelMixin:DestroyModel()
    self:_DestroyRenderModel()
end

function ModelMixin:SetModelVisible(visible)        
    if self.model ~= nil then
        self.model:SetIsVisible(visible)
    end
end        

/**
 * Used in a few places inside SimpleActor to destroy the RenderModel safely.
 */
function ModelMixin:_DestroyRenderModel()

    if self.model ~= nil then
        Client.DestroyRenderModel(self.model)
        self.model = nil
    end

end

function ModelMixin:SetAnimationGraph(fileName)
    self.animationGraphIndex = Shared.GetAnimationGraphIndex(fileName)
end

/**
 * Assigns the model. modelName is a string specifying the file name of the model,
 * which should have been precached by calling Shared.PrecacheModel during load time.
 * Returns true if the model was changed.
 */
function ModelMixin:SetModel(modelName)
    
    local prevModelIndex = self.modelIndex
    
    if modelName == nil then
        self.modelIndex = 0
    else
        self.modelIndex = Shared.GetModelIndex(modelName)
    end
    
    if self.modelIndex == 0 and modelName ~= nil and modelName ~= "" then
        Shared.Message("Model '" .. modelName .. "' wasn't precached")
    end
    
    if Client then
        self:UpdateRenderModel()
    end
    
    return self.modelIndex ~= prevModelIndex

end

/**
 * Returns the index of the named pose parameter on the actor's model. If the
 * actor doesn't have a model set or the pose parameter doesn't exist, the
 * method returns -1
 */
function ModelMixin:GetPoseParamIndex(name)
  
    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
        return model:GetPoseParamIndex(name)
    else
        return -1
    end
        
end
    
/**
 * Sets a parameter used to compute the final pose of an animation. These are
 * named in the actor's .model file and are usually things like the amount the
 * actor is moving, the pitch of the view, etc. This only applies to the currently
 * set model, so if the model is changed, the values will need to be reset.
 * Returns true if the pose parameter was found and set.
 */
function ModelMixin:SetPoseParam(name, value)
    
    local paramIndex = self:GetPoseParamIndex(name)

    if paramIndex ~= -1 then
        self.poseParams:Set(paramIndex, value)
    end
    
end

function ModelMixin:SetAnimationInput(name, value)

    local graph = Shared.GetAnimationGraph(self.animationGraphIndex)
    if graph ~= nil then
        self.animationState:SetInputValue(graph, name, value)
    end
    
end

function ModelMixin:UpdateAnimationState()

    local model = Shared.GetModel(self.modelIndex)
    local graph = Shared.GetAnimationGraph(self.animationGraphIndex)
    local time  = Shared.GetTime()
    
    if model ~= nil and graph ~= nil then
    
        local state = self.animationState
        
        state:Update(graph, model, self.poseParams, time)
        
        self.animationGraphNode = state:GetCurrentNode(0)
        self.animationSequence,  self.animationStart, self.animationBlend = state:GetCurrentAnimation(0, 0)
        self.animationSequence2, self.animationStart2 = state:GetCurrentAnimation(0, 1)

        self.layer1AnimationGraphNode = state:GetCurrentNode(1)
        self.layer1AnimationSequence,  self.layer1AnimationStart, self.animationBlend = state:GetCurrentAnimation(1, 0)
        self.layer1AnimationSequence2, self.layer1AnimationStart2 = state:GetCurrentAnimation(1, 1)
    
    end
    
end

function ModelMixin:SynchronizeAnimation()

    if Client then

        // Sync the graph with the network state.
        
        local graph = Shared.GetAnimationGraph(self.animationGraphIndex)
        
        if graph ~= nil then
            
            local state = self.animationState
            
            state:SetCurrentNode( 0, self.animationGraphNode )
            state:SetCurrentAnimation(0, 0, self.animationSequence, self.animationStart, self.animationBlend)
            state:SetCurrentAnimation(0, 1, self.animationSequence2, self.animationStart2, 1.0)
            
            state:SetCurrentNode( 1, self.layer1AnimationGraphNode )
            state:SetCurrentAnimation(1, 0, self.layer1AnimationSequence, self.layer1AnimationStart, self.layer1AnimationBlend)
            state:SetCurrentAnimation(1, 1, self.layer1AnimationSequence2, self.layer1AnimationStart2, 1.0)
                
        end
    
        // If this actor is the local player, then their animation state will be
        // updated by OnProcessMove
        if Client.GetLocalPlayer() ~= self then
            self:UpdateAnimationState()    
        end
        
    end

end

function ModelMixin:UpdateBoneCoords()
    
    local model = Shared.GetModel(self.modelIndex)
    
    if model ~= nil then
        self.animationState:GetBoneCoords(model, self.poseParams, self.boneCoords)        
    end

end

/** 
 * Creates the rendering representation of the model if it doesn't match
 * the currently set model index and update's it state to match the SimpleActor.
 */
function ModelMixin:UpdateRenderModel()

    if self.oldModelIndex ~= self.modelIndex then

        self:_DestroyRenderModel()
        
        // Create/destroy the model as necessary.
        if self.modelIndex ~= 0 then
            self.model = Client.CreateRenderModel(RenderScene.Zone_Default)
            self.model:SetModel(self.modelIndex)
        end
        
        // Save off the model index so we can detect when it changes.
        self.oldModelIndex = self.modelIndex
        
    end
    
    if self.model ~= nil then
        
        // Update the render model's coordinate frame to match the entity.
        self.model:SetCoords(self:GetCoords())
        self.model:SetBoneCoords(self.boneCoords)            
    
        // Show or hide the model depending on whether or not the
        // entity is visible. This allows the owner to show or hide it as needed.
        self.model:SetIsVisible(self:GetIsVisible())
        
    end

end

