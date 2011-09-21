// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\WeaponOwnerMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

WeaponOwnerMixin = { }
WeaponOwnerMixin.type = "WeaponOwner"

WeaponOwnerMixin.optionalCallbacks =
{
    OnWeaponAdded = "Will be called right after a weapon is added with the weapon as the only parameter."
}

function WeaponOwnerMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "WeaponOwnerMixin expects the class to have network fields")
    
    toClass.networkVars.updateWeapons = "boolean"
    
    toClass.networkVars.activeWeaponId = "entityid"
    
    toClass.networkVars.timeOfLastWeaponSwitch = "float"
    
end

function WeaponOwnerMixin:__initmixin()

    self.updateWeapons = true
    self.activeWeaponId = Entity.invalidId
    self.timeOfLastWeaponSwitch = 0
    
end

function WeaponOwnerMixin:SetUpdateWeapons(updates)
    self.updateWeapons = updates
end
AddFunctionContract(WeaponOwnerMixin.SetUpdateWeapons, { Arguments = { "Entity", "boolean" }, Returns = { } })

function WeaponOwnerMixin:UpdateWeapons(input)

    // Don't update weapon if set to false (commander mode)
    if self.updateWeapons then
        
        local activeWeapon = self:GetActiveWeapon()
        // Call ProcessMove on only the active weapon.
        if activeWeapon then
            activeWeapon:OnProcessMove(self, input)
        end
        
    end
        
end
AddFunctionContract(WeaponOwnerMixin.UpdateWeapons, { Arguments = { "Entity", "Move" }, Returns = { } })

/**
 * Sorter used in WeaponOwnerMixin:GetHUDOrderedWeaponList().
 */
local function WeaponSorter(weapon1, weapon2)
    return weapon2:GetHUDSlot() > weapon1:GetHUDSlot()
end

function WeaponOwnerMixin:GetHUDOrderedWeaponList()

    PROFILE("WeaponOwnerMixin:GetHUDOrderedWeaponList")
    
    local hudOrderedWeaponList = { }
    for i, child in ientitychildren(self, "Weapon") do
        table.insert(hudOrderedWeaponList, child)
    end

    table.sort(hudOrderedWeaponList, WeaponSorter)
    
    return hudOrderedWeaponList
    
end
AddFunctionContract(WeaponOwnerMixin.GetHUDOrderedWeaponList, { Arguments = { "Entity" }, Returns = { "table" } })

// Returns true if we switched to weapon or if weapon is already active. Returns false if we 
// don't have that weapon.
function WeaponOwnerMixin:SetActiveWeapon(weaponMapName)

    local foundWeapon = nil
    for i, child in ientitychildren(self, "Weapon") do
    
        if child:GetMapName() == weaponMapName then
            foundWeapon = child
            break
        end
        
    end
    
    if foundWeapon then
        
        local newWeapon = foundWeapon
        local activeWeapon = self:GetActiveWeapon()
        
        if activeWeapon == nil or activeWeapon:GetMapName() ~= weaponMapName then
        
            local previousWeaponName = ""
            
            if activeWeapon then
            
                activeWeapon:OnHolster(self)
                activeWeapon:SetIsVisible(false)
                previousWeaponName = activeWeapon:GetMapName()
                
            end

            // Set active first so proper anim plays
            self.activeWeaponId = newWeapon:GetId()
            
            newWeapon:SetIsVisible(true)
            
            newWeapon:OnDraw(self, previousWeaponName)
            
            self.timeOfLastWeaponSwitch = Shared.GetTime()

            return true
            
        end
        
    end
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon ~= nil and activeWeapon:GetMapName() == weaponMapName then
        return true
    end
    
    Print("%s:SetActiveWeapon(%s) failed", self:GetClassName(), weaponMapName)
    
    return false

end
AddFunctionContract(WeaponOwnerMixin.SetActiveWeapon, { Arguments = { "Entity", "string" }, Returns = { "boolean" } })

function WeaponOwnerMixin:GetActiveWeapon()
    return Shared.GetEntity(self.activeWeaponId)
end
AddFunctionContract(WeaponOwnerMixin.GetActiveWeapon, { Arguments = { "Entity" }, Returns = { { "Weapon", "nil" } } })

function WeaponOwnerMixin:GetTimeOfLastWeaponSwitch()
    return self.timeOfLastWeaponSwitch
end
AddFunctionContract(WeaponOwnerMixin.GetTimeOfLastWeaponSwitch, { Arguments = { "Entity" }, Returns = { "number" } })

function WeaponOwnerMixin:SwitchWeapon(hudSlot)

    local success = false
    
    local foundWeapon = nil
    for i, child in ientitychildren(self, "Weapon") do
    
        if child:GetHUDSlot() == hudSlot then
            foundWeapon = child
            break
        end
        
    end
    
    if foundWeapon then
        success = self:SetActiveWeapon(foundWeapon:GetMapName())
    end
    
    return success
    
