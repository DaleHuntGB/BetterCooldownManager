local _, BCDM = ...

local runeBars = {}
local comboPoints = {}
local essenceTicks = {}
local resizeTimer = nil

local isDestruction;

local function SetBarValue(bar, value)
    local GeneralDB = BCDM.db.profile.General
    local smoothBars = GeneralDB.Animation and GeneralDB.Animation.SmoothBars
    if smoothBars and Enum and Enum.StatusBarInterpolation then
        bar:SetValue(value, Enum.StatusBarInterpolation.ExponentialEaseOut)
    else
        bar:SetValue(value)
    end
end

local function DetectSecondaryPower()
    local class = select(2, UnitClass("player"))
    local spec = C_SpecializationInfo.GetSpecialization()
    local specID = C_SpecializationInfo.GetSpecializationInfo(spec)
    isDestruction = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization()) == 267

    if class == "MONK" then
        if specID == 268 then return "STAGGER" end
        if specID == 269 then return Enum.PowerType.Chi end
    elseif class == "ROGUE" then
        return Enum.PowerType.ComboPoints
    elseif class == "DRUID" then
        local form = GetShapeshiftFormID()
        if form == 1 then return Enum.PowerType.ComboPoints end
    elseif class == "PALADIN" then
        return Enum.PowerType.HolyPower
    elseif class == "WARLOCK" then
        return Enum.PowerType.SoulShards
    elseif class == "MAGE" then
        if specID == 62 then return Enum.PowerType.ArcaneCharges end
    elseif class == "EVOKER" then
        return Enum.PowerType.Essence
    elseif class == "DEATHKNIGHT" then
        return Enum.PowerType.Runes
    elseif class == "DEMONHUNTER" then
        if specID == 1480 then return "SOUL" end
    elseif class == "SHAMAN" then
        if specID == 263 then return Enum.PowerType.Maelstrom end
    end

    return nil
end

local function NudgeSecondaryPowerBar(secondaryPowerBar, xOffset, yOffset)
    local powerBarFrame = _G[secondaryPowerBar]
    if not powerBarFrame then return end

    local point, relativeTo, relativePoint, xOfs, yOfs = powerBarFrame:GetPoint(1)
    powerBarFrame:ClearAllPoints()
    powerBarFrame:SetPoint(point, relativeTo, relativePoint, xOfs + xOffset, yOfs + yOffset)
end

local function GetPowerBarColor()
    local cooldownManagerDB = BCDM.db.profile
    local generalDB = cooldownManagerDB.General
    local secondaryPowerBarDB = cooldownManagerDB.SecondaryPowerBar

    if not secondaryPowerBarDB then
        return 1, 1, 1, 1
    end

    if secondaryPowerBarDB.ColourByType then
        local powerType = DetectSecondaryPower()
        local powerColour = generalDB.Colours.SecondaryPower[powerType]
        if powerColour then
            return powerColour[1], powerColour[2], powerColour[3], powerColour[4] or 1
        end
    elseif secondaryPowerBarDB.ColourByClass then
        local _, class = UnitClass("player")
        local classColour = RAID_CLASS_COLORS[class]
        if classColour then
            return classColour.r, classColour.g, classColour.b, 1
        end
    elseif BCDM.IS_DEATHKNIGHT and secondaryPowerBarDB.ColourBySpec then
        local spec = GetSpecialization()
        local specID = GetSpecializationInfo(spec)
        local runeColours = generalDB.Colours.SecondaryPower["RUNES"]

        if specID == 250 and runeColours and runeColours.BLOOD then
            local colour = runeColours.BLOOD
            return colour[1], colour[2], colour[3], colour[4] or 1
        elseif specID == 251 and runeColours and runeColours.FROST then
            local colour = runeColours.FROST
            return colour[1], colour[2], colour[3], colour[4] or 1
        elseif specID == 252 and runeColours and runeColours.UNHOLY then
            local colour = runeColours.UNHOLY
            return colour[1], colour[2], colour[3], colour[4] or 1
        end
    else
        return secondaryPowerBarDB.ForegroundColour[1], secondaryPowerBarDB.ForegroundColour[2], secondaryPowerBarDB.ForegroundColour[3], secondaryPowerBarDB.ForegroundColour[4] or 1
    end

    return 1, 1, 1, 1
end

local function CreateRuneBars()
    local parent = BCDM.SecondaryPowerBar
    if not parent then return end

    for i = 1, #runeBars do
        if runeBars[i] then
            runeBars[i]:SetScript("OnUpdate", nil)
            runeBars[i]:Hide()
            runeBars[i]:SetParent(nil)
            runeBars[i] = nil
        end
    end
    wipe(runeBars)

    for i = 1, 6 do
        local runeBar = CreateFrame("StatusBar", nil, parent)
        runeBar:SetStatusBarTexture(BCDM.Media.Foreground)
        runeBar:SetMinMaxValues(0, 1)
        runeBar:SetValue(0)
        runeBars[i] = runeBar
    end
