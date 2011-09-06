
// ======= Copyright © 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAlienHUD.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the health and armor HUD information for the alien.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIDial.lua")

class 'GUIAlienHUD' (GUIScript)

GUIAlienHUD.kTextureName = "ui/alien_hud_health.dds"
GUIAlienHUD.kAbilityImage = "ui/alien_abilities.dds"
GUIAlienHUD.kTextFontName = "MicrogrammaDMedExt"

GUIAlienHUD.kHealthBackgroundWidth = 128
GUIAlienHUD.kHealthBackgroundHeight = 128
GUIAlienHUD.kHealthBackgroundOffset = Vector(30, -30, 0)
GUIAlienHUD.kHealthBackgroundTextureX1 = 0
GUIAlienHUD.kHealthBackgroundTextureY1 = 0
GUIAlienHUD.kHealthBackgroundTextureX2 = 128
GUIAlienHUD.kHealthBackgroundTextureY2 = 128

GUIAlienHUD.kHealthTextureX1 = 0
GUIAlienHUD.kHealthTextureY1 = 128
GUIAlienHUD.kHealthTextureX2 = 128
GUIAlienHUD.kHealthTextureY2 = 256

GUIAlienHUD.kArmorTextureX1 = 128
GUIAlienHUD.kArmorTextureY1 = 0
GUIAlienHUD.kArmorTextureX2 = 256
GUIAlienHUD.kArmorTextureY2 = 128

GUIAlienHUD.kBarMoveRate = 0.5

GUIAlienHUD.kFontColor = Color(0.8, 0.4, 0.4, 1)

GUIAlienHUD.kHealthTextFontSize = 35
GUIAlienHUD.kHealthTextYOffset = -20

GUIAlienHUD.kArmorTextFontSize = 25
GUIAlienHUD.kArmorTextYOffset = 20

// This is how long a ball remains visible after it changes.
GUIAlienHUD.kBallFillVisibleTimer = 5
// This is at what point in the GUIAlienHUD.kBallFillVisibleTimer to
// begin fading out.
GUIAlienHUD.kBallStartFadeOutTimer = 2

// Energy ball settings.
GUIAlienHUD.kEnergyBackgroundWidth = 96
GUIAlienHUD.kEnergyBackgroundHeight = 96
GUIAlienHUD.kEnergyBackgroundOffset = Vector(-GUIAlienHUD.kEnergyBackgroundWidth - 30, -30, 0)
GUIAlienHUD.kEnergyTextureX1 = 128
GUIAlienHUD.kEnergyTextureY1 = 128
GUIAlienHUD.kEnergyTextureX2 = 256
GUIAlienHUD.kEnergyTextureY2 = 256

GUIAlienHUD.kNotEnoughEnergyColor = Color(0.6, 0, 0, 1)

GUIAlienHUD.kAbilityIconSize = 98

GUIAlienHUD.kSecondaryAbilityIconSize = 60
GUIAlienHUD.kSecondaryAbilityBackgroundOffset = Vector(10, -100, 0)

GUIAlienHUD.kInactiveAbilityBarWidth = GUIAlienHUD.kSecondaryAbilityIconSize * kMaxAlienAbilities
GUIAlienHUD.kInactiveAbilityBarHeight = GUIAlienHUD.kSecondaryAbilityIconSize
GUIAlienHUD.kInactiveAbilityBarOffset = Vector(-GUIAlienHUD.kInactiveAbilityBarWidth - GUIAlienHUD.kEnergyBackgroundWidth - 25, -GUIAlienHUD.kInactiveAbilityBarHeight, 0)

GUIAlienHUD.kSelectedAbilityColor = Color(1, 1, 1, 1)
GUIAlienHUD.kUnselectedAbilityColor = Color(0.5, 0.5, 0.5, 1)

