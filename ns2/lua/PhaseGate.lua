// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PhaseGate.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

// Transform angles, view angles and velocity from srcCoords to destCoords (when going through phase gate)
local function TransformPlayerCoordsForPhaseGate(player, srcCoords, dstCoords)

    local viewCoords = player:GetViewCoords()

    // If we're going through the backside of the phase gate, orient us
    // so we go out of the front side of the other gate.
    if Math.DotProduct(viewCoords.zAxis, srcCoords.zAxis) < 0 then
        srcCoords.zAxis = -srcCoords.zAxis
        srcCoords.xAxis = -srcCoords.xAxis
    end 


    // Redirect player velocity relative to gates
    local invSrcCoords = srcCoords:GetInverse()
    local invVel = invSrcCoords:TransformVector( player:GetVelocity() )
    local newVelocity = dstCoords:TransformVector( invVel )
    player:SetVelocity(newVelocity)
    
    local viewCoords = dstCoords * (invSrcCoords * viewCoords)
    local viewAngles = Angles()
    viewAngles:BuildFromCoords(viewCoords)
    
    player:SetOffsetAngles(viewAngles)
    
end

class 'PhaseGate' (Structure)

PhaseGate.kMapName = "phasegate"

PhaseGate.kUpdateInterval = 0.25
PhaseGate.kModelName = PrecacheAsset("models/marine/phase_gate/phase_gate.model")

// Offset about the phase gate origin where the player will spawn
PhaseGate.spawnOffset = Vector(0, 0.1, 0)

// Can only teleport a player every so often
PhaseGate.kDepartureRate = .5

PhaseGate.networkVars =
{
    linked              = "boolean",
    destLocationId      = "entityid",
}

function PhaseGate:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function PhaseGate:OnInit()

    Structure.OnInit(self)

    self:SetModel(PhaseGate.kModelName)
    
    // Compute link state on server and propagate to client for looping effects
    self.linked = false
    self.destLocationId = Entity.invalidId
    
    if Server then
    
        self:AddTimedCallback(PhaseGate.Update, PhaseGate.kUpdateInterval)
        self.timeOfLastPhase = nil
    
    end
    
end

function PhaseGate:GetTechButtons(techId)

    return { kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
             kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    
end

// Temporarily don't use "target" attach point
function PhaseGate:GetEngagementPoint()
    return ScriptActor.GetEngagementPoint(self)
end

function PhaseGate:GetRequiresPower()
    return true
end

function PhaseGate:GetDestLocationId()
    return self.destLocationId
end

if Server then

/**
 * Returns true if the phase gate is ready to teleport a player. This does not check if
 * there is a destination phase gate however.
 */ 
function PhaseGate:_GetCanPhase()

    if not self:GetIsBuilt() or not self:GetIsActive() then
        return false
    end

    if self.timeOfLastPhase == nil or (Shared.GetTime() > (self.timeOfLastPhase + PhaseGate.kDepartureRate)) then
        return true
    end

    return false

end

function PhaseGate:Update()

    local destinationPhaseGate = self:GetDestinationGate()
    
    // If built and active 
    if destinationPhaseGate ~= nil and self:_GetCanPhase() then
    
        local players = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 1)
        
        for index, player in ipairs(players) do
        
            if player.GetCanPhase and player:GetCanPhase() then
                
                local destOrigin = destinationPhaseGate:GetOrigin() + PhaseGate.spawnOffset
                
                // Check if destination is clear
                if player:SpaceClearForEntity(destOrigin) then
                
                    self:TriggerEffects("phase_gate_player_enter")
                    
                    TransformPlayerCoordsForPhaseGate(player, self:GetCoords(), destinationPhaseGate:GetCoords())
            
                    SpawnPlayerAtPoint(player, destOrigin)
                    
                    destinationPhaseGate:TriggerEffects("phase_gate_player_exit")
                    
                    self.timeOfLastPhase = Shared.GetTime()
                    
                    player:SetTimeOfLastPhase(self.timeOfLastPhase)
                    
                    break    

                end
                
            end
            
        end
            
    end
    
    // Update linked state
    self.linked = self:GetIsBuilt() and self:GetIsActive() and (destinationPhaseGate ~= nil)
    
    // Update destination id for displaying in description
    self.destLocationId = self:ComputeDestinationLocationId()
    
    return true
    
end

function PhaseGate:ComputeDestinationLocationId()

    local destLocationId = Entity.invalidId
    
    local destGate = self:GetDestinationGate()
    if destGate then
    
        local name, location = GetLocationForPoint(destGate:GetOrigin())
        if location then
            destLocationId = location:GetId()
        end
        
    end
    
    return destLocationId
    
end

// Returns next phase gate in round-robin order. Returns nil if there are no other built/active phase gates 
function PhaseGate:GetDestinationGate()

    // Find next phase gate to teleport to
    local phaseGates = {}    
    for index, phaseGate in ipairs( GetEntitiesForTeam("PhaseGate", self:GetTeamNumber()) ) do
        if phaseGate:GetIsAlive() and phaseGate:GetIsBuilt() and phaseGate:GetIsActive() then
            table.insert(phaseGates, phaseGate)
        end
    end    
    
    if table.count(phaseGates) < 2 then
        return nil
    end
    
    // Find our index and add 1
    local index = table.find(phaseGates, self)
    if (index ~= nil) then
    
        local nextIndex = ConditionalValue(index == table.count(phaseGates), 1, index + 1)
        ASSERT(nextIndex >= 1)
        ASSERT(nextIndex <= table.count(phaseGates))
        return phaseGates[nextIndex]
        
    end
    
    return nil
    
end

end

if Client then

    // Update effects
    function PhaseGate:OnUpdateRender()

        PROFILE("PhaseGate:OnSynchronized")
        
        Structure.OnUpdateRender(self)
        
        if self.linked ~= self.clientLinkedState then
        
            local effects = ConditionalValue(self.linked, "phase_gate_linked", "phase_gate_unlinked")
            self:TriggerEffects(effects)
            self.clientLinkedState = self.linked
            
        end
        
    end

end

Shared.LinkClassToMap("PhaseGate", PhaseGate.kMapName, PhaseGate.networkVars)