end

local function CreateComboPoints(maxPower)
    local parent = BCDM.SecondaryPowerBar
    if not parent then return end

    for i = 1, #comboPoints do
        comboPoints[i]:Hide()
        comboPoints[i]:SetParent(nil)
        comboPoints[i] = nil
    end
    wipe(comboPoints)

    for i = 1, maxPower do
        local bar = CreateFrame("StatusBar", nil, parent)
        bar:SetStatusBarTexture(BCDM.Media.Foreground)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        comboPoints[i] = bar
    end
end

local function CreateEssenceTicks(maxEssence)
    local parent = BCDM.SecondaryPowerBar
    if not parent then return end

    for i = 1, #essenceTicks do
        essenceTicks[i].bar:SetScript("OnUpdate", nil)
        essenceTicks[i].bar:Hide()
        essenceTicks[i].bar:SetParent(nil)
        essenceTicks[i] = nil
    end
    wipe(essenceTicks)

    for i = 1, maxEssence do
        local bar = CreateFrame("StatusBar", nil, parent)
        bar:SetStatusBarTexture(BCDM.Media.Foreground)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)

        essenceTicks[i] = {
            bar = bar,
        }
    end
end

local function LayoutRuneBars()
    local secondaryBar = BCDM.SecondaryPowerBar
    if not secondaryBar or #runeBars == 0 then return end

    local powerBarWidth = secondaryBar:GetWidth() - 2
    local powerBarHeight = secondaryBar:GetHeight() - 2
    local runeSpacing = 1
    local runeWidth = (powerBarWidth - (runeSpacing * 5)) / 6

    for i = 1, 6 do
        local runeBar = runeBars[i]
        if not runeBar then return end

        runeBar:ClearAllPoints()
        runeBar:SetSize(runeWidth, powerBarHeight)

        if i == 1 then
            runeBar:SetPoint("LEFT", secondaryBar, "LEFT", 1, 0)
        else
            runeBar:SetPoint("LEFT", runeBars[i-1], "RIGHT", runeSpacing, 0)
        end
    end
end

local function LayoutComboPoints()
    local parent = BCDM.SecondaryPowerBar
    if not parent or #comboPoints == 0 then return end

    local inset = 1
    local width = parent:GetWidth() - inset * 2
    local height = parent:GetHeight() - inset * 2
    local count = #comboPoints
    local barWidth = math.floor(width / count)

    for i = 1, count do
        local bar = comboPoints[i]
        bar:ClearAllPoints()
        bar:SetHeight(height)

        if i == count then
            bar:SetPoint("TOPLEFT", comboPoints[i-1], "TOPRIGHT", 0, 0)
            bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
        elseif i == 1 then
            bar:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
            bar:SetWidth(barWidth)
        else
            bar:SetPoint("TOPLEFT", comboPoints[i-1], "TOPRIGHT", 0, 0)
            bar:SetWidth(barWidth)
        end
    end
end

local function LayoutEssenceTicks()
    local parent = BCDM.SecondaryPowerBar
    if not parent or #essenceTicks == 0 then return end

    local powerBarWidth = parent:GetWidth() - 2
    local powerBarHeight = parent:GetHeight() - 2
    local spacing = 1
    local count = #essenceTicks
    local barWidth = (powerBarWidth - (spacing * (count - 1))) / count

    for i = 1, count do
        local tick = essenceTicks[i]
        local bar = tick.bar

        bar:ClearAllPoints()
        bar:SetSize(barWidth, powerBarHeight)

        if i == 1 then
            bar:SetPoint("LEFT", parent, "LEFT", 1, 0)
        else
            bar:SetPoint("LEFT", essenceTicks[i - 1].bar, "RIGHT", spacing, 0)
        end
    end
end

local function StartRuneOnUpdate(runeBar, runeIndex)
    local generalDB = BCDM.db.profile.General

    runeBar:SetScript("OnUpdate", function(self)
        local runeStartTime, runeDuration, runeReady = GetRuneCooldown(runeIndex)

        if runeReady then
            self:SetScript("OnUpdate", nil)
            self:SetValue(1)
            local r, g, b, a = GetPowerBarColor()
            self:SetStatusBarColor(r, g, b, a)
            return
        end

        if runeDuration and runeDuration > 0 then
            local now = GetTime()
            local elapsed = now - runeStartTime
            local progress = math.min(1, elapsed / runeDuration)
            self:SetValue(progress)

            local rechargeColour = generalDB.Colours.SecondaryPower["RUNE_RECHARGE"]
            if rechargeColour then
                self:SetStatusBarColor(rechargeColour[1], rechargeColour[2], rechargeColour[3], rechargeColour[4] or 1)
            end
        end
    end)
