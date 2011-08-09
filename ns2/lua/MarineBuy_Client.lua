//=============================================================================
//
// lua/MarineBuy_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// Specifies which and order of weapons to buy
// Jetpack removed until it is implemented.
local kWeaponIdList = {kTechId.Axe, kTechId.Pistol, kTechId.Rifle, kTechId.GrenadeLauncher, kTechId.Shotgun, kTechId.Flamethrower}//, kTechId.Jetpack}

local kBigIconIndices = {{0, 0}, {0, 1},{0, 2},{0, 3},{1, 0},{1, 1},{1, 2} }
    
// From marine_buy_icons. Add indices to get to unavailable and expensive versions
local kIconIndexToTechId = {
    kTechId.Axe, kTechId.Pistol, kTechId.Rifle, kTechId.GrenadeLauncher, kTechId.Shotgun, kTechId.Flamethrower, kTechId.Jetpack
}

// Number if icons in each row of Marine.kBuyMenuUpgradesTexture
local kUpgradeIconRowSize = 6

local kIconIndexToUpgradeId = {
    kTechId.Armor1, kTechId.Armor2, kTechId.Armor3,
    kTechId.RifleUpgrade, kTechId.NerveGas, kTechId.FlamethrowerAltTech
}

local kWeaponDescription = {
    "The Switch-Ax has replaced the knife as standard issue. The nomenclature \"2.Sec\" describes the elapsed time from deployment to burying it in someone's (or thing's) cranium. Some marines have also said the sound it makes from button push to lock sounds like \"two...Sec!\" In compact form, the blade's edge folds into a nanoscopic substratum which converts matter debris into an oily substance. The 2.Sec never sticks -- in fact, the more you use it, the better it works. The blade's edge is very slowly consumed as well. It's getting sharper while it hangs from your belt.",
    "P37 9MM Combat Pistol. This pistol is compact yet powerful and packs a punch. It has a laser-site which can be deployed as an alternate mode for increased accuracy (but slower firing rate). It features a unique palm print id scanner in the handle to make sure it's keyed only for your use.",
    "TSA standard issue rifle. This standby is an all-around versatile weapon at most ranges. While slightly heavier than previous models, it can still be effective in the field when you're low on ammo with a rifle butt.",
    "TSA rifle with grenade launcher attachment. Previous grenade launcher deployments left soldiers vulnerable to close combat, so grenades are now able to be outfitted onto the rifle. Use the regular grenades vs. structures or outfit it with nerve gas for use against breathing targets.",
    "The shotgun is the bane of skulks everywhere. While slightly limited in clip size, it has been tuned to be even more effective at closer ranges. Sneak up on something slimy and see if it has a chance to react. Answer: it won't. Enjoy, jarhead.",
    "The flamethrower is a new addition to the TSA load-out and was developed to battle the alien bacterial \"growth\" directly. It's main fire can be used to do medium damage to many adjacent targets. It's alternate firing is still under development by TSA scientists and will be unveiled \"when it's done, OKAY?\".",
    "This experimental jetpack technology allows its user to fly for short distances, get into vents and stay off the ground and away from snapping jaws.",
}

function GetIndexFromTechId(techId)

    for index, id in ipairs(kIconIndexToTechId) do
    
        if techId == id then
        
            return index
            
        end
        
    end
    
    Print("GetIndexFromTechId(%d) - Couldn't find icon.")
    
    return 0
    
end

function TechIdToWeaponIndex(techId)

    for index, id in ipairs(kIconIndexToTechId) do

        if techId == id then
        
            return index
            
        end
        
    end
   
    Print("TechIdToWeaponIndex(%d) - couldn't find weapon index for tech id.", techId)
    
    return 1
    
end

/**
 * Return atlas string for weapon icons (80x80)
 */
function MarineBuy_IconImage()
    return "marine_buy_icons"
end

/**
 * Return atlas string for big weapon picture (512x256)
 */
function MarineBuy_WeaponInfoImage()
    return "marine_buymenu"
end

function GetCurrentPrimaryWeaponTechId()

    local weapons = Client.GetLocalPlayer():GetHUDOrderedWeaponList()
    if table.count(weapons) > 0 then
    
        // Main weapon is our primary weapon - in the first slot
        return weapons[1]:GetTechId()
        
    end
    
    Print("GetCurrentPrimaryWeaponTechId(): Couldn't find current primary weapon.")
    
    return kTechId.None

end

/**
 * Get weapon id for current weapon (nebulously defined since there are 3 potentials?)
 */
function MarineBuy_GetCurrentWeapon()
    return TechIdToWeaponIndex(GetCurrentPrimaryWeaponTechId())
end

function DamageTypeToString(type)

    local damageString = ""

    if type == kDamageType.Light then
        damageString = "Light - reduced vs. armor"
    elseif type == kDamageType.Heavy then
        damageString = "Heavy - extra vs. armor"
    elseif type == kDamageType.Puncture then
        damageString = "Puncture - extra vs. players"
    elseif type == kDamageType.Structural then
        damageString = "Structural - double vs. structures"
    elseif type == kDamageType.Gas then
        damageString = "Gas - damages breathing targets only"
    elseif type == kDamageType.Biological then
        damageString = "Biological - damages living targets only"
    elseif type == kDamageType.StructuresOnly then
        damageString = "Hurts structures only"
    end
    
    return damageString
    
end

