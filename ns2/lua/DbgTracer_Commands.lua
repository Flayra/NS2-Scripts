
if Server then

function OnCommandTrace(client, traceName) 

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        local msg = nil
        if traceName then
            msg = Server.dbgTracer:Toggle(traceName)
        end
        Shared.Message(Server.dbgTracer:StatusMsg(msg))
    end
    
end

function OnCommandTraceDur(client, traceName, duration)

    if client == nil or Shared.GetCheatsEnabled() or Shared.GetDevMode() then
        local msg = null
        if traceName and duration then
            msg = Server.dbgTracer:SetDuration(traceName, tonumber(duration))
        end
        Shared.Message(Server.dbgTracer:StatusMsg(msg))
    end
    
end

function OnUpdateServer(deltaTime)
    Server.dbgTracer:OnUpdate(deltaTime)
end


Event.Hook("Console_trace",                 OnCommandTrace)
Event.Hook("Console_tracedur",              OnCommandTraceDur)
Event.Hook("UpdateServer",                  OnUpdateServer)

end

