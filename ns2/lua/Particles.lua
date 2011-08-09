// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Particles.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Effect.lua")

class 'Particles' (Effect)

Particles.kMapName = "particles"

if (Client) then

    function Particles:StartPlaying()

        if(not self.playing) then
        
            if self.cinematicNameIndex == nil then
                self.cinematicNameIndex = Shared.GetCinematicIndex(self.cinematicName)
            end

            local coords = Coords()
            coords.origin = self.origin
            
            Client.PlayParticlesWithIndex(self.cinematicNameIndex, coords)
            
            self.playing = true
            
        end
        
    end

    function Particles:StopPlaying()

        if(self.playing) then
        
            if self.cinematicNameIndex == nil then
                self.cinematicNameIndex = Shared.GetCinematicIndex(self.cinematicName)
            end

            Client.StopParticlesWithIndex(self.cinematicNameIndex, self:GetOrigin())
            
            self.playing = false
            
        end
        
    end

end

