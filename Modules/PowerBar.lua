local _, BCDM = ...

local function FetchPowerBarColour(unit)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local PowerBarDB = CooldownManagerDB.PowerBar
    if PowerBarDB then
        if PowerBarDB.ColourByPower then
            local powerType = UnitPowerType(unit)
            local powerColour = GeneralDB.CustomColours.PrimaryPower[powerType]
            if powerColour then return GeneralDB.CustomColours.PrimaryPower[powerType][1], GeneralDB.CustomColours.PrimaryPower[powerType][2], GeneralDB.CustomColours.PrimaryPower[powerType][3], GeneralDB.CustomColours.PrimaryPower[powerType][4] or 1 end
        end
        return PowerBarDB.FGColour[1], PowerBarDB.FGColour[2], PowerBarDB.FGColour[3], PowerBarDB.FGColour[4]
    end
end

local function FetchPowerTextColour(unit)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local PowerBarDB = CooldownManagerDB.PowerBar
    if PowerBarDB then
        if PowerBarDB.Text.ColourByPower then
            local powerType = UnitPowerType(unit)
            local powerColour = GeneralDB.CustomColours.PrimaryPower[powerType]
            if powerColour then return GeneralDB.CustomColours.PrimaryPower[powerType][1], GeneralDB.CustomColours.PrimaryPower[powerType][2], GeneralDB.CustomColours.PrimaryPower[powerType][3], GeneralDB.CustomColours.PrimaryPower[powerType][4] or 1 end
        end
        return PowerBarDB.Text.Colour[1], PowerBarDB.Text.Colour[2], PowerBarDB.Text.Colour[3], PowerBarDB.Text.Colour[4]
    end
end

local function CreatePowerBar()
    local CooldownManagerDB = BCDM.db.profile
    local PowerBarDB = CooldownManagerDB.PowerBar
    local PowerBar = CreateFrame("Frame", "BCDM_PowerBar", UIParent, "BackdropTemplate")
    PowerBar:SetSize(220, PowerBarDB.Height)
    PowerBar:SetPoint(PowerBarDB.Anchors[1], PowerBarDB.Anchors[2], PowerBarDB.Anchors[3], PowerBarDB.Anchors[4], PowerBarDB.Anchors[5])
    PowerBar:SetBackdrop({bgFile = BCDM.Media.PowerBarBGTexture, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    PowerBar:SetBackdropColor(unpack(PowerBarDB.BGColour))
    PowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    PowerBar:SetFrameStrata("MEDIUM")
    PowerBar.StatusBar = CreateFrame("StatusBar", "BCDM_PowerBar_StatusBar", PowerBar)
    PowerBar.StatusBar:SetPoint("TOPLEFT", PowerBar, "TOPLEFT", 1, -1)
    PowerBar.StatusBar:SetPoint("BOTTOMRIGHT", PowerBar, "BOTTOMRIGHT", -1, 1)
    PowerBar.StatusBar:SetMinMaxValues(0, 100)
    PowerBar.StatusBar:SetStatusBarTexture(BCDM.Media.PowerBarFGTexture)
    PowerBar.StatusBar.Value = PowerBar.StatusBar:CreateFontString(nil, "OVERLAY")
    PowerBar.StatusBar.Value:SetFont(BCDM.Media.Font, PowerBarDB.Text.FontSize, BCDM.db.profile.General.FontFlag)
    PowerBar.StatusBar.Value:SetTextColor(FetchPowerTextColour("player"))
    PowerBar.StatusBar.Value:SetPoint(PowerBarDB.Text.Anchors[1], PowerBar.StatusBar, PowerBarDB.Text.Anchors[2], PowerBarDB.Text.Anchors[3], PowerBarDB.Text.Anchors[4])
    PowerBar.StatusBar.Value:SetText("")
    PowerBar.StatusBar.Value:SetShadowColor(BCDM.db.profile.General.Shadows.Colour[1], BCDM.db.profile.General.Shadows.Colour[2], BCDM.db.profile.General.Shadows.Colour[3], BCDM.db.profile.General.Shadows.Colour[4])
    PowerBar.StatusBar.Value:SetShadowOffset(BCDM.db.profile.General.Shadows.OffsetX, BCDM.db.profile.General.Shadows.OffsetY)
    PowerBar.StatusBar.Value:SetDrawLayer("OVERLAY", 7)

    local function UpdatePowerBar()
        local powerType, powerToken = UnitPowerType("player")
        local isMana = (powerType == 0)
        local current = UnitPower("player", powerType)
        local max = UnitPowerMax("player", powerType)
        if max > 0 then
            PowerBar.StatusBar:SetMinMaxValues(0, max)
            PowerBar.StatusBar:SetValue(current)
            PowerBar.StatusBar.Value:SetText(isMana and string.format("%.0f%%", UnitPowerPercent("player", Enum.PowerType.Mana, false, true)) or current)
            PowerBar.StatusBar:SetStatusBarColor(FetchPowerBarColour("player"))
        end
    end

    PowerBar:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    PowerBar:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    PowerBar:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    PowerBar:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    PowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
    PowerBar:SetScript("OnEvent", function(self, event, ...) UpdatePowerBar() end)

    C_Timer.After(0.1, UpdatePowerBar)

    BCDM.PowerBar = PowerBar
end

function BCDM:SetPowerBarWidth()
    local PowerBarDB = BCDM.db.profile.PowerBar
    if BCDM.PowerBar then
        local powerBarWidth = _G[PowerBarDB.Anchors[2]]:GetWidth() + 2
        BCDM.PowerBar:SetWidth(powerBarWidth)
    end
end

function BCDM:SetPowerBarHeight()
    if BCDM.PowerBar then
        BCDM.PowerBar:SetHeight(BCDM.db.profile.PowerBar.Height)
    end
end

function BCDM:SetupPowerBar()
    CreatePowerBar()
end

function BCDM:UpdatePowerBar()
    local PowerBarDB = BCDM.db.profile.PowerBar
    if BCDM.PowerBar then
        BCDM:ResolveMedia()
        BCDM.PowerBar:ClearAllPoints()
        BCDM.PowerBar:SetPoint(PowerBarDB.Anchors[1], PowerBarDB.Anchors[2], PowerBarDB.Anchors[3], PowerBarDB.Anchors[4], PowerBarDB.Anchors[5])
        BCDM.PowerBar:SetBackdrop({bgFile = BCDM.Media.PowerBarBGTexture, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        BCDM.PowerBar:SetBackdropColor(unpack(PowerBarDB.BGColour))
        BCDM.PowerBar:SetBackdropBorderColor(0, 0, 0, 1)
        BCDM.PowerBar.StatusBar:SetStatusBarTexture(BCDM.Media.PowerBarFGTexture)
        BCDM.PowerBar.StatusBar:SetStatusBarColor(FetchPowerBarColour("player"))
        BCDM.PowerBar.StatusBar.Value:ClearAllPoints()
        BCDM.PowerBar.StatusBar.Value:SetPoint(PowerBarDB.Text.Anchors[1], BCDM.PowerBar.StatusBar, PowerBarDB.Text.Anchors[2], PowerBarDB.Text.Anchors[3], PowerBarDB.Text.Anchors[4])
        BCDM.PowerBar.StatusBar.Value:SetFont(BCDM.Media.Font, PowerBarDB.Text.FontSize, BCDM.db.profile.General.FontFlag)
        BCDM.PowerBar.StatusBar.Value:SetTextColor(FetchPowerTextColour("player"))
        BCDM.PowerBar.StatusBar.Value:SetShadowColor(BCDM.db.profile.General.Shadows.Colour[1], BCDM.db.profile.General.Shadows.Colour[2], BCDM.db.profile.General.Shadows.Colour[3], BCDM.db.profile.General.Shadows.Colour[4])
        BCDM.PowerBar.StatusBar.Value:SetShadowOffset(BCDM.db.profile.General.Shadows.OffsetX, BCDM.db.profile.General.Shadows.OffsetY)
        BCDM:SetPowerBarHeight()
        BCDM:SetPowerBarWidth()
    end
end