// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/Actor.lua
//
// Created by Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TimedCallbackMixin.lua")
Script.Load("lua/PhysicsGroups.lua")

/**
 * An Actor is a type of Entity that has a model associated with it.
 */
class 'Actor' (Entity)

Actor.kMapName = "actor"

// Maximum number of animations we support on in a model. This is
// limited for the sake of propagating animation indices.
Actor.maxAnimations = 72
    
Actor.networkVars = 
    {
        modelIndex          = "resource",
        animationSequence   = "compensated integer (-1 to " .. Actor.maxAnimations .. ")",
        animationStart      = "compensated float",
        animationComplete   = "compensated boolean",
        
        // Setting to 1 plays animation at normal speed, .5 plays at half speed, 2 at double speed, etc.
        // Reset to 1 every time a new animation is set.
        animationSpeed      = "compensated float",
        
        physicsType         = "enum PhysicsType",
        physicsGroup        = "integer (0 to 31)",
    }

// Set to non-empty to enable
gActorAnimDebugClass = ""

PrepareClassForMixin(Actor, TimedCallbackMixin)

/**
 * Don't allow setting of new animations when actor is locked. Lock actor when 
 * we're inside OnProcessMove() to make sure animations aren't reverted during
 * lag compensation. Changing animations could affect if an entity is hit so they
 * are rolled back during lag compensation. Set with the player that OnProcessMove() 
 * is being called for and with nil when done.
 */
function SetRunningProcessMove(player)
    gProcessMovePlayer = player
    SetNetworkRandomLog(player)
    GetEffectManager():SetLockedPlayer(player)
end

function Actor:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, TimedCallbackMixin)
    
    self.modelIndex         = 0
    self.animationSequence  = Model.invalidSequence
    self.animationStart     = 0
    // Note: If animationLastTime is networked, the tags will not work correctly
    // in UpdateTags(), the server will put "last time" into the past from the
    // client's POV which will cause the same tag to fire off multiple times
    self.animationLastTime  = 0
    self.animationComplete  = false
    self.animationSpeed     = 1.0
    self.boneCoords         = CoordsArray()
    self.poseParams         = PoseParams()
    self.physicsType        = PhysicsType.None
    self.physicsModel       = nil
    self.physicsGroup       = 0 //PhysicsGroup.DefaultGroup
    
    if (Client) then
        // Use to track when the model is changed on the server.
        self.oldModelIndex = 0
    end

    // This field is not synchronized over the network.
    self.creationTime = Shared.GetTime()
    
    self:SetUpdates(true)
    
    self:TriggerEffects("on_create")
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:SetRelevancyDistance(kMaxRelevancyDistance)
    self:SetPhysicsGroup(PhysicsGroup.DefaultGroup)

end

function Actor:OnLoad()
    self:OnInit()
end

function Actor:OnInit()

    if Client then
    
        self:TriggerEffects("on_init")
        
        self:UpdateRenderModel()
        
    end
    
    if (self.animationSequence == Model.invalidSequence) then
        self:OnIdle()
    end
    
end

function Actor:OnDestroy()

    if Server then
        self:TriggerEffects("on_destroy")
    end
    
    Entity.OnDestroy(self)
    
    if (Client) then
    
        // Destroy the render model.
        if (self.model ~= nil) then
            Client.DestroyRenderModel(self.model)
            self.model = nil
        end
        
    end
        
    if (self.physicsModel ~= nil) then
        Shared.DestroyCollisionObject(self.physicsModel)
        self.physicsModel = nil
    end
    
end

/**
 * Returns the time which this Actor was created at.
 */
function Actor:GetCreationTime()
    return self.creationTime
end

function Actor:ResetAnimState()

    self.animationSequence          = Model.invalidSequence
    self.animationStart             = 0

    self.animationLastTime          = 0
    self.animationComplete          = false

end

