// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Flamethrower_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Flamethrower:OnDestroy()

    self:SetPilotLightState(false)
    
    ClipWeapon.OnDestroy(self)
    
end

function Flamethrower:SetPilotLightState(state)

    if self.pilotLightState ~= state then
    
        // Pilot can't be on when out of fuel
        if state and self:GetClip() > 0 then
    
            self.pilotLightEffect = Client.CreateCinematic(RenderScene.Zone_Default)
            self.pilotLightEffect:SetCinematic(Flamethrower.kPilotCinematic)            
            self.pilotLightEffect:SetRepeatStyle(Cinematic.Repeat_Endless)

        elseif not state and self.pilotLightEffect then
        
            Client.DestroyCinematic(self.pilotLightEffect)
            self.pilotLightEffect = nil
                
        end
        
        self.pilotLightState = state
        
        self:SetUpdates(self.pilotLightState)
        
    end
    
end

/*
function Flamethrower:OnUpdate(deltaTime)

    ClipWeapon.OnUpdate(self, deltaTime)

    // Set "rotate" parameter so attacking sound get louder or changes when you wave it arround, the way 
    // a real flame would (think how a flaming torch sounds when you wave it around)
    local parentPlayer = self:GetParent()   
    if (parentPlayer == Client.GetLocalPlayer()) and parentPlayer:isa("Marine") and self.loopingWeaponSoundPlaying then
    
        // Weapon swing is -1 to 1
        local amount = Clamp(math.abs(parentPlayer:GetWeaponSwing())*2, 0, 1)
        parentPlayer:SetSoundParameter(self:GetFireSoundName(), "rotate", amount, 10)
        
    end

    if self.pilotLightEffect ~= nil and self:GetId() ~= Entity.invalidId then
    
        ClipWeapon.OnUpdate(self)
        
        local viewModel = self:GetParent():GetViewModelEntity()
        local coords = viewModel:GetAttachPointCoords(Flamethrower.kMuzzleNode)
        
        self.pilotLightEffect:SetCoords(coords)        
            
    end 
   
end
*/

