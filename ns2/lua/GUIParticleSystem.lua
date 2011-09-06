// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIParticleSystem.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages emitters and particles that display on the GUI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


// Helper functions.
local function GetRandomEmissionTime(forEmitter)
    local minRateLimit = forEmitter.RateLimits.Min
    local maxRateLimit = forEmitter.RateLimits.Max
    return minRateLimit + ((maxRateLimit - minRateLimit) * math.random())
end

local function GetRandomVelocity(forEmitter)
    local minVelocity = forEmitter.VelocityLimits.Min
    local maxVelocity = forEmitter.VelocityLimits.Max
    local randomX = minVelocity.x + ((maxVelocity.x - minVelocity.x) * math.random())
    local randomY = minVelocity.y + ((maxVelocity.y - minVelocity.y) * math.random())
    return Vector(randomX, randomY, 0)
end

local function GetRandomAccel(forEmitter)
    local minAccel = forEmitter.AccelLimits.Min
    local maxAccel = forEmitter.AccelLimits.Max
    local randomX = minAccel.x + ((maxAccel.x - minAccel.x) * math.random())
    local randomY = minAccel.y + ((maxAccel.y - minAccel.y) * math.random())
    return Vector(randomX, randomY, 0)
end

local function GetRandomSize(forEmitter)
    local minSize = Vector(forEmitter.SizeLimits.MinX, forEmitter.SizeLimits.MinY, 0)
    local maxSize = Vector(forEmitter.SizeLimits.MaxX, forEmitter.SizeLimits.MaxY, 0)
    return minSize + ((maxSize - minSize) * math.random())
end

local function GetRandomEmitOffset(forEmitter)
    local returnOffset = Vector(0, 0, 0)
    if forEmitter.EmitOffsetLimits then
        local minOffset = forEmitter.EmitOffsetLimits.Min
        local maxOffset = forEmitter.EmitOffsetLimits.Max
        returnOffset.x = minOffset.x + ((maxOffset.x - minOffset.x) * math.random())
        returnOffset.y = minOffset.y + ((maxOffset.y - minOffset.y) * math.random())
    end
    return returnOffset
end

local function GetRandomLifeTime(forEmitter)
    local minLifeTime = forEmitter.LifeLimits.Min
    local maxLifeTime = forEmitter.LifeLimits.Max
    return minLifeTime + ((maxLifeTime - minLifeTime) * math.random())
end


class 'GUIParticleSystem'

// The size of the background doesn't really matter as it is invisible.
GUIParticleSystem.kBackgroundSize = 100

function GUIParticleSystem:Initialize()

    // There is an invisible background that all the particles are anchored to.
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIParticleSystem.kBackgroundSize, GUIParticleSystem.kBackgroundSize, 0))
    self.background:SetColor(Color(0, 0, 0, 0))
    
    self.particles = { }
    self.particleTypes = { }
    self.emitters = { }
    self.modifiers = { }

end

function GUIParticleSystem:Uninitialize()
    
    for p, particle in ipairs(self.particles) do
        GUI.DestroyItem(particle.Item)
    end
    
    self.particles = { }
    self.particleTypes = { }
    self.emitters = { }
    self.modifiers = { }
    
    GUI.DestroyItem(self.background)
    self.background = nil

end

function GUIParticleSystem:AttachToItem(attachItem)

    ASSERT(attachItem ~= nil)

    attachItem:AddChild(self.background)

end

function GUIParticleSystem:SetAnchor(setXAnchor, setYAnchor)

    self.background:SetAnchor(setXAnchor, setYAnchor)

end

function GUIParticleSystem:SetLayer(setLayer)

    // If a layer is set, this system should render in that layer even if it has a parent.
    self.background:SetParentRenders(false)
    self.background:SetLayer(setLayer)

end

function GUIParticleSystem:SetIsVisible(setVisible)

    self.background:SetIsVisible(setVisible)

end

/**
 * Define a particle type that can be emitted by this system.
 * Pass in a type name to identify this particle type later.
 * Pass in a table that has function names contained in a GUIItem such as SetTexture.
 * The function name is a key followed by a table of possible values. A random one will be selected
 * for each emitted particle.
 * SetColor = { Color(0, 0, 0, 1), Color(1, 1, 1, 1) } for example.
 */