/**
 * Assigns the model for the actor. modelName is a string specifying the file
 * name of the model, which should have been precached by calling
 * Shared.PrecacheModel during load time. Returns true if the model was changed.
 */
function Actor:SetModel(modelName)
    
    local prevModelIndex = self.modelIndex
    
    if (modelName == nil) then
        self.modelIndex = 0
    else
        self.modelIndex = Shared.GetModelIndex(modelName)
    end
    
    if (self.modelIndex == 0 and modelName ~= nil and modelName ~= "") then
        Print("Model '%s' wasn't precached", modelName)
    end
    
    self:DestroyPhysicsModel()
    self:UpdateBoneCoords()
    
    if (Client) then
        self:UpdateRenderModel()
    end
    
    return self.modelIndex ~= prevModelIndex

end

/**
 * Sets whether or not the actor is physically simulated. A physically
 * simulated actor will have its bones updated based on the simulation of
 * its physics representation (ragdoll). If an actor is not physically
 * simulated, the physics respresentation will be updated based on the
 * animation that is playing on the model.
 */
function Actor:SetPhysicsType(physicsType)

    self.physicsType = physicsType
    
    if (self.physicsModel ~= nil) then
        self:UpdatePhysicsModelSimulation()
     end

end

function Actor:GetPhysicsType()
    return self.physicsType
end

function Actor:GetPhysicsGroup()
    return self.physicsGroup
end

function Actor:SetPhysicsGroup(physicsGroup)

    self.physicsGroup = physicsGroup

    if (self.physicsModel ~= nil) then
        self.physicsModel:SetGroup(physicsGroup)
    end
    
end

function Actor:GetPhysicsType()
    return self.physicsType
end

function Actor:GetPhysicsModel()
    return self.physicsModel
end

function Actor:UpdatePhysicsModelSimulation()

    if (self.physicsModel ~= nil) then
        
        if (self.physicsType == PhysicsType.None) then
            self.physicsModel:SetPhysicsType(CollisionObject.None)
        elseif (self.physicsType == PhysicsType.DynamicServer) then
            if (Server) then
                self.physicsModel:SetPhysicsType(CollisionObject.Dynamic)
            else
                self.physicsModel:SetPhysicsType(CollisionObject.Kinematic)
            end
        elseif (self.physicsType == PhysicsType.Dynamic) then
            self.physicsModel:SetPhysicsType(CollisionObject.Dynamic)
        elseif (self.physicsType == PhysicsType.Kinematic) then
            self.physicsModel:SetPhysicsType(CollisionObject.Kinematic)
        end
        
    end
    
end

function Actor:GetIsDynamic()

    if (Server) then
        return self.physicsType == PhysicsType.DynamicServer
    else
        return self.physicsType == PhysicsType.Dynamic
    end

end

/**
 * Returns the mesh's center, in world coordinates. Needed because some objects
 * have their origin at the ground and others don't.
 */
function Actor:GetModelOrigin()

    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
        return self:GetOrigin() + model:GetOrigin()
    else
        return self:GetOrigin()
    end
    
end

function Actor:GetAnimationsLocked()
    return (gProcessMovePlayer ~= nil) and (gProcessMovePlayer ~= self) and (self:GetParent() ~= gProcessMovePlayer)
end

/**
 * Sets the animation currently playing on the actor. The sequence name is the
 * name stored in the current model. Returns true of the animation was set (false
 * if it was already playing and force not passed
 */
