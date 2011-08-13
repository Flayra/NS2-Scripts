// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Scan.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Invisible entity that gives LOS to marine team for a short time. Also used to parent
// the particle system to.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")

class 'Scan' (Structure)

Scan.kMapName = "scan"

Scan.kScanEffect = PrecacheAsset("cinematics/marine/observatory/scan.cinematic")

Scan.kScanDistance = kScanRadius

kScanEffectInterval = 0.2

function Scan:OnInit()

    Structure.OnInit(self)
    
    if Client then
    
        self:SetUpdates(true)
        
        // Glowing growing circles
        self.scanEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        
        self.scanEffect:SetCinematic(Scan.kScanEffect)
        
        self.scanEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        
    end
    
    self:SetIsVisible(false)
    
    self:SetNextThink(kScanEffectInterval)
    
    self.endOfLifeTime = Shared.GetTime() + kScanDuration
end

function Scan:OnThink()

    if (Server) then
        for _, target in ipairs(GetEntitiesForTeamWithinRange("ScriptActor", kAlienTeamType, self:GetOrigin(), Scan.kScanDistance)) do
            if target.OnScan then
                target:OnScan()
            end
            target:SetSighted(true)
        end
        self:SetNextThink(kScanEffectInterval)
        if Shared.GetTime() >= self.endOfLifeTime then
            DestroyEntity(self)
        end
    end
end

function Scan:OnDestroy()

    if Client and self.scanEffect then
        Client.DestroyCinematic(self.scanEffect)
        self.scanEffect = nil
    end
    
    Structure.OnDestroy(self)

end

if Client then

    function Scan:OnUpdate(deltaTime)
    
        if self.scanEffect ~= nil and self:GetId() ~= Entity.invalidId then
        
            Structure.OnUpdate(self, deltaTime)
            
            local coords = Coords.GetIdentity()
            coords.origin = self:GetOrigin()
            self.scanEffect:SetCoords(coords)
            
        end 
       
    end
    
end

function Scan:GetRequiresPower()
    return false
end

Shared.LinkClassToMap("Scan", Scan.kMapName, {})