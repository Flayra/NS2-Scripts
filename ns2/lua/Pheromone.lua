// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Pheromone.lua
//
// A way for the alien commander to communicate with his minions.
// 
// Goals
//   Create easy way for alien commander to communicate with his team without needing to click aliens and give orders. That wouldn’t fit.
//   Keep it feeling “bottom-up” so players can make their own choices
//   Have “orders” feel environmental
//
// First implementation
//   Create pheromones that act as a hive sight blip. Aliens can see pheromones like blips on their HUD. Examples: “Need healing”, “Need protection”, “Building here”, 
//   “Need infestation”, “Threat detected”, “Reinforce”. These are not orders, but informational. It’s up to aliens to decide what to do, if anything. 
//
//   Each time you create pheromones, it will create a new “signpost” at that location if there isn’t one nearby. Otherwise, if it is a new type, it will remove the 
//   old one and create the new one. If there is one of the same type nearby, it will intensify the current one to make it more important. In this way, each pheromone 
//   has an analog intensity which indicates the range at which it can be seen, as well as the alpha, font weight, etc. (how much it stands out to players).
//
//   Each time you click, a circle animates showing the new intensity (larger intensity shows a bigger circle). When creating pheromones, VAFX play slight gas sound and 
//   foggy bits pop out of the environment and coalesce, spinning, around the new sign post text.
//
//   When mousing over them, a “dismiss” button appears so the commander and manually delete them if no longer relevant. They also dissipate over time. Each level gives 
//   it x seconds of life.
// 
//   Pheromones are public property and have no owner. Any commander can dismiss, modify or grow any other pheromone cloud.
//
//   Show very faint/basic pheromone indicator to marines also. They have an idea that they are nearby, but don’t know what (perhaps just play faint sound when created, no visual).
//
//   Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'Pheromone' (ScriptActor)

Pheromone.kMapName = "pheromone"
Pheromone.kMaxLevel = 5
Pheromone.kDistPerLevel = 15
Pheromone.kLifetimePerLevel = 20

Pheromone.networkVars =
{
    // "Threat detected", "Reinforce", etc.
    type            = "enum kTechId",

    // Lifetime left before expiring (seconds)
    lifetime        = "float",
    
    // Level 1 - 5, indicating how widely to broadcast to nearby aliens and the "strength" to display it
    level           = string.format("integer (1 to %d", Pheromone.kMaxLevel)
}

function Pheromone:OnCreate()

    ScriptActor.OnCreate(self)
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()

    self.type = kTechId.None
    self.lifetime = 0
    self.level = 1
    
    if Server then
        self:SetUpdates(true)
    end
    
end

// Set lifetime and level
function Pheromone:Initialize(techId)
    self.type = techId
    self.level = 1
    self.lifetime = Pheromone.kLifetimePerLevel
end

function Pheromone:GetType()
    return self.type
end

function Pheromone:GetBlipType()
    return kBlipType.Pheromone
end

function Pheromone:GetLevel()
    return self.level
end

function Pheromone:GetDisplayName()
    return GetDisplayNameForTechId(self.type, "<no pheromone name>")
end

function Pheromone:GetAppearDistance()
    return self.level * Pheromone.kDistPerLevel
end

function Pheromone:OnGetIsRelevant(player)
    return GetGamerules():GetIsRelevant(player, self)   
end

function Pheromone:UpdateRelevancy()

    self:SetRelevancyDistance( self:GetAppearDistance() )
    
    if self.teamNumber == 1 then
        self:SetIncludeRelevancyMask( kRelevantToTeam1 )
    else
        self:SetIncludeRelevancyMask( kRelevantToTeam2 )
    end
    
end

if Server then

function GetExistingPheromoneInRange(techId, position, teamNumber)

    local pheromone = nil
    local nearestDist = nil
    
    local pheromones = GetEntitiesWithinRange("Pheromone", position, Pheromone.kMaxLevel * Pheromone.kDistPerLevel)
    for index, parentPheromone in ipairs(pheromones) do
    
        if (parentPheromone:GetType() == techId) and (parentPheromone:GetTeamNumber() == teamNumber) then
        
            local dist = (position - parentPheromone:GetOrigin()):GetLength()
            if dist <= parentPheromone:GetAppearDistance() then
            
                if nearestDist == nil or dist < nearestDist then
                
                    nearestDist = dist
                    pheromone = parentPheromone
                    
                end
                
            end
            
        end
        
    end
    
    return pheromone
    
end

function CreatePheromone(techId, position, commander)

    // Look for existing nearby pheromone with same type and increase the size of it
    local teamNumber = commander:GetTeamNumber()
    local pheromone = GetExistingPheromoneInRange(techId, position, teamNumber)
    local createdNew = false
    
    if pheromone then 
        pheromone:Increase()        
    else
    
        // Otherwise create new one (hover off ground a little)
        pheromone = CreateEntity(Pheromone.kMapName, position + Vector(0, .5, 0), teamNumber)
        pheromone:Initialize(techId)
        createdNew = true
        
    end
    
    // Create gas effects for teammates and very subtle sound for enemies
    commander:TriggerEffects("create_pheromone", {kEffectHostCoords = pheromone:GetAngles():GetCoords()})
    
    return pheromone
    
end

function Pheromone:Increase()

    // Don't increase if we're already the biggest we can be
    if self.level < Pheromone.kMaxLevel then
        self.level = self.level + 1
        self.lifetime = self.lifetime + Pheromone.kLifetimePerLevel
    end
    //Print("Increasing pheromone level to %d, lifetime to %.2f", self.level, self.lifetime)
    
end

function Pheromone:OnUpdate(timePassed)

    ScriptActor.OnUpdate(self, timePassed)
    
    // Expire pheromones after a time
    self.lifetime = self.lifetime - timePassed
    if self.lifetime <= 0 then
        DestroyEntity(self)
    end
    
end

end

Shared.LinkClassToMap("Pheromone", Pheromone.kMapName, Pheromone.networkVars)
