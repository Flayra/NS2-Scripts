// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Armory_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// A Flash buy menu for marines to purchase weapons and armory from.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Tech ids that player can buy
local armoryWeapons = { kTechId.Rifle, kTechId.Shotgun, kTechId.Pistol, kTechId.Flamethrower }
local armoryArmor = { kTechId.Jetpack, kTechId.Exoskeleton }

// Visual categories, in order
local categories = { armoryWeapons, armoryArmor }

// Upgrades for each thing player can buy
local upgrades =    {  
                    // TODO: Fix this up
                    {kTechId.GrenadeLauncher, {kTechId.RifleUpgradeTech, kTechId.NerveGasTech}}, 
                    {kTechId.Minigun, {kTechId.None}},
                    {kTechId.Flamethrower, {kTechId.FlamethrowerAltTech}},
                    {kTechId.Jetpack, {kTechId.JetpackFuelTech}},
                    }

function ArmoryUI_MenuImage()
    return "marine_buymenu"
end

function ArmoryUI_MenuUpgradesImage()
    return "marine_buymenu_upgrades"
end

function ArmoryUI_GetCategoryCount()
    return table.maxn(categories)
end

function ArmoryUI_GetCategoryName(categoryIdx)
    if(categoryIdx == 1) then
        return "Weapons"
    end
    return "Armor"
end

function ArmoryUI_GetCategoryItemCount(categoryIdx)
    return table.maxn(categories[categoryIdx])
end

function ArmoryUI_GetItemName(categoryIdx, itemIdx)

    local techId = categories[categoryIdx][itemIdx]
    return GetDisplayNameForTechId(techId)
    
end

function ArmoryUI_GetItemCost(categoryIdx, itemIdx)

    local techId = categories[categoryIdx][itemIdx]
    return LookupTechData(techId, kTechDataCostKey, 0)
    
end

function GetResearchPercentage(techId)

    local techNode = GetTechTree():GetTechNode(techId)
    
    if(techNode ~= nil) then
    
        if(techNode:GetAvailable()) then
            return 1
        elseif(techNode:GetResearching()) then
            return techNode:GetResearchProgress()
        end    
        
    end
    
    return 0
    
end

// return 0 - 1, assuming 0 will show "unavailable"
function ArmoryUI_GetItemResearchPct(categoryIdx, itemIdx)

    local techId = categories[categoryIdx][itemIdx]
    return GetResearchPercentage(techId)
    
end

// return 0 - 1
function ArmoryUI_GetItemXPos(categoryIdx, itemIdx)
    // TODO:
    return 0
end

// return 0 - 1
function ArmoryUI_GetItemYPos(categoryIdx, itemIdx)
    // TODO:
    return 0
end

function GetUpgrades(techId)
    // TODO:
end

// return 0 - 1
function ArmoryUI_GetItemUpgradeCount(categoryIdx, itemIdx)

    local techId = categories[categoryIdx][itemIdx]
    local upgrades = GetUpgrades(techId)
    
    if(upgrades ~= nil) then
        return table.maxn(upgrades)
    end
    
    return 0    
    
end

// Assuming 0 will NOT show upgrade
function ArmoryUI_GetItemUpgradeResearchPct(categoryIdx, itemIdx, upgradeIdx)

    local hostTechId = categories[categoryIdx][itemIdx]
    local upgrades = GetUpgrades(hostTechId)
    local upgradeTechId = upgrades[upgradeIdx]
    
    return GetResearchPercentage(upgradeTechId)

end

function ArmoryUI_GetItemUpgradeXPos(categoryIdx, itemIdx, upgradeIdx)
    // TODO: 
    return 0
end

function ArmoryUI_GetItemUpgradeYPos(categoryIdx, itemIdx, upgradeIdx)
    // TODO: 
    return 0
end

// Not yet implemented
function ArmoryUI_GetItemUpgradeTooltip(categoryIdx, itemIdx, upgradeIdx)

    local hostTechId = categories[categoryIdx][itemIdx]
    local upgrades = GetUpgrades(hostTechId)
    local upgradeTechId = upgrades[upgradeIdx]
    return GetDisplayNameForTechId(upgradeTechId)
    
end

function ArmoryUI_GetItemTooltip(categoryIdx, itemIdx)

    local techId = categories[categoryIdx][itemIdx]
    return GetDisplayNameForTechId(techId)

end
 
function ArmoryUI_PurchaseItem(catItemArray)

    local i = 0
    
    while catItemArray[tostring(i)] ~= nil do

        local category = catItemArray[tostring(i)] + 1
        local itemIndex = catItemArray[tostring(i + 1)] + 1
        local techId = categories[category][itemIndex]
        
        Client.ConsoleCommand("buy " .. tostring(techId))
    
        i = i + 2
        
    end
    
    ArmoryUI_Close()

end

function ArmoryUI_Close()

    Client.SetMouseVisible(false)
    Client.SetMouseCaptured(true)
    Client.SetMouseClipped(false)
    
    local player = Client.GetLocalPlayer()
    RemoveFlashPlayer(kClassFlashIndex)
    
end

function Armory_Debug()

    // Draw armory points
    
    local indexToUseOrigin = {
        Vector(Armory.kResupplyUseRange, 0, 0), 
        Vector(0, 0, Armory.kResupplyUseRange),
        Vector(-Armory.kResupplyUseRange, 0, 0),
        Vector(0, 0, -Armory.kResupplyUseRange)
    }
    
    local indexToColor = {
        Vector(1, 0, 0),
        Vector(0, 1, 0),
        Vector(0, 0, 1),
        Vector(1, 1, 1)
    }
    
    function isaArmory(entity) return entity:isa("Armory") end
    
    for index, armory in ientitylist(Shared.GetEntitiesWithClassname("Armory")) do
    
        local startPoint = armory:GetOrigin()
        
        for loop = 1, 4 do
            
            local endPoint = startPoint + indexToUseOrigin[loop]
            local color = indexToColor[loop]
            DebugLine(startPoint, endPoint, .2, color.x, color.y, color.z, 1)
            
        end
        
    end
    
end

function Armory:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    if self:GetIsBuilt() and self:GetIsActive() then

        if not Client.GetMouseVisible() and (Client.GetLocalPlayer() == player) then    
        
            GetFlashPlayer(kClassFlashIndex):Load(Armory.kBuyMenuFlash)
            GetFlashPlayer(kClassFlashIndex):SetBackgroundOpacity(0)
            
            player.showingBuyMenu = true
            
            Client.SetCursor("ui/Cursor_MenuDefault.dds")
            
            Client.SetMouseVisible(true)
            Client.SetMouseCaptured(false)
            Client.SetMouseClipped(true)
    
            // Play looping "active" sound while logged in
            Shared.PlayPrivateSound(player, Armory.kResupplySound, player, 1.0, Vector(0, 0, 0))
            
        end
        
    end
    
end