// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUISquad.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// Draws your current squad and squad info on the marine HUD. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUISquad' (GUIScript)

GUISquad.kPlayerNameFontSize = 14
GUISquad.kLeftInset = 10
GUISquad.kBottomInset = 100
GUISquad.kPlayerNameHeightMargin = 4        // Extra space between player names
GUISquad.kPlayerNameWidthMargin = 6         // Extra margin to left and right of player names
GUISquad.kBackgroundTransparency = .4

function GUISquad:Initialize()

    // Create panel
    self.squadPanelItem = self:CreateBackground()

    // Create text item for each potential squad mate
    self.playerNameItems = {}
    for i = 1, kMaxSquadSize do
        table.insert(self.playerNameItems, self:CreatePlayerNameItem())
    end
    
    self.playerIdsInSquad = {}
    
end

function GUISquad:CreateBackground()

    local background = GUIManager:CreateGraphicItem()
    
    background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    background:SetPosition(Vector(GUISquad.kLeftInset, -GUISquad.kBottomInset, 0))
    
    return background
    
end

function GUISquad:CreatePlayerNameItem()

    local playerNameItem = GUIManager:CreateTextItem()
    
    playerNameItem:SetFontSize(GUISquad.kPlayerNameFontSize)
    playerNameItem:SetFontIsBold(true)
    playerNameItem:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    playerNameItem:SetTextAlignmentX(GUIItem.Align_Center)
    playerNameItem:SetTextAlignmentY(GUIItem.Align_Min)

    return playerNameItem
    
end

function GUISquad:Uninitialize()

    GUI.DestroyItem(self.squadPanelItem)
    self.squadPanelItem = nil
    
    for index, playerNameItem in ipairs(self.playerNameItems) do
        GUI.DestroyItem(playerNameItem)
    end
    table.clear(self.playerNameItems)
    
end

function GUISquad:SetIsVisible(state)

    self.squadPanelItem:SetIsVisible(state)
    
    for index, playerNameItem in ipairs(self.playerNameItems) do
        playerNameItem:SetIsVisible(state)
    end
    
end

function GUISquad:ComputeSquadInfo()

    local player = Client.GetLocalPlayer()
    local localSquadIndex = player:GetSquad()

    // On entering, leaving, changing squad
    if self.clientLocalSquad ~= localSquadIndex then
    
        local destColor = Color(0, 0, 0, 0)
        
        if localSquadIndex > 0 then
            destColor = GetColorForSquad(localSquadIndex)
            destColor = Color(destColor[1]/255, destColor[2]/255, destColor[3]/255, GUISquad.kBackgroundTransparency)
        end
        
        local startColor = Color(self.squadPanelItem:GetColor())
        
        //Print("StartAnim(%s => %s)", ToString(startColor), ToString(destColor))
        
        GetGUIManager():StartAnimation(self.squadPanelItem, GUISetColor, startColor, destColor, .75, kAnimFlagSin)
        
        self.clientLocalSquad = localSquadIndex    
        
    end
    
    // Now compute players in our squad, but not if we're fading in our out the panel
    self.playerIdsInSquad = {}    
    local playerIndex
    for playerIndex = 1, kMaxSquadSize do    
        self.playerNameItems[playerIndex]:SetText("")        
    end

    for playerIndex, marine in ipairs( GetEntitiesForTeam("Marine", player:GetTeamNumber()) ) do
    
        if marine:GetSquad() == localSquadIndex and (marine ~= player) then
        
            table.insert(self.playerIdsInSquad, marine:GetId())
            local numberPlayerIdsInSquad = table.count(self.playerIdsInSquad)
            // This check shouldn't be needed but adding it just in case.
            if numberPlayerIdsInSquad <= table.count(self.playerNameItems) then
                self.playerNameItems[numberPlayerIdsInSquad]:SetText(ToString(marine:GetName()))
            end
            
        end
        
    end  
    
    //Print("Found %d marines in squad", table.count(self.playerIdsInSquad))
    
end

// Update name and visibility in squad indicator
function GUISquad:UpdateSquadInfo()

    local numPlayersInList = table.count(self.playerIdsInSquad)
    
    local maxWidth = 0
    local totalHeight = 0 
    
    for index, marineId in ipairs(self.playerIdsInSquad) do
    
        // This check shouldn't be needed but adding it just in case.
        if index <= table.count(self.playerNameItems) then
        
            local playerNameItem = self.playerNameItems[index]
            local player = Shared.GetEntity(marineId)
            
            if player then
            
                local playerName = ToString(player:GetName())
                //playerNameItem:SetText(playerName)

                // Set position so always centered
                local textWidth = playerNameItem:GetTextWidth(playerName)
                local textHeight = playerNameItem:GetTextHeight(playerName)
                local x = GUISquad.kLeftInset + GUISquad.kPlayerNameWidthMargin + textWidth/2
                local y = GUISquad.kBottomInset + index * (textHeight + GUISquad.kPlayerNameHeightMargin)
                playerNameItem:SetPosition(Vector(x, -y, 0))
                
                if textWidth > maxWidth then
                    maxWidth = textWidth
                end
                totalHeight = totalHeight + textHeight + GUISquad.kPlayerNameHeightMargin
                
                // Fade out player name as they take damage
                local textColorComponent = .4 + player:GetHealthScalar()*.6
                playerNameItem:SetColor(Color(textColorComponent, textColorComponent, textColorComponent, textColorComponent))
                
            end
            
        end
        
    end
    
    // Update size of background
    //Print("SetWidth/height: %.2f/%2.f", maxWidth + 2*GUISquad.kPlayerNameWidthMargin, totalHeight)
    if maxWidth > 0 and totalHeight > 0 then
        self.squadPanelItem:SetSize(Vector(maxWidth + 2*GUISquad.kPlayerNameWidthMargin, totalHeight, 0))
        self.squadPanelItem:SetPosition(Vector(GUISquad.kLeftInset, - GUISquad.kBottomInset - totalHeight, 0))
    end
    
end

function GUISquad:Update(deltaTime)   

    PROFILE("GUISquad:Update")

    local player = Client.GetLocalPlayer()
    if player and player:isa("Marine") then
    
        if self.timeLastUpdate == nil or (Shared.GetTime() > self.timeLastUpdate + .5) then
        
            self:ComputeSquadInfo()            
            self.timeLastUpdate = Shared.GetTime()
            
        end
        
        self:UpdateSquadInfo()
        
        self:SetIsVisible(true)
        
    else
        self:SetIsVisible(false)
    end
    
end

