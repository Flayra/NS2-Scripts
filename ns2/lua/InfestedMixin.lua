// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\InfestedMixin.lua    
//    
//    Created by:  Mats Olsson (mats.olsson@matsotech.se)   
//    
// Tracks infested state for entities. 
// Cooperates with the Infestation to update the infestation state of entities.
// Listens for changes in location for self, adding itself to the dirty table, which
// is cleaned out regularly. 
// In addition, an infestation that changes its radius will also cause all entities in the
// changed radius to be marked as dirty
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

InfestedMixin = { }
InfestedMixin.type = "Infested"


//
// Listen on the state that infested state depends on - ie where we are
//
InfestedMixin.expectedCallbacks = {
    SetOrigin = "Sets the location of an entity",
    SetCoords = "Sets both both location and angles",
}

// What entities have become dirty.
// Flushed in the UpdateServer hook by InfestedMixin.OnUpdateServer
InfestedMixin.dirtyTable = {}

//
// Call all dirty entities
//
function InfestedMixin.OnUpdateServer()
    PROFILE("InfestedMixin.OnUpdateServer")
    for entityId, _ in pairs(InfestedMixin.dirtyTable) do
        local entity = Shared.GetEntity(entityId)
        if entity then
            entity:UpdateInfestedState()
        end
    end
    InfestedMixin.dirtyTable = {}
end


//
// Intercept the functions that changes the state the mapblip depends on
//
function InfestedMixin:SetOrigin(origin)
    InfestedMixin.dirtyTable[self:GetId()] = true
end
function InfestedMixin:SetCoords(coords)
    InfestedMixin.dirtyTable[self:GetId()] = true
end

function InfestedMixin:__initmixin()

    assert(Client == nil)

end

function InfestedMixin:UpdateInfestedState()
    // could use GetEntitiesWithinRadius here, but we'll wait until we can set it up for
    // infestations. For now, use the InfestationMap
    //local prevInf = self:GetGameEffectMask(kGameEffect.OnInfestation)
    UpdateInfestationMask(self)
    //local nowInf = self:GetGameEffectMask(kGameEffect.OnInfestation)
    //if prevInf ~= nowInf then
    //    Log("%s: inf %s -> %s", self, prevInf, nowInf)
    //end
end

function InfestedMixin:InfestationNeedsUpdate()
    //Log("%s: inf update", self)
    InfestedMixin.dirtyTable[self:GetId()] = true  
end

Event.Hook("UpdateServer", InfestedMixin.OnUpdateServer)