

//
// Console commands for TargetCache (in its own file to avoid duplicate registrations when hacking)
//

function OnCommandTcLog(client, onOrOff, prefix)
    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        local on = onOrOff == "on"
        if not on and onOrOff ~= "off" then
            Log("Usage: tcllog on|off <prefix>")
        else
            Log("%s", LogCtrl(prefix, on, Server.targetCache.logTable))
        end
    end
end

Event.Hook("Console_tclog",                 OnCommandTcLog)

