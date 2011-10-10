// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Onos:GetIdleSoundName()
    return Onos.kLocalIdleSound
end

function Onos:PlayFootstepShake()

    if not Shared.GetIsRunningPrediction() then
    
        // Get all nearby players and shake their screen
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        
            if player:GetIsAlive() and not player:isa("Commander") then
            
                self:PlayFootstepShake(player)
                
            end
            
        end
        
    end
    
end

// Shake camera for nearby players
function Onos:PlayFootstepShake(player)

    if player ~= nil and player:GetIsAlive() then
        
        local kMaxDist = 25
        
        local dist = (player:GetOrigin() - self:GetOrigin()):GetLength()
        
        if dist < kMaxDist then
        
            local amount = (kMaxDist - dist)/kMaxDist
            
            local shakeAmount = .01 + amount * amount * .08
            local shakeSpeed = 5 + amount * amount * 9
            local shakeTime = .4 - (amount * amount * .2)
            
            player:SetCameraShake(shakeAmount, shakeSpeed, shakeTime)
            
        end
        
    end
        
end
