// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerPoint_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

PowerPoint.kDisabledColor = Color(1, 0, 0)
// chance of a aux light flickering when powering up
PowerPoint.kAuxFlickerChance = 0
// chance of a full light flickering when powering up
PowerPoint.kFullFlickerChance = 0.30

// determines if aux lights will randomly fail after they have come on for a certain amount of time
PowerPoint.kAuxLightsFail = false

// max varying delay to turn on full lights
PowerPoint.kMaxFullLightDelay = 4
// min 2 seconds from repairing the node till the light goes on
PowerPoint.kMinFullLightDelay = 2
// how long time for the light to reach full power (PowerOnTime was a bit brutal and give no chance for the flicker to work)
PowerPoint.kFullPowerOnTime = 4

// max varying delay to turn on aux lights
PowerPoint.kMaxAuxLightDelay = 4

// minimum time that aux lights are on before they start going out
PowerPoint.kAuxLightSafeTime = 20 // short for testing, should be like 300 (5 minutes)
// maximum time for a power point to stay on after the safe time
PowerPoint.kAuxLightFailTime = 20 // short .. should be like 600 (10 minues)
// how long time a light takes to go from full aux power to dead (last 1/3 of that time is spent flickering)
PowerPoint.kAuxLightDyingTime = 20

function PowerPoint:UpdatePoweredLights()
    
    if not self.lightList then    
        self.lightList = GetLightsForPowerPoint(self)
        
        // random value used to individualize each light
        self.perLightRandom = {}
        for _,light in ipairs(self.lightList) do
            self.perLightRandom[light] = Shared.GetRandomFloat()
        end
        self.timeOfFirstModeChange = self:GetTimeOfLightModeChange()
   
    end
    
    for lightIndex, renderLight in ipairs(self.lightList) do
        self:UpdatePoweredLight(renderLight)
    end
end

// Used for efficiency, so we don't have iterate over lights unnecessarily
// if a light enters a state where it can stay constant until the next powernode change, it
// is added to the unchangedLights table. When all lights are in that table, we can 
// return false and say that we are not having any lights that need updating.
function PowerPoint:GetIsAffectingLights()

    // if the unchanged list has been collected during another lightmode, it needs resetting
    if self.unchangedMode ~= self:GetLightMode() then
        // whenever we change mode, we need to start updating the lights again
        self.unchangingLights = {}
        self.unchangedMode = self:GetLightMode()
        // reset which light flickers
        self.lightFlickers = {}
    end

    // the insanity of a language that doens't keep track of (or rather, doesn't have a 
    // method of finding out) the number of keys in a table is kinda amazing.
    local unchangedCount =  table.countkeys(self.unchangingLights)
    local lightListLen = self.lightList and #self.lightList or -1
    local result = unchangedCount ~= lightListLen
    return result
end

