// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\InfestationAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Infestation spray on primary. Currently not used.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'InfestationAbility' (Ability)

InfestationAbility.kMapName = "infestation_ability"
InfestationAbility.kInfestationRange = 1.75
InfestationAbility.kInfestationMaxSize = 1.5
InfestationAbility.kModelName = PrecacheAsset("models/misc/circle/circle_alien.model")

local networkVars = 
{
    // When true, show ghost preview (on deploy and after attacking)
    showGhost               = "boolean",
}

function InfestationAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Infestation
end

function InfestationAbility:GetHUDSlot()
    return 2
end

function InfestationAbility:OnDraw(player, prevWeapon)

    Ability.OnDraw(self, player, prevWeapon)
    
    self.showGhost = true
    
end

function InfestationAbility:GetEnergyCost(player)
    return 40
end

function InfestationAbility:GetPrimaryAttackDelay()
    return 1.0
end

// Check before energy is spent if a Infestation can be built in the current location.
function InfestationAbility:OnPrimaryAttack(player)

    local coords, valid = self:GetPositionForInfestation(player)
    if valid then
        Ability.OnPrimaryAttack(self, player)
    else
        player:AddTooltip("Could not place Infestation in that location.")
    end
    
end

// Create infestation
function InfestationAbility:PerformPrimaryAttack(player)

    // Make ghost disappear
    if self.showGhost then
    
        player:TriggerEffects("start_create_infestation")
    
        player:SetAnimAndMode(Gorge.kCreateStructure, kPlayerMode.GorgeStructure)
            
        player:SetActivityEnd(player:AdjustFuryFireDelay(self:GetPrimaryAttackDelay()))

        // We create this right away!    
        self:CreateInfestation(player)
    end
    
end

function InfestationAbility:CreateInfestation(player)

    // Trace in front and create infestation there
    local success = false
    
    if Server then

        local coords, valid = self:GetPositionForInfestation(player)
        if valid then
    
            local infestation = CreateEntity(Infestation.kMapName, coords.origin, player:GetTeamNumber())
            
            infestation:SetMaxRadius(InfestationAbility.kInfestationMaxSize)
            infestation:SetCoords(coords)
            infestation:SetLifetime(kGorgeInfestationLifetime)
            infestation:SetRadiusPercent(.3)
            
            player:TriggerEffects("create_infestation")
            
            success = true
            
        else
        
            player:AddTooltip("Could not place Infestation in that location.")
        
        end
            
    end
    
    return success
    
end

// Given a gorge player's position and view angles, return a position and orientation
// for infestation patch. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function InfestationAbility:GetPositionForInfestation(player)

    local validPosition = false
    
    local origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * InfestationAbility.kInfestationRange

    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = Vector()
    VectorCopy(trace.endPoint, displayOrigin)
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * InfestationAbility.kInfestationRange
        trace = Shared.TraceRay(origin, origin - Vector(0, InfestationAbility.kInfestationRange, 0), PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end
    
    // If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
    
        if trace.entity == nil then
            validPosition = true
        elseif not trace.entity:isa("LiveScriptActor") then
            validPosition = true
        end
        
        VectorCopy(trace.endPoint, displayOrigin)
        
    end
    
    local coords = nil
    
    if validPosition then
    
        // Don't allow placing infestation above or below us and don't draw either
        local infestationFacing = Vector()
        VectorCopy(player:GetViewAngles():GetCoords().zAxis, infestationFacing)
        
        coords = BuildCoords(trace.normal, infestationFacing, displayOrigin, InfestationAbility.kInfestationMaxSize * 2)    

        
        ASSERT(ValidateValue(coords.xAxis))
        ASSERT(ValidateValue(coords.yAxis))
        ASSERT(ValidateValue(coords.zAxis))

        local infestations = GetEntitiesForTeamWithinRange("Infestation", player:GetTeamNumber(), coords.origin, 1)
        
        if table.count(infestations) >= 3 then
            validPosition = false
        end
        
    end
    
    return coords, validPosition

end

if Client then
function InfestationAbility:OnUpdate(deltaTime)

    Ability.OnUpdate(self, deltaTime)
    
    if not Shared.GetIsRunningPrediction() then

        local player = self:GetParent()
        
        if player == Client.GetLocalPlayer() and player:GetActiveWeapon() == self then
        
            // Show ghost if we're able to create an infestation patch.
            self.showGhost = player:GetCanNewActivityStart()
            
            // Create ghost
            if not self.ghostInfestation and self.showGhost then
            
                self.ghostInfestation = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.ghostInfestation:SetModel( Shared.GetModelIndex(InfestationAbility.kModelName) )
                self.ghostInfestation:SetCastsShadows(false)
                                
            end
            
            // Destroy ghost
            if self.ghostInfestation and not self.showGhost then
                self:DestroyInfestationGhost()
            end
            
            // Update ghost position 
            if self.ghostInfestation then
            
                local coords, valid = self:GetPositionForInfestation(player)
                
                if valid then
                    self.ghostInfestation:SetCoords(coords)
                end
                self.ghostInfestation:SetIsVisible(valid)
                
                // TODO: Set color of structure according to validity
                
            end
          
        end
        
    end
    
end

function InfestationAbility:DestroyInfestationGhost()

    if Client then
    
        if self.ghostInfestation ~= nil then
        
            Client.DestroyRenderModel(self.ghostInfestation)
            self.ghostInfestation = nil
            
        end
        
    end
    
end

function InfestationAbility:OnDestroy()
    self:DestroyInfestationGhost()
    Ability.OnDestroy(self)
end

function InfestationAbility:OnHolster(player)
    Ability.OnHolster(self, player)
    self:DestroyInfestationGhost()
end

end

Shared.LinkClassToMap("InfestationAbility", InfestationAbility.kMapName, networkVars )
