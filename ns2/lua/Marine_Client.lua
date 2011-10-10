// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Marine.k2DHUDFlash = "ui/marine_hud_2d.swf"
Marine.kBuyMenuTexture = "ui/marine_buymenu.dds"
Marine.kBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
Marine.kBuyMenuiconsTexture = "ui/marine_buy_icons.dds"

// These should be removed once the Marine buy menu is not Flash anymore.
Client.BindFlashTexture("marine_buymenu", Marine.kBuyMenuTexture)
Client.BindFlashTexture("marine_buymenu_upgrades", Marine.kBuyMenuUpgradesTexture)
Client.BindFlashTexture("marine_buy_icons", Marine.kBuyMenuiconsTexture)

function Marine:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    if self:GetTeamNumber() ~= kTeamReadyRoom then

        if self.marineHUD == nil then
            self.marineHUD = GetGUIManager():CreateGUIScript("GUIMarineHUD")
        end
        
        if self.waypoints == nil then
            self.waypoints = GetGUIManager():CreateGUIScript("GUIWaypoints")
        end
        
        if self.pickups == nil then
            self.pickups = GetGUIManager():CreateGUIScript("GUIPickups")
        end
        
        if self.guiOrders == nil then
            self.guiOrders = GetGUIManager():CreateGUIScript("GUIOrders")
        end
        
        if self.guiSquad == nil then
            self.guiSquad = GetGUIManager():CreateGUIScript("GUISquad")
        end
        
        if self.guiDistressBeacon == nil then
            self.guiDistressBeacon = GetGUIManager():CreateGUIScript("GUIDistressBeacon")
        end
        
    end
    
end

function Marine:UpdateClientEffects(deltaTime, isLocal)
    
    Player.UpdateClientEffects(self, deltaTime, isLocal)

    // Synchronize the state of the light representing the flash light.
    self.flashlight:SetIsVisible( self.flashlightOn )

    if (self.flashlightOn) then
    
        local coords = Coords(self:GetViewCoords())
        coords.origin = coords.origin + coords.zAxis * 0.75
        
        self.flashlight:SetCoords( coords )
        
    end
    
    // If we're too far from an armory or dead, close the menu
    if isLocal then
    
        self.screenEffects.disorient:SetParameter("time", Client.GetTime())
   
        if GetFlashPlayerDisplaying(kClassFlashIndex) then
            if not GetArmory(self) or not self:GetIsAlive() then
                self:CloseMenu(kClassFlashIndex)
            end
        end
        
        if self.showingBuyMenu then
            self:SetBlurEnabled( true )
        else
            self:SetBlurEnabled( false )
        end
        
    end
    
end

function Marine:CloseMenu(flashIndex)

    if self.showingBuyMenu then
        
        if Player.CloseMenu(self, flashIndex) then
        
            Shared.StopSound(self, Armory.kResupplySound)
            
            self.showingBuyMenu = false
            
            return true
            
        end
            
    end
   
    return false
    
end