GUIAlienHUD.kPhantomTextFontSize = 24
GUIAlienHUD.kPhantomProgressBarWidth = 200
GUIAlienHUD.kPhantomProgressBarHeight = 10
GUIAlienHUD.kPhantomProgressBarColor = Color(0.0, 0.24313725490196078431372549019608, 0.48235294117647058823529411764706, 0.5)

function GUIAlienHUD:Initialize()

    // Stores all state related to fading balls.
    self.fadeValues = { }
    
    // Keep track of weapon changes.
    self.lastActiveHudSlot = 0
    
    self:CreateHealthBall()
    self:CreateEnergyBall()

end

function GUIAlienHUD:CreateHealthBall()
    
    self.healthBallFadeAmount = 1
    self.fadeHealthBallTime = 0
    
    self.healthBarPercentage = PlayerUI_GetPlayerHealth() / PlayerUI_GetPlayerMaxHealth()
    
    local healthBallSettings = { }
    healthBallSettings.BackgroundWidth = GUIAlienHUD.kHealthBackgroundWidth
    healthBallSettings.BackgroundHeight = GUIAlienHUD.kHealthBackgroundHeight
    healthBallSettings.BackgroundAnchorX = GUIItem.Left
    healthBallSettings.BackgroundAnchorY = GUIItem.Bottom
    healthBallSettings.BackgroundOffset = Vector(GUIAlienHUD.kHealthBackgroundOffset)
    healthBallSettings.BackgroundTextureName = GUIAlienHUD.kTextureName
    healthBallSettings.BackgroundTextureX1 = GUIAlienHUD.kHealthBackgroundTextureX1
    healthBallSettings.BackgroundTextureY1 = GUIAlienHUD.kHealthBackgroundTextureY1
    healthBallSettings.BackgroundTextureX2 = GUIAlienHUD.kHealthBackgroundTextureX2
    healthBallSettings.BackgroundTextureY2 = GUIAlienHUD.kHealthBackgroundTextureY2
    healthBallSettings.ForegroundTextureName = GUIAlienHUD.kTextureName
    healthBallSettings.ForegroundTextureWidth = 128
    healthBallSettings.ForegroundTextureHeight = 128
    healthBallSettings.ForegroundTextureX1 = GUIAlienHUD.kHealthTextureX1
    healthBallSettings.ForegroundTextureY1 = GUIAlienHUD.kHealthTextureY1
    healthBallSettings.ForegroundTextureX2 = GUIAlienHUD.kHealthTextureX2
    healthBallSettings.ForegroundTextureY2 = GUIAlienHUD.kHealthTextureY2
    healthBallSettings.InheritParentAlpha = true
    self.healthBall = GUIDial()
    self.healthBall:Initialize(healthBallSettings)
    
    self.armorBarPercentage = PlayerUI_GetPlayerArmor() / PlayerUI_GetPlayerMaxArmor()
    
    local armorBallSettings = { }
    armorBallSettings.BackgroundWidth = GUIAlienHUD.kHealthBackgroundWidth
    armorBallSettings.BackgroundHeight = GUIAlienHUD.kHealthBackgroundHeight
    armorBallSettings.BackgroundAnchorX = GUIItem.Left
    armorBallSettings.BackgroundAnchorY = GUIItem.Bottom
    armorBallSettings.BackgroundOffset = Vector(GUIAlienHUD.kHealthBackgroundOffset)
    armorBallSettings.BackgroundTextureName = nil
    armorBallSettings.BackgroundTextureX1 = GUIAlienHUD.kHealthBackgroundTextureX1
    armorBallSettings.BackgroundTextureY1 = GUIAlienHUD.kHealthBackgroundTextureY1
    armorBallSettings.BackgroundTextureX2 = GUIAlienHUD.kHealthBackgroundTextureX2
    armorBallSettings.BackgroundTextureY2 = GUIAlienHUD.kHealthBackgroundTextureY2
    armorBallSettings.ForegroundTextureName = GUIAlienHUD.kTextureName
    armorBallSettings.ForegroundTextureWidth = 128
    armorBallSettings.ForegroundTextureHeight = 128
    armorBallSettings.ForegroundTextureX1 = GUIAlienHUD.kArmorTextureX1
    armorBallSettings.ForegroundTextureY1 = GUIAlienHUD.kArmorTextureY1
    armorBallSettings.ForegroundTextureX2 = GUIAlienHUD.kArmorTextureX2
    armorBallSettings.ForegroundTextureY2 = GUIAlienHUD.kArmorTextureY2
    armorBallSettings.InheritParentAlpha = false
    self.armorBall = GUIDial()
    self.armorBall:Initialize(armorBallSettings)
    
    self.healthText = GUIManager:CreateTextItem()
    self.healthText:SetFontSize(GUIAlienHUD.kHealthTextFontSize)
    self.healthText:SetFontName(GUIAlienHUD.kTextFontName)
    self.healthText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.healthText:SetPosition(Vector(0, GUIAlienHUD.kHealthTextYOffset, 0))
    self.healthText:SetTextAlignmentX(GUIItem.Align_Center)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetColor(GUIAlienHUD.kFontColor)
    self.healthText:SetInheritsParentAlpha(true)
    
    self.healthBall:GetBackground():AddChild(self.healthText)
    
    self.armorText = GUIManager:CreateTextItem()
    self.armorText:SetFontSize(GUIAlienHUD.kArmorTextFontSize)
    self.armorText:SetFontName(GUIAlienHUD.kTextFontName)
    self.armorText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.armorText:SetPosition(Vector(0, GUIAlienHUD.kArmorTextYOffset, 0))
    self.armorText:SetTextAlignmentX(GUIItem.Align_Center)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetColor(GUIAlienHUD.kFontColor)
    self.armorText:SetInheritsParentAlpha(true)
    
    self.healthBall:GetBackground():AddChild(self.armorText)
    
    // Add bar that goes down over time
    self.phantomProgressBar = GUIManager:CreateGraphicItem()
    self.phantomProgressBar:SetSize(Vector(GUIAlienHUD.kPhantomProgressBarWidth, GUIAlienHUD.kPhantomProgressBarHeight, 0))
    self.phantomProgressBar:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.phantomProgressBar:SetPosition(Vector(0, -20, 0))
    self.phantomProgressBar:SetColor(GUIAlienHUD.kPhantomProgressBarColor)
    
    // Display "Phantom" help text
    self.phantomText = GUIManager:CreateTextItem()
    self.phantomText:SetIsVisible(false)
    self.phantomText:SetFontSize(GUIAlienHUD.kPhantomTextFontSize)
    self.phantomText:SetFontName(GUIAlienHUD.kTextFontName)
    self.phantomText:SetPosition(Vector(0, GUIAlienHUD.kHealthTextYOffset, 0))
    self.phantomText:SetColor(GUIAlienHUD.kFontColor)
    self.phantomText:SetInheritsParentAlpha(true)    
    self.phantomText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.phantomText:SetTextAlignmentX(GUIItem.Align_Center)
    self.phantomText:SetTextAlignmentY(GUIItem.Align_Center)    
    self.phantomText:SetPosition(Vector(0, -50, 0))
    self.phantomText:SetText(Locale.ResolveString("ALIEN_HUD_PHANTOM"))
    
