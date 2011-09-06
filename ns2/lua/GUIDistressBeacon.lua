// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDistressBeacon.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// Draw distress beacon alert for marines, dead players and marine commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIDistressBeacon' (GUIScript)

GUIDistressBeacon.kBeaconTextFontSize = 24
GUIDistressBeacon.kBeaconTextOffset = Vector(0, -50, 0)
GUIDistressBeacon.kCommanderBeaconTextOffset = Vector(0, -290, 0)
GUIDistressBeacon.kTextFontName = "MicrogrammaDBolExt"

function GUIDistressBeacon:Initialize()

    self.beacon = GUIManager:CreateTextItem()
    self.beacon:SetFontSize(GUIDistressBeacon.kBeaconTextFontSize)
    self.beacon:SetFontName(GUIDistressBeacon.kTextFontName)
    self.beacon:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.beacon:SetTextAlignmentX(GUIItem.Align_Center)
    self.beacon:SetTextAlignmentY(GUIItem.Align_Center)
    self.beacon:SetIsVisible(false)
    
end

function GUIDistressBeacon:Uninitialize()

    GUI.DestroyItem(self.beacon)
    self.beacon = nil
    
end

function GUIDistressBeacon:UpdateDistressBeacon(deltaTime)

    PROFILE("GUIDistressBeacon:Update")

    local localPlayer = Client.GetLocalPlayer()
    
    if localPlayer then
    
        local beaconing = PlayerUI_GetIsBeaconing()
        local alpha = 0
        
        if self.beacon:GetIsVisible() ~= beaconing then
        
            self.beacon:SetIsVisible(beaconing)
            
            if beaconing then
                self.beaconTime = Shared.GetTime()
            end
            
        end
        
        if localPlayer:isa("Commander") then
            self.beacon:SetPosition(GUIDistressBeacon.kCommanderBeaconTextOffset)
            self.beacon:SetText(Locale.ResolveString("BEACONING_COMMANDER"))
        else
            self.beacon:SetPosition(GUIDistressBeacon.kBeaconTextOffset)
            self.beacon:SetText(Locale.ResolveString("BEACONING"))
        end

        if self.beacon:GetIsVisible() then
        
            // Fade alpha in and out dramatically
            local sin = math.sin((Shared.GetTime() - self.beaconTime) * 5/(math.pi/2))
            alpha = math.abs(sin)
            
        end
        
        self.beacon:SetColor(Color(kMarineTeamColorFloat.r, kMarineTeamColorFloat.g, kMarineTeamColorFloat.b, alpha))
        
    else
        self.beacon:SetIsVisible(false)
    end
    
end

function GUIDistressBeacon:Update(deltaTime)

    self:UpdateDistressBeacon(deltaTime)
    
end

