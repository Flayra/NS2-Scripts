// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AmbientSound.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Effect.lua")
class 'AmbientSound' (Effect)

AmbientSound.kMapName = "ambient_sound"

// Read trigger radius and FMOD event name
function AmbientSound:OnLoad()

    Effect.OnLoad(self)

    // Precache sound name and lookup index for it
    self.minFalloff = GetAndCheckValue(self.minFalloff, 0, 1000, "minFalloff", 0)
    self.maxFalloff = GetAndCheckValue(self.maxFalloff, 0, 1000, "maxFalloff", 0)
    self.falloffType = GetAndCheckValue(self.falloffType, 1, 2, "falloffType", 1)
    self.positioning = GetAndCheckValue(self.positioning, 1, 2, "positioning", 1)
    self.volume = GetAndCheckValue(self.volume, 0, 1, "volume", 1)
    self.pitch = GetAndCheckValue(self.pitch, -4, 4, "pitch", 0)

end

if (Client) then

    // From fmod_event.h and fmod.h
    local kFmod3DSound = 16
    local kFmodLogarithmicRolloff = 1048576
    local kFmodLinearRolloff = 2097152
    local kFmodCustomRolloff = 67108864

    local kFmodVolumePropertyIndex = 1
    local kFmodPitchPropertyIndex = 4
    local kFmodRolloffPropertyIndex = 16
    local kFmodMinDistancePropertyIndex = 17
    local kFmodMaxDistancePropertyIndex = 18

    local kFmodPositioningPropertyIndex = 19
    local kFmodWorldRelative = 524288
    local kFmodHeadRelative = 262144

    function AmbientSound:StartPlaying()

        if(not self.playing) then

            // Start playing sound locally only    
            if self.eventNameIndex == nil then
                self.eventNameIndex = Shared.GetSoundIndex(self.eventName)
            end
            
            Client.PlayLocalSoundWithIndex(self.eventNameIndex, self:GetOrigin())
            
            local listenerOrigin = self:GetOrigin()
            if(self.positioning == 2) then
                listenerOrigin = Vector(0, 0, 0)
            end
            
            local positioningType = ConditionalValue(self.positioning == 1, kFmodWorldRelative, kFmodHeadRelative)
            Client.SetSoundPropertyInt(listenerOrigin, self.eventNameIndex, kFmodPositioningPropertyIndex, positioningType, true)
           
            // Set extended FMOD property values according to values in ambient sound entity
            Client.SetSoundPropertyInt(listenerOrigin, self.eventNameIndex, kFmodRolloffPropertyIndex, kFmod3DSound, true)
            
            local rolloffType = kFmodLogarithmicRolloff
            if self.falloffType == 2 then
                rolloffType = kFmodLinearRolloff
            elseif self.falloffType == 3 then
                rolloffType = kFmodCustomRolloff
            end
            Client.SetSoundPropertyInt(listenerOrigin, self.eventNameIndex, kFmodRolloffPropertyIndex, rolloffType, true)
            
            Client.SetSoundPropertyFloat(listenerOrigin, self.eventNameIndex, kFmodMinDistancePropertyIndex, self.minFalloff, true)
            Client.SetSoundPropertyFloat(listenerOrigin, self.eventNameIndex, kFmodMaxDistancePropertyIndex, self.maxFalloff, true)
            
            Client.SetSoundPropertyFloat(listenerOrigin, self.eventNameIndex, kFmodVolumePropertyIndex, self.volume, true)
            Client.SetSoundPropertyFloat(listenerOrigin, self.eventNameIndex, kFmodPitchPropertyIndex, self.pitch, true)
                
            self.playing = true
            
        end
        
    end

    function AmbientSound:StopPlaying()

        if(self.playing) then
        
            Client.StopLocalSoundWithIndex(self.eventNameIndex, self:GetOrigin())
            self.playing = false
            
        end
        
    end

end

