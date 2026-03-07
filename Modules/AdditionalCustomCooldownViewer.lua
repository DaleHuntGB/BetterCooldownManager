local _, BCDM = ...

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function ApplyCooldownText()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = CooldownManagerDB.CooldownManager.General.CooldownText
    local Viewer = _G["BCDM_AdditionalCustomCooldownViewer"]
    if not Viewer then return end
    for _, icon in ipairs({ Viewer:GetChildren() }) do
        if icon and icon.Cooldown then
            local textRegion = FetchCooldownTextRegion(icon.Cooldown)
            if textRegion then
                if CooldownTextDB.ScaleByIconSize then
                    local iconWidth = icon:GetWidth()
                    local scaleFactor = iconWidth / 36
                    textRegion:SetFont(BCDM.Media.Font, CooldownTextDB.FontSize * scaleFactor, GeneralDB.Fonts.FontFlag)
                else
                    textRegion:SetFont(BCDM.Media.Font, CooldownTextDB.FontSize, GeneralDB.Fonts.FontFlag)
                end
                textRegion:SetTextColor(CooldownTextDB.Colour[1], CooldownTextDB.Colour[2], CooldownTextDB.Colour[3], 1)
                textRegion:ClearAllPoints()
                textRegion:SetPoint(CooldownTextDB.Layout[1], icon, CooldownTextDB.Layout[2], CooldownTextDB.Layout[3], CooldownTextDB.Layout[4])
                if GeneralDB.Fonts.Shadow.Enabled then
                    textRegion:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                    textRegion:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
                else
                    textRegion:SetShadowColor(0, 0, 0, 0)
                    textRegion:SetShadowOffset(0, 0)
                end
            end
        end
    end
end

local desaturationCurve
local gcdFilterCurve

local function IsSecretNumber(value)
    return type(value) == "number" and type(issecretvalue) == "function" and issecretvalue(value)
end

local function EnsureCurves()
    if desaturationCurve and gcdFilterCurve then return end
    if not (C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step) then return end

    if not desaturationCurve then
        desaturationCurve = C_CurveUtil.CreateCurve()
        if desaturationCurve then
            desaturationCurve:SetType(Enum.LuaCurveType.Step)
            desaturationCurve:AddPoint(0, 0)
            desaturationCurve:AddPoint(0.001, 1)
        end
    end

    if not gcdFilterCurve then
        gcdFilterCurve = C_CurveUtil.CreateCurve()
        if gcdFilterCurve then
            gcdFilterCurve:SetType(Enum.LuaCurveType.Step)
            gcdFilterCurve:AddPoint(0, 0)
            gcdFilterCurve:AddPoint(1.6, 0)
            gcdFilterCurve:AddPoint(1.601, 1)
        end
    end
end

local function SetIconDesaturation(icon, value)
    if not icon then return end
    if icon.SetDesaturation then
        icon:SetDesaturation(value)
        return
    end
    if icon.SetDesaturated then
        icon:SetDesaturated(value > 0)
    end
end

local function CalculateFallbackDesaturation(startTime, duration)
    if not startTime or not duration then return 0 end
    if IsSecretNumber(startTime) or IsSecretNumber(duration) then return 0 end
    local remaining = (startTime + duration) - GetTime()
    return remaining > 0.001 and 1 or 0
end

local function GetReadableNumber(value)
    if type(value) ~= "number" then return nil end
    if IsSecretNumber(value) then return nil end
    return value
end

local function UpdateSpellIconDesaturation(customIcon, spellId)
    if not customIcon or not customIcon.Icon then return end
    EnsureCurves()

    local cooldownData = C_Spell.GetSpellCooldown(spellId)
    if cooldownData and cooldownData.isOnGCD then
        SetIconDesaturation(customIcon.Icon, 0)
        return
    end

    local spellCharges = C_Spell.GetSpellCharges(spellId)
    local currentCharges = spellCharges and GetReadableNumber(spellCharges.currentCharges)
    if currentCharges then
        if currentCharges > 0 then
            SetIconDesaturation(customIcon.Icon, 0)
            return
        end
        local chargeDuration = C_Spell.GetSpellChargeDuration and C_Spell.GetSpellChargeDuration(spellId)
        if chargeDuration and type(chargeDuration.EvaluateRemainingDuration) == "function" then
            SetIconDesaturation(customIcon.Icon, (desaturationCurve and chargeDuration:EvaluateRemainingDuration(desaturationCurve, 0)) or CalculateFallbackDesaturation(spellCharges.cooldownStartTime, spellCharges.cooldownDuration))
        else
            SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(spellCharges.cooldownStartTime, spellCharges.cooldownDuration))
        end
        return
    end

    local durationObject = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(spellId)
    if durationObject and type(durationObject.EvaluateRemainingDuration) == "function" then
        local curve = (cooldownData and cooldownData.isOnGCD) and gcdFilterCurve or desaturationCurve
        SetIconDesaturation(customIcon.Icon, (curve and durationObject:EvaluateRemainingDuration(curve, 0)) or 0)
    else
        if not cooldownData then
            SetIconDesaturation(customIcon.Icon, 0)
        else
            SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(cooldownData.startTime, cooldownData.duration))
        end
    end
end

local function CreateCustomIcon(spellId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.CooldownManager.AdditionalCustom
    if not spellId then return end
    if not C_SpellBook.IsSpellInSpellBook(spellId) then return end

    local customIcon = CreateFrame("Button", "BCDM_AdditionalCustom_" .. spellId, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end
    local iconWidth, iconHeight = BCDM:GetIconDimensions(CustomDB)
    customIcon:SetSize(iconWidth, iconHeight)
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    customIcon:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    customIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    customIcon:RegisterEvent("SPELL_UPDATE_CHARGES")
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(CustomDB.FrameStrata or "LOW")

    local HighLevelContainer = CreateFrame("Frame", nil, customIcon)
    HighLevelContainer:SetAllPoints(customIcon)
    HighLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

    customIcon.Charges = HighLevelContainer:CreateFontString(nil, "OVERLAY")
    customIcon.Charges:SetFont(BCDM.Media.Font, CustomDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    customIcon.Charges:SetPoint(CustomDB.Text.Layout[1], customIcon, CustomDB.Text.Layout[2], CustomDB.Text.Layout[3], CustomDB.Text.Layout[4])
    customIcon.Charges:SetTextColor(CustomDB.Text.Colour[1], CustomDB.Text.Colour[2], CustomDB.Text.Colour[3], 1)
    if GeneralDB.Fonts.Shadow.Enabled then
        customIcon.Charges:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        customIcon.Charges:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
    else
        customIcon.Charges:SetShadowColor(0, 0, 0, 0)
        customIcon.Charges:SetShadowOffset(0, 0)
    end

    customIcon.Cooldown = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
    customIcon.Cooldown:SetAllPoints(customIcon)
    customIcon.Cooldown:SetDrawEdge(false)
    customIcon.Cooldown:SetDrawSwipe(true)
    customIcon.Cooldown:SetDrawBling(false)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)

    customIcon:SetScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "SPELL_UPDATE_CHARGES" then
            local spellCharges = C_Spell.GetSpellCharges(spellId)
            if spellCharges then
                customIcon.Charges:SetText(tostring(spellCharges.currentCharges))
                customIcon.Cooldown:SetCooldown(spellCharges.cooldownStartTime, spellCharges.cooldownDuration)
            else
                local cooldownData = C_Spell.GetSpellCooldown(spellId)
                customIcon.Cooldown:SetCooldown(cooldownData.startTime, cooldownData.duration)
            end
            UpdateSpellIconDesaturation(self, spellId)
        end
    end)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)
    customIcon.Icon:SetTexture(C_Spell.GetSpellInfo(spellId).iconID)

    return customIcon
end

local function CreateCustomIcons(iconTable)
    local playerClass = select(2, UnitClass("player"))
    local specIndex = GetSpecialization()
    local specID, specName = specIndex and GetSpecializationInfo(specIndex)
    local playerSpecialization = BCDM:NormalizeSpecToken(specName, specID, specIndex)
    local DefensiveSpells = BCDM.db.profile.CooldownManager.AdditionalCustom.Spells

    wipe(iconTable)

    if playerSpecialization and DefensiveSpells[playerClass] and DefensiveSpells[playerClass][playerSpecialization] then

        local defensiveSpells = {}

        for spellId, data in pairs(DefensiveSpells[playerClass][playerSpecialization]) do
            if data.isActive then
                table.insert(defensiveSpells, {id = spellId, index = data.layoutIndex})
            end
        end

        table.sort(defensiveSpells, function(a, b) return a.index < b.index end)

        for _, spell in ipairs(defensiveSpells) do
            local customSpell = CreateCustomIcon(spell.id)
            if customSpell then
                table.insert(iconTable, customSpell)
            end
        end
    end
end

local function GetColumnWrapLimit(customDB)
    local wrapLimit = math.floor(tonumber(customDB.Columns) or 0)
    if wrapLimit < 1 then
        return 0
    end
    return wrapLimit
end

local function IsCenteredHorizontalLayout(point, growthDirection)
    return (point == "TOP" or point == "BOTTOM") and (growthDirection == "LEFT" or growthDirection == "RIGHT")
end

local function ShouldGrowUp(point)
    return point and point:find("BOTTOM") ~= nil
end

local function ShouldGrowLeft(point)
    return point and point:find("RIGHT") ~= nil
end

local function LayoutAdditionalCustomCooldownViewer()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.AdditionalCustom
    local AdditionalCustomCooldownViewerIcons = {}

    local growthDirection = CustomDB.GrowthDirection or "RIGHT"

    local containerAnchorFrom = CustomDB.Layout[1]
    if growthDirection == "UP" then
        local verticalFlipMap = {
            ["TOPLEFT"] = "BOTTOMLEFT",
            ["TOP"] = "BOTTOM",
            ["TOPRIGHT"] = "BOTTOMRIGHT",
            ["BOTTOMLEFT"] = "TOPLEFT",
            ["BOTTOM"] = "TOP",
            ["BOTTOMRIGHT"] = "TOPRIGHT",
        }
        containerAnchorFrom = verticalFlipMap[CustomDB.Layout[1]] or CustomDB.Layout[1]
    end

    if not BCDM.AdditionalCustomCooldownViewerContainer then
        BCDM.AdditionalCustomCooldownViewerContainer = CreateFrame("Frame", "BCDM_AdditionalCustomCooldownViewer", UIParent, "BackdropTemplate")
        BCDM.AdditionalCustomCooldownViewerContainer:SetSize(1, 1)
    end

    BCDM.AdditionalCustomCooldownViewerContainer:ClearAllPoints()
    BCDM.AdditionalCustomCooldownViewerContainer:SetFrameStrata(CustomDB.FrameStrata or "LOW")
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    BCDM.AdditionalCustomCooldownViewerContainer:SetPoint(containerAnchorFrom, anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])

    for _, child in ipairs({BCDM.AdditionalCustomCooldownViewerContainer:GetChildren()}) do child:UnregisterAllEvents() child:Hide() child:SetParent(nil) end

    CreateCustomIcons(AdditionalCustomCooldownViewerIcons)

    local iconWidth, iconHeight = BCDM:GetIconDimensions(CustomDB)
    local iconSpacing = CustomDB.Spacing
    local point = select(1, BCDM.AdditionalCustomCooldownViewerContainer:GetPoint(1))
    local isHorizontalGrowth = growthDirection == "LEFT" or growthDirection == "RIGHT"
    local wrapLimit = GetColumnWrapLimit(CustomDB)
    local lineLimit = (wrapLimit > 0) and wrapLimit or #AdditionalCustomCooldownViewerIcons
    local useCenteredLayout = IsCenteredHorizontalLayout(point, growthDirection)

    -- Calculate and set container size first
    if #AdditionalCustomCooldownViewerIcons == 0 then
        BCDM.AdditionalCustomCooldownViewerContainer:SetSize(1, 1)
    else
        local totalWidth, totalHeight
        local lineCount = math.ceil(#AdditionalCustomCooldownViewerIcons / lineLimit)

        if isHorizontalGrowth then
            local columnsInRow = math.min(lineLimit, #AdditionalCustomCooldownViewerIcons)
            totalWidth = (columnsInRow * iconWidth) + ((columnsInRow - 1) * iconSpacing)
            totalHeight = (lineCount * iconHeight) + ((lineCount - 1) * iconSpacing)
        else
            local rowsInColumn = math.min(lineLimit, #AdditionalCustomCooldownViewerIcons)
            totalWidth = (lineCount * iconWidth) + ((lineCount - 1) * iconSpacing)
            totalHeight = (rowsInColumn * iconHeight) + ((rowsInColumn - 1) * iconSpacing)
        end
        BCDM.AdditionalCustomCooldownViewerContainer:SetSize(totalWidth, totalHeight)
    end

    local LayoutConfig = {
        TOPLEFT     = { anchor = "TOPLEFT" },
        TOP         = { anchor = "TOP" },
        TOPRIGHT    = { anchor = "TOPRIGHT" },
        BOTTOMLEFT  = { anchor = "BOTTOMLEFT" },
        BOTTOM      = { anchor = "BOTTOM" },
        BOTTOMRIGHT = { anchor = "BOTTOMRIGHT" },
        LEFT        = { anchor = "LEFT" },
        RIGHT       = { anchor = "RIGHT" },
        CENTER      = { anchor = "CENTER" },
    }

    if useCenteredLayout and #AdditionalCustomCooldownViewerIcons > 0 then
        local rowCount = math.ceil(#AdditionalCustomCooldownViewerIcons / lineLimit)
        local rowDirection = ShouldGrowUp(point) and 1 or -1

        for rowIndex = 1, rowCount do
            local rowStart = ((rowIndex - 1) * lineLimit) + 1
            local rowEnd = math.min(rowStart + lineLimit - 1, #AdditionalCustomCooldownViewerIcons)
            local rowIcons = rowEnd - rowStart + 1
            local rowWidth = (rowIcons * iconWidth) + ((rowIcons - 1) * iconSpacing)
            local startOffset = -(rowWidth / 2) + (iconWidth / 2)
            local yOffset = (rowIndex - 1) * (iconHeight + iconSpacing) * rowDirection

            for i = rowStart, rowEnd do
                local spellIcon = AdditionalCustomCooldownViewerIcons[i]
                spellIcon:SetParent(BCDM.AdditionalCustomCooldownViewerContainer)
                spellIcon:SetSize(iconWidth, iconHeight)
                spellIcon:ClearAllPoints()

                local xOffset = startOffset + ((i - rowStart) * (iconWidth + iconSpacing))
                spellIcon:SetPoint("CENTER", BCDM.AdditionalCustomCooldownViewerContainer, "CENTER", xOffset, yOffset)
                ApplyCooldownText()
                spellIcon:Show()
            end
        end
    else
        for i, spellIcon in ipairs(AdditionalCustomCooldownViewerIcons) do
            spellIcon:SetParent(BCDM.AdditionalCustomCooldownViewerContainer)
            spellIcon:SetSize(iconWidth, iconHeight)
            spellIcon:ClearAllPoints()

            if i == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                spellIcon:SetPoint(config.anchor, BCDM.AdditionalCustomCooldownViewerContainer, config.anchor, 0, 0)
            else
                local isWrappedRowStart = (i - 1) % lineLimit == 0
                if isWrappedRowStart then
                    local lineAnchorIcon = AdditionalCustomCooldownViewerIcons[i - lineLimit]
                    if isHorizontalGrowth then
                        if ShouldGrowUp(point) then
                            spellIcon:SetPoint("BOTTOM", lineAnchorIcon, "TOP", 0, iconSpacing)
                        else
                            spellIcon:SetPoint("TOP", lineAnchorIcon, "BOTTOM", 0, -iconSpacing)
                        end
                    else
                        if ShouldGrowLeft(point) then
                            spellIcon:SetPoint("RIGHT", lineAnchorIcon, "LEFT", -iconSpacing, 0)
                        else
                            spellIcon:SetPoint("LEFT", lineAnchorIcon, "RIGHT", iconSpacing, 0)
                        end
                    end
                else
                    if growthDirection == "RIGHT" then
                        spellIcon:SetPoint("LEFT", AdditionalCustomCooldownViewerIcons[i - 1], "RIGHT", iconSpacing, 0)
                    elseif growthDirection == "LEFT" then
                        spellIcon:SetPoint("RIGHT", AdditionalCustomCooldownViewerIcons[i - 1], "LEFT", -iconSpacing, 0)
                    elseif growthDirection == "UP" then
                        spellIcon:SetPoint("BOTTOM", AdditionalCustomCooldownViewerIcons[i - 1], "TOP", 0, iconSpacing)
                    elseif growthDirection == "DOWN" then
                        spellIcon:SetPoint("TOP", AdditionalCustomCooldownViewerIcons[i - 1], "BOTTOM", 0, -iconSpacing)
                    end
                end
            end
            ApplyCooldownText()
            spellIcon:Show()
        end
    end

    BCDM.AdditionalCustomCooldownViewerContainer:Show()
end

function BCDM:SetupAdditionalCustomCooldownViewer()
    LayoutAdditionalCustomCooldownViewer()
end

function BCDM:UpdateAdditionalCustomCooldownViewer()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.AdditionalCustom
    if BCDM.AdditionalCustomCooldownViewerContainer then
        BCDM.AdditionalCustomCooldownViewerContainer:ClearAllPoints()
        local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
        BCDM.AdditionalCustomCooldownViewerContainer:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    end
    LayoutAdditionalCustomCooldownViewer()
end
