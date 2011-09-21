//=============================================================================
//
// lua/AlienBuy_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================
Script.Load("lua/InterfaceSounds_Client.lua")
Script.Load("lua/AlienUpgrades_Client.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/Gorge.lua")
Script.Load("lua/Lerk.lua")
Script.Load("lua/Fade.lua")
Script.Load("lua/Onos.lua")

// Indices passed in from flash
local indexToAlienTechIdTable = {kTechId.Fade, kTechId.Gorge, kTechId.Lerk, kTechId.Onos, kTechId.Skulk}

local kAlienBuyMenuSounds = { Open = "sound/ns2.fev/alien/common/alien_menu/open_menu",
                              Close = "sound/ns2.fev/alien/common/alien_menu/close_menu",
                              Evolve = "sound/ns2.fev/alien/common/alien_menu/evolve",
                              BuyUpgrade = "sound/ns2.fev/alien/common/alien_menu/buy_upgrade",
                              SellUpgrade = "sound/ns2.fev/alien/common/alien_menu/sell_upgrade",
                              Hover = "sound/ns2.fev/alien/common/alien_menu/hover",
                              SelectSkulk = "sound/ns2.fev/alien/common/alien_menu/skulk_select",
                              SelectFade = "sound/ns2.fev/alien/common/alien_menu/fade_select",
                              SelectGorge = "sound/ns2.fev/alien/common/alien_menu/gorge_select",
                              SelectOnos = "sound/ns2.fev/alien/common/alien_menu/onos_select",
                              SelectLerk = "sound/ns2.fev/alien/common/alien_menu/lerk_select" }

for i, soundAsset in pairs(kAlienBuyMenuSounds) do
    Client.PrecacheLocalSound(soundAsset)
end

function IndexToAlienTechId(index)

    if index >= 1 and index <= table.count(indexToAlienTechIdTable) then
        return indexToAlienTechIdTable[index]
    else    
        Print("IndexToAlienTechId(%d) - invalid id passed", index)
        return kTechId.None
    end
    
end

function AlienTechIdToIndex(techId)
    for index, alienTechId in ipairs(indexToAlienTechIdTable) do
        if techId == alienTechId then
            return index
        end
    end
    
    ASSERT(false, "AlienTechIdToIndex(" .. ToString(techId) .. ") - invalid tech id passed")
    return 0
    
end

/**
 * Return 1-d array of name, hp, ap, and cost for this class index
 */
function AlienBuy_GetClassStats(idx)

    if idx == nil then
        Print("AlienBuy_GetClassStats(nil) called")
    end
    
    // name, hp, ap, cost
    local techId = IndexToAlienTechId(idx)
    
    if techId == kTechId.Fade then
        return {"Fade", Fade.kHealth, Fade.kArmor, kFadeCost}
    elseif techId == kTechId.Gorge then
        return {"Gorge", Gorge.kHealth, Gorge.kArmor, kGorgeCost}
    elseif techId == kTechId.Lerk then
        return {"Lerk", Lerk.kHealth, Lerk.kArmor, kLerkCost}
    elseif techId == kTechId.Onos then
        return {"Onos", Onos.kHealth, Onos.kArmor, kOnosCost}
    else
        return {"Skulk", Skulk.kHealth, Skulk.kArmor, kSkulkCost}
    end   
    
end

// iconx, icony, name, tooltip, research, cost
function GetUnpurchasedUpgradeInfoArray(techIdTable)

    local t = {}
    
    for index, techId in ipairs(techIdTable) do
    
        local iconX, iconY = GetMaterialXYOffset(techId, false)
        
        if iconX and iconY then
        
            table.insert(t, iconX)
            table.insert(t, iconY)
            
            table.insert(t, GetDisplayNameForTechId(techId, string.format("<name not found - %s>", EnumToString(kTechId, techId))))
            
            table.insert(t, GetDisplayNameForTechId(techId))
            
            table.insert(t, GetTechTree():GetResearchProgressForNode(techId))
            
            table.insert(t, LookupTechData(techId, kTechDataCostKey, 0))
            
        end
        
    end
    
    return t
    
end