end
AddFunctionContract(WeaponOwnerMixin.SwitchWeapon, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

function WeaponOwnerMixin:SelectNextWeaponInDirection(direction)

    local weaponList = self:GetHUDOrderedWeaponList()
    local activeWeapon = self:GetActiveWeapon()
    local activeIndex = nil
    for i, weapon in ipairs(weaponList) do
    
        if weapon == activeWeapon then
            activeIndex = i
            break
        end

    end
    
    local numWeapons = table.count(weaponList)
    if numWeapons > 0 and activeIndex then
    
        local newIndex = activeIndex + direction
        // Handle wrap around.
        if newIndex > numWeapons then
            newIndex = 1
        elseif newIndex < 1 then
            newIndex = numWeapons
        end
        
        self:SetActiveWeapon(weaponList[newIndex]:GetMapName())
        
    end
    
end
AddFunctionContract(WeaponOwnerMixin.SelectNextWeaponInDirection, { Arguments = { "Entity", "number" }, Returns = { } })

function WeaponOwnerMixin:GetActiveWeaponName()

    local activeWeaponName = ""
    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon ~= nil then
        activeWeaponName = activeWeapon:GetClassName()
    end
    
    return activeWeaponName
    
end
AddFunctionContract(WeaponOwnerMixin.GetActiveWeaponName, { Arguments = { "Entity" }, Returns = { "string" } })

/**
 * Checks to see if self already has a weapon with the passed in map name.
 * Returns this weapon if it exists, nil otherwise.
 */
function WeaponOwnerMixin:GetWeapon(weaponMapName)

    local found = nil
    for i, child in ientitychildren(self, "Weapon") do
    
        if child:GetMapName() == weaponMapName then
            found = child
            break
        end
    
    end
    
    return found

end
AddFunctionContract(WeaponOwnerMixin.GetWeapon, { Arguments = { "Entity", "string" }, Returns = { { "Weapon", "nil" } } })

/**
 * Checks to see if self already has a weapon in the passed in HUD slot.
 * Returns this weapon if it exists, nil otherwise.
 */
function WeaponOwnerMixin:GetWeaponInHUDSlot(slot)

    for i, child in ientitychildren(self, "Weapon") do
    
        if child:GetHUDSlot() == slot then
            return child
        end
    
    end
    
    return nil
    
end
AddFunctionContract(WeaponOwnerMixin.GetWeaponInHUDSlot, { Arguments = { "Entity", "number" }, Returns = { { "Weapon", "nil" } } })

function WeaponOwnerMixin:AddWeapon(weapon, setActive)

    assert(weapon:GetParent() ~= self)

    // Remove any existing weapon that shares the HUD slot to the
    // incoming weapon.
    local hasWeapon = self:GetWeaponInHUDSlot(weapon:GetHUDSlot())
    if hasWeapon then
        local success = self:Drop(hasWeapon, true)
        assert(success == true)
    end
    
    assert(self:GetWeaponInHUDSlot(weapon:GetHUDSlot()) == nil)

    weapon:SetParent(self)
    
    // The weapon no longer belongs to the world once a weapon owner has it.
    if Server then
        weapon:SetWeaponWorldState(false)
    end
    
    if setActive then
        self:SetActiveWeapon(weapon:GetMapName())
    end
    
    if self.OnWeaponAdded then
        self:OnWeaponAdded(weapon)
    end
    
end
AddFunctionContract(WeaponOwnerMixin.AddWeapon, { Arguments = { "Entity", "Weapon", "boolean" }, Returns = { } })

function WeaponOwnerMixin:RemoveWeapon(weapon)

    assert(weapon:GetParent() == self)
    
    // Switch weapons if we're dropping our current weapon
    local activeWeapon = self:GetActiveWeapon()
    local removingActive = activeWeapon ~= nil and weapon == activeWeapon
    
    weapon:SetParent(nil)
    
    if removingActive then
        self.activeWeaponId = Entity.invalidId
        self:SelectNextWeaponInDirection(1)
    end
    
end
AddFunctionContract(WeaponOwnerMixin.RemoveWeapon, { Arguments = { "Entity", "Weapon" }, Returns = { } })

function WeaponOwnerMixin:DestroyWeapons()

    self.activeWeaponId = Entity.invalidId
    
    local allWeapons = { }
    for i, child in ientitychildren(self, "Weapon") do
        table.insert(allWeapons, child)
    end
    
    for i, weapon in ipairs(allWeapons) do
        DestroyEntity(weapon)
    end

end
AddFunctionContract(WeaponOwnerMixin.DestroyWeapons, { Arguments = { "Entity" }, Returns = { } })