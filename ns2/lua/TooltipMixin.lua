// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TooltipMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

TooltipMixin = { }
TooltipMixin.type = "Tooltip"

function TooltipMixin:__initmixin()

    self.displayedTooltips = {}

end

/**
 * Internal function to check if we've already displayed this tooltip. Returns false if we haven't, or if time
 * has expired since we've displayed
 */
function TooltipMixin:_GetCanDisplayTooltip(tooltipText, timeInterval)

    ASSERT(type(tooltipText) == "string")
    
    local currentTime = Shared.GetTime()
    
    // Return false if we've recently added any tooltip
    if self.timeOfLastTooltip ~= nil and currentTime < (self.timeOfLastTooltip + self:GetMixinConstants().kToolTipInterval) then
    
        return false
        
    end
    
    // Return false if we've too recently shown this particular tooltip
    for index, entity in ipairs(self.displayedTooltips) do
    
        if(tooltipText == entity[1]) then
        
            if(timeInterval == nil or (currentTime < entity[2] + timeInterval)) then
            
                return false
                
            end
            
        end
        
    end
    
    return true
    
end
AddFunctionContract(TooltipMixin._GetCanDisplayTooltip, { Arguments = { "Entity", "string", { "number", "nil" } }, Returns = { "boolean" } })

function TooltipMixin:AddLocalizedTooltip(tooltipText, once, isTech)
    if Server then
      Server.SendCommand(self, string.format("%s %s %s %s", "localizedtooltip", tostring(once), tostring(isTech), tooltipText))      
    elseif Client then
      if (once == "true") then
        self:AddTooltipOnce(tooltipText)
      else
        self:AddTooltip(tooltipText)
      end
    end
end
AddFunctionContract(TooltipMixin.AddLocalizedTooltip, { Arguments = { "Entity", "string", "boolean", "boolean" }, Returns = { } })

function TooltipMixin:AddTooltipOnce(tooltipText)

    ASSERT(type(tooltipText) == "string")
    
    if(self:_GetCanDisplayTooltip(tooltipText, nil)) then
    
        self:AddTooltip(tooltipText)
        return true
        
    end

    return false
    
end
AddFunctionContract(TooltipMixin.AddTooltipOnce, { Arguments = { "Entity", "string" }, Returns = { "boolean" } })

function TooltipMixin:AddTooltipOncePer(tooltipText, timeInterval)

    ASSERT(type(tooltipText) == "string")
    
    if(timeInterval == nil) then
        timeInterval = 10
    end
    
    if(self:_GetCanDisplayTooltip(tooltipText, timeInterval)) then
    
        self:AddTooltip(tooltipText)
        
        return true
        
    end

    return false

end
AddFunctionContract(TooltipMixin.AddTooltipOncePer, { Arguments = { "Entity", "string", { "number", "nil" } }, Returns = { "boolean" } })

function TooltipMixin:AddTooltip(message)

    ASSERT(type(message) == "string")        
    
    if Client then
        self:AddTooltipClient(message)
    elseif Server then
        self:AddTooltipServer(message)
    end
    
    table.insertunique(self.displayedTooltips, {message, Shared.GetTime()})
    self.timeOfLastTooltip = Shared.GetTime()
    
end
AddFunctionContract(TooltipMixin.AddTooltip, { Arguments = { "Entity", "string" }, Returns = { } })

/**
 * Display the tooltip and play a sound.
 */
function TooltipMixin:AddTooltipClient(message, localize)
    
    if (localize == nil) then
      // Localize string if possible
      local localizedMessage = Locale.ResolveString(message)
      if type(localizedMessage) == "string" then
        message = localizedMessage
      end
    end
    
    // Strip out surrounding "s
    local message = string.gsub(message, "\"(.*)\"", "%1")
    
    // Hook GUI display 
    HudTooltip_SetMessage(message)
    
    Shared.PlaySound(self, self:GetMixinConstants().kTooltipSound)
    
end
AddFunctionContract(TooltipMixin.AddTooltipClient, { Arguments = { "Entity", "string" }, Returns = { } })

/**
 * Send notification to the Client to add this tooltip.
 */
function TooltipMixin:AddTooltipServer(message)
    
    Server.SendCommand(self, string.format("%s \"%s\"", "tooltip", message))

end
AddFunctionContract(TooltipMixin.AddTooltipServer, { Arguments = { "Entity", "string" }, Returns = { } })

function TooltipMixin:ClearDisplayedTooltips()
    table.clear(self.displayedTooltips)
end
AddFunctionContract(TooltipMixin.ClearDisplayedTooltips, { Arguments = { "Entity" }, Returns = { } })

function TooltipMixin:GetNumberOfDisplayedTooltips()
    return table.count(self.displayedTooltips)
end
AddFunctionContract(TooltipMixin.GetNumberOfDisplayedTooltips, { Arguments = { "Entity" }, Returns = { "number" } })