end

function GUIAlienHUD:CreateEnergyBall()

    self.energyBarPercentage = PlayerUI_GetPlayerEnergy() / PlayerUI_GetPlayerMaxEnergy()
    
    local energyBallSettings = { }
    energyBallSettings.BackgroundWidth = GUIAlienHUD.kEnergyBackgroundWidth
    energyBallSettings.BackgroundHeight = GUIAlienHUD.kEnergyBackgroundHeight
    energyBallSettings.BackgroundAnchorX = GUIItem.Right
    energyBallSettings.BackgroundAnchorY = GUIItem.Bottom
    energyBallSettings.BackgroundOffset = Vector(GUIAlienHUD.kEnergyBackgroundOffset)
    energyBallSettings.BackgroundTextureName = GUIAlienHUD.kTextureName
    energyBallSettings.BackgroundTextureX1 = GUIAlienHUD.kHealthBackgroundTextureX1
    energyBallSettings.BackgroundTextureY1 = GUIAlienHUD.kHealthBackgroundTextureY1
    energyBallSettings.BackgroundTextureX2 = GUIAlienHUD.kHealthBackgroundTextureX2
    energyBallSettings.BackgroundTextureY2 = GUIAlienHUD.kHealthBackgroundTextureY2
    energyBallSettings.ForegroundTextureName = GUIAlienHUD.kTextureName
    energyBallSettings.ForegroundTextureWidth = 128
    energyBallSettings.ForegroundTextureHeight = 128
    energyBallSettings.ForegroundTextureX1 = GUIAlienHUD.kEnergyTextureX1
    energyBallSettings.ForegroundTextureY1 = GUIAlienHUD.kEnergyTextureY1
    energyBallSettings.ForegroundTextureX2 = GUIAlienHUD.kEnergyTextureX2
    energyBallSettings.ForegroundTextureY2 = GUIAlienHUD.kEnergyTextureY2
    energyBallSettings.InheritParentAlpha = true
    self.energyBall = GUIDial()
    self.energyBall:Initialize(energyBallSettings)
    
    self.activeAbilityIcon = GUIManager:CreateGraphicItem()
    self.activeAbilityIcon:SetSize(Vector(GUIAlienHUD.kAbilityIconSize, GUIAlienHUD.kAbilityIconSize, 0))
    self.activeAbilityIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.activeAbilityIcon:SetPosition(Vector(-GUIAlienHUD.kAbilityIconSize / 2, -GUIAlienHUD.kAbilityIconSize / 2, 0))
    self.activeAbilityIcon:SetTexture(GUIAlienHUD.kAbilityImage)
    self.activeAbilityIcon:SetIsVisible(false)
    self.activeAbilityIcon:SetInheritsParentAlpha(true)
    self.energyBall:GetBackground():AddChild(self.activeAbilityIcon)
    
    self.secondaryAbilityBackground = GUIManager:CreateGraphicItem()
    self.secondaryAbilityBackground:SetSize(Vector(GUIAlienHUD.kSecondaryAbilityIconSize, GUIAlienHUD.kSecondaryAbilityIconSize, 0))
    self.secondaryAbilityBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.secondaryAbilityBackground:SetPosition(GUIAlienHUD.kSecondaryAbilityBackgroundOffset)
    self.secondaryAbilityBackground:SetTexture(GUIAlienHUD.kTextureName)
    self.secondaryAbilityBackground:SetTexturePixelCoordinates(GUIAlienHUD.kHealthBackgroundTextureX1, GUIAlienHUD.kHealthBackgroundTextureY1,
                                                               GUIAlienHUD.kHealthBackgroundTextureX2, GUIAlienHUD.kHealthBackgroundTextureY2)
    self.secondaryAbilityBackground:SetInheritsParentAlpha(true)
    self.secondaryAbilityBackground:SetIsVisible(false)
    self.activeAbilityIcon:AddChild(self.secondaryAbilityBackground)
    
    self.secondaryAbilityIcon = GUIManager:CreateGraphicItem()
    self.secondaryAbilityIcon:SetSize(Vector(GUIAlienHUD.kSecondaryAbilityIconSize, GUIAlienHUD.kSecondaryAbilityIconSize, 0))
    self.secondaryAbilityIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.secondaryAbilityIcon:SetPosition(Vector(0, 0, 0))
    self.secondaryAbilityIcon:SetTexture(GUIAlienHUD.kAbilityImage)
    self.secondaryAbilityIcon:SetInheritsParentAlpha(true)
    self.secondaryAbilityBackground:AddChild(self.secondaryAbilityIcon)
    
    self:CreateInactiveAbilityIcons(kMaxAlienAbilities)
    
