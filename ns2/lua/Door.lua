// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Door.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/LiveScriptActor.lua")

class 'Door' (LiveScriptActor)

Door.kMapName = "door"

Door.kModelName = PrecacheAsset("models/misc/door/door.model")
Door.kInoperableSound = PrecacheAsset("sound/ns2.fev/common/door_inoperable")
Door.kOpenSound = PrecacheAsset("sound/ns2.fev/common/door_open")
Door.kCloseSound = PrecacheAsset("sound/ns2.fev/common/door_close")
Door.kWeldedSound = PrecacheAsset("sound/ns2.fev/common/door_welded")
Door.kLockSound = PrecacheAsset("sound/ns2.fev/common/door_lock")
Door.kUnlockSound = PrecacheAsset("sound/ns2.fev/common/door_unlock")

// Open means it's opening, close means it's closing, welding means its being welded
Door.kState = enum( {'Opened', 'Open', 'Closed', 'Close', 'Welded', 'Lock', 'Locked', 'Unlock', 'Unlocked', 'LockDestroyed', 'Welding'} )
Door.kStateAnim = {'opened', 'open', 'closed', 'close', 'welded', 'lock', 'locked', 'unlock', 'unlocked', '', ''}
Door.kStateSound = {'', Door.kOpenSound, '', Door.kCloseSound, Door.kWeldedSound, Door.kLockSound, '', Door.kUnlockSound, '', '', ''}

Door.kDefaultWeldTime = 15
Door.kDefaultHealth = 500
Door.kWeldPointValue = 3
Door.kThinkTime = .3

if (Server) then
    Script.Load("lua/Door_Server.lua")
end

local networkVars   = {

    // Saved health we restore to on reset
    weldHealth      = "integer (0 to 2000)",

    // Amount door has been welded so far
    time            = "float",
    
    // Saved weld time we restore to on reset
    weldTime        = "float",
    
    // Marine overriding the lock temporarily
    overrideUnlockTime = "float",
    
    // So door doesn't act on its own accord too soon after Commander affects it
    timeLastCommanderAction = "float",
    
    // Stores current state (kState )
    state           = string.format("integer (1 to %d)", Door.kState.LockDestroyed)

}

function Door:OnInit()
      
    LiveScriptActor.OnInit(self)
       
    if (Server) then
    
        self:SetModel(Door.kModelName)  
      
        self:SetIsVisible(true)
        
        self:SetPhysicsType(Actor.PhysicsType.Kinematic)
        
        self:SetPhysicsGroup(PhysicsGroup.CommanderUnitGroup)
        
        self:SetNextThink(Door.kThinkTime)
        
    end
    
    // In case door isn't placed in map
    if (self.weldHealth == nil) then
    
        self.weldHealth = Door.kDefaultHealth
        
    end
    
    self:SetMaxHealth(self.weldHealth)
    self:SetHealth(self.weldHealth)
    
    if (self.weldTime == nil) then
    
        self.weldTime = Door.kDefaultWeldTime
        
    end
    
    self.overrideUnlockTime = 0
    
    self.time = 0
    
    self.timeLastCommanderAction = 0
    
    self:SetIsAlive(true)
    
    self:SetState(Door.kState.Closed)    
end

function Door:OnCreate()
    LiveScriptActor.OnCreate(self)
    
    InitMixin(self, PathingMixin) 
    self:SetPathingFlags(Pathing.PolyFlag_NoBuild)
end

