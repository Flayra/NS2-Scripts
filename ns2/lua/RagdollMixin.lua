// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\RagdollMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

local function GetDamageImpulse(damage, doer, point)

    if damage and doer and point then
        return GetNormalizedVector(doer:GetOrigin() - point) * (damage / 40) * .01
    end
    return nil
    
end

RagdollMixin = { }
RagdollMixin.type = "Ragdoll"

RagdollMixin.expectedMixins =
{
    Live = "Needed for SetIsAlive()."
}

RagdollMixin.expectedCallbacks =
{
    SetPhysicsType = "Sets the physics to the passed in type.",
    GetPhysicsType = "Returns the physics type, dynamic, kinematic, etc.",
    SetPhysicsGroup = "Sets the physics group to the passed in value.",
    GetPhysicsGroup = "",
    GetPhysicsModel = "Returns the physics model.",
    SetAnimation = "",
    TriggerEffects = ""
}

function RagdollMixin:__initmixin()
end

function RagdollMixin:OnTakeDamage(damage, attacker, doer, point)

    // Apply directed impulse to physically simulated objects, according to amount of damage.
    if self:GetPhysicsModel() ~= nil and self:GetPhysicsType() == PhysicsType.Dynamic then    
    
        local damageImpulse = GetDamageImpulse(damage, doer, point)
        if damageImpulse then
            self:GetPhysicsModel():AddImpulse(point, damageImpulse)
        end
        
    end
    
end
AddFunctionContract(RagdollMixin.OnTakeDamage, { Arguments = { "Entity", "number", "Entity", { "Entity", "nil" }, "Vector" }, Returns = { } })

function RagdollMixin:OnKill(damage, attacker, doer, point, direction)

    self.justKilled = true
    if point then
        self.deathImpulse = GetDamageImpulse(damage, doer, point)
        self.deathPoint = Vector(point)
    end

end
AddFunctionContract(RagdollMixin.OnKill, { Arguments = { "Entity", "number", "Entity", { "Entity", "nil" }, "Vector" }, Returns = { } })

function RagdollMixin:SetRagdoll(deathTime)

    if self:GetPhysicsGroup() ~= PhysicsGroup.RagdollGroup then

        self:SetPhysicsType(PhysicsType.Dynamic)
        
        self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
        
        // Apply landing blow death impulse to ragdoll (but only if we didn't play death animation).
        if self.deathImpulse and self.deathPoint and self:GetPhysicsModel() and self:GetPhysicsType() == PhysicsType.Dynamic then
        
            self:GetPhysicsModel():AddImpulse(self.deathPoint, self.deathImpulse)
            self.deathImpulse = nil
            self.deathPoint = nil
            
        end
        
        if deathTime then
            self.timeToDestroy = deathTime
        end
        
    end
    
end
AddFunctionContract(RagdollMixin.SetRagdoll, { Arguments = { "Entity", { "number", "nil" } }, Returns = { } })

function RagdollMixin:OnUpdate(deltaTime)

    // Process outside of OnProcessMove() because animations can't be set there.
    if Server then
        self:_UpdateJustKilled()
        self:_UpdateTimeToDestroy(deltaTime)
    end
    
end
AddFunctionContract(RagdollMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function RagdollMixin:_UpdateJustKilled()

    if self.justKilled then
    
        // Clear current animation so we know if it was set in TriggerEffects
        self:SetAnimation("", true)
        
        self:TriggerEffects("death")
        
        // Destroy immediately if death animation or ragdoll wasn't triggered (used queued because we're in OnProcessMove)
        local anim = self:GetAnimation()
        if (self:GetPhysicsGroup() == PhysicsGroup.RagdollGroup) or (anim ~= nil and anim ~= "") then
            
            if self.timeToDestroy == nil then
                // Set default time to destroy so it's impossible to have things lying around.
                self.timeToDestroy = 4
            end
            
        else
            self:SafeDestroy()
        end
        
        self.justKilled = nil

    end
    
end
AddFunctionContract(RagdollMixin._UpdateJustKilled, { Arguments = { "Entity" }, Returns = { } })

function RagdollMixin:_UpdateTimeToDestroy(deltaTime)
    
    if self.timeToDestroy then
    
        self.timeToDestroy = self.timeToDestroy - deltaTime
        
        if self.timeToDestroy <= 0 then
    
            self:SafeDestroy()
            self.timeToDestroy = nil
            
        end

    end
    
end
AddFunctionContract(RagdollMixin._UpdateTimeToDestroy, { Arguments = { "Entity" }, Returns = { } })

function RagdollMixin:SafeDestroy()

    // Note: This should be moved somewhere else soon.
    if self.GetIsOnFire and self:GetIsOnFire() then
        self:TriggerEffects("fire_stop")
    end

    if self:GetIsMapEntity() then
    
        self:SetIsAlive(false)
        self:SetIsVisible(false)
        self:SetPhysicsType(PhysicsType.None)
    
    // Players handle destroying themselves.
    elseif not self:isa("Player") then
    
        DestroyEntity(self)
        
    end

end
AddFunctionContract(RagdollMixin.SafeDestroy, { Arguments = { "Entity" }, Returns = { } })