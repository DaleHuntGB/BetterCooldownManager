local _, BCDM = ...

function GetPlayerClassAndSpec()
    local playerClass = select(2, UnitClass("player"))
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()
    return playerClass, playerSpecialization
end


local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() if InCombatLockdown() then return end UpdateTickBarWidth() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() if InCombatLockdown() then return end UpdateTickBarWidth() end)
end

function ConfigureTickBarStatus(tickBar, tickBarDB, playerClass, playerSpecialization)
    -- TODO make this dynamic and scale to n=3? Probably a reasonable, arbitrary celing is desired
    -- to avoid users from creating too many bars
    local spellID, spellConfig = next(tickBarDB.Spells[playerClass][playerSpecialization])
    if spellConfig ~= nil and spellConfig.isActive ~= nil and spellConfig.isActive == false then
        return
    end
    local trackedSpellCharges = C_Spell.GetSpellCharges(spellID)
    tickBar.Status:SetStatusBarColor(tickBarDB.ForegroundColour[1], tickBarDB.ForegroundColour[2], tickBarDB.ForegroundColour[3], tickBarDB.ForegroundColour[4])
    tickBar.Status:SetMinMaxValues(0, trackedSpellCharges.maxCharges)
    tickBar.Status:SetValue(trackedSpellCharges.currentCharges)
    tickBar:SetScript("OnEvent", function(self, ...)
        local current = C_Spell.GetSpellCharges(spellID)
        if current ~= nil and current.currentCharges ~= nil then
            tickBar.Status:SetValue(current.currentCharges)
        end
    end)

    tickBar.Status:SetScript("OnSizeChanged", function()
        local current = C_Spell.GetSpellCharges(spellID)
        if current ~= nil and current.currentCharges ~= nil then
            BCDM:CreateTicks(tickBar, current.maxCharges)
        end
    end)
end

function BCDM:CreateTickBar()
    local generalDB = BCDM.db.profile.General
    local tickBarDB = BCDM.db.profile.CooldownManager.TickBar

    SetHooks()

    local playerClass, playerSpecialization = GetPlayerClassAndSpec()

    local tickBar = CreateFrame("Frame", "BCDM_TickBar", UIParent, "BackdropTemplate")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    tickBar:SetBackdrop(BCDM.BACKDROP)
    if borderSize > 0 then
        tickBar:SetBackdropBorderColor(0, 0, 0, 1)
    else
        tickBar:SetBackdropBorderColor(0, 0, 0, 0)
    end
    tickBar:SetBackdropColor(tickBarDB.BackgroundColour[1], tickBarDB.BackgroundColour[2], tickBarDB.BackgroundColour[3], tickBarDB.BackgroundColour[4])
    tickBar:SetSize(tickBarDB.Width, tickBarDB.Height)
    tickBar:SetPoint(tickBarDB.Layout[1], _G[tickBarDB.Layout[2]], tickBarDB.Layout[3], tickBarDB.Layout[4], tickBarDB.Layout[5])
    tickBar:SetFrameStrata(tickBarDB.FrameStrata)

    tickBar.Status = CreateFrame("StatusBar", nil, tickBar)
    tickBar.Status:SetPoint("TOPLEFT", tickBar, "TOPLEFT", borderSize, -borderSize)
    tickBar.Status:SetPoint("BOTTOMRIGHT", tickBar, "BOTTOMRIGHT", -borderSize, borderSize)
    tickBar.Status:SetStatusBarTexture(BCDM.Media.Foreground)

    tickBar.TickFrame = CreateFrame("Frame", nil, tickBar)
    tickBar.TickFrame:SetAllPoints(tickBar)
    tickBar.TickFrame:SetFrameLevel(tickBar.Status:GetFrameLevel() + 10)
    tickBar.Ticks = {}

    tickBar.Text = tickBar.Status:CreateFontString(nil, "OVERLAY")
    tickBar.Text:SetFont(BCDM.Media.Font, tickBarDB.Text.FontSize, generalDB.Fonts.FontFlag)
    tickBar.Text:SetTextColor(tickBarDB.Text.Colour[1], tickBarDB.Text.Colour[2], tickBarDB.Text.Colour[3], 1)
    tickBar.Text:SetPoint(tickBarDB.Text.Layout[1], tickBar, tickBarDB.Text.Layout[2], tickBarDB.Text.Layout[3], tickBarDB.Text.Layout[4])

    if generalDB.Fonts.Shadow.Enabled then
        tickBar.Text:SetShadowColor(generalDB.Fonts.Shadow.Colour[1], generalDB.Fonts.Shadow.Colour[2], generalDB.Fonts.Shadow.Colour[3], generalDB.Fonts.Shadow.Colour[4])
        tickBar.Text:SetShadowOffset(generalDB.Fonts.Shadow.OffsetX, generalDB.Fonts.Shadow.OffsetY)
    else
        tickBar.Text:SetShadowColor(0, 0, 0, 0)
        tickBar.Text:SetShadowOffset(0, 0)
    end

    tickBar.Text:SetText("")
    if tickBarDB.Text.Enabled then
        tickBar.Text:Show()
    else
        tickBar.Text:Hide()
    end

    BCDM.TickBar = tickBar
    tickBar:RegisterEvent("SPELL_UPDATE_CHARGES")

    if tickBarDB.Enabled then
        if tickBarDB.Spells[playerClass] ~= nil and tickBarDB.Spells[playerClass][playerSpecialization]  ~= nil and next(tickBarDB.Spells[playerClass][playerSpecialization]) ~= nil then
            ConfigureTickBarStatus(tickBar, tickBarDB, playerClass, playerSpecialization)
            tickBar.Text:Show()
            --NudgeSecondaryPowerBar("BCDM_TickBar", -0.1, 0)
            tickBar:Show()
            --local val = 0
            --C_Timer.NewTicker(0.1, function(self)
            --    local current = C_Spell.GetSpellCharges(spellID)
            --    if current.currentCharges ~= current.maxCharges then
            --        val = val + .1
            --        print(val)
            --        tickBar.Status:SetValue(current.currentCharges + val)
            --    else
            --        val = 0
            --    end
            --end)
        end
    else
        ClearTickBar()
    end

    UpdateTickBarWidth()
end

function ClearTickBar()
    local tickBar = BCDM.TickBar
    if not tickBar then return end
    tickBar.Text:Hide()
    tickBar:Hide()
    tickBar:SetScript("OnEvent", nil)
    tickBar.Status:SetScript("OnSizeChanged", nil)
    tickBar:UnregisterAllEvents()
end

function UpdateTickBarWidth()
    local tickBarDB = BCDM.db.profile.TickBar
    local tickBar = BCDM.TickBar

    if not tickBar or not tickBarDB.MatchWidthOfAnchor then return end

    local anchorFrame = _G[tickBarDB.Layout[2]]
    if not anchorFrame then return end

    if resizeTimer then
        resizeTimer:Cancel()
    end

    resizeTimer = C_Timer.After(0.5, function()
        local anchorWidth = anchorFrame:GetWidth()
        tickBar:SetWidth(anchorWidth)
        resizeTimer = nil
    end)
end
