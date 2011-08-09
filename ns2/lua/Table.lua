// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Table.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Table related utility functions. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Safe equality checking for tables and nested tables.
//  Eg, elementEqualsElement( { {1}, {2} }, { {1}, {2} } returns true
function elementEqualsElement(i, j) 

    if(type(i) == "table" and type(j) == "table") then
    
        local tablesEqual = false
        
        local numIElements = table.maxn(i)
        local numJElements = table.maxn(j)
        
        if(numIElements == numJElements) then
        
            tablesEqual = true
            
            for index = 1, numIElements do
            
                if(not elementEqualsElement(i[index], j[index])) then
                
                    tablesEqual = false
                    break
                    
                end                    
                
            end
        
        end
        
        return tablesEqual
        
    else
    
        return i == j
        
    end
    
end

function table.duplicate(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function table.copy(srcTable, destTable, noClear)

    if not noClear then
        table.clear(destTable)
    end
    
    for index, element in ipairs(srcTable) do
        table.insert(destTable, Copy(element))
    end
    
end

/**
 * Searches a table for the specified value. If the value is in the table
 * the index of the (first) matching element is returned. If its not found
 * the function returns nil.
 */
function table.find(findTable, value)

    assert(type(findTable) == "table")
    
    for i,element in ipairs(findTable) do
        if elementEqualsElement(element, value) then
            return i
        end
    end

    return nil

end

/**
 * Returns true if the passed in table contains the passed in value. This
 * function can be used on any table (dictionary-like tables as well as those
 * created with table.insert()).
 */
function table.contains(inTable, value)

    assert(type(inTable) == "table")
    
    for _, element in pairs(inTable) do
        if element == value then
            return true
        end
    end
    return false
    
end

/**
 * Returns random element in table.
 */
function table.random(t)
    local max = table.maxn(t)
    if max > 0 then
        return t[math.floor(NetworkRandomInt(1, max))]
    else
        return nil    
    end
end

/**
 * Choose random weighted index according. Pass in table of arrays where the first element in each
 * array is a float that indicates how often that index is chosen.
 *
 * {{.9, "chooseOften"}, {.1, "chooseLessOften"}, {.001, "chooseAlmostNever}}
 *
 * This returns 1 most often, 2 less often and 3 even less. It adds up all the numbers that are the 
 * first elements in the table to calculate the chance. Returns -1 on error.
 */
function table.chooseWeightedIndex(t)

    local weightedIndex = -1
    
    // Calculate total weight
    local totalWeight = 0
    for i, element in ipairs(t) do
        totalWeight = totalWeight + element[1]
    end
    
    // Choose random weighted index of input table data
    local randomFloat = NetworkRandom()
    local randomNumber = randomFloat * totalWeight
    local total = 0
    
    for i, element in ipairs(t) do
    
        local currentWeight = element[1]
        
        if((total + currentWeight) >= randomNumber) then
            weightedIndex = i
            break
        else
            total = total + currentWeight
        end
        
    end

    return weightedIndex
    
end

// Helper function for table.chooseWeightedIndex
function chooseWeightedEntry(t)

    if(t ~= nil) then
        local entry = t[table.chooseWeightedIndex(t)][2]
        return entry
    end
    
    Print("chooseWeightedEntry(nil) - Table is nil.")
    return nil
    
end

// Checks if tables have all the same elements
function table.getIsEquivalent(origT1, origT2)

    if (origT1 == nil and origT2 == nil) then
    
        return true
        
    elseif (origT1 == nil) or (origT2 == nil) then
    
        return false
        
    elseif (table.count(origT1) == table.count(origT2)) then
    
        local t1 = {}
        local t2 = {}
        
        table.copy(origT1, t1)
        table.copy(origT2, t2)
    
        for index, elem in ipairs(t1) do
        
            if not table.find(t2, elem) then
            
                return false
                
            else
            
                table.removevalue(t2, elem)
                
            end
        
        end
        
        return true
        
    end
    
    return false
    
end

function entryInTable(t, entry)
    
    if(t ~= nil) then
    
        for index, subTable in ipairs(t) do
        
            if (subTable[2] == entry) then
            
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

/**
 * Removes all elements from a table.
 */
function table.clear(t)

    if(t ~= nil) then
    
        local numElements = table.maxn(t)
    
        for i = 1, numElements do
        
            table.remove(t, 1)
            
        end
        
    end
    
end

/**
 * Way to elegantly remove elements from a table according to a function.
 * Eg: table.removeConditional(t, function (elem) return elem == "test5" end)
 */
function table.removeConditional(t, conditionalFunction)

    if(t ~= nil) then
    
        local numElements = table.maxn(t)
    
        local i = 1
        while i <= numElements do
        
            local element = t[i]
            
            if element then
            
                if conditionalFunction(element) then
                
                    table.remove(t, i)
                    
                    numElements = numElements - 1
                    
                    i = i - 1
                    
                end
                
            end
            
            i = i + 1
            
        end
        
    end

end

/**
 * Removes the specified value from the table (note only the first occurance is
 * removed). Returns true if element was found and removed, false otherwise.
 * This will not work for tables created as dictionaries.
 */
function table.removevalue(t, v)

    local i = table.find(t, v)

    if i ~= nil then
    
        table.remove(t, i)
        return true
        
    end
    
    return false

end

function table.insertunique(t, v)

    if(table.find(t, v) == nil) then
    
        table.insert(t, v)
        return true
        
    end
    
    return false
    
end

/**
 * Adds the contents of one table to another. Duplicate elements added.
 */
function table.addtable(srcTable, destTable)

    for index, element in ipairs(srcTable) do
    
        table.insert(destTable, element)

    end
    
end

/**
 * Adds the contents of onte table to another. Duplicate elements are not inserted.
 */
function table.adduniquetable(srcTable, destTable)

    for index, element in ipairs(srcTable) do
    
        table.insertunique(destTable, element)

    end
    
end

/**
 * Call specified functor with every element in the table.
 */
function table.foreachfunctor(t, functor)

    if(table.maxn(t) > 0) then
    
        for index, element in ipairs(t) do
        
            functor(element)
            
        end
        
    end
    
end

function table.count(t, logError)
    if(t ~= nil) then
        return table.maxn(t)
    elseif logError then
        Print("table.count() - Nil table passed in, returning 0.")
    end
    return 0
end

/**
 * Counts up the number of keys. This is different from table.count
 * because dictionaries do not have numbered keys and so won't be
 * counted correctly. It is also slower.
 */
function table.countkeys(t)

    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count

end

function table.removeTable(srcTable, destTable)

    for index, elem in ipairs(srcTable, destTable) do
    
        local index = table.find(destTable, elem)
        
        if index ~= nil then
            table.remove(destTable, index)
        end
        
    end
    
end

// Returns a table full of elements that aren't found in both tables
function table.diff(t1, t2)

    local newT1 = {}
    table.copy(t1, newT1)
    
    local newT2 = {}
    table.copy(t2, newT2)
    
    table.removeTable(t1, newT2)
    table.removeTable(t2, newT1)

    local output = {}
    table.copy(newT1, output)
    table.copy(newT2, output, true)
    
    return output
    
end

/**
 * Print the table to a string and returns it. Eg, "{ "element1", "element2", {1, 2} }".
 */
function table.tostring(t)

    local buffer = {}
        
    table.insert(buffer, "{")
    
    if(type(t) == "table") then

        local numElements = table.maxn(t)
        local currentElement = 1
        
        for key, value in pairs(t) do
        
            if(type(value) == "table") then
            
                table.insert(buffer, table.tostring(value))
            
            elseif(type(value) == "number") then

                /* For printing out lists of entity ids
                
                local className = "unknown"
                local entity = Shared.GetEntity(value)
                if(entity ~= nil) then
                    className = entity:GetMapName()
                end
                
                table.insert(buffer, string.format("%s (%s)", tostring(value), tostring(className)))
                */
                
                table.insert(buffer, string.format("%s", tostring(value)))
                
            elseif(type(value) == "userdata") then
            
                if value.GetClassName then
                    table.insert(buffer, string.format("class \"%s\"", value:GetClassName()))
                end
                
            else
            
                table.insert(buffer, string.format("\"%s\"", tostring(value)))
                
            end
            
            // Insert commas between elements
            if(currentElement ~= numElements) then
            
                table.insert(buffer, ",")
                
            end
            
            currentElement = currentElement + 1
        
        end
        
    else
    
        table.insert(buffer, "<data is \"" .. type(t) .. "\", not \"table\">")
        
    end
    
    table.insert(buffer, "}")
    
    return table.concat(buffer)
    
end
