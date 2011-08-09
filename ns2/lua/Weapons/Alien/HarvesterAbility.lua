// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\HarvesterAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'HarvesterAbility' (Ability)

HarvesterAbility.kMapName = "harvesterability"

HarvesterAbility.kCreateStartSound = PrecacheAsset("sound/ns2.fev/alien/gorge/create_structure_start")

HarvesterAbility.kCreateEffect = PrecacheAsset("cinematics/alien/gorge/create.cinematic")
HarvesterAbility.kCreateViewEffect = PrecacheAsset("cinematics/alien/gorge/create_view.cinematic")

// Gorge create harvester
HarvesterAbility.kAnimHarvesterAttack = "chamber_attack"

HarvesterAbility.kPlacementDistance = 1.5

local networkVars = 
{
    // When true, show ghost harvester (on deploy and after attacking)
    showGhost               = "boolean",
    healthSprayPoseParam    = "compensated float",
    chamberPoseParam        = "compensated float"
}

function HarvesterAbility:OnInit()
    Ability.OnInit(self)
    self.showGhost = false
    self.healthSprayPoseParam = 0
    self.chamberPoseParam = 0
end

function HarvesterAbility:OnDraw(player, prevWeapon)

    Ability.OnDraw(self, player, prevWeapon)
    
    // Show ghost when switch to this weapon
    self.showGhost = true
    
end

function HarvesterAbility:GetEnergyCost(player)
    return 0
end

function HarvesterAbility:GetPrimaryAttackDelay()
    return 1.0
end

function HarvesterAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

// Drop harvester
function HarvesterAbility:PerformPrimaryAttack(player)

    if not self.showGhost then

        // Show ghost if not doing so
        self.showGhost = true
        
        player:SetActivityEnd(.1)
        
    else

        local coords, valid = self:GetPositionForHarvester(player)
        
        if valid then
        
            // If we have enough resources
            local cost = LookupTechData(kTechId.Harvester, kTechDataCostKey)
            if player:GetResources() >= cost then
        
                Shared.PlaySound(player, HarvesterAbility.kCreateStartSound)
                
                player:SetViewAnimation(HarvesterAbility.kAnimHarvesterAttack)
                player:SetActivityEnd(self:GetPrimaryAttackDelay())
                               
                if Client then
                    self:CreateWeaponEffect(player, "", "HydraSpray", HarvesterAbility.kCreateViewEffect)
                else
                    player:CreateAttachedEffect(HarvesterAbility.kCreateEffect, "Head")
                end
                
                // Create structure on animation complete
                player:SetAnimAndMode(Gorge.kCreateStructure, kPlayerMode.GorgeStructure)
                
                // Don't show ghost any longer until we attack again
                self.showGhost = false
                
            else
                Shared.PlayPrivateSound(player, player:GetNotEnoughResourcesSound(), player, 1.0, Vector(0, 0, 0))
            end
            
        else
        
            Shared.PlayPrivateSound(player, Player.kInvalidSound, player, 1.0, Vector(0, 0, 0))
        
        end    
        
    end
    
    return true
    
end

function HarvesterAbility:CreateHarvester(player)

    // If team has enough resources
    if Server then
    
        local coords, valid = self:GetPositionForHarvester(player)
    
        local team = self:GetTeam()
        local cost = LookupTechData(kTechId.Harvester, kTechDataCostKey)
        if valid and (team:GetTeamResources() >= cost) then
        
            // Get resource point
            local origin, resourcePoint = self:GetResourcePoint(player)
            if resourcePoint ~= nil then

                // Create structure
                local harvester = CreateEntity( Harvester.kMapName, origin, player:GetTeamNumber() )
                harvester:SetOwner(player)
                
                if harvester:SpaceClearForEntity(origin) then
                
                    harvester:SetAngles(resourcePoint:GetAngles())
                    
                    // Attach to resource point
                    harvester:SetAttached(resourcePoint)
                    
                    team:AddTeamResources( -cost )
                    
                    // Trigger alert for Commander 
                    team:TriggerAlert(kTechId.AlienAlertGorgeBuiltHarvester, harvester)
                    
                else
                    DestroyEntity(harvester)
                end
                
            end
            
        end
        
    end
    
