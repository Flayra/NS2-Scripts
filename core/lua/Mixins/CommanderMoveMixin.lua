// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CommanderMoveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")

CommanderMoveMixin = { }
CommanderMoveMixin.type = "MoveChild"

CommanderMoveMixin.expectedCallbacks = {
    GetHeightmap = "",
    ProcessNumberKeysMove = "",
    SetOrigin = "",
    GetViewAngles = "Returns the current view angles" }

CommanderMoveMixin.optionalCallbacks = { }

CommanderMoveMixin.expectedConstants = {
    kScrollVelocity = "How quickly scroll moves the player",
    kDefaultHeight = "The default height the heightmap provides an offset for.",
    kViewOffsetXHeight = "Extra hard-coded vertical distance that makes it so we set our scroll position, we are looking at that point, instead of setting our position to that point." }

function CommanderMoveMixin.__prepareclass(toClass)

    PrepareClassForMixin(toClass, BaseMoveMixin)
    
end

function CommanderMoveMixin:__initmixin()

    InitMixin(self, BaseMoveMixin)
    
end

// Update origin and velocity from input.
function CommanderMoveMixin:UpdateMove(input)

    local finalPos = Vector()
    
    local heightmap = self:GetHeightmap()
    // If minimap clicked, go right to that position
    if (bit.band(input.commands, Move.Minimap) ~= 0) then

        // Translate from panel coords to world coordinates described by minimap
        if(heightmap ~= nil) then
            
            // Store normalized minimap coords in yaw and pitch
            finalPos = Vector(heightmap:GetWorldX(input.pitch), 0, heightmap:GetWorldZ(input.yaw))
            
            // Add in extra x offset to center view where we're told, not ourselves
            finalPos.x = finalPos.x - self:GetMixinConstants().kViewOffsetXHeight
            
        end

        self.gotoHotKeyGroup = 0
        
    // Returns true if player jumped to a hotkey group
    elseif not self:ProcessNumberKeysMove(input, finalPos) then
    
        local angles = self:GetViewAngles()
        local moveVelocity = angles:GetCoords():TransformVector( input.move ) * self:GetMixinConstants().kScrollVelocity
        
        // Set final position (no collision)
        finalPos = self:GetOrigin() + moveVelocity * input.time
        
        if input.move:GetLength() > kEpsilon then
            self.gotoHotKeyGroup = 0
        end
        
    end
    
    // Set commander height according to height map (allows commander to move off height map, but uses clipped values to determine height)
    if(heightmap ~= nil) then
    
        finalPos.x = heightmap:ClampXToMapBounds(finalPos.x)
        finalPos.z = heightmap:ClampZToMapBounds(finalPos.z)
        finalPos.y = heightmap:GetElevation(finalPos.x, finalPos.z) + self:GetMixinConstants().kDefaultHeight

    else
    
        // If there's no height map, trace to the ground and hover a set distance above it 
        // Doesn't update height if nothing was hit
        local belowComm = Vector(self:GetOrigin())
        belowComm.y = belowComm.y - 50
        
        local trace = Shared.TraceRay(self:GetOrigin(), belowComm, PhysicsMask.CommanderSelect, EntityFilterOne(self))
        
        if trace.fraction < 1 then
            finalPos.y = trace.endPoint.y + Commander.kDefaultCommanderHeight
        end
        
    end

    self:SetOrigin(finalPos)

end
AddFunctionContract(CommanderMoveMixin.UpdateMove, { Arguments = { "Entity", "Move" }, Returns = { } })