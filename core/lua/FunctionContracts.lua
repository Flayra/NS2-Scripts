//======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\FunctionContracts.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local __functionPrototypes = { }

local function GetValueTypeMatchesExpectedType(argument, expectedType)

    ASSERT(type(expectedType) == "string" or type(expectedType) == "table")
    
    local value = argument.Value
    
    local valueType = type(value)
    
    // If value is a table with a GetClassName() function, use the result of that function as the type.
    local tableClassName = (valueType == "table" and not value.isa and value.GetClassName and value:GetClassName()) or nil
    valueType = tableClassName or valueType
    
    argument.Type = valueType
    
    if valueType == expectedType then
    
        return true
        
    elseif value and (valueType == "userdata" or valueType == "table") and value.isa then
    
        local matchFound = false
        // Any of the types in the table can be expected.
        if type(expectedType) == "table" then
            for i, currentExpectedType in ipairs(expectedType) do
                ASSERT(type(currentExpectedType) == "string")
                matchFound = value:isa(currentExpectedType)
                if matchFound then break end
            end
            // Handle the case where the expectedType table has the exact valueType.
            // This can happen if the valueType is a table or userdata and expectedType
            // includes table or userdata (in such cases where the value has the isa function
            // but is also a table or userdata and isa doesn't return true for table or userdata.
            matchFound = matchFound or table.contains(expectedType, valueType)
        else
            // Default to the string expectedType.
            matchFound = value:isa(expectedType)
        end
        // Structs do not have the GetClassName() function and cannot be queried for it.
        local venueClassName = (value.GetClassName and value:GetClassName()) or nil
        argument.Type = (matchFound and expectedType) or (valueClassName or argument.Type)
        return matchFound
        
    end
    
    if type(expectedType) == "table" then
        return table.contains(expectedType, valueType)
    else
        return valueType == expectedType
    end
    
end

local function VerifyFunctionPrototypes(hookType)

    local functionInfo = debug.getinfo(2, "fn")
    local functionPrototype = __functionPrototypes[functionInfo.func]
    local errorString = ""
    
    if functionPrototype then
    
        local arguments = { }
        local lastNonTempIndex = 0
        for i = 1, math.huge do
            local n, v = debug.getlocal(2, i)
            if not n then break end
            // Ignore Lua variables (which start with open parentheses).
            if string.sub(n, 0, 1) ~= '(' then
                lastNonTempIndex = i
                table.insert(arguments, { Name = n, Value = v })
            end
            // Check if all the arguments have been found.
            if hookType == "call" and table.count(arguments) >= table.count(functionPrototype.Arguments) then
                break
            end
        end
        
        if hookType == "call" then

            for i, argument in ipairs(arguments) do
                if not GetValueTypeMatchesExpectedType(argument, functionPrototype.Arguments[i]) then
                    if string.len(errorString) ~= 0 then
                        errorString = errorString .. "\n"
                    end
                    local expectedArgumentsString = type(functionPrototype.Arguments[i]) == "string" and functionPrototype.Arguments[i] or nil
                    if not expectedArgumentsString then
                        for i, currentExpectedArgument in ipairs(functionPrototype.Arguments[i]) do
                            ASSERT(type(currentExpectedArgument) == "string")
                            if expectedArgumentsString then
                                expectedArgumentsString = expectedArgumentsString .. " or " .. currentExpectedArgument
                            else
                                expectedArgumentsString = currentExpectedArgument
                            end
                        end
                    end
                    errorString = errorString .. "Error: Argument number " .. i .. " expected to be a " .. expectedArgumentsString .. " for function " .. functionInfo.name ..
                                                 " but was a " .. argument.Type
                end
            end
        
        elseif hookType == "return" then
        
            // Find all the return values.
            local returnValues = { }
            for i = lastNonTempIndex + 1, math.huge do
                local n, v = debug.getlocal(2, i)
                if not n then break end
                table.insert(returnValues, { Type = type(v), Value = v })
            end
            // The last one isn't actually a return value.
            table.remove(returnValues, table.count(returnValues))
            if table.count(returnValues) > table.count(functionPrototype.Returns) then
                errorString = errorString .. "Error: Too many return values from function " .. functionInfo.name
            else
                for i, returnValue in ipairs(returnValues) do
                    if not GetValueTypeMatchesExpectedType(returnValue, functionPrototype.Returns[i]) then
                        if string.len(errorString) ~= 0 then
                            errorString = errorString .. "\n"
                        end
                        errorString = errorString .. "Error: Return value number " .. i .. " expected to be a " .. functionPrototype.Returns[i] .. " for function " .. functionInfo.name ..
                                                     " but was a " .. returnValue.Type
                    end
                end
            end
        
        end
        
        if string.len(errorString) > 0 then
            error(errorString)
        end
        
    end

end

/**
 * Call to enabled or disable function contract checks. When enabled the game will
 * run slower than usual.
 */
function SetFunctionContractsEnabled(setEnabled)

    // DISABLED UNTIL I CAN FIX A PROBLEM.
    /*if setEnabled then
        debug.sethook(VerifyFunctionPrototypes, "cr")
    else
        debug.sethook()
    end*/
    
end

/**
 * The contract data is in the following format:
 * Arguments = { "number", "Vector" }, { Returns = { "string" } }
 * Where the values are the types of expected variables in the order expected.
 */
function AddFunctionContract(contractFunction, contractData)

    assert(type(contractFunction) == "function", "First parameter must be a function.")
    assert(type(contractData) == "table", "Second parameter must be a table of contract data.")
    assert(type(contractData.Arguments) == "table", "Arguments table missing in contract data.")
    assert(type(contractData.Returns) == "table", "Returns table missing in contract data.")
    assert(__functionPrototypes[contractFunction] == nil, "Cannot add a function contract more than once")
    
    __functionPrototypes[contractFunction] = contractData
    
end