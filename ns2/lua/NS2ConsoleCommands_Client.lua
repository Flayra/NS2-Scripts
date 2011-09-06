// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Only loaded when game rules are set and propagated to client.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandSelectAndGoto(selectAndGotoMessage)

    local player = Client.GetLocalPlayer()
    if player and player:isa("Commander") then
    
        local entityId = ParseSelectAndGotoMessage(selectAndGotoMessage)
        player:SetSelection({entityId})
        
        local entity = Shared.GetEntity(entityId)
        if entity ~= nil then
        
            player:SetWorldScrollPosition(entity:GetOrigin().x, entity:GetOrigin().z)
            
        else
            Print("OnCommandSelectAndGoto() - Couldn't goto position of entity %d", entityId)
        end
        
    end
    
end

function OnCommandTakeDamageIndicator(damageIndicatorMessage)
    
    local player = Client.GetLocalPlayer()
    if player then
    
        local worldX, worldZ, damage = ParseTakeDamageIndicatorMessage(damageIndicatorMessage)
        player:AddTakeDamageIndicator(worldX, worldZ)
        
        // Shake the camera if this player supports it.
        if player.SetCameraShake ~= nil then
            // Direction not used right now.
            //local shakeDir = Vector(worldX, player:GetOrigin().y, worldZ) - player:GetOrigin()
            //shakeDir:Normalize()
            local amountScalar = damage / player:GetMaxHealth()
            player:SetCameraShake(amountScalar * Player.kDamageCameraShakeAmount, Player.kDamageCameraShakeSpeed, Player.kDamageCameraShakeTime)
        end
        
    end
    
end

local cameraShakeDoerTypes = { kDeathMessageIcon.RifleButt, kDeathMessageIcon.Axe, kDeathMessageIcon.Bite, kDeathMessageIcon.SwipeBlink, kDeathMessageIcon.StabBlink }
local disabledSoundEffectDoerTypes = { kDeathMessageIcon.Flamethrower }
function OnCommandGiveDamageIndicator(damageIndicatorMessage)

    local player = Client.GetLocalPlayer()
    if player then
    
        local damageAmount, doerType, targetIsPlayer, targetTeam = ParseGiveDamageIndicatorMessage(damageIndicatorMessage)
        
        player:AddGiveDamageIndicator(damageAmount)
        
        // Only play sound if the target is on the other team and the doer isn't marked as not playing this effect.
        if targetTeam == GetEnemyTeamNumber(player:GetTeamNumber()) and not table.contains(disabledSoundEffectDoerTypes, doerType) then
            player:TriggerEffects("give_damage")
        end
        
        // Shake the camera for melee attacks if the target is a player and this local player supports it.
        if targetIsPlayer and player.SetCameraShake ~= nil and table.contains(cameraShakeDoerTypes, doerType) then
            player:SetCameraShake(Player.kMeleeHitCameraShakeAmount, Player.kMeleeHitCameraShakeSpeed, Player.kMeleeHitCameraShakeTime)
        end
        
    end

end

function OnCommandHotgroup(number, hotgroupString)

    local player = Client.GetLocalPlayer()

    if player then
    
        // Read hotgroup number and list of entities (separated by _)
        local hotgroupNumber = tonumber(number)
        local entityList = {}    
        
        if(hotgroupString ~= nil) then 
       
            for currentInt in string.gmatch(hotgroupString, "[0-9]+") do 
            
                table.insert(entityList, tonumber(currentInt))
                
            end
            
        end
        
        player:SetHotgroup(hotgroupNumber, entityList)
        
    end
        
end

function OnCommandTraceReticle()
    if Shared.GetCheatsEnabled() then
        Print("Toggling tracereticle cheat.")        
        Client.GetLocalPlayer():ToggleTraceReticle()
    end
end

function OnCommandTestSentry()

    local player = Client.GetLocalPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        // Look for nearest sentry and have it show us what it sees
        local sentries = GetEntitiesForTeamWithinRange("Sentry", player:GetTeamNumber(), player:GetOrigin(), 20)    
        for index, sentry in ipairs(sentries) do
            
            local targets = GetEntitiesWithMixinWithinRange("Live", sentry:GetOrigin(), Sentry.kRange)
            for index, target in pairs(targets) do
            
                if sentry ~= target then
                    sentry:GetCanSeeEntity(target)
                end

            end
        end
        
    end
    
end

function OnCommandRandomDebug()

    if Shared.GetCheatsEnabled() then
        local newState = not gRandomDebugEnabled
        gRandomDebugEnabled = newState
    end
    
end

function OnCommandLocation(client)

    local player = Client.GetLocalPlayer()

    local locationName = player:GetLocationName()
    if(locationName ~= "") then
        Print("You are in \"%s\".", locationName)
    else
        Print("You are nowhere.")
    end
    
end

function OnCommandChangeGCSettingClient(settingName, newValue)

    if Shared.GetCheatsEnabled() then
    
        if settingName == "setpause" or settingName == "setstepmul" then
            Shared.Message("Changing client GC setting " .. settingName .. " to " .. tostring(newValue))
            collectgarbage(settingName, newValue)
        else
            Shared.Message(settingName .. " is not a valid setting")
        end
        
    end
    
end

Event.Hook("Console_hotgroup",              OnCommandHotgroup)
Event.Hook("Console_tracereticle",          OnCommandTraceReticle)
Event.Hook("Console_testsentry",            OnCommandTestSentry)
Event.Hook("Console_random_debug",          OnCommandRandomDebug)
Event.Hook("Console_location",              OnCommandLocation)
Event.Hook("Console_changegcsettingclient", OnCommandChangeGCSettingClient)

Client.HookNetworkMessage("SelectAndGoto",      OnCommandSelectAndGoto)
Client.HookNetworkMessage("TakeDamageIndicator",    OnCommandTakeDamageIndicator)
Client.HookNetworkMessage("GiveDamageIndicator",    OnCommandGiveDamageIndicator)