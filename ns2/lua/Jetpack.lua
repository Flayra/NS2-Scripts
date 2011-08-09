// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Axe.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")

class 'Jetpack' (ScriptActor)

Jetpack.kMapName = "jetpack"

Jetpack.kAttachPoint = "JetPack"
Jetpack.kPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_jetpack")
Jetpack.kModelName = PrecacheAsset("models/marine/jetpack/jetpack.model")

function Jetpack:OnInit()

    ScriptActor.OnInit(self)
    
    self:SetModel(Jetpack.kModelName)      
    
end

function Jetpack:OnTouch(player)

    if( player:GetTeamNumber() == self:GetTeamNumber() ) then

        player:PlaySound(Jetpack.kPickupSound)
        
        self:SetParent(player)
        
        // Attach weapon to parent's back
        self:SetAttachPoint(Jetpack.kAttachPoint)
        
        player.hasJetpack = true
        
    end
    
end

Shared.LinkClassToMap("Jetpack", Jetpack.kMapName, {})