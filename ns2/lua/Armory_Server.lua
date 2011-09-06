// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Armory_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// west/east = x/-x
// north/south = -z/z

local indexToUseOrigin = {
    // West
    Vector(Armory.kResupplyUseRange, 0, 0), 
    // North
    Vector(0, 0, -Armory.kResupplyUseRange),
    // South
    Vector(0, 0, Armory.kResupplyUseRange),
    // East
    Vector(-Armory.kResupplyUseRange, 0, 0)
}

function Armory:GetShouldResupplyPlayer(player)

    local inNeed = false
    
    // Don't resupply when already full
    if( (player:GetHealth() < player:GetMaxHealth()) or (player:GetArmor() < player:GetMaxArmor()) ) then
    
        inNeed = true
        
    else

        // Do any weapons need ammo?
        local weapons = player:GetHUDOrderedWeaponList()
            
        for index, weapon in ipairs(weapons) do
        
            if weapon:isa("ClipWeapon") and weapon:GetNeedsAmmo() then
            
                inNeed = true
                break
                    
            end
            
        end
        
    end
    
    if inNeed then
    
        // Check player facing so players can't fight while getting benefits of armory
        local viewVec = player:GetViewAngles():GetCoords().zAxis

        local toArmoryVec = self:GetOrigin() - player:GetOrigin()
        
        if(GetNormalizedVector(viewVec):DotProduct(GetNormalizedVector(toArmoryVec)) > .75) then
        
            local timeResupplied = self.resuppliedPlayers[player:GetId()]
            
            if(timeResupplied ~= nil) then
            
                // Make sure we haven't done this recently    
                if(Shared.GetTime() < (timeResupplied + Armory.kResupplyInterval)) then
                
                    return false
                    
                end
                
            end
            
            return true
            
        end
        
    end
    
    return false
    
end

function Armory:ResupplyPlayer(player)
    
    local resuppliedPlayer = false
    
    // Heal player first
    if( (player:GetHealth() < player:GetMaxHealth()) or (player:GetArmor() < player:GetMaxArmor()) ) then

        player:AddHealth(Armory.kHealAmount)

        self:TriggerEffects("armory_health", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        resuppliedPlayer = true
        
    end

    // Give ammo to all their weapons, one clip at a time, starting from primary
    local weapons = player:GetHUDOrderedWeaponList()
    
    for index, weapon in ipairs(weapons) do
    
        if weapon:isa("ClipWeapon") then
        
            if weapon:GiveAmmo(1) then
            
                self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
                
                resuppliedPlayer = true
                
                break
                
            end 
                   
        end
        
    end
        
    if resuppliedPlayer then
    
        // Insert/update entry in table
        self.resuppliedPlayers[player:GetId()] = Shared.GetTime()
        
        // Play effect
        //self:PlayArmoryScan(player:GetId())

    end

end

function Armory:ResupplyPlayers()

    local playersInRange = GetEntitiesForTeamWithinRange("Player", self:GetTeamNumber(), self:GetOrigin(), Armory.kResupplyUseRange)
    for index, player in ipairs(playersInRange) do
    
        // For each, check if they are facing us and if they haven't been resupplied for awhile
        if self:GetShouldResupplyPlayer(player) then
        
            self:ResupplyPlayer(player)                

        end
            
    end

end

function Armory:AddChildModel(modelName)

    local scriptActor = CreateEntity(ArmoryAddon.kMapName, nil, self:GetTeamNumber())
    
    scriptActor:SetModel(modelName)
    scriptActor:SetParent(self)
    scriptActor:SetAttachPoint(Armory.kAttachPoint)
    scriptActor:SetAnimation("spawn")
    scriptActor:SetPoseParam("spawn", self.researchProgress)
    
end

function Armory:TriggerChildDeployAnimation(modelName)

    local children = GetChildEntities(self, "ArmoryAddon")
    
    for index, child in ipairs(children) do
    
        if child:GetModelName() == modelName then
            child:SetAnimation("deploy")
            
            function TriggerChildIdleAnimation()
                child:SetAnimation("idle")
                // Cancel the timed callback.
                return false
            end
            self:AddTimedCallback(TriggerChildIdleAnimation, child:GetAnimationLength("deploy"))
        end
        
    end

end

function Armory:OnResearch(researchId)

    if(researchId == kTechId.AdvancedArmoryUpgrade) then

        // Create visual add-on
        self:AddChildModel(Armory.kAdvancedArmoryChildModel)
        
    end
    
end

// Called when research or upgrade complete
function Armory:OnResearchComplete(structure, researchId)

    local success = Structure.OnResearchComplete(self, structure, researchId)

    if success then
    
        if(researchId == kTechId.AdvancedArmoryUpgrade) then

            // Transform into Advanced Armory
            success = self:SetTechId(kTechId.AdvancedArmory)
            
            self:TriggerChildDeployAnimation(Armory.kAdvancedArmoryChildModel)
        
        end
        
    end
    
    return success    
    
end

// Check if friendly players are nearby and facing armory and heal/resupply them
function Armory:OnThink()

    Structure.OnThink(self)

    self:UpdateLoggedIn()
    
    // Make sure players are still close enough, alive, marines, etc.
    if self:GetIsBuilt() and self:GetIsActive() then
    
        // Give health and ammo to logged in players
        self:ResupplyPlayers()
        
    end    
    
    self:SetNextThink(Armory.kThinkTime)
    
end

function Armory:UpdateLoggedIn()

    local players = GetEntitiesForTeamWithinRange("Player", self:GetTeamNumber(), self:GetOrigin(), 2 * Armory.kResupplyUseRange)
    local armoryCoords = self:GetAngles():GetCoords()
    
    for i = 1, 4 do 
        
        local newState = false
        
        if self:GetIsBuilt() and self:GetIsActive() then
        
            local worldUseOrigin = self:GetModelOrigin() + armoryCoords:TransformVector(indexToUseOrigin[i])
        
            for playerIndex, player in ipairs(players) do
            
                // See if player is nearby
                if player:GetIsAlive() and (player:GetModelOrigin() - worldUseOrigin):GetLength() < Armory.kResupplyUseRange then
                
                    newState = true
                    break
                    
                end
                
            end
            
        end
        
        if newState ~= self.loggedInArray[i] then
        
            if newState then
                self:TriggerEffects("armory_open")
            else
                self:TriggerEffects("armory_close")
            end
            
            self.loggedInArray[i] = newState
            
        end
        
    end
    
    // Copy data to network variables (arrays not supported)    
    self.loggedInWest = self.loggedInArray[1]
    self.loggedInNorth = self.loggedInArray[2]
    self.loggedInSouth = self.loggedInArray[3]
    self.loggedInEast = self.loggedInArray[4]

end

