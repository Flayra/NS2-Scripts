// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/HudTooltips.lua")
Script.Load("lua/DSPEffects.lua")
Script.Load("lua/tweener/Tweener.lua")

Player.kFeedbackFlash = "ui/feedback.swf"
Player.kSharedHUDFlash = "ui/shared_hud.swf"

Player.kDamageCameraShakeAmount = 0.10
Player.kDamageCameraShakeSpeed = 5
Player.kDamageCameraShakeTime = 0.25

Player.kMeleeHitCameraShakeAmount = 0.05
Player.kMeleeHitCameraShakeSpeed = 5
Player.kMeleeHitCameraShakeTime = 0.25

// The amount of health left before the low health warning
// screen effect is active
Player.kLowHealthWarning = 0.35
Player.kLowHealthPulseSpeed = 10

Player.kShowGiveDamageTime = 1

Player.kPhaseEffectActiveTime = 1

gFlashPlayers = nil

/**
 * Get setup data for crosshairs
 * Returns modified key, value pairs in single dimensional array
 * Changes are applied only to current frame
 *
 * "mask", <maskname>
 * "scale", [1 - ???]
 * "cameraShake", [0 - ???]
 * "targetHit", [alpha, 0-1]
 * "target", [alpha, 0-1]
 * 
 */
function PlayerUI_GetCrosshairValues()

   local crosshairValues = {}
   
   local player = Client.GetLocalPlayer()
   if(player ~= nil) then
   
        local weapon = player:GetActiveWeapon()
        
        // Grow crosshair to account for inaccuracy/recoil
        if(weapon ~= nil) then

            // Don't show inaccuracy in reticle until we can get it looking better        
            local inaccuracyScalar = 1 //= weapon:GetInaccuracyScalar()
            table.insert(crosshairValues, "scale")
            table.insert(crosshairValues, inaccuracyScalar)
            
            table.insert(crosshairValues, "cameraShake")
            table.insert(crosshairValues, math.max(0, (inaccuracyScalar - 1)*.005))
            
        end
        
        // Draw hit indicator
        local kDrawReticleHitTime = .25
        local time = player:GetTimeTargetHit()
        if(time ~= 0 and (Shared.GetTime() - time < kDrawReticleHitTime)) then
        
            table.insert(crosshairValues, "targetHit")
            table.insert(crosshairValues, 1)        
            
        end
        
        // Draw reticle differently if we have live target under crosshairs
        if(player:GetReticleTarget()) then
        
            table.insert(crosshairValues, "target")
            table.insert(crosshairValues, 1)        
            
        end
        
   end
   
   return crosshairValues
   
end

function PlayerUI_GetNextWaypointActive()

    local player = Client.GetLocalPlayer()
    return player ~= nil and player.nextOrderWaypointActive and not player:isa("Commander")

end

/**
 * Gives the UI the screen space coordinates of where to display
 * the next waypoint for when players have an order location
 */
function PlayerUI_GetNextWaypointInScreenspace()

    local player = Client.GetLocalPlayer()
    
    local playerEyePos = Vector(player:GetCameraViewCoords().origin)
    local playerForwardNorm = Vector(player:GetCameraViewCoords().zAxis)
    
    // This method needs to use the previous updates player info
    if(player.lastPlayerEyePos == nil) then
        player.lastPlayerEyePos = Vector(playerEyePos)
        player.lastPlayerForwardNorm = Vector(playerForwardNorm)
    end
    
    local screenPos = Client.WorldToScreen(player.nextOrderWaypoint)
    
    local isInScreenSpace = false
    local nextWPDir = player.nextOrderWaypoint - player.lastPlayerEyePos
    local normToEntityVec = GetNormalizedVectorXZ(nextWPDir)
    local normViewVec = GetNormalizedVectorXZ(player.lastPlayerForwardNorm)
    local dotProduct = Math.DotProduct(normToEntityVec, normViewVec)
    
    // Distance is used for scaling
    local nextWPDist = nextWPDir:GetLength()
    local nextWPMaxDist = 25
    local nextWPScale = math.max(0.5, 1 - (nextWPDist / nextWPMaxDist))
    
    if(player.nextWPInScreenSpace == nil) then
    
        player.nextWPInScreenSpace = true
        player.nextWPDoingTrans = false
        player.nextWPLastVal = { }
        
        for i = 1, 5 do 
            player.nextWPLastVal[i] = 0
        end
        
        player.nextWPCurrWP = Vector(player.nextOrderWaypoint)
        
    end
    
    // If the waypoint has changed, do a smooth transition
    if(player.nextWPCurrWP ~= player.nextOrderWaypoint) then
    
        player.nextWPDoingTrans = true
        VectorCopy(player.nextOrderWaypoint, player.nextWPCurrWP)
        
    end
    
    local returnTable = nil

    // If offscreen, fallback on compass method
    local minWidthBuff = Client.GetScreenWidth() * 0.1
    local minHeightBuff = Client.GetScreenHeight() * 0.1
    local maxWidthBuff = Client.GetScreenWidth() * 0.9
    local maxHeightBuff = Client.GetScreenHeight() * 0.9
    if(screenPos.x < minWidthBuff or screenPos.x > maxWidthBuff or
    
       screenPos.y < minHeightBuff or screenPos.y > maxHeightBuff or dotProduct < 0) then
       
        if(player.nextWPInScreenSpace) then
        
            player.nextWPDoingTrans = true
            
        end
        player.nextWPInScreenSpace = false

        local eyeForwardPos = player.lastPlayerEyePos + (player.lastPlayerForwardNorm * 5)
        local eyeForwardToWP = player.nextOrderWaypoint - eyeForwardPos
        eyeForwardToWP:Normalize()
        local eyeForwardToWPScreen = Client.WorldToScreen(eyeForwardPos + eyeForwardToWP)
        local middleOfScreen = Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() / 2, 0)
        local screenSpaceDir = eyeForwardToWPScreen - middleOfScreen
        screenSpaceDir:Normalize()
        local finalScreenPos = middleOfScreen + Vector(screenSpaceDir.x * (Client.GetScreenWidth() / 2), screenSpaceDir.y * (Client.GetScreenHeight() / 2), 0)
        // Clamp to edge of screen with buffer
        finalScreenPos.x = Clamp(finalScreenPos.x, minWidthBuff, maxWidthBuff)
        finalScreenPos.y = Clamp(finalScreenPos.y, minHeightBuff, maxHeightBuff)
        returnTable = { finalScreenPos.x, finalScreenPos.y, 3.14, nextWPScale, nextWPDist }
        
    else
    
        isInScreenSpace = true
        if(not player.nextWPInScreenSpace) then
        
            player.nextWPDoingTrans = true
            
        end
        player.nextWPInScreenSpace = true
        
        local bounceY = screenPos.y + (math.sin(Shared.GetTime() * 3) * (30 * nextWPScale))
        returnTable = { screenPos.x, bounceY, 3.14, nextWPScale, nextWPDist }
        
    end
    
    if(player.nextWPDoingTrans) then
    
        local replaceTable = { }
        local allEqual = true
        for i = 1, 5 do
        
            replaceTable[i] = Slerp(player.nextWPLastVal[i], returnTable[i], 50) 
            allEqual = allEqual and replaceTable[i] == returnTable[i]
            
        end
        
        if(allEqual) then
        
            player.nextWPDoingTrans = false
            
        end
        
        returnTable = replaceTable
        
    end
    
    for i = 1, 5 do
    
        player.nextWPLastVal[i] = returnTable[i]
        
    end
    
    // If the next waypoint is also the final waypoint and is in screen space,
    // setting the distance to negative will hide it since the distance is
    // also displayed on the final waypoint
    local nextIsFinal = player:GetVisibleWaypoint() == player.nextOrderWaypoint
    if nextIsFinal and isInScreenSpace then
    
        returnTable[5] = -1
    
    end
    
    // Save current for next update
    VectorCopy(playerEyePos, player.lastPlayerEyePos)
    VectorCopy(playerForwardNorm, player.lastPlayerForwardNorm)
    
    return returnTable