function GUIParticleSystem:AddParticleType(typeName, particleValues)

    ASSERT(type(typeName) == "string")
    ASSERT(type(particleValues) == "table")

    self.particleTypes[typeName] = particleValues

end

/**
 * Add a particle emitter to the system.
 * Pass in a table that has the following elements:
 * Name - A string to indentify this emitter later.
 * Position - A Vector describing the location of this emitter relative to the origin
 *  of the background.
 * EmitOffsetLimits - Optional, a table with a min and max offset for an emitted particles starting location.
 *  { Min = Vector(-5, -3.5, 0), Max = Vector(5, 3.5, 0) } for example.
 * SizeLimits - A table with a min and max size for the x and y axis,
 *  { MinX = 2, MaxX = 5, MinY = 7, MaxY = 10 } for example.
 * VelocityLimits - A table with a min and max velocity particles can have,
 *  { Min = Vector(-100, 20, 0), Max = Vector(100, 30, 0) } for example.
 * AccelLimits - A table with a min and max acceleration that changes velocity over time.
 *  { Min = Vector(-0.5, 0, 0), Max = Vector(0.5, 2, 0) } for example.
 * RateLimits - A table to specify how often particles are emitted,
 *  { Min = 0.5, Max = 2.3 } would emit a particle every 0.5 to 2.3 seconds for example.
 * LifeLimits - A table to specify how long emitted particles last.
 *  { Min = 0.8, Max = 4 } indicates a particle lives for 0.8 to 4 seconds for example.
 * LifeTimeFuncs - A table with all the functions to call during the lifetime of all particles
 *  emitted from this emitter. The particle is passed in with the lifetime as a number between 0 and 1.
 *  { function(particle, lifetime) particle.Item:SetColor(Color(1, 1, 1, lifetime)) end } for example.
 */
function GUIParticleSystem:AddEmitter(emitterDefTable)

    ASSERT(type(emitterDefTable) == "table")
    ASSERT(type(emitterDefTable.Name) == "string")
    ASSERT(emitterDefTable.Position ~= nil)
    ASSERT(type(emitterDefTable.SizeLimits) == "table")
    ASSERT(emitterDefTable.SizeLimits.MinX <= emitterDefTable.SizeLimits.MaxX)
    ASSERT(emitterDefTable.SizeLimits.MinY <= emitterDefTable.SizeLimits.MaxY)
    ASSERT(type(emitterDefTable.VelocityLimits) == "table")
    ASSERT(type(emitterDefTable.AccelLimits) == "table")
    ASSERT(type(emitterDefTable.RateLimits) == "table")
    ASSERT(type(emitterDefTable.LifeLimits) == "table")
    ASSERT(type(emitterDefTable.LifeTimeFuncs) == "table")

    self.emitters[emitterDefTable.Name] = emitterDefTable
    self.emitters[emitterDefTable.Name].timeUntilEmission = GetRandomEmissionTime(emitterDefTable)
    self.emitters[emitterDefTable.Name].particleTypesToEmit = { }

end

/**
 * Defines which particle types can be emitted by the emitter.
 */
function GUIParticleSystem:AddParticleTypeToEmitter(particleTypeName, emitterName)

    ASSERT(self.emitters[emitterName] ~= nil)
    ASSERT(type(particleTypeName) == "string")

    table.insert(self.emitters[emitterName].particleTypesToEmit, particleTypeName)

end

/**
 * Adds a particle modifier to the system.
 * Pass in a table that has the following elements.
 * Name - A string to indentify this modifier later.
 * ModFunc - A function that will modify a particle.
 *  function(particle, deltaTime) particle.velocity = particle.velocity * 0.1 * deltaTime end for example.
 */
function GUIParticleSystem:AddModifier(modifierDefTable)

    ASSERT(type(modifierDefTable) == "table")
    ASSERT(type(modifierDefTable.Name) == "string")
    ASSERT(type(modifierDefTable.ModFunc) == "function")
    
    self.modifiers[modifierDefTable.Name] = modifierDefTable

end

/**
 * Fast forward the system in cases where particles should be visible right
 * away (you don't want to wait for enough to spawn).
 * This will simulate the amount of time passed in the first parameter in discrete
 * chunks of time as specified in the optional second parameter.
 */
