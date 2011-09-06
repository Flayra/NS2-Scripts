// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Returns all the info about all hive sight blips so it can be rendered by the UI.
// Returns single-dimensional array of fields in the format screenX, screenY, drawRadius, blipType
function PlayerUI_FetchBlips(blips, player)

    local eyePos = player:GetEyePos()
    for index, blip in ientitylist(Shared.GetEntitiesWithClassname("Blip")) do
    
        local blipType = blip.blipType
        local blipOrigin = blip:GetOrigin()
        local blipEntId = blip.entId
        local blipName = ""
        
        // Lookup more recent position of blip
        local blipEntity = Shared.GetEntity(blipEntId)
        
        // Do not display a blip for the local player.
        if blipEntity ~= player then

            if blipEntity then
            
                if blipEntity:isa("Player") then
                    blipName = Scoreboard_GetPlayerData(blipEntity:GetClientIndex(), kScoreboardDataIndexName)
                elseif blipEntity.GetTechId then
                    blipName = GetDisplayNameForTechId(blipEntity:GetTechId())
                end
                
            end
            
            if not blipName then
                blipName = ""
            end
            
            // Get direction to blip. If off-screen, don't render. Bad values are generated if 
            // Client.WorldToScreen is called on a point behind the camera.
            local normToEntityVec = GetNormalizedVector(blipOrigin - eyePos)
            local normViewVec = player:GetViewAngles():GetCoords().zAxis
           
            local dotProduct = normToEntityVec:DotProduct(normViewVec)
            if dotProduct > 0 then
            
                // Get distance to blip and determine radius
                local distance = (eyePos - blipOrigin):GetLength()
                local drawRadius = 35/distance
                
                // Compute screen xy to draw blip
                local screenPos = Client.WorldToScreen(blipOrigin)

                local trace = Shared.TraceRay(eyePos, blipOrigin, PhysicsMask.Bullets, EntityFilterTwo(player, entity))                               
                local obstructed = ((trace.fraction ~= 1) and ((trace.entity == nil) or trace.entity:isa("Door"))) 
                
                // Add to array (update numElementsPerBlip in GUIHiveBlips:UpdateBlipList)
                table.insert(blips, screenPos.x)
                table.insert(blips, screenPos.y)
                table.insert(blips, drawRadius)
                table.insert(blips, blipType)
                table.insert(blips, obstructed)
                table.insert(blips, blipName)

            end
            
        end
        
    end
    
end

function PlayerUI_FetchPheromones(blips, player)

    local eyePos = player:GetEyePos()
    for index, pheromone in ientitylist(Shared.GetEntitiesWithClassname("Pheromone")) do
    
        local pheromoneOrigin = pheromone:GetOrigin()
        local normToEntityVec = GetNormalizedVector(pheromoneOrigin - eyePos)
        local normViewVec = player:GetViewAngles():GetCoords().zAxis
       
        local dotProduct = normToEntityVec:DotProduct(normViewVec)
        if(dotProduct > 0) then
        
            // Draw pheromones at base size no matter how close
            local distance = math.max((eyePos - pheromoneOrigin):GetLength(), 10)
            
            // Don't have them vary with distance as much as blips
            local drawRadius = (1 / (.2 * distance )) * 50 * pheromone:GetLevel()
            
            // Compute screen xy to draw it
            local screenPos = Client.WorldToScreen(pheromoneOrigin)

            local trace = Shared.TraceRay(eyePos, pheromoneOrigin, PhysicsMask.Bullets, EntityFilterTwo(player, entity))                               
            local obstructed = ((trace.fraction ~= 1) and ((trace.entity == nil) or trace.entity:isa("Door"))) 
            
            // Add to array (update numElementsPerBlip in GUIHiveBlips:UpdateBlipList)
            table.insert(blips, screenPos.x)
            table.insert(blips, screenPos.y)
            table.insert(blips, drawRadius)
            table.insert(blips, pheromone:GetBlipType())
            table.insert(blips, true)
            table.insert(blips, pheromone:GetDisplayName())

        end
        
    end
    
