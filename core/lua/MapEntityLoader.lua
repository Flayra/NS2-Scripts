// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MapEntityLoader.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PlayerSpawn.lua")

local function ClientOnly()
    return Client ~= nil
end

local function ServerOnly()
    return Server ~= nil
end

local function ClientAndServer()
    return true
end

function LoadEntityFromValues(entity, values, initOnly)

    entity:SetOrigin(values.origin)
    entity:SetAngles(values.angles)

    // Copy all of the key values as fields on the entity.
    for key, value in pairs(values) do 
    
        if key ~= "origin" and key ~= "angles" then
            entity[key] = value
        end
        
    end
    
    if not initOnly then
    
        if entity.OnLoad then
            entity:OnLoad()
        end
        
    end
    
    if entity.OnInit then
        entity:OnInit()
    end
    
end
AddFunctionContract(LoadEntityFromValues, { Arguments = { "userdata", "table", "boolean" }, Returns = { } })

local loadTypes = { }


local function LoadLight(className, groupName, values)
            
    local renderLight = Client.CreateRenderLight()
    local coords = values.angles:GetCoords(values.origin)
    
    if className == "light_spot" then
    
        renderLight:SetType(RenderLight.Type_Spot)
        renderLight:SetOuterCone(values.outerAngle)
        renderLight:SetInnerCone(values.innerAngle)
        renderLight:SetCastsShadows(values.casts_shadows)
        renderLight:SetSpecular(values.specular or true)
        
        if values.shadow_fade_rate ~= nil then
            renderLight:SetShadowFadeRate(values.shadow_fade_rate)
        end
    
    elseif className == "light_point" then
    
        renderLight:SetType(RenderLight.Type_Point)
        renderLight:SetCastsShadows(values.casts_shadows)
        renderLight:SetSpecular(values.specular or true)

        if values.shadow_fade_rate ~= nil then
            renderLight:SetShadowFadeRate(values.shadow_fade_rate)
        end
        
    elseif className == "light_ambient" then
        
        renderLight:SetType(RenderLight.Type_AmbientVolume)
        
        renderLight:SetDirectionalColor(RenderLight.Direction_Right,    values.color_dir_right)
        renderLight:SetDirectionalColor(RenderLight.Direction_Left,     values.color_dir_left)
        renderLight:SetDirectionalColor(RenderLight.Direction_Up,       values.color_dir_up)
        renderLight:SetDirectionalColor(RenderLight.Direction_Down,     values.color_dir_down)
        renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  values.color_dir_forward)
        renderLight:SetDirectionalColor(RenderLight.Direction_Backward, values.color_dir_backward)
        
    end

    renderLight:SetCoords(coords)
    renderLight:SetRadius(values.distance)
    renderLight:SetIntensity(values.intensity)
    renderLight:SetColor(values.color)
    renderLight:SetGroup(groupName)
    renderLight.ignorePowergrid = values.ignorePowergrid
    
    if (values.atmospheric == true) then
        renderLight:SetAtmospheric( true )
    end
    
    // Save original values so we can alter and restore lights
    renderLight.originalIntensity = values.intensity
    renderLight.originalColor = values.color
    
    if (className == "light_ambient") then
    
        renderLight.originalRight = values.color_dir_right
        renderLight.originalLeft = values.color_dir_left
        renderLight.originalUp = values.color_dir_up
        renderLight.originalDown = values.color_dir_down
        renderLight.originalForward = values.color_dir_forward
        renderLight.originalBackward = values.color_dir_backward
        
    end
    
    if Client.lightList == nil then
        Client.lightList = { }
    end
    table.insert(Client.lightList, renderLight)
    
    return true
        
end
AddFunctionContract(LoadLight, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })

loadTypes["light_spot"] = { LoadAllowed = ClientOnly, LoadFunction = LoadLight }
loadTypes["light_point"] = { LoadAllowed = ClientOnly, LoadFunction = LoadLight }
loadTypes["light_ambient"] = { LoadAllowed = ClientOnly, LoadFunction = LoadLight }


local function LoadPlayerSpawn(className, groupName, values)

    local entity = PlayerSpawn()
    entity:OnCreate()
    LoadEntityFromValues(entity, values, false)
    
    if Server.playerSpawnList == nil then
        Server.playerSpawnList = { }
    end
    table.insert(Server.playerSpawnList, entity)
    
    return true
    
end
AddFunctionContract(LoadPlayerSpawn, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })

loadTypes[PlayerSpawn.kMapName] = { LoadAllowed = ServerOnly, LoadFunction = LoadPlayerSpawn }


/**
 * This will load common map entities for the Client, Server, or both.
 * Call LoadMapEntity() with the map name of the entity and the map values
 * and it will be loaded. Returns true on success.
 */
function LoadMapEntity(className, groupName, values)

    local loadData = loadTypes[className]
    if loadData and loadData.LoadAllowed() then
        return loadData.LoadFunction(className, groupName, values)
    end
    return false

end
AddFunctionContract(LoadMapEntity, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })