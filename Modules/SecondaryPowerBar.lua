local _, BCDM = ...

local RUNE_BARS = {}
local resizeTimer = nil

local function DetectSecondaryPower()
    local class = select(2, UnitClass("player"))
    local spec  = GetSpecialization()
    local specID = GetSpecializationInfo(spec)
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

local function FetchPowerBarColour()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local SecondaryPowerBarDB = CooldownManagerDB.SecondaryPowerBar
    if SecondaryPowerBarDB then
        if SecondaryPowerBarDB.ColourByType then
            local powerType = DetectSecondaryPower()
            local powerColour = GeneralDB.Colours.SecondaryPower[powerType]
            if powerColour then return powerColour[1], powerColour[2], powerColour[3], powerColour[4] or 1 end
        elseif SecondaryPowerBarDB.ColourByClass then
            local _, class = UnitClass("player")
            local classColour = RAID_CLASS_COLORS[class]
            if classColour then return classColour.r, classColour.g, classColour.b, 1 end
        else
            return SecondaryPowerBarDB.ForegroundColour[1], SecondaryPowerBarDB.ForegroundColour[2],
                   SecondaryPowerBarDB.ForegroundColour[3], SecondaryPowerBarDB.ForegroundColour[4] or 1
        end
    end
    return 1, 1, 1, 1
end

local function CreateRuneBars()
    local parent = BCDM.SecondaryPowerBar
    if not parent then return end
    for i = 1, #RUNE_BARS do
        if RUNE_BARS[i] then
            RUNE_BARS[i]:SetScript("OnUpdate", nil)
            RUNE_BARS[i]:Hide()
            RUNE_BARS[i]:SetParent(nil)
            RUNE_BARS[i] = nil
        end
    end
    wipe(RUNE_BARS)
    for i = 1, 6 do
        local runeBar = CreateFrame("StatusBar", nil, parent)
        runeBar:SetStatusBarTexture(BCDM.Media.Foreground)
        runeBar:SetMinMaxValues(0, 1)
        runeBar:SetValue(0)
        RUNE_BARS[i] = runeBar
    end
end

local function LayoutRuneBars()
    local secondaryBar = BCDM.SecondaryPowerBar
    if not secondaryBar or #RUNE_BARS == 0 then return end

    local powerBarWidth = secondaryBar:GetWidth() - 2
    local powerBarHeight = secondaryBar:GetHeight() - 2
    local runeSpacing = 1
    local runeWidth = (powerBarWidth - (runeSpacing * 5)) / 6

    for i = 1, 6 do
        local runeBar = RUNE_BARS[i]
        if not runeBar then return end

        runeBar:ClearAllPoints()
        runeBar:SetSize(runeWidth, powerBarHeight)

        if i == 1 then
            runeBar:SetPoint("LEFT", secondaryBar, "LEFT", 1, 0)
        else
            runeBar:SetPoint("LEFT", RUNE_BARS[i-1], "RIGHT", runeSpacing, 0)
        end
    end
end

local function StartRuneOnUpdate(runeBar, runeIndex)
    local GeneralDB = BCDM.db.profile.General
    runeBar:SetScript("OnUpdate", function(self)
        local runeStartTime, runeDuration, runeReady = GetRuneCooldown(runeIndex)
        if runeReady then
            self:SetScript("OnUpdate", nil)
            self:SetValue(1)
            local r, g, b, a = FetchPowerBarColour()
            self:SetStatusBarColor(r, g, b, a)
            return
        end
        if runeDuration and runeDuration > 0 then
            local now = GetTime()
            local elapsed = now - runeStartTime
            local progress = math.min(1, elapsed / runeDuration)
            self:SetValue(progress)

            local rechargeColour = GeneralDB.Colours.SecondaryPower["RUNE_RECHARGE"]
            if rechargeColour then
                self:SetStatusBarColor(rechargeColour[1], rechargeColour[2], rechargeColour[3], rechargeColour[4] or 1)
            end
        end
    end)
end

local function UpdateRuneDisplay()
    local parent = BCDM.SecondaryPowerBar
    if not parent or #RUNE_BARS == 0 then return end

    local maxPower = 6
    local r, g, b, a = FetchPowerBarColour()

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
        local runeBar = RUNE_BARS[i]

        runeBar:ClearAllPoints()
        if runePosition == 1 then
            runeBar:SetPoint("LEFT", parent, "LEFT", 1, 0)
        else
            runeBar:SetPoint("LEFT", RUNE_BARS[order[runePosition-1]], "RIGHT", 1, 0)
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

local function FetchAuraStacks(spellId)
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
    if auraData then return auraData.applications or 0 end
    return 0
end

local function IsInMetamorphosis(spellId)
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(spellId)
    if auraData then return true end
end

