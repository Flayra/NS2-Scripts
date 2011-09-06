// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PrototypeLab.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'PrototypeLab' (Structure)

PrototypeLab.kMapName = "prototypelab"

PrototypeLab.kModelName = PrecacheAsset("models/marine/prototype_module/prototype_module.model")

function PrototypeLab:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function PrototypeLab:OnInit()

    self:SetModel(PrototypeLab.kModelName)
    
    Structure.OnInit(self)
    
end

function PrototypeLab:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        return  {   kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
                    kTechId.None, kTechId.None, kTechId.None, kTechId.None }

    elseif techId == kTechId.kTechId.PrototypeLabUpgradesMenu then
    
        return {   kTechId.JetpackTech, kTechId.JetpackFuelTech, kTechId.JetpackArmorTech, kTechId.None,
                   kTechId.ExosuitTech, kTechId.ExoskeletonLockdownTech, kTechId.ExoskeletonUpgradeTech, kTechId.RootMenu }
        
    end
    
    return nil
    
end

function PrototypeLab:GetRequiresPower()
    return true
end

Shared.LinkClassToMap("PrototypeLab", PrototypeLab.kMapName, {})