end

// Returns all the info about all hive sight blips so it can be rendered by the UI.
// Returns single-dimensional array of fields in the format screenX, screenY, drawRadius, blipType
function PlayerUI_GetBlipInfo()

    local blips = { }

    local player = Client.GetLocalPlayer()
    
    if player then
    
        PlayerUI_FetchBlips(blips, player)
        
        // Treat pheromones as part of blips for draw purposes
        PlayerUI_FetchPheromones(blips, player)
        
    end
    
    return blips

end       

/* Texture used for icons. Pics are masked, so don't worry about boundaries of the images being over the energy circle. */
function PlayerUI_AlienAbilityIconsImage()
    return "alien_abilities"
end

// array of totalPower, minPower, xoff, yoff, visibility (boolean), hud slot
function GetActiveAbilityData(secondary)

    local data = {}
    
    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
    
        local ability = player:GetActiveWeapon()
        
        if ability ~= nil and ability:isa("Ability") then
        
            if ( (not secondary) or ( secondary and ability:GetHasSecondary(player))) then
            
                data = ability:GetInterfaceData(secondary, false)
                
            end
            
        end
        
    end
    
    return data
    
end

/**
 * For current ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean), command name
 */
function PlayerUI_GetAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
    
        table.addtable(GetActiveAbilityData(false), data)

    end
    
    return data
    
end

/**
 * Return boolean value indicating if there's a special ability
 */
function PlayerUI_HasSpecialAbility()
    local player = Client.GetLocalPlayer()
    return player:isa("Alien") and player:GetHasSpecialAbility()
end

/**
 * For special ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean), command name
 */
function PlayerUI_GetSpecialAbilityData()

    local player = Client.GetLocalPlayer()
    if player:isa("Alien") and player:GetHasSpecialAbility() then
    
        return player:GetSpecialAbilityInterfaceData()
        
    end

    return {}
    
end

/**
 * For secondary ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean)
 */
function PlayerUI_GetSecondaryAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
        
        table.addtable(GetActiveAbilityData(true), data)
        
    end
    
    return data
    
end

/**
 * Return boolean value indicating if inactive powers should be visible
 */
function PlayerUI_GetInactiveVisible()
    local player = Client.GetLocalPlayer()
    return player:isa("Alien") and player:GetInactiveVisible()
end

// Loop through child weapons that aren't active and add all their data into one array
function PlayerUI_GetInactiveAbilities()

    local data = {}
    
    local player = Client.GetLocalPlayer()

    if player and player:isa("Alien") then    
    
        local inactiveAbilities = player:GetHUDOrderedWeaponList()
        
        // Don't show selector if we only have one ability
        if table.count(inactiveAbilities) > 1 then
        
            for index, ability in ipairs(inactiveAbilities) do
            
                if ability:isa("Ability") then
                    local abilityData = ability:GetInterfaceData(false, true)
                    if table.count(abilityData) > 0 then
                        table.addtable(abilityData, data)
                    end
                end
                    
            end
            
        end
        
    end
    
    return data
    
end

function PlayerUI_GetPlayerEnergy()
    local player = Client.GetLocalPlayer()
    if player and player.GetEnergy then
        return player:GetEnergy()
    end
    return 0
end

function PlayerUI_GetPlayerMaxEnergy()
    return Ability.kMaxEnergy
end


function GetAbility(abilityIndex)

    local ability = nil
    
    local player = Client.GetLocalPlayer()
    if(player and player:isa("Alien")) then
    
        local abilities = player:GetHUDOrderedWeaponList()
        local numAbilities = table.maxn(abilities)   
        
        if(abilityIndex >= 1 and abilityIndex <= numAbilities) then
        
            ability = abilities[abilityIndex]
            
        else
        
            Shared.Message("GetAbility(" .. abilityIndex .. ") outside range 1 - " .. numAbilities)
            
        end
         
    end
    
    return ability
    