function GetWeaponInfoArray(techId)

    local t = {}
    
    table.insert(t, GetDisplayNameForTechId(techId))
    
    // Look up big icon indices
    local iconIndex = GetIndexFromTechId(techId)
    //Print("Returning big icon for %d => %d at %s", techId, iconIndex, table.tostring(kBigIconIndices[iconIndex]))
    table.insert(t, kBigIconIndices[iconIndex][1])
    table.insert(t, kBigIconIndices[iconIndex][2])
    
    table.insert(t, LookupTechData(techId, kTechDataCostKey, 0))
    
    // Description text
    table.insert(t, kWeaponDescription[TechIdToWeaponIndex(techId)])
    
    // Damage type explanation
    table.insert(t, DamageTypeToString(LookupTechData(techId, kTechDataDamageType, kDamageType.Normal)))
    
    // Ignore damage value, ammo type and ammo count for now
    table.insert(t, "")
    table.insert(t, "")
    table.insert(t, "")
    
    return t
    
end
    
/**
 * Return information about the selected weapon id in 1-d array
 *
 * Weapon name  - String
 * Big weapon image x offset - int
 * Big weapon image y offset - int
 * Cost - int
 * Description - String
 * Damage Type - String
 * Damage Value - String
 * Ammo type - String
 * Ammo count - int
 */
function MarineBuy_GetInfoForWeapon(idx)
    local t = GetWeaponInfoArray(kWeaponIdList[idx])
    //Print("MarineBuy_GetInfoForWeapon(%d): %s", idx, table.tostring(t))
    return t
end

function GetWeaponArray(techIdArray)

    local t = {}
    
    for index, id in ipairs(techIdArray) do
    
        // Name, cost, weapon index
        table.insert(t, GetDisplayNameForTechId(id))
        table.insert(t, TechIdToWeaponIndex(id))
        table.insert(t, LookupTechData(id, kTechDataCostKey, 0))        
        
        // Researched
        local researched = false
        local techNode = GetTechTree():GetTechNode(id)
        
        ASSERT(techNode ~= nil, "GetWeaponArray(" .. id .. "): Couldn't find techNode for " .. GetDisplayNameForTechId(id))
        if techNode ~= nil then
            researched = techNode:GetAvailable()
        end

        table.insert(t, researched)
        
        // normal
        local iconIndex = math.max(GetIndexFromTechId(id) - 1, 0)
        table.insert(t, 0)
        table.insert(t, iconIndex)

        // expensive
        table.insert(t, 1)
        table.insert(t, iconIndex)

        // unresearched
        table.insert(t, 2)
        table.insert(t, iconIndex)
    
    end
    
    return t
    
end

/**
 * Return information about the available weapons in a linear array
 * Name - string (for tooltips?)
 * weaponIdx - int (internal lua id number for weapon)
 * cost - int
 * researched - Boolean
 * normal tex x - int
 * normal tex y - int
 * expensive tex x - int
 * expensive tex y - int
 * unresearched tex x - int
 * unresearched tex y - int
 */
function MarineBuy_GetAvailableWeapons()
    local t = GetWeaponArray(kWeaponIdList)
    //Print("MarineBuy_GetAvailableWeapons(): %s", table.tostring(t))
    return t
end

/**
 * Return information about the available weapons in a linear array
 * Name - string (for tooltips?)
 * normal tex x - int
 * normal tex y - int
 */
function MarineBuy_GetEquippedWeapons()

    local t = {}
    
    local items = GetChildEntities(Client.GetLocalPlayer(), "ScriptActor")
    
    for index, item in ipairs(items) do
    
        local techId = item:GetTechId()
        local itemName = GetDisplayNameForTechId(techId)
        table.insert(t, itemName)    
        
        local index = TechIdToWeaponIndex(techId)
        table.insert(t, 0)
        table.insert(t, index - 1)

    end
    
    return t
    
end

function GetAddonArray(addons)

    local t = {}
    
    for index, addonId in ipairs(addons) do
    
        table.insert(t, GetDisplayNameForTechId(addOnId))
        
        table.insert(t, GetTechTree():GetResearchProgressForBuyNode(addOnId))
        
        table.insert(t, 0)
        
        // TODO: Look up icon here
        table.insert(t, 0)
        
    end
    
    return t
    
end

/**
 * Return information about the available weapons in a linear array
 * Name - string (for tooltips?)
 * research amount - float [0-1]
 * tex x - int
 * tex y - int
 */
function MarineBuy_GetAvailableUpgradesFor(weaponItem)        
    return GetAddonArray(GetTechTree():GetAddOnsForTechId(techId))
end

/**
 * Called when upgrade is purchased
 */
function MarineBuy_BuyUpgradeFor(weaponItem, upgradeIndex)
    Print("MarineBuy_BuyUpgradeFor(%d, %d)", weaponItem, upgradeIndex)
    //Client.ConsoleCommand("buy " .. tostring(techId))
end

/**
 * Called when weapon is purchased
 */
function MarineBuy_BuyWeapon(idx)

    local techId = kWeaponIdList[idx]
    
    // Don't allow buying basic weapons so they can't be spammed all over the server
    if techId ~= kTechId.Axe and techId ~= kTechId.Pistol and techId ~= kTechId.Rifle then
        Client.ConsoleCommand("buy " .. tostring(techId))
    end
    
end

/**
 * User pressed close button
 */
function MarineBuy_Close()

    // Close menu
    local player = Client.GetLocalPlayer()
    if player then
        player:CloseMenu(kClassFlashIndex)
    end
    
end