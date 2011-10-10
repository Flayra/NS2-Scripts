// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerManager.lua
//
// Created by: Andrew Spiering (andrew@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'PowerGrid'

function PowerGrid:Intialize(width, height)
    self.width = width
    self.height = height
    
    self.data = {}
end

function PowerGrid:GetWidth()
    return self.width
end

function PowerGrid:GetHeight()
    return self.height
end

function PowerGrid:SetValue(x, y, val)
    ASSERT(x >= 0 and y >= 0 and x < self.width and y < self.height)
    
    self.data[y * self.width + x] =  val
end

function PowerGrid:GetHasPower(x, y)
    local hasPower = false
    if(x < 0 or y < 0 or x >= self.width or p.y >= self.height) then
	    hasPower = false
	else
        if (self.data[y * self.width + x] ~= 0 and self.data[y * self.width + x] ~= nil ) then
            hasPower = true
        end
    end

    return hasPower
end

class 'PowerManager' 
PowerManager.kPowerOffEvent = "PowerOff"
PowerManager.kPowerOnEvent  = "PowerOn"

function PowerManager:Initialize(mapWidth, mapHeight)
  //  self.powerGrid = PowerGrid()
  //  self.powerGrid:Initialize(mapWdith, mapHeight)
    
    self.powerEvents = {}
end

function PowerManager:UpdatePowerCells(powerSource, power, center, radius, sendEvent)
    // $AS TODO: User powerGrid instead of power source to check if need power    
    local eventName = ConditionalValue(power, PowerManager.kPowerOnEvent, PowerManager.kPowerOffEvent)
    local ents      = self.powerEvents[eventName]
    
    if (ents ~= nil and sendEvent) then
        for index, entityId in ipairs(ents) do
            local entity = Shared.GetEntity(entityId)
            if (entity and entity:GetRequiresPower()) then            
                self:GetIsLocationPowered(entity, true)
            end
        end
    end        
end

function PowerManager:SendPowerEvent(powerSource, entity, power)
    if not HasMixin(entity, "Power") then
        return
    end
    
    if (power) then
        entity:OnPowerOnEvent(powerSource)
    else
        entity:OnPowerOffEvent(powerSource)
    end    
end

function PowerManager:RegisterPowerEvent(entity, event)
    if (self.powerEvents[event] == nil) then
        self.powerEvents[event] = {}
    end    
    
    table.insertunique(self.powerEvents[event], entity:GetId())
end

function PowerManager:UnRegisterPowerEvent(entity, event)    
    if (self.powerEvents[event] ~= nil) then
        table.removevalue(self.powerEvents[event], entity:GetId())       
    end            
end

function PowerManager:GetIsLocationPowered(entity, sendEvent)
    //$AS TODO: Use powerGrid instead of this horrible search method that makes me sad
    local foundPower = false
    function FindPowerSource()
        for index, powerPoint in ientitylist(Shared.GetEntitiesWithClassname("PowerPoint")) do            
            if powerPoint:GetLocationName() == entity:GetLocationName() and powerPoint:GetIsPowered() then
                return powerPoint                    
            end            
        end       
        local powerPacks = GetEntitiesForTeamWithinXZRange("PowerPack", entity:GetTeamNumber(), entity:GetOrigin(), PowerPack.kRange)
    
        for index, powerPack in ipairs(powerPacks) do    
            if powerPack:GetIsPowered() then        
                return powerPack            
            end            
        end
        return nil
    end
    
    local powerSource = FindPowerSource()
    if (powerSource ~= nil) then
        foundPower = true
    end
    
    if (sendEvent) then
       self:SendPowerEvent(powerSource, entity, foundPower)
    end
    
    return foundPower        
end

local gPowerManager = PowerManager()
gPowerManager:Initialize()

function GetPowerManager()
    return gPowerManager
end