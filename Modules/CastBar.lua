local _, BCDM = ...

local function FetchCastBarColour(unit)
    local CooldownManagerDB = BCDM.db.profile
    local CastBarDB = CooldownManagerDB.CastBar
    if CastBarDB.ColourByClass then
        local _, class = UnitClass(unit)
        local classColour = RAID_CLASS_COLORS[class]
        if classColour then return classColour.r, classColour.g, classColour.b, 1 end
    end
    return CastBarDB.FGColour[1], CastBarDB.FGColour[2], CastBarDB.FGColour[3], CastBarDB.FGColour[4]
end

local function CreateCastBar()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CastBarDB = CooldownManagerDB.CastBar
    if BCDM.CastBar then return end
    local CastBarContainer = CreateFrame("Frame", "BCDM_CastBarContainer", UIParent, "BackdropTemplate")
    CastBarContainer:SetPoint(CastBarDB.Anchors[1], CastBarDB.Anchors[2], CastBarDB.Anchors[3], CastBarDB.Anchors[4], CastBarDB.Anchors[5])
    CastBarContainer:SetSize(224, CastBarDB.Height)
    CastBarContainer:SetBackdrop({ bgFile = BCDM.Media.CastBarBGTexture, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, })
    CastBarContainer:SetBackdropColor(20/255, 20/255, 20/255, 1)
    CastBarContainer:SetBackdropBorderColor(0, 0, 0, 1)

    local CastBarIcon = CastBarContainer:CreateTexture("BCDM_CastBarIcon", "ARTWORK")
    CastBarIcon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
    CastBarIcon:SetPoint("LEFT", CastBarContainer, "LEFT", 1, 0)
    CastBarIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local CastBar = CreateFrame("StatusBar", "BCDM_CastBar", CastBarContainer)
    CastBar:SetPoint("LEFT", CastBarIcon, "RIGHT", 0, 0)
    CastBar:SetPoint("TOPRIGHT", CastBarContainer, "TOPRIGHT", 1, -1)
    CastBar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
    CastBar:SetMinMaxValues(0, 100)
    CastBar:SetStatusBarTexture(BCDM.Media.CastBarFGTexture)
    CastBar:SetStatusBarColor(FetchCastBarColour("player"))

    CastBar.SpellName = CastBar:CreateFontString(nil, "OVERLAY")
    CastBar.SpellName:SetFont(BCDM.Media.Font, CastBarDB.SpellName.FontSize, BCDM.db.profile.General.FontFlag)
    CastBar.SpellName:SetPoint(CastBarDB.SpellName.Anchors[1], CastBar, CastBarDB.SpellName.Anchors[2], CastBarDB.SpellName.Anchors[3], CastBarDB.SpellName.Anchors[4])
    CastBar.SpellName:SetText("")
    CastBar.SpellName:SetTextColor(CastBarDB.SpellName.Colour[1], CastBarDB.SpellName.Colour[2], CastBarDB.SpellName.Colour[3], CastBarDB.SpellName.Colour[4])
    CastBar.SpellName:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
    CastBar.SpellName:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)

    CastBar.Duration = CastBar:CreateFontString(nil, "OVERLAY")
    CastBar.Duration:SetFont(BCDM.Media.Font, CastBarDB.Duration.FontSize, BCDM.db.profile.General.FontFlag)
    CastBar.Duration:SetPoint(CastBarDB.Duration.Anchors[1], CastBar, CastBarDB.Duration.Anchors[2], CastBarDB.Duration.Anchors[3], CastBarDB.Duration.Anchors[4])
    CastBar.Duration:SetText("")
    CastBar.Duration:SetTextColor(CastBarDB.Duration.Colour[1], CastBarDB.Duration.Colour[2], CastBarDB.Duration.Colour[3], CastBarDB.Duration.Colour[4])
    CastBar.Duration:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
    CastBar.Duration:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)

    CastBar.Icon = CastBarIcon

    CastBar:SetScript("OnShow", function(self)
        local spellName, _, icon = UnitCastingInfo("player")
        if not spellName then spellName, _, icon = UnitChannelInfo("player") end
        if icon then
            self.Icon:SetTexture(icon)
            self.Icon:Show()
        else
            self.Icon:Hide()
        end
    end)

    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player")

    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")

    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "player")
    CastBar:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")

    CastBar:SetScript("OnEvent", function(self, event, unit)
        if unit ~= "player" then return end

        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
            local name, _, _, startTime, endTime = UnitCastingInfo("player")
            if not name then return end
            self.isChannel = false
            self.startTime = startTime
            self.endTime = endTime
            self:SetMinMaxValues(0, endTime - startTime)
            self:SetValue((GetTime() * 1000) - startTime)
            self.SpellName:SetText(name)
            self:Show()
            BCDM.CastBarContainer:Show()
            self:SetScript("OnUpdate", function(self)
                local now = GetTime() * 1000
                local elapsed = now - self.startTime
                local remaining = (self.endTime - now) / 1000
                if not UnitCastingInfo("player") then
                    self:Hide()
                    BCDM.CastBarContainer:Hide()
                    self:SetScript("OnUpdate", nil)
                    return
                end
                if elapsed < 0 then elapsed = 0 end
                self:SetValue(elapsed)
                local seconds = remaining
                if seconds < BCDM.db.profile.CastBar.Duration.ExpirationThreshold then
                    self.Duration:SetText(string.format("%.1f", seconds))
                else
                    self.Duration:SetText(string.format("%d", seconds))
                end
            end)
            return
        end

        if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
            local name, _, _, startTime, endTime = UnitChannelInfo("player")
            if not name then return end
            self.isChannel = true
            self.startTime = startTime
            self.endTime = endTime
            self:SetMinMaxValues(0, endTime - startTime)
            self:SetValue(endTime - (GetTime() * 1000))
            self.SpellName:SetText(name)
            self:Show()
            BCDM.CastBarContainer:Show()
            self:SetScript("OnUpdate", function(self)
                local now = GetTime() * 1000
                local remaining = self.endTime - now
                local chanName = UnitChannelInfo("player")
                if not chanName then
                    self:Hide()
                    BCDM.CastBarContainer:Hide()
                    self:SetScript("OnUpdate", nil)
                    return
                end
                if remaining < 0 then remaining = 0 end
                self:SetValue(remaining)
                local seconds = remaining / 1000
                if seconds < BCDM.db.profile.CastBar.Duration.ExpirationThreshold then
                    self.Duration:SetText(string.format("%.1f", seconds))
                else
                    self.Duration:SetText(string.format("%d", seconds))
                end
            end)
            return
        end

        if event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
            if not UnitCastingInfo("player") and not UnitChannelInfo("player") then
                self:Hide()
                BCDM.CastBarContainer:Hide()
                self:SetScript("OnUpdate", nil)
            end
            return
        end
    end)

    BCDM.CastBar = CastBar
    BCDM.CastBarContainer = CastBarContainer
    CastBar:Hide()
    CastBarContainer:Hide()
end

function BCDM:SetupCastBar()
    CreateCastBar()
    C_Timer.After(1, function() PlayerCastingBarFrame:UnregisterAllEvents() end)
end

function BCDM:SetCastBarHeight()
    local CastBarDB = BCDM.db.profile.CastBar
    if BCDM.CastBar then
        BCDM.CastBarContainer:SetHeight(CastBarDB.Height)
        BCDM.CastBar.Icon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
    end
end

function BCDM:SetCastBarWidth()
    local CastBarDB = BCDM.db.profile.CastBar
    if BCDM.CastBar then
        local powerBarAnchor = _G[CastBarDB.Anchors[2]] == _G["BCDM_PowerBar"]
        local castBarWidth = (powerBarAnchor and _G[CastBarDB.Anchors[2]]:GetWidth()) or _G[CastBarDB.Anchors[2]]:GetWidth() + 2
        BCDM.CastBar:SetWidth(castBarWidth)
        BCDM.CastBarContainer:SetWidth(castBarWidth)
    end
end

function BCDM:UpdateCastBar()
    local GeneralDB = BCDM.db.profile.General
    local CastBarDB = BCDM.db.profile.CastBar
    if BCDM.CastBar then
        BCDM:ResolveMedia()
        BCDM.CastBarContainer:ClearAllPoints()
        BCDM.CastBarContainer:SetPoint(CastBarDB.Anchors[1], CastBarDB.Anchors[2], CastBarDB.Anchors[3], CastBarDB.Anchors[4], CastBarDB.Anchors[5])
        BCDM.CastBarContainer:SetBackdrop({bgFile = BCDM.Media.CastBarBGTexture, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        BCDM.CastBarContainer:SetBackdropColor(unpack(CastBarDB.BGColour))
        BCDM.CastBarContainer:SetBackdropBorderColor(0, 0, 0, 1)
        BCDM.CastBar:SetStatusBarTexture(BCDM.Media.CastBarFGTexture)
        BCDM.CastBar:SetStatusBarColor(FetchCastBarColour("player"))
        BCDM.CastBar.SpellName:ClearAllPoints()
        BCDM.CastBar.SpellName:SetPoint(CastBarDB.SpellName.Anchors[1], BCDM.CastBar, CastBarDB.SpellName.Anchors[2], CastBarDB.SpellName.Anchors[3], CastBarDB.SpellName.Anchors[4])
        BCDM.CastBar.SpellName:SetFont(BCDM.Media.Font, CastBarDB.SpellName.FontSize, BCDM.db.profile.General.FontFlag)
        BCDM.CastBar.SpellName:SetTextColor(CastBarDB.SpellName.Colour[1], CastBarDB.SpellName.Colour[2], CastBarDB.SpellName.Colour[3], CastBarDB.SpellName.Colour[4])
        BCDM.CastBar.SpellName:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
        BCDM.CastBar.SpellName:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        BCDM.CastBar.Duration:ClearAllPoints()
        BCDM.CastBar.Duration:SetPoint(CastBarDB.Duration.Anchors[1], BCDM.CastBar, CastBarDB.Duration.Anchors[2], CastBarDB.Duration.Anchors[3], CastBarDB.Duration.Anchors[4])
        BCDM.CastBar.Duration:SetFont(BCDM.Media.Font, CastBarDB.Duration.FontSize, BCDM.db.profile.General.FontFlag)
        BCDM.CastBar.Duration:SetTextColor(CastBarDB.Duration.Colour[1], CastBarDB.Duration.Colour[2], CastBarDB.Duration.Colour[3], CastBarDB.Duration.Colour[4])
        BCDM.CastBar.Duration:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
        BCDM.CastBar.Duration:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        BCDM:SetCastBarHeight()
        BCDM:SetCastBarWidth()
    end
end