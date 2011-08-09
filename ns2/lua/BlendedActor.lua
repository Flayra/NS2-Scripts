// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BlendedActor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handles animation blending, overlay animations and idling.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Actor.lua")

class 'BlendedActor' (Actor)

BlendedActor.kMapName = "blendedactor"

local networkVars = 
{   
    // Overlay animations
    overlayAnimationSequence    = "compensated integer (-1 to " .. Actor.maxAnimations .. ")",
    overlayAnimationStart       = "compensated float", 
    
    // Animation blending
    prevAnimationSequence       = "compensated integer (-1 to " .. Actor.maxAnimations .. ")",
    prevAnimationStart          = "compensated float",
    blendTime                   = "compensated float",
}


// Temporary used in BlendedActor:BlendAnimation to reduce the amount of
// allocation/garbage created.
local g_poses = PosesArray()

// Called right after an entity is created on the client or server. This happens through Server.CreateEntity, 
// or when a server-created object is propagated to client. 
function BlendedActor:OnCreate()    

    Actor.OnCreate(self)

    // Overlay animations
    self.overlayAnimationSequence   = Model.invalidSequence
    self.overlayAnimationStart      = 0

    // Animation blending    
    self.prevAnimationSequence      = Model.invalidSequence
    self.prevAnimationStart         = 0
    self.blendTime                  = 0.0
    
end

function BlendedActor:ResetAnimState()

    Actor.ResetAnimState(self)
    
    self.overlayAnimationSequence   = Model.invalidSequence
    self.overlayAnimationStart      = 0
    
    self.prevAnimationSequence      = Model.invalidSequence
    self.prevAnimationStart         = 0
    self.blendTime                  = 0.0
    
end

// Allow children to process animation names to translate something like 
// "idle" to "bite_idle" depending on current state
function BlendedActor:GetCustomAnimationName(baseAnimationName)
    return baseAnimationName
end

// Default movement blending time
function BlendedActor:GetBlendTime()
    return .2
end

/* Sets default blend length when not otherwise specified */
function BlendedActor:SetBlendTime( blendTime )
    self.blendTime = blendTime
end

function BlendedActor:SetAnimation(sequenceName, force, animSpeed)

    if Actor.SetAnimation(self, sequenceName, force, animSpeed) then
    
        local length = self:GetAnimationLength(sequenceName)        
        if(length > 0) then
        
            if animSpeed then
                length = length / animSpeed
            end
        
        end
        
        self.prevAnimationSequence = Model.invalidSequence

        return true
        
    end
    
    return false
    
end

/**
 * Sets the primary animation, blending into it from the currently playing
 * animation. The blendTime specifies the time (in seconds) over which
 * the new animation will be blended in. Note the model can only blend
 * between two animations at a time, so if an an animation is already being
 * blended in, there will be a pop. If nothing passed for blendTime, it
 * uses the default blend time. Returns true if the animation was changed.
 */
function BlendedActor:SetAnimationWithBlending(baseAnimationName, blendTime, force, speed)

    if(baseAnimationName == "" or baseAnimationName == nil) then
        return false
    end
    
    if(type(baseAnimationName) ~= "string") then
        Print("%s:SetAnimationWithBlending(%s): Didn't pass a string.", tostring(baseAnimationName))
        return false
    end
    
    if(blendTime == nil) then
        blendTime = self:GetBlendTime()
    end

    // Translate animation name to one that uses current weapon    
    local animationName = self:GetCustomAnimationName(baseAnimationName)
    
    if(force == nil or force == false) then
    
        local newSequence = self:GetAnimationIndex(animationName)
        if((newSequence == self.prevAnimationSequence) and (newSequence ~= Model.invalidSequence) and (Shared.GetTime() < (self.prevAnimationStart + self.blendTime))) then
            return false
        end
        
    end
    
    // If we don't have a weapon-specific animation, try to play the base one
    if(self:GetAnimationIndex(animationName) == Model.invalidSequence) then
        animationName = baseAnimationName
    end
    
    local theCurrentAnimName = self:GetAnimation()
    
    // If we're already playing this and it hasn't expired, do nothing new
    if(theCurrentAnimName == animationName and not force and not self.animationComplete) then
    
        // If we've already blended with previous animation once, blend no more
        if((self.prevAnimationSequence ~= Model.invalidSequence) and (Shared.GetTime() > self.prevAnimationStart + self.blendTime)) then
            self.prevAnimationSequence = Model.invalidSequence
        end

        return false
        
    end

    // If we have no animation or are already playing this animation, don't blend
    if(theCurrentAnimName ~= nil and theCurrentAnimName ~= animationName) then    
    
        self.prevAnimationSequence = self:GetAnimationIndex(theCurrentAnimName)
        self.prevAnimationStart    = self.animationStart
        self.blendTime             = blendTime
        
        if self.GetClassName and self:GetClassName() == gActorAnimDebugClass then
            Print("%s:SetAnimationWithBlending(%s, %.2f, %s, %s) (next SetAnimation is from this one)", self:GetClassName(), ToString(theCurrentAnimName), blendTime, ToString(force), ToString(speed))
        end

    else
        self.prevAnimationSequence = Model.invalidSequence
        self.prevAnimationStart = 0
    end
    
    return self:SetAnimation(animationName, force, speed)
    
end

