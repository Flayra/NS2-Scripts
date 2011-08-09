// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_SquadSelection.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// Client code to that handles squad selection and squad visualization.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kMaxRenderBlobSquads = 3
local kBallRadius = 0.03
local kMinThreshold = 0.47
local kMaxThreshold = 0.50
    
function MarineCommander:InitSquadSelectionScreenEffects()

    self.squadScreenEffect = {}
    for i = 1, kMaxRenderBlobSquads do
        self.squadScreenEffect[i] = Client.CreateScreenEffect("shaders/Metaballs.screenfx")
    end

end

function MarineCommander:DestroySquadSelectionScreenEffects()

    if self.squadScreenEffect ~= nil then
        for i, screenEffect in ipairs(self.squadScreenEffect) do
            Client.DestroyScreenEffect(screenEffect)
        end    
        self.squadScreenEffect = nil
    end

end

function MarineCommander:GetMaxNumSquadBalls()
    return GetMaxSquadSize()
end

function MarineCommander:GetMaxRenderBlobSquads()
    return kMaxRenderBlobSquads
end

function MarineCommander:GetSquadBallRadius()
    return kBallRadius
end

function MarineCommander:GetSquadBallMinThreshold()
    return kMinThreshold
end

function MarineCommander:GetSquadBallMaxThreshold()
    return kMaxThreshold
end

function MarineCommander:GetSquadBallInfo()

    local virSquads = {}
    local i = 1

    while(i <= self:GetMaxRenderBlobSquads()) do
    
        virSquads[i] = { playerCount = 0, squadID = -1 }
        i = i + 1
        
    end
    
    local ballInfo = {}
    local squadEntities = GetEntitiesForTeamWithinXZRange(GetSquadClass(), self:GetTeamNumber(), self:GetOrigin(), 20)
    // Create list of squads nearby
    for index, entity in pairs(squadEntities) do
        
        // Only consider an entity if it is in a nearby squad
        if(entity ~= nil and entity.squad ~= nil and entity.squad > 0) then
        
            local virSquadID = -1
            // First check if we can render this player
            local doRender = false
            for index, virSquad in pairs(virSquads) do
                if(virSquad.squadID == -1 or virSquad.squadID == entity.squad) then
                    virSquad.squadID = entity.squad
                    virSquadID = index
                    doRender = true
                    break
                end
            end
            
            if(doRender) then
            
                local squadColor = GetColorForSquad(entity.squad)
                
                local entOrigin = entity:GetOrigin()
                local screenPos = Client.WorldToScreen(entOrigin)
                screenPos.x = screenPos.x / Client.GetScreenWidth()
                screenPos.y = screenPos.y / Client.GetScreenHeight()
                
                local ballIndex = virSquads[virSquadID].playerCount
                virSquads[virSquadID].playerCount = virSquads[virSquadID].playerCount + 1
                table.insert(ballInfo, {ballIndex, Color(squadColor[1], squadColor[2], squadColor[3], squadColor[4]), screenPos, entity.squad, virSquadID})
                
            end
            
        end
        
    end
    
    return ballInfo

end

