//======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Utility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Table.lua")

gNetworkRandomLogData = nil
gRandomDebugEnabled = false
  
function EntityFilterOne(entity)
    return function (test) return test == entity end
end

function EntityFilterTwo(entity1, entity2)
    return function (test) return test == entity1 or test == entity2 end
end

function EntityFilterOnly(entity)
    return function(test) return entity ~= test end
end

// filter out all entities
function EntityFilterAll()
    return function(test) return test ~= nil end
end

function EntityFilterAllButIsa(classname)
    return function(test) return not test:isa(classname) end
end

// Splits string into array, along whitespace boundaries. First element indexed at 1.
function StringToArray(instring)

    local thearray = {}
    local index = 1

    for word in instring:gmatch("%S+") do
        thearray[index] = word
        index = index + 1
    end
    
    return thearray

end

function GetAspectRatio()
    
    return Client.GetScreenWidth() / Client.GetScreenHeight()

end

// Enums are tables with keys with the string, values of the enum number
function EnumToString(enumTable, enumNumber)

    function f(key, value)
        if value == enumNumber then
            return key
        end      
        return nil
    end
    
    if enumTable == nil then
        return "nil enumTable"
    elseif enumNumber == nil then
        return "nil"
    end

    return table.foreach(enumTable, f)
    
end

function StringToEnum(enumTable, enumString)

    function f(key, value)
        if EnumToString(enumTable, value) == enumString then
            return value
        end      
    end
    
    if enumTable == nil or enumString == nil then
        return nil
    end

    return table.foreach(enumTable, f)
    
end


// Returns a string that represents the diff of the two strings passed in. They should be similar
// or this won't produce anything useful.
function StringDiff(s1, s2)

    if s1 ~= nil and s2 == nil then
        return s1
    elseif s1 == nil and s2 ~= nil then
        return s2
    elseif s1 == nil and s2 == nil then
        return ""
    end
    
    if string.len(s2) > string.len(s1) then
        local temp = s1
        s1 = s2
        s2 = temp
    end

    local output = ""
    
    local j = 1
    for i = 1, string.len(s1) do
        local s1char = s1:sub(i, i)
        local s2char = s2:sub(j, j)
        
        if s1char ~= s2char then
            output = output .. s1char
        else
            j = j + 1
        end
        
    end    
    
    return output
    
end

// Examples:
//    Pluralize(1, "clip") => "1 clip"
//    Pluralize(2, "horse") => "2 horses"
//    Pluralize(0, "player") => "0 players"
//    Pluralize(3, "glass") => "3 glasses"
function Pluralize(number, baseText)
    if number == 1 then
        return string.format("%d %s", number, baseText)
    else
        // If ends with an s
        if(StringEndsWith(baseText, "s")) then
            return string.format("%d %ses", number, baseText)
        else
            return string.format("%d %ss", number, baseText)
        end
    end
end

// Returns nil if it doesn't hit
function GetLinePlaneIntersection(planePoint, planeNormal, lineOrigin, lineDirection)

    local p = Math.DotProduct(lineDirection, planeNormal)
    
    if p < 0  then

        local d = -Math.DotProduct(planePoint, planeNormal)
        local t = -(Math.DotProduct(planeNormal, lineOrigin) + d) / p

        if t >= 0 then
        
            return lineOrigin + lineDirection * t
            
        end
        
    end
    
    return nil
    
end

// Returns the sign of a number (1, 0, -1)
function Sign(num)

    local sign = 1

    if (num < 0) then
        sign = -1
    elseif(num == 0) then
        sign = 0
    end

    return sign

end

function Hump(x)
    return 0.5 - math.cos(x * math.pi) * 0.5
end

function DebugBox(minPoint, maxPoint, extents, lifetime, r, g, b, a)
    
    local minX = math.min(minPoint.x - extents.x, maxPoint.x - extents.x)
    local maxX = math.max(maxPoint.x + extents.x, maxPoint.x + extents.x)

    local minY = math.min(minPoint.y - extents.y, maxPoint.y - extents.y)
    local maxY = math.max(maxPoint.y + extents.y, maxPoint.y + extents.y)

    local minZ = math.min(minPoint.z - extents.z, maxPoint.z - extents.z)
    local maxZ = math.max(maxPoint.z + extents.z, maxPoint.z + extents.z)
    
    // Bottom of cube
    DebugLine(Vector(minX, minY, minZ), Vector(minX, minY, maxZ), lifetime, r, g, b, a)
    DebugLine(Vector(minX, minY, minZ), Vector(maxX, minY, minZ), lifetime, r, g, b, a)
    DebugLine(Vector(maxX, minY, minZ), Vector(maxX, minY, maxZ), lifetime, r, g, b, a)
    DebugLine(Vector(minX, minY, maxZ), Vector(maxX, minY, maxZ), lifetime, r, g, b, a)
    
    // Top of cube
    DebugLine(Vector(minX, maxY, minZ), Vector(minX, maxY, maxZ), lifetime, r, g, b, a)
    DebugLine(Vector(minX, maxY, minZ), Vector(maxX, maxY, minZ), lifetime, r, g, b, a)
    DebugLine(Vector(maxX, maxY, minZ), Vector(maxX, maxY, maxZ), lifetime, r, g, b, a)
    DebugLine(Vector(minX, maxY, maxZ), Vector(maxX, maxY, maxZ), lifetime, r, g, b, a)
    
    // Sides
    DebugLine(Vector(minX, maxY, minZ), Vector(minX, minY, minZ), lifetime, r, g, b, a)
    DebugLine(Vector(maxX, maxY, minZ), Vector(maxX, minY, minZ), lifetime, r, g, b, a)
    DebugLine(Vector(maxX, maxY, maxZ), Vector(maxX, minY, maxZ), lifetime, r, g, b, a)
    DebugLine(Vector(minX, maxY, maxZ), Vector(minX, minY, maxZ), lifetime, r, g, b, a)

    
