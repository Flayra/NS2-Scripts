// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/DbgTracer.lua")

class 'Weapon' (ScriptActor)

Weapon.kMapName = "weapon"

// Attach point for marine weapons
Weapon.kHumanAttachPoint = "RHand_Weapon"

Weapon.kSprintStart = "sprint_start"
Weapon.kAnimSprint = "sprint"
Weapon.kSprintEnd = "sprint_end"

Weapon.kSwingYaw = "swing_yaw"
Weapon.kSwingPitch = "swing_pitch"

// Move hit effect slightly off surface we hit so particles don't penetrate. In meters.
Weapon.kHitEffectOffset = .15

// How much force to use when knocking back a target.
Weapon.kKnockbackForce = 25
// This value is multiplied into the y component of the velocity after knockback force has been calculated.
Weapon.kKnockbackYScalar = 0.05
// How long a target is stunned (unable to control their velocity) after being knocked back.
Weapon.kKnockbackStunTime = 0.5

if (Server) then
    Script.Load("lua/Weapons/Weapon_Server.lua")
else
    Script.Load("lua/Weapons/Weapon_Client.lua")
end

local networkVars = 
{
    isHostered = "boolean"
}

function Weapon:OnCreate()

    ScriptActor.OnCreate(self)
    
    self:SetPhysicsGroup(PhysicsGroup.WeaponGroup)
    
    self:SetUpdates(true)
    
    self.reverseX = false
    self.moveWithView = false
    
    self:SetIsVisible(false)
    self.isHostered = true
    
end

function Weapon:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    // Force end events just in case the weapon goes out of relevancy on the client for example.
    self:TriggerEffects(self:GetPrimaryAttackPrefix() .. "_attack_end")
    self:TriggerEffects(self:GetSecondaryAttackPrefix() .. "_alt_attack_end")

end

function Weapon:GetViewModelName()
    return ""
end

function Weapon:SetMoveWithView(moveWithView)
    self.moveWithView = moveWithView
end

function Weapon:GetRange()
    return 8012
end

// Return 0-1 scalar approximation for weight. Owner of weapon will determine
// what this means and how to use it.
function Weapon:GetWeight()
    return 0
end

function Weapon:SetCameraShake(amount, speed, time)
    local parent = self:GetParent()
    if(parent ~= nil and Client) then
        parent:SetCameraShake(amount, speed, time)
    end
end

function Weapon:GetIsDroppable()
    return false
end

function Weapon:GetRunIdleAnimation()
    return self:GetBaseIdleAnimation()
    //return Weapon.kAnimRunIdle
end

function Weapon:GetPrimaryAttackDelay()
    return .5
end

function Weapon:GetSecondaryAttackDelay()
    return .5
end

function Weapon:GetPrimaryAttackRequiresPress()
    return false
end

function Weapon:GetSecondaryAttackRequiresPress()
    return false
end

// So child classes can override names of event names that are triggered (for grenade launcher to use rifle effects block)
function Weapon:GetPrimaryAttackPrefix()
    return self:GetMapName()
end

function Weapon:GetSecondaryAttackPrefix()
    return self:GetMapName()
end

function Weapon:OnPrimaryAttack(player)
    self:TriggerEffects(self:GetPrimaryAttackPrefix() .. "_attack")
end

function Weapon:OnPrimaryAttackEnd(player)
    self:TriggerEffects(self:GetPrimaryAttackPrefix() .. "_attack_end")
end

function Weapon:OnSecondaryAttack(player)
    self:TriggerEffects(self:GetSecondaryAttackPrefix() .. "_alt_attack")
end

function Weapon:OnSecondaryAttackEnd(player)
    self:TriggerEffects(self:GetSecondaryAttackPrefix() .. "_alt_attack_end")
end

function Weapon:OnReload(player)
end

function Weapon:GetIsHolstered()
    return self.isHostered
end

function Weapon:OnHolster(player)
    self.isHostered = true
    self:SetIsVisible(false)
end

function Weapon:OnDraw(player, previousWeaponMapName)

    self.isHostered = false
    self:SetIsVisible(true)
    
    player:SetViewModel(self:GetViewModelName(), self)

    local viewModel = player:GetViewModelEntity()
    ASSERT(viewModel)
    local prevSequence = viewModel.animationSequence

    // Speed parameter stacks for animations (ie, playback speed is one specified below * any speed parameter specified in script)
    local speedScalar = ConditionalValue(player:isa("Marine"), kMarineDrawSpeedScalar, 1)
    self:TriggerEffects("draw", {speed = speedScalar})
    
    // Only set activity length to draw animation if set in trigger effects
    local drawTime = 0
    if prevSequence ~= viewModel.animationSequence then
        player:SetActivityEnd(player:GetViewAnimationLength())   
    end
    
end

/**
 * Allow weapons to have different capsules
 */
function Weapon:GetMeleeCapsule()
    return Vector(0.4, 0.4, 0.4)
end

/**
 * Offset the start of the melee capsule with this much from the viewpoint
 */
function Weapon:GetMeleeOffset()
    return -0.1
end

/**
 * Checks if a melee capsule would hit anything. Does not actually carry
 * out any attack or inflict any damage.
 */