end

function PlayerUI_GetOrderInfo()

    local orderInfo = {}
    
    // Hard-coded for testing
    local player = Client.GetLocalPlayer()
    if player then
    
        for index, order in ientitylist(Shared.GetEntitiesWithClassname("Order")) do
        
            table.insert(orderInfo, order.orderType)
            table.insert(orderInfo, order.orderParam)
            table.insert(orderInfo, order.orderLocation)
            table.insert(orderInfo, order.orderOrientation)
            
        end
        
    end
    
    return orderInfo
end

/**
 * Gives the UI the screen space coordinates of where to display
 * the final waypoint for when players have an order location
 */
function PlayerUI_GetFinalWaypointInScreenspace()

    local player = Client.GetLocalPlayer()
    
    // Get our own waypoint, or if we're comm, the waypoint of our first selected player
    local waypoint = Vector(player:GetVisibleWaypoint())
    
    local returnTable = { }
    local screenPos = Client.WorldToScreen(waypoint)
    local finalWPDir = waypoint - player:GetEyePos()
    local normToEntityVec = GetNormalizedVectorXZ(finalWPDir)
    local normViewVec = GetNormalizedVectorXZ(player:GetViewAngles():GetCoords().zAxis)
    local dotProduct = Math.DotProduct(normToEntityVec, normViewVec)
    
    // Distance is used for scaling
    local finalWPDist = finalWPDir:GetLengthSquared()
    local finalWPMaxDist = 25 * 25
    local finalWPScale = math.max(0.3, 1 - (finalWPDist / finalWPMaxDist))
    
    if(screenPos.x < 0 or screenPos.x > Client.GetScreenWidth() or
       screenPos.y < 0 or screenPos.y > Client.GetScreenHeight() or dotProduct < 0) then
       
        // Don't draw if it is behind the player
        returnTable[1] = false
        
    else
    
        returnTable[1] = true
        returnTable[2] = screenPos.x
        local bounceY = screenPos.y + (math.sin(Shared.GetTime() * 3) * (30 * finalWPScale))
        returnTable[3] = bounceY
        returnTable[4] = finalWPScale
        returnTable[5] = GetDisplayNameForTechId(player.orderType, "<no display name>")
        returnTable[6] = math.sqrt(finalWPDist)
        
    end
    
    return returnTable
    
end

/**
 * Get crosshair texture atlas
 */
function PlayerUI_GetCrosshairTexture()

    Client.BindFlashTexture("weapon_crosshair", "ui/crosshairs.dds")
    return "weapon_crosshair"

end

/**
 * Get the X position of the crosshair image in the atlas. 
 */
function PlayerUI_GetCrosshairX()
    return 0
end

/**
 * Get the Y position of the crosshair image in the atlas.
 * Listed in this order:
 *   Rifle, Pistol, Axe, Shotgun, Minigun, Rifle with GL, Flamethrower
 */
function PlayerUI_GetCrosshairY()

    local player = Client.GetLocalPlayer()

    if(player and not player:GetIsThirdPerson()) then  
      
        local weapon = player:GetActiveWeapon()
        if(weapon ~= nil) then
        
            // Get class name and use to return index
            local index 
            local mapname = weapon:GetMapName()
            
            if(mapname == Rifle.kMapName or mapname == GrenadeLauncher.kMapName) then 
                index = 0
            elseif(mapname == Pistol.kMapName) then
                index = 1
            elseif(mapname == Shotgun.kMapName) then
                index = 3
            elseif(mapname == Minigun.kMapName) then
                index = 4
            elseif(mapname == Flamethrower.kMapName) then
                index = 5   
            // All alien crosshairs are the same for now
            elseif((mapname == Spikes.kMapName) or (mapname == Spores.kMapName) or (mapname == Parasite.kMapName)) then
                index = 6
            elseif(mapname == SpitSpray.kMapName) then
                index = 7              
            // Picking blink target
            elseif (mapname == SwipeBlink.kMapName) and weapon:GetShowingGhost() then
                index = 6
            // Blanks
            else
                index = 9
            end
        
            return index*64
            
        end
        
    end

    return nil

end

function PlayerUI_GetCrosshairDamageIndicatorY()

    return 8 * 64
    
end

/**
 * Returns the player name under the crosshair for display (return "" to not display anything).
 */
function PlayerUI_GetCrosshairText()
    local player = Client.GetLocalPlayer()
    if player then
        return player.crossHairText
    end
    return ""