local function FetchSpellCharges(spellId)
    local spellCharges = C_Spell.GetSpellCastCount(spellId)
    return spellCharges
end

local function UpdatePowerValues()
    local powerType = DetectSecondaryPower()
    local SecondaryPowerBar = BCDM.SecondaryPowerBar
    if not powerType then if SecondaryPowerBar then SecondaryPowerBar:Hide() end return end
    if not SecondaryPowerBar then return end

    local powerCurrent = 0

    if powerType == "STAGGER" then
        BCDM:ClearTicks()
        powerCurrent = UnitStagger("player") or 0
        local powerMax = UnitHealthMax("player") or 0
        SecondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(AbbreviateLargeNumbers(powerCurrent)))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Maelstrom then
        powerCurrent = FetchAuraStacks(344179)
        SecondaryPowerBar.Status:SetMinMaxValues(0, 10)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(powerCurrent))
        SecondaryPowerBar.Status:Show()
    elseif powerType == "SOUL" then
        local hasSoulGlutton = C_SpellBook.IsSpellKnown(1247534)
        local isInMeta = IsInMetamorphosis(1217607)
        powerCurrent = FetchSpellCharges(1217605)
        SecondaryPowerBar.Status:SetMinMaxValues(0, (isInMeta and 40) or (hasSoulGlutton and 35 or 50))
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(powerCurrent))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Chi then
        powerCurrent = UnitPower("player", Enum.PowerType.Chi) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.Chi) or 0
        SecondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(powerCurrent))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.SoulShards then
        powerCurrent = UnitPower("player", Enum.PowerType.SoulShards, true)
        SecondaryPowerBar.Status:SetMinMaxValues(0, 50)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(string.format("%.1f", powerCurrent / 10))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.HolyPower then
        powerCurrent = UnitPower("player", Enum.PowerType.HolyPower) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.HolyPower) or 0
        SecondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(powerCurrent))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.ComboPoints then
        powerCurrent = UnitPower("player", Enum.PowerType.ComboPoints) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.ComboPoints) or 0
        SecondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(powerCurrent))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Essence then
        powerCurrent = UnitPower("player", Enum.PowerType.Essence) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.Essence) or 0
        SecondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(powerCurrent))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.ArcaneCharges then
        powerCurrent = UnitPower("player", Enum.PowerType.ArcaneCharges) or 0
        local powerMax = UnitPowerMax("player", Enum.PowerType.ArcaneCharges) or 0
        SecondaryPowerBar.Status:SetMinMaxValues(0, powerMax)
        SecondaryPowerBar.Status:SetValue(powerCurrent)
        SecondaryPowerBar.Text:SetText(tostring(powerCurrent))
        SecondaryPowerBar.Status:Show()
    elseif powerType == Enum.PowerType.Runes then SecondaryPowerBar.Status:Hide() UpdateRuneDisplay() end
    SecondaryPowerBar:Show()
end

local function CreateTicksBasedOnPowerType()
    local secondaryPowerResource = DetectSecondaryPower()
    if secondaryPowerResource == "SOUL" then local hasSoulGlutton = C_SpellBook.IsSpellKnown(1247534) BCDM:CreateTicks(hasSoulGlutton and 7 or 10) return end
    if secondaryPowerResource == "STAGGER" then return end
    if secondaryPowerResource == Enum.PowerType.Runes then
        BCDM:ClearTicks()
        CreateRuneBars()
        LayoutRuneBars()
        UpdateRuneDisplay()
        return
    end
    if secondaryPowerResource == Enum.PowerType.SoulShards then BCDM:CreateTicks(5) return end
    if secondaryPowerResource == Enum.PowerType.Maelstrom then BCDM:CreateTicks(10) return end
    local maxPower = UnitPowerMax("player", secondaryPowerResource) or 0
    if maxPower > 0 then BCDM:CreateTicks(maxPower) end
end

local function UpdateBarWidth()
    local SecondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar
    local SecondaryPowerBar = BCDM.SecondaryPowerBar

    if not SecondaryPowerBar or not SecondaryPowerBarDB.MatchWidthOfAnchor then return end

    local anchorFrame = _G[SecondaryPowerBarDB.Layout[2]]
    if not anchorFrame then return end
    if resizeTimer then resizeTimer:Cancel() end
    resizeTimer = C_Timer.After(0.1, function()
        local anchorWidth = anchorFrame:GetWidth()
        SecondaryPowerBar:SetWidth(anchorWidth)
        if DetectSecondaryPower() == Enum.PowerType.Runes and #RUNE_BARS > 0 then LayoutRuneBars() end
        resizeTimer = nil
    end)
end

local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() if InCombatLockdown() then return end UpdateBarWidth() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() if InCombatLockdown() then return end UpdateBarWidth() end)
end

