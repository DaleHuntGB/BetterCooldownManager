local _, BCDM = ...

local function FetchPowerBarColour()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local PowerBarDB = CooldownManagerDB.PowerBar
    if PowerBarDB then
        if PowerBarDB.ColourByType then
            local powerType = UnitPowerType("player")
            local powerColour = GeneralDB.Colours.PrimaryPower[powerType]
            if powerColour then return GeneralDB.Colours.PrimaryPower[powerType][1], GeneralDB.Colours.PrimaryPower[powerType][2], GeneralDB.Colours.PrimaryPower[powerType][3], GeneralDB.Colours.PrimaryPower[powerType][4] or 1 end
        elseif PowerBarDB.ColourByClass then
            local _, class = UnitClass("player")
            local classColour = RAID_CLASS_COLORS[class]
            if classColour then return classColour.r, classColour.g, classColour.b, 1 end
        else
            return PowerBarDB.ForegroundColour[1], PowerBarDB.ForegroundColour[2], PowerBarDB.ForegroundColour[3], PowerBarDB.ForegroundColour[4]
        end
    end
end

local function DetectSecondaryPower()
    local class = select(2, UnitClass("player"))
    local spec  = GetSpecialization()
    local specID = GetSpecializationInfo(spec)
    if class == "MONK" then
        if specID == 268 then return true end
        if specID == 269 then return true end
    elseif class == "ROGUE" then
        return true
    elseif class == "DRUID" then
        local form = GetShapeshiftFormID()
        if form == 1 then return true end
    elseif class == "PALADIN" then
        return true
    elseif class == "WARLOCK" then
        return true
    elseif class == "MAGE" then
        if specID == 62 then return true end
    elseif class == "EVOKER" then
        return true
    elseif class == "DEATHKNIGHT" then
        return true
    elseif class == "DEMONHUNTER" then
        if specID == 1480 then return true end
    elseif class == "SHAMAN" then
        if specID == 263 then return true end
    end
    return false
end

local function NudgePowerBar(powerBar, xOffset, yOffset)
    local powerBarFrame = _G[powerBar]
    if not powerBarFrame then return end
    local point, relativeTo, relativePoint, xOfs, yOfs = powerBarFrame:GetPoint(1)
    powerBarFrame:ClearAllPoints()
    powerBarFrame:SetPoint(point, relativeTo, relativePoint, xOfs + xOffset, yOfs + yOffset)
end

local function UpdatePowerValues()
    local powerCurrent = UnitPower("player")
    local powerType = UnitPowerType("player")
    local PowerBar = BCDM.PowerBar
    local GeneralDB = BCDM.db.profile.General
    if PowerBar and PowerBar.Status and powerType then
        if powerType == 0 then
            PowerBar.Text:SetText(string.format("%.0f%%", UnitPowerPercent("player", 0, false, CurveConstants.ScaleTo100)))
        else
            PowerBar.Text:SetText(tostring(powerCurrent))
        end
        PowerBar.Status:SetStatusBarColor(FetchPowerBarColour())
        PowerBar.Status:SetMinMaxValues(0, UnitPowerMax("player"))
        local smoothBars = GeneralDB.Animation and GeneralDB.Animation.SmoothBars
        if smoothBars and Enum and Enum.StatusBarInterpolation then
            PowerBar.Status:SetValue(powerCurrent, Enum.StatusBarInterpolation.ExponentialEaseOut)
        else
            PowerBar.Status:SetValue(powerCurrent)
        end
    end
end

local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() if InCombatLockdown() then return end  BCDM:UpdatePowerBarWidth() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() if InCombatLockdown() then return end  BCDM:UpdatePowerBarWidth() end)
end

local updatePowerBarHeightEventFrame = CreateFrame("Frame")
updatePowerBarHeightEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
updatePowerBarHeightEventFrame:SetScript("OnEvent", function(self, event, ...)
    local PowerBarDB = BCDM.db.profile.PowerBar
    local PowerBar = BCDM.PowerBar
    if PowerBarDB.Enabled and PowerBar then
        local hasSecondary = DetectSecondaryPower()
        PowerBar:SetHeight(hasSecondary and PowerBarDB.Height or PowerBarDB.HeightWithoutSecondary)
    end
end)