end

// Returns the int color to draw the results of PlayerUI_GetCrosshairText() in. 
function PlayerUI_GetCrosshairTextColor()
    local player = Client.GetLocalPlayer()
    if player then
        return player.crossHairTextColor
    end
    return kFriendlyNeutralColor
end

/**
 * Get the width of the crosshair image in the atlas, return 0 to hide
 */
function PlayerUI_GetCrosshairWidth()

    local player = Client.GetLocalPlayer()
    if player then

        local weapon = player:GetActiveWeapon()
    
        //if (weapon ~= nil and player:isa("Marine") and not player:GetIsThirdPerson()) then
    if (weapon ~= nil and not player:GetIsThirdPerson()) then
            return 64
        end
    end
    
    return 0
    
end


/**
 * Get the height of the crosshair image in the atlas, return 0 to hide
 */
function PlayerUI_GetCrosshairHeight()

    local player = Client.GetLocalPlayer()
    if(player ~= nil) then

        local weapon = player:GetActiveWeapon()    
        //if(weapon ~= nil and player:isa("Marine") and not player:GetIsThirdPerson()) then
    if (weapon ~= nil and not player:GetIsThirdPerson()) then
            return 64
        end
    
    end
    
    return 0

end

function PlayerUI_GetWeapon()
-- TODO : Return actual weapon name
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetActiveWeapon()
    end
    return nil

end

function PlayerUI_GetPlayerClass()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetClassName()
    end
    return nil

end

function PlayerUI_GetMinimapPlayerDirection()

    local player = Client.GetLocalPlayer()
    if player then
        local coords = player:GetViewAngles():GetCoords().zAxis
        return math.atan2(coords.x, coords.z)
    end
    return 0

end

/**
 * Called by Flash to get the number of reserve bullets in the active weapon.
 */
function PlayerUI_GetWeaponAmmo()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetWeaponAmmo()
    end
    return 0
end

/**
 * Called by Flash to get the number of bullets left in the reserve for 
 * the active weapon.
 */
function PlayerUI_GetWeaponClip()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetWeaponClip()
    end
    return 0
end

function PlayerUI_GetAuxWeaponClip()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetAuxWeaponClip()
    end
    return 0
end

/**
 * Called by Flash to get the value to display for the team resources on
 * the HUD.
 */
function PlayerUI_GetTeamResources()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayTeamResources()
    end
    return 0
end

// TODO: 
function PlayerUI_MarineAbilityIconsImage()
end

/**
 * Called by Flash to get the value to display for the personal resources on
 * the HUD.
 */
function PlayerUI_GetPlayerResources()
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayResources()
    end
    return 0

end

function PlayerUI_GetPlayerHealth()
    local player = Client.GetLocalPlayer()
    if player then
        return Client.GetLocalPlayer():GetHealth()
    end
    return 0
end

function PlayerUI_GetPlayerMaxHealth()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetMaxHealth()
    end
    return 0
end

function PlayerUI_GetPlayerArmor()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetArmor()
    end
    return 0
end

function PlayerUI_GetPlayerMaxArmor()
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetMaxArmor()
    end
    return 0
end

function PlayerUI_GetPlayerIsParasited()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetGameEffectMask(kGameEffect.Parasite)
    end
    return false

end

function PlayerUI_GetIsBeaconing()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetGameEffectMask(kGameEffect.Beacon)
    end
    return false

end

function PlayerUI_GetPlayerOnInfestation()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetGameEffectMask(kGameEffect.OnInfestation)
    end
    return false

end

// For drawing health circles
function GameUI_GetHealthStatus(entityId)

    local entity = Shared.GetEntity(entityId)
    if(entity ~= nil) then
    
        if entity:isa("LiveScriptActor") then
        
            return entity:GetHealth()/entity:GetMaxHealth()
            
        else
        
            Print("GameUI_GetHealthStatus(%d) - Entity not a ScriptActor (%s instead).", entityId, entity:GetMapName())
            
        end
        
    end
    
    return 0

end

function Player:GetName()

    // There are cases where the player name will be nil such as right before
    // this Player is destroyed on the Client (due to the scoreboard removal message
    // being received on the Client before the entity removed message). Play it safe.
    return Scoreboard_GetPlayerData(self:GetClientIndex(), "Name") or "No Name"
    
end

function Player:UpdateHelp()
end

function Player:GetDrawResourceDisplay()
    return false
end

// Update crosshair text and color which displays what player you're looking at and
// whether they're a friend or enemy. When tracereticle cheat is on, display any 
// entity under the crosshair.
function Player:UpdateCrossHairText()

    // Clear text if we don't hit anything
    self.crossHairText = ""

    local viewAngles = self:GetViewAngles()
    
    local viewCoords = viewAngles:GetCoords()
    
    local startPoint = self:GetEyePos()
        
    local endPoint = startPoint + viewCoords.zAxis * 20
        
    local trace = Shared.TraceRay(startPoint, endPoint, PhysicsMask.AllButPCsAndRagdolls, EntityFilterOne(self))
    local entity = trace.entity
    
    // Show players and important structures
    if trace.fraction < 1 and entity ~= nil then
    
        local text = nil
        local updatedText = false
        
        if self.traceReticle then
            
            text = string.format("%s (id: %d) origin: %s, %.2f dist", SafeClassName(entity), entity:GetId(), ToString(entity:GetOrigin()), (trace.endPoint - startPoint):GetLength())

            if entity.GetExtents then
                text = string.format("%s extents: %s", self.crossHairText, ToString(entity:GetExtents()))
            end
            
            if entity.GetTeamNumber then
                text = string.format("%s teamNum: %d", self.crossHairText, entity:GetTeamNumber())
            end
            
            updatedText = true
    
        else
            text = GetCrosshairText(entity, self:GetTeamNumber())
            updatedText = (text ~= "")
        end
   
        if updatedText then
        
            self.crossHairText = text
            
            if GetEnemyTeamNumber(self:GetTeamNumber()) == entity:GetTeamNumber() then
    
                self.crossHairTextColor = kEnemyColor
                
            elseif entity:GetGameEffectMask(kGameEffect.Parasite) then
            
                self.crossHairTextColor = kParasitedTextColor
                
            else
            
                self.crossHairTextColor = kFriendlyNeutralColor
                
            end
            
            self.crossHairTextTime = Shared.GetTime()

        end
            
    end     
    