end

/**
 * Show how a Shared.TraceBox works. 
 */
function DebugTraceBox(extents, startPoint, endPoint, lifetime, r, g, b, a)  
    local lineArgs= { lifetime, r, g, b, a }
  
    DebugLine(startPoint, endPoint, unpack(lineArgs))

    local points = {}
    // create points for the boxes around the start and endpoint
    for i=0,7 do
        local v = Vector(
                    extents.x * (bit.band(i,1) == 1 and 1 or -1),
                    extents.y * (bit.band(i,2) == 2 and 1 or -1),
                    extents.z * (bit.band(i,4) == 4 and 1 or -1))
        table.insert(points, startPoint + v )
        table.insert(points, endPoint + v)
    end
    // even points are the startpoint box
    // first four points have the same z-coords
    // first point is all negative
    _DebugTraceNeighbours(lineArgs, points, 1, 3, 5, 9, 2)
    _DebugTraceNeighbours(lineArgs, points, 7, 3, 5, 15, 8)
    _DebugTraceNeighbours(lineArgs, points, 11, 3, 9, 15, 12)
    _DebugTraceNeighbours(lineArgs, points, 13, 5, 9, 15, 14)
    
    _DebugTraceNeighbours(lineArgs, points, 4, 2, 8, 12, 3)
    _DebugTraceNeighbours(lineArgs, points, 6, 2, 8, 14, 5)
    _DebugTraceNeighbours(lineArgs, points, 10, 2, 12, 14, 9)
    _DebugTraceNeighbours(lineArgs, points, 16, 8, 12, 14, 15 )
    
end

function _DebugTraceNeighbours(lineArgs, points, pi, ...)
    local p1 = points[pi]
    for _,pointIndex in ipairs(arg) do
        local p2 = points[pointIndex] 
        DebugLine(p1, p2, unpack(lineArgs))
    end
end

function DebugLineSuccess(startPoint, endPoint, lifetime, success)
    DebugLine(startPoint, endPoint, lifetime, ConditionalValue(success, 0, 1), ConditionalValue(success, 1, 0), 0, 1)
end

// rgba are normalized values (0-1)
function DebugLine(startPoint, endPoint, lifetime, r, g, b, a)
    if (Client and not Shared.GetIsRunningPrediction()) then
        Client.DebugColor(r, g, b, a)
        Client.DebugLine(startPoint, endPoint, lifetime)
    elseif Server then
        Server.SendNetworkMessage("DebugLine", BuildDebugLineMessage(startPoint, endPoint, lifetime, r, g, b, a), true)
    end
end

function DebugPoint(point, size, lifetime, r, g, b, a)
    if (Client and not Shared.GetIsRunningPrediction()) then
        Client.DebugColor(r, g, b, a)
        Client.DebugPoint(point, size, lifetime)
    end
end

function DebugCapsule(sweepStart, sweepEnd, capsuleRadius, capsuleHeight, lifetime)
    if (Client and not Shared.GetIsRunningPrediction()) then    
        Client.DebugCapsule(sweepStart, sweepEnd, capsuleRadius, capsuleHeight, lifetime)        
    end
end

// Takes an array of four values - RGB (0-255 each) and makes them into a 4-byte int for use with Flash.
// Red in the most significant byte, blue in the last.
function ColorArrayToInt(color)
    return bit.lshift(color[1], 16) + bit.lshift(color[2], 8) + color[3]
end

// Takes a color as an integer (0xFF00EE for example) and converts it to a Color object with
// full opacity.
function ColorIntToColor(color)

    local red = bit.rshift(bit.band(color, 0xFF0000), 16)
    local blue = bit.rshift(bit.band(color, 0x00FF00), 8)
    local green = bit.band(color, 0x0000FF)
    
    return Color(red / 0xFF, blue / 0xFF, green / 0xFF, 1)
        
end

// Returns table of bit masks 
// Ex: local t = CreateBitMaskTable({"test1", "test2", "test3"})
// t.test1 => 1
// t.test2 => 2
// t.test3 => 4
function CreateBitMask(tableBitStrings)

    local outputBitMask = {}
    
    for index, bitStringName in ipairs(tableBitStrings) do
        outputBitMask[bitStringName] = bit.lshift(1, index - 1)
    end
    
    return outputBitMask
    
end

gPrintEnabled = false
gPrintPostfix = ""

function SetPrintEnabled(state, postFix)

    gPrintEnabled = state
    
    if postFix ~= nil then
        gPrintPostfix = postFix
    end
    
end

// Can print one argument (string or not), or a string and variable list of parameters passed to string.format()
// Print formatted message to console:
// Print("%s %.2f", "Animation fraction:", .5)
// Print(intValue)
// Only prints in dev mode, or if SetPrintEnabled(true) and not predicting
function Print(formatString, ...)

    local result = string.format(formatString, ...)

    if(Shared and not Shared.GetIsRunningPrediction()) then
        if(Client) then
            Shared.Message(result .. " - Client " .. gPrintPostfix)
            printed = true
        else
            Shared.Message(result .. " - Server " .. gPrintPostfix)
        end
    end
    
    return result
    
end