function Actor:SetAnimation(sequenceName, force, animSpeed)
    
    if self:GetAnimationsLocked() then
    
        if self.queuedSequenceName ~= nil and self.queuedSequenceName ~= sequenceName then
            Print("%s:SetAnimation(%s): Actor animations locked during OnProcessMove() and previous animation (%s) already queued.", self:GetClassName(), sequenceName, self.queuedSequenceName)
        end
        
        if gActorAnimDebugClass ~= "" and self:isa(gActorAnimDebugClass) then
            Print("%s:SetAnimation(%s, %s, %s) (queueing)", self:GetClassName(), ToString(sequenceName), ToString(force), ToString(animSpeed))
        end
        
        self.queuedSequenceName = sequenceName
        self.queuedForce = force
        self.queuedAnimSpeed = animSpeed
        
        return true
        
    end

    local success = false
    
    local model = Shared.GetModel(self.modelIndex)
    local animationSequence = Model.invalidSequence
    
    if (model ~= nil) then
        animationSequence = model:GetSequenceIndex(sequenceName)
    end
    
    // Only play the animation if it isn't already playing (unless it's finished)
    if (animationSequence ~= self.animationSequence or self.animationComplete or force) then
    
        self.animationSequence = animationSequence
        self.animationStart    = Shared.GetTime()
        
        self.animationSpeed    = 1.0
        if animSpeed then
            self.animationSpeed = animSpeed
        end

        if gActorAnimDebugClass ~= "" and self:isa(gActorAnimDebugClass) then
            Print("%s:SetAnimation(%s, %s, %s) - animationStart: %.2f, animationSpeed: %.2f", self:GetClassName(), ToString(sequenceName), ToString(force), ToString(animSpeed), self.animationStart, self.animationSpeed)
        end
        
        self.animationComplete = false
        
        success = true
        
    end
    
    return success

end

/**
 * If no parameter passed, returns the name of the currently playing animation. Otherwise
 * returns the name of the specified animation index (or nil if it can't be found).
 */
function Actor:GetAnimation(animationIndex)

    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
        
        if(animationIndex == nil) then
            animationIndex = self.animationSequence
        end
        
        if (animationIndex ~= Model.invalidSequence) then
            return model:GetSequenceName(animationIndex)
        end
        
    end
    
    return nil

end

function Actor:GetQueuedSequenceName()
    return self.queuedSequenceName
end

/**
 * Returns length of animation sequence in seconds, or 0 if it can't be found. Pass
 * nil to return current animation length.
 */
function Actor:GetAnimationLength(sequenceName)

    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
    
        local animationSequence
        
        if(sequenceName == nil) then
            animationSequence = self.animationSequence
        else
            animationSequence = model:GetSequenceIndex(sequenceName)
        end
        
        if (animationSequence ~= Model.invalidSequence) then
            return model:GetSequenceLength(animationSequence) / self.animationSpeed
        end
        
    end
    
    return 0
    
end

/**
 * Returns the index of an animation with the specified name. If a model isn't
 * assigned to the actor or the named animation doesn't exist, the method
 * returns -1.
 */
function Actor:GetAnimationIndex(sequenceName)
    
    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
        return model:GetSequenceIndex(sequenceName)
    else
        return Model.invalidSequence
    end
    
end

/**
 * Sets a parameter used to compute the final pose of an animation. These are
 * named in the actor's .model file and are usually things like the amount the
 * actor is moving, the pitch of the view, etc. This only applies to the currently
 * set model, so if the model is changed, the values will need to be reset.
 * Returns true if the pose parameter was found and set.
 */
function Actor:SetPoseParam(name, value)

    if self:GetAnimationsLocked() then
        Print("%s:SetPoseParam(%s): Actor animations locked during OnProcessMove().", self:GetClassName(), ToString(name))
        return false
    end

    local success = false
    
    local paramIndex = self:GetPoseParamIndex(name)

    if (paramIndex ~= -1) then

        self.poseParams:Set(paramIndex, value)
        success = true
    
    elseif displayErrors then
    
        Print("%s:SetPoseParam(%s) - Couldn't find pose parameter with name.", self:GetClassName(), tostring(name)) 
    
    end
    
    return success
    
end

/**
 * Returns the value of a parameter used to compute the final pose of an
 * animation. These are named in the actor's .model file and are usually
 * things like the amount the actor is moving, the pitch of the view, etc.
 * Returns -1 if pose parameter with that name couldn't be found.
 */