end

local function UpdateRuneDisplay()
    local parent = BCDM.SecondaryPowerBar
    if not parent or #runeBars == 0 then return end

    local maxPower = 6
    local r, g, b, a = GetPowerBarColor()

    local runeReadyList = {}
    local runeOnCDList = {}

    for i = 1, maxPower do
        local runeStartTime, runeDuration, runeReady = GetRuneCooldown(i)

        if runeReady then
            table.insert(runeReadyList, { index = i })
        else
            if runeStartTime and runeDuration and runeDuration > 0 then
                local elapsed = GetTime() - runeStartTime
                local remain = math.max(0, runeDuration - elapsed)
                table.insert(runeOnCDList, { index = i, remaining = remain })
            else
                table.insert(runeOnCDList, { index = i, remaining = 999 })
            end
        end
    end

    table.sort(runeOnCDList, function(a, b) return a.remaining < b.remaining end)

    local order = {}
    for _, v in ipairs(runeReadyList) do table.insert(order, v.index) end
    for _, v in ipairs(runeOnCDList) do table.insert(order, v.index) end

    for runePosition = 1, maxPower do
        local i = order[runePosition]
        local runeBar = runeBars[i]

        runeBar:ClearAllPoints()
        if runePosition == 1 then
            runeBar:SetPoint("LEFT", parent, "LEFT", 1, 0)
        else
            runeBar:SetPoint("LEFT", runeBars[order[runePosition-1]], "RIGHT", 1, 0)
        end

        runeBar:Show()

        local _, _, runeReady = GetRuneCooldown(i)
        if runeReady then
            runeBar:SetValue(1)
            runeBar:SetStatusBarColor(r, g, b, a)
            runeBar:SetScript("OnUpdate", nil)
        else
            StartRuneOnUpdate(runeBar, i)
        end
    end
end

local function UpdateComboDisplay()
    local powerCurrent = UnitPower("player", Enum.PowerType.ComboPoints) or 0
    local powerMax = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 0
    local charged = GetUnitChargedPowerPoints("player")
    local chargedLookup = {}

    if charged then
        for _, index in ipairs(charged) do
            chargedLookup[index] = true
        end
    end

    if #comboPoints ~= powerMax then
        CreateComboPoints(powerMax)
        LayoutComboPoints()
    end

    local powerBarColourR, powerBarColourG, powerBarColourB, powerBarColourA = GetPowerBarColor()
    local chargedComboPointColourR, chargedComboPointColourG, chargedComboPointColourB, chargedComboPointColourA = unpack(BCDM.db.profile.General.Colours.SecondaryPower["CHARGED_COMBO_POINTS"] or {0.25, 0.5, 1.0, 1.0})

    for i = 1, powerMax do
        local bar = comboPoints[i]

        if i <= powerCurrent then
            bar:SetValue(1)
            if chargedLookup[i] then
                bar:SetStatusBarColor(chargedComboPointColourR, chargedComboPointColourG,
                                     chargedComboPointColourB, chargedComboPointColourA or 1)
            else
                bar:SetStatusBarColor(powerBarColourR, powerBarColourG, powerBarColourB, powerBarColourA or 1)
            end
            bar:Show()
        else
            bar:SetValue(0)
            bar:Hide()
        end
    end
end

local function StartEssenceOnUpdate(tick, tickDuration, nextTickTime)
    tick.bar:SetScript("OnUpdate", function(self)
        local now = GetTime()
        local remaining = math.max(0, nextTickTime - now)

        if remaining <= 0 then
            self:SetScript("OnUpdate", nil)
            tick.bar:SetValue(1)
            local r, g, b, a = GetPowerBarColor()
            tick.bar:SetStatusBarColor(r, g, b, a)
            return
        end

        local value = 1 - (remaining / tickDuration)
        tick.bar:SetValue(value)

        local rechargeColour = BCDM.db.profile.General.Colours.SecondaryPower["ESSENCE_RECHARGE"]
        if rechargeColour then
            tick.bar:SetStatusBarColor(rechargeColour[1], rechargeColour[2], rechargeColour[3], rechargeColour[4] or 1)
        end
    end)
end

