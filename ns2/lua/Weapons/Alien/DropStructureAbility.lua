// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\DropStructureAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'DropStructureAbility' (Ability)

DropStructureAbility.kMapName = "drop_structure_ability"

DropStructureAbility.kCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")

DropStructureAbility.kPlacementDistance = 1.1

DropStructureAbility.networkVars = 
{
    // When true, show ghost (on deploy and after attacking)
    showGhost               = "boolean",
    healthSprayPoseParam    = "compensated float",
    chamberPoseParam        = "compensated float"
}

function DropStructureAbility:OnInit()
    Ability.OnInit(self)
    self.showGhost = false
    self.healthSprayPoseParam = 0
    self.chamberPoseParam = 0
end

function DropStructureAbility:OnDraw(player, prevWeapon)

    Ability.OnDraw(self, player, prevWeapon)
    self.showGhost = true
    
end

// Child should override
function DropStructureAbility:GetEnergyCost(player)
    ASSERT(false)
end

// Child should override
function DropStructureAbility:GetPrimaryAttackDelay()
    ASSERT(false)
end

// Child should override
function DropStructureAbility:GetIconOffsetY(secondary)
    ASSERT(false)
end

// Child should override
function DropStructureAbility:GetDropStructureId()
    ASSERT(false)
end

// Child should override ("hydra", "cyst", etc.). 
function DropStructureAbility:GetSuffixName()
    ASSERT(false)
end

// Child should override ("Hydra")
function DropStructureAbility:GetDropClassName()
    ASSERT(false)
end

// Child should override 
function DropStructureAbility:GetDropMapName()
    ASSERT(false)
end

// Child should override 
function DropStructureAbility:GetHUDSlot()
    ASSERT(false)
end

// Check before energy is spent if a Hydra can be built in the current location.
function DropStructureAbility:OnPrimaryAttack(player)

    // Ensure the current location is valid for placement.
    local coords, valid = self:GetPositionForStructure(player)
    if valid then
        // Ensure they have enough resources.
        local cost = GetCostForTech(self:GetDropStructureId())
        if player:GetResources() >= cost then
            Ability.OnPrimaryAttack(self, player)
        else
            player:AddTooltip(string.format("Not enough resources to create %s.", self:GetDropClassName()))
        end
    else
        player:AddTooltip(string.format("Could not place %s in that location.", self:GetDropClassName()))
    end
    
end

// Create structure
function DropStructureAbility:PerformPrimaryAttack(player)
    local success = true
    // Make ghost disappear
    if self.showGhost then
    
        player:TriggerEffects("start_create_" .. self:GetSuffixName())
    
        player:SetAnimAndMode(Gorge.kCreateStructure, kPlayerMode.GorgeStructure)
            
        player:SetActivityEnd(player:AdjustAttackDelay(self:GetPrimaryAttackDelay()))
        success = self:DropStructure(player)
    end
    
    return success
    
end

function DropStructureAbility:DropStructure(player)

    // If we have enough resources
    if Server then
    
        local coords, valid = self:GetPositionForStructure(player)
    
        local cost = LookupTechData(self:GetDropStructureId(), kTechDataCostKey)
        if valid and (player:GetResources() >= cost) then
        
            // Create structure
            local structure = self:CreateStructure(coords, player)
            if structure then
            
                structure:SetOwner(player)
                
                // Check for space
                if structure:SpaceClearForEntity(coords.origin) then
                
                    local angles = Angles()
                    angles:BuildFromCoords(coords)
                    structure:SetAngles(angles)
                    
                    player:TriggerEffects("create_" .. self:GetSuffixName())
                    
                    player:AddResources( -cost )
                    
                    player:SetActivityEnd(.5)
                    
                    // Jackpot
                    return true                    
                else
                    
                    player:AddTooltip(string.format("Not enough space for %s in that location.", self:GetDropClassName()))
                    DestroyEntity(structure)            
                end

            else
                player:AddTooltip(string.format("Create %s failed.", self:GetDropClassName()))                
            end            
            
        else        
            if not valid then
                player:AddTooltip(string.format("Could not place %s in that location.", self:GetDropClassName()))
            else
                player:AddTooltip(string.format("Not enough resources to create %s.", self:GetDropClassName()))
            end                        
        end
        
    end
    
    return false
    
end

function DropStructureAbility:CreateStructure(coords, player)
    return CreateEntity( self:GetDropMapName(), coords.origin, player:GetTeamNumber() )
end

// Given a gorge player's position and view angles, return a position and orientation
// for structure. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function DropStructureAbility:GetPositionForStructure(player)

    local validPosition = false
    
    local origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * DropStructureAbility.kPlacementDistance

    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * DropStructureAbility.kPlacementDistance
        trace = Shared.TraceRay(origin, origin - Vector(0, DropStructureAbility.kPlacementDistance, 0), PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end
    
    // If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
    
        if trace.entity == nil then
            validPosition = true
        elseif trace.entity:isa("Infestation") or (not trace.entity:isa("ScriptActor") and not trace.entity:isa(self:GetDropClassName())) then
            validPosition = true
        end
        
        displayOrigin = trace.endPoint
        
    end
    
    // Can only be built on infestation
    local requiresInfestation = LookupTechData(self:GetDropStructureId(), kTechDataRequiresInfestation)
    if requiresInfestation and not GetIsPointOnInfestation(displayOrigin) then
        validPosition = false
    end
    
    // Don't allow placing above or below us and don't draw either
    local structureFacing = player:GetViewAngles():GetCoords().zAxis
    local coords = BuildCoords(trace.normal, structureFacing, displayOrigin)    
    
    return coords, validPosition

end

function DropStructureAbility:GetGhostModelName()
    return LookupTechData(self:GetDropStructureId(), kTechDataModel)
end

if Client then
function DropStructureAbility:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    if not Shared.GetIsRunningPrediction() then

        local player = self:GetParent()
        
        if player == Client.GetLocalPlayer() and player:GetActiveWeapon() == self then
        
            // Show ghost if we're able to create structure
            self.showGhost = player:GetCanNewActivityStart()
            
            // Create ghost
            if not self.ghostStructure and self.showGhost then
            
                self.ghostStructure = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.ghostStructure:SetCastsShadows(false)
                
                // Create build circle to show hydra range
                self.circle = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.circle:SetModel( Shared.GetModelIndex(DropStructureAbility.kCircleModelName) )
                
            end

            // Update ghost model every frame in case it changes
            if self.ghostStructure then
                local modelName = self:GetGhostModelName()
                self.ghostStructure:SetModel( Shared.GetModelIndex(modelName) )
            end
            
            // Destroy ghost
            if self.ghostStructure and not self.showGhost then
                self:DestroyStructureGhost()
            end
            
            // Update ghost position 
            if self.ghostStructure then
            
                local coords, valid = self:GetPositionForStructure(player)
                
                if valid then
                    self.ghostStructure:SetCoords(coords)
                end
                self.ghostStructure:SetIsVisible(valid)
                
                // Check resources
                if player:GetResources() < LookupTechData(self:GetDropStructureId(), kTechDataCostKey) then
                
                    valid = false
                    
                end
                
                // Scale and position circle to show range
                if self.circle then
                
                    local coords = BuildCoords(Vector(0, 1, 0), Vector(1, 0, 0), coords.origin + Vector(0, .01, 0), 2 * Hydra.kRange)
                    self.circle:SetCoords(coords)
                    self.circle:SetIsVisible(valid)
                    
                end
                
                // TODO: Set color of structure according to validity
                
            end
          
        end
        
    end
    
end

function DropStructureAbility:DestroyStructureGhost()

    if Client then
    
        if self.ghostStructure ~= nil then
        
            Client.DestroyRenderModel(self.ghostStructure)
            self.ghostStructure = nil
            
        end
        
        if self.circle ~= nil then
        
            Client.DestroyRenderModel(self.circle)
            self.circle = nil
            
        end
        
    end
    
end

function DropStructureAbility:OnDestroy()
    self:DestroyStructureGhost()
    Ability.OnDestroy(self)
end

function DropStructureAbility:OnHolster(player)
    Ability.OnHolster(self, player)
    self:DestroyStructureGhost()
end

end

function DropStructureAbility:UpdateViewModelPoseParameters(viewModel, input)

    Ability.UpdateViewModelPoseParameters(self, viewModel, input)

    // Move away from health spray
    self.healthSprayPoseParam = Clamp(Slerp(self.healthSprayPoseParam, 0, .5 * input.time), 0, 1)
    viewModel:SetPoseParam("health_spray", self.healthSprayPoseParam)
    
    // Move away from chamber 
    self.chamberPoseParam = Clamp(Slerp(self.chamberPoseParam, 0, .5 * input.time), 0, 1)
    viewModel:SetPoseParam("chamber", self.chamberPoseParam)
    
end

Shared.LinkClassToMap("DropStructureAbility", DropStructureAbility.kMapName, DropStructureAbility.networkVars )
