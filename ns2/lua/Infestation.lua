// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Infestation.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Patch of infestation created by alien commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")

class 'Infestation' (LiveScriptActor)

Infestation.kMapName = "infestation"

Infestation.kEnergyCost = kGrowCost
Infestation.kInitialHealth = 50
Infestation.kMaxHealth = 500
Infestation.kVerticalSize = 1
Infestation.kDecalVerticalSize = 1
Infestation.kGrowthRateScalar = 1

Infestation.kInitialRadius = .05
Infestation.kModelName = PrecacheAsset("models/alien/pustule/pustule.model")

Infestation.kThinkTime = 3

if Server then
    Script.Load("lua/Infestation_Server.lua")
end

Infestation.networkVars = 
{
    // 0 to kMaxRadius
    radius                  = "interpolated float",
    maxRadius               = "float",
    
    // Host hive or cyst
    hostAlive               = "boolean",
}

PrepareClassForMixin(Infestation, GameEffectsMixin)
PrepareClassForMixin(Infestation, FlinchMixin)

function Infestation:OnCreate()

    LiveScriptActor.OnCreate(self)
    
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, PathingMixin)
    
    self.health = Infestation.kInitialHealth
    self.maxHealth = Infestation.kMaxHealth
    self.maxRadius = kInfestationRadius
    
    self.hostAlive = true
    
    // False when created, turns true once it has reached full radius
    // Doesn't need to be connected to hive until it has reached full radius
    self.fullyGrown = false
    
    // how fast it is growing
    self.growthRate = 0
    
    self.growthRateScalar = Infestation.kGrowthRateScalar
    
    // Start visible
    self.radius = Infestation.kInitialRadius
    
    // track when we last thought
    self.lastThinkTime = Shared.GetTime()
    
    // our personal thinktime; avoid clumping
    self.thinkTime = Infestation.kThinkTime + 0.001 * self:GetId() % 100
    
    if (Client) then
        self.decal = Client.CreateRenderDecal()
        self.decal:SetMaterial("materials/infestation/infestation_decal.material")
    else 
        self.lastUpdateThinkTime = 0
		InitMixin(self, LOSMixin)
    end
    
    self:SetPhysicsGroup(PhysicsGroup.InfestationGroup)    
end

function Infestation:SetGrowthRateScalar(scalar)
    self.growthRateScalar = scalar
end

function Infestation:OnDestroy()    
    LiveScriptActor.OnDestroy(self)

    if Client then
        Client.DestroyRenderDecal( self.decal )
        self.decal = nil
    else
        Server.infestationMap:RemoveInfestation(self)
    end

   // self:ClearPathingFlags(Pathing.PolyFlag_Infestation)
end

function Infestation:OnInit()

    LiveScriptActor.OnInit(self)
    
    self:SetAnimation("scale")

    if Server then    
        self:TriggerEffects("spawn")
    end
    
    self:SetNextThink(0.01)        
end

function Infestation:GetRadius()
    return self.radius
end

function Infestation:SetMaxRadius(radius)
    self.maxRadius = radius        
end

function Infestation:GetMaxRadius()
    return self.maxRadius
end

// Takes 0 to 1
function Infestation:SetRadiusPercent(percent)
    self.radius = Clamp(percent, 0, 1)*self:GetMaxRadius()
end

function Infestation:GetTechId()
    return kTechId.Infestation
end

function Infestation:GetIsSelectable()
    return false
end

function Infestation:OnThink()
    PROFILE("Infestation:OnThink")

    local now = Shared.GetTime()

    local deltaTime = now - self.lastThinkTime
    
     if Server then
        self:UpdateInfestation(deltaTime)
    end
       
    if self.radius ~= self.maxRadius then
        LiveScriptActor.OnUpdate(self, deltaTime)
        self:SetNextThink(0.01) // update on every tick while we are changing the radius
        self.lastThinkTime = now 
        self:SetPathingFlags(Pathing.PolyFlag_Infestation)     
    else
        LiveScriptActor.OnThink(self)
        // avoid clumping and vary the thinkTime individually for each infestation patch (with 0-100ms)
        self.lastThinkTime = self.lastThinkTime + self.thinkTime
        // lastThinktime is now "now". Add in another dose of delta to find when we want to run next
        local nextThinkTime = self.lastThinkTime + self.thinkTime
        
        self:SetNextThink(nextThinkTime - now)
    end   

    if self.lastRadius ~= self.radius then
        self:SetPoseParam("scale", self.radius * 2)
        self.lastRadius = self.radius
    end

end

function Infestation:GetIsPointOnInfestation(point)

    local onInfestation = false
    
    // Check radius
    local radius = point:GetDistanceTo(self:GetOrigin())
    if radius <= self.radius then
    
        // Check dot product
        local toPoint = point - self:GetOrigin()
        local verticalProjection = math.abs( self:GetCoords().yAxis:DotProduct( toPoint ) )
        
        onInfestation = (verticalProjection < Infestation.kVerticalSize)
        
    end
    
    return onInfestation
   
end

function Infestation:GetPathingFlagOverride(position, extents, flags)
    return position, Vector(self.radius, Infestation.kDecalVerticalSize, self.radius), flags
end

function Infestation:OnUpdate(deltatime)
end

function Infestation:OverrideCheckvision()
  return false
end

if Client then

function Infestation:UpdateRenderModel()

    LiveScriptActor.UpdateRenderModel(self)
    
    if self.decal then
        self.decal:SetCoords( self:GetCoords() )
        self.decal:SetExtents( Vector(self.radius, Infestation.kDecalVerticalSize, self.radius) )
    end
    
end

end

Shared.LinkClassToMap("Infestation", Infestation.kMapName, Infestation.networkVars)