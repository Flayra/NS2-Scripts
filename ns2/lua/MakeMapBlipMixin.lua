// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\MakeMapBlipMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

MakeMapBlipMixin = { }
MakeMapBlipMixin.type = "MakeMapBlip"

function MakeMapBlipMixin:__initmixin()

    assert(Client == nil)
    
    // Check if the new entity should have a map blip to represent it.
    local success, blipType, blipTeam = self:_GetMapBlipTypeAndTeam()
    if success then
        self:_CreateMapBlip(blipType, blipTeam)
    end

end

function MakeMapBlipMixin:_GetMapBlipTypeAndTeam()

    local success = false
    local blipType = 0
    local blipTeam = -1
    
    // Only consider ScriptActors.
    if not self:isa("ScriptActor") then
        return success, blipType, blipTeam
    end

    // World entities
    if self:isa("Door") then

        blipType = kMinimapBlipType.Door
        
    elseif self:isa("ResourcePoint") then

        blipType = kMinimapBlipType.ResourcePoint
    
    elseif self:isa("TechPoint") then
    
        blipType = kMinimapBlipType.TechPoint
        
    // Don't display PowerPoints unless they are in an unpowered state.
    elseif self:isa("PowerPoint") then
        
        // Important to have this statement inside the isa("PowerPoint") statement.
        if self:GetLightMode() == kLightMode.NoPower then
            blipType = kMinimapBlipType.PowerPoint
        end

    // Everything else that is supported by kMinimapBlipType.
    elseif self:GetIsVisible() then
    
        if kMinimapBlipType[self:GetClassName()] ~= nil then
            blipType = kMinimapBlipType[self:GetClassName()]
        end
        
        blipTeam = self:GetTeamNumber()
        
    end
    
    if blipType ~= 0 then
        
        success = true
        
    end

    return success, blipType, blipTeam
    
end
AddFunctionContract(MakeMapBlipMixin._GetMapBlipTypeAndTeam, { Arguments = { "Entity" }, Returns = { "boolean", "number", "number" } })

function MakeMapBlipMixin:_CreateMapBlip(blipType, blipTeam)

    local mapBlip = Server.CreateEntity(MapBlip.kMapName)
    mapBlip:SetOwner(self:GetId(), blipType, blipTeam)
    self.mapBlipId = mapBlip:GetId()
    
end
AddFunctionContract(MakeMapBlipMixin._CreateMapBlip, { Arguments = { "Entity", "number", "number" }, Returns = { } })

function MakeMapBlipMixin:OnDestroy()

    if self.mapBlipId and Shared.GetEntity(self.mapBlipId) then
        Server.DestroyEntity(Shared.GetEntity(self.mapBlipId))
        self.mapBlipId = nil
    end

end
AddFunctionContract(MakeMapBlipMixin.OnDestroy, { Arguments = { "Entity" }, Returns = { } })