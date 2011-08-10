// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Cyst.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// A cyst controls and spreads infestation
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Cyst' (Structure)

PrepareClassForMixin(Cyst, InfestationMixin)

Cyst.kMaxEncodedPathLength = 30
Cyst.kMapName = "cyst"
Cyst.kModelName = PrecacheAsset("models/alien/pustule/pustule.model")
Cyst.kOffModelName = PrecacheAsset("models/alien/pustule/pustule_off.model")

Cyst.kEnergyCost = 25
Cyst.kPointValue = 5
// how fast the impulse moves
Cyst.kImpulseSpeed = 8

Cyst.kThinkInterval = 1 
Cyst.kImpulseColor = Color(1,1,0)
Cyst.kImpulseLightIntensity = 8
Cyst.kImpulseLightRadius = 1

Cyst.kExtents = Vector(0.2, 0.1, 0.2)

// range at which we can be a parent
Cyst.kCystParentRange = kCystParentRange

// size of infestation patch
Cyst.kInfestationRadius = kInfestationRadius

local networkVars = {
    // Track our parentId
    parentId         = "entityid",    
        
    // when the last impulse was started. The impulse is inactive if the starttime + pathtime < now
    impulseStartTime = "float",

    // id of our owned infestation
    infestationId    = "entityid",  
    
    // if we are connected. Note: do NOT use on the server side when calculating reconnects/disconnects,
    // as the random order of entity update means that you can't trust it to reflect the actual connect/disconnects
    // used on the client side by the ui to determine connection status for potently cyst building locations
    connected        = "boolean",
}

function CreateBetween(trackStart, trackEnd)
    trackStart = trackStart + Vector(0, 0.25, 0)
    trackEnd   = trackEnd 
    local points = FindConnectionPath(trackEnd, trackStart)
    
    if points ~= nil then
        return points
    end

    return nil
end


if Server then
    Script.Load("lua/Cyst_Server.lua")
end

function Cyst:OnInit()

    InitMixin(self, InfestationMixin)
    
    Structure.OnInit(self)
    
    self.parentId = Entity.invalidId    
 
    if Server then
    
        // start out as disconnected; wait for impulse to arrive
        self.connected = false
        
        // mark us as not having received an impulse
        self.lastImpulseReceived = -1000
        
        self.lastImpulseSent = Shared.GetTime() 
        self.nextUpdate = Shared.GetTime()
        self.impulseActive = false
        self.children = { }
        self.infestationId = Entity.invalidId
        
        // initalize impulse setup
        self.impulseStartTime = 0
        
    elseif Client then    
    
        // create the impulse light
        self.light = Client.CreateRenderLight()
        
        self.light:SetType( RenderLight.Type_Point )
        self.light:SetCastsShadows( false )

        self.lightCoords = CopyCoords(self:GetCoords())
        self.light:SetCoords( self.lightCoords )
        self.light:SetRadius( Cyst.kImpulseLightRadius )
        self.light:SetIntensity( Cyst.kImpulseLightIntensity ) 
        self.light:SetColor( Cyst.kImpulseColor )
            
        self.light:SetIsVisible(true) 

    end
    
    self.points = nil
    self.pathLen = 0
    self.index = 1    
    
    self:SetUpdates(true)
    
end

// No idle for cyst, removing this function will cause
// EffectManager to attempt to lookup the cyst idle effects
// which is a very slow process.
function Cyst:OnIdle()
end

function _DebugTrack(points, dur, r, g, b, a, force)
    if force then
        local prevP = nil
        for _,p in ipairs(points) do
            if prevP then
                DebugLine(prevP, p,dur, r, g, b, a)
                DebugLine(p, p + Vector.yAxis , dur, r, g, b, a)
            end
            prevP = p
        end
    end
end

function Cyst:GetAddToPathing()
  return false
end

/**
 * Draw the track using the given color/dur (defaults to 30/green)
 */
function Cyst:Debug(dur, color)
    dur = dur or 30
    color = color or { 0, 1, 0, 1 }
    
    local r,g,b,a = unpack(color)
    
    _DebugTrack(self.points, dur,r,g,b,a, true)
end

function Cyst:StartOnSegment(index)
    ASSERT(index <= table.count(self.points))
    ASSERT(index >= 1)    
    self.index = index
    if index < self.pathLen then
        self.segment = self.points[index+1]-self.points[index]
    else
        self.segment = Vector(0, 0, 0)
    end
    self.length = self.segment:GetLength()
    self.segmentLengthRemaining = self.length
end

function Cyst:AdvanceTo(time)
    if self.index == self.pathLen then
        return nil
    end
    
    if self.pathLen and self.pathLen == 1 then
      return nil
    end
    
    local deltaTime = time - self.currentTime
    self.currentTime = time
    
    local length = self.speed * deltaTime
    
    while length > self.segmentLengthRemaining do
        self.index = self.index + 1
        if self.index == self.pathLen then
            return nil
        end
        length = length - self.segmentLengthRemaining
        self:StartOnSegment(self.index)        
    end
    self.segmentLengthRemaining = self.segmentLengthRemaining - length
    local fraction = (self.length - self.segmentLengthRemaining) / self.length
    return self.points[self.index] + self.segment * fraction
end

function Cyst:GetIsAlienStructure()
    return true
end

function Cyst:GetInfestationRadius()
    return Cyst.kInfestationRadius
end

function Cyst:GetCystParentRange()
    return Cyst.kCystParentRange
end

function Cyst:GetInfestation()
    return Shared.GetEntity(self.infestationId)