function Actor:GetPoseParam(name)

    local paramIndex = self:GetPoseParamIndex(name)

    if (paramIndex ~= -1) then
        return self.poseParams:Get(paramIndex)
    else
        Print("%s:GetPoseParam(%s): Parameter name doesn't exist.", self:GetClassName(), ToString(name))
    end
    
    return -1

end

/**
 * Returns the index of the named pose parameter on the actor's model. If the
 * actor doesn't have a model set or the pose parameter doesn't exist, the
 * method returns -1
 */
function Actor:GetPoseParamIndex(name)
  
    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
        return model:GetPoseParamIndex(name)
    else
        return -1
    end
        
end
    
// Called whenever actor is created (if no animation playing) and when animation
// completes and no new animation playing.
// Enable or disable idling through GetCanIdle().
function Actor:OnIdle()
    
    PROFILE("Actor:OnIdle")
    
    if self:GetCanIdle() then
        self:TriggerEffects("idle")  
    end
    
end

function Actor:GetCanIdle()
    return true
end

/**
 * Recursively calls UpdateTags on the parent and its children.
 */
local function UpdateTagsRecursively(parent)

    PROFILE("UpdateTagsRecursively")
    
    for i = 0, parent:GetNumChildren() - 1 do
        local child = parent:GetChildAtIndex(i)
        UpdateTagsRecursively(child)
    end
    
    parent:UpdateTags()

end

function Actor:OnProcessMove(input)
    
    Entity.OnProcessMove(self, input)
    UpdateTagsRecursively(self)

end

/**
 * Called every frame to update the actor. If a derived class overrides this
 * method, it should call the base class implementation or else animation will
 * not work for the actor. Must call self:SetUpdates(true) for this to be called.
 */    
function Actor:OnUpdate(deltaTime)

    PROFILE("Actor:OnUpdate")
    
    // Trigger queued animation that was set during OnProcessMove
    if self.queuedSequenceName ~= nil then
    
        self:SetAnimation(self.queuedSequenceName, self.queuedForce, self.queuedAnimSpeed)
        self.queuedSequenceName = nil
        self.queuedForce = nil
        
    end
    
    // For actors that are being controlled by a player, we call UpdateTags from inside the player's
    // OnProcessMove function. This allows anything that depends on tag callbacks to properly take
    // advantage of lag compensation on the server.
    if not self:GetIsClientControlled() then
        self:UpdateTags()
    end
    
    local model = Shared.GetModel(self.modelIndex)

    if (model ~= nil) then

        // Check to see if the animation has completed.
        if (not self.animationComplete) then

            local currentTime     = Shared.GetTime()     
            local animationTime   = currentTime - self.animationStart
            local animationLength = 0

            if self.animationSequence ~= Model.invalidSequence then
                animationLength = model:GetSequenceLength(self.animationSequence) / self.animationSpeed
            end

            if (animationTime >= animationLength) then
            
                self.animationComplete = true
                
                // TODO: Think about getting rid of idle completely and moving effects blocks into animation_complete
                local animationName
                
                if self.animationSequence ~= Model.invalidSequence then
                    animationName = model:GetSequenceName(self.animationSequence)
                else
                    animationName = ""
                end
                
                self:OnIdle()
                self:OnAnimationComplete( animationName )                
                
            end
            
        end
        
        self:SetPhysicsDirty()
        
    end
    
end

if (Client) then

    /**
     * Called after OnUpdate, OnUpdatePhysics, but before rendering takes place.
     */
    function Actor:OnUpdateRender()

        PROFILE("Actor:OnUpdateRender")
        
        Entity.OnUpdateRender(self)
    
        // Update the render model's coordinate frame to match the entity.
        if (self.model ~= nil) then
            local modelCoords = self:GetCoords()
            // There may be some special cases where an offset needs to be added
            // or rotated for example. No adjustments are made by default.
            self:AdjustModelCoords(modelCoords)
            self.model:SetCoords( modelCoords )
            self.model:SetBoneCoords( self.boneCoords )
        end 

        self:UpdateRenderModel()

    end

