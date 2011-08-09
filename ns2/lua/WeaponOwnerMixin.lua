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

function WeaponOwnerMixin.__prepareclass(toClass)
    
    ASSERT(toClass.networkVars ~= nil, "WeaponOwnerMixin expects the class to have network fields")
    
    local addNetworkFields =
    {
        updateWeapons   = "boolean",
    }
    
    for k, v in pairs(addNetworkFields) do
        toClass.networkVars[k] = v
    end
    
end

function WeaponOwnerMixin:__initmixin()
    self.updateWeapons = true
end

function WeaponOwnerMixin:SetUpdateWeapons(updates)
    self.updateWeapons = updates
end
AddFunctionContract(WeaponOwnerMixin.SetUpdateWeapons, { Arguments = { "Entity", "boolean" }, Returns = { } })

function WeaponOwnerMixin:UpdateWeapons(input)

    // Don't update weapon if set to false (commander mode)
    if self.updateWeapons then
        
        // Call ProcessMove on all our weapons so they can update properly
        for index, weapon in ipairs(self:GetHUDOrderedWeaponList()) do
            weapon:OnProcessMove(self, input)
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
    
    self.hudOrderedWeaponList = { }
    for i = 0, self:GetNumChildren() - 1 do
        local currentChild = self:GetChildAtIndex(i)
        if currentChild:isa("Weapon") then
            table.insert(self.hudOrderedWeaponList, currentChild)
        end
    end

    table.sort(self.hudOrderedWeaponList, WeaponSorter)
    
    return self.hudOrderedWeaponList
    
end
AddFunctionContract(WeaponOwnerMixin.GetHUDOrderedWeaponList, { Arguments = { "Entity" }, Returns = { "table" } })

// Returns true if we switched to weapon or if weapon is already active. Returns false if we 
// don't have that weapon.
function WeaponOwnerMixin:SetActiveWeapon(weaponMapName)

    local weaponList = self:GetHUDOrderedWeaponList()
    
    for index, weapon in ipairs(weaponList) do
    
        local mapName = weapon:GetMapName()

        if (mapName == weaponMapName) then
        
            local newWeapon = weapon
            local activeWeapon = self:GetActiveWeapon()
            
            if (activeWeapon == nil or activeWeapon:GetMapName() ~= weaponMapName) then
            
                local previousWeaponName = ""
                
                if activeWeapon then
                
                    activeWeapon:OnHolster(self)
                    activeWeapon:SetIsVisible(false)
                    previousWeaponName = activeWeapon:GetMapName()
                    
                end

                // Set active first so proper anim plays
                self.activeWeaponIndex = index
                
                newWeapon:SetIsVisible(true)
                
                newWeapon:OnDraw(self, previousWeaponName)

                return true
                
            end
            
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

    local activeWeapon = nil
    
    if(self.activeWeaponIndex ~= 0) then
    
        local weapons = self:GetHUDOrderedWeaponList()
        
        if self.activeWeaponIndex <= table.count(weapons) then
            activeWeapon = weapons[self.activeWeaponIndex]
        end
        
    end
    
    return activeWeapon
    
end
AddFunctionContract(WeaponOwnerMixin.GetActiveWeapon, { Arguments = { "Entity" }, Returns = { { "Weapon", "nil" } } })

function WeaponOwnerMixin:GetActiveWeaponIndex()

    return self.activeWeaponIndex

end
AddFunctionContract(WeaponOwnerMixin.GetActiveWeaponIndex, { Arguments = { "Entity" }, Returns = { "number" } })

// SwitchWeapon or choose option from sayings menu if open weaponindex starts at 1.
function WeaponOwnerMixin:SwitchWeapon(weaponIndex)

    local success = false
    
    if( not self:GetIsCommander()) then
        
        local weaponList = self:GetHUDOrderedWeaponList()
        
        if(weaponIndex >= 1 and weaponIndex <= table.maxn(weaponList)) then

            success = self:SetActiveWeapon(weaponList[weaponIndex]:GetMapName())
            
            self.timeOfLastWeaponSwitch = Shared.GetTime()
            
        end
        
    end
    
    return success
    
end
AddFunctionContract(WeaponOwnerMixin.SwitchWeapon, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

// Checks to see if self already has a weapon with the passed in map name.
function WeaponOwnerMixin:GetHasWeapon(weaponMapName)

    local weapons = self:GetHUDOrderedWeaponList()
    for index, weapon in ipairs(weapons) do
        if weapon:GetMapName() == weaponMapName then
            return true
        end
    end
    
    return false

end
AddFunctionContract(WeaponOwnerMixin.GetHasWeapon, { Arguments = { "Entity", "string" }, Returns = { "boolean" } })