// Print message with stamp showing if it is on client or server, along with timestamp. Good for time-sensitive
// or client/server logging.
// Print(4.5)
// Print("%s", "testing")
function PrintDetailed(formatString, ...)

    local result = string.format(formatString, ...)
    
    local timestampedMessage = result .. " (at " .. Shared.GetTime() .. ")"

    if(Server) then
        Server.Broadcast(player, timestampedMessage .. " (Server)")
    elseif(Client and not Shared.GetIsRunningPrediction()) then
        Client.DebugMessage(timestampedMessage .. " (Client)")
    end    
    
    return result
    
end

// Save to server log for 3rd party utilities
function PrintToLog(formatString, ...)
    Print(formatString, ...)
end


//
// Wraps all arguments in ToString() before passing them to Print(). Very convinient.
//
function Log(formatString, ...)
    local args = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        table.insert(args, ToString(v))
    end
    if #args > 0 then 
        PrintToLog(formatString, unpack(args))
    else
        PrintToLog(formatString)
    end
end

// 
// Enable a logger that can be turned on /off
// Usage:
// self.logTable = {}
// self.logStats = Logger("stats", self.logTable, false)
// self.logStats = Logger("base", self.logTable, true)
// self.enabledLogs.stats = true
// self.logStats("logs %s", msg)
// 
function Logger(name, logTable, enabled)
    local result = function(format, ...) if logTable[name] then Log(format, ...) end end
    logTable[name] = enabled and true or false
    return result
end

//
// Allow turning on/off loggers belonging to the given logTable.
// It returns a description of changed logs and the available logs.
//
function LogCtrl(prefix, on, logTable)
    local msg = nil
    if prefix and string.len(prefix) > 0 then
        for name,v in pairs(logTable) do
            if prefix == "all" or prefix == "*" or string.find(name, prefix) == 1 then
                logTable[name] = on
                msg = (msg and msg .. ", " .. name) or "Set " .. name
            end
        end
    end
    msg = msg or "No logs changed"   
    for name,v in pairs(logTable) do
        msg = msg .. "\n" .. name .. " = " .. (v and "on" or "off")
    end
    return msg 
end



function ConditionalValue(expression, value1, value2) 

    if(expression) then
        return value1
    else
        return value2
    end
    
end

function SafeId(entity, default)
    if entity ~= nil then
        return entity:GetId()
    end
    return default
end

function SafeClassName(entity)
    if entity ~= nil then
        return entity:GetClassName()
    end
    return "nil"
end

function GetDisplayName(entity)

    local name = "nil"
    
    if entity ~= nil then
    
        if entity:isa("Player") then
            name = entity:GetName()
        else
 
            name = GetDisplayNameForTechId(entity:GetTechId())
            if not name then
                name = entity:GetClassName()
            end
            
        end
        
    end
    
    return name
    
end

function GetDisplayNameForAlert(techId, defaultText)
  local displayName = LookupTechData(techId, kTechDataAlertText, defaultText)
  
  local localizedName = nil
  if displayName ~= nil then
    localizedName = Locale.ResolveString(displayName)
  end
    
  if type(localizedName) == "string" then
        displayName = localizedName
  else
    if (displayName ~= nil) then
        displayName = "#" .. displayName
    else
        displayName = "#" .. ToString(EnumToString(kTechId, techId))
    end
  end
            
    return displayName
end

// Get localized name for tech data display name's
function GetDisplayNameForTechId(techId, defaultText)

    local displayName = LookupTechData(techId, kTechDataDisplayName, defaultText)
    
    // Now localize
    local localizedName = nil
    if displayName ~= nil then
        localizedName = Locale.ResolveString(displayName)
    end
    
    if type(localizedName) == "string" then
        displayName = localizedName
    else
        if (displayName ~= nil) then
         displayName = "#" .. displayName
        else
          displayName = "#" .. ToString(EnumToString(kTechId, techId))
        end
    end
            
    return displayName
    
end

function GetTooltipInfoText(techId)

    local text = LookupTechData(techId, kTechDataTooltipInfo, "")
    
    local localizedText = Locale.ResolveString(text)
    if type(localizedText) == "string" and localizedText ~= "NO STRING" then
        text = localizedText
    end
    
    // Display special message if not yet implemented
    local implemented = LookupTechData(techId, kTechDataImplemented, true) or Shared.GetDevMode()
    
    if implemented == false then
        if tech ~= "" then
            text = text .. Locale.ResolveString("COMING_SOON_1")
        else
            text = text .. Locale.ResolveString("COMING_SOON_2")
        end
    else

        local newString = LookupTechData(techId, kTechDataNew)
        if newString then
        
            // Localize "new" string if possible
            local localizedNewString = Locale.ResolveString(newString)
            if type(localizedNewString) == "string" then
                newString = localizedNewString
            end
            text = text .. " (" .. newString .. ")"
            
        end
        
    end

    return text
    
end

function CreatePickRay(player, xRes, yRes)

    local pickVec = Client.CreatePickingRayXY(xRes, yRes)
       
    // Do traceline against world to see where it ends (for debugging)
    //local trace = Shared.TraceRay(player:GetOrigin(), player:GetOrigin() + pickVec * 1000, PhysicsMask.AllButPCs, EntityFilterOne(player))
    //DebugLine(player:GetOrigin(), trace.endPoint, 3, 1, 1, 1, 1)   
    
    return pickVec
    
end