function GetUnpurchasedTechIds(techId)

    // Get list of potential upgrades for lifeform. These are tech nodes with
    // "addOnTechId" set to this tech id.
    local addOnUpgrades = {}
    
    local player = Client.GetLocalPlayer()
    local techTree = GetTechTree()
    
    if techTree ~= nil then
    
        // Use upgrades for our lifeform, plus global upgrades 
        addOnUpgrades = techTree:GetAddOnsForTechId(techId)
        
        table.copy(techTree:GetAddOnsForTechId(kTechId.AllAliens), addOnUpgrades, true)        
        
        // If we've already purchased it, or if it's not available, remove it. Iterate through a different
        // table as we'll be changing it as we go.
        local addOnCopy = {}
        table.copy(addOnUpgrades, addOnCopy)

        for key, value in pairs(addOnCopy) do
        
            local hasTech = player:GetHasUpgrade(value)
            local techNode = techTree:GetTechNode(value)
            local canPurchase = (techNode and techNode:GetIsBuy() and techNode:GetAvailable())
            
            if hasTech or not canPurchase then
            
                table.removevalue(addOnUpgrades, value)
                
            end
            
        end
        
    end
    
    return addOnUpgrades
    
end

/**
 * Return 1-d array of all unpurchased upgrades for this class index
 * Format is x icon offset, y icon offset, name, tooltip,
 * research pct [0.0 - 1.0], and cost
 */
function AlienBuy_GetUnpurchasedUpgrades(idx)
    if idx == nil then
        Print("AlienBuy_GetUnpurchasedUpgrades(nil) called")
        return {}
    end
    
    return GetUnpurchasedUpgradeInfoArray(GetUnpurchasedTechIds(IndexToAlienTechId(idx)))   
end

function GetPurchasedUpgradeInfoArray(techIdTable)

    local t = {}
    
    for index, techId in ipairs(techIdTable) do

        local iconX, iconY = GetMaterialXYOffset(techId, false)
        if iconX and iconY then
        
            table.insert(t, iconX)
            table.insert(t, iconY)
            table.insert(t, GetDisplayNameForTechId(techId, string.format("<not found - %s>", EnumToString(kTechId, techId))))
            table.insert(t, GetTooltipInfoText(techId))
            
        else
        
            Print("GetPurchasedUpgradeInfoArray():GetAlienUpgradeIconXY(%s): Couldn't find upgrade icon.", ToString(techId))
            
        end
    end
    
    return t
    
end

/**
 * Filter out tech Ids that don't apply to this specific Alien or all Aliens.
 */
local function FilterInvalidUpgradesForPlayer(player, forAlienTechId)

    local techIdTable = player:GetUpgrades()
    local techTree = GetTechTree()
    // We can't check if there is no tech tree, assume everything is ok.
    if not techTree then
        return techIdTable
    end
    
    local validAddons = techTree:GetAddOnsForTechId(forAlienTechId)
    table.copy(techTree:GetAddOnsForTechId(kTechId.AllAliens), validAddons, true)  

    local validIds = { }
    for index, upgradeTechId in ipairs(techIdTable) do
    
        if table.contains(validAddons, upgradeTechId) then
            table.insert(validIds, upgradeTechId)
        end
    
    end
    
    return validIds

end

/**
 * Return 1-d array of all purchased upgrades for this class index
 * Format is x icon offset, y icon offset, and name
 */
function AlienBuy_GetPurchasedUpgrades(idx)

    local player = Client.GetLocalPlayer()
    return GetPurchasedUpgradeInfoArray(FilterInvalidUpgradesForPlayer(player, IndexToAlienTechId(idx)))
    
end

function PurchaseTechs(purchaseIds)

    ASSERT(purchaseIds)
    ASSERT(table.count(purchaseIds) > 0)
    
    local player = Client.GetLocalPlayer()
    
    local buyCommand = "buy"
    local buyAllowed = true
    local totalCost = 0
    
    for i, purchaseId in ipairs(purchaseIds) do
    
        local techNode = GetTechTree():GetTechNode(purchaseId)
        
        if techNode ~= nil then
        
            if techNode:GetAvailable() then
                totalCost = totalCost + techNode:GetCost()
                buyCommand = buyCommand .. " " .. tostring(purchaseId)
            else
                buyAllowed = false
                break
            end
            
        else
        
            Print("PurchaseTechs(): Couldn't find tech node %d", purchaseId)
            buyAllowed = false
            break
            
        end
        
    end
    
    if buyAllowed then
        if totalCost <= player:GetResources() then
            Client.ConsoleCommand(buyCommand)
        else
            Shared.PlayPrivateSound(player, player:GetNotEnoughResourcesSound(), player, 1.0, Vector(0, 0, 0))
        end
    end