function PowerPoint:UpdatePoweredLight(renderLight)

    local lightMode = self:GetLightMode()
    local timeOfChange = self:GetTimeOfLightModeChange()
    local time = Shared.GetTime()
    local timePassed = time - timeOfChange
    
    local randomValue = self.perLightRandom[renderLight]
    
    // the various mode-altering points
    
    // full power times
    // full power light start coming on 
    local startFullLightTime = PowerPoint.kMinFullLightDelay + PowerPoint.kMaxFullLightDelay * randomValue
    // time when full lightning is achieved
    local fullFullLightTime = startFullLightTime + PowerPoint.kFullPowerOnTime  

    if timeOfChange == self.timeOfFirstModeChange then
        // stop flickering light at start of game
        timePassed = timePassed + fullFullLightTime
    end

    // aux times 
    // aux light starting to come on
    local startAuxLightTime = PowerPoint.kPowerDownTime + PowerPoint.kOffTime + randomValue * PowerPoint.kMaxAuxLightDelay 
    // ... fully on
    local fullAuxLightTime = startAuxLightTime + PowerPoint.kAuxPowerCycleTime
    // aux lights starts to fade
    local startAuxLightFailTime = fullAuxLightTime + PowerPoint.kAuxLightSafeTime + randomValue * PowerPoint.kAuxLightFailTime
    // ... and dies completly
    local totalAuxLightFailTime = startAuxLightFailTime + PowerPoint.kAuxLightDyingTime
    
    // initialize to default
    local color = renderLight.originalColor
    local intensity = renderLight.originalIntensity
    
    local color_right = renderLight.originalRight
    local color_left = renderLight.originalLeft
    local color_up = renderLight.originalUp
    local color_down = renderLight.originalDown
    local color_forward = renderLight.originalForward
    local color_backward = renderLight.originalBackward
    
    // Don't affect lights that have this set in editor
    if not renderLight.ignorePowergrid then
    
        // Bring lights back on
        if lightMode == kLightMode.Normal then
        
            if timePassed < startFullLightTime then
            
                //  delay before we power on
                self:SetupFlicker(renderLight, PowerPoint.kFullFlickerChance) 
                // keep the current color/intensity  
                color = nil
                intensity = nil 
                color_right = nil
                color_left = nil
                color_up = nil
                color_down = nil
                color_forward = nil
                color_backward = nil  
          
            elseif timePassed < fullFullLightTime then
            
                local t = timePassed - startFullLightTime
                local scalar = math.sin(( t / PowerPoint.kFullPowerOnTime  ) * math.pi / 2)
                intensity = intensity * scalar 
                if self.lightFlickers[renderLight] then
                    intensity = intensity * self:FlickerLight(scalar)
                end
                
            else 
            
                self.unchangingLights[renderLight] = true
                
            end
           
        elseif lightMode == kLightMode.NoPower then
        
            if timePassed < PowerPoint.kPowerDownTime then
            
                local scalar = math.sin( Clamp(timePassed/PowerPoint.kPowerDownTime, 0, 1) * math.pi / 2)
                intensity = intensity * (1 - scalar)

            elseif timePassed < startAuxLightTime then
            
                self:SetupFlicker(renderLight,PowerPoint.kAuxFlickerChance)
                intensity = 0           
                
            elseif timePassed < fullAuxLightTime then
            
                // Fade red in smoothly. t will stay at zero during the individual delay time
                local t = timePassed - startAuxLightTime
                // angle goes from zero to 90 degres in one kAuxPowerCycleTime
                local angleRad = (t / PowerPoint.kAuxPowerCycleTime) * math.pi / 2
                // and scalar goes 0->1
                local scalar = math.sin(angleRad)
                
                intensity = scalar * intensity

                self.lightFlickers = self.lightFlickers or {}
                if self.lightFlickers[renderLight] then
                    intensity = intensity * self:FlickerLight(scalar)                       
                end
                
                //if renderLight == self.lightList[1] then
                //    Shared.Message("SAT t " .. t .. ", sc " .. scalar.. ", int " .. intensity)
                //end
                
                color = PowerPoint.kDisabledColor
                
                if renderLight:GetType() == RenderLight.Type_AmbientVolume then
                    color_right = PowerPoint.kDisabledColor
                    color_left = PowerPoint.kDisabledColor
                    color_up = PowerPoint.kDisabledColor
                    color_down = PowerPoint.kDisabledColor
                    color_forward = PowerPoint.kDisabledColor
                    color_backward = PowerPoint.kDisabledColor
                end
         
            elseif not PowerPoint.kAuxLightsFail or timePassed < totalAuxLightFailTime then
                do
                    // Fade disabled color in and out to make it very clear that the power is out        
                    local t = timePassed - fullAuxLightTime               
                    local scalar = math.cos((t / (PowerPoint.kAuxPowerCycleTime/2)) * math.pi / 2)
                    local halfAmplitude = (1 - PowerPoint.kAuxPowerMinIntensity)/2
                    
                    local disabledIntensity = (PowerPoint.kAuxPowerMinIntensity + halfAmplitude + scalar * halfAmplitude)
                    intensity = intensity * disabledIntensity
                    //Print("Setting light intensity: %.2f (disabled intensity: %.2f)", intensity, disabledIntensity)
                    color = PowerPoint.kDisabledColor    
                    
                    //if renderLight == self.lightList[1] then
                    //    Shared.Message("FAT t " .. t .. ", sc " .. scalar .. ", int " .. intensity)
                    //end
                end
                if  PowerPoint.kAuxLightsFail and timePassed > startAuxLightFailTime then     
                    // Fade to black in kAuxLightDyingTime
                    local t = timePassed - startAuxLightFailTime
                    local scalar = math.cos((t / PowerPoint.kAuxLightDyingTime) * math.pi / 2)
                    // flicker the light as it is dying (scalar < 0.5, roughly the last third of dying time
                    intensity = intensity * scalar * self:FlickerLight(scalar)   
                    //if renderLight == self.lightList[1] then
                    //    Shared.Message("ALF t " .. t .. ", sc " .. scalar.. ", int " .. intensity)
                    //end  
                end
                
                color = PowerPoint.kDisabledColor
                
                if renderLight:GetType() == RenderLight.Type_AmbientVolume then
                    color_right = PowerPoint.kDisabledColor
                    color_left = PowerPoint.kDisabledColor
                    color_up = PowerPoint.kDisabledColor
                    color_down = PowerPoint.kDisabledColor
                    color_forward = PowerPoint.kDisabledColor
                    color_backward = PowerPoint.kDisabledColor
                end
                
            else
                // completely dead...
                intensity = 0
                self.unchangingLights[renderLight] = true

            end
            

        elseif lightMode == kLightMode.LowPower then

             // Cycle lights up and down telling everyone that there's an imminent threat
            local scalar = math.cos ((timePassed / (PowerPoint.kLowPowerCycleTime/2)) * math.pi / 2)
            local halfIntensity = (1 - PowerPoint.kLowPowerMinIntensity)/2
            intensity = intensity * PowerPoint.kLowPowerMinIntensity + halfIntensity + scalar * halfIntensity

        // Cycle once when taking damage
        elseif lightMode == kLightMode.Damaged then

            local scalar = math.sin( Clamp(timePassed/PowerPoint.kDamagedCycleTime, 0, 1) * math.pi)
            intensity = intensity * (1 - scalar * (1 - PowerPoint.kDamagedMinIntensity))
                    
        end
        
    end
    
    if intensity then
        renderLight:SetIntensity( intensity )
    end
    if color then
        renderLight:SetColor( color )
    end 
    if color_right then
        renderLight:SetDirectionalColor(RenderLight.Direction_Right,    color_right)
        renderLight:SetDirectionalColor(RenderLight.Direction_Left,     color_left)
        renderLight:SetDirectionalColor(RenderLight.Direction_Up,       color_up)
        renderLight:SetDirectionalColor(RenderLight.Direction_Down,     color_down)
        renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  color_forward)
        renderLight:SetDirectionalColor(RenderLight.Direction_Backward, color_backward)
    end
    
