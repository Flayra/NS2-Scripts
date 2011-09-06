// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gorge_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Gorge:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(SpitSpray.kMapName)
    self:GiveItem(HydraAbility.kMapName)
    self:GiveItem(CystAbility.kMapName)
    
    self:SetActiveWeapon(SpitSpray.kMapName)
    
end

function Gorge:OnGiveUpgrade(techId)
    if techId == kTechId.BileBomb then
        self:GiveItem(BileBomb.kMapName)
    end
    
end

// Create hydra from menu
function Gorge:AttemptToBuy(techIds)

    local techId = techIds[1]
    
    // Drop hydra
    if (techId == kTechId.Hydra) then    
    
        // Create hydra in front of us
        local playerViewPoint = self:GetEyePos()
        local hydraEndPoint = playerViewPoint + self:GetViewAngles():GetCoords().zAxis * 2
        local trace = Shared.TraceRay(playerViewPoint, hydraEndPoint, PhysicsMask.AllButPCs, EntityFilterOne(self))
        local hydraPosition = trace.endPoint
        
        local hydra = CreateEntity(LookupTechData(techId, kTechDataMapName), hydraPosition, self:GetTeamNumber())
        
        // Make sure there's room
        if(hydra:SpaceClearForEntity(hydraPosition)) then
        
            hydra:SetOwner(self)

            self:AddResources(-LookupTechData(techId, kTechDataCostKey))
                    
            self:TriggerEffects("gorge_create")
            
            self:SetActivityEnd(.6)

        else
        
            DestroyEntity(hydra)
            
        end
        
        return true
        
    else
    
        return Alien.AttemptToBuy(self, techIds)
        
    end
    
end


