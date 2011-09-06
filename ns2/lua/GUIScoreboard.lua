
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIScoreboard.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the player scoreboard (scores, pings, etc).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIScoreboard' (GUIScript)

GUIScoreboard.kClickForMouseBackgroundSize = Vector(GUIScale(200), GUIScale(32), 0)
GUIScoreboard.kClickForMouseTextSize = GUIScale(22)
GUIScoreboard.kClickForMouseText = "Click for mouse"

// Shared constants.
GUIScoreboard.kFontName = "Calibri"
GUIScoreboard.kLowPingThreshold = 100
GUIScoreboard.kLowPingColor = Color(0, 1, 0, 1)
GUIScoreboard.kMedPingThreshold = 249
GUIScoreboard.kMedPingColor = Color(1, 1, 0, 1)
GUIScoreboard.kHighPingThreshold = 499
GUIScoreboard.kHighPingColor = Color(1, 0.5, 0, 1)
GUIScoreboard.kInsanePingColor = Color(1, 0, 0, 1)
GUIScoreboard.kVoiceMuteColor = Color(1, 0, 0, 0.5)
GUIScoreboard.kVoiceDefaultColor = Color(1, 1, 1, 0.5)

// Team constants.
GUIScoreboard.kTeamNameFontSize = 26
GUIScoreboard.kTeamInfoFontSize = 16
GUIScoreboard.kTeamItemWidth = 500 + 150
GUIScoreboard.kTeamItemHeight = GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize + 8
GUIScoreboard.kTeamSpacing = 32
GUIScoreboard.kTeamScoreColumnStartX = 250
GUIScoreboard.kTeamColumnSpacingX = 50

// Player constants.
GUIScoreboard.kPlayerStatsFontSize = 16
GUIScoreboard.kPlayerItemWidthBuffer = 10
GUIScoreboard.kPlayerItemHeight = 32
GUIScoreboard.kPlayerSpacing = 4
GUIScoreboard.kPlayerVoiceChatIconSize = 20

// Color constants.
GUIScoreboard.kBlueColor = ColorIntToColor(kMarineTeamColor)
GUIScoreboard.kBlueHighlightColor = Color(0.30, 0.69, 1, 1)
GUIScoreboard.kRedColor = ColorIntToColor(kAlienTeamColor)
GUIScoreboard.kRedHighlightColor = Color(1, 0.79, 0.23, 1)
GUIScoreboard.kSpectatorColor = ColorIntToColor(kNeutralTeamColor)
GUIScoreboard.kSpectatorHighlightColor = Color(0.8, 0.8, 0.8, 1)

function GUIScoreboard:Initialize()
    
    self.teams = { }
    self.reusePlayerItems = { }
    
    // Teams table format: Team GUIItems, color, player GUIItem list, get scores function.
    // Blue team.
    table.insert(self.teams, { GUIs = self:CreateTeamBackground(GUIScoreboard.kBlueColor), TeamName = ScoreboardUI_GetBlueTeamName(),
                               Color = GUIScoreboard.kBlueColor, PlayerList = { }, HighlightColor = GUIScoreboard.kBlueHighlightColor,
                               GetScores = ScoreboardUI_GetBlueScores, TeamNumber = kTeam1Index})

    // Red team.
    table.insert(self.teams, { GUIs = self:CreateTeamBackground(GUIScoreboard.kRedColor), TeamName = ScoreboardUI_GetRedTeamName(),
                               Color = GUIScoreboard.kRedColor, PlayerList = { }, HighlightColor = GUIScoreboard.kRedHighlightColor,
                               GetScores = ScoreboardUI_GetRedScores, TeamNumber = kTeam2Index })

    // Spectator team.
    table.insert(self.teams, { GUIs = self:CreateTeamBackground(GUIScoreboard.kSpectatorColor), TeamName = ScoreboardUI_GetSpectatorTeamName(),
                               Color = GUIScoreboard.kSpectatorColor, PlayerList = { }, HighlightColor = GUIScoreboard.kSpectatorHighlightColor,
                               GetScores = ScoreboardUI_GetSpectatorScores, TeamNumber = kTeamReadyRoom })

    self.playerHighlightItem = GUIManager:CreateGraphicItem()
    self.playerHighlightItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0))
    self.playerHighlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.playerHighlightItem:SetColor(Color(1, 1, 1, 1))
    self.playerHighlightItem:SetTexture("ui/hud_elements.dds")
    self.playerHighlightItem:SetTextureCoordinates(0, 0.16, 0.558, 0.32)
    self.playerHighlightItem:SetIsVisible(false)
    
    self.clickForMouseBackground = GUIManager:CreateGraphicItem()
    self.clickForMouseBackground:SetSize(GUIScoreboard.kClickForMouseBackgroundSize)
    self.clickForMouseBackground:SetPosition(Vector(-GUIScoreboard.kClickForMouseBackgroundSize.x / 2, 10, 0))
    self.clickForMouseBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.clickForMouseBackground:SetIsVisible(false)
    
    self.clickForMouseIndicator = GUIManager:CreateTextItem()
    self.clickForMouseIndicator:SetFontName(GUIScoreboard.kFontName)
    self.clickForMouseIndicator:SetFontSize(GUIScoreboard.kClickForMouseTextSize)
    self.clickForMouseIndicator:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.clickForMouseIndicator:SetTextAlignmentX(GUIItem.Align_Center)
    self.clickForMouseIndicator:SetTextAlignmentY(GUIItem.Align_Center)
    self.clickForMouseIndicator:SetColor(Color(0, 0, 0, 1))
    self.clickForMouseIndicator:SetText(GUIScoreboard.kClickForMouseText)
    self.clickForMouseBackground:AddChild(self.clickForMouseIndicator)
    
    self.mousePressed = { LMB = { Down = nil }, RMB = { Down = nil } }