// Assumes input angles are in radians and will move angle towards target the shortest direction (CW or CCW). Speed must be positive.
// Ex. current 1, desired 4, speed 2 => angleDiff 3, sign = +1, moveAmount = 2, return 1 + 2 = 3
//     current -1, desired -3, speed 1 => angleDiff -2, sign = -1, moveAmount = -1, return -1 - 1 = -2
function InterpolateAngle(currentAngle, desiredAngle, speed)

    local angleDiff = desiredAngle - currentAngle
    
    local angleDiffSign = GetSign(angleDiff)
    
    // Don't move past angle
    local moveAmount = math.min(math.abs(angleDiff), math.abs(speed))*angleDiffSign
    
    return currentAngle + moveAmount

end

// Moves value towards target by rate, regardless of sign of rate
function Slerp(current, target, rate)

    if(rate < 0) then
        rate = -rate
    end
    
    if(math.abs(target - current) < rate) then
        return target
    end
    
    return current + GetSign(target - current)*rate
    
end

function SlerpRadians(current, target, rate)

    // Interpoloate the short way around
    if(target - current > math.pi) then
        target = target - 2*math.pi
    elseif(current - target > math.pi) then
        target = target + 2*math.pi
    end
   
    return Slerp(current, target, rate)

end

function SlerpDegrees(current, target, rate)

    // Interpolate the short way around
    if(target - current > 180) then
        target = target - 360
    elseif(current - target > 180) then
        target = target + 360
    end
   
    return Slerp(current, target, rate)
    
end

// Lerps between any two color, vector or numerical values. Can also lerp between
// two tables with any of these values (but must have the same number of elements
// and same order of types).
function LerpGeneric(startValue, targetValue, percentage)

    local lerpedValue = 0
    
    ASSERT(percentage >= 0)
    ASSERT(percentage <= 1)
    
    // If table, call recursively on values in it
    if type(startValue) == "table" then
    
        if table.count(startValue) ~= table.count(targetValue) then
            Print("LerpGeneric(): startValue and targetValue tables not the same size (%s, %s)", ToString(startValue), ToString(targetValue))
        else
        
            lerpedValue = {}
            for index, value in ipairs(startValue) do
                table.insert(lerpedValue, LerpGeneric(startValue[index], targetValue[index], percentage))
            end
            
        end
 
    elseif type(startValue) == "number" then
        lerpedValue = startValue + ((targetValue - startValue) * percentage)
        
    // Colors
    elseif startValue:isa("Color") then
    
        lerpedValue = Color(startValue.r + (targetValue.r - startValue.r) * percentage, 
                            startValue.g + (targetValue.g - startValue.g) * percentage,
                            startValue.b + (targetValue.b - startValue.b) * percentage,
                            startValue.a + (targetValue.a - startValue.a) * percentage)
                            
    elseif startValue:isa("Vector") then
    
        lerpedValue = Vector(startValue.x + (targetValue.x - startValue.x) * percentage, 
                            startValue.y + (targetValue.y - startValue.y) * percentage,
                            startValue.z + (targetValue.z - startValue.z) * percentage)   
    else
        Print("LerpGeneric(): Can't handle type \"%s\".", type(startValue))
    end
    
    return lerpedValue
    
end

function GetClientServerString()
    return ConditionalValue(Client, "Client", "Server")
end

function ToString(t)

    if t == nil then
        return "nil"
    elseif type(t) == "string" then
        return t
    elseif type(t) == "table" then
        return table.tostring(t)
    elseif type(t) == "function" then
        return tostring(t)
    elseif type(t) == "userdata" then
        if not t.isa then
            return "non-isa userdata"
        elseif t:isa("Vector") then
            return tostring(t)
        elseif t:isa("Trace") then
            return string.format("trace fraction: %.2f entity: %s", t.fraction, SafeClassName(t.entity))
        elseif t:isa("Color") then            
            return string.format("color rgba: %.2f, %.2f, %.2f, %.2f", t.r, t.g, t.b, t.a)
        elseif t:isa("Angles") then
            return string.format("angles yaw/pitch/roll: %.2f, %.2f, %.2f", t.yaw, t.pitch, t.roll)
        elseif t:isa("Coords") then
            return CoordsToString(t)
        elseif t:isa("Entity") then
            return t:GetClassName() .. "-" .. t:GetId()
        elseif t.GetClassName then
            return t:GetClassName()
        else
            return "unknown userdata"
        end
    elseif type(t) == "boolean" then
        return tostring(t)
    elseif type(t) == "number" then
    
        // Insert commas in proper places
        local s = tostring(t)
        local suffix = ""
        
        local index = string.len(s) - 3  
        
        // Take into account decimal place, if any
        local decimalIndex = string.find(s, "(%.)")
        if decimalIndex ~= nil then
            index = decimalIndex - 4
            suffix = string.sub(s, decimalIndex)            
            s = string.sub(s, 1, decimalIndex - 1)            
        end
        
        while index >= 1 do
        
            local prefix = string.sub(s, 1, index)
            local postfix = string.sub(s, index + 1)
            s = string.format("%s,%s", prefix, postfix)
            index = index - 3
            
        end
        
        return s .. suffix
        
    end
    
    Print("ToString() on type \"%s\" failed.", type(t))
    
end

function Copy(t)

    if t == nil then
        return nil
    elseif type(t) == "string" then
        return t
    elseif type(t) == "table" then
        local newTable = {}
        table.copy(t, newTable)
        return newTable
    elseif type(t) == "Coords" then
        return Coords(t)
    elseif type(t) == "userdata" then
        if t:isa("Vector") then
            return Vector(t)
        elseif (Trace ~= nil) and t:isa("Trace") then
            return Trace(t)
        else
            //Print("Copy(%s): Not implemented.", t:GetClassName())
            return t
        end
    elseif type(t) == "number" or type(t) == "boolean" then
        return t
    elseif type(t) == "function" then
        return t
    end
    
    Print("Copy() on type \"%s\" failed.", type(t))
    