end

function GUIAlienHUD:CreateInactiveAbilityIcons(numberOfIcons)

    self.inactiveAbilityIconList = { }
    self.inactiveAbilitiesBar = GUI.CreateItem()
    self.inactiveAbilitiesBar:SetSize(Vector(GUIAlienHUD.kInactiveAbilityBarWidth, GUIAlienHUD.kInactiveAbilityBarHeight, 0))
    self.inactiveAbilitiesBar:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.inactiveAbilitiesBar:SetPosition(GUIAlienHUD.kInactiveAbilityBarOffset)
    self.inactiveAbilitiesBar:SetColor(Color(0, 0, 0, 0))
    
    local currentIcon = 0
    while currentIcon < numberOfIcons do
    
        local iconBackground = GUIManager:CreateGraphicItem()
        iconBackground:SetSize(Vector(GUIAlienHUD.kSecondaryAbilityIconSize, GUIAlienHUD.kSecondaryAbilityIconSize, 0))
        iconBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
        iconBackground:SetPosition(Vector(currentIcon * GUIAlienHUD.kSecondaryAbilityIconSize, 0, 0))
        iconBackground:SetTexture(GUIAlienHUD.kTextureName)
        iconBackground:SetTexturePixelCoordinates(GUIAlienHUD.kHealthBackgroundTextureX1, GUIAlienHUD.kHealthBackgroundTextureY1,
                                                  GUIAlienHUD.kHealthBackgroundTextureX2, GUIAlienHUD.kHealthBackgroundTextureY2)
        iconBackground:SetIsVisible(false)

        self.inactiveAbilitiesBar:AddChild(iconBackground)
        
        local inactiveIcon = GUIManager:CreateGraphicItem()
        inactiveIcon:SetSize(Vector(GUIAlienHUD.kSecondaryAbilityIconSize, GUIAlienHUD.kSecondaryAbilityIconSize, 0))
        inactiveIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
        inactiveIcon:SetPosition(Vector(0, 0, 0))
        inactiveIcon:SetTexture(GUIAlienHUD.kAbilityImage)
        inactiveIcon:SetInheritsParentAlpha(true)
        iconBackground:AddChild(inactiveIcon)
        
        local numberIndicatorText = GUIManager:CreateTextItem()
        numberIndicatorText:SetFontSize(12)
        numberIndicatorText:SetFontName(GUIAlienHUD.kTextFontName)
        numberIndicatorText:SetAnchor(GUIItem.Middle, GUIItem.Top)
        numberIndicatorText:SetPosition(Vector(0, 0, 0))
        numberIndicatorText:SetTextAlignmentX(GUIItem.Align_Center)
        numberIndicatorText:SetTextAlignmentY(GUIItem.Align_Max)
        numberIndicatorText:SetText(tostring(currentIcon + 1))
        numberIndicatorText:SetInheritsParentAlpha(true)
        inactiveIcon:AddChild(numberIndicatorText)
        
        table.insert(self.inactiveAbilityIconList, { Background = iconBackground, Icon = inactiveIcon })
        
        currentIcon = currentIcon + 1
        
    end

