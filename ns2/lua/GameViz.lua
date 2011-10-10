// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GameViz.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/NS2Utility.lua")

local classToGrid = BuildClassToGrid()
local heightmap = nil

local function GameVizGetHeightMap()

    if not heightmap then
    
        heightmap = HeightMap()   
        local heightmapFilename = string.format("maps/overviews/%s.hmp", Shared.GetMapName())
        
        if(not heightmap:Load(heightmapFilename)) then
        
            Shared.Message("PostGameViz: Couldn't load height map " .. heightmapFilename)
            heightmap = nil
            
        end

    end
    
    return heightmap

end

local function OutputLogMessage(msg, targetEntity, heightMap) 

    ASSERT(msg ~= nil)
    
    // Output all relevant entities, marking targetEntity as active
    local entData = ""
    local ents = GetEntitiesMatchAnyTypes({"Player", "Structure"})

    for index, ent in ipairs(ents) do    
    
        local blipIndexX, blipIndexY = GetSpriteGridByClass(SafeClassName(ent), classToGrid)
        local targetPos = ent:GetOrigin()
        local entityNormMapX = heightMap:GetMapX(targetPos.z)
        local entityNormMapY = heightMap:GetMapY(targetPos.x)
        local yaw = ent:GetAngles().yaw

        // GameViz:MsgName numEnts ents <icon index x, icon index y, entity world X, rotation><icon index x, icon index y, entity world X, rotation>,etc
        local activeEntity = (targetEntity ~= nil and (targetEntity:GetId() == ent:GetId()))
        entData = string.format("%s<%d, %d, %.2f, %.2f, %.2f, %s>", entData, blipIndexX, blipIndexY, entityNormMapX, entityNormMapY, yaw, ToString(activeEntity))
        
    end
    
    Print("GameViz:\"%s (time: %.2f)\" %d ents %s", ToString(msg), Shared.GetTime(), table.count(ents), entData)

end

// Output GameViz event log entry showing entity icon and position and message
function PostGameViz(msg, targetEntity)

    // Include this manually only
    /*
    local heightMap = GameVizGetHeightMap()
    
    if heightMap then

        OutputLogMessage(msg, targetEntity, heightMap)
       
    else
        Print("PostGameViz(): Couldn't get height map, ignoring \"%s\" message.", msg)
    end
    */
    
end 