// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\TargetMixin.lua    
//    
//    Created by:   Mats Olsson (mats.olsson@matsotech.se) 
//
// Things which can be targeted by AI units needs to mixin this class. 
// Simply notifies the TargetCache when they are created and deleted.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

TargetMixin = { }
TargetMixin.type = "Target"

function TargetMixin:__initmixin()
    TargetType.OnCreateEntity(self)
end

function TargetMixin:OnDestroy()
    TargetType.OnDestroyEntity(self)
end

