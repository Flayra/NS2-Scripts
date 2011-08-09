// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AnimatedModel.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Utility.lua")

class 'AnimatedModel'

function CreateAnimatedModel(modelName)

    local animatedModel = AnimatedModel()
    
    animatedModel:OnInit(modelName)
    
    return animatedModel
            
end

function AnimatedModel:OnInit(modelName)

    self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
    
    self.modelIndex = Shared.GetModelIndex(modelName)
    
    self.modelName = modelName
    
    self.renderModel:SetModel( self.modelIndex )
    
    self.animationName = nil
    
    self.animationTime = 0
    
    self.poseParams = PoseParams()
    
end

function AnimatedModel:SetCoords(coords)
    if self.renderModel ~= nil then
        self.renderModel:SetCoords(coords)
    end
end

function AnimatedModel:SetIsVisible(visible)    
    if self.renderModel ~= nil then
        self.renderModel:SetIsVisible(visible)
    end
end

function AnimatedModel:SetAnimation(animationName)
    self.animationName = ToString(animationName)
    self.animationTime = 0
end

function AnimatedModel:SetPoseParam(name, value)

    local success = false
    
    local paramIndex = self:GetPoseParamIndex(name)

    if (paramIndex ~= -1) then

        self.poseParams:Set(paramIndex, value)
        success = true
    
    else
    
        Print("AnimatedModel:SetPoseParam(%s) - Couldn't find pose parameter with name.", ToString(name)) 
    
    end
    
    return success
    
end

function AnimatedModel:GetPoseParamIndex(name)
  
    local model = Shared.GetModel(self.modelIndex)  
    if (model ~= nil) then
        return model:GetPoseParamIndex(name)
    else
        return -1
    end
        
end

function AnimatedModel:GetAnimation()
    return self.animationName    
end

function AnimatedModel:GetAnimationLength(animationName)

    local model = Shared.GetModel(self.modelIndex)
    if model ~= nil then

        local anim = ConditionalValue(animationName ~= nil, animationName, self.animationName)
        local animationIndex = model:GetSequenceIndex(anim)
        return model:GetSequenceLength(animationIndex)
    end
    
    return 0
    
end

function AnimatedModel:SetQueuedAnimation(queuedAnimationName)
    self.queuedAnimationName = ToString(queuedAnimationName)
end

function AnimatedModel:SetAnimationTime(time)

    local model = Shared.GetModel(self.modelIndex)
    if model ~= nil and self.animationName ~= nil then

        local animationIndex = model:GetSequenceIndex(self.animationName)
        local animationLength = model:GetSequenceLength(animationIndex)
        self.animationTime = Clamp(time, 0, animationLength)
        
    end
    
end

function AnimatedModel:SetAnimationParameter(scalar)
    self.animationParameter = Clamp(scalar, 0, 1)
end

// Must be called manually 
function AnimatedModel:OnUpdate(deltaTime)

    if not Shared.GetIsRunningPrediction() then
    
        // ...in random dramatic attack pose
        if self.animationName ~= nil then
        
            local model = Shared.GetModel(self.modelIndex)
            if model ~= nil then
            
                // Update animation time
                local animationIndex = model:GetSequenceIndex(self.animationName)            
                self.animationTime = self.animationTime + deltaTime
                
                local animationLength = model:GetSequenceLength(animationIndex)
                local animationTime = self.animationTime
                if self.animationTime > animationLength then
                
                    self.animationTime = self.animationTime - animationLength
                
                    // When we hit the end of the current animation, transition to queued animation                    
                    if self.queuedAnimationName ~= nil then
                    
                        self:SetAnimation(self.queuedAnimationName)
                        
                        animationIndex = model:GetSequenceIndex(self.queuedAnimationName)            
                        animationTime = 0
                        self.queuedAnimationName = nil

                    end
                    
                end       
                
                // Update bone coords
                local boneCoords = CoordsArray()
                local poses = PosesArray()
                model:GetReferencePose(poses)
                
                model:AccumulateSequence(animationIndex, animationTime, self.poseParams, poses)
                model:GetBoneCoords(poses, boneCoords)
                self.renderModel:SetBoneCoords(boneCoords)
                
            else
                Print("AnimatedModel:OnUpdate(): Couldn't find model for model index %s (%s)", ToString(self.modelIndex), ToString(self.modelName))
            end
            
        end
        
    end 
   
end

function AnimatedModel:SetCastsShadows(showShadows)
    if self.renderModel ~= nil then
        self.renderModel:SetCastsShadows(showShadows)
    end
end

// Must be called manually 
function AnimatedModel:OnDestroy()

    if self.renderModel ~= nil then
    
        Client.DestroyRenderModel(self.renderModel)
        self.renderModel = nil
        
    end

end