end

function GUIAlienHUD:Uninitialize()

    if self.healthBall then
        self.healthBall:Uninitialize()
        self.healthBall = nil
    end
    
    if self.armorBall then
        self.armorBall:Uninitialize()
        self.armorBall = nil
    end
    
    if self.energyBall then
        self.energyBall:Uninitialize()
        self.energyBall = nil
    end
    
    if self.inactiveAbilitiesBar then
        GUI.DestroyItem(self.inactiveAbilitiesBar)
        self.inactiveAbilitiesBar = nil
        self.inactiveAbilityIconList = { }
    end
    
end

function GUIAlienHUD:Update(deltaTime)

    PROFILE("GUIAlienHUD:Update")
    
    self:UpdateHealthBall(deltaTime)
    self:UpdateEnergyBall(deltaTime)
    self:UpdatePhantom(deltaTime)
    
end

function GUIAlienHUD:UpdateHealthBall(deltaTime)

    local healthBarPercentageGoal = PlayerUI_GetPlayerHealth() / PlayerUI_GetPlayerMaxHealth()
    self.healthBarPercentage = Slerp(self.healthBarPercentage, healthBarPercentageGoal, deltaTime * GUIAlienHUD.kBarMoveRate)
    
    local armorBarPercentageGoal = PlayerUI_GetPlayerArmor() / PlayerUI_GetPlayerMaxArmor()
    self.armorBarPercentage = Slerp(self.armorBarPercentage, armorBarPercentageGoal, deltaTime * GUIAlienHUD.kBarMoveRate)

    // It's probably better to do a math.ceil for display health instead of floor, but NS1 did it this way
    // and I want to make sure the values are exactly the same to avoid confusion right now
    self.healthBall:SetPercentage(self.healthBarPercentage)
    self.healthText:SetText(tostring(math.floor(PlayerUI_GetPlayerHealth())))
    self.healthBall:Update(deltaTime)
    
    self.armorBall:SetPercentage(self.armorBarPercentage)
    self.armorText:SetText(tostring(math.floor(PlayerUI_GetPlayerArmor())))
    self.armorBall:Update(deltaTime)
    
    self:UpdateFading(self.healthBall:GetBackground(), self.healthBarPercentage * self.armorBarPercentage, deltaTime)
    self.armorBall:GetLeftSide():SetColor(self.healthBall:GetBackground():GetColor())
    self.armorBall:GetLeftSide():SetIsVisible(self.healthBall:GetBackground():GetIsVisible())
    self.armorBall:GetRightSide():SetColor(self.healthBall:GetBackground():GetColor())
    self.armorBall:GetRightSide():SetIsVisible(self.healthBall:GetBackground():GetIsVisible())
    