end

// For debugging. Cheats only.
function Player:ToggleTraceReticle()
    self.traceReticle = not self.traceReticle
end

function Player:UpdateMisc(input)

    PROFILE("Player:UpdateMisc")

    if not Shared.GetIsRunningPrediction() then
    
        self:UpdateCrossHairText()
        self:UpdateDamageIndicators()
        self:UpdateChat(input)
        
    end
    
end

function Player:SetBlurEnabled(blurEnabled)
    self.screenEffects.blur:SetActive(blurEnabled)
end

function Player:UpdateScreenEffects(deltaTime)

    if(self.flareStartTime > 0) then
    
        self.screenEffects.flare:SetActive(true)
        
        // How long to flare for
        local flareEffectTime = self.flareStopTime - self.flareStartTime
        local currFlareTime = Shared.GetTime() - self.flareStartTime
        local flareWeight = Clamp(currFlareTime / flareEffectTime, 0, 1)
        
        // We want the effect to ramp up fast for the first bit of the time, stick
        // for most the time and then down slow for the last bit
        // The point within the flare time which the flare will reach full power
        local atFullPoint = 0.1
        // The point where the flare will begin to die down
        local rampDownAtPoint = 0.75
        local rampUpSpeed = 1 / atFullPoint
        flareWeight = flareWeight * rampUpSpeed
        local rampDownTime = rampUpSpeed * rampDownAtPoint
        if(flareWeight > rampDownTime) then
        
            flareWeight = (rampUpSpeed - flareWeight) / (rampUpSpeed - rampDownTime)
        
        end
        flareWeight = Clamp(flareWeight, 0, 1) * self.flareScalar
        self.screenEffects.flare:SetParameter("flareWeight", flareWeight)
        
    else
    
        self.screenEffects.flare:SetActive(false)
        
    end
    
    // Show low health warning if below the threshold and not a spectator.
    local isSpectator = self:isa("Spectator") or self:isa("AlienSpectator")
    if(self:GetHealthScalar() <= Player.kLowHealthWarning) and not isSpectator then
    
        self.screenEffects.lowHealth:SetActive(true)
        local healthWeight = 1 - (self:GetHealthScalar() / Player.kLowHealthWarning)
        local pulseSpeed = Player.kLowHealthPulseSpeed / 2 + (Player.kLowHealthPulseSpeed / 2 * healthWeight)
        local pulseScalar = (math.sin(Shared.GetTime() * pulseSpeed) + 1) / 2
        healthWeight = 0.5 + (0.5 * (healthWeight * pulseScalar))
        self.screenEffects.lowHealth:SetParameter("healthWeight", healthWeight)
        
    else
    
        self.screenEffects.lowHealth:SetActive(false)
        
    end
    
    if self.timeOfLastPhase and (Shared.GetTime() - self.timeOfLastPhase <= Player.kPhaseEffectActiveTime) then
        self.screenEffects.phase:SetActive(true)
        if not self.phaseTweener then
            self.phaseTweener = Tweener("forward")
            self.phaseTweener.add(0, { amount = 1 }, Easing.linear)
            local amplitude = 0.01
            local period = Player.kPhaseEffectActiveTime * 0.75
            self.phaseTweener.add(Player.kPhaseEffectActiveTime, { amount = 0 }, Easing.outElastic, { amplitude, period })
        end
        self.phaseTweener.update(deltaTime)
        self.screenEffects.phase:SetParameter("amount", self.phaseTweener.getCurrentProperties().amount)
    else
        self.screenEffects.phase:SetActive(false)
        self.phaseTweener = nil
    end
    
    // If we're cloaked, change screen effect
    local cloakScreenEffectState = (HasMixin(self, "Cloakable") and self:GetIsCloaked()) or (HasMixin(self, "Camouflage") and self:GetIsCamouflaged())
    self:SetCloakShaderState(cloakScreenEffectState)
    
    self:UpdateCloakSoundLoop(cloakScreenEffectState)
    
    // Play disorient screen effect to show we're near a shade
    self:UpdateDisorientFX()

end

// Only called when not running prediction
function Player:UpdateClientEffects(deltaTime, isLocal)

    // Only show local player model and active weapon for local player when third person 
    // or for other players (not ethereal Fades)
    local drawWorld = ((not isLocal) or self:GetIsThirdPerson())
    local drawPlayer = drawWorld and (not self.GetIsEthereal or not self:GetIsEthereal())
    self:SetIsVisible(drawPlayer)
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
        activeWeapon:SetIsVisible( drawWorld )
    end
    
    // Hide view model for other players and when in third person
    local viewModel = self:GetViewModelEntity()    
    if viewModel and drawWorld then
        viewModel:SetIsVisible( false )
    end
    
    if isLocal then
        self:UpdateScreenEffects(deltaTime)
    end
    
end

function Player:ExpireDebugText()

    // Expire debug text items after lifetime has elapsed        
    local numElements = table.maxn(gDebugTextList)

    for i = 1, numElements do
    
        local elementPair = gDebugTextList[i]
        
        if elementPair and elementPair[1]:GetExpired() then
        
            GetGUIManager():DestroyGUIScript(elementPair[1])
            
            table.remove(gDebugTextList, i)
                
            numElements = numElements - 1
            
            i = i - 1
            
        end
        
    end
        
end

// Return flash player at index, creating it if it doesn't exist. Must call GetFlashPlayer(n-1) before calling GetFlashPlayer(n)
// or it will return nil. Start with GetFlashPlayer(1).
function GetFlashPlayer(index)

    // Create table if it doesn't exist
    if not gFlashPlayers then
        gFlashPlayers = {}
    end
    
    if index == nil then
        Print("GetFlashPlayer(nil): Error encountered - nil passed in as index")
        return nil
    end
    
    if(index > (table.maxn(gFlashPlayers) + 1)) then
        Print("GetFlashPlayer(%d): Error encountered - must have previously called GetFlashPlayer(%d) (num created: %d).", index, index - 1, table.maxn(gFlashPlayers))
        return nil
    end
    
    if(index > table.maxn(gFlashPlayers)) then
    
        local flashPlayer = Client.CreateFlashPlayer()
        Client.AddFlashPlayerToDisplay(flashPlayer)
        
        if gFlashPlayers[index] ~= nil then
            Print("GetFlashPlayer(%d): Creating flash player at index but flash player already there, overwriting", index)
        end
        
        gFlashPlayers[index] = flashPlayer
        
    end
    
    return gFlashPlayers[index]
    
