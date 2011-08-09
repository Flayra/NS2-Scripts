// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LOSMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

LOSMixin = { }
LOSMixin.type = "LOS"
LOSMixin.kMinLOSRange = 5

LOSMixin.kUnitMaxLOSDistance = 30
LOSMixin.kUnitMinLOSDistance = 1.5
LOSMixin.kStructureMinLOSDistance = 10

function LOSMixin.__prepareclass(toClass)
    ASSERT(toClass.networkVars ~= nil, "LOSMixin expects the class to have network fields")    
    
    local addNetworkFields =
    {
         // Whether this entity is in sight of the enemy team
        sighted                     = "boolean",
        
        // Whether we should do a LOS check for this unit
        updateLOS                   = "boolean",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end    
    
end

function LOSMixin:__initmixin()
   self.sighted = false
   self.updateLOS = true
   
   self.LOSList = {}
end

function LOSMixin:Reset()
  table.clear(self.LOSList)
  self.updateLost = true
end

function LOSMixin:GetLOSRange()
  local range = LOSMixin.kStructureMinLOSDistance
  
  if (self.OverrideLOSRange) then
    range = self:OverrideLOSRange()
  end
  
  return range
end

function LOSMixin:GetIsSighted()
  return self.sighted
end

function LOSMixin:SetIsSighted(sighted)
  self.sighted = sighted 
end

function LOSMixin:GetProvidesLOS()

  local isAlien = (self:GetTeamType() ~= kMarineTeamType) 
  
  // Get all non-commander players on our team
  local teamBuilderName = ConditionalValue(isAlien, "Drifter", "MAC")
  
  // Scan entities are structures
  if( (self:isa("Player") and not self:GetIsCommander()) or 
      (self:isa(teamBuilderName)) or 
      (self:isa("Structure") and not self:isa("PowerPoint") and not self:isa("Door") and not self:isa("Egg")) or 
      (self:isa("ARC")) ) then            
        return true                
  end
  
  return false
end

function LOSMixin:SetUpdateLOS(update)
  self.updateLOS = update
end

function LOSMixin:GetUpdateLOS()
  return self.updateLOS
end

function LOSMixin:GetEntitesWithinRange(range, outEntities)
  Shared.GetEntitiesWithinRadius(self:GetOrigin(), range, outEntities)  
end

function LOSMixin:GetLOSEntites()
  return self.LOSList
end

function LOSMixin:AddLOSEntity(entityId)
  Print("adding ent")
  table.insert(self.LOSList, entityId)
end

function LOSMixin:RemoveLOSEntity(entityId)
  table.removevalue(self.LOSList, entityId)
end

function LOSMixin:GetHasLOS(entityId)
  return table.contains(self.LOSList, entityId)
end

function LOSMixin:UpdateLOS()
    PROFILE("LOSMixin:UpdateLOS()")
   // If we do not need to update out LOS because we have not moved or something
   // then we can just bail out here.
   if (not self:GetUpdateLOS() or not self:GetProvidesLOS()) then
    // Print("Not updating %s", EntityToString(self))
     return 
   end      
   
   local enemyTeamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
   local losEnts = {}
   self:GetEntitesWithinRange(self:GetLOSRange(), losEnts)
   for index, entityId in ipairs(losEnts) do
     if not (self:GetHasLOS(entityId)) then
        local entity = Shared.GetEntity(entityId)       
        if (entity ~= nil) then
            // For each visible entity on other team
            if not entity:GetIsVisible() then
                entity:SetExcludeRelevancyMask( 0 )      
            end 
            
            local wasAdded = false
            
            // If this unit sees us then its very likely
            // we see them
            if (entity:GetHasLOS(self:GetId())) then
              self:AddLOSEntity(entityId)
              wasAdded = true
            else
              
              if self:isa("Structure") and self:GetIsActive() and (entity:isa("Structure") or entity:isa("Infestation"))then                
                // Check to make sure view isn't blocked by the level or big visible entities (add in a little height in case infestation is on ground)
                local trace = Shared.TraceRay(self:GetModelOrigin(), entity:GetModelOrigin() + Vector(0, 1, 0), PhysicsMask.AllButPCs, EntityFilterTwo(self, entity))                
                if trace.fraction == 1 then                     
                    self:AddLOSEntity(entityId)
                    wasAdded = true
                end
              elseif self:isa("Scan")then                     
                self:AddLOSEntity(entityId)
                wasAdded = true
              elseif(not self:isa("Structure") ) then                                      
                if( self:GetCanSeeEntity(entity) ) then
                    self:AddLOSEntity(entityId)
                    wasAdded = true
                end
              end                                   
            end
           // Print("%s am adding a %s %s", EntityToString(self), EntityToString(entity), ToString(wasAdded))
            entity:SetIsSighted(wasAdded)
              
            if (wasAdded) then                
              entity:AddLOSEntity(self:GetId())                
            end
        end        
     end
   end
   
end