end

function Alien:OnInitLocalClient()

    Player.OnInitLocalClient(self)
    
    if(self:GetTeamNumber() ~= kTeamReadyRoom) then

        if self.alienHUD == nil then
            self.alienHUD = GetGUIManager():CreateGUIScript("GUIAlienHUD")
        end
        if self.hiveBlips == nil then
            self.hiveBlips = GetGUIManager():CreateGUIScript("GUIHiveBlips")
        end

    end
    
end

function Alien:OnDestroyClient()
    
    if self.alienHUD then
        GetGUIManager():DestroyGUIScript(self.alienHUD)
        self.alienHUD = nil
    end
    if self.hiveBlips then
        GetGUIManager():DestroyGUIScript(self.hiveBlips)
        self.hiveBlips = nil
    end
    if self.buyMenu then
        GetGUIManager():DestroyGUIScript(self.buyMenu)
        self.buyMenu = nil
    end

end

function Alien:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    // If we are dead, close the evolve menu.
    if isLocal and not self:GetIsAlive() and self:GetBuyMenuIsDisplaying() then
        self:CloseMenu()
    end
    
    if isLocal then
        
        local darkVisionFadeAmount = 1
        local darkVisionFadeTime = 0.2
        
        if not self.darkVisionOn then
            darkVisionFadeAmount = math.max( 1 - (Client.GetTime() - self.darkVisionEndTime) / darkVisionFadeTime, 0 )
        end
        
        self.screenEffects.darkVision:SetActive(self.darkVisionOn or darkVisionFadeAmount > 0)
        
        self.screenEffects.darkVision:SetParameter("startTime", self.darkVisionTime)
        self.screenEffects.darkVision:SetParameter("time", Client.GetTime())
        self.screenEffects.darkVision:SetParameter("amount", darkVisionFadeAmount)
        
        // Blur alien vision if they are using the buy menu or are stunned.
        local stunned = HasMixin(self, "Stun") and self:GetIsStunned()
        self:SetBlurEnabled( self:GetBuyMenuIsDisplaying() or stunned )
        
    end
    
end

function Alien:UpdateMisc(input)

    Player.UpdateMisc(self, input)
    
    if not Shared.GetIsRunningPrediction() then

        // Close the buy menu if it is visible when the Alien moves.
        if input.move.x ~= 0 or input.move.z ~= 0 then
            self:CloseMenu()
        end
        
    end
    
end

function Alien:GetBuyMenuIsDisplaying()
    return self.buyMenu ~= nil
end

function Alien:_UpdateMenuMouseState()

    local showingBuyMenu = self:GetBuyMenuIsDisplaying()
    Client.SetMouseVisible(showingBuyMenu)
    Client.SetMouseCaptured(not showingBuyMenu)
    Client.SetMouseClipped(not showingBuyMenu)

end

function Alien:CloseMenu()

    if self.buyMenu then
    
        self.buyMenu:OnClose()
        
        GetGUIManager():DestroyGUIScript(self.buyMenu)
        self.buyMenu = nil
        
        self:_UpdateMenuMouseState()
        
        // Quick work-around to not fire weapon when closing menu
        self.timeClosedMenu = Shared.GetTime()
        
        return true
        
    end
    
    return false
    
end

// Bring up evolve menu
function Alien:Buy()
    
    // Don't allow display in the ready room, or as phantom
    if self:GetTeamNumber() ~= 0 and (Client.GetLocalPlayer() == self) and (not HasMixin(self, "Phantom") or not self:GetIsPhantom()) then
    
        if not self.buyMenu then
            self.buyMenu = GetGUIManager():CreateGUIScript("GUIAlienBuyMenu")
            self:_UpdateMenuMouseState()
        else
            self:CloseMenu()
        end
        
    end
    
end