end

// You can only remove the top-most flash player, or else it would invalidate the other indices.
function RemoveFlashPlayer(index)

    ASSERT(index ~= nil)
    
    if gFlashPlayers then
    
        if(index == table.maxn(gFlashPlayers)) then
        
            local flashPlayer = gFlashPlayers[index]
            Client.RemoveFlashPlayerFromDisplay(flashPlayer)
            Client.DestroyFlashPlayer(flashPlayer)
            gFlashPlayers[index] = nil
            
        elseif index < table.maxn(gFlashPlayers) then
            Print("RemoveFlashPlayer(%d): Error - can only remove top-most flash player (currently at index %d)", index, table.maxn(gFlashPlayers))
        end 
       
    else
        Print("RemoveFlashPlayer(%d): No flash players have been created, use GetFlashPlayer() first.", index)
    end
    
end

function GetFlashPlayerDisplaying(index)

    local displaying = false
    
    if gFlashPlayers ~= nil and index >= table.maxn(gFlashPlayers) then
    
        if gFlashPlayers[index] then
        
            displaying = true
            
        end
        
    end
    
    return displaying
    
end

function RemoveFlashPlayers( all )

    // Destroy all flash players
    if (gFlashPlayers ~= nil) then
    
        local startIndex = ConditionalValue(all, 1, kClassFlashIndex)
        
        for index = startIndex, table.count(gFlashPlayers) do
            RemoveFlashPlayer(index)
        end

        if all or table.count(gFlashPlayers) == 0 then
            gFlashPlayers = nil
        end
        
    end
    
end

function Player:SetDesiredName()

    // Set default player name to one set in Steam, or one we've used and saved previously
    local playerName = Client.GetOptionString( kNicknameOptionsKey, Client.GetUserName() )
   
    Client.ConsoleCommand(string.format("name \"%s\"", playerName))

end

// Called on the Client only, after OnInit(), for a ScriptActor that is controlled by the local player.
// Ie, the local player is controlling this Marine and wants to intialize local UI, flash, etc.
function Player:OnInitLocalClient()
    
    // Initialize offsets used for drawing tech ids as buttons
    InitTechTreeMaterialOffsets()

    // Only create base HUDs the first time a player is created.
    // We only ever want one of these.
    GetGUIManager():CreateGUIScriptSingle("GUICrosshair")
    GetGUIManager():CreateGUIScriptSingle("GUIScoreboard")
    GetGUIManager():CreateGUIScriptSingle("GUINotifications")
    GetGUIManager():CreateGUIScriptSingle("GUIRequests")
    GetGUIManager():CreateGUIScriptSingle("GUIDamageIndicators")
    GetGUIManager():CreateGUIScriptSingle("GUIDeathMessages")
    GetGUIManager():CreateGUIScriptSingle("GUIChat")
    GetGUIManager():CreateGUIScriptSingle("GUIVoiceChat")
    self.minimapScript = GetGUIManager():CreateGUIScriptSingle("GUIMinimap")
    GetGUIManager():CreateGUIScriptSingle("GUIMapAnnotations")
    
    // In case we were commanding on map reset, hide the mouse
    // unless a menu is visible.
    if MenuManager.GetMenu() == nil then
        Client.SetMouseVisible(false)
        Client.SetMouseCaptured(true)
        Client.SetMouseClipped(false)
    end
    
    // Re-enable skybox rendering after commanding
    SetSkyboxDrawState(true)
    
    // Show props normally
    SetCommanderPropState(false)
    
    // Turn on sound occlusion for non-commanders
    Client.SetSoundGeometryEnabled(true)
    
    // Setup materials, etc. for death messages
    InitDeathMessages(self)
    
    self:ClearDisplayedTooltips()
    
    // Fix after Main/Client issue resolved
    self:SetDesiredName()
    
    self.cameraShakeAmount = 0
    self.cameraShakeSpeed = 0
    self.cameraShakeTime = 0
    self.cameraShakeLastTime = 0
    
    self.crossHairText = ""
    self.crossHairTextColor = kFriendlyNeutralColor
    
    self.traceReticle = false
    
    self.damageIndicators = {}
    
    // Set commander geometry visible
    Client.SetGroupIsVisible(kCommanderInvisibleGroupName, true)
    
    Client.SetEnableFog(true)
    
    self:InitScreenEffects()
    
end

function Player:InitScreenEffects()

    self.screenEffects = {}
    self.screenEffects.fadeBlink = Client.CreateScreenEffect("shaders/FadeBlink.screenfx")
    self.screenEffects.fadeBlink:SetActive(false)
    self.screenEffects.flare = Client.CreateScreenEffect("shaders/Flare.screenfx")
    self.screenEffects.lowHealth = Client.CreateScreenEffect("shaders/LowHealth.screenfx")
    self.screenEffects.darkVision = Client.CreateScreenEffect("shaders/DarkVision.screenfx")
    self.screenEffects.darkVision:SetActive(false)    
    self.screenEffects.blur = Client.CreateScreenEffect("shaders/Blur.screenfx")
    self.screenEffects.blur:SetActive(false)
    self.screenEffects.phase = Client.CreateScreenEffect("shaders/Phase.screenfx")
    self.screenEffects.phase:SetActive(false)
    self.screenEffects.cloaked = Client.CreateScreenEffect("shaders/Cloaked.screenfx")
    self.screenEffects.cloaked:SetActive(false)
    self.screenEffects.disorient = Client.CreateScreenEffect("shaders/Disorient.screenfx")
    self.screenEffects.disorient:SetActive(false)
    
end

function Player:SetEthereal(ethereal)
    if not ethereal or not self:GetIsThirdPerson() then
        self.screenEffects.fadeBlink:SetActive(ethereal)
    end
end