end

function GUIAlienHUD:UpdateEnergyBall(deltaTime)
    
    local energyBarPercentageGoal = PlayerUI_GetPlayerEnergy() / PlayerUI_GetPlayerMaxEnergy()
    self.energyBarPercentage = Slerp(self.energyBarPercentage, energyBarPercentageGoal, deltaTime * GUIAlienHUD.kBarMoveRate)
    
    self.energyBall:SetPercentage(self.energyBarPercentage)
    self.energyBall:Update(deltaTime)
    
    self:UpdateFading(self.energyBall:GetBackground(), self.energyBarPercentage, deltaTime)
    
    self:UpdateAbilities(deltaTime)
    
end

function GUIAlienHUD:UpdatePhantom(deltaTime)

    local visible = false
    local player = Client.GetLocalPlayer()
    local progressWidth = GUIAlienHUD.kPhantomProgressBarWidth
    
    if player and HasMixin(player, "Phantom") and player:GetIsPhantom() then
    
        visible = true
        progressWidth = GUIAlienHUD.kPhantomProgressBarWidth * (player:GetPhantomLifetime() / kPhantomLifetime)
        
    end
    
    self.phantomText:SetIsVisible(visible)
    
    self.phantomProgressBar:SetSize(Vector(progressWidth, GUIAlienHUD.kPhantomProgressBarHeight, 0))    
    self.phantomProgressBar:SetIsVisible(visible)
    
end