end

function HarvesterAbility:GetHUDSlot()
    return 2
end

// Returns point from which it looks for a resource point (or the point that the harvester will be created), along with an unoccupied resource point, if any
function HarvesterAbility:GetResourcePoint(player)

    local playerZAxis = Vector(player:GetViewAngles():GetCoords().zAxis)
    local horizontalView = GetNormalizedVector(Vector(playerZAxis.x, 0, playerZAxis.z))
    local origin = player:GetOrigin() + horizontalView * HarvesterAbility.kPlacementDistance
    
    // Look for nearest unoccupied resource nozzle near this point
    local resourcePoints = GetEntitiesWithinRange("ResourcePoint", origin, 2)
    for index, resourcePoint in ipairs(resourcePoints) do
    
        if resourcePoint:GetAttached() == nil then
        
            return Vector(resourcePoint:GetOrigin()), resourcePoint
            
        end
        
    end
    
    return origin, nil

end

// Given a gorge player's position and view angles, return a position and orientation
// for a harvester. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function HarvesterAbility:GetPositionForHarvester(player)

    local validPosition = false
    local drawHarvester = true
    
    local harvesterFacing = Vector(player:GetViewAngles():GetCoords().xAxis)
    
    // Look for nearest unoccupied resource nozzle near this point
    local displayOrigin, resourcePoint = self:GetResourcePoint(player)
    if resourcePoint ~= nil then
    
        VectorCopy(resourcePoint:GetAngles():GetCoords().zAxis, harvesterFacing)        
        validPosition = true
        
    end
    
    return BuildCoords(Vector(0, 1, 0), harvesterFacing, displayOrigin), validPosition

end

function HarvesterAbility:OnSecondaryAttack(player)
    // Make ghost disappear
    self.showGhost = false
end

if Client then
function HarvesterAbility:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    if not Shared.GetIsRunningPrediction() then

        local player = self:GetParent()
        
        if player == Client.GetLocalPlayer() and player:GetActiveWeapon() == self then
        
            // Create ghost
            if not self.ghostHarvester and self.showGhost then
            
                self.ghostHarvester = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.ghostHarvester:SetModel( Shared.GetModelIndex(Harvester.kModelName) )
                
            end
            
            // Destroy ghost
            if self.ghostHarvester and not self.showGhost then
                self:DestroyGhost()
            end
            
            // Update ghost position 
            if self.ghostHarvester then
            
                local coords, valid = self:GetPositionForHarvester(player)
                
                self.ghostHarvester:SetCoords(coords)
                
                // Check resources
                if player:GetResources() < LookupTechData(kTechId.Harvester, kTechDataCostKey) then
                
                    valid = false
                    
                end
                
            end
          
        end
        
    end
    
end

function HarvesterAbility:DestroyGhost()

    if Client then
    
        if self.ghostHarvester ~= nil then
        
            Client.DestroyRenderModel(self.ghostHarvester)
            self.ghostHarvester = nil
            
        end
        
    end
    
end

function HarvesterAbility:OnDestroy()
    self:DestroyGhost()
    Ability.OnDestroy(self)
end

function HarvesterAbility:OnHolster(player)
    self:DestroyGhost()
    Ability.OnHolster(self, player)
end

end

function HarvesterAbility:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)

    // Move away from health spray
    self.healthSprayPoseParam = Clamp(Slerp(self.healthSprayPoseParam, 0, .5 * input.time), 0, 1)
    viewModel:SetPoseParam("health_spray", self.healthSprayPoseParam)
    
    // Move away from chamber 
    self.chamberPoseParam = Clamp(Slerp(self.chamberPoseParam, 0, .5 * input.time), 0, 1)
    viewModel:SetPoseParam("chamber", self.chamberPoseParam)
    
end

Shared.LinkClassToMap("HarvesterAbility", HarvesterAbility.kMapName, networkVars )