function BlendedActor:SetOverlayAnimation(animationName, dontForce)

    if( animationName == nil or animationName == "") then
    
        if self.GetClassName and self:GetClassName() == gActorAnimDebugClass then
            Print("%s:SetOverlayAnimation(%s, %s) - Clearing overlay.", self:GetClassName(), ToString(animationName), ToString(dontForce))
        end

        self.overlayAnimationSequence = Model.invalidSequence
    
    elseif ( animationName ~= nil ) then
    
        // Try to play the weapon or player specific version of this animation 
        local theAnimName = self:GetCustomAnimationName(animationName)
        local index = self:GetAnimationIndex(theAnimName)
        if(index == Model.invalidSequence) then
            // ...but fall back to base if there is none 
            theAnimName = animationName
            index = self:GetAnimationIndex( theAnimName )
        end

        // Don't reset it if already playing
        if(index ~= Model.invalidSequence) and ((self.overlayAnimationSequence ~= index) or (not dontForce)) then

            if self.GetClassName and self:GetClassName() == gActorAnimDebugClass then
                Print("%s:SetOverlayAnimation(%s, %s)", self:GetClassName(), ToString(animationName), ToString(dontForce))
            end
        
            self.overlayAnimationSequence = index
            self.overlayAnimationStart    = Shared.GetTime()
            
        end
        
    end

end

// Stop playing specified overlay animation if it's playing
function BlendedActor:StopOverlayAnimation(animationName)

    local success = false
    
    if( animationName ~= nil and animationName ~= "") then
    
        if self.overlayAnimationSequence ~= Model.invalidSequence then
        
            // Try to play the weapon or player specific version of this animation 
            local customAnimName = self:GetCustomAnimationName(animationName)
            local index = self:GetAnimationIndex(customAnimName)
            
            if(index ~= Model.invalidSequence) then
            
                if self.overlayAnimationSequence == index then
                
                    self.overlayAnimationSequence = Model.invalidSequence
                    success = true
                    
                end
                
            end
            
        end
        
    else
        Print("%s:StopOverlayAnimation(): Must specify an animation name.", self:GetClassName())
    end
    
    return success
    
end

function BlendedActor:GetOverlayAnimationFinished()

    local finished = false
    
    if(self.overlayAnimationSequence ~= Model.invalidSequence) then
    
        local animName = self:GetOverlayAnimation()
        finished = (Shared.GetTime() > self.overlayAnimationStart + self:GetAnimationLength(animName))
        
    end
    
    return finished
    
end

function BlendedActor:GetOverlayAnimation()

    local overlayAnimName = ""
    
    if(self.overlayAnimationSequence ~= Model.invalidSequence) then
        overlayAnimName = self:GetAnimation(self.overlayAnimationSequence)
    end
    
    return overlayAnimName
    
end

/**
 * Called by the engine to construct the pose of the bones for the actor's model.
 */
function BlendedActor:BuildPose(model, poses)
    
    Actor.BuildPose(self, model, poses)

    // If we have a previous animation, blend it in.
    if (self.prevAnimationSequence ~= Model.invalidSequence) then

        if(self.blendTime ~= nil and self.blendTime > 0) then
        
            local time     = Shared.GetTime()
            local fraction = Clamp( (time - self.animationStart) / self.blendTime, 0, 1 )
            
            if (fraction < 1) then
            
                if self.GetClassName and self:GetClassName() == gActorAnimDebugClass then
                    Print("%s:BuildPose(): fraction: %.2f", self:GetClassName(), fraction)
                end
                
                self:BlendAnimation(model, poses, self.prevAnimationSequence, self.prevAnimationStart, 1 - fraction)
            end
            
        end
    
    end

    // Apply the overlay animation if we have one.
    if (self.overlayAnimationSequence ~= Model.invalidSequence) then
        self:AccumulateAnimation(model, poses, self.overlayAnimationSequence, self.overlayAnimationStart)
    end
    
end

/**
 * Blends an animation over the existing pose by the indicated fraction (0 to 1).
 */
function BlendedActor:BlendAnimation(model, poses, animationIndex, animationStart, fraction)
   
    local animationTime = (Shared.GetTime() - animationStart) * self.animationSpeed

    model:GetReferencePose(g_poses)
    model:AccumulateSequence(animationIndex, animationTime, self.poseParams, g_poses)

    Model.GetBlendedPoses(poses, g_poses, fraction)
    
end

// Called every tick
function BlendedActor:OnUpdate(deltaTime)

    Actor.OnUpdate( self, deltaTime )
    self:UpdateAnimation( deltaTime )
    
end

function BlendedActor:GetName()
    return self:GetMapName()
end

function BlendedActor:UpdateAnimation(timePassed)

    PROFILE("BlendedActor:UpdateAnimation")

    // Run idles on the server only until we have shared random numbers
    if self:GetIsVisible() and self.modelIndex ~= 0 then
    
        if self:GetOverlayAnimationFinished() then
        
            self.overlayAnimationSequence   = Model.invalidSequence
            self.overlayAnimationStart      = 0
            
        end
    
    end
    
end

// Called with name of animation that finished. Called at end of looping animation also.
function BlendedActor:OnAnimationComplete(animationName)
    Actor.OnAnimationComplete(self, animationName)
    self.prevAnimationSequence = Model.invalidSequence
end

Shared.LinkClassToMap("BlendedActor", BlendedActor.kMapName, networkVars )