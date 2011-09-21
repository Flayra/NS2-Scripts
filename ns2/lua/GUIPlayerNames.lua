// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIPlayerNames.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// Draw names of players above their heads for commanders.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIPlayerNames' (GUIScript)

GUIPlayerNames.kMaxNames = kMaxPlayers/2
GUIPlayerNames.kMarineTextColor = Color(.30, .69, 1, .75)
GUIPlayerNames.kAlienTextColor = Color(1, .79, .227, .75)
GUIPlayerNames.kFontSize = 16

function GUIPlayerNames:Initialize()

    self.playerNameItemList = {}
    self.playerIdList = {}
    
    local player = Client.GetLocalPlayer()
    local color = ConditionalValue(player:isa("AlienCommander"), GUIPlayerNames.kAlienTextColor, GUIPlayerNames.kMarineTextColor)
    
    for i = 1, GUIPlayerNames.kMaxNames do
    
        local playerNameItem = GUIManager:CreateTextItem()
        
        playerNameItem:SetFontSize(GUIPlayerNames.kFontSize)
        playerNameItem:SetFontIsBold(true)
        playerNameItem:SetTextAlignmentX(GUIItem.Align_Center)
        playerNameItem:SetTextAlignmentY(GUIItem.Align_Min)
        playerNameItem:SetIsVisible(false)
        playerNameItem:SetColor(color)

        table.insert(self.playerNameItemList, playerNameItem)
        
    end 
   
end

function GUIPlayerNames:Uninitialize()

    for i, playerNameItem in ipairs(self.playerNameItemList) do
        GUI.DestroyItem(playerNameItem)
    end
    
    self.playerNameItemList = nil
    self.playerIdList = nil
    
end

function GUIPlayerNames:Update(deltaTime)

    PROFILE("GUIPlayerNames:Update")

    local player = Client.GetLocalPlayer()
    if not player then
        return 
    end
    
    // Every so often, update player id list and names of players
    if (self.timeOfLastNameIdUpdate == nil) or (Shared.GetTime() > self.timeOfLastNameIdUpdate + .75) then
    
        self.playerIdList = {}
        
        local players = GetEntitiesForTeam("Player", player:GetTeamNumber())
        for index, currentPlayer in ipairs(players) do

            if currentPlayer:GetIsAlive() and not currentPlayer:isa("Commander") then
            
                table.insert(self.playerIdList, currentPlayer:GetId())
     
            end

        end
        
        self.timeOfLastNameIdUpdate = Shared.GetTime()

    end
    
    local numVis = 0
    
    // Every tick, update position of player name to be where player is
    for index, playerId in ipairs(self.playerIdList) do
    
        // Offset below player a tad
        local player = Shared.GetEntity(playerId)
        if player ~= nil then
            local position = Client.WorldToScreen(player:GetOrigin() - Vector(.5, 0, 0))
            self.playerNameItemList[index]:SetText(ToString(player:GetName()))
            self.playerNameItemList[index]:SetPosition(Vector(position.x, position.y, 0))
            self.playerNameItemList[index]:SetIsVisible(true)
            numVis = numVis + 1
        else
            self.playerNameItemList[index]:SetIsVisible(false)
        end
        
    end
    
    // Set the rest invisible
    for index = table.count(self.playerIdList) + 1, GUIPlayerNames.kMaxNames do
        self.playerNameItemList[index]:SetIsVisible(false)
    end
    
end