function Player:SetCloakShaderState(cloaked)
    if not cloaked or not self:GetIsThirdPerson() then
        self.screenEffects.cloaked:SetActive(cloaked)
    end
end

function Player:UpdateDisorientSoundLoop(state)

    // Start or stop sound effects
    if state ~= self.playerDisorientSoundLoopPlaying then
        
        self:TriggerEffects("disorient_loop", {active = state})
        self.playerDisorientSoundLoopPlaying = state
        
    end

end

function Player:UpdateCloakSoundLoop(state)

    // Start or stop sound effects
    if state ~= self.playerCloakSoundLoopPlaying then
        
        self:TriggerEffects("cloak_loop", {active = state})
        self.playerCloakSoundLoopPlaying = state
        
    end
 
end

function Player:UpdateDisorientFX()
    
    local amount = 0
    if HasMixin(self, "Disorientable") then
        amount = self:GetDisorientedAmount()
    end

    local state = (amount > 0)
    if not self:GetIsThirdPerson() or not state then
        self.screenEffects.disorient:SetActive(state)
    end
    
    self.screenEffects.disorient:SetParameter("amount", amount)
    
    self:UpdateDisorientSoundLoop(state)
    
end

/**
 * Called when the player entity is destroyed.
 */
function Player:OnDestroy()

    LiveScriptActor.OnDestroy(self)
    
    if (self.viewModel ~= nil) then
        Client.DestroyRenderViewModel(self.viewModel)
        self.viewModel = nil
    end
    
    self:DestroyScreenEffects()
    
    self:UpdateCloakSoundLoop(false)
    self:UpdateDisorientSoundLoop(false)    
    
    self:CloseMenu(kClassFlashIndex)
    
end

function Player:DestroyScreenEffects()

    if(self.screenEffects ~= nil) then
    
        for effectName, effect in pairs(self.screenEffects) do
        
            Client.DestroyScreenEffect(effect)

        end
        
        self.screenEffects = {}
        
    end

end

function Player:DrawGameStatusMessage()

    local time = Shared.GetTime()
    local fraction = 1 - (time - math.floor(time))
    Client.DrawSetColor(255, 0, 0, fraction*200)

    if(self.countingDown) then
    
        Client.DrawSetTextPos(.42*Client.GetScreenWidth(), .95*Client.GetScreenHeight())
        Client.DrawString("Game is starting")
        
    else
    
        Client.DrawSetTextPos(.25*Client.GetScreenWidth(), .95*Client.GetScreenHeight())
        Client.DrawString("Game will start when both sides have players")
        
    end

end

function entityIdInList(entityId, entityList, useParentId)

    for index, entity in ipairs(entityList) do
    
        local id = entity:GetId()
        if(useParentId) then id = entity:GetParentId() end
        
        if(id == entityId) then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Player:DebugVisibility()

    // For each visible entity on other team
    local entities = GetEntitiesMatchAnyTypesForTeam({"Player", "ScriptActor"}, GetEnemyTeamNumber(self:GetTeamNumber()))
    
    for entIndex, entity in ipairs(entities) do
    
        // If so, remember that it's seen and break
        local seen = self:GetCanSeeEntity(entity)            
        
        // Draw red or green depending
        DebugLine(self:GetEyePos(), entity:GetOrigin(), 1, ConditionalValue(seen, 0, 1), ConditionalValue(seen, 1, 0), 0, 1)
        
    end

end

// Opens a menu in the kMenuFlashIndex layer
function Player:OpenMenu(swfMenuName)

    if(not Client.GetMouseVisible() and (Client.GetLocalPlayer() == self)) then
    
        GetFlashPlayer(kMenuFlashIndex):Load(swfMenuName)
        GetFlashPlayer(kMenuFlashIndex):SetBackgroundOpacity(0)
        
        Client.SetCursor("ui/Cursor_MenuDefault.dds")
        Client.SetMouseVisible(true)
        Client.SetMouseCaptured(false)
        Client.SetMouseClipped(true)
        
        return true

    end
    
    return false
           
end

function Player:CloseMenu(flashIndex)

    local success = false
    
    if flashIndex == nil and gFlashPlayers ~= nil then
        // Close top-level menu if not specified
        flashIndex = table.maxn(gFlashPlayers)
    end
    
    if(self == Client.GetLocalPlayer() and GetFlashPlayerDisplaying(flashIndex)) then
        
        RemoveFlashPlayer(flashIndex)
    
        // Do not take away mouse from the player if they are a commander.
        // They are going to want the mouse.
        if not self:GetIsCommander() then
            Client.SetMouseVisible(false)
            Client.SetMouseCaptured(true)
            Client.SetMouseClipped(false)
        end
        
        // Quick work-around to not fire weapon when closing menu
        self.timeClosedMenu = Shared.GetTime()
        
        success = true

    end
    
    return success
    
end

function Player:ShowMap(showMap)

    self.minimapScript:ShowMap(showMap)

end

function Player:GetWeaponAmmo()

    // We could do some checks to make sure we have a non-nil ClipWeapon,
    // but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and weapon:isa("ClipWeapon")) then
        return weapon:GetAmmo()
    end
    
    return 0
    
end

function Player:GetWeaponClip()

    // We could do some checks to make sure we have a non-nil ClipWeapon,
    // but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and weapon:isa("ClipWeapon")) then
        return weapon:GetClip()
    end
    
    return 0
    
end

function Player:GetAuxWeaponClip()

    // We could do some checks to make sure we have a non-nil ClipWeapon,
    // but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if(weapon ~= nil and weapon:isa("ClipWeapon")) then
        return weapon:GetAuxClip()
    end
    
    return 0
    
end