function GUIAlienHUD:UpdateAbilities(deltaTime)

    local activeHudSlot = 0
    
    local abilityData = PlayerUI_GetAbilityData()
    local currentIndex = 1
    if table.count(abilityData) > 0 then
        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local texXOffset = abilityData[currentIndex + 2] * GUIAlienHUD.kAbilityIconSize
        local texYOffset = abilityData[currentIndex + 3] * GUIAlienHUD.kAbilityIconSize
        local visibility = abilityData[currentIndex + 4]
        activeHudSlot = abilityData[currentIndex + 5]
        self.activeAbilityIcon:SetIsVisible(true)
        self.activeAbilityIcon:SetTexturePixelCoordinates(texXOffset, texYOffset, texXOffset + GUIAlienHUD.kAbilityIconSize, texYOffset + GUIAlienHUD.kAbilityIconSize)
        local setColor = GUIAlienHUD.kNotEnoughEnergyColor
        if totalPower >= minimumPower then
            setColor = Color(1, 1, 1, 1)
        end
        local currentBackgroundColor = self.energyBall:GetBackground():GetColor()
        currentBackgroundColor.r = setColor.r
        currentBackgroundColor.g = setColor.g
        currentBackgroundColor.b = setColor.b
        self.energyBall:GetBackground():SetColor(currentBackgroundColor)
        self.activeAbilityIcon:SetColor(setColor)
        self.energyBall:GetLeftSide():SetColor(setColor)
        self.energyBall:GetRightSide():SetColor(setColor)
    else
        self.activeAbilityIcon:SetIsVisible(false)
    end
    
    // The the player changed abilities, force show the energy ball and
    // the inactive abilities bar.
    if activeHudSlot ~= self.lastActiveHudSlot then
        self:ForceUnfade(self.energyBall:GetBackground())
        for i, ability in ipairs(self.inactiveAbilityIconList) do
            self:ForceUnfade(ability.Background)
        end
    end
    self.lastActiveHudSlot = activeHudSlot
    
    // Secondary ability.
    abilityData = PlayerUI_GetSecondaryAbilityData()
    currentIndex = 1
    if table.count(abilityData) > 0 then
        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local texXOffset = abilityData[currentIndex + 2] * GUIAlienHUD.kAbilityIconSize
        local texYOffset = abilityData[currentIndex + 3] * GUIAlienHUD.kAbilityIconSize
        local visibility = abilityData[currentIndex + 4]
        self.secondaryAbilityBackground:SetIsVisible(true)
        self.secondaryAbilityIcon:SetTexturePixelCoordinates(texXOffset, texYOffset, texXOffset + GUIAlienHUD.kAbilityIconSize, texYOffset + GUIAlienHUD.kAbilityIconSize)
        if totalPower < minimumPower then
            self.secondaryAbilityIcon:SetColor(GUIAlienHUD.kNotEnoughEnergyColor)
            self.secondaryAbilityBackground:SetColor(GUIAlienHUD.kNotEnoughEnergyColor)
        else
            local enoughEnergyColor = Color(1, 1, 1, 1)
            self.secondaryAbilityIcon:SetColor(enoughEnergyColor)
            self.secondaryAbilityBackground:SetColor(enoughEnergyColor)
        end
    else
        self.secondaryAbilityBackground:SetIsVisible(false)
    end
    
    self:UpdateInactiveAbilities(deltaTime, activeHudSlot)
    
end

