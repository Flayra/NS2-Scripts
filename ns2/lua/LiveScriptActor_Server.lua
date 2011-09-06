// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\LiveScriptActor_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function LiveScriptActor:SetPathingEnabled(state)
    self.pathingEnabled = state
end

function LiveScriptActor:SetFuryLevel(level)
    self.furyLevel = level
end

// If false, then MoveToTarget() projects entity down to floor
function LiveScriptActor:GetIsFlying()
    return false
end