end

function CoordsToString(coords, coordsName)
    local name = ConditionalValue(coordsName ~= nil, tostring(coordsName), "Coord: ")
    return string.format("%s origin: (%0.2f, %0.2f, %0.2f) xAxis: (%0.2f, %0.2f, %0.2f) yAxis: (%0.2f, %0.2f, %0.2f) zAxis: (%0.2f, %0.2f, %0.2f)",
                            name, coords.origin.x, coords.origin.y, coords.origin.z, 
                            coords.xAxis.x, coords.xAxis.y, coords.xAxis.z, 
                            coords.yAxis.x, coords.yAxis.y, coords.yAxis.z, 
                            coords.zAxis.x, coords.zAxis.y, coords.zAxis.z)
end

function GetAnglesDifference(startAngle, endAngle)

    local tolerance = 0.1
    local diff = endAngle - startAngle
    
    if(math.abs(diff) > 100) then
        Print("Warning - GetAnglesDiff(%.2f, %.2f) called with large numbers, should be optimized.", startAngle, endAngle)
    end
    
    while(math.abs(diff) > (2*math.pi - tolerance)) do
        diff = diff - GetSign(diff)*2*math.pi
    end
    
    // Return shortest path around circle
    if(math.abs(diff) > math.pi) then
        diff = diff - GetSign(diff)*2*math.pi
    end
    
    return diff
    
end

// Takes a normalized vector
function SetAnglesFromVector(entity, vec)

    local angles = Angles(entity:GetAngles())
    angles.yaw = GetYawFromVector(vec)
    entity:SetAngles(angles)
    
end

function SetViewAnglesFromVector(entity, vec)

    local angles = Angles(entity:GetViewAngles())
    angles.yaw = GetYawFromVector(vec)
    angles.pitch = GetPitchFromVector(vec)
    entity:SetViewAngles(angles)
    
end

function SetRandomOrientation(entity)

    local angles = Angles(entity:GetAngles())
    angles.yaw = NetworkRandom() * math.pi * 2
    entity:SetAngles(angles)
    
end

function GetYawFromVector(vec)

    local dx = vec.x
    local dz = vec.z
    
    if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then
        // If the vector is vertical, then the rotation around the vertical
        // axis is arbitrary.
        return 0.0
    else
        return math.atan2(dx, dz)
    end    

end

function GetPitchFromVector(vec)
    return -math.asin(vec.y)    
end

function DrawCoords(coords)
    DebugLine(coords.origin, coords.origin + coords.xAxis, .2, 1, 0, 0, 1)
    DebugLine(coords.origin, coords.origin + coords.yAxis, .2, 0, 1, 0, 1)
    DebugLine(coords.origin, coords.origin + coords.zAxis, .2, 0, 0, 1, 1)
end

function BuildCoordsFromDirection(zAxis, origin, scale)

    // Compute normal 
    local upVector = Vector(0, 1, 0)
   
    // If zAxis is facing mostly up or down
    if math.abs(zAxis.y) > .9 then
    
        // Choose arbitrary vector that should work well enough
        upVector = Vector(1, 0, 0)
        
    end

    local rightVector = zAxis:CrossProduct(upVector)
    local normal = rightVector:CrossProduct(zAxis)
    if not scale then
        scale = 1
    end
    
    return BuildCoords(normal, zAxis, origin, scale)
    
end

function BuildCoords(yAxis, zAxis, origin, scale)

    local coords = Coords()

    coords.yAxis = yAxis:GetUnit()
    coords.zAxis = zAxis:GetUnit()
    
    // The two axes that were specified are parallel
    if math.abs( Math.DotProduct(coords.yAxis, coords.zAxis) ) > 0.9 then
        coords.zAxis = coords.yAxis:GetPerpendicular()
    end
    
    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis):GetUnit()
    coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis):GetUnit()
    
    // Set scale
    if scale ~= nil then
        if type(scale) == "userdata" and scale:isa("Vector") then
            coords.xAxis:Scale(scale.x)
            coords.yAxis:Scale(scale.y)
            coords.zAxis:Scale(scale.z)            
        else
            coords.xAxis:Scale(scale)
            coords.yAxis:Scale(scale)
            coords.zAxis:Scale(scale)
        end
    end
    
    if origin then
        coords.origin = origin
    end

    return coords
    
end

function CopyCoords(coords)
    return Coords(coords)
end

// Returns degrees between -360 and 360
function DegreesTo360(degrees, positiveOnly)

    while(degrees < -360 or (positiveOnly and degrees < 0)) do
        degrees = degrees + 360
    end
    
    while(degrees > 360) do
        degrees = degrees - 360
    end
    
    return degrees

end

function DebugTraceRay(p0, p1, mask, filter)

    if not filter then
        filter = EntityFilterOne(nil)
    end
    
    local trace = Shared.TraceRay(p0, p1, mask, filter)
    
    if Client then
        if trace.fraction ~= 1 and trace.entity then
            DebugLine(p0, p1, 10, 1, 0, 0, 1)
        else
            DebugLine(p0, p1, 10, 0, 1, 0, 1)
        end
    end
    
    return trace
    
end

function DrawEntityAxes(entity)

    // Draw x red, y green, z blue (like 3ds Max)
    local lineLength = 2
    local coords = entity:GetAngles():GetCoords()
    local p0 = entity:GetOrigin()
    
    DebugLine(p0, p0 + coords.xAxis*lineLength, .1, 1, 0, 0, 1)
    DebugLine(p0, p0 + coords.yAxis*lineLength, .1, 0, 1, 0, 1)
    DebugLine(p0, p0 + coords.zAxis*lineLength, .1, 0, 0, 1, 1)
    