// Only hackable by marine commander
function Door:PerformActivation(techId, position, normal, commander)

    local success = nil
    local state = self:GetState()

    // Set success to false if action specifically not allowed
    if techId == kTechId.DoorOpen then
    
        if (state == Door.kState.Closed) then
    
            self:SetState(Door.kState.Open, commander)
            success = true
            
        else
            success = false
        end
        
    elseif techId == kTechId.DoorClose then
    
        if state == Door.kState.Opened then
        
            self:SetState(Door.kState.Close, commander)
            success = true
            
        else
            success = false
        end
        
    elseif techId == kTechId.DoorLock then
    
        if state == Door.kState.Closed then
        
            self:SetState(Door.kState.Lock, commander)
            success = true
            
            self:SetPathingFlags(Pathing.PolyFlag_Closed)
            
        else
            success = false
        end
        
    elseif techId == kTechId.DoorUnlock then
    
        if state == Door.kState.Locked then
        
            self:SetState(Door.kState.Unlock, commander)
            
            // Clear marine override so it doesn't lock on us again
            self.overrideUnlockTime = 0
            
            success = true
            self:ClearPathingFlags(Pathing.PolyFlag_Closed)
            
        else
            success = false            
        end
        
    end
    
    if success == false then
        self:PlaySound(Door.kInoperableSound)
    else
        self.timeLastCommanderAction = Shared.GetTime()        
    end
    
    return success

end

function Door:GetDescription()

    local doorName = GetDisplayNameForTechId(self:GetTechId())
    local doorDescription = doorName
    
    local state = self:GetState()
    
    if state == Door.kState.Locked then
        doorDescription = string.format("Locked %s", doorName)
    elseif state == Door.kState.LockDestroyed then
        doorDescription = string.format("Destroyed %s", doorName)
    end
    
    return doorDescription
    
end

function Door:GetTechAllowed(techId, techNode, player)

    local state = self:GetState()
    
    if techId == kTechId.DoorOpen then
        return state == Door.kState.Closed
    elseif techId == kTechId.DoorClose then
        return state == Door.kState.Opened
    elseif techId == kTechId.DoorLock then
        return (state ~= Door.kState.Locked) and (state ~= Door.kState.LockDestroyed)
    elseif techId == kTechId.DoorUnlock then
        return state == Door.kState.Locked
    end

    return true

end

function Door:GetTechButtons(techId, teamType)

    if(techId == kTechId.RootMenu) then   
        // $AS - Aliens do not get tech on doors they can just select them
        if not (teamType == kAlienTeamType) then
            return  {kTechId.DoorOpen, kTechId.DoorClose, kTechId.None, kTechId.None,
                     kTechId.DoorLock, kTechId.DoorUnlock, kTechId.None, kTechId.None }
        else            
            return  {kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                     kTechId.None, kTechId.None, kTechId.None, kTechId.None }
        end
        
    end
    
    return nil
    
end

// Set door state and play animation. If commander parameter plassed, 
// play door sound for that player as well.
function Door:SetState(state, commander)

    if(self.state ~= state) then
    
        self.state = state
        
        self:SetAnimation(Door.kStateAnim[ self.state ])
        
        if Server then
        
            local sound = Door.kStateSound[ self.state ]
            if sound ~= "" then
            
                self:PlaySound(sound)
                
                if commander ~= nil then
                    Server.PlayPrivateSound(commander, sound, nil, 1.0, commander:GetOrigin())
                end
                
            end
            
            // Clear override once locked again
            if self.state == Door.kState.Lock or self.state == Door.kState.Locked then
                self.overrideUnlockTime = 0
            end
            
        end
        
    end
    
end

function Door:GetState()
    return self.state
end

function Door:GetWeldTime()
    return self.weldTime
end

// If door is ready to be welded by buildbot right now, and in the future
function Door:GetCanBeWelded(entity)

    local canBeWeldedNow = (self.state == Door.kState.Closed)
    local canBeWeldedFuture = (self.state ~= Door.kState.Welded)
    
    return canBeWeldedNow, canBeWeldedFuture
    
end

// If we've been destroyed or not (only after we've been welded and smashed)
function Door:GetIsAliveOverride()
    return self.alive
end

function Door:GetCanBeUsed(player)
    return true
end

function Door:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    local state = self:GetState()
    if state == Door.kState.Welded then
        self:PlaySound(Door.kInoperableSound)
        
    // Unlock door temporarily (this won't work properly for MvM)
    elseif state == Door.kState.Locked and player:isa("Marine") then
    
        self:SetState(Door.kState.Unlock, player)
        self.overrideUnlockTime = Shared.GetTime()
        
    end
    
end

function Door:OnOverrideCanSetFire()
    return false
end

Shared.LinkClassToMap("Door", Door.kMapName, networkVars)