end

/**
 * There are special cases when the model coordinates need to be adjusted.
 * For example, if it is rotated 90 degrees and needs to look attached to
 * a nearby wall. Child classes can override this function to provide a
 * special adjustment.
 */
function Actor:AdjustModelCoords(modelCoords)

end

// Gets our currently set model name
function Actor:GetModelName()
    return Shared.GetModelName(self.modelIndex)
end

function Actor:UpdateBoneCoords()
    
    PROFILE("Actor:UpdateBoneCoords")
    
    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
    
        // The globalPosesArray saves A LOT of PosesArray allocations.
        // It should only be used in this function.
        if (globalPosesArray == nil) then
            globalPosesArray = PosesArray()
        end
        
        self:BuildPose(model, globalPosesArray)
        model:GetBoneCoords(globalPosesArray, self.boneCoords)
        
    end
    
    self:UpdatePhysicsModelCoords()

end

function Actor:UpdatePhysicsModelCoords()

    if (self.physicsModel ~= nil) then
    
        local update = self.physicsType == PhysicsType.Kinematic or self.physicsType == PhysicsType.None
        
        if Client and self.physicsType == PhysicsType.DynamicServer then
            update = true
        end

        if update then
            // Update the physics model based on the current bone animation.
            local coords = self:GetCoords()
            self:AdjustModelCoords(coords)
            self.physicsModel:SetBoneCoords(coords, self.boneCoords)
        end
        
    end

end

/**
 * Called when an animation finishes playing.
 */
function Actor:OnAnimationComplete(animName)

    local tableParams = nil
    
    if animName and animName ~= "" then
        tableParams = {}
        tableParams[kEffectFilterFromAnimation] = animName
    end
    
    self:TriggerEffects("animation_complete", tableParams)
    
end

/**
 * Called to build the final pose for the actor's bones. This may be overriden
 * to apply additional overlay animations, The base class implementation should
 * be called to play the base animation for the actor.
 */
function Actor:BuildPose(model, poses)

    PROFILE("Actor:BuildPose")
    
    model:GetReferencePose(poses)
    self:AccumulateAnimation(model, poses, self.animationSequence, self.animationStart)

end

/**
 * Accumulates the specified animation on the model into the poses.
 */
function Actor:AccumulateAnimation(model, poses, animationIndex, animationStart)

    local animationTime = (Shared.GetTime() - animationStart) * self.animationSpeed
    model:AccumulateSequence(animationIndex, animationTime, self.poseParams, poses)

end

/**
 * Blends an animation over the existing pose by the indicated fraction (0 to 1).
 */
function Actor:BlendAnimation(model, poses, animationIndex, animationStart, fraction)

    local animationTime = (Shared.GetTime() - animationStart) * self.animationSpeed

    local poses2 = PosesArray()
    model:GetReferencePose(poses2)
    model:AccumulateSequence(animationIndex, animationTime, self.poseParams, poses2)

    Model.GetBlendedPoses(poses, poses2, fraction)
    
end


/**
 * Overriden from Entity.
 */
function Actor:GetAttachPointIndex(attachPointName)

    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
        return model:GetAttachPointIndex(attachPointName)
    end

    Print("%s:GetAttachPointIndex(%s): model is nil", self:GetClassName(), attachPointName)
    
    return -1

end

/**
 * Overriden from Entity. Pass attach point index or attach point name.
 */