function MarineCommander:UpdateSquadScreenEffects(highlightSquad, selectedSquad)

    if self.squadScreenEffect == nil then
        return
    end

    // Initially disable all squads. We'll enable them later if there are players
    // in the squads.
    for i=1,self:GetMaxRenderBlobSquads() do

        local screenEffect = self.squadScreenEffect[i];
        screenEffect:SetActive(false)

        for j=1,self:GetMaxNumSquadBalls() do
            screenEffect:SetParameter("metaBallRender", j, 0)
        end

        screenEffect:SetParameter("metaBallRadius", self:GetSquadBallRadius())
        screenEffect:SetParameter("minThreshold", self:GetSquadBallMinThreshold())
        screenEffect:SetParameter("maxThreshold", self:GetSquadBallMaxThreshold())
    
    end
    
    local ballInfo = self:GetSquadBallInfo()
    
    for index, ball in ipairs(ballInfo) do
    
        local setColor = Color(ball[2])
        
        if (selectedSquad == ball[4]) then
            setColor.r = setColor.r * 6
            setColor.g = setColor.g * 6
            setColor.b = setColor.b * 6
        elseif(highlightSquad == ball[4]) then
            setColor.r = setColor.r * 4
            setColor.g = setColor.g * 4
            setColor.b = setColor.b * 4
        end
        
        setColor.r = setColor.r * 0.2
        setColor.g = setColor.g * 0.2
        setColor.b = setColor.b * 0.2
        
        local ballIndex    = ball[1]
        local screenPos    = ball[3]
        local squadIndex   = ball[5]
        
        local screenEffect = self.squadScreenEffect[ squadIndex ]
        
        screenEffect:SetActive(true)
        screenEffect:SetParameter("metaBallColor", ballIndex, setColor)
        screenEffect:SetParameter("metaBallPos", ballIndex, screenPos)
        screenEffect:SetParameter("metaBallRender", ballIndex, 1)
        
    end
    
    /*
    self.metaballScreenEffect:SetParameter("metaBallRadius", self:GetSquadBallRadius())
    self.metaballScreenEffect:SetParameter("minThreshold", self:GetSquadBallMinThreshold())
    self.metaballScreenEffect:SetParameter("maxThreshold", self:GetSquadBallMaxThreshold())
    
    // First assume no balls will be rendered
    local currSquad = 1
    while(currSquad <= self:GetMaxRenderBlobSquads()) do
        local currBallIndex = 0
        while(currBallIndex < self:GetMaxNumSquadBalls()) do
            self.metaballScreenEffect:SetParameter("metaBallRender", 0, currBallIndex, string.format("p%d", currSquad))
            currBallIndex = currBallIndex + 1
        end
        
        self.metaballScreenEffect:SetPassActive(string.format("p%d", currSquad), false)
        currSquad = currSquad + 1
    end
    
    local ballInfo = self:GetSquadBallInfo()
    
    for index, ball in pairs(ballInfo) do
    
        local setColor = Color(ball[2])
        if(selectedSquad == ball[4]) then
            setColor.r = setColor.r * 6
            setColor.g = setColor.g * 6
            setColor.b = setColor.b * 6
        elseif(highlightSquad == ball[4]) then
            setColor.r = setColor.r * 4
            setColor.g = setColor.g * 4
            setColor.b = setColor.b * 4
        end
        setColor.r = setColor.r * 0.2
        setColor.g = setColor.g * 0.2
        setColor.b = setColor.b * 0.2
        self.metaballScreenEffect:SetParameter("metaBallColor", setColor, ball[1], string.format("p%d", ball[5]))
        
        self.metaballScreenEffect:SetParameter("metaBallPos", ball[3], ball[1], string.format("p%d", ball[5]))
        // This ball is being rendered, notify the effect
        self.metaballScreenEffect:SetParameter("metaBallRender", 1, ball[1], string.format("p%d", ball[5]))
        self.metaballScreenEffect:SetPassActive(string.format("p%d", ball[5]), true)
        
    end
    */
 
end

function MarineCommander:GetSquadBlob(atScreenPos)

    local ballInfo = self:GetSquadBallInfo()
    
    atScreenPos.y = atScreenPos.y * (Client.GetScreenHeight() / Client.GetScreenWidth())
	for index, ball in pairs(ballInfo) do
		ball[3] = Vector(ball[3].x, ball[3].y * (Client.GetScreenHeight() / Client.GetScreenWidth()), 0)
	end
	
	local weight = 0
	local radiusSq = self:GetSquadBallRadius() * self:GetSquadBallRadius()
	local foundSquads = {}
	for index, ball in pairs(ballInfo) do
		local tempWeight = radiusSq / ((atScreenPos.x - ball[3].x) * (atScreenPos.x - ball[3].x) + (atScreenPos.y - ball[3].y) * (atScreenPos.y - ball[3].y))
		if(foundSquads[ball[4]] == nil) then
		    foundSquads[ball[4]] = 0
		end
		foundSquads[ball[4]] = foundSquads[ball[4]] + tempWeight
		weight = weight + tempWeight
	end

    local isInside = false
    local foundSquad = -1
    local foundSquadWeight = 0
    if(weight >= self:GetSquadBallMaxThreshold()) then
		isInside = true
		for index, squad in pairs(foundSquads) do
		    if (squad > foundSquadWeight) then
		        foundSquadWeight = squad
		        foundSquad = index
		    end
		end
	end

    return foundSquad

end