end        

/**
 * Note: On the server side, used GetIsActuallyConnected()!
 */
function Cyst:GetIsConnected() 
    return self.connected
end

function Cyst:GetDescription()
    local prePendText = ConditionalValue(self:GetIsConnected(), "", "Unconnected ")
    return prePendText .. Structure.GetDescription(self)
end

function Cyst:OnDestroy()
    if (Client) then    
        if (self.light ~= nil) then
            Client.DestroyRenderLight(self.light)
        end        
    end
    
    Structure.OnDestroy(self)    
end


function Cyst:GetIsAlienStructure()
    return true
end


function Cyst:GetDeployAnimation()
    return ""
end

function Cyst:GetCanDoDamage()
    return false
end

function Cyst:GetEngagementPoint()
   // Structure:GetEngagementPoint requires a target attachment point on the model, which Cyst doesn't have right now,
   // so override to get rid of the console spam
    return LiveScriptActor.GetEngagementPoint(self) 
end

function Cyst:OnOverrideSpawnInfestation(infestation)
    infestation.maxRadius = kInfestationRadius 
    infestation:SetRadiusPercent(.2)
end

function Cyst:Restart(time)
  self.startTime = time
  self.currentTime = time
  self.index = 1
  self.speed = Cyst.kImpulseSpeed
  self.pathLen = #(self.points)
  self:StartOnSegment(1)
end

function Cyst:OnUpdate(deltaTime)

    PROFILE("Cyst:OnUpdate")
    
    Structure.OnUpdate(self, deltaTime)
    
    local point = nil
    local now = Shared.GetTime()
                   
    // Make a connect to the parent so we can do the visual whatevers 
    // the client and server could differ in these paths but to be honest
    // the server is always the authority the client is just for visuals 
    // which could be out of sync
    if (self.points == nil)then   
        local parent = self:GetCystParent()
        if parent ~= nil then
         // Create the connect between me and my parent
         local parentOrigin = parent:GetOrigin()
         local myOrigin = self:GetOrigin()
         
         self.points = CreateBetween(myOrigin, parentOrigin)
         if (self.points) then
            self:Restart(self.impulseStartTime)
         end
         
        end        
    else 
         // if we have a tracker, check if we need to restart it
        if self.impulseStartTime ~= self.startTime then         
            self:Restart(self.impulseStartTime)
        end
  
        // Advanced the point on the timeline     
        point = self:AdvanceTo(now)      
    end    
    
    if Server then
        self:Update(point, deltaTime)
    else
        self.light:SetIsVisible(point ~= nil)
        if point then
            self.lightCoords.origin = point            
            self.light:SetCoords(self.lightCoords)
        end
    end      

end

function Cyst:GetCystParent()
    local parent = nil
    if self.parentId and self.parentId ~= Entity.invalidId then
        parent = Shared.GetEntity(self.parentId)
    end
    return parent
end

/**
 * Returns a parent and the track from that parent, or nil if none found.
 */
function GetCystParentFromPoint(origin, normal)

    PROFILE("GetCystParentFromPoint")   

    local ents = GetSortedListOfPotentialParents(origin)
    
    for i,ent in ipairs(ents) do
        
        // must be either a built hive or an cyst with a connected infestation
        if ((ent:isa("Hive") and ent:GetIsBuilt()) or (ent.GetIsConnected and ent:GetIsConnected())) then
            local range = (origin - ent:GetOrigin()):GetLength() 
            if range <= ent:GetCystParentRange() then                
                // check if we have a track from the entity to origin
                local path = CreateBetween(ent:GetOrigin(), origin )
                if path then
                    // Check that the total path length is within the range.
                    local pathLength = GetPointDistance(path)
                    if pathLength <= ent:GetCystParentRange() then
                        return ent, path
                    end
                end
            end
        end
    end
    
    return nil, nil
end

/**
 * Return true if a connected cyst parent is availble at the given origin normal. 
 */
function GetCystParentAvailable(techId, origin, normal, commander)    
    local parent, path = GetCystParentFromPoint(origin, normal)    
    return parent ~= nil
    
end

/**
 * Returns a ghost-guide table for gui-use. 
 */
function GetCystGhostGuides(commander)    
    local parent, path = commander:GetCystParentFromCursor()
    local result = {}
    if parent then
        result[parent] = parent:GetCystParentRange()
    end
    return result    
end

function GetIsPositionConnected(origin,normal)
    local parent, path = GetCystParentFromPoint(origin, normal)
    return parent ~= nil    
end

function GetSortedListOfPotentialParents(origin)
    
    function sortByDistance(ent1, ent2)
        return (ent1:GetOrigin() - origin):GetLength() < (ent2:GetOrigin() - origin):GetLength()
    end
    
    // first, check for hives
    local hives = GetEntitiesWithinRange("Hive", origin, kHiveCystParentRange)
    table.sort(hives, sortByDistance)
    
    // add in the cysts. We get all cysts here, but mini-cysts have a shorter parenting range (bug, should be filtered out)
    local cysts = GetEntitiesWithinRange("Cyst", origin, kCystParentRange)
    table.sort(cysts, sortByDistance)
    
    local parents = {}
    table.copy(hives, parents)
    table.copy(cysts, parents, true)
    
    return parents
    
end

function Cyst:GetCystModelName(connected)
    return ConditionalValue(connected, Cyst.kModelName, Cyst.kOffModelName)
end

Shared.LinkClassToMap("Cyst", Cyst.kMapName, networkVars)