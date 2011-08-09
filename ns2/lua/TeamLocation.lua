// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TeamLocation.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'TeamLocation' (ScriptActor)

TeamLocation.kMapName = "team_location"

// Set as property in editor. Allows players to spawn at player_spawn entities within this distance of team location.
function TeamLocation:GetSpawnRadius()
    return tonumber(self.spawnRadius)
end

function TeamLocation:OnCreate()
    ScriptActor.OnCreate(self)
    self:SetIsVisible(false)
    self:SetUpdates(false)
end

Shared.LinkClassToMap("TeamLocation", TeamLocation.kMapName, {} )

