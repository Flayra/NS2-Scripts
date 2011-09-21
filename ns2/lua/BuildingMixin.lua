// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\BuildingMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

BuildingMixin = { }
BuildingMixin.type = "Building"

// Snap structures within this range to attach points.
BuildingMixin.kStructureSnapRadius = 4


function BuildingMixin:__initmixin()    
    
end

function BuildingMixin:EvalBuildIsLegal(techId, origin, builderEntity, pickVec)
    local legalBuildPosition = false
    local position = nil
    local attachEntity = nil

    if pickVec == nil then
    
        // When Drifters and MACs build, or untargeted build/buy actions, no pickVec. Trace from order point down to see
        // if they're trying to build on top of anything and if that's OK.
        local trace = Shared.TraceRay(Vector(origin.x, origin.y + .1, origin.z), Vector(origin.x, origin.y - .2, origin.z), PhysicsMask.CommanderBuild, EntityFilterOne(builderEntity))
        legalBuildPosition, position, attachEntity = GetIsBuildLegal(techId, trace.endPoint, BuildingMixin.kStructureSnapRadius, self:GetOwner(), builderEntity)

    else
    
        // Make sure entity is near enough to attach class if required (snap to it as well)
        local commander = self:GetOwner()
        if commander == nil then
            commander = self
        end
        legalBuildPosition, position, attachEntity = GetIsBuildLegal(techId, origin, BuildingMixin.kStructureSnapRadius, commander, builderEntity)
        
    end
    
    return legalBuildPosition, position, attachEntity
end

// Returns true or false, as well as the entity id of the new structure (or -1 if false)
// pickVec optional (for AI units). In those cases, builderEntity will be the entity doing the building.
function BuildingMixin:AttemptToBuild(techId, origin, normal, orientation, pickVec, buildTech, builderEntity, trace, owner)

    local legalBuildPosition = false
    local position = nil
    local attachEntity = nil
    
    legalBuildPosition, position, attachEntity = self:EvalBuildIsLegal(techId, origin, builderEntity, pickVec)
    
    if legalBuildPosition then
    
        local commander = self:GetOwner()
        if commander == nil then
            commander = self
        end
        
        if (owner ~= nil) then
            commander = owner
        end
        
        local newEnt = CreateEntityForCommander(techId, position, commander)
        
        if newEnt ~= nil then
        
            // Use attach entity orientation 
            if attachEntity then
                orientation = attachEntity:GetAngles().yaw
            end
            
            // If orientation yaw specified, set it
            if orientation then
                local angles = Angles(0, orientation, 0)
                local coords = BuildCoordsFromDirection(angles:GetCoords().zAxis, newEnt:GetOrigin())
                newEnt:SetCoords(coords)                
            else          
                // align it with the surface (normal)
                local coords = BuildCoords(normal, Vector.zAxis, newEnt:GetOrigin())
                newEnt:SetCoords(coords)
            end
            
            local isAlien = false
            if newEnt.GetIsAlienStructure then
                isalien = newEnt:GetIsAlienStructure()
            end
            
            newEnt:TriggerEffects("commander_create", {isalien = isAlien})
            
            self:TriggerEffects("commander_create_local")
            
            return true, newEnt:GetId()
                        
        end
        
    end
    
    return false, -1
            
end