function BCDM:CreatePowerBar()
    local GeneralDB = BCDM.db.profile.General
    local PowerBarDB = BCDM.db.profile.PowerBar

    SetHooks()

    local PowerBar = CreateFrame("Frame", "BCDM_PowerBar", UIParent, "BackdropTemplate")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize

    PowerBar:SetBackdrop(BCDM.BACKDROP)
    if borderSize > 0 then
        PowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    else
        PowerBar:SetBackdropBorderColor(0, 0, 0, 0)
    end
    PowerBar:SetBackdropColor(PowerBarDB.BackgroundColour[1], PowerBarDB.BackgroundColour[2], PowerBarDB.BackgroundColour[3], PowerBarDB.BackgroundColour[4])
    local hasSecondary = DetectSecondaryPower()
    PowerBar:SetSize(PowerBarDB.Width, hasSecondary and PowerBarDB.Height or PowerBarDB.HeightWithoutSecondary)
    PowerBar:SetPoint(PowerBarDB.Layout[1], _G[PowerBarDB.Layout[2]], PowerBarDB.Layout[3], PowerBarDB.Layout[4], PowerBarDB.Layout[5])
    PowerBar:SetFrameStrata(PowerBarDB.FrameStrata or "LOW")

    if PowerBarDB.MatchWidthOfAnchor then
        local anchorFrame = _G[PowerBarDB.Layout[2]]
        if anchorFrame then
            C_Timer.After(0.1, function() local anchorWidth = anchorFrame:GetWidth() PowerBar:SetWidth(anchorWidth) end)
        end
    end

    PowerBar.Status = CreateFrame("StatusBar", nil, PowerBar)
    PowerBar.Status:SetPoint("TOPLEFT", PowerBar, "TOPLEFT", borderSize, -borderSize)
    PowerBar.Status:SetPoint("BOTTOMRIGHT", PowerBar, "BOTTOMRIGHT", -borderSize, borderSize)
    PowerBar.Status:SetStatusBarTexture(BCDM.Media.Foreground)
    PowerBar.Status:SetStatusBarColor(FetchPowerBarColour())
    PowerBar.Status:SetMinMaxValues(0, UnitPowerMax("player"))
    PowerBar.Status:SetValue(UnitPower("player"))

    PowerBar.Text = PowerBar.Status:CreateFontString(nil, "OVERLAY")
    PowerBar.Text:SetFont(BCDM.Media.Font, PowerBarDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    PowerBar.Text:SetTextColor(PowerBarDB.Text.Colour[1], PowerBarDB.Text.Colour[2], PowerBarDB.Text.Colour[3], 1)
    PowerBar.Text:SetPoint(PowerBarDB.Text.Layout[1], PowerBar, PowerBarDB.Text.Layout[2], PowerBarDB.Text.Layout[3], PowerBarDB.Text.Layout[4])
    if GeneralDB.Fonts.Shadow.Enabled then
        PowerBar.Text:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        PowerBar.Text:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
    else
        PowerBar.Text:SetShadowColor(0, 0, 0, 0)
        PowerBar.Text:SetShadowOffset(0, 0)
    end
    PowerBar.Text:SetText("")
    if PowerBarDB.Text.Enabled then PowerBar.Text:Show() else PowerBar.Text:Hide() end

    BCDM.PowerBar = PowerBar

    if PowerBarDB.Enabled then
        PowerBar:RegisterEvent("UNIT_POWER_UPDATE")
        PowerBar:RegisterEvent("UNIT_MAXPOWER")
        PowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        PowerBar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
        if PowerBarDB.FrequentUpdates then PowerBar:RegisterEvent("UNIT_POWER_FREQUENT") else PowerBar:UnregisterEvent("UNIT_POWER_FREQUENT") end
        PowerBar:SetScript("OnEvent", UpdatePowerValues)
        NudgePowerBar("BCDM_PowerBar", -0.1, 0)
    else
        PowerBar:Hide()
        PowerBar:SetScript("OnEvent", nil)
        PowerBar:UnregisterAllEvents()
    end
end

function BCDM:UpdatePowerBar()
    local GeneralDB = BCDM.db.profile.General
    local PowerBarDB = BCDM.db.profile.PowerBar
    local PowerBar = BCDM.PowerBar
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    if PowerBar then
        if PowerBarDB.Enabled then
            PowerBar:SetBackdrop(BCDM.BACKDROP)
            if borderSize > 0 then
                PowerBar:SetBackdropBorderColor(0, 0, 0, 1)
            else
                PowerBar:SetBackdropBorderColor(0, 0, 0, 0)
            end
            PowerBar.Status:SetPoint("TOPLEFT", PowerBar, "TOPLEFT", borderSize, -borderSize)
            PowerBar.Status:SetPoint("BOTTOMRIGHT", PowerBar, "BOTTOMRIGHT", -borderSize, borderSize)
            PowerBar:ClearAllPoints()
            PowerBar:SetPoint(PowerBarDB.Layout[1], _G[PowerBarDB.Layout[2]], PowerBarDB.Layout[3], PowerBarDB.Layout[4], PowerBarDB.Layout[5])
            PowerBar:SetFrameStrata(PowerBarDB.FrameStrata or "LOW")
            if PowerBarDB.MatchWidthOfAnchor then
                local anchorFrame = _G[PowerBarDB.Layout[2]]
                if anchorFrame then
                    C_Timer.After(0.1, function() local anchorWidth = anchorFrame:GetWidth() PowerBar:SetWidth(anchorWidth) end)
                end
            else
                PowerBar:SetWidth(PowerBarDB.Width)
            end
            local hasSecondary = DetectSecondaryPower()
            PowerBar:SetHeight(hasSecondary and PowerBarDB.Height or PowerBarDB.HeightWithoutSecondary)
            PowerBar:SetBackdropColor(PowerBarDB.BackgroundColour[1], PowerBarDB.BackgroundColour[2], PowerBarDB.BackgroundColour[3], PowerBarDB.BackgroundColour[4])
            PowerBar.Status:SetStatusBarTexture(BCDM.Media.Foreground)
            PowerBar.Text:SetFont(BCDM.Media.Font, PowerBarDB.Text.FontSize, BCDM.db.profile.General.Fonts.FontFlag)
            PowerBar.Text:SetTextColor(PowerBarDB.Text.Colour[1], PowerBarDB.Text.Colour[2], PowerBarDB.Text.Colour[3], 1)
            PowerBar.Text:SetPoint(PowerBarDB.Text.Layout[1], PowerBar, PowerBarDB.Text.Layout[2], PowerBarDB.Text.Layout[3], PowerBarDB.Text.Layout[4])
            if GeneralDB.Fonts.Shadow.Enabled then
                PowerBar.Text:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                PowerBar.Text:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
            else
                PowerBar.Text:SetShadowColor(0, 0, 0, 0)
                PowerBar.Text:SetShadowOffset(0, 0)
            end
            PowerBar.Status:SetMinMaxValues(0, UnitPowerMax("player"))
            PowerBar.Status:SetStatusBarColor(FetchPowerBarColour())
            PowerBar:RegisterEvent("UNIT_POWER_UPDATE")
            PowerBar:RegisterEvent("UNIT_MAXPOWER")
            PowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
            PowerBar:RegisterEvent("UPDATE_SHAPESHIFT_COOLDOWN")
            if PowerBarDB.FrequentUpdates then PowerBar:RegisterEvent("UNIT_POWER_FREQUENT") else PowerBar:UnregisterEvent("UNIT_POWER_FREQUENT") end
            PowerBar:SetScript("OnEvent", UpdatePowerValues)
            UpdatePowerValues()
            if PowerBarDB.Text.Enabled then PowerBar.Text:Show() else PowerBar.Text:Hide() end
            NudgePowerBar("BCDM_PowerBar", -0.1, 0)
            if PowerBarDB.Enabled and not BCDM.db.profile.SecondaryPowerBar.SwapToPowerBarPosition then PowerBar:Show() end
        else
            PowerBar:Hide()
            PowerBar:SetScript("OnEvent", nil)
            PowerBar:UnregisterAllEvents()
        end
    end
end

function BCDM:UpdatePowerBarWidth()
    local PowerBarDB = BCDM.db.profile.PowerBar
    local PowerBar = BCDM.PowerBar
    if PowerBarDB.Enabled and PowerBarDB.MatchWidthOfAnchor then
        local anchorFrame = _G[PowerBarDB.Layout[2]]
        if anchorFrame then
            C_Timer.After(0.5, function() local anchorWidth = anchorFrame:GetWidth() PowerBar:SetWidth(anchorWidth) end)
        end
    end
end
