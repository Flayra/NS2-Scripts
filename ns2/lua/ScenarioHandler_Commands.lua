//
// Console commands for ScenarioHandler
//
Script.Load("lua/ScenarioHandler.lua")

function HandleData(data)
    ScenarioHandler.instance:Load(data)
end

function OnCommandScenSave(client)
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        ScenarioHandler.instance:Save()
    end
end

function OnCommandScenLoad(client, name, url)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
    
        url = url or "http://www.matsotech.se/ns2scenarios"
        local urlString = url .. "/" .. name .. ".scn"
        Shared.Message("Loading " .. urlString)
        local loadFunction = function(data)
            ScenarioHandler.instance:Load(data)
            Shared.Message("... done loading " .. name .. "!")
        end
        Shared.GetWebpage(urlString, loadFunction)
        
    end
    
end

function OnCommandScenCheckpoint(client)
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        Shared.Message("Checkpoint scenario")
        ScenarioHandler.instance:Checkpoint()
    end
end


Event.Hook("Console_scensave",      OnCommandScenSave)
Event.Hook("Console_scenload",      OnCommandScenLoad)
Event.Hook("Console_scencp",        OnCommandScenCheckpoint)
