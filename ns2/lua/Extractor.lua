// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Extractor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Marine resource extractor. Gathers resources when built on a nozzle.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ResourceTower.lua")

class 'Extractor' (ResourceTower)

Extractor.kMapName = "extractor"

Extractor.kModelName = PrecacheAsset("models/marine/extractor/extractor.model")

Shared.PrecacheModel(Extractor.kModelName)

function Extractor:GetRequiresPower()
    return true
end

function Extractor:OnResearchComplete(structure, researchId)

    local success = ResourceTower.OnResearchComplete(self, structure, researchId)
    
    if success and structure == self and researchId == kTechId.ExtractorUpgrade then
    
        self:SetUpgradeLevel(self:GetUpgradeLevel() + 1)
        
    end
    
    return success   
    
end

function Extractor:GetDamagedAlertId()
    return kTechId.MarineAlertExtractorUnderAttack
end


Shared.LinkClassToMap("Extractor", Extractor.kMapName, {})