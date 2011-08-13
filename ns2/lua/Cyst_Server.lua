//=============================================================================
//
// lua\Cyst_Server.lua
//
// Created by Mats Olsson (mats.olsson@matsotech.se) and 
// Charlie Cleveland (charlie@unknownworlds.com)
//
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//============================================================================


Cyst.kThinkTime = 1

// How long we can be without a confirmation impulse before we disconnect
Cyst.kImpulseDisconnectTime = 15

function Cyst:SetCystParent(parent)

    ASSERT(parent ~= self)

    self.parentId = parent:GetId()
    parent:AddChildCyst(self)    
end

/**
 * Return true if we are ACTUALLY connected, ie our ultimate parent is a Hive. 
 *
 * Note: this is valid only on the server, as the client may not (probably does not)
 * have all the entities in the chain to the hive loaded.
 * 
 * the GetIsConnected() method used the connect bit, which may not reflect the actual connection status.
 */
function Cyst:GetIsActuallyConnected()
    
    local parent = self:GetCystParent()
    if parent and parent ~= start then
        if parent:isa("Hive") then
            return true
        end
        return parent:GetIsActuallyConnected()
    end
    return false
end


/**
 * If we can track to our new parent, use it instead
 */
function Cyst:TryNewCystParent(parent)

    local path = CreateBetween(parent:GetOrigin(),self:GetOrigin())

    if path then
        local pathLength = GetPointDistance(path)
        if pathLength <= parent:GetCystParentRange() then
            Log("%s found better parent %s", self, parent)
            self:ReplaceParent(parent)
            return true
        end            
    end
    
    return false
end

/**
 * Returns a parent and the track from that parent, or nil if none found. 
 * 
 * This is is very similar to GetCystParentFromPoint, but uses ACTUALLY connected rather than the connect flag.
 */
function Cyst:FindBestParent()

    local origin = self:GetOrigin()
    local ents = GetSortedListOfPotentialParents(origin)
    
    for i,ent in ipairs(ents) do
        // must be either a hive or an cyst with a connected infestation
        if self ~= ent and ((ent:isa("Hive") and ent:GetIsBuilt()) or (ent.GetIsActuallyConnected and ent:GetIsActuallyConnected())) then
            local range = (origin - ent:GetOrigin()):GetLength() 
            if range <= ent:GetCystParentRange() then
                // check if we have a track from the entity to origin
                local path = CreateBetween(ent:GetOrigin(), origin)
                // Check that the total path length is within the range.
                local pathLength = GetPointDistance(path)
                if pathLength <= ent:GetCystParentRange() then
                    return ent, path
                end
            end
        end
    end
    
    return nil, nil
end

/**
 * Try to find an actually connected parent. Connect to the closest entity (but bias hives).
 */
function Cyst:TryToFindABetterParent()
    local parent, path = self:FindBestParent(self, self:GetOrigin(), self:GetCoords().yAxis)

    if parent and path then
        self:ReplaceParent(parent)
        return true
    end
    
    return false
    
end

/**
 * Reconnect any other cysts to me
 */
function Cyst:ReconnectOthers()

    local cysts = GetEntitiesWithinRange("Cyst", self:GetOrigin(), self:GetCystParentRange())

    for _, cyst in ipairs(cysts) do
        // when working on the server side, always use the actually connected rather than the connected bit
        // the connected 
        if not cyst:GetIsActuallyConnected() then
            cyst:TryNewCystParent(self)
        end
    end    
end

function Cyst:TriggerDamage()
  if (self:GetCystParent() == nil) then
     // Increase damage over time the longer it hasn't been connected if alien "islands" are 
     // being kept alive undesirably long by Crags, Gorges and such
     local damage = kCystUnconnectedDamage * Cyst.kThinkTime
     self:TakeDamage(damage, nil, self, self:GetOrigin(), nil)
  end
end

function Cyst:DamageChildren()
   local numChildHurt = 0   
   for key,id in pairs(self.children) do
        local child = Shared.GetEntity(id)
        if child ~= nil then
            child:TriggerDamage(now)
            numChildHurt = numChildHurt + 1
        end
    end
    Print("numChildHurt %s", ToString(numChildHurt))
    return numChildHurt
end
 