end

/**
 * Pass in a table describing what should be purchased. The table has the following format:
 * Type = "Alien" or "Upgrade"
 * Alien = "Skulk", "Lerk", etc
 * UpgradeIndex = Only needed when purchasing an upgrade, number index for the upgrade
 */
function AlienBuy_Purchase(purchaseTable)

    ASSERT(type(purchaseTable) == "table")
    
    local purchaseTechIds = { }
    
    for i, purchase in ipairs(purchaseTable) do

        if purchase.Type == "Alien" then
            table.insert(purchaseTechIds, IndexToAlienTechId(purchase.Alien))
        elseif purchase.Type == "Upgrade" then
            local unpurchasedIds = GetUnpurchasedTechIds(IndexToAlienTechId(purchase.Alien))
            table.insert(purchaseTechIds, unpurchasedIds[purchase.UpgradeIndex])
        end
    
    end
    
    PurchaseTechs(purchaseTechIds)

end

function GetAlienTechNode(idx, isAlienIndex)

    local techNode = nil
    
    local techId = idx
    
    if isAlienIndex then
        techId = IndexToAlienTechId(idx)
    end
    
    local techTree = GetTechTree()
    
    if techTree ~= nil then
        techNode = techTree:GetTechNode(techId)
    end
    
    return techNode
    
end

/**
 * Return true if alien type is researched, false otherwise
 */
function AlienBuy_IsAlienResearched(alienType)
    local techNode = GetAlienTechNode(alienType, true)
    return (techNode ~= nil) and techNode:GetAvailable()    
end

/**
 * Return the research progress (0-1) of the passed in alien type.
 * Returns 0 if the passed in alien type didn't have a tech node.
 */
function AlienBuy_GetAlienResearchProgress(alienType)

    local techNode = GetAlienTechNode(alienType, true)
    if techNode then
        return techNode:GetPrereqResearchProgress()
    end
    return 0
    
end

/**
 * Return cost for the base alien type
 */
function AlienBuy_GetAlienCost(alienType)

    local cost = nil
    
    local techNode = GetAlienTechNode(alienType, true)
    if techNode ~= nil then
        cost = techNode:GetCost()
    end
    
    if cost == nil then
        cost = 0
    end
    
    return cost
    
end

/**
 * Return current alien type
 */
function AlienBuy_GetCurrentAlien()
    local player = Client.GetLocalPlayer()
    local techId = player:GetTechId()
    local index = AlienTechIdToIndex(techId)
    
    ASSERT(index >= 1 and index <= table.count(indexToAlienTechIdTable), "AlienBuy_GetCurrentAlien(" .. ToString(techId) .. "): returning invalid index " .. ToString(index) .. " for " .. SafeClassName(player))
    
    return index
    
end

function AlienBuy_OnMouseOver()

    Shared.PlaySound(nil, kAlienBuyMenuSounds.Hover)

end

function AlienBuy_OnOpen()

    Shared.PlaySound(nil, kAlienBuyMenuSounds.Open)

end

function AlienBuy_OnClose()

    Shared.PlaySound(nil, kAlienBuyMenuSounds.Close)

end

function AlienBuy_OnPurchase()

    Shared.PlaySound(nil, kAlienBuyMenuSounds.Evolve)

end

function AlienBuy_OnSelectAlien(type)

    local assetName = ""
    if type == "Skulk" then
        assetName = kAlienBuyMenuSounds.SelectSkulk
    elseif type == "Gorge" then
        assetName = kAlienBuyMenuSounds.SelectGorge
    elseif type == "Lerk" then
        assetName = kAlienBuyMenuSounds.SelectLerk
    elseif type == "Onos" then
        assetName = kAlienBuyMenuSounds.SelectOnos
    elseif type == "Fade" then
        assetName = kAlienBuyMenuSounds.SelectFade
    end
    Shared.PlaySound(nil, assetName)

end

function AlienBuy_OnUpgradeSelected()

    Shared.PlaySound(nil, kAlienBuyMenuSounds.BuyUpgrade)
    
end

function AlienBuy_OnUpgradeDeselected()

    Shared.PlaySound(nil, kAlienBuyMenuSounds.SellUpgrade)
    
end

/**
 * User pressed close button
 */
function AlienBuy_Close()
    local player = Client.GetLocalPlayer()
    player:CloseMenu()
end