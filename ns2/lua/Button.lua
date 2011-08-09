// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Button.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/PropDynamic.lua")

class 'Button' (PropDynamic)

local kUseStateOff = 0
local kUseStateToOff = 1
local kUseStateToOn = 2
local kUseStateOn = 3

function Button:OnLoad()

    Shared.PrecacheModel(self.model)
   
end

function Button:OnInit()

    if (self.model ~= nil) then        
        self:SetModel(self.model)
    end

    if (self.DefaultAnim ~= nil) then
        self:SetAnimation(self.DefaultAnim)
    end
    
    self:SetUseState(self.initialState)
    
end

function Button:OnThink()

    PropDynamic.OnThink(self)
    
    // The animation is finished, so update the state.
    if(self.useState == kUseStateToOff) then
        self:SetUseState(kUseStateOff)
    elseif(self.useState == kUseStateToOn) then
        self:SetUseState(kUseStateOn)
    end
    
end

function Button:GetEntitiesWithName(targetName)

    local entities = {}
    local startEntity = nil
    local currentEntity = nil
    
    if(targetName ~= nil) then
    
        repeat
            
            currentEntity = Shared.FindNextEntity(startEntity)
            if(currentEntity and (currentEntity.targetname == targetName)) then
                table.insert(entities, currentEntity)
            end
            
            startEntity = currentEntity
            
        until currentEntity == nil
        
    end
    
    return entities

end

function Button:SetUseState(useState)

    if(useState ~= self.useState) then
    
        self.useState = useState
        
        local animationName = "off"
        
        if(self.useState == kUseStateToOff) then
            animationName = "to_off"
        elseif(self.useState == kUseStateToOn) then
            animationName = "to_on"
        elseif(self.useState == kUseStateOn) then
            animationName = "on"
        end
        
        // Lookup entity target
        local entities = self:GetEntitiesWithName(self.ButtonTarget)
        for index, entity in pairs(entities) do
        
            // Play animation on it
            entity:SetAnimation(animationName)
            
            // Stop the animation when it's done
            if (self.useState == kUseStateToOff or self.useState == kUseStateToOn) then
                self:SetNextThink( entity:GetAnimationLength(animationName) )
            end
                        
        end
        
    end
    
end

function Button:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    if(self.useState == kUseStateOff) then
        self:SetUseState(kUseStateToOn)
        return true
    elseif(self.useState == kUseStateOn) then
        self:SetUseState(kUseStateToOff)
        return true
    end    
    
    return false

end

function Button:GetCanBeUsed(player)
    return true
end

Shared.LinkClassToMap( "Button", "ns2_button", {} )