end

function PowerPoint:SetupFlicker(renderLight, chance)
    if self.lightFlickers[renderLight] == nil then
        self.lightFlickers[renderLight] = math.random() < chance
    end
end

function PowerPoint:FlickerLight(scalar)
    if (scalar < .5) then
        local flicker_intensity = Clamp(math.sin(math.pow((1 - scalar) * 6, 8)) + 1, .8, 2) / 2.0
        return flicker_intensity * flicker_intensity
    end
    return 1
end

function PowerPoint:CreateEffects()

    // Create looping cinematics if we're low power or no power
    local lightMode = self:GetLightMode() 
    
    if lightMode == kLightMode.LowPower and not self.lowPowerEffect then
    
        self.lowPowerEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        self.lowPowerEffect:SetCinematic(PowerPoint.kDamagedEffect)        
        self.lowPowerEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.lowPowerEffect:SetCoords(self:GetCoords())
        self.timeCreatedLowPower = Shared.GetTime()
    
    elseif lightMode == kLightMode.NoPower and not self.noPowerEffect then

        self.noPowerEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        self.noPowerEffect:SetCinematic(PowerPoint.kOfflineEffect)        
        self.noPowerEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.noPowerEffect:SetCoords(self:GetCoords())
        self.timeCreatedNoPower = Shared.GetTime()
    
    end

end

function PowerPoint:DeleteEffects()

    local lightMode = self:GetLightMode() 

    // Delete old effects when they shouldn't be played any more, and also every three seconds
    local kReplayInterval = 3
    
    if (lightMode ~= kLightMode.LowPower and self.lowPowerEffect) or (self.timeCreatedLowPower and (Shared.GetTime() > self.timeCreatedLowPower + kReplayInterval)) then
    
        Client.DestroyCinematic(self.lowPowerEffect)
        self.lowPowerEffect = nil
        self.timeCreatedLowPower = nil

    end

    if (lightMode ~= kLightMode.NoPower and self.noPowerEffect) or (self.timeCreatedNoPower and (Shared.GetTime() > self.timeCreatedNoPower + kReplayInterval)) then
            
        Client.DestroyCinematic(self.noPowerEffect)
        self.noPowerEffect = nil
        self.timeCreatedNoPower = nil

    end

end

function PowerPoint:OnDestroy()

    if self.lowPowerEffect then
        Client.DestroyCinematic(self.lowPowerEffect)
        self.lowPowerEffect = nil
    end

    if self.noPowerEffect then
        Client.DestroyCinematic(self.noPowerEffect)
        self.noPowerEffect = nil
    end

    Structure.OnDestroy(self)

end