function GUIParticleSystem:FastForward(deltaTime, timeChunk)

    if not timeChunk then
        timeChunk = 0.1
    end
    
    while deltaTime > 0 do
    
        // Simulate either timeChunk or what is left in deltaTime, whatever
        // is smaller.
        local simAmount = math.min(timeChunk, deltaTime - timeChunk)
        deltaTime = deltaTime - timeChunk
        self:Update(simAmount)
    
    end

end

/**
 * This will emit and simulate particles for the amount of time
 * passed in. It should generally be called every tick with a deltaTime.
 */
function GUIParticleSystem:Update(deltaTime)

    PROFILE("GUIParticleSystem:Update")

    ASSERT(type(deltaTime) == "number")
    
    for i, emitter in pairs(self.emitters) do
        self:_UpdateEmitter(emitter, deltaTime)
    end
    
    for p, particle in ipairs(self.particles) do
    
        if particle.Active then
        
            for m, modifier in pairs(self.modifiers) do
                modifier.ModFunc(particle, deltaTime)
            end
            
            self:_UpdateParticle(particle, deltaTime)
            
        end
        
    end

end

function GUIParticleSystem:_UpdateEmitter(emitter, deltaTime)

    // Create new particles based on emission rates.
    emitter.timeUntilEmission = emitter.timeUntilEmission - deltaTime
    
    while emitter.timeUntilEmission <= 0 do
    
        emitter.timeUntilEmission = emitter.timeUntilEmission + GetRandomEmissionTime(emitter)
        
        self:_EmitParticle(emitter)
        
    end

end

function GUIParticleSystem:_EmitParticle(emitter)

    if table.count(emitter.particleTypesToEmit) > 0 then
        
        local freeParticle = self:_GetFreeParticle()
        local particleTypeName = emitter.particleTypesToEmit[math.random(1, table.count(emitter.particleTypesToEmit))]
        local randomParticleType = self.particleTypes[particleTypeName]
        
        // Loop through the particle GUIItem values and call each function with a random value.
        // These are the functions/values passed into AddParticleType() above.
        for funcName, values in pairs(randomParticleType) do
            local randomValue = values[math.random(1, table.count(values))]
            local itemOperation = freeParticle.Item[funcName]
            ASSERT(type(itemOperation) == "function")
            // If the random value is a table, unpack the values from it.
            if type(randomValue) == "table" then
                itemOperation(freeParticle.Item, unpack(randomValue))
            else
                itemOperation(freeParticle.Item, randomValue)
            end
        end
        
        local randomSize = GetRandomSize(emitter)
        freeParticle.Item:SetSize(randomSize)
        
        local randomOffset = GetRandomEmitOffset(emitter)
        freeParticle.Item:SetPosition(Vector((emitter.Position.x - randomSize.x / 2) + randomOffset.x, (emitter.Position.y - randomSize.y / 2) + randomOffset.y, 0))
        
        freeParticle.velocity = GetRandomVelocity(emitter)
        freeParticle.Accel = GetRandomAccel(emitter)
        freeParticle.LifeTimeFuncs = emitter.LifeTimeFuncs
        freeParticle.TotalLifeTime = GetRandomLifeTime(emitter)
        freeParticle.lifeTimeLeft = freeParticle.TotalLifeTime
        
    end

end

function GUIParticleSystem:_GetFreeParticle()

    for p, particle in ipairs(self.particles) do
    
        if not particle.Active then
            particle.Active = true
            particle.Item:SetIsVisible(true)
            return particle
        end
        
    end
    
    // Could not find a free one, creata a new particle.
    local newParticle = { Active = true }
    newParticle.Item = GUIManager:CreateGraphicItem()
    self.background:AddChild(newParticle.Item)
    table.insert(self.particles, newParticle)
    return newParticle

end

function GUIParticleSystem:_UpdateParticle(particle, deltaTime)

    particle.lifeTimeLeft = particle.lifeTimeLeft - deltaTime
    particle.velocity = particle.velocity + (particle.Accel * deltaTime)
    particle.Item:SetPosition(particle.Item:GetPosition() + (particle.velocity * deltaTime))
    for i, lifeTimeFunc in ipairs(particle.LifeTimeFuncs) do
        lifeTimeFunc(particle, 1 - (particle.lifeTimeLeft / particle.TotalLifeTime))
    end
    if particle.lifeTimeLeft <= 0 then
        particle.Active = false
        particle.Item:SetIsVisible(false)
    end

end