function GUIAlienHUD:UpdateInactiveAbilities(deltaTime, activeHudSlot)

    local numberElementsPerAbility = 3
    local abilityData = PlayerUI_GetInactiveAbilities()
    local numberAbilties = table.count(abilityData) / numberElementsPerAbility
    local currentIndex = 1
    if numberAbilties > 0 then
        self.inactiveAbilitiesBar:SetIsVisible(true)
        local totalAbilityCount = table.count(self.inactiveAbilityIconList)
        local shiftedXPosition = (totalAbilityCount - numberAbilties) * GUIAlienHUD.kSecondaryAbilityIconSize
        local fixedOffset = GUIAlienHUD.kInactiveAbilityBarOffset + Vector(shiftedXPosition, 0, 0)
        self.inactiveAbilitiesBar:SetPosition(fixedOffset)
        local currentAbilityIndex = 1
        while currentAbilityIndex <= totalAbilityCount do
            local visible = currentAbilityIndex <= numberAbilties
            self.inactiveAbilityIconList[currentAbilityIndex].Background:SetIsVisible(visible)
            if visible then
                local texXOffset = abilityData[currentIndex] * GUIAlienHUD.kAbilityIconSize
                local texYOffset = abilityData[currentIndex + 1] * GUIAlienHUD.kAbilityIconSize
                local hudSlot = abilityData[currentIndex + 2]
                self.inactiveAbilityIconList[currentAbilityIndex].Icon:SetTexturePixelCoordinates(texXOffset, texYOffset, texXOffset + GUIAlienHUD.kAbilityIconSize, texYOffset + GUIAlienHUD.kAbilityIconSize)
                if hudSlot == activeHudSlot then
                    self.inactiveAbilityIconList[currentAbilityIndex].Icon:SetColor(GUIAlienHUD.kSelectedAbilityColor)
                    self.inactiveAbilityIconList[currentAbilityIndex].Background:SetColor(GUIAlienHUD.kSelectedAbilityColor)
                else
                    self.inactiveAbilityIconList[currentAbilityIndex].Icon:SetColor(GUIAlienHUD.kUnselectedAbilityColor)
                    self.inactiveAbilityIconList[currentAbilityIndex].Background:SetColor(GUIAlienHUD.kUnselectedAbilityColor)
                end
                currentIndex = currentIndex + numberElementsPerAbility
            end
            self:UpdateFading(self.inactiveAbilityIconList[currentAbilityIndex].Background, 1, deltaTime)
            currentAbilityIndex = currentAbilityIndex + 1
        end
    else
        self.inactiveAbilitiesBar:SetIsVisible(false)
    end

end

function GUIAlienHUD:UpdateFading(fadeItem, itemFillPercentage, deltaTime)

    if self.fadeValues[fadeItem] == nil then
        self.fadeValues[fadeItem] = { }
        self.fadeValues[fadeItem].lastFillPercentage = 0
        self.fadeValues[fadeItem].currentFadeAmount = 1
        self.fadeValues[fadeItem].fadeTime = 0
    end
    
    local lastFadePercentage = self.fadeValues[fadeItem].lastPercentage
    self.fadeValues[fadeItem].lastPercentage = itemFillPercentage
    
    // Only fade when the ball is completely filled.
    if itemFillPercentage == 1 then
        // Check if we should start fading (itemFillPercentage just hit 100%).
        if lastFadePercentage ~= 1 then
            self:ForceUnfade(fadeItem)
        end
        
        // Handle fading out the health ball.
        self.fadeValues[fadeItem].fadeTime = math.max(0, self.fadeValues[fadeItem].fadeTime - deltaTime)
        if self.fadeValues[fadeItem].fadeTime <= GUIAlienHUD.kBallStartFadeOutTimer then
            self.fadeValues[fadeItem].currentFadeAmount = self.fadeValues[fadeItem].fadeTime / GUIAlienHUD.kBallStartFadeOutTimer
        end
        
        if self.fadeValues[fadeItem].currentFadeAmount == 0 then
            fadeItem:SetIsVisible(false)
        else
            fadeItem:SetColor(Color(1, 1, 1, self.fadeValues[fadeItem].currentFadeAmount))
        end
    else
        fadeItem:SetIsVisible(true)
        fadeItem:SetColor(Color(1, 1, 1, 1))
    end

end

function GUIAlienHUD:ForceUnfade(unfadeItem)

    if self.fadeValues[unfadeItem] ~= nil then
        unfadeItem:SetIsVisible(true)
        unfadeItem:SetColor(Color(1, 1, 1, 1))
        self.fadeValues[unfadeItem].fadeTime = GUIAlienHUD.kBallFillVisibleTimer
        self.fadeValues[unfadeItem].currentFadeAmount = 1
    end
    
end