function Actor:GetAttachPointCoords(attachPoint)

    local attachPointIndex = attachPoint
    if type(attachPointIndex) == "string" then
        attachPointIndex = self:GetAttachPointIndex(attachPoint)
    end
    
    if (attachPointIndex ~= -1) then
   
        local model = Shared.GetModel(self.modelIndex)
    
        if (model ~= nil) then
                
            local coords = self:GetCoords()
            self:AdjustModelCoords(coords)
            
            if self.boneCoords:GetSize() > 0 then
            
                local attachPointExists = model:GetAttachPointExists(attachPointIndex)
                ASSERT(attachPointExists, self:GetClassName() .. ":GetAttachPointCoords(" .. attachPointIndex .. "): Attach point doesn't exist. Named: " .. ToString(attachPoint) .. " Model Name: " .. model:GetFileName())

                if attachPointExists then
                    coords = coords * model:GetAttachPointCoords(attachPointIndex, self.boneCoords)
                else
                    Print("%s:GetAttachPointCoords(%d): Attach point doesn't exist.", self:GetClassName(), attachPointIndex)
                end
                
            end
            
            return coords
            
        end

    end
    
    return Coords.GetIdentity()
    
end

/**
 * Returns true if this actor is under the control of a client (i.e. either the
 * entity for which SetControllingPlayer has been called on the server, or one
 * of its children).
 */
function Actor:GetIsClientControlled()

    PROFILE("Actor:GetIsClientControlled")

    local parent = self:GetParent()

    if (parent ~= nil and parent:GetIsClientControlled()) then
        return true;
    end

    if (Server) then
        return Server.GetOwner(self) ~= nil
    else
        return Client.GetLocalPlayer() == self
    end

end

function Actor:UpdateTags()

    PROFILE("Actor:UpdateTags")
    
    local model = Shared.GetModel(self.modelIndex)

    if (model ~= nil and self.animationSequence ~= Model.invalidSequence) then
    
        local currentTime     = Shared.GetTime()
        local animationTime   = currentTime - self.animationStart
        
        local animationLength = model:GetSequenceLength(self.animationSequence)
        
        // Don't play tags on 0 length (pose) animations, as it doesn't really make sense
        if(animationLength == 0) then
            return
        end
        
        local frameTagName, lastTime = model:GetTagPassed(self.animationSequence, self.poseParams, self.animationLastTime, animationTime)
        self.animationLastTime = animationTime

        local currentSequence = self.animationSequence
        
        while (lastTime >= 0 and lastTime < animationTime) do
        
            // tag could have changed the sequence
            if (currentSequence ~= self.animationSequence) then
                return
            end

            self:OnTag(frameTagName)

            frameTagName, lastTime = model:GetTagPassed(self.animationSequence, self.poseParams, lastTime, animationTime)

        end

    end
    
end

/**
 * Called when the playing animation passes a frame tag. Derived classes can
 * can override this.
 */
function Actor:OnTag(tagName)
end

/**
 * Called when the network variables for the actor are updated from values
 * from the server.
 */
function Actor:OnSynchronized()

    PROFILE("Actor:OnSynchronized")

    Entity.OnSynchronized(self)
    
    // The animation and physics model are dependent on the networked parameters
    // so once we've synchronized we'll need to update those.
    self:SetPhysicsDirty()
        
end

function Actor:SetPhysicsDirty()

    PROFILE("Actor:SetPhysicsDirty")
    
    local model = Shared.GetModel(self.modelIndex)
    
    if (model ~= nil) then
        self:SetPhysicsBoundingBox(model)
    end

end

function Actor:OnUpdatePhysics()

    PROFILE("Actor:OnUpdatePhysics")

    Entity.OnUpdatePhysics(self)

    self:UpdateBoneCoords()
    self:UpdatePhysicsModel()
    
    if (self.physicsType ~= PhysicsType.None) then
        
        if (self.physicsModel ~= nil and self:GetIsDynamic()) then
        
            // On the server, update the position of the actor based on the
            // motion of the root. We don't do this on the client because 
            // it won't match what's happening on the server.
            if (Server) then
                
                local coords = self.physicsModel:GetCoords()
                
                local angles = Angles()
                angles:BuildFromCoords( coords )
                
                self:SetAngles( angles )
                self:SetOrigin( coords.origin )
                
                
            end
        
            // Update the bones based on the simulation of the physics model.
            self.physicsModel:GetBoneCoords(self.boneCoords)
            
        end
        
    end

