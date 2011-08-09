// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Reverb.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Point entity placed in the map editor that specifies which reverb settings to use
// from FMOD Designer. Specifies reverb settings name, min radius and max radius.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'Reverb' 

Reverb.kMapName = "reverb"

// Array for looking up hard-coded reverb (change this to a string when game supports networked strings)
// Change editor input.txt when changing these so they synch up.
kReverbNames = {"generic", "hallway", "vent", "medium room", "large room", "big hallway"}

local networkVars   = {
    reverbType      = "integer (0 to 8)",
    minRadius       = "float",
    maxRadius       = "float"        
}

function Reverb:SetOrigin(newOrigin)

    self.origin = Vector()
    VectorCopy(newOrigin, self.origin)

end

function Reverb:SetAngles(newAngles)
end

// Normally called only on server but not in this case
function Reverb:OnLoad()

    if(not self.createdReverb and self.minRadius ~= nil and self.maxRadius ~= nil) then
    
        local reverbName = kReverbNames[self.reverbType]
        Client.CreateReverb("sound/ns2.fev/" .. reverbName, self:GetOrigin(), self.minRadius, self.maxRadius)
        self.createdReverb = true
        
    end
    
end

function Reverb:GetOrigin()
    return self.origin
end