function BCDM:CreateSecondaryPowerBar()
    local GeneralDB = BCDM.db.profile.General
    local SecondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar

    SetHooks()

    local SecondaryPowerBar = CreateFrame("Frame", "BCDM_SecondaryPowerBar", UIParent, "BackdropTemplate")

    SecondaryPowerBar:SetBackdrop(BCDM.BACKDROP)
    SecondaryPowerBar:SetBackdropColor(SecondaryPowerBarDB.BackgroundColour[1], SecondaryPowerBarDB.BackgroundColour[2], SecondaryPowerBarDB.BackgroundColour[3], SecondaryPowerBarDB.BackgroundColour[4])
    SecondaryPowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    SecondaryPowerBar:SetSize(SecondaryPowerBarDB.Width, SecondaryPowerBarDB.Height)
    SecondaryPowerBar:SetPoint(SecondaryPowerBarDB.Layout[1], _G[SecondaryPowerBarDB.Layout[2]], SecondaryPowerBarDB.Layout[3], SecondaryPowerBarDB.Layout[4], SecondaryPowerBarDB.Layout[5])
    SecondaryPowerBar:SetFrameStrata("MEDIUM")

    SecondaryPowerBar.Status = CreateFrame("StatusBar", nil, SecondaryPowerBar)
    SecondaryPowerBar.Status:SetPoint("TOPLEFT", SecondaryPowerBar, "TOPLEFT", 1, -1)
    SecondaryPowerBar.Status:SetPoint("BOTTOMRIGHT", SecondaryPowerBar, "BOTTOMRIGHT", -1, 1)
    SecondaryPowerBar.Status:SetStatusBarTexture(BCDM.Media.Foreground)

    SecondaryPowerBar.TickFrame = CreateFrame("Frame", nil, SecondaryPowerBar)
    SecondaryPowerBar.TickFrame:SetAllPoints(SecondaryPowerBar)
    SecondaryPowerBar.TickFrame:SetFrameLevel(SecondaryPowerBar.Status:GetFrameLevel() + 10)
    SecondaryPowerBar.Ticks = {}

    SecondaryPowerBar.Status:SetScript("OnSizeChanged", function() CreateTicksBasedOnPowerType() end)

    SecondaryPowerBar.Text = SecondaryPowerBar.Status:CreateFontString(nil, "OVERLAY")
    SecondaryPowerBar.Text:SetFont(BCDM.Media.Font, SecondaryPowerBarDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    SecondaryPowerBar.Text:SetTextColor(SecondaryPowerBarDB.Text.Colour[1], SecondaryPowerBarDB.Text.Colour[2], SecondaryPowerBarDB.Text.Colour[3], 1)
    SecondaryPowerBar.Text:SetPoint(SecondaryPowerBarDB.Text.Layout[1], SecondaryPowerBar, SecondaryPowerBarDB.Text.Layout[2], SecondaryPowerBarDB.Text.Layout[3], SecondaryPowerBarDB.Text.Layout[4])

    if GeneralDB.Fonts.Shadow.Enabled then
        SecondaryPowerBar.Text:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        SecondaryPowerBar.Text:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
    else
        SecondaryPowerBar.Text:SetShadowColor(0, 0, 0, 0)
        SecondaryPowerBar.Text:SetShadowOffset(0, 0)
    end

    SecondaryPowerBar.Text:SetText("")
    if SecondaryPowerBarDB.Text.Enabled then
        SecondaryPowerBar.Text:Show()
    else
        SecondaryPowerBar.Text:Hide()
    end

    BCDM.SecondaryPowerBar = SecondaryPowerBar

    if SecondaryPowerBarDB.Enabled then
        if DetectSecondaryPower() then
            SecondaryPowerBar.Status:SetStatusBarColor(FetchPowerBarColour())
            SecondaryPowerBar.Status:SetMinMaxValues(0, UnitPowerMax("player"))
            SecondaryPowerBar.Status:SetValue(UnitPower("player"))
            NudgeSecondaryPowerBar("BCDM_SecondaryPowerBar", -0.1, 0)
            SecondaryPowerBar:Show()
        end

        SecondaryPowerBar:RegisterEvent("UNIT_POWER_UPDATE")
        SecondaryPowerBar:RegisterEvent("UNIT_MAXPOWER")
        SecondaryPowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        SecondaryPowerBar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        SecondaryPowerBar:RegisterEvent("RUNE_POWER_UPDATE")
        SecondaryPowerBar:RegisterEvent("RUNE_TYPE_UPDATE")

        SecondaryPowerBar:SetScript("OnEvent", function(self, event, ...)
            if event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE" then
                if DetectSecondaryPower() == Enum.PowerType.Runes then
                    UpdateRuneDisplay()
                end
            else
                UpdatePowerValues()
            end
        end)
    else
        SecondaryPowerBar:Hide()
        SecondaryPowerBar:SetScript("OnEvent", nil)
        SecondaryPowerBar:UnregisterAllEvents()
    end

    UpdateBarWidth()
end

function BCDM:UpdateSecondaryPowerBar()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local SecondaryPowerBarDB = BCDM.db.profile.SecondaryPowerBar
    local requiresSecondaryBar = DetectSecondaryPower()

    if not requiresSecondaryBar then if BCDM.SecondaryPowerBar then BCDM.SecondaryPowerBar:Hide() end return end

    local SecondaryPowerBar = BCDM.SecondaryPowerBar
    if not SecondaryPowerBar then return end

    SecondaryPowerBar:SetBackdrop(BCDM.BACKDROP)
    SecondaryPowerBar:SetBackdropColor(SecondaryPowerBarDB.BackgroundColour[1], SecondaryPowerBarDB.BackgroundColour[2], SecondaryPowerBarDB.BackgroundColour[3], SecondaryPowerBarDB.BackgroundColour[4])
    SecondaryPowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    SecondaryPowerBar:SetSize(SecondaryPowerBarDB.Width, SecondaryPowerBarDB.Height)

    SecondaryPowerBar:ClearAllPoints()
    SecondaryPowerBar:SetPoint(SecondaryPowerBarDB.Layout[1], _G[SecondaryPowerBarDB.Layout[2]], SecondaryPowerBarDB.Layout[3], SecondaryPowerBarDB.Layout[4], SecondaryPowerBarDB.Layout[5])

    SecondaryPowerBar.Status:SetPoint("TOPLEFT", SecondaryPowerBar, "TOPLEFT", 1, -1)
    SecondaryPowerBar.Status:SetPoint("BOTTOMRIGHT", SecondaryPowerBar, "BOTTOMRIGHT", -1, 1)
    SecondaryPowerBar.Status:SetStatusBarTexture(BCDM.Media.Foreground)
    SecondaryPowerBar.Status:SetStatusBarColor(FetchPowerBarColour())
    SecondaryPowerBar.Status:SetMinMaxValues(0, UnitPowerMax("player"))
    SecondaryPowerBar.Status:SetValue(UnitPower("player"))

    SecondaryPowerBar.Text:SetFont(BCDM.Media.Font, SecondaryPowerBarDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    SecondaryPowerBar.Text:SetTextColor(SecondaryPowerBarDB.Text.Colour[1], SecondaryPowerBarDB.Text.Colour[2], SecondaryPowerBarDB.Text.Colour[3], 1)
    SecondaryPowerBar.Text:SetPoint(SecondaryPowerBarDB.Text.Layout[1], SecondaryPowerBar, SecondaryPowerBarDB.Text.Layout[2], SecondaryPowerBarDB.Text.Layout[3], SecondaryPowerBarDB.Text.Layout[4])

    if GeneralDB.Fonts.Shadow.Enabled then
        SecondaryPowerBar.Text:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        SecondaryPowerBar.Text:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
    else
        SecondaryPowerBar.Text:SetShadowColor(0, 0, 0, 0)
        SecondaryPowerBar.Text:SetShadowOffset(0, 0)
    end

    SecondaryPowerBar.Text:SetText("")
    if SecondaryPowerBarDB.Text.Enabled then SecondaryPowerBar.Text:Show() else SecondaryPowerBar.Text:Hide() end

    if SecondaryPowerBarDB.Enabled then
        SecondaryPowerBar:RegisterEvent("UNIT_POWER_UPDATE")
        SecondaryPowerBar:RegisterEvent("UNIT_MAXPOWER")
        SecondaryPowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        SecondaryPowerBar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        SecondaryPowerBar:RegisterEvent("RUNE_POWER_UPDATE")
        SecondaryPowerBar:RegisterEvent("RUNE_TYPE_UPDATE")

        SecondaryPowerBar:SetScript("OnEvent", function(self, event, ...) if event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE" then if DetectSecondaryPower() == Enum.PowerType.Runes then UpdateRuneDisplay() end else UpdatePowerValues() end end)

        SecondaryPowerBar.Status:SetScript("OnSizeChanged", function() CreateTicksBasedOnPowerType() end)

        UpdatePowerValues()
        CreateTicksBasedOnPowerType()
        NudgeSecondaryPowerBar("BCDM_SecondaryPowerBar", -0.1, 0)
        SecondaryPowerBar:Show()
    else
        SecondaryPowerBar:Hide()
        SecondaryPowerBar:SetScript("OnEvent", nil)
        SecondaryPowerBar.Status:SetScript("OnSizeChanged", nil)
        SecondaryPowerBar:UnregisterAllEvents()
    end

    UpdateBarWidth()
end

function BCDM:UpdateSecondaryPowerBarWidth()
    UpdateBarWidth()
end