local function UpdateEssenceDisplay()
    local parent = BCDM.SecondaryPowerBar
    if not parent or #essenceTicks == 0 then return end

    local powerCurrent = UnitPower("player", Enum.PowerType.Essence) or 0
    local r, g, b, a = GetPowerBarColor()

    for i = 1, #essenceTicks do
        local tick = essenceTicks[i]
        local bar = tick.bar

        bar:Show()

        if i <= powerCurrent then
            bar:SetScript("OnUpdate", nil)
            bar:SetValue(1)
            bar:SetStatusBarColor(r, g, b, a)
        elseif i == powerCurrent + 1 and parent._NextEssenceTick then
            local regen = GetPowerRegenForPowerType(Enum.PowerType.Essence) or 0.2
            local tickDuration = 1 / regen
            StartEssenceOnUpdate(tick, tickDuration, parent._NextEssenceTick)
        else
            bar:SetScript("OnUpdate", nil)
            bar:SetValue(0)
            bar:SetStatusBarColor(0, 0, 0, 1)
        end
    end
end

local function GetAuraStacks(spellId)
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
    if auraData then
        return auraData.applications or 0
    end
    return 0
end

local function IsInMetamorphosis(spellId)
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
    return auraData ~= nil
end

local function GetSpellCharges(spellId)
    return C_Spell.GetSpellCastCount(spellId)
end

local function UpdatePowerValues()
    local powerType = DetectSecondaryPower()
    local secondaryPowerBar = BCDM.SecondaryPowerBar
    local secondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar
    if not powerType then if secondaryPowerBar then secondaryPowerBar:Hide() end return end
    if not secondaryPowerBar then return end
    local powerCurrent = 0
    if powerType == "STAGGER" then
        BCDM:ClearTicks()
        powerCurrent = UnitStagger("player") or 0
        local powerMax = UnitHealthMax("player") or 0
        local staggerPercentage = (powerCurrent / powerMax) * 100
        secondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        SetBarValue(secondaryPowerBar.Status, powerCurrent)
        if BCDM.IS_MONK and GetSpecializationInfo(GetSpecialization()) == 268 and BCDM.db.profile.SecondaryPowerBar.ColourByState then
            local staggerPercentageColour = BCDM.db.profile.General.Colours.SecondaryPower["STAGGER_COLOURS"]
            if staggerPercentage < 30 then
                secondaryPowerBar.Status:SetStatusBarColor(staggerPercentageColour.LIGHT[1], staggerPercentageColour.LIGHT[2], staggerPercentageColour.LIGHT[3], staggerPercentageColour.LIGHT[4] or 1)
            elseif staggerPercentage < 60 then
                secondaryPowerBar.Status:SetStatusBarColor(staggerPercentageColour.MODERATE[1], staggerPercentageColour.MODERATE[2], staggerPercentageColour.MODERATE[3], staggerPercentageColour.MODERATE[4] or 1)
            else
                secondaryPowerBar.Status:SetStatusBarColor(staggerPercentageColour.HEAVY[1], staggerPercentageColour.HEAVY[2], staggerPercentageColour.HEAVY[3], staggerPercentageColour.HEAVY[4] or 1)
            end
        else
            secondaryPowerBar.Status:SetStatusBarColor(GetPowerBarColor())
        end
        local textDisplay = AbbreviateLargeNumbers(powerCurrent)
        if secondaryPowerBarDB.Text.ShowStaggerDPS and powerCurrent > 0 then
            local damagePerTick = powerCurrent / 20
            textDisplay = textDisplay .. " (" .. AbbreviateLargeNumbers(damagePerTick) .. " / 0.5s)"
        end
        secondaryPowerBar.Text:SetText(textDisplay)
        secondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Maelstrom then
        powerCurrent = GetAuraStacks(344179)
        secondaryPowerBar.Status:SetMinMaxValues(0, 10)
        secondaryPowerBar.Status:SetValue(powerCurrent)
        secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        secondaryPowerBar.Status:Show()
    elseif powerType == "SOUL" then
        local hasSoulGlutton = C_SpellBook.IsSpellKnown(1247534)
        local isInMeta = IsInMetamorphosis(1217607)
        powerCurrent = GetSpellCharges(1217605)
        secondaryPowerBar.Status:SetMinMaxValues(0, (isInMeta and 40) or (hasSoulGlutton and 35 or 50))
        secondaryPowerBar.Status:SetValue(powerCurrent)
        secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        secondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Chi then
        powerCurrent = UnitPower("player", Enum.PowerType.Chi) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.Chi) or 0
        secondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        secondaryPowerBar.Status:SetValue(powerCurrent)
        secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        secondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.SoulShards then
        if isDestruction then
            powerCurrent = UnitPower("player", Enum.PowerType.SoulShards, true)
            secondaryPowerBar.Status:SetMinMaxValues(0, 50)
            SetBarValue(secondaryPowerBar.Status, powerCurrent)
            secondaryPowerBar.Text:SetText(string.format("%.1f", powerCurrent / 10))
        else
            powerCurrent = UnitPower("player", Enum.PowerType.SoulShards, false)
            local powerMax = UnitPowerMax("player", Enum.PowerType.SoulShards) or 0
            secondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
            SetBarValue(secondaryPowerBar.Status, powerCurrent)
            secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        end
        secondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.HolyPower then
        powerCurrent = UnitPower("player", Enum.PowerType.HolyPower) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.HolyPower) or 0
        secondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        secondaryPowerBar.Status:SetValue(powerCurrent)
        secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        secondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.ComboPoints then
        secondaryPowerBar.Status:SetValue(0)
        local isRogue = select(2, UnitClass("player")) == "ROGUE"
        if isRogue then
            UpdateComboDisplay()
            secondaryPowerBar.Text:SetText(tostring(UnitPower("player", Enum.PowerType.ComboPoints) or 0))
        else
            powerCurrent = UnitPower("player", Enum.PowerType.ComboPoints) or 0
            local powerMax = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 0
            secondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
            secondaryPowerBar.Status:SetValue(powerCurrent)
            secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        end
        secondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Essence then
        -- Inspired by Sensei's Resource Bar - <https://www.curseforge.com/wow/addons/senseiclassresourcebar>
        powerCurrent = UnitPower("player", Enum.PowerType.Essence) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.Essence) or 0
        local essenceRechargeRate = GetPowerRegenForPowerType(Enum.PowerType.Essence) or 0.2
        local tickDuration = 5 / (5 / (1 / essenceRechargeRate))
        local currentTime = GetTime()
        secondaryPowerBar._NextEssenceTick = secondaryPowerBar._NextEssenceTick or nil
        secondaryPowerBar._LastEssence = secondaryPowerBar._LastEssence or powerCurrent
        if powerCurrent > secondaryPowerBar._LastEssence then
            if powerCurrent < powerMax then
                secondaryPowerBar._NextEssenceTick = currentTime + tickDuration
            else
                secondaryPowerBar._NextEssenceTick = nil
            end
        end
        if powerCurrent < powerMax and not secondaryPowerBar._NextEssenceTick then secondaryPowerBar._NextEssenceTick = currentTime + tickDuration end
        if powerCurrent >= powerMax then secondaryPowerBar._NextEssenceTick = nil end
        secondaryPowerBar._LastEssence = powerCurrent
        UpdateEssenceDisplay()
        secondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        secondaryPowerBar.Status:SetValue(powerCurrent)
        secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        secondaryPowerBar.Status:Show()
        BCDM:CreateTicks(powerMax)
    elseif powerType == Enum.PowerType.ArcaneCharges then
        powerCurrent = UnitPower("player", Enum.PowerType.ArcaneCharges) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.ArcaneCharges) or 0
        secondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        secondaryPowerBar.Status:SetValue(powerCurrent)
        secondaryPowerBar.Text:SetText(tostring(powerCurrent))
        secondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Runes then
        secondaryPowerBar.Status:Hide()
        UpdateRuneDisplay()
    end

    if not (powerType == "STAGGER" and secondaryPowerBarDB.ColourByState) then
        secondaryPowerBar.Status:SetStatusBarColor(GetPowerBarColor())
    end
    secondaryPowerBar:Show()