end

function Actor:UpdatePhysicsModel()

    PROFILE("Actor:UpdatePhysicsModel")

    // Create a physics model if necessary.
    if (self.physicsModel == nil and self:GetPhysicsModelAllowed()) then
    
        self.physicsModel = Shared.CreatePhysicsModel(self.modelIndex, true, self:GetCoords(), self.boneCoords, self)
        
        if self.physicsModel ~= nil then
            self.physicsModel:SetEntity(self)
        end

    end
    
    // Update the state of the physics model.
    if (self.physicsModel ~= nil) then
        self.physicsModel:SetGroup(self.physicsGroup)
        self.physicsModel:SetCollisionEnabled(self:GetIsVisible())
        self:UpdatePhysicsModelSimulation()
    end
        
end

function Actor:DestroyPhysicsModel()
    
    if (self.physicsModel ~= nil) then
        // We're no longer are using a physics model, so destroy it.
        Shared.DestroyCollisionObject(self.physicsModel)
        self.physicsModel = nil
    end
    
end

/**
 * By default every Actor is allowed to have a physics model.
 * Child classes can override this behavior through this method.
 */
function Actor:GetPhysicsModelAllowed()

    return true
    
end

/** 
 * Called when actor collides with another entity. Entity hit will be nil if we hit
 * the world or if SetUserData() wasn't called on the physics actor.
 */
function Actor:OnCollision(entityHit)
end

if (Client) then
    
    /** 
     * Creates the rendering representation of the model if it doesn't match
     * the currently set model index and update's it state to match the actor.
     */
    function Actor:UpdateRenderModel()
    
        PROFILE("Actor:UpdateRenderModel")
    
        if (self.oldModelIndex ~= self.modelIndex) then
    
            // Create/destroy the model as necessary.
            if (self.modelIndex == 0) then
                Client.DestroyRenderModel(self.model)
                self.model = nil
            else
            
                if (self.model ~= nil) then
                    Client.DestroyRenderModel(self.model)
                    self.model = nil
                end
                      
                self.model = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.model:SetModel(self.modelIndex)
            end
        
            // Save off the model index so we can detect when it changes.
            self.oldModelIndex = self.modelIndex
            
        end
        
        if (self.model ~= nil) then
        
            // Show or hide the model depending on whether or not the
            // entity is visible. This allows the owner to show or hide it
            // as needed.
            self.model:SetIsVisible( self:GetIsVisible() )
            
        end

    end

    function Actor:SetIsVisible(visible)
    
        Entity.SetIsVisible(self, visible)
        
        if (self.model ~= nil) then
            self.model:SetIsVisible(visible)
        end
        
    end

end

function Actor:AddImpulse(position, direction)

    if self.physicsModel then
        self.physicsModel:AddImpulse(position, direction)
    else
        Print("%s:AddImpulse(%s, %s): No physics model.", self:GetClassName(), ToString(position), ToString(direction))
    end
    
end

function Actor:GetEffectParams(tableParams)

    if not tableParams[kEffectFilterFromAnimation] then
        tableParams[kEffectFilterFromAnimation] = self:GetAnimation()
    end
    
end

// Hooks into effect manager
function Actor:TriggerEffects(effectName, tableParams)

    if effectName and effectName ~= "" then

        if not tableParams then
            tableParams = {}
        end
        
        self:GetEffectParams(tableParams)
        
        GetEffectManager():TriggerEffects(effectName, tableParams, self)
        
    else
        Print("%s:TriggerEffects(): Called with invalid effectName)", self:GetClassName(), ToString(effectName))
    end
        
end

Shared.LinkClassToMap( "Actor", Actor.kMapName, Actor.networkVars )