function Player:GetCameraViewCoordsOverride(cameraCoords)
   
    // Add in camera movement from view model animation
    if self:GetCameraDistance() == 0 then    
    
        local viewModel = self:GetViewModelEntity()
        if viewModel then
        
            local success, viewModelCameraCoords = viewModel:GetCameraCoords()
            if success then
            
                cameraCoords = cameraCoords * viewModelCameraCoords
                
            end
            
        end
    
    end
    
    // Allow weapon or ability to override camera (needed for Blink)
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
    
        local override, newCoords = activeWeapon:GetCameraCoords()
        
        if override then
            cameraCoords = newCoords
        end
        
    end

    // Add in camera shake effect if any
    if(Shared.GetTime() < self.cameraShakeTime) then
    
        // Camera shake knocks view up and down a bit
        local shakeAmount = math.sin( Shared.GetTime() * self.cameraShakeSpeed * 2 * math.pi ) * self.cameraShakeAmount
        local origin = Vector(cameraCoords.origin)
        
        //cameraCoords.origin = cameraCoords.origin + self.shakeVec*shakeAmount
        local yaw = GetYawFromVector(cameraCoords.zAxis)
        local pitch = GetPitchFromVector(cameraCoords.zAxis) + shakeAmount
        local angles = Angles(pitch, yaw, 0)
        cameraCoords = angles:GetCoords(origin)
        
    end
    
    cameraCoords = self:PlayerCameraCoordsAdjustment(cameraCoords)
        
    return cameraCoords
    
end

function Player:PlayerCameraCoordsAdjustment(cameraCoords)

    // No adjustment by default. This function can be overridden to modify the camera
    // coordinates right before rendering.
    return cameraCoords

end

// Ignore camera shaking when done quickly in a row
function Player:SetCameraShake(amount, speed, time)

    // Overrides existing shake if it has elapsed or if new shake amount is larger
    local success = false
    
    local currentTime = Shared.GetTime()
    
    if currentTime > (self.cameraShakeLastTime + .5) then
    
        if currentTime > self.cameraShakeTime or amount > self.cameraShakeAmount then
        
            self.cameraShakeAmount = amount

            // "bumps" per second
            self.cameraShakeSpeed = speed 
            
            self.cameraShakeTime = currentTime + time
            
            self.cameraShakeLastTime = currentTime
            
            success = true
            
        end
        
    end
    
    return success
    
end

// For drawing build circles
function GameUI_GetBuildStatus(entityId)

    local entity = Shared.GetEntity(entityId)
    
    if(entity ~= nil) then
    
        if(entity:isa("Structure")) then
        
            if(entity:GetIsBuilt()) then
                return 1.0
            end
            
            return entity:GetBuiltFraction()
            
        else
        
            Print("GameUI_GetBuildStatus(%d) - Entity not a BuildableStructure (%s instead).", entityId, entity:GetMapName())
            
        end
        
    end
    
    return 0
    
end

// True means display the menu or sub-menu
function PlayerUI_ShowSayings()
    local player = Client.GetLocalPlayer()    
    if player then
        return player:GetShowSayings()
    end
    return nil
end

// return array of sayings
function PlayerUI_GetSayings()

    local sayings = nil
    local player = Client.GetLocalPlayer()        
    if(player:GetHasSayings()) then
        sayings = player:GetSayings()
    end
    return sayings
    
end

// Returns 0 unless a saying was just chosen. Returns 1 - number of sayings when one is chosen.
function PlayerUI_SayingChosen()
    local player = Client.GetLocalPlayer()
    if player then
        local saying = player:GetAndClearSaying()
        if(saying ~= nil) then
            return saying
        end
    end
    return 0
end

// Draw the current location on the HUD ("Marine Start", "Processing", etc.)
function PlayerUI_GetLocationName()

    local locationName = ""
    
    local player = Client.GetLocalPlayer()    
    if(player ~= nil and player:GetIsPlaying()) then
        locationName = player:GetLocationName()
    end
    
    return locationName
    
end

function PlayerUI_GetOrigin()

    local player = Client.GetLocalPlayer()    
    if player ~= nil then
        return player:GetOrigin()
    end
    
    return Vector(0, 0, 0)

end

function PlayerUI_GetEyePos()

    local player = Client.GetLocalPlayer()    
    if player ~= nil then
        return player:GetEyePos()
    end
    
    return Vector(0, 0, 0)
    
end

function PlayerUI_GetForwardNormal()

    local player = Client.GetLocalPlayer()    
    if player ~= nil then
        return player:GetCameraViewCoords().zAxis
    end
    return Vector(0, 0, 1)

end

function PlayerUI_IsACommander()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:isa("Commander")
    end
    
    return false

end

function PlayerUI_IsAReadyRoomPlayer()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:GetTeamNumber() == kTeamReadyRoom
    end
    
    return false
    
end

function PlayerUI_GetTeamColor(teamNumber)

    if teamNumber then
        return ColorIntToColor(GetColorForTeamNumber(teamNumber))
    else
        local player = Client.GetLocalPlayer()
        return ColorIntToColor(GetColorForPlayer(player))
    end
    
end

/**
 * Returns all locations as a name and origin.
 */
function PlayerUI_GetLocationData()

    local returnData = { }
    local locationEnts = GetLocations()
    for i, location in ipairs(locationEnts) do
        if location:GetShowOnMinimap() then
            table.insert(returnData, { Name = location:GetName(), Origin = location:GetOrigin() })
        end
    end
    return returnData

end

/**
 * Converts world coordinates into normalized map coordinates.
 */
function PlayerUI_GetMapXY(worldX, worldZ)

    local player = Client.GetLocalPlayer()
    if player then
        local success, mapX, mapY = player:GetMapXY(worldX, worldZ)
        return mapX, mapY
    end
    return 0, 0

end

/**
 * Returns a linear array of static blip data
 * X position, Y position, rotation, X texture offset, Y texture offset, kMinimapBlipType, kMinimapBlipTeam
 *
 * Eg {0.5, 0.5, 1.32, 0, 0, 3, 1}
 */
function PlayerUI_GetStaticMapBlips()

    player = Client.GetLocalPlayer()
    
    local blipsData = {}
    
    if player then
    
        for index, blip in ientitylist(Shared.GetEntitiesWithClassname("MapBlip")) do
            
            if blip.ownerEntityId ~= player:GetId() then
                
                local blipOrigin = blip:GetOrigin()
                table.insert(blipsData, blipOrigin.x)
                table.insert(blipsData, blipOrigin.z)
                table.insert(blipsData, blip:GetRotation())
                table.insert(blipsData, 0)
                table.insert(blipsData, 0)
                table.insert(blipsData, blip:GetType())
                local blipTeam = kMinimapBlipTeam.Neutral
                if blip:GetTeamNumber() == player:GetTeamNumber() then
                    blipTeam = kMinimapBlipTeam.Friendly
                elseif blip:GetTeamNumber() == GetEnemyTeamNumber(player:GetTeamNumber()) then
                    blipTeam = kMinimapBlipTeam.Enemy
                end
                table.insert(blipsData, blipTeam)
            
            end            
            
        end
        
    end
    
    return blipsData
    