end

local function CreateTicksBasedOnPowerType()
    local SecondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar
    if SecondaryPowerBarDB.HideTicks then BCDM:ClearTicks() return end
    local secondaryPowerResource = DetectSecondaryPower()

    if secondaryPowerResource == "SOUL" then
        local hasSoulGlutton = C_SpellBook.IsSpellKnown(1247534)
        BCDM:CreateTicks(hasSoulGlutton and 7 or 10)
        return
    end

    if secondaryPowerResource == "STAGGER" then
        return
    end

    if secondaryPowerResource == Enum.PowerType.Runes then
        BCDM:ClearTicks()
        CreateRuneBars()
        LayoutRuneBars()
        UpdateRuneDisplay()
        return
    end

    if secondaryPowerResource == Enum.PowerType.Essence then
        local maxEssence = UnitPowerMax("player", Enum.PowerType.Essence) or 0
        CreateEssenceTicks(maxEssence)
        LayoutEssenceTicks()
        UpdateEssenceDisplay()
        BCDM:CreateTicks(maxEssence)
        return
    end

    if secondaryPowerResource == Enum.PowerType.SoulShards then
        BCDM:CreateTicks(5)
        return
    end

    if secondaryPowerResource == Enum.PowerType.Maelstrom then
        BCDM:CreateTicks(10)
        return
    end

    local maxPower = UnitPowerMax("player", secondaryPowerResource) or 0
    if maxPower > 0 then
        BCDM:CreateTicks(maxPower)
    end
end

