// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Cocoon.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Intermediate that a Drifter turns into before eventually growing into a structure.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'Cocoon' (Structure)

Cocoon.kMapName = "cocoon"

Cocoon.kModelName = PrecacheAsset("models/alien/cocoon/cocoon.model")

Cocoon.kHealth = 200
Cocoon.kArmor = 50

function Cocoon:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function Cocoon:OnInit()

    self:SetModel(Cocoon.kModelName)
    
    Structure.OnInit(self)
    
end

function Cocoon:GetIsAlienStructure()
    return true
end

Shared.LinkClassToMap("Cocoon", Cocoon.kMapName, {})
