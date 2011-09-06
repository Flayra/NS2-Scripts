// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\MixinUtility.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================   

Script.Load("lua/FunctionContracts.lua")

local function MixinSendEvent(self, eventName, ...)

    local returnValues = nil
    if self.__watchedEvents[eventName] then
        for index, eventHandler in ipairs(self.__watchedEvents[eventName]) do
            returnValues = { eventHandler(self, unpack(arg)) }
        end
    end
    
    // Return the last values returned by an event handler if present.
    // Otherwise, just return all the parameters passed in by default.
    return (returnValues and unpack(returnValues)) or unpack(arg)

end
// Don't have variable number of arguments handled yet.
//AddFunctionContract(MixinSendEvent, { Arguments = { "Entity", "string", "..." }, Returns = { "..." } })

local function MixinWatchEvent(self, eventName, eventHandler)

    if self.__watchedEvents[eventName] == nil then
        self.__watchedEvents[eventName] = { }
    end
    table.insert(self.__watchedEvents[eventName], eventHandler)

end
AddFunctionContract(MixinWatchEvent, { Arguments = { "Entity", "string", "function" }, Returns = { } })

local function CheckExpectedMixins(classInstance, theMixin)

    if theMixin.expectedMixins then
    
        assert(type(theMixin.expectedMixins) == "table", "Expected Mixins should be a table of Mixin type names and documentation on what the Mixin is needed for.")
        for mixinType, mixinInfo in pairs(theMixin.expectedMixins) do
        
            if not HasMixin(classInstance, mixinType) then
                error("Mixin type " .. mixinType .. " was expected on class instance while initializing mixin type " .. theMixin.type .. "\nInfo: " .. mixinInfo)
            end
            
        end
        
    end

end

local function CheckExpectedCallbacks(classInstance, theMixin)

    if theMixin.expectedCallbacks then
    
        assert(type(theMixin.expectedCallbacks) == "table", "Expected callbacks should be a table of callback function names and documentation on how the function is used")
        for callbackName, callbackInfo in pairs(theMixin.expectedCallbacks) do
        
            if type(classInstance[callbackName]) ~= "function" then
                error("Callback named " .. callbackName .. " was expected for mixin type " .. theMixin.type .. "\nInfo: " .. callbackInfo)
            end
            
        end
        
    end

end

local function CheckExpectedConstants(classInstance, theMixin)

    if theMixin.expectedConstants then
    
        for constantName, constantInfo in pairs(theMixin.expectedConstants) do
        
            if classInstance.__mixindata[constantName] == nil then
                error("Constant named " .. constantName .. " expected\nInfo: " .. constantInfo)
            end
            
        end
        
    end

end

// This should be called for all Mixins that will be added to a class instance
// in case the mixin has to do anything special to the class (add network fields).
function PrepareClassForMixin(toClass, theMixin, ...)

    // Allow the mixin to initialize the class it is being added to.
    if theMixin.__prepareclass then
        theMixin.__prepareclass(toClass, ...)
    end

end

// InitMixin takes a class instance and adds the passed in mixin functions to it if the class instance
// doesn't yet have the mixin. If the mixin was previously added, it reinitializes the mixin for the instance.
function InitMixin(classInstance, theMixin, optionalMixinData)

    // Don't add the mixin to the class instance again.
    if not HasMixin(classInstance, theMixin) then
    
        // Add the Mixin type as a tag for the classInstance if it is an Entity.
        if Shared and Shared.AddTagToEntity and classInstance:isa("Entity") then
            Shared.AddTagToEntity(classInstance:GetId(), theMixin.type)
        end
        
        // Ensure the class has the expected Mixins.
        CheckExpectedMixins(classInstance, theMixin)
        
        // Ensure the class instance implements the expected callbacks.
        CheckExpectedCallbacks(classInstance, theMixin)
        
        for k, v in pairs(theMixin) do
            if type(v) == "function" and k ~= "__initmixin" and k ~= "__prepareclass" then
                // Directly set the function for this class instance.
                // Only affects this instance.
                local classFunction = classInstance[k]
                if classFunction == nil then
                    classInstance[k] = v
                
                // If the function already exists then it is added to a list of functions to call.
                // The return values from the last called function in this list is returned.
                else
                
                    local functionsTable = classInstance[k .. "__functions"]
                    if functionsTable == nil then
                        
                        local allFunctionsTable = { }
                        // Insert existing function.
                        table.insert(allFunctionsTable, classFunction)
                        // Then insert the new Mixin function.
                        table.insert(allFunctionsTable, v)
                        
                        local function _CallAllFunctions(ignoreSelf, ...)
                            local allReturns = { }
                            for i, callFunc in ipairs(allFunctionsTable) do
                                local returnResults = { callFunc(classInstance, unpack(arg)) }
                                for i = #returnResults, 1, -1 do
                                    table.insert(allReturns, 1, returnResults[i])
                                end
                            end
                            return unpack(allReturns)
                        end
                        classInstance[k .. "__functions"] = allFunctionsTable
                        classInstance[k] = _CallAllFunctions
                        
                    else
                        table.insert(functionsTable, v)
                    end
                    
                end
            end
        end
        
        // Keep track that this mixin has been added to the class instance.
        if classInstance.__mixinlist == nil then
            classInstance.__mixinlist = { }
            
            // Add in the event functions.
            assert(classInstance.MixinSendEvent == nil and classInstance.MixinWatchEvent == nil)
            classInstance.MixinSendEvent = MixinSendEvent
            classInstance.MixinWatchEvent = MixinWatchEvent
            classInstance.__watchedEvents = { }
        end
        table.insert(classInstance.__mixinlist, theMixin)
        
        // Add the static mixin data to this class instance.
        if classInstance.__mixindata == nil then
            classInstance.__mixindata = { }
            function classInstance:GetMixinConstants() return self.__mixindata end
        end
        if optionalMixinData then
            for k, v in pairs(optionalMixinData) do
                classInstance.__mixindata[k] = v
            end
        end
        
        // Ensure the expected constants are present.
        CheckExpectedConstants(classInstance, theMixin)
        
    end
    
    // Finally, initialize the mixin on this class instance.
    // This can be done multiple times for a class instance.
    if theMixin.__initmixin then
        theMixin.__initmixin(classInstance)
    end

end
AddFunctionContract(InitMixin, { Arguments = { { "userdata", "table" }, "table", { "table", "nil" } }, Returns = { } })

// Returns true if the passed in class instance has a Mixin that
// matches the passed in mixin table or mixin type name.
// Note, this name can be shared by multiple Mixin types.
// It is more of an implicit interface the Mixin adheres to.
function HasMixin(classInstance, mixinTypeOrTypeName)

    if classInstance.__mixinlist then
        for index, currentMixin in ipairs(classInstance.__mixinlist) do
            if (type(mixinTypeOrTypeName) == "string" and currentMixin.type == mixinTypeOrTypeName) or
               (type(mixinTypeOrTypeName) == "table" and currentMixin == mixinTypeOrTypeName) then
                return true
            end
        end
    end
    return false

end
AddFunctionContract(HasMixin, { Arguments = { { "userdata", "table" }, { "string", "table" } }, Returns = { "boolean" } })

// Returns the number of mixins the passed in class instance currently is using.
function NumberOfMixins(classInstance)

    ASSERT(type(classInstance) == "userdata", "First parameter to InitMixin() must be a class instance")
    
    if classInstance.__mixinlist then
        return table.count(classInstance.__mixinlist)
    end
    return 0

end