local function UpdateBarWidth()
    local secondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar
    local secondaryPowerBar = BCDM.SecondaryPowerBar

    if not secondaryPowerBar or not secondaryPowerBarDB.MatchWidthOfAnchor then return end

    local anchorFrame = _G[secondaryPowerBarDB.Layout[2]]
    if not anchorFrame then return end

    if resizeTimer then
        resizeTimer:Cancel()
    end

    resizeTimer = C_Timer.After(0.5, function()
        local anchorWidth = anchorFrame:GetWidth()
        secondaryPowerBar:SetWidth(anchorWidth)
        local powerType = DetectSecondaryPower()

        if powerType == Enum.PowerType.Runes and #runeBars > 0 then
            LayoutRuneBars()
        elseif powerType == Enum.PowerType.ComboPoints and #comboPoints > 0 then
            LayoutComboPoints()
        elseif powerType == Enum.PowerType.Essence and #essenceTicks > 0 then
            LayoutEssenceTicks()
            UpdateEssenceDisplay()
        end

        resizeTimer = nil
    end)
end

local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() if InCombatLockdown() then return end UpdateBarWidth() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() if InCombatLockdown() then return end UpdateBarWidth() end)
end

function BCDM:CreateSecondaryPowerBar()
    local generalDB = BCDM.db.profile.General
    local powerBarDB = BCDM.db.profile.PowerBar
    local secondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar

    SetHooks()

    local secondaryPowerBar = CreateFrame("Frame", "BCDM_SecondaryPowerBar", UIParent, "BackdropTemplate")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize

    secondaryPowerBar:SetBackdrop(BCDM.BACKDROP)
    if borderSize > 0 then
        secondaryPowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    else
        secondaryPowerBar:SetBackdropBorderColor(0, 0, 0, 0)
    end
    secondaryPowerBar:SetBackdropColor(secondaryPowerBarDB.BackgroundColour[1], secondaryPowerBarDB.BackgroundColour[2], secondaryPowerBarDB.BackgroundColour[3], secondaryPowerBarDB.BackgroundColour[4])
    secondaryPowerBar:SetSize(secondaryPowerBarDB.Width, secondaryPowerBarDB.Height)

    if BCDM:RepositionSecondaryBar() then
        BCDM.PowerBar:Hide()
        secondaryPowerBar:ClearAllPoints()
        secondaryPowerBar:SetPoint(powerBarDB.Layout[1], _G[powerBarDB.Layout[2]], powerBarDB.Layout[3], powerBarDB.Layout[4], powerBarDB.Layout[5])
        secondaryPowerBar:SetHeight(secondaryPowerBarDB.HeightWithoutPrimary)
    else
        secondaryPowerBar:ClearAllPoints()
        secondaryPowerBar:SetPoint(secondaryPowerBarDB.Layout[1], _G[secondaryPowerBarDB.Layout[2]], secondaryPowerBarDB.Layout[3], secondaryPowerBarDB.Layout[4], secondaryPowerBarDB.Layout[5])
        secondaryPowerBar:SetHeight(secondaryPowerBarDB.Height)
        if powerBarDB.Enabled then BCDM.PowerBar:Show() end
    end

    secondaryPowerBar:SetFrameStrata(secondaryPowerBarDB.FrameStrata)
    secondaryPowerBar.Status = CreateFrame("StatusBar", nil, secondaryPowerBar)
    secondaryPowerBar.Status:SetPoint("TOPLEFT", secondaryPowerBar, "TOPLEFT", borderSize, -borderSize)
    secondaryPowerBar.Status:SetPoint("BOTTOMRIGHT", secondaryPowerBar, "BOTTOMRIGHT", -borderSize, borderSize)
    secondaryPowerBar.Status:SetStatusBarTexture(BCDM.Media.Foreground)

    secondaryPowerBar.TickFrame = CreateFrame("Frame", nil, secondaryPowerBar)
    secondaryPowerBar.TickFrame:SetAllPoints(secondaryPowerBar)
    secondaryPowerBar.TickFrame:SetFrameLevel(secondaryPowerBar.Status:GetFrameLevel() + 10)
    secondaryPowerBar.Ticks = {}

    secondaryPowerBar.Status:SetScript("OnSizeChanged", function() CreateTicksBasedOnPowerType() end)

    secondaryPowerBar.Text = secondaryPowerBar.Status:CreateFontString(nil, "OVERLAY")
    secondaryPowerBar.Text:SetFont(BCDM.Media.Font, secondaryPowerBarDB.Text.FontSize, generalDB.Fonts.FontFlag)
    secondaryPowerBar.Text:SetTextColor(secondaryPowerBarDB.Text.Colour[1], secondaryPowerBarDB.Text.Colour[2], secondaryPowerBarDB.Text.Colour[3], 1)
    secondaryPowerBar.Text:SetPoint(secondaryPowerBarDB.Text.Layout[1], secondaryPowerBar, secondaryPowerBarDB.Text.Layout[2], secondaryPowerBarDB.Text.Layout[3], secondaryPowerBarDB.Text.Layout[4])

    if generalDB.Fonts.Shadow.Enabled then
        secondaryPowerBar.Text:SetShadowColor(generalDB.Fonts.Shadow.Colour[1], generalDB.Fonts.Shadow.Colour[2], generalDB.Fonts.Shadow.Colour[3], generalDB.Fonts.Shadow.Colour[4])
        secondaryPowerBar.Text:SetShadowOffset(generalDB.Fonts.Shadow.OffsetX, generalDB.Fonts.Shadow.OffsetY)
    else
        secondaryPowerBar.Text:SetShadowColor(0, 0, 0, 0)
        secondaryPowerBar.Text:SetShadowOffset(0, 0)
    end

    secondaryPowerBar.Text:SetText("")
    if secondaryPowerBarDB.Text.Enabled then
        secondaryPowerBar.Text:Show()
    else
        secondaryPowerBar.Text:Hide()
    end

    BCDM.SecondaryPowerBar = secondaryPowerBar

    if secondaryPowerBarDB.Enabled then
        if DetectSecondaryPower() then
            secondaryPowerBar.Status:SetStatusBarColor(GetPowerBarColor())
            secondaryPowerBar.Status:SetMinMaxValues(0, UnitPowerMax("player"))
            secondaryPowerBar.Status:SetValue(UnitPower("player"))
            NudgeSecondaryPowerBar("BCDM_SecondaryPowerBar", -0.1, 0)
            secondaryPowerBar:Show()
        end

        secondaryPowerBar:RegisterEvent("UNIT_POWER_UPDATE")
        secondaryPowerBar:RegisterEvent("UNIT_MAXPOWER")
        secondaryPowerBar:RegisterEvent("UNIT_HEALTH")
        secondaryPowerBar:RegisterEvent("UNIT_MAXHEALTH")
        secondaryPowerBar:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
        secondaryPowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        secondaryPowerBar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        secondaryPowerBar:RegisterEvent("RUNE_POWER_UPDATE")
        secondaryPowerBar:RegisterEvent("RUNE_TYPE_UPDATE")
        secondaryPowerBar:RegisterEvent("UNIT_AURA")

        secondaryPowerBar:SetScript("OnEvent", function(self, event, ...)
            if event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE" then
                if DetectSecondaryPower() == Enum.PowerType.Runes then
                    UpdateRuneDisplay()
                end
                return
            end
            if event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_HEALTH"
                or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED"
                or event == "UNIT_AURA" then                
                local unit = ...
                if unit and unit ~= "player" then return end
            end
            UpdatePowerValues()
        end)
    else
        secondaryPowerBar:Hide()
        secondaryPowerBar:SetScript("OnEvent", nil)
        secondaryPowerBar:UnregisterAllEvents()
    end

    UpdateBarWidth()
