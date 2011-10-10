// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Infestation.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Patch of infestation created by alien commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Infestation.kClientGeometryUpdateRate = 10

// this is not an absolute number, just the "attempts" to find a place for infestation geometry
Infestation.kNumInfestationCinematics = 60

// floating point accuracy for finding a place
Infestation.kCoordAccuracy = 100

// maximum offest from source position
Infestation.kCinematicMaxOffset = 4
Infestation.kCinematicMinOffset = 0.2

Infestation.kGeometryCinematics =
{
    PrecacheAsset("cinematics/alien/infestation/infestation1.cinematic"),
    PrecacheAsset("cinematics/alien/infestation/infestation2.cinematic"),
    PrecacheAsset("cinematics/alien/infestation/infestation3.cinematic")
}

// calculates coordinates for the infestation cinematics, so it's only done once (once when you see it)
function Infestation:InitClientGeometry()

    self.infestationCoords = { }
    local xOffset = 0
    local zOffset = 0

    for j = 1, Infestation.kNumInfestationCinematics do
    
        local hostCoords = self:GetCoords()
        local startPoint = hostCoords.origin + hostCoords.yAxis * 0.2
        
        local xDirection = 1
        local yDirection = 1
        
        if math.random(-2, 1) < 0 then
            xDirection = -1
        end
        
        if math.random(-2, 1) < 0 then
            yDirection = -1
        end
        
        xOffset = (math.random(Infestation.kCinematicMinOffset*Infestation.kCoordAccuracy, Infestation.kCinematicMaxOffset*Infestation.kCoordAccuracy) / Infestation.kCoordAccuracy) * xDirection
        zOffset = (math.random(Infestation.kCinematicMinOffset*Infestation.kCoordAccuracy, Infestation.kCinematicMaxOffset*Infestation.kCoordAccuracy) / Infestation.kCoordAccuracy) * yDirection
        
        startPoint = startPoint + hostCoords.xAxis * xOffset
        startPoint = startPoint + hostCoords.zAxis * zOffset
        
        local endPoint = startPoint - hostCoords.yAxis * 1
        local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.Bullets, EntityFilterAll())
        
        local angles = Angles(0, 0, 0)
        angles.yaw = GetYawFromVector(trace.normal)
        angles.pitch = GetPitchFromVector(trace.normal) + (math.pi / 2)
        
        local normalCoords = angles:GetCoords()
        normalCoords.origin = trace.endPoint
        
        if trace.endPoint ~= endPoint then
            table.insert(self.infestationCoords, CopyCoords(normalCoords))
        end
    
    end

end

function Infestation:UpdateGeometryVisibility()

    local numberVisible = 0
    
    if self.infestationCinematics ~= nil then
    
        for index, infestation in ipairs(self.infestationCinematics) do
        
            local origin = infestation.Coords.origin
            local distanceSquared = (origin - self:GetOrigin()):GetLengthSquared()
            if distanceSquared < (self.radius * self.radius) then
            
                infestation.Cinematic:SetIsVisible(true)
                numberVisible = numberVisible + 1
            
            end
            
        end
        
    end
    
    // Keep this callback going as long as there are more to reveal.
    return numberVisible < #self.infestationCinematics

end

function Infestation:CreateClientGeometry()

    self.infestationCinematics = { }
    local numCinematicVariations = table.count(Infestation.kGeometryCinematics)
    
    if self.infestationCoords == nil or table.count(self.infestationCoords) == 0 then
        self:InitClientGeometry()
    end
    
    for index, coords in ipairs(self.infestationCoords) do

        local cinematic = Infestation.kGeometryCinematics[(index % numCinematicVariations) + 1]
        
        local infestationCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        infestationCinematic:SetRepeatStyle(Cinematic.Repeat_Loop)
        infestationCinematic:SetCinematic(cinematic)
        infestationCinematic:SetCoords(coords)
        infestationCinematic:SetIsVisible(false)
        
        table.insert(self.infestationCinematics, { Cinematic = infestationCinematic, Coords = coords, Visible = false })
        
    end
    
    self:AddTimedCallback(Infestation.UpdateGeometryVisibility, 1)
    
end

function Infestation:DestroyClientGeometry()

    if self.infestationCinematics ~= nil then
    
        for index, infestationCinematic in ipairs(self.infestationCinematics) do
            Client.DestroyCinematic(infestationCinematic.Cinematic)
        end
        
        self.infestationCinematics = nil
        
    end

end