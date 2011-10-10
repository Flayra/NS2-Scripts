// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Flamethrower_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Flamethrower:OnUpdate(deltaTime)

    Weapon.OnUpdate(self, deltaTime)

    // Only update when held in inventory
    if self.loopingSoundEntId ~= Entity.invalidId and self:GetParent() ~= nil then
    
        local player = Client.GetLocalPlayer()
        local viewAngles = player:GetViewAngles()
        local yaw = viewAngles.yaw

        local soundEnt = Shared.GetEntity(self.loopingSoundEntId)
        if soundEnt then

            if soundEnt:GetIsPlaying() and self.lastYaw ~= nil then
            
                // 180 degree rotation = param of 1
                local rotateParam = math.abs((yaw - self.lastYaw) / math.pi)
                
                // Use the maximum rotation we've set in the past short interval
                if not self.maxRotate or (rotateParam > self.maxRotate) then
                
                    self.maxRotate = rotateParam
                    self.timeOfMaxRotate = Shared.GetTime()
                    
                end
                
                if self.timeOfMaxRotate ~= nil and Shared.GetTime() > self.timeOfMaxRotate + .75 then
                
                    self.maxRotate = nil
                    self.timeOfMaxRotate = nil
                    
                end
                
                if self.maxRotate ~= nil then
                    rotateParam = math.max(rotateParam, self.maxRotate)
                end
                
                local success = soundEnt:SetParameter("rotate", rotateParam, 1)
                if success == false then
                    Print("Tried to use invalid looping flamethrower sound entity id: %s", ToString(self.loopingSoundEntId))
                end
                
            end
            
        else
            Print("Flamethrower:OnUpdate(): Couldn't find sound ent on client")
        end
            
        self.lastYaw = yaw
        
    end
    
end