end

function BCDM:UpdateSecondaryPowerBar()
    local cooldownManagerDB = BCDM.db.profile
    local generalDB = cooldownManagerDB.General
    local powerBarDB = cooldownManagerDB.PowerBar
    local secondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar
    local requiresSecondaryBar = DetectSecondaryPower()
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize

    if not requiresSecondaryBar then if BCDM.SecondaryPowerBar then BCDM.SecondaryPowerBar:Hide() end return end

    local secondaryPowerBar = BCDM.SecondaryPowerBar
    if not secondaryPowerBar then return end
    secondaryPowerBar:SetBackdrop(BCDM.BACKDROP)
    if borderSize > 0 then
        secondaryPowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    else
        secondaryPowerBar:SetBackdropBorderColor(0, 0, 0, 0)
    end
    secondaryPowerBar:SetBackdropColor(secondaryPowerBarDB.BackgroundColour[1], secondaryPowerBarDB.BackgroundColour[2], secondaryPowerBarDB.BackgroundColour[3], secondaryPowerBarDB.BackgroundColour[4])
    secondaryPowerBar:SetSize(secondaryPowerBarDB.Width, secondaryPowerBarDB.Height)

    if BCDM:RepositionSecondaryBar() and BCDM.db.profile.SecondaryPowerBar.SwapToPowerBarPosition then
        BCDM.PowerBar:Hide()
        secondaryPowerBar:ClearAllPoints()
        secondaryPowerBar:SetPoint(powerBarDB.Layout[1], _G[powerBarDB.Layout[2]], powerBarDB.Layout[3], powerBarDB.Layout[4], powerBarDB.Layout[5])
        secondaryPowerBar:SetHeight(secondaryPowerBarDB.HeightWithoutPrimary)
    else
        secondaryPowerBar:ClearAllPoints()
        secondaryPowerBar:SetPoint(secondaryPowerBarDB.Layout[1], _G[secondaryPowerBarDB.Layout[2]], secondaryPowerBarDB.Layout[3], secondaryPowerBarDB.Layout[4], secondaryPowerBarDB.Layout[5])
        secondaryPowerBar:SetHeight(secondaryPowerBarDB.Height)
        if powerBarDB.Enabled then BCDM.PowerBar:Show() end
    end
    secondaryPowerBar:SetFrameStrata(secondaryPowerBarDB.FrameStrata)
    secondaryPowerBar.Status:SetPoint("TOPLEFT", secondaryPowerBar, "TOPLEFT", borderSize, -borderSize)
    secondaryPowerBar.Status:SetPoint("BOTTOMRIGHT", secondaryPowerBar, "BOTTOMRIGHT", -borderSize, borderSize)
    secondaryPowerBar.Status:SetStatusBarTexture(BCDM.Media.Foreground)
    secondaryPowerBar.Status:SetStatusBarColor(GetPowerBarColor())
    secondaryPowerBar.Status:SetMinMaxValues(0, UnitPowerMax("player"))
    secondaryPowerBar.Status:SetValue(UnitPower("player"))
    secondaryPowerBar.Text:SetFont(BCDM.Media.Font, secondaryPowerBarDB.Text.FontSize, generalDB.Fonts.FontFlag)
    secondaryPowerBar.Text:SetTextColor(secondaryPowerBarDB.Text.Colour[1], secondaryPowerBarDB.Text.Colour[2], secondaryPowerBarDB.Text.Colour[3], 1)
    secondaryPowerBar.Text:ClearAllPoints()
    secondaryPowerBar.Text:SetPoint(secondaryPowerBarDB.Text.Layout[1], secondaryPowerBar, secondaryPowerBarDB.Text.Layout[2], secondaryPowerBarDB.Text.Layout[3], secondaryPowerBarDB.Text.Layout[4])
    if generalDB.Fonts.Shadow.Enabled then
        secondaryPowerBar.Text:SetShadowColor(generalDB.Fonts.Shadow.Colour[1], generalDB.Fonts.Shadow.Colour[2], generalDB.Fonts.Shadow.Colour[3], generalDB.Fonts.Shadow.Colour[4])
        secondaryPowerBar.Text:SetShadowOffset(generalDB.Fonts.Shadow.OffsetX, generalDB.Fonts.Shadow.OffsetY)
    else
        secondaryPowerBar.Text:SetShadowColor(0, 0, 0, 0)
        secondaryPowerBar.Text:SetShadowOffset(0, 0)
    end
    secondaryPowerBar.Text:SetText("")
    if secondaryPowerBarDB.Text.Enabled then secondaryPowerBar.Text:Show() else secondaryPowerBar.Text:Hide() end
    if secondaryPowerBarDB.Enabled then
        secondaryPowerBar:RegisterEvent("UNIT_POWER_UPDATE")
        secondaryPowerBar:RegisterEvent("UNIT_MAXPOWER")
        secondaryPowerBar:RegisterEvent("UNIT_HEALTH")
        secondaryPowerBar:RegisterEvent("UNIT_MAXHEALTH")
        secondaryPowerBar:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
        secondaryPowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        secondaryPowerBar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        secondaryPowerBar:RegisterEvent("RUNE_POWER_UPDATE")
        secondaryPowerBar:RegisterEvent("RUNE_TYPE_UPDATE")

        secondaryPowerBar:SetScript("OnEvent", function(self, event, ...)
            if event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE" then
                if DetectSecondaryPower() == Enum.PowerType.Runes then UpdateRuneDisplay() end
                return
            end
            if event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_HEALTH"
                or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
                local unit = ...
                if unit and unit ~= "player" then return end
            end
            UpdatePowerValues()
        end)
        secondaryPowerBar.Status:SetScript("OnSizeChanged", function()
            CreateTicksBasedOnPowerType()
            local powerType = DetectSecondaryPower()
            if powerType == Enum.PowerType.ComboPoints and #comboPoints > 0 then
                LayoutComboPoints()
            elseif powerType == Enum.PowerType.Essence and #essenceTicks > 0 then
                LayoutEssenceTicks()
                UpdateEssenceDisplay()
            end
        end)
        UpdatePowerValues()
        CreateTicksBasedOnPowerType()
        NudgeSecondaryPowerBar("BCDM_SecondaryPowerBar", -0.1, 0)
        secondaryPowerBar:Show()
    else
        secondaryPowerBar:Hide()
        secondaryPowerBar:SetScript("OnEvent", nil)
        secondaryPowerBar.Status:SetScript("OnSizeChanged", nil)
        secondaryPowerBar:UnregisterAllEvents()
    end
    UpdateBarWidth()
end

function BCDM:UpdateSecondaryPowerBarWidth()
    UpdateBarWidth()
end
