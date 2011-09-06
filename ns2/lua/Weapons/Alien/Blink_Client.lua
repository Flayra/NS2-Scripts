// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Blink_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Draw ghost version of Fade showing where you'll blink.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Blink:GetShowingGhost()
    return self.showingGhost
end

function Blink:SetFadeGhostAnimation(animName)

    if self.fadeGhostAnimModel then
    
        local currentAnim = self.fadeGhostAnimModel:GetAnimation()
        
        if currentAnim == Fade.kBlinkInAnim then
        
            self.fadeGhostAnimModel:SetQueuedAnimation(animName)
            
        elseif currentAnim ~= animName then
        
            self.fadeGhostAnimModel:SetAnimation(animName)
            
        end
        
    end
    
end

function Blink:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    if not Shared.GetIsRunningPrediction() then

        local player = self:GetParent()
        
        if player == Client.GetLocalPlayer() and player:GetActiveWeapon() == self then
        
            if not self.fadeGhostAnimModel and self.showingGhost then

                // Create ghost Fade in random dramatic attack pose
                self.fadeGhostAnimModel = CreateAnimatedModel(Fade.kModelName)
                self.fadeGhostAnimModel:SetAnimation(Fade.kBlinkInAnim)
                self.fadeGhostAnimModel:SetCastsShadows(false)
                
            end
            
            // Destroy ghost
            if self.fadeGhostAnimModel and not self.showingGhost then
                self:DestroyGhost()
            end
            
            // Update ghost position 
            if self.fadeGhostAnimModel then
            
                local coords, valid, blinkType = self:GetBlinkPosition(player)
                
                self.fadeGhostAnimModel:SetCoords(coords)
                self.fadeGhostAnimModel:SetIsVisible(valid)                    
                self.fadeGhostAnimModel:SetPoseParam("crouch", player:GetCrouchAmount())
                
                if blinkType == kBlinkType.InAir then
                
                    self:SetFadeGhostAnimation(Player.kAnimJump)
                    
                elseif blinkType == kBlinkType.Attack then
                
                    if NetworkRandom() < .1 then
                        self:SetFadeGhostAnimation(Player.kAnimTaunt)
                    else
                        self:SetFadeGhostAnimation(chooseWeightedEntry(Fade.kAnimSwipeTable))
                    end

                else
                    self:SetFadeGhostAnimation("idle")
                end

                self.fadeGhostAnimModel:OnUpdate(deltaTime)

                if self.blinkPreviewEffect then
                
                    if not valid then
                        Client.DestroyCinematic(self.blinkPreviewEffect)
                        self.blinkPreviewEffect = nil
                    else
                        self.blinkPreviewEffect:SetCoords(coords)
                    end
                    
                elseif valid then
                
                    // Create blink preview effect
                    self.blinkPreviewEffect = Client.CreateCinematic(RenderScene.Zone_Default)
                    self.blinkPreviewEffect:SetCinematic(Blink.kBlinkPreviewEffect)
                    self.blinkPreviewEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
                    self.blinkPreviewEffect:SetCoords(coords)

                end
                
            end
          
        end
        
        // Expire model once animation finishes    
        if self.blinkOutModel ~= nil and Shared.GetTime() >= self.blinkOutExpireTime then
            self:DestroyBlinkOutModel()
        end
        
    end
    
end

function Blink:CreateBlinkOutEffect(player)

    // Create render model of fade vanishing
    self:DestroyBlinkOutModel()
    
    self.blinkOutModel = CreateAnimatedModel(Fade.kModelName)
    self.blinkOutModel:SetAnimation(Fade.kBlinkOutAnim)
    self.blinkOutModel:SetCoords(player:GetViewAngles():GetCoords())
    
    self.blinkOutExpireTime = Shared.GetTime() + self.blinkOutModel:GetAnimationLength()

end

function Blink:DestroyBlinkOutModel()

    if self.blinkOutModel then
    
        self.blinkOutModel:OnDestroy()
        self.blinkOutModel = nil
        
        self.blinkEndTime = nil
        
    end

end

function Blink:OnDestroy()

    self:DestroyBlinkOutModel()
    
    self:DestroyGhost()
    
    Ability.OnDestroy(self)
    
end


function Blink:DestroyGhost()

    if self.fadeGhostAnimModel ~= nil then
    
        self.fadeGhostAnimModel:OnDestroy()
        self.fadeGhostAnimModel = nil
        
    end
    
    if Client and self.blinkPreviewEffect then
    
        Client.DestroyCinematic(self.blinkPreviewEffect)
        self.blinkPreviewEffect = nil
        
    end
        
end

// Perform cool camera transition effect while blinking
function Blink:GetCameraCoords()

    local time = Shared.GetTime()
    
    if self.blinkStartTime ~= nil and self.blinkTransitionTime ~= nil then
    
        if (time >= self.blinkStartTime) and (time <= (self.blinkStartTime + self.blinkTransitionTime)) then
        
            local timeScalar = Clamp((time - self.blinkStartTime) / self.blinkTransitionTime, 0, 1)
            
            timeScalar = math.sin( timeScalar * math.pi / 2 )
            
            // Interpolate between z axis in start/end view coords
            return true, Shared.SlerpCoords(self.cameraStart, self.cameraEnd, timeScalar)
            
        end
        
    end
    
    return false, nil
    
end

function Blink:SetBlinkCamera(startCoords, endCoords, cameraTransitionTime) 

    self.cameraStart = startCoords
    self.cameraEnd = endCoords
    
    self.blinkTransitionTime = cameraTransitionTime
    
    self.blinkStartTime = Shared.GetTime()
    
end
