// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ArmsLab.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'ArmsLab' (Structure)
ArmsLab.kMapName = "armslab"

ArmsLab.kModelName = PrecacheAsset("models/marine/arms_lab/arms_lab.model")

function ArmsLab:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function ArmsLab:GetTechButtons(techId)

    return {    kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3, kTechId.CatPackTech,
                kTechId.Armor1, kTechId.Armor2, kTechId.Armor3, kTechId.None }

end

Shared.LinkClassToMap("ArmsLab", ArmsLab.kMapName, {})
