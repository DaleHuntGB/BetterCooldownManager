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
    local Viewer = _G["BCDM_CustomCooldownViewer"]
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

local function CreateCustomIcon(spellId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.CooldownManager.Custom
    if not spellId then return end
    if not C_SpellBook.IsSpellInSpellBook(spellId) then return end

    local customIcon = CreateFrame("Button", "BCDM_Custom_" .. spellId, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    customIcon:SetSize(CustomDB.IconSize, CustomDB.IconSize)
    customIcon:SetPoint(CustomDB.Layout[1], _G[CustomDB.Layout[2]], CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    customIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    customIcon:RegisterEvent("SPELL_UPDATE_CHARGES")

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
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)

    customIcon:HookScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "SPELL_UPDATE_CHARGES" then
            local spellCharges = C_Spell.GetSpellCharges(spellId)
            if spellCharges then
                customIcon.Charges:SetText(tostring(spellCharges.currentCharges))
                customIcon.Cooldown:SetCooldown(spellCharges.cooldownStartTime, spellCharges.cooldownDuration)
            else
                local cooldownData = C_Spell.GetSpellCooldown(spellId)
                customIcon.Cooldown:SetCooldown(cooldownData.startTime, cooldownData.duration)
            end
        end
    end)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", 1, -1)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -1, 1)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    customIcon.Icon:SetTexCoord(iconZoom, 1 - iconZoom, iconZoom, 1 - iconZoom)
    customIcon.Icon:SetTexture(C_Spell.GetSpellInfo(spellId).iconID)

    return customIcon
end

local function CreateCustomIcons(iconTable)
    local playerClass = select(2, UnitClass("player"))
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()
    local DefensiveSpells = BCDM.db.profile.CooldownManager.Custom.Spells

    wipe(iconTable)

    if DefensiveSpells[playerClass] and DefensiveSpells[playerClass][playerSpecialization] then

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

local function LayoutCustomCooldownViewer()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Custom
    local customCooldownViewerIcons = {}

    local growthDirection = CustomDB.GrowthDirection or "RIGHT"

    local anchorFlipMap = {
        ["LEFT"] = "RIGHT",
        ["RIGHT"] = "LEFT",
        ["TOPLEFT"] = "TOPRIGHT",
        ["TOPRIGHT"] = "TOPLEFT",
        ["BOTTOMLEFT"] = "BOTTOMRIGHT",
        ["BOTTOMRIGHT"] = "BOTTOMLEFT",
        ["TOP"] = "TOP",
        ["BOTTOM"] = "BOTTOM",
        ["CENTER"] = "CENTER"
    }

    local containerAnchorFrom = CustomDB.Layout[1]
    if growthDirection == "LEFT" then
        containerAnchorFrom = anchorFlipMap[CustomDB.Layout[1]] or CustomDB.Layout[1]
    elseif growthDirection == "UP" then
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

    if not BCDM.CustomCooldownViewerContainer then
        BCDM.CustomCooldownViewerContainer = CreateFrame("Frame", "BCDM_CustomCooldownViewer", UIParent, "BackdropTemplate")
        BCDM.CustomCooldownViewerContainer:SetSize(1, 1)
        BCDM.CustomCooldownViewerContainer:SetFrameStrata("LOW")
    end

    BCDM.CustomCooldownViewerContainer:ClearAllPoints()
    BCDM.CustomCooldownViewerContainer:SetPoint(containerAnchorFrom, _G[CustomDB.Layout[2]], CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])

    for _, child in ipairs({BCDM.CustomCooldownViewerContainer:GetChildren()}) do child:UnregisterAllEvents() child:Hide() child:SetParent(nil) end

    CreateCustomIcons(customCooldownViewerIcons)

    local iconSize = CustomDB.IconSize
    local iconSpacing = CustomDB.Spacing

    local LayoutConfig = {
        TOPLEFT     = { anchor="TOPLEFT",     xMult=1,  yMult=1  },
        TOP         = { anchor="TOP",         xMult=0,  yMult=1  },
        TOPRIGHT    = { anchor="TOPRIGHT",    xMult=-1, yMult=1  },
        BOTTOMLEFT  = { anchor="BOTTOMLEFT",  xMult=1,  yMult=-1 },
        BOTTOM      = { anchor="BOTTOM",      xMult=0,  yMult=-1 },
        BOTTOMRIGHT = { anchor="BOTTOMRIGHT", xMult=-1, yMult=-1 },
        LEFT        = { anchor="LEFT",        xMult=1,  yMult=0  },
        RIGHT       = { anchor="RIGHT",       xMult=-1, yMult=0  },
        CENTER      = { anchor="CENTER",      xMult=0,  yMult=0  },
    }

    local point = select(1, BCDM.CustomCooldownViewerContainer:GetPoint(1))
    local useCenteredLayout = (point == "TOP" or point == "BOTTOM") and (growthDirection == "LEFT" or growthDirection == "RIGHT")

    if useCenteredLayout then
        local totalWidth = (#customCooldownViewerIcons * iconSize) + ((#customCooldownViewerIcons - 1) * iconSpacing)
        local startOffset = -(totalWidth / 2) + (iconSize / 2)

        for i, spellIcon in ipairs(customCooldownViewerIcons) do
            spellIcon:SetParent(BCDM.CustomCooldownViewerContainer)
            spellIcon:SetSize(iconSize, iconSize)
            spellIcon:ClearAllPoints()

            local xOffset = startOffset + ((i - 1) * (iconSize + iconSpacing))
            spellIcon:SetPoint("CENTER", BCDM.CustomCooldownViewerContainer, "CENTER", xOffset, 0)
            ApplyCooldownText()
            spellIcon:Show()
        end
    else
        for i, spellIcon in ipairs(customCooldownViewerIcons) do
            spellIcon:SetParent(BCDM.CustomCooldownViewerContainer)
            spellIcon:SetSize(iconSize, iconSize)
            spellIcon:ClearAllPoints()

            if i == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                spellIcon:SetPoint(config.anchor, BCDM.CustomCooldownViewerContainer, config.anchor, 0, 0)
            else
                if growthDirection == "RIGHT" then
                    spellIcon:SetPoint("LEFT", customCooldownViewerIcons[i - 1], "RIGHT", iconSpacing, 0)
                elseif growthDirection == "LEFT" then
                    spellIcon:SetPoint("RIGHT", customCooldownViewerIcons[i - 1], "LEFT", -iconSpacing, 0)
                elseif growthDirection == "UP" then
                    spellIcon:SetPoint("BOTTOM", customCooldownViewerIcons[i - 1], "TOP", 0, iconSpacing)
                elseif growthDirection == "DOWN" then
                    spellIcon:SetPoint("TOP", customCooldownViewerIcons[i - 1], "BOTTOM", 0, -iconSpacing)
                end
            end
            ApplyCooldownText()
            spellIcon:Show()
        end
    end

    if #customCooldownViewerIcons == 0 then
        BCDM.CustomCooldownViewerContainer:SetSize(1, 1)
    else
        local totalWidth, totalHeight = 0, 0
        if growthDirection == "RIGHT" or growthDirection == "LEFT" then
            totalWidth = (#customCooldownViewerIcons * iconSize) + ((#customCooldownViewerIcons - 1) * iconSpacing)
            totalHeight = iconSize
        elseif growthDirection == "UP" or growthDirection == "DOWN" then
            totalWidth = iconSize
            totalHeight = (#customCooldownViewerIcons * iconSize) + ((#customCooldownViewerIcons - 1) * iconSpacing)
        end
        BCDM.CustomCooldownViewerContainer:SetSize(totalWidth, totalHeight)
    end

    BCDM.CustomCooldownViewerContainer:Show()
end

function BCDM:SetupCustomCooldownViewer()
    LayoutCustomCooldownViewer()
end

function BCDM:UpdateCustomCooldownViewer()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Custom
    if BCDM.CustomCooldownViewerContainer then
        BCDM.CustomCooldownViewerContainer:ClearAllPoints()
        BCDM.CustomCooldownViewerContainer:SetPoint(CustomDB.Layout[1], _G[CustomDB.Layout[2]], CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    end
    LayoutCustomCooldownViewer()
end

function BCDM:AdjustSpellLayoutIndex(direction, spellId)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Custom
    local playerClass = select(2, UnitClass("player"))
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()
    local DefensiveSpells = CustomDB.Spells

    if not DefensiveSpells[playerClass] or not DefensiveSpells[playerClass][playerSpecialization] or not DefensiveSpells[playerClass][playerSpecialization][spellId] then return end

    local currentIndex = DefensiveSpells[playerClass][playerSpecialization][spellId].layoutIndex
    local newIndex = currentIndex + direction

    local totalSpells = 0

    for _ in pairs(DefensiveSpells[playerClass][playerSpecialization]) do totalSpells = totalSpells + 1 end
    if newIndex < 1 or newIndex > totalSpells then return end

    for _, data in pairs(DefensiveSpells[playerClass][playerSpecialization]) do
        if data.layoutIndex == newIndex then
            data.layoutIndex = currentIndex
            break
        end
    end

    DefensiveSpells[playerClass][playerSpecialization][spellId].layoutIndex = newIndex

    BCDM:UpdateCustomCooldownViewer()
end

function BCDM:AdjustSpellList(spellId, adjustingHow)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Custom
    local playerClass = select(2, UnitClass("player"))
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()
    local DefensiveSpells = CustomDB.Spells

    if not DefensiveSpells[playerClass] then
        DefensiveSpells[playerClass] = {}
    end
    if not DefensiveSpells[playerClass][playerSpecialization] then
        DefensiveSpells[playerClass][playerSpecialization] = {}
    end

    if adjustingHow == "add" then
        local maxIndex = 0
        for _, data in pairs(DefensiveSpells[playerClass][playerSpecialization]) do
            if data.layoutIndex > maxIndex then
                maxIndex = data.layoutIndex
            end
        end
        DefensiveSpells[playerClass][playerSpecialization][spellId] = { isActive = true, layoutIndex = maxIndex + 1 }
    elseif adjustingHow == "remove" then
        DefensiveSpells[playerClass][playerSpecialization][spellId] = nil
    end

    BCDM:UpdateCustomCooldownViewer()
end