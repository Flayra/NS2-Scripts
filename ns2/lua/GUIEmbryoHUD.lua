// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIEmbryoHUD.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// Draw gestation percentage when evolving.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIDial.lua")

class 'GUIEmbryoHUD' (GUIScript)

GUIEmbryoHUD.kTextFontName = "MicrogrammaDMedExt"
GUIEmbryoHUD.kFontColor = Color(0.8, 0.4, 0.4, 1)
GUIEmbryoHUD.kHealthTextFontSize = 16
GUIEmbryoHUD.kHealthTextYOffset = 20

function GUIEmbryoHUD:Initialize()

    self.evolveText = GUIManager:CreateTextItem()
    self.evolveText:SetFontSize(GUIEmbryoHUD.kHealthTextFontSize)
    self.evolveText:SetFontName(GUIEmbryoHUD.kTextFontName)
    self.evolveText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.evolveText:SetPosition(Vector(0, GUIEmbryoHUD.kHealthTextYOffset, 0))
    self.evolveText:SetTextAlignmentX(GUIItem.Align_Center)
    self.evolveText:SetTextAlignmentY(GUIItem.Align_Center)
    self.evolveText:SetColor(GUIEmbryoHUD.kFontColor)

end

function GUIEmbryoHUD:Uninitialize()

    if self.evolveText then
    
        GUI.DestroyItem(self.evolveText)
        self.evolveText = nil
        
    end
    
end

function GUIEmbryoHUD:Update(deltaTime)

    PROFILE("GUIEmbryoHUD:Update")

    if self.evolveText then
    
        local player = Client.GetLocalPlayer()
        
        if player and player:isa("Embryo") then
            self.evolveText:SetText(string.format("Evolving %d%%...", math.floor(player.evolvePercentage)))
        end
        
    end
    
end

