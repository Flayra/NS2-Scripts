// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\HiveSightBlipMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com) 
//    Modified by: Mats Olsson (mats.olsson@matsotech.se)   
//    
// Tracks creation and updates of any hivesight blips for units that may have one. 
//
// Similar to MapBlipMixin, but the alien hivesight blips are rarer than MapBlips,
// so instead of always having them around, we delete them when they are no longer
// visible. 
//
// Listens to OnGameEffectMaskChanged (to check parasite status) and SetCoords/SetOrigin
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================    


HiveSightBlipMixin = { }
HiveSightBlipMixin.type = "HiveSightBlip"

//
// Listen on the state that the mapblip depends on
//
HiveSightBlipMixin.expectedCallbacks =
{
    SetOrigin = "Sets the location of an entity",
    SetCoords = "Sets the location/angles of an entity"
}

// What entities have become dirty.
// Flushed in the UpdateServer hook by HiveSightBlipMixin.OnUpdateServer
local HiveSightBlipMixinDirtyTable = { }

// for entities that have reported themselves as being under attack
local HiveSightBlipMixinUnderAttackTable = { }

//
// Call all dirty mapblips
//
local function HiveSightBlipMixinOnUpdateServer()

    PROFILE("HiveSightBlipMixinOnUpdateServer")
    
    for entityId, _ in pairs(HiveSightBlipMixinDirtyTable) do
    
        local entity = Shared.GetEntity(entityId)
        if entity then
            entity:_UpdateHiveSightBlip()
        end
        
    end
    
    HiveSightBlipMixinDirtyTable = { }
    
    // update any timeout blips
    local now = Shared.GetTime()
    if HiveSightBlipMixin.nextUnderAttackCheck and now > HiveSightBlipMixin.nextUnderAttackCheck then
    
        local entitiesInTable = false
        for entityId, _ in pairs(HiveSightBlipMixinUnderAttackTable) do
        
            local entity = Shared.GetEntity(entityId)
            HiveSightBlipMixinUnderAttackTable[entityId] = nil

            if entity then
            
                entity:_UpdateHiveSightBlip()
                entitiesInTable = true
                
            end
            
        end
        
        // clear the nextUnderAttack check if 
        HiveSightBlipMixin.nextUnderAttackCheck = entitiesInTable and (now + 1) or nil
        
    end
    
end

function HiveSightBlipMixin:__initmixin()

    assert(Client == nil)

    HiveSightBlipMixinDirtyTable[self:GetId()] = true
    
end

//
// Intercept the functions that changes the state the mapblip depends on
//
function HiveSightBlipMixin:SetOrigin()
    HiveSightBlipMixinDirtyTable[self:GetId()] = true
end

function HiveSightBlipMixin:SetCoords()
    HiveSightBlipMixinDirtyTable[self:GetId()] = true
end

function HiveSightBlipMixin:OnGameEffectMaskChanged(effect, enabled)

    // We are only interested in Parasited and OnInfestation bit, and only if we belong to the marine team
    if self:GetTeamNumber() == kMarineTeamType then
    
        local affected = bit.band(effect, bit.bor(kGameEffect.Parasite, kGameEffect.OnInfestation)) and enabled
        if self.hiveSightEffectMask ~= affected then
            self.hiveSightEffectMask = affected
            HiveSightBlipMixinDirtyTable[self:GetId()] = true
        end
        
    end
    
end

function HiveSightBlipMixin:OnTakeDamage()
    HiveSightBlipMixinDirtyTable[self:GetId()] = true
end

function HiveSightBlipMixin:OnSighted(sighted)

    // only interested if a marine team has its sighted status changed
    if self:GetTeamNumber() == kMarineTeamType and self.hiveSightSighted ~= sighted then
    
        self.hiveSightSighted = sighted
        HiveSightBlipMixinDirtyTable[self:GetId()] = true
        
    end
    
end

// Returns blipType if we should add a hive sight blip for this entity.
// Returns kBlipType.Undefined if we shouldn't add one right now.
// Returns kBlipType.Never if there is never a chance that this entity will have a hive sight blip
function HiveSightBlipMixin:GetBlipType()

    local blipType = kBlipType.Undefined
            
    local damageTime = self:GetTimeOfLastDamage()

    local underAttack = damageTime and (Shared.GetTime() < (damageTime + kHiveSightDamageTime)) 
    
    if self:GetIsVisible() and self:GetIsAlive() then
   
       if self:GetTeamNumber() == kAlienTeamType then
        
            blipType = kBlipType.Friendly
            
            // If it's a hive or harvester, add special icon to show how important it is
            if self:isa("Hive") or self:isa("Harvester") then
                blipType = kBlipType.TechPointStructure
            end

            if underAttack then
                blipType = kBlipType.FriendlyUnderAttack  // Draw blip as under attack               
            end
            
        elseif self:GetTeamNumber() ~= kAlienTeamType and (self.sighted or self:GetGameEffectMask(kGameEffect.Parasite) or self:GetGameEffectMask(kGameEffect.OnInfestation)) then
            blipType = kBlipType.Sighted
        end
        
        // Only send other structures if they are under attack or parasited
        if ((blipType == kBlipType.Sighted) or (blipType == kBlipType.Friendly)) and self:isa("Structure") and (not underAttack) and not self:GetGameEffectMask(kGameEffect.Parasite) then
            blipType = kBlipType.Undefined
        end

    end

    return blipType, underAttack
    
end

//
// Called when something may change the hiveSightStatus of this entity
//
function HiveSightBlipMixin:_UpdateHiveSightBlip()

    local blip = self.hiveSightBlipId and Shared.GetEntity(self.hiveSightBlipId)
    local type, underAttack = self:GetBlipType()

    if type == kBlipType.Undefined then
    
        if blip then
        
            DestroyEntity(blip)
            self.hiveSightBlipId = nil
            
        end
        
    else
    
        if not blip then
        
            blip = CreateEntity(Blip.kMapName)
            self.hiveSightBlipId = blip:GetId()
            
        end
        
        blip:Update(self, type)
        
        // mark it as in need of refresh
        if underAttack then
        
            HiveSightBlipMixinUnderAttackTable[self:GetId()] = true
            HiveSightBlipMixin.nextUnderAttackCheck = HiveSightBlipMixin.nextUnderAttackCheck or (Shared.GetTime() + 1)
            
        end
        
    end
    
end

function HiveSightBlipMixin:OnDestroy()

    if self.hiveSightBlipId and Shared.GetEntity(self.hiveSightBlipId) then
    
        Server.DestroyEntity(Shared.GetEntity(self.hiveSightBlipId))
        self.hiveSightBlipId = nil
        
    end

end

Event.Hook("UpdateServer", HiveSightBlipMixinOnUpdateServer)