end

function GetIsDebugging()
    return (decoda_output ~= nil)
end

function GetSign(number)

    if(number > 0) then
        return 1
    elseif(number < 0) then
        return -1
    end
    
    return 0
    
end

// Pass no parameters for 0-1 random value, otherwise pass integers for random number between those numbers (inclusive).
// NOTE: It's important to make sure that this is called the same number of times and for the same reasons both on client
// and server during OnProcessMove(). Use SetNetworkRandomLog() below to make sure they are being called the right
// number of times for the right reasons below.
function NetworkRandom(logMessage)

    local result = Shared.GetRandomFloat()

    if gNetworkRandomLogData and gRandomDebugEnabled then
    
        local baseLogMessage = string.format("NetworkRandom() => %s", tostring(result))
        
        LogRandom(baseLogMessage, logMessage)
        
    end
    
    return result
    
end

function NetworkRandomInt(minValue, maxValue, logMessage)

    local result = Shared.GetRandomInt( math.min(minValue, maxValue), math.max(minValue, maxValue) )
    
    if gNetworkRandomLogData and gRandomDebugEnabled then
    
        local baseLogMessage = string.format("NetworkRandomInt(%s, %s) => %s", ToString(minValue), ToString(maxValue), ToString(result))
        
        LogRandom(baseLogMessage, logMessage)
        
    end
    
    return result

end

function LogRandom(baseLogMessage, logMessage)

    if gNetworkRandomLogData and gRandomDebugEnabled then
    
        local s = baseLogMessage
        
        if logMessage then
            s = string.format("%s (%s)", s, ToString(logMessage))
        end
        
        table.insert(gNetworkRandomLogData, s)      
        
    end

end

function SetNetworkRandomLog(player)

    if gRandomDebugEnabled then

        if not player then
        
            // Print data
            local numLogEntries = table.count(gNetworkRandomLogData)
            if numLogEntries > 0 then
            
                Print("SetNetworkRandomLog() %s:", Pluralize(numLogEntries, "result"))
                
                for index, s in ipairs(gNetworkRandomLogData) do
                    Print(s)
                end
                
            end
            
            gNetworkRandomLogData = nil    
            
        else
            gNetworkRandomLogData = {}
        end
        
    end
    
end

function EncodePointInString(point)
    return string.format("%0.2f_%0.2f_%0.2f_", point.x, point.y, point.z)
end

function DecodePointFromString(string)

    local numParsed = 0
    local point = Vector()
    
    for stringCoord in string.gmatch(string, "[0-9.\-]+") do 
    
        local coord = tonumber(stringCoord)
        numParsed = numParsed + 1
        
        if(numParsed == 1) then
            point.x = coord
        elseif(numParsed == 2) then
            point.y = coord
        else
            point.z = coord
        end
        
        if(numParsed == 3) then
            return true, point
        end
        
    end
    
    return false, nil
    
end

// Grabbed these from the lua wiki 
// http://lua-users.org/wiki/StringRecipes
function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

function url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str    
end

function EncodeStringForNetwork(inputString)       
    return url_encode(inputString)    
end

function DecodeStringFromNetwork(inputString)
    if(inputString == nil) then
        return nil
    end
    
    return url_decode(inputString)
end

function GetColorForPlayer(player)

    if(player ~= nil) then
        if player:GetTeamNumber() == kTeam1Index then
            return kMarineTeamColor
        elseif player:GetTeamNumber() == kTeam2Index then
            return kAlienTeamColor
        end
    end
    
    return kNeutralTeamColor   
    
end

// This assumes marines vs. aliens
function GetColorForTeamNumber(teamNumber)

    if teamNumber == kTeam1Index then
        return kMarineTeamColor
    elseif teamNumber == kTeam2Index then
        return kAlienTeamColor
    end
    
    return kNeutralTeamColor   
    
end

// Generate unique name that isn't taken by another player on the server. If it is,
// return number variant "NsPlayer (2)". Optionally pass a list of names for testing.
// If not passing a list of names, this is on the server only.
function GetUniqueNameForPlayer(name, nameList)

    // Make sure name isn't in use
    if(nameList == nil) then
    
        nameList = {}
        
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            local name = player:GetName()
            if(name ~= nil and name ~= "") then
                table.insert(nameList, string.lower(name))
            end
        end

    end
    
    // Case-insensitive check for specified name in nameList
    function nameInTable(name)
    
        for index, entryName in ipairs(nameList) do
        
            if(string.lower(entryName) == string.lower(name)) then
                return true
            end
            
        end
        
        return false
        
    end
    
    local returnName = name
    
    if(nameInTable(name)) then
    
        for i = 1, kMaxPlayers do
        
            // NsPlayer (2)
            local newName = string.format("%s (%d)", name, i+1)
            
            if(not nameInTable(newName)) then
            
                returnName = newName
                break
                
            end
            
        end

    end
    
    return returnName
    
end

// http://lua-users.org/wiki/InfAndNanComparisons
function IsValidValue(value)

    if(type(value) == "number") then
    
        if(value ~= value) then
            return false, "NaN"
        elseif(value >= math.huge) then
            return false, "infinity"
        elseif(value <= -math.huge) then
            return false, "-infinity"
        end
        
    end
    
    return true

end

function Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