end

function GUIScoreboard:Uninitialize()

    for index, team in ipairs(self.teams) do
        GUI.DestroyItem(team["GUIs"]["Background"])
    end
    self.teams = { }
    
    for index, playerItem in ipairs(self.reusePlayerItems) do
        GUI.DestroyItem(playerItem["Background"])
    end
    self.reusePlayerItems = { }
    
    GUI.DestroyItem(self.clickForMouseIndicator)
    self.clickForMouseIndicator = nil
    GUI.DestroyItem(self.clickForMouseBackground)
    self.clickForMouseBackground = nil
    
    
end

function GUIScoreboard:CreateTeamBackground(color)

    // Create background.
    local teamItem = GUIManager:CreateGraphicItem()
    teamItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth, GUIScoreboard.kTeamItemHeight, 0))
    teamItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
    teamItem:SetPosition(Vector(-GUIScoreboard.kTeamItemWidth / 2, -GUIScoreboard.kTeamItemHeight / 2, 0))
    teamItem:SetColor(Color(0, 0, 0, 0.75))
    teamItem:SetIsVisible(ScoreboardUI_GetVisible())
    
    // Team name text item.
    local teamNameItem = GUIManager:CreateTextItem()
    teamNameItem:SetFontName(GUIScoreboard.kFontName)
    teamNameItem:SetFontSize(GUIScoreboard.kTeamNameFontSize)
    teamNameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamNameItem:SetTextAlignmentX(GUIItem.Align_Min)
    teamNameItem:SetTextAlignmentY(GUIItem.Align_Min)
    teamNameItem:SetPosition(Vector(5, 5, 0))
    teamNameItem:SetColor(color)
    teamItem:AddChild(teamNameItem)
    
    // Add team info (team resources and number of players)
    local teamInfoItem = GUIManager:CreateTextItem()
    teamInfoItem:SetFontName(GUIScoreboard.kFontName)
    teamInfoItem:SetFontSize(GUIScoreboard.kTeamInfoFontSize)
    teamInfoItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    teamInfoItem:SetTextAlignmentX(GUIItem.Align_Min)
    teamInfoItem:SetTextAlignmentY(GUIItem.Align_Min)
    teamInfoItem:SetPosition(Vector(15, GUIScoreboard.kTeamNameFontSize, 0))
    teamInfoItem:SetColor(color)
    teamItem:AddChild(teamInfoItem)
    
    local currentColumnX = GUIScoreboard.kTeamScoreColumnStartX
    
    // Status text item.
    local statusItem = GUIManager:CreateTextItem()
    statusItem:SetFontName(GUIScoreboard.kFontName)
    statusItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    statusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    statusItem:SetTextAlignmentX(GUIItem.Align_Min)
    statusItem:SetTextAlignmentY(GUIItem.Align_Min)
    statusItem:SetPosition(Vector(currentColumnX, 5, 0))
    statusItem:SetColor(color)
    statusItem:SetText("")
    teamItem:AddChild(statusItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 3
    
    // Score text item.
    local scoreItem = GUIManager:CreateTextItem()
    scoreItem:SetFontName(GUIScoreboard.kFontName)
    scoreItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    scoreItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    scoreItem:SetTextAlignmentX(GUIItem.Align_Min)
    scoreItem:SetTextAlignmentY(GUIItem.Align_Min)
    scoreItem:SetPosition(Vector(currentColumnX, 5, 0))
    scoreItem:SetColor(color)
    scoreItem:SetText("Score")
    teamItem:AddChild(scoreItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Kill text item.
    local killsItem = GUIManager:CreateTextItem()
    killsItem:SetFontName(GUIScoreboard.kFontName)
    killsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    killsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    killsItem:SetTextAlignmentX(GUIItem.Align_Min)
    killsItem:SetTextAlignmentY(GUIItem.Align_Min)
    killsItem:SetPosition(Vector(currentColumnX, 5, 0))
    killsItem:SetColor(color)
    killsItem:SetText("Kills")
    teamItem:AddChild(killsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Deaths text item.
    local deathsItem = GUIManager:CreateTextItem()
    deathsItem:SetFontName(GUIScoreboard.kFontName)
    deathsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    deathsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    deathsItem:SetTextAlignmentX(GUIItem.Align_Min)
    deathsItem:SetTextAlignmentY(GUIItem.Align_Min)
    deathsItem:SetPosition(Vector(currentColumnX, 5, 0))
    deathsItem:SetColor(color)
    deathsItem:SetText("Deaths")
    teamItem:AddChild(deathsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Resources text item.
    local resItem = GUIManager:CreateTextItem()
    resItem:SetFontName(GUIScoreboard.kFontName)
    resItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    resItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    resItem:SetTextAlignmentX(GUIItem.Align_Min)
    resItem:SetTextAlignmentY(GUIItem.Align_Min)
    resItem:SetPosition(Vector(currentColumnX , 5, 0))
    resItem:SetColor(color)
    resItem:SetText("  Res")
    teamItem:AddChild(resItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Ping text item.
    local pingItem = GUIManager:CreateTextItem()
    pingItem:SetFontName(GUIScoreboard.kFontName)
    pingItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    pingItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    pingItem:SetTextAlignmentX(GUIItem.Align_Min)
    pingItem:SetTextAlignmentY(GUIItem.Align_Min)
    pingItem:SetPosition(Vector(currentColumnX, 5, 0))
    pingItem:SetColor(color)
    pingItem:SetText("Ping")
    teamItem:AddChild(pingItem)
    
    return { Background = teamItem, TeamName = teamNameItem, TeamInfo = teamInfoItem }
    
end

function GUIScoreboard:Update(deltaTime)

    PROFILE("GUIScoreboard:Update")

    local teamsVisible = ScoreboardUI_GetVisible()
    
    ASSERT(teamsVisible ~= nil)
    
    if not teamsVisible then
        self:_SetMouseVisible(false)
    end
    
    if not self.mouseVisible then
        // Click for mouse only visible when not a commander and when the scoreboard is visible.
        local clickForMouseBackgroundVisible = (not PlayerUI_IsACommander()) and teamsVisible
        self.clickForMouseBackground:SetIsVisible(clickForMouseBackgroundVisible)
        local backgroundColor = PlayerUI_GetTeamColor()
        backgroundColor.a = 0.8
        self.clickForMouseBackground:SetColor(backgroundColor)
    end
    
    //First, update teams.
    for index, team in ipairs(self.teams) do
    
        // Don't draw if no players on team
        local numPlayers = table.count(team["GetScores"]())    
        team["GUIs"]["Background"]:SetIsVisible(teamsVisible and (numPlayers > 0))
        
        if teamsVisible then
            self:UpdateTeam(team)
        end
    end
    
    // Next, position teams.
    if teamsVisible then
        
        local numTeams = table.count(self.teams)
        if numTeams > 0 then
        
            // Count the size the team tables are going to take up on the screen.
            local sizeOfAllTeams = 0
            for index, team in ipairs(self.teams) do
                if team["GUIs"]["Background"]:GetIsVisible() then
                    sizeOfAllTeams = sizeOfAllTeams + team["GUIs"]["Background"]:GetSize().y + GUIScoreboard.kTeamSpacing 
                end
            end
            
            local currentY = -(sizeOfAllTeams / 2)
            for index, team in ipairs(self.teams) do
                local newPosition = Vector(-GUIScoreboard.kTeamItemWidth / 2, 0, 0)
                newPosition.y = currentY
                currentY = currentY + team["GUIs"]["Background"]:GetSize().y + GUIScoreboard.kTeamSpacing
                team["GUIs"]["Background"]:SetPosition(newPosition)
            end
            
        end
        
    end
    
end

function GUIScoreboard:UpdateTeam(updateTeam)
    
    local teamGUIItem = updateTeam["GUIs"]["Background"]
    local teamNameGUIItem = updateTeam["GUIs"]["TeamName"]
    local teamInfoGUIItem = updateTeam["GUIs"]["TeamInfo"]
    local teamNameText = updateTeam["TeamName"]
    local teamColor = updateTeam["Color"]
    local localPlayerHighlightColor = updateTeam["HighlightColor"]
    local playerList = updateTeam["PlayerList"]
    local teamScores = updateTeam["GetScores"]()
    
    local isLocalTeam = false
    local player = Client.GetLocalPlayer()
    if player and player:GetTeamNumber() == updateTeam["TeamNumber"] then
        isLocalTeam = true
    end

    // How many items per player.
    local numPlayers = table.count(teamScores)
    
    // Update the team name text.
    teamNameGUIItem:SetText(string.format("%s (%s)", teamNameText, Pluralize(numPlayers, "Player")))
    
    // Update team resource display
    local teamResourcesString = ConditionalValue(isLocalTeam, string.format("%d team resources", player:GetTeamResources()), "")
    teamInfoGUIItem:SetText(string.format("%s", teamResourcesString))
    
    // Make sure there is enough room for all players on this team GUI.
    teamGUIItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth, (GUIScoreboard.kTeamItemHeight) + ((GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing) * numPlayers), 0))
    
    // Resize the player list if it doesn't match.
    if table.count(playerList) ~= numPlayers then
        self:ResizePlayerList(playerList, numPlayers, teamGUIItem)
    end
    
    local currentY = GUIScoreboard.kTeamNameFontSize + GUIScoreboard.kTeamInfoFontSize
    local currentPlayerIndex = 1
    for index, player in pairs(playerList) do
        local playerRecord = teamScores[currentPlayerIndex]
        local playerName = playerRecord.Name
        local clientIndex = playerRecord.ClientIndex
        local score = playerRecord.Score
        local kills = playerRecord.Kills
        local deaths = playerRecord.Deaths
        local isCommander = playerRecord.IsCommander
        local resourcesStr = ConditionalValue(isLocalTeam, tostring(playerRecord.Resources), "-")
        local ping = playerRecord.Ping
        local pingStr = tostring(ping)
        local currentPosition = Vector(player["Background"]:GetPosition())
        local playerStatus = playerRecord.Status
        local isSpectator = playerRecord.IsSpectator
        
        currentPosition.y = currentY
        player["Background"]:SetPosition(currentPosition)
        player["Background"]:SetColor(teamColor)
        
        // Handle local player highlight
        if ScoreboardUI_IsPlayerLocal(playerName) then
            if self.playerHighlightItem:GetParent() ~= player["Background"] then
                if self.playerHighlightItem:GetParent() ~= nil then
                    self.playerHighlightItem:GetParent():RemoveChild(self.playerHighlightItem)
                end
                player["Background"]:AddChild(self.playerHighlightItem)
                self.playerHighlightItem:SetIsVisible(true)
                self.playerHighlightItem:SetColor(localPlayerHighlightColor)
            end
        end
        
        player["Name"]:SetText(playerName)
        
        // Needed to determine who to (un)mute when voice icon is clicked.
        player["ClientIndex"] = clientIndex
        
        // Voice icon.
        local playerVoiceColor = GUIScoreboard.kVoiceDefaultColor
        if ChatUI_GetClientMuted(clientIndex) then
            playerVoiceColor = GUIScoreboard.kVoiceMuteColor
        elseif ChatUI_GetIsClientSpeaking(clientIndex) then
            playerVoiceColor = teamColor
        end
        player["Voice"]:SetColor(playerVoiceColor)

        player["Score"]:SetText(tostring(score))
        player["Kills"]:SetText(tostring(kills))
        player["Deaths"]:SetText(tostring(deaths))
        player["Status"]:SetText(playerStatus)
        player["Resources"]:SetText(resourcesStr)
        player["Ping"]:SetText(pingStr)
        if ping < GUIScoreboard.kLowPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kLowPingColor)
        elseif ping < GUIScoreboard.kMedPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kMedPingColor)
        elseif ping < GUIScoreboard.kHighPingThreshold then
            player["Ping"]:SetColor(GUIScoreboard.kHighPingColor)
        else
            player["Ping"]:SetColor(GUIScoreboard.kInsanePingColor)
        end
        currentY = currentY + GUIScoreboard.kPlayerItemHeight + GUIScoreboard.kPlayerSpacing
        currentPlayerIndex = currentPlayerIndex + 1
    end

end

function GUIScoreboard:ResizePlayerList(playerList, numPlayers, teamGUIItem)
    
    while table.count(playerList) > numPlayers do
        teamGUIItem:RemoveChild(playerList[1]["Background"])
        playerList[1]["Background"]:SetIsVisible(false)
        table.insert(self.reusePlayerItems, playerList[1])
        table.remove(playerList, 1)
    end
    
    while table.count(playerList) < numPlayers do
        local newPlayerItem = self:CreatePlayerItem()
        table.insert(playerList, newPlayerItem)
        teamGUIItem:AddChild(newPlayerItem["Background"])
        newPlayerItem["Background"]:SetIsVisible(true)
    end

end

function GUIScoreboard:CreatePlayerItem()
    
    // Reuse an existing player item if there is one.
    if table.count(self.reusePlayerItems) > 0 then
        local returnPlayerItem = self.reusePlayerItems[1]
        table.remove(self.reusePlayerItems, 1)
        return returnPlayerItem
    end
    
    // Create background.
    local playerItem = GUIManager:CreateGraphicItem()
    playerItem:SetSize(Vector(GUIScoreboard.kTeamItemWidth - (GUIScoreboard.kPlayerItemWidthBuffer * 2), GUIScoreboard.kPlayerItemHeight, 0))
    playerItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerItem:SetPosition(Vector(GUIScoreboard.kPlayerItemWidthBuffer, GUIScoreboard.kPlayerItemHeight / 2, 0))
    playerItem:SetColor(Color(1, 1, 1, 1))
    playerItem:SetTexture("ui/hud_elements.dds")
    playerItem:SetTextureCoordinates(0, 0, 0.558, 0.16)
    
    // Player name text item.
    local playerNameItem = GUIManager:CreateTextItem()
    playerNameItem:SetFontName(GUIScoreboard.kFontName)
    playerNameItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    playerNameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerNameItem:SetTextAlignmentX(GUIItem.Align_Min)
    playerNameItem:SetTextAlignmentY(GUIItem.Align_Min)
    playerNameItem:SetPosition(Vector(30, 5, 0))
    playerNameItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(playerNameItem)
    
    // Player voice icon item.
    local playerVoiceIcon = GUIManager:CreateGraphicItem()
    playerVoiceIcon:SetSize(Vector(GUIScoreboard.kPlayerVoiceChatIconSize, GUIScoreboard.kPlayerVoiceChatIconSize, 0))
    playerVoiceIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    playerVoiceIcon:SetPosition(Vector(-GUIScoreboard.kPlayerVoiceChatIconSize - 5, 0, 0))
    playerVoiceIcon:SetTexture("ui/speaker.dds")
    playerNameItem:AddChild(playerVoiceIcon)
    
    local currentColumnX = GUIScoreboard.kTeamScoreColumnStartX
    
    // Status text item.
    local statusItem = GUIManager:CreateTextItem()
    statusItem:SetFontName(GUIScoreboard.kFontName)
    statusItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    statusItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    statusItem:SetTextAlignmentX(GUIItem.Align_Min)
    statusItem:SetTextAlignmentY(GUIItem.Align_Min)
    statusItem:SetPosition(Vector(currentColumnX, 5, 0))
    statusItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(statusItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX * 3
    
    // Score text item.
    local scoreItem = GUIManager:CreateTextItem()
    scoreItem:SetFontName(GUIScoreboard.kFontName)
    scoreItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    scoreItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    scoreItem:SetTextAlignmentX(GUIItem.Align_Min)
    scoreItem:SetTextAlignmentY(GUIItem.Align_Min)
    scoreItem:SetPosition(Vector(currentColumnX, 5, 0))
    scoreItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(scoreItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Kill text item.
    local killsItem = GUIManager:CreateTextItem()
    killsItem:SetFontName(GUIScoreboard.kFontName)
    killsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    killsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    killsItem:SetTextAlignmentX(GUIItem.Align_Min)
    killsItem:SetTextAlignmentY(GUIItem.Align_Min)
    killsItem:SetPosition(Vector(currentColumnX, 5, 0))
    killsItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(killsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Deaths text item.
    local deathsItem = GUIManager:CreateTextItem()
    deathsItem:SetFontName(GUIScoreboard.kFontName)
    deathsItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    deathsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    deathsItem:SetTextAlignmentX(GUIItem.Align_Min)
    deathsItem:SetTextAlignmentY(GUIItem.Align_Min)
    deathsItem:SetPosition(Vector(currentColumnX, 5, 0))
    deathsItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(deathsItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Resources text item.
    local resItem = GUIManager:CreateTextItem()
    resItem:SetFontName(GUIScoreboard.kFontName)
    resItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    resItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    resItem:SetTextAlignmentX(GUIItem.Align_Min)
    resItem:SetTextAlignmentY(GUIItem.Align_Min)
    resItem:SetPosition(Vector(currentColumnX, 5, 0))
    resItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(resItem)
    
    currentColumnX = currentColumnX + GUIScoreboard.kTeamColumnSpacingX
    
    // Ping text item.
    local pingItem = GUIManager:CreateTextItem()
    pingItem:SetFontName(GUIScoreboard.kFontName)
    pingItem:SetFontSize(GUIScoreboard.kPlayerStatsFontSize)
    pingItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    pingItem:SetTextAlignmentX(GUIItem.Align_Min)
    pingItem:SetTextAlignmentY(GUIItem.Align_Min)
    pingItem:SetPosition(Vector(currentColumnX, 5, 0))
    pingItem:SetColor(Color(1, 1, 1, 1))
    playerItem:AddChild(pingItem)
    
    return { Background = playerItem, Name = playerNameItem, Voice = playerVoiceIcon, Status = statusItem, Score = scoreItem, Kills = killsItem, Deaths = deathsItem, Resources = resItem, Ping = pingItem }
    
end

function GUIScoreboard:SendKeyEvent(key, down)

    if not ScoreboardUI_GetVisible() then
        return
    end
    
    if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
        self.mousePressed["LMB"]["Down"] = down
        if down then
            // A commander already has the mouse visible so skip this step.
            if not self.mouseVisible and not PlayerUI_IsACommander() then
                self:_SetMouseVisible(true)
            else
                self:_HandlePlayerVoiceClicked()
            end
        end
    end
    
end

function GUIScoreboard:_HandlePlayerVoiceClicked()

    local mouseX, mouseY = Client.GetCursorPosScreen()
    for index, team in ipairs(self.teams) do
        local playerList = team["PlayerList"]
        for playerIndex, playerItem in ipairs(playerList) do
            if GUIItemContainsPoint(playerItem["Voice"], mouseX, mouseY) then
                local clientIndex = playerItem["ClientIndex"]
                ChatUI_SetClientMuted(clientIndex, not ChatUI_GetClientMuted(clientIndex))
            end
        end
    end
    
end

function GUIScoreboard:_SetMouseVisible(setVisible)

    if self.mouseVisible ~= setVisible then
        self.mouseVisible = setVisible
        // Don't take away the mouse if the player is a commander.
        if not PlayerUI_IsACommander() then
            Client.SetMouseVisible(self.mouseVisible)
            Client.SetMouseCaptured(not self.mouseVisible)
            if self.mouseVisible then
                self.clickForMouseBackground:SetIsVisible(false)
            end
        end
    end

end