end

/**
 * Damage indicators. Returns a array of damage indicators which are used to draw red arrows pointing towards
 * recent damage. Each damage indicator pair will consist of an alpha and a direction. The alpha is 0-1 and the
 * direction in radians is the angle at which to display it. 0 should face forward (top of the screen), pi 
 * should be behind us (bottom of the screen), pi/2 is to our left, 3*pi/2 is right.
 * 
 * For two damage indicators, perhaps:
 *  {alpha1, directionRadians1, alpha2, directonRadius2}
 *
 * It returns an empty table if the player has taken no damage recently. 
 */
function PlayerUI_GetDamageIndicators()

    local drawIndicators = {}
    
    local player = Client.GetLocalPlayer()
    if player then
    
        for index, indicatorTriple in ipairs(player.damageIndicators) do
            
            local alpha = Clamp(1 - ((Shared.GetTime() - indicatorTriple[3])/Player.kDamageIndicatorDrawTime), 0, 1)
            table.insert(drawIndicators, alpha)

            local worldX = indicatorTriple[1]
            local worldZ = indicatorTriple[2]
            
            local normDirToDamage = GetNormalizedVector(Vector(player:GetOrigin().x, 0, player:GetOrigin().z) - Vector(worldX, 0, worldZ))
            local worldToView = player:GetViewAngles():GetCoords():GetInverse()
            
            local damageDirInView = worldToView:TransformVector(normDirToDamage)
            
            local directionRadians = math.atan2(damageDirInView.x, damageDirInView.z)
            if directionRadians < 0 then
                directionRadians = directionRadians + 2 * math.pi
            end
            
            table.insert(drawIndicators, directionRadians)
            
        end
        
    end
    
    //if table.count(drawIndicators) > 0 then
    //    Print("PlayerUI_GetDamageIndicators() => %s", table.tostring(drawIndicators))
    //end
    
    return drawIndicators
    
end

// Displays an image around the crosshair when the local player has given damage to something else.
// Returns true if the indicator should be displayed and the time that has passed as a percentage.
function PlayerUI_GetShowGiveDamageIndicator()

    local player = Client.GetLocalPlayer()
    if player and player.giveDamageTime then
        local timePassed = Shared.GetTime() - player.giveDamageTime
        return timePassed <= Player.kShowGiveDamageTime, math.min(timePassed / Player.kShowGiveDamageTime, 1)
    end
    return false, 0

end

function Player:AddTakeDamageIndicator(worldX, worldZ)

    // Insert triple indicating when damage was taken and from where it came 
    local triple = {worldX, worldZ, Shared.GetTime()}
    table.insert(self.damageIndicators, triple)
    
end

function Player:AddGiveDamageIndicator(damageAmount)

    self.giveDamageTime = Shared.GetTime()
    
end

function Player:UpdateDamageIndicators()

    local indicesToRemove = {}
    
    // Expire old damage indicators
    for index, indicatorTriple in ipairs(self.damageIndicators) do
    
        if Shared.GetTime() > (indicatorTriple[3] + Player.kDamageIndicatorDrawTime) then
        
            table.insert(indicesToRemove, index)
            
        end
        
    end
    
    for i, index in ipairs(indicesToRemove) do
        table.remove(self.damageIndicators, index)
    end
    
end

// Set after hotgroup updated over the network
function Player:SetHotgroup(number, entityList)

    if(number >= 1 and number <= Player.kMaxHotkeyGroups) then
        //table.copy(entityList, self.hotkeyGroups[number])
        self.hotkeyGroups[number] = entityList
    end
    
end

function Player:OnSynchronized()

    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
        
        // Make sure to call OnInit() for client entities that have been propagated by the server
        if(not self.clientInitedOnSynch) then
        
            self:OnInit()
            
            // Only call OnInitLocalClient() for entities that are the local player
            if(Client and (player == self)) then   
                self:OnInitLocalClient()    
            end
            
            self.clientInitedOnSynch = true
            
        end

        // Update these here because they could update hitboxes
        local deltaTime = 0
        local currentTime = Shared.GetTime()
        if self.lastSynchronizedTime ~= nil then
            deltaTime = currentTime - self.lastSynchronizedTime
        end
        
        self:UpdatePoseParameters(deltaTime)
        self.lastSynchronizedTime = currentTime
        
        LiveScriptActor.OnSynchronized(self)
        
    end
    
end

function Player:OnUpdate(deltaTime)

    PROFILE("Player_Client:OnUpdate")
    
    // Need to update pose parameters every frame to keep them smooth
    LiveScriptActor.OnUpdate(self, deltaTime)
    
    local isLocal = (self == Client.GetLocalPlayer())
    
    if not isLocal then
        self:UpdatePoseParameters(deltaTime)
    end

    self:UpdateClientEffects(deltaTime, isLocal)
    
    self:ExpireDebugText()
    
end

function Player:UpdateGUI()

    // Update the view model's GUI.
    
    local viewModel = self:GetViewModelEntity()    
    if(viewModel ~= nil) then
        viewModel:UpdateGUI()
    end

end

function Player:UpdateChat(input)

    if not Shared.GetIsRunningPrediction() then
    
        // Enter chat message
        if (bit.band(input.commands, Move.TextChat) ~= 0) then
            ChatUI_EnterChatMessage(false)
        end

        // Enter chat message
        if (bit.band(input.commands, Move.TeamChat) ~= 0) then
            ChatUI_EnterChatMessage(true)
        end
        
    end
    
end

function Player:GetCustomSelectionText()
    return string.format("%s kills\n%s deaths\n%s score",
            ToString(Scoreboard_GetPlayerData(self:GetClientIndex(), "Kills")),
            ToString(Scoreboard_GetPlayerData(self:GetClientIndex(), "Deaths")),
            ToString(Scoreboard_GetPlayerData(self:GetClientIndex(), "Score")))
end