function Wrap(x, min, max)

    range = max - min
    
    if range == 0 then
        return min
    end
    
    local returnVal = x
    
    if returnVal < min then
        returnVal = returnVal + math.floor((max - returnVal) / range) * range
    end
    
    if returnVal >= max then
        returnVal = returnVal - math.floor((returnVal - min) / range) * range
    end
    
    return returnVal
    
end

// Replace this with functionality from keybindings
function GetDescForMove(move)

    if move == Move.Crouch then
        return "CTRL"
    elseif move == Move.MovementModifier then
        return "SHIFT"
    elseif move == Move.PrimaryAttack then
        return "LMB"
    elseif move == Move.SecondaryAttack then
        return "RMB"
    elseif move == Move.Weapon1 then
        return "1"
    elseif move == Move.Weapon2 then
        return "2"
    elseif move == Move.Weapon3 then
        return "3"
    elseif move == Move.Weapon4 then
        return "4"
    elseif move == Move.Weapon5 then
        return "5"
    end
    
    return "??"
    
end

function ValidateValue(value, logMessage)

   if(type(value) == "number") then
    
        local valid, reason = IsValidValue(value)
        if(not valid) then
            if(logMessage) then
                Print("Numeric value not valid (%s) - %s", reason, logMessage)
            end
            return false
        end
 
    else
    
        local valid, reason = IsValidValue(value.x)
        if(not valid) then
            if(logMessage) then
                Print("Vector.x not valid (%s) - %s", reason, logMessage)
            end
            return false
        end
        
        valid, reason = IsValidValue(value.y)
        if(not valid) then
            if(logMessage) then
                Print("Vector.y not valid (%s) - %s", reason, logMessage)
            end
            return false
        end

        valid, reason = IsValidValue(value.z)
        if(not valid) then
            if(logMessage) then
                Print("Vector.z not valid (%s) - %s", reason, logMessage)
            end
            return false
        end
                    
    end
    
    return true
    
end

// Parse number value from editor_setup and emit error if outside expected range
function GetAndCheckValue(valueString, min, max, valueName, defaultValue, silent)

    local numValue = tonumber(valueString)
    
    if(numValue == nil) then
    
        numValue = defaultValue
        
        if(not silent) then
            Shared.Message(string.format("GetAndCheckValue(%s): Value is nil, returning default of %s.", valueName, numValue))
        end
        
    elseif(numValue < min or numValue > max) then
    
        numValue = math.max(math.min(numValue, max), min)
        
        if (not silent) then
            Shared.Message(string.format("%s - Value is outside expected range (%.2f, %.2f), clamping to %.2f: ", valueName, min, max, numValue))
        end
        
    end
    
    return numValue
    
end

function GetAndCheckBoolean(valueString, valueName, defaultValue)

    local returnValue = false
    
    if(valueString == nil) then
        Shared.Message(string.format("GetAndCheckBoolean(%s): Value is nil, returning default of %s.", valueName, tostring(defaultValue)))
        returnValue = defaultValue
    elseif(type(valueString) == "string") then
        returnValue = ConditionalValue(string.find(valueString, "true") ~= nil, true, false)
    elseif(type(valueString) == "boolean") then
        returnValue = valueString
    end  
    
    return returnValue
    
end

function StringStartsWith(inString, startString)

    if(type(inString) ~= "string" or type(startString) ~= "string") then
        Print("StringStartsWith(%s, %s) not called with strings.", tostring(inString), tostring(startString))
        return false
    end
    
    return string.lower(string.sub(inString, 1, string.len(startString))) == string.lower(startString)

end

function StringEndsWith(inString, endString)

    if(type(inString) ~= "string" or type(endString) ~= "string") then
        Print("StringEndsWith(%s, %s) not called with strings.", tostring(inString), tostring(endString))
        return false
    end
    
    return string.lower(string.sub(inString, -string.len(endString))) == string.lower(endString)

end

/**
 * Return a string that removes any leading or trailing whitespace characters from the passed in string.
 */
function StringTrim(inString)

    ASSERT(type(inString) == "string")
    
    return (inString:gsub("^%s*(.-)%s*$", "%1"))
    
end

// Returns base value when dev is off, base value * scalar when it's on
function GetDevScalar(value, scalar)
    return ConditionalValue(Shared.GetDevMode(), value * scalar, value)
end

// Capsule start and end define the "core" of the capsule. The ends of the capsule are 
// rounded and are a half-sphere with radius capsuleRadius.
// Default is human/bipedal movement, so return upright capsule
function GetTraceCapsuleFromExtents(extents)

    local radius = math.max(extents.x, 0)
    
    if radius == 0 then
        Print("%GetTraceCapsuleFromExtents(): radius is 0.")
    end
    
    local height = math.max(extents.y * 2, 0)
    return height, radius
    
end

function PrecacheAsset(effectName)

    if(type(effectName) ~= "string") then
    
        Print("PrecacheAsset(%s): effect name isn't a string (%s instead).", tostring(effectName), type(effectName))
        return nil
        
    end
    
    // If ends with .model
    local kCinematic = ".cinematic"
    local kModel = ".model"
    
    if(StringEndsWith(effectName, ".cinematic")) then
        Shared.PrecacheCinematic(effectName)
    elseif(StringEndsWith(effectName, ".model")) then
        Shared.PrecacheModel(effectName)
    elseif(StringEndsWith(effectName, ".material")) then
        // Materials don't need to be precached
    elseif(StringStartsWith(effectName, "sound")) then
        Shared.PrecacheSound(effectName)
    end
        
    return effectName
    
end

// Precache multiple assets, using table as a substitution
function PrecacheMultipleAssets(effectName, substTable)

    for index, substString in ipairs(substTable) do

        PrecacheAsset(string.format(effectName, substString))   
        
    end
    