function Weapon:CheckMeleeCapsule(player, damage, range, optionalCoords)
    // Trace using a box so that unlike bullet attacks we don't require precise targeting
    local extents = self:GetMeleeCapsule()
   
    local attackOffset = self:GetMeleeOffset()
    local eyePoint = player:GetEyePos()

    local coords = optionalCoords or player:GetViewAngles():GetCoords()

    local axis = coords.zAxis
    
    local startPoint = eyePoint + axis * attackOffset
    local endPoint   = eyePoint + axis * range 

    local filter = EntityFilterTwo(player, self)
   
    if attackOffset > 0 then
        // Make sure that nothing comes between us and the offset point; no biting through walls/railings!
        local trace = Shared.TraceRay(eyePoint, startPoint, PhysicsMask.Melee, filter)
        if trace.fraction < 1 then 
              // Do a full trace from the eye
             startPoint = eyePoint
        end
    end
        
    trace = Shared.TraceBox(extents, startPoint, endPoint, PhysicsMask.Melee, filter)

    if self.traceRealAttack then
        if Client then
            DbgTracer.MarkClientFire(player, startPoint)
        end

        if Server then
            Server.dbgTracer:TraceMelee(player, startPoint, trace, extents, coords)
        end
    end
    
    local direction = nil
    if trace.fraction < 1 then
        direction = (trace.endPoint - startPoint):GetUnit()
    end
    
    return trace.fraction < 1, trace, direction

end

/**
 * Does an attack with a melee capsule.
 */
function Weapon:AttackMeleeCapsule(player, damage, range, optionalCoords)

    // Enable tracing on this capsule check.
    self.traceRealAttack = true
    local didHit, trace, direction = self:CheckMeleeCapsule(player, damage, range, optionalCoords)
    self.traceRealAttack = false
    
    if trace.fraction < 1 then
    
        self:ApplyMeleeHit(player, damage, trace, direction)
        
    end
    
    return didHit, trace
    
end

/**
 * Apply melee attack hit on the target
 */
function Weapon:ApplyMeleeHit(player, damage, trace, direction)

    if Server then
        self:ApplyMeleeHitEffects(player, damage, trace.entity, trace.endPoint, direction)
        TriggerHitEffects(self, trace.entity, trace.endPoint, trace.surface, true)
    end
    
end

function Weapon:ConstrainMoveVelocity(moveVelocity)
end

// Weapons can override
function Weapon:OnTargetKilled(entity)
end

function Weapon:ApplyMeleeHitEffects(player, damage, target, endPoint, direction)

    if(target ~= nil and Server and target:isa("LiveScriptActor")) then
    
        if(target:TakeDamage(damage, player, self, endPoint, direction)) then
            self:OnTargetKilled(player)        
        end
            
        self:GetParent():SetTimeTargetHit()
        
    end
    
end

function Weapon:UpdateViewModelPoseParameters(viewModel, input)
end

/**
 * Some weapons support knocking back the target. This will cause the target's
 * velocity to be repelled backward's away from the player and stun the target
 * if they are stunnable (have the StunMixin).
 */
function Weapon:KnockbackTarget(player, target, hitLocation)

    // Knockback the target a bit if the target allows it.
    if Server and target.GetIsKnockbackAllowed and target:GetIsKnockbackAllowed() then
    
        // Take target mass into account.
        local direction = target:GetOrigin() - player:GetOrigin()
        direction:Normalize()
        
        self.executeKnockback = { Direction = direction, TargetId = target:GetId() }
        
    end

end

function Weapon:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server and self.executeKnockback then
    
        local direction = self.executeKnockback.Direction
        local knockEntity = Shared.GetEntity(self.executeKnockback.TargetId)
        self.executeKnockback = nil
        // Just in case the target is no longer valid.
        if knockEntity then
            local targetVelocity = direction * (300 / knockEntity:GetMass()) * Weapon.kKnockbackForce
            targetVelocity.y = targetVelocity.y * Weapon.kKnockbackYScalar
            knockEntity:SetVelocity(targetVelocity)
            // Stun after setting velocity as stun limits the ability to set velocity.
            if HasMixin(knockEntity, "Stun") then
                knockEntity:SetStunTime(Shared.GetTime() + Weapon.kKnockbackStunTime)
                knockEntity:SetAnimationWithBlending("death")
            end
        end
        
    end
    
    // Handle dropping on the client
    if Client then
        self:UpdateDropped()
    end

end

// TODO: Move into UpdateAnimation?
function Weapon:OnProcessMove(player, input)

    // Only update if deployed as current weapon
    if(self:GetIsActive()) then
    
        if not Shared.GetIsRunningPrediction() then
        
            local viewModel = player:GetViewModelEntity()
            if viewModel ~= nil and viewModel.modelIndex ~= 0 then
                self:UpdateViewModelPoseParameters(player:GetViewModelEntity(), input)
            end

            self:UpdateAnimation( input.time )
            
        end
        
    end
end

function Weapon:GetIsActive()
    local parent = self:GetParent()
    return (parent ~= nil and (parent.GetActiveWeapon) and (parent:GetActiveWeapon() == self))
end

/**
 * Only allow idle if this weapon is active.
 */
function Weapon:GetCanIdle()
    return self:GetIsActive()
end

/**
 * Don't play animations on weapons.
 */
function Weapon:SetAnimation(sequenceName, force)
end

function Weapon:GetSprintStartAnimation()
    return Weapon.kSprintStart
end

function Weapon:GetSprintAnimation()
    return Weapon.kAnimSprint
end

function Weapon:GetSprintEndAnimation()
    return Weapon.kSprintEnd
end

// Max degrees that weapon can swing left or right
function Weapon:GetSwingAmount()
    return 40
end

function Weapon:GetSwingSensitivity()
    return .5
end

Shared.LinkClassToMap("Weapon", Weapon.kMapName, networkVars)