function Cyst:Update(point, deltaTime)
    
    if not self.constructionComplete or not self:GetIsAlive() then
        return 
    end
    
    local now = Shared.GetTime()
    
    if now > self.nextUpdate then
    
        local infestation = self:GetInfestation()
        if infestation == nil then
            // this will rebuild the infestation
            self.infestationId = Entity.invalidId
        end
               
        local connectedNow = self:GetIsActuallyConnected() 

        // the very first time we are placed, we try to connect 
        if not self.madeInitialConnectAttempt then
            if not connectedNow then 
                connectedNow = self:TryToFindABetterParent()
            end
            self.madeInitialConnectAttempt = true
        end
        
        // try a single reconnect when we become disconnected
        if self.connected and not connectedNow then
            connectedNow = self:TryToFindABetterParent()
        end 
        
        // if we become connected, see if we have any unconnected pustules around that could use us as their parents
        if not self.connected and connectedNow then
            self:ReconnectOthers()
        end

        // change our model depending on connection state
        if self.connected  ~= connectedNow then
            self.connected = connectedNow
            //Log("%s: change conn status to %s", self, self.connected)
            local modelName = self:GetCystModelName(self.connected)
            self:SetModel(modelName)
        end
        
        self:UpdateInfestation()

        // point == nil signals that the impulse tracker is done
        if self.impulseActive and point == nil then
            self.lastImpulseReceived = now
            self.impulseActive = false
        end
        
        // if we have received an impulse but hasn't sent one out yet, send one
        if self.lastImpulseReceived > self.lastImpulseSent then
            self:FireImpulses(now)
            self.lastImpulseSent = now
        end
        // avoid clumping; don't use now when calculating next think time (large kThinkTime)
        self.nextUpdate = self.nextUpdate + Cyst.kThinkTime
        
        // Take damage if not connected 
        if not self.connected then
          self:TriggerDamage()
        end

    end
    
end

function Cyst:OnKill(targetEntity, damage, killer, doer, point, direction)
    
    // Shrink infestation
    local infestation = self:GetInfestation()
    if infestation ~= nil then
        infestation.hostAlive = false
    end
    
    Structure.OnKill(self, targetEntity, damage, killer, doer, point, direction)
    
end

function Cyst:ReplaceParent(newParent)
    //Log("%s: Activate crosslink from to %s", self, peer)
    // make the peer our child and tell it to make us its parent via the given track
    newParent:AddChildCyst(self)
    self:ChangeParent(newParent)
end


function Cyst:ChangeParent(newParent)
    local oldParent = self:GetCystParent()
    //Log("%s:Changing parent from %s to %s", self, oldParent, newParent)    
    self.children[""..newParent:GetId()] = nil    
    self:SetCystParent(newParent)    
    if oldParent then        
        oldParent:ChangeParent(self)        
    end 
end

function Cyst:FireImpulses(now)
    local removals = {}
    for key,id in pairs(self.children) do
        local child = Shared.GetEntity(id)
        if child == nil then
            removals[key] = true
        else
            // we ask the children to trigger the impulse to themselves
            child:TriggerImpulse(now)
        end
    end
    for key,_ in pairs(removals) do
        self.children[key] = nil
    end
end

/**
 * Trigger an impulse to us along the track. 
 */
function Cyst:TriggerImpulse(now)
    if self.impulseActive then
        //Log("already driving impulse")
    else
        self.impulseStartTime = now
        self.impulseActive = true   
    end
end

function Cyst:AddChildCyst(child)
    // children can die; tragic; so only keep the id around
    self.children["" .. child:GetId()] = child:GetId()
end

function Cyst:OnTakeDamage(damage, attacker, doer, point)

    // When we take disconnection damage, don't play alerts or effects, just expire silently
    if doer ~= self then
        Structure.OnTakeDamage(self, damage, attacker, doer, point)
    end
    
end

function CreateCyst(player, targetPoint, normal, createMini) 

    local cyst = nil
    local connected = false
    
    if createMini then
        // created by the gorge
        cyst = CreateEntity(MiniCyst.kMapName, targetPoint, player:GetTeamNumber())
    else
        // created by the commander (this is never called, actually...)
        ASSERT(player.AttemptToBuild ~= nil)
        local success, entityId = player:AttemptToBuild(kTechId.Cyst, targetPoint, normal, nil, nil, nil, player)      
        cyst = Shared.GetEntity(entityId)
    end

    // Check if we should start out the model as connected or not
    local path = nil
    local cystParent, path = GetCystParentFromPoint(targetPoint, normal, player:GetTeamNumber())    
    if cyst and cystParent and path then    
        connected = true        
    end
    
    return cyst, connected
    
end

function Cyst:SetSighted(sighted)
    Structure.SetSighted(self, sighted)
    // propagate our sighedness to our infestation
    local infest = self:GetInfestation()
    if infest then 
        infest:SetSighted(sighted)
    end
end