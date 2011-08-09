// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ReadyRoomPlayer.lua
//
//    Created by:   Brian Cronin (brainc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

/**
 * ReadyRoomPlayer is a simple Player class that adds the required Move type mixin
 * to Player. Player should not be instantiated directly.
 */
class 'ReadyRoomPlayer' (Player)

ReadyRoomPlayer.kMapName = "ready_room_player"

ReadyRoomPlayer.networkVars =
{
}

PrepareClassForMixin(ReadyRoomPlayer, GroundMoveMixin)
PrepareClassForMixin(ReadyRoomPlayer, CameraHolderMixin)

function ReadyRoomPlayer:OnInit()

    InitMixin(self, GroundMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CameraHolderMixin, { kFov = Player.kFov })
    
    Player.OnInit(self)

end

Shared.LinkClassToMap( "ReadyRoomPlayer", ReadyRoomPlayer.kMapName, ReadyRoomPlayer.networkVars )