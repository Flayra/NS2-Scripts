// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommander_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/MarineCommander_SquadSelection.lua")

MarineCommander.kMenuFlash = "ui/commander-mark2.swf"

function MarineCommander:OnInitLocalClient()

    Commander.OnInitLocalClient(self)
    
    self:InitSquadSelectionScreenEffects()
    
    if self.guiDistressBeacon == nil then
        self.guiDistressBeacon = GetGUIManager():CreateGUIScript("GUIDistressBeacon")
    end
    
end

// Called commander clicks squad element
function MarineCommander:ClientSelectSquad(index)

    // So select squad command is sent to server
    self.selectSquad = index    

end

function MarineCommander:OverrideInput(input)

    input = Commander.OverrideInput(self, input)
    
    if self.selectSquad ~= nil and self.selectSquad >= 1 and self.selectSquad <= 5 then
    
        // Process squad select and send up to server
        input.commands = bit.bor(input.commands, Move.Weapon1 + self.selectSquad - 1)
        input.commands = bit.bor(input.commands, Move.MovementModifier)
        
        self.selectSquad = nil
        
    end    
    
    return input
    
end

function MarineCommander:SetSelectionCircleMaterial(entity)
 
    if(entity:isa("Structure") and not entity:GetIsBuilt()) then
    
        SetMaterialFrame("marineBuild", entity.buildFraction)

    else

        // Allow entities without health to be selected (infest nodes)
        local healthPercent = 1
        if(entity.health ~= nil and entity.maxHealth ~= nil) then
            healthPercent = entity.health / entity.maxHealth
        end
        
        SetMaterialFrame("marineHealth", healthPercent)

    end
   
end

// Only called when not running prediction
function MarineCommander:UpdateClientEffects(deltaTime, isLocal)

    Commander.UpdateClientEffects(self, deltaTime, isLocal)
    
    if isLocal then
        
        // Highlight squad under cursor
        local xScalar, yScalar = Client.GetCursorPos()
        local highlightSquad = self:GetSquadBlob(Vector(xScalar, yScalar, 0))
        self:UpdateSquadScreenEffects(highlightSquad, self.selectSquad)
        
    end
    
end