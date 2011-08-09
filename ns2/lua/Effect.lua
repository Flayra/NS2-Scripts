// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Effect.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'Effect'

Effect.mapName = "effect"
Effect.kUpdateInterval = .5

function Effect:SetOrigin(newOrigin)

    self.origin = Vector(newOrigin)

end

function Effect:SetAngles(newAngles)
end

function Effect:OnLoad()

    self.radius = GetAndCheckValue(self.radius, 0, 1000, "radius", 0)
    self.offOnExit = GetAndCheckBoolean(self.offOnExit, "offOnExit", false)
    self.startsOn = GetAndCheckBoolean(self.startsOn, "startsOn", false)
    
    self.playing = false
    self.triggered = false
    self.startedOn = false
    self.timeOfLastUpdate = nil
    
end

function Effect:GetOrigin()
    return self.origin
end

function Effect:GetRadius()
    return self.radius
end

function Effect:GetOffOnExit()
    return self.offOnExit
end

function Effect:GetStartsOn()
    return self.startsOn
end

if (Client) then

    // Check if effect should be turned on or of
    function Effect:OnUpdate(deltaTime)
        
        local time = Shared.GetTime()
        
        // Don't update every tick to reduce garbage
        if not self.timeOfLastUpdate or (time > (self.timeOfLastUpdate + Effect.kUpdateInterval)) then
        
            if self:GetStartsOn() and not self.startedOn then    
            
                self:StartPlaying()
                self.startedOn = true
                
            else
                    
                if self:GetOffOnExit() and self.triggered then
                
                    local player = Client.GetLocalPlayer()
                    local origin = player:GetOrigin()
                    
                    if self:GetOrigin():GetDistanceTo(origin) > self:GetRadius() then

                        self:StopPlaying()
                        self.triggered = false
                        
                    end
                    
                elseif not self.playing then
                
                    local player = Client.GetLocalPlayer()
                    local origin = player:GetOrigin()
                    
                    if self:GetOrigin():GetDistanceTo(origin) < self:GetRadius() then
                    
                        self:StartPlaying()
                        self.triggered = true
                    end
                    
                end
                
            end
            
            self.timeOfLastUpdate = time
            
        end
        
    end

end