end

// Calls entity:SetTeamNumber(teamNumber) (if team number passed), SetOrigin() and OnInit(), if those functions exist.
// Player entities are added to the specified team by default.
function InitEntity(entity, className, origin, teamNumber)

    if entity.SetTeamNumber and teamNumber ~= -1 then
        entity:SetTeamNumber(teamNumber)
    end
    
    if entity.SetOrigin then
        entity:SetOrigin(origin)    
    end
    
    if entity.OnInit then
        entity:OnInit()
    end
    
end

if(Server) then

// Creates entity, initializes it and adds it to the proper team via gamerules.
// Pass the mapName, not className (teamNumber and origin optional - defaults to -1 and the origin)
function CreateEntity(mapName, origin, teamNumber)

    if (teamNumber == nil) then
        teamNumber = -1
    end
    
    if (origin == nil) then
        origin = Vector(0, 0, 0)
    end
    
    ASSERT( type(mapName) == "string" )
    ASSERT( type(teamNumber) == "number" )
    ASSERT( origin:isa("Vector") )    
    
    // Calls OnCreate()
    local entity = Server.CreateEntity(mapName)    
    if entity then
    
        // Set team number, origin then OnInit()
        InitEntity(entity, mapName, origin, teamNumber)
        
        // Add entity to team, add/remove tech from tech tree, etc.
        GetGamerules():OnEntityCreate(entity)
            
    else
        ASSERT(entity)
        Print("CreateEntity(%s, %s, %s) returned nil.", ToString(mapName), ToString(origin), ToString(teamNumber))
    end
    
    return entity
    
end

// Script should only use this function, never call Server.DestroyEntity directly.
function DestroyEntity(entity)

    ASSERT(entity ~= nil)
    
    // Remove from team, tech tree, etc.
    GetGamerules():OnEntityDestroy(entity)

    // Calls OnDestroy()
    Server.DestroyEntity(entity)        
    
end

end

/**
 * This function can be used to verify that a computation is done identically on
 * the client and server. It should only be used when running a listen server.
 */
function CheckPredictionData(key, includeTime, values)

    // Add the time to the key.
    
    if (includeTime) then
        key = key .. string.format(" time=%0.3f", Shared.GetTime())
    end
    
    local data = ""
    
    for k,v in pairs(values) do
        
        if (type(v) == "number") then
            // Due to floating point inaccuracy, we only compare up to 3 digits.
            data = data .. string.format( "%s=%.3f ", k, v ) 
        else
            data = data .. string.format( "%s=%s ", k, tostring(v) ) 
        end
        
    end
    
    if (Server) then
        if (not Server.VerifyPredictionData(key, data)) then
            Shared.Message("Prediction data failed")
        end
    else
        Client.StorePredictionData(key, data)
    end

end

/**
 * Scale the passed in value down based on two other values.
 */
function math.scaledown(value, av, mv)
    if mv ~= 0 and av >= mv then
        return value
    end
    if mv == 0 then
        mv = av
    end
    return math.percentf((av/mv)*100,value)
end

/**
 * Rounds to nearest number by the passed in decimal places.
 */
function math.round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

/**
 * Returns the value from the percentage p of v where p is between 0 and 100.
 */
function math.percentf(p, v)
    return (p/100)*v
end

/**
 * ColorValue(0-255) : Convert standard convention to decimal.
 */
function ColorValue(val)
    ASSERT(type(val) == "number")
    return (val/255)
end

/**
 * AlphaValue(0-100) : Percentage Transparency ~ Convert standard convention to decimal.
 */
function AlphaValue(val)
    ASSERT(type(val) == "number")
    return (val/100)
end

/**
 * Call MonitorCallHistoryBegin() to begin monitoring the calls and MonitorCallHistoryEnd()
 * to return a list of functions called in order after MonitorCallHistoryBegin() was called.
 * Calling MonitorCallHistoryEnd() stops the monitoring process and returns a string.
 */
local callHistoryMonitorString = ""
local callstackDepth = 1
local allowedFunctionTypes = { "local", "global", "method", "field", "upvalue" }
local filterFunctionNames = { "MonitorCallHistoryEnd", "sethook", "(for generator)" }
local function MonitorCallHistoryHook(type)

    if type == "call" then
        callstackDepth = callstackDepth + 1
        local function generateOffset(offsetString, currentDepth) if currentDepth <= callstackDepth then return generateOffset(" " .. offsetString, currentDepth + 1) end return offsetString end
        local offsetString = generateOffset("", 1)
        local functionName = debug.getinfo(2, "n").name or "No name"
        local functionType = debug.getinfo(2, "n").namewhat
        local otherInfo = functionType .. " - " .. debug.getinfo(2, "S").short_src .. ":" .. debug.getinfo(2, "l").currentline
        if table.contains(allowedFunctionTypes, functionType) and not table.contains(filterFunctionNames, functionName) then
            if string.len(callHistoryMonitorString) ~= 0 then
                callHistoryMonitorString = callHistoryMonitorString .. "\n"
            end
            callHistoryMonitorString = callHistoryMonitorString .. offsetString .. functionName .. " - " .. otherInfo
        end
    elseif type == "return" then
        callstackDepth = callstackDepth - 1
    end

end

function MonitorCallHistoryBegin()

    debug.sethook(MonitorCallHistoryHook, "cr")

end

function MonitorCallHistoryEnd()

    debug.sethook()
    local returnHistory = callHistoryMonitorString
    callHistoryMonitorString = ""
    callstackDepth = 1
    return returnHistory

end