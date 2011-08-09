// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Spectator_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Spectator:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    if self.guiDistressBeacon == nil then
        self.guiDistressBeacon = GetGUIManager():CreateGUIScript("GUIDistressBeacon")
    end

end

function Spectator:OnDestroyClient()

    Player.OnDestroyClient(self)
    
    if self.guiDistressBeacon then
        GetGUIManager():DestroyGUIScript(self.guiDistressBeacon)
        self.guiDistressBeacon = nil
    end

end