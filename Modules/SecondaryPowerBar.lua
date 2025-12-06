local _, BCDM = ...
local RuneBars = {}
local soulTicker = nil

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
        if form == CAT_FORM then return Enum.PowerType.ComboPoints end
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
    end
    return nil
end

local function FetchPowerBarColour(unit)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local SecondaryPowerBarDB = CooldownManagerDB.SecondaryBar
    if SecondaryPowerBarDB then
        if SecondaryPowerBarDB.ColourByPower then
            local powerColour = GeneralDB.CustomColours.SecondaryPower[DetectSecondaryPower()]
            if powerColour then return GeneralDB.CustomColours.SecondaryPower[DetectSecondaryPower()][1], GeneralDB.CustomColours.SecondaryPower[DetectSecondaryPower()][2], GeneralDB.CustomColours.SecondaryPower[DetectSecondaryPower()][3], GeneralDB.CustomColours.SecondaryPower[DetectSecondaryPower()][4] or 1 end
        end
        return SecondaryPowerBarDB.FGColour[1], SecondaryPowerBarDB.FGColour[2], SecondaryPowerBarDB.FGColour[3], SecondaryPowerBarDB.FGColour[4]
    end
end

local function LayoutRuneBars()
    local secondaryBar = BCDM.SecondaryPowerBar
    if not secondaryBar then return end

    local width = secondaryBar:GetWidth() - 2
    local height = secondaryBar:GetHeight()
    local spacing = 1
    local runeWidth = (width - (spacing * 5)) / 6

    for i = 1, 6 do
        local runeBar = RuneBars[i]
        runeBar:SetSize(runeWidth, height - 2)

        if i == 1 then
            runeBar:SetPoint("LEFT", secondaryBar, "LEFT", 1, 0)
        else
            runeBar:SetPoint("LEFT", RuneBars[i-1], "RIGHT", spacing, 0)
        end
    end
end

local function StartSoulTicker()
    if soulTicker then return end
    soulTicker = C_Timer.NewTicker(0.1, function()
        if DetectSecondaryPower() == "SOUL" and BCDM.SecondaryPowerBar and BCDM.SecondaryPowerBar:IsShown() then
            BCDM:UpdateSecondary()
        else
            if soulTicker then
                soulTicker:Cancel()
                soulTicker = nil
            end
        end
    end)
end

local function StartRuneOnUpdate(runeBar, runeIndex)
    local GeneralDB = BCDM.db.profile.General
    runeBar:SetScript("OnUpdate", function(self)
        local start, duration, ready = GetRuneCooldown(runeIndex)
        if ready then
            self:SetScript("OnUpdate", nil)
            self:SetValue(1)
            return
        end
        if duration and duration > 0 then
            local now       = GetTime()
            local elapsed   = now - start
            local timeLeft      = math.min(1, elapsed / duration)
            self:SetValue(timeLeft)
            runeBar:SetStatusBarColor(GeneralDB.CustomColours.SecondaryPower["RUNE_RECHARGE"][1], GeneralDB.CustomColours.SecondaryPower["RUNE_RECHARGE"][2], GeneralDB.CustomColours.SecondaryPower["RUNE_RECHARGE"][3], GeneralDB.CustomColours.SecondaryPower["RUNE_RECHARGE"][4] or 1)
        end
    end)
end

local function UpdateRuneDisplay()
    local parent = BCDM.SecondaryPowerBar
    if not parent then return end

    local maxPower = 6
    local r, g, b, a = FetchPowerBarColour("player")

    local readyList = {}
    local cdList = {}
    local now = GetTime()

    for i = 1, maxPower do
        local start, duration, ready = GetRuneCooldown(i)
        if ready then
            table.insert(readyList, { index = i })
        else
            if start and duration and duration > 0 then
                local elapsed = now - start
                local remain = math.max(0, duration - elapsed)
                local frac = math.max(0, math.min(1, elapsed / duration))
                table.insert(cdList, { index = i, remaining = remain, frac = frac })
            else
                table.insert(cdList, { index = i, remaining = 999, frac = 0 })
            end
        end
    end

    table.sort(cdList, function(a,b) return a.remaining < b.remaining end)

    local order = {}
    for _,v in ipairs(readyList) do table.insert(order, v.index) end
    for _,v in ipairs(cdList)  do table.insert(order, v.index) end

    for pos = 1, maxPower do
        local i = order[pos]
        local runeBar = RuneBars[i]
        runeBar:ClearAllPoints()
        if pos == 1 then
            runeBar:SetPoint("LEFT", parent, "LEFT", 1, 0)
        else
            runeBar:SetPoint("LEFT", RuneBars[ order[pos-1] ], "RIGHT", 1, 0)
        end
        runeBar:SetSize(runeBar:GetWidth(), parent:GetHeight() - 2)
        runeBar:Show()
        local start, duration, ready = GetRuneCooldown(i)
        if ready then
            runeBar:SetValue(1)
            runeBar:SetStatusBarColor(r, g, b, a)
            runeBar:SetScript("OnUpdate", nil)
        else
            StartRuneOnUpdate(runeBar, i)
        end
    end
end

local function CreateSecondaryPowerBar()
    local CooldownManagerDB = BCDM.db.profile
    local SecondaryPowerBarDB = CooldownManagerDB.SecondaryBar
    local SecondaryPowerBar = CreateFrame("Frame", "BCDM_SecondaryPowerBar", UIParent, "BackdropTemplate")
    SecondaryPowerBar:SetSize(200, SecondaryPowerBarDB.Height)
    SecondaryPowerBar:SetPoint(SecondaryPowerBarDB.Anchors[1], SecondaryPowerBarDB.Anchors[2], SecondaryPowerBarDB.Anchors[3], SecondaryPowerBarDB.Anchors[4], SecondaryPowerBarDB.Anchors[5])
    SecondaryPowerBar:SetBackdrop({ bgFile = BCDM.Media.PowerBarBGTexture, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, })
    SecondaryPowerBar:SetBackdropColor(unpack(SecondaryPowerBarDB.BGColour))
    SecondaryPowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    SecondaryPowerBar.StatusBar = CreateFrame("StatusBar", nil, SecondaryPowerBar)
    SecondaryPowerBar.StatusBar:SetPoint("TOPLEFT", SecondaryPowerBar, "TOPLEFT", 1, -1)
    SecondaryPowerBar.StatusBar:SetPoint("BOTTOMRIGHT", SecondaryPowerBar, "BOTTOMRIGHT", -1, 1)
    SecondaryPowerBar.StatusBar:SetStatusBarTexture(BCDM.Media.PowerBarFGTexture)
    for i = 1, 6 do
        local runeBar = CreateFrame("StatusBar", nil, SecondaryPowerBar)
        runeBar:SetMinMaxValues(0, 1)
        runeBar:SetStatusBarTexture(BCDM.Media.PowerBarFGTexture)
        runeBar:SetStatusBarColor(FetchPowerBarColour("player"))
        RuneBars[i] = runeBar
        runeBar:Hide()
    end
    SecondaryPowerBar.TickFrame = CreateFrame("Frame", nil, SecondaryPowerBar)
    SecondaryPowerBar.TickFrame:SetAllPoints(SecondaryPowerBar)
    SecondaryPowerBar.TickFrame:SetFrameLevel(SecondaryPowerBar.StatusBar:GetFrameLevel() + 10)
    SecondaryPowerBar.Ticks = {}

    local function ClearTicks() for _, tick in ipairs(SecondaryPowerBar.Ticks) do tick:Hide() end end
    local function CreateTicks(count)
        ClearTicks()
        if count <= 1 then return end
        local width = SecondaryPowerBar.StatusBar:GetWidth()
        for i = 1, count - 1 do
            local tick = SecondaryPowerBar.Ticks[i]
            if not tick then
                tick = SecondaryPowerBar.StatusBar:CreateTexture(nil, "OVERLAY")
                tick:SetColorTexture(0, 0, 0, 1)
                SecondaryPowerBar.Ticks[i] = tick
            end
            local tickPosition = (i / count) * width
            tick:ClearAllPoints()
            tick:SetSize(1, SecondaryPowerBarDB.Height - 2)
            tick:SetPoint("LEFT", SecondaryPowerBar.StatusBar, "LEFT", tickPosition - 0.1, 0)
            tick:SetDrawLayer("OVERLAY", 7)
            tick:Show()
        end
    end

    function BCDM:UpdateSecondary()
        local secondaryPowerResource = DetectSecondaryPower()
        if not secondaryPowerResource then
            SecondaryPowerBar:Hide()
            ClearTicks()
            SecondaryPowerBar.StatusBar:SetValue(0)
            return
        end
        if secondaryPowerResource == "SOUL" then
         ClearTicks()

        local soulBar = _G["DemonHunterSoulFragmentsBar"]
            if soulBar then
                if not soulBar:IsShown() then soulBar:Show() soulBar:SetAlpha(0) end

                local current = soulBar:GetValue() or 0
                local min, max = soulBar:GetMinMaxValues()

                SecondaryPowerBar.StatusBar:SetMinMaxValues(min, max)
                SecondaryPowerBar.StatusBar:SetValue(current)
                SecondaryPowerBar.StatusBar:SetStatusBarColor(FetchPowerBarColour("player"))
            else
                SecondaryPowerBar.StatusBar:SetValue(0)
            end
            return
        end
        if secondaryPowerResource == "STAGGER" then
            ClearTicks()
            local current = UnitStagger("player") or 0
            local maxHP = UnitHealthMax("player")
            SecondaryPowerBar.StatusBar:SetMinMaxValues(0, maxHP)
            SecondaryPowerBar.StatusBar:SetValue(current)
            SecondaryPowerBar.StatusBar:SetStatusBarColor(FetchPowerBarColour("player"))
            return
        end
        if secondaryPowerResource == Enum.PowerType.Runes then
            ClearTicks()
            SecondaryPowerBar.StatusBar:Hide()
            LayoutRuneBars()
            UpdateRuneDisplay()
            return
        end
        if secondaryPowerResource == Enum.PowerType.SoulShards then
            local currentDisplay = UnitPower("player", secondaryPowerResource)
            local currentRaw = UnitPower("player", secondaryPowerResource, true)
            SecondaryPowerBar.StatusBar:SetMinMaxValues(0, 50)
            SecondaryPowerBar.StatusBar:SetValue(currentRaw)
            SecondaryPowerBar.StatusBar:SetStatusBarColor(FetchPowerBarColour("player"))
            CreateTicks(5)
            return
        end
        local current = UnitPower("player", secondaryPowerResource) or 0
        local max = UnitPowerMax("player", secondaryPowerResource) or 0
        if max <= 0 then
            ClearTicks()
            SecondaryPowerBar.StatusBar:SetValue(0)
            return
        end
        SecondaryPowerBar.StatusBar:SetMinMaxValues(0, max)
        SecondaryPowerBar.StatusBar:SetValue(current)
        SecondaryPowerBar.StatusBar:SetStatusBarColor(FetchPowerBarColour("player"))
        CreateTicks(max)
    end

    BCDM:RegisterSecondaryBarEvents(SecondaryPowerBar)
    C_Timer.After(0.1, function() BCDM:UpdateSecondary() end)
    BCDM.SecondaryPowerBar = SecondaryPowerBar
end

local function UpdateSecondaryPowerTicks()
    local SecondaryPowerBar = BCDM.SecondaryPowerBar
    if not SecondaryPowerBar or not SecondaryPowerBar.Ticks or #SecondaryPowerBar.Ticks == 0 then return end
    local width = SecondaryPowerBar.StatusBar:GetWidth()
    local tickCount = 0
    for i, tick in ipairs(SecondaryPowerBar.Ticks) do
        if tick:IsShown() then tickCount = tickCount + 1 end
    end
    if tickCount == 0 then return end
    local segments = tickCount + 1
    for i = 1, tickCount do
        local tick = SecondaryPowerBar.Ticks[i]
        if tick and tick:IsShown() then
            local pos = (i / segments) * width
            tick:ClearAllPoints()
            tick:SetSize(1, SecondaryPowerBar:GetHeight() - 2)
            tick:SetPoint("LEFT", SecondaryPowerBar.StatusBar, "LEFT", pos - 0.1, 0)
        end
    end
end

function BCDM:RegisterSecondaryBarEvents(secondaryPowerBar)
    if DetectSecondaryPower() == "SOUL" then StartSoulTicker() end
    if DetectSecondaryPower() ~= nil then
        secondaryPowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        secondaryPowerBar:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        secondaryPowerBar:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        secondaryPowerBar:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        secondaryPowerBar:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        secondaryPowerBar:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
        secondaryPowerBar:SetScript("OnSizeChanged", UpdateSecondaryPowerTicks)
        secondaryPowerBar:SetScript("OnEvent", function(self, event, ...) BCDM:UpdateSecondary() end)
        secondaryPowerBar:RegisterEvent("RUNE_POWER_UPDATE")
        secondaryPowerBar:RegisterEvent("RUNE_TYPE_UPDATE")
        secondaryPowerBar:SetScript("OnEvent", function(self, event, arg1) if event == "RUNE_POWER_UPDATE" or event == "RUNE_TYPE_UPDATE" then UpdateRuneDisplay() return end BCDM:UpdateSecondary() end)
        secondaryPowerBar.StatusBar:SetScript("OnSizeChanged", function() LayoutRuneBars() end)
    else
        secondaryPowerBar:UnregisterEvent("PLAYER_ENTERING_WORLD")
        secondaryPowerBar:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
        secondaryPowerBar:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        secondaryPowerBar:UnregisterEvent("UNIT_POWER_UPDATE")
        secondaryPowerBar:UnregisterEvent("UNIT_MAXPOWER")
        secondaryPowerBar:UnregisterEvent("UNIT_DISPLAYPOWER")
        secondaryPowerBar:SetScript("OnSizeChanged", nil)
        secondaryPowerBar:SetScript("OnEvent", nil)
        if soulTicker then soulTicker:Cancel() soulTicker = nil end
    end
end

function BCDM:SetupSecondaryPowerBar()
    CreateSecondaryPowerBar()
end

function BCDM:SetSecondaryPowerBarWidth()
    local SecondaryPowerBarDB = BCDM.db.profile.SecondaryBar
    if BCDM.SecondaryPowerBar then
        local powerBarWidth = _G[SecondaryPowerBarDB.Anchors[2]]:GetWidth() + 2
        BCDM.SecondaryPowerBar:SetWidth(powerBarWidth)
    end
end

function BCDM:SetSecondaryPowerBarHeight()
    if BCDM.SecondaryPowerBar then
        BCDM.SecondaryPowerBar:SetHeight(BCDM.db.profile.SecondaryBar.Height)
    end
end

function BCDM:UpdateSecondaryPowerBar()
    local SecondaryPowerBarDB = BCDM.db.profile.SecondaryBar
    if BCDM.SecondaryPowerBar then
        BCDM:ResolveMedia()
        BCDM.SecondaryPowerBar:ClearAllPoints()
        BCDM.SecondaryPowerBar:SetPoint(SecondaryPowerBarDB.Anchors[1], SecondaryPowerBarDB.Anchors[2], SecondaryPowerBarDB.Anchors[3], SecondaryPowerBarDB.Anchors[4], SecondaryPowerBarDB.Anchors[5])
        BCDM.SecondaryPowerBar:SetHeight(SecondaryPowerBarDB.Height)
        BCDM.SecondaryPowerBar.StatusBar:SetStatusBarTexture(BCDM.Media.PowerBarFGTexture)
        BCDM.SecondaryPowerBar:SetBackdropColor(unpack(SecondaryPowerBarDB.BGColour))
        BCDM.SecondaryPowerBar.StatusBar:SetStatusBarTexture(BCDM.Media.PowerBarFGTexture)
        BCDM.SecondaryPowerBar.StatusBar:SetStatusBarColor(FetchPowerBarColour("player"))
        BCDM:UpdateSecondary()
    end
end