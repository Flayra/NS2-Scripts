// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\RoboticsFactory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Structure.lua")
Script.Load("lua/RagdollMixin.lua")

class 'RoboticsFactory' (Structure)

RoboticsFactory.kMapName = "roboticsfactory"

RoboticsFactory.kModelName = PrecacheAsset("models/marine/robotics_factory/robotics_factory.model")

RoboticsFactory.kCloseDelay  = .5
RoboticsFactory.kActiveEffect = PrecacheAsset("cinematics/marine/roboticsfactory/active.cinematic")
RoboticsFactory.kAnimOpen   = "open"
RoboticsFactory.kAnimClose  = "close"

RoboticsFactory.kState = enum( {'Idle', 'Building', 'Deploying', 'Deployed', 'Closing'} )

local networkVars =
    {        
        state               = "enum RoboticsFactory.kState",
        currentBuiltId      = "entityid"   
    }

function RoboticsFactory:OnCreate()

    Structure.OnCreate(self)
    
    InitMixin(self, RagdollMixin)

end

function RoboticsFactory:OnInit()

    self:SetModel(RoboticsFactory.kModelName)
    
    Structure.OnInit(self)
    
    self:SetPhysicsType(PhysicsType.Kinematic)       
        
    self.currentArcId = Entity.invalidId
    
    self.currentBuiltId = Entity.invalidId
    
    if Server then
        self:SetState(RoboticsFactory.kState.Idle)
    end
    
end

function RoboticsFactory:GetRequiresPower()
    return true
end

function RoboticsFactory:GetTechButtons(techId)

    if(techId == kTechId.RootMenu) then
    
        return {   kTechId.MAC, kTechId.RoboticsFactoryMACUpgradesMenu, kTechId.None, kTechId.None, 
                   kTechId.ARC, kTechId.RoboticsFactoryARCUpgradesMenu, kTechId.None, kTechId.None }
    
    elseif techId == kTechId.RoboticsFactoryARCUpgradesMenu then
        return {   kTechId.ARCArmorTech, kTechId.ARCSplashTech, kTechId.None, kTechId.None,
                    kTechId.None, kTechId.None, kTechId.None, kTechId.RootMenu }
                    
    elseif techId == kTechId.RoboticsFactoryMACUpgradesMenu then
        return {   kTechId.MACSpeedTech, kTechId.MACEMPTech, kTechId.MACMinesTech, kTechId.None,
                    kTechId.None, kTechId.None, kTechId.None, kTechId.RootMenu }
        
    end
    
    return nil
    
end

function RoboticsFactory:GetPositionForEntity()
    
    local direction = Vector(self:GetAngles():GetCoords().zAxis)    
    local origin = self:GetOrigin() + direction * 3.2
    
    return BuildCoords(Vector(0, 1, 0), direction, origin)

end

// $AS - FIXME: Clean this state machine up if you would even call it that :/ 

function RoboticsFactory:ProcessOpenOrders()
    local builtEntity = Shared.GetEntity(self.currentBuiltId)
    if builtEntity ~= nil then      
       // local dest = builtEntity:GetOrigin() + Vector(4, 0 , 0)
       // builtEntity:GiveOrder(kTechId.Move, 0, dest, nil, true, true)
        coords = self:GetPositionForEntity()
        builtEntity:SetCoords(coords)
        self:SetActivityEnd(RoboticsFactory.kCloseDelay)
        self:SetState(RoboticsFactory.kState.Closing)
        self.currentBuiltId = Entity.invalidId
    end
end

// Don't allow researching when we're still finishing up building the ARC
function RoboticsFactory:GetIsResearching()
    return Structure.GetIsResearching(self) or (self.currentBuiltId ~= Entity.invalidId)
end

function RoboticsFactory:OnResearchComplete(structure, researchId)

    local researchNode = self:GetTeam():GetTechTree():GetTechNode(researchId)
    if structure == self and (researchId == kTechId.ARC or researchId == kTechId.MAC) then
    
        if researchNode then
        
            local mapName = LookupTechData(researchId, kTechDataMapName)
            local builtEntity = CreateEntity(mapName, self:GetOrigin(), structure:GetTeamNumber())
            
            // Set owner to commander that issued the order 
            local owner = Shared.GetEntity(self.researchingPlayerId)
            builtEntity:SetOwner(owner)
                        
            if researchNode:GetIsManufacture() then
            
                self.currentBuiltId = builtEntity:GetId()
                self:TriggerEffects("robo_factory_open")                                  
                self:SetState(RoboticsFactory.kState.Deploying)
                
            else
            
                self.currentBuiltId = Entity.invalidId
                self:SetState(RoboticsFactory.kState.Idle)
                
            end
            
        end
        
    end
    
    return Structure.OnResearchComplete(self, structure, researchId)
        
end


if Server then

    function RoboticsFactory:OnAnimationComplete(animName)
    
        Structure.OnAnimationComplete(self, animName)
    
        if animName == RoboticsFactory.kAnimOpen then
            self:SetState(RoboticsFactory.kState.Deployed)
        end
        if animName == RoboticsFactory.kAnimClose then
            self:SetState(RoboticsFactory.kState.Idle)
        end
        
    end

    function RoboticsFactory:OnResearch(researchId)    
        self:SetState(RoboticsFactory.kState.Building)    
    end
       
    
    function RoboticsFactory:GetCanIdle()
       return (self.state == RoboticsFactory.kState.Idle)
    end

    function RoboticsFactory:SetState(state)
        self.state = state
    end

    function RoboticsFactory:OnUpdate(deltaTime)

        Structure.OnUpdate(self, deltaTime)
    
        if self.state == RoboticsFactory.kState.Building then
            self:TriggerEffects("robo_factory_building")
        end
        
        if self.state == RoboticsFactory.kState.Deployed then
            self:ProcessOpenOrders()
        end
        
        if self.state == RoboticsFactory.kState.Closing then
        
            if self:GetCanNewActivityStart() then
                self:TriggerEffects("robo_factory_close")
            end
            
        end
            
    end
    
end


Shared.LinkClassToMap("RoboticsFactory", RoboticsFactory.kMapName, networkVars)