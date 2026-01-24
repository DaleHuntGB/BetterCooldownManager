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
    local Viewer = _G["BCDM_CustomItemSpellBar"]
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

local function IsCooldownFrameActive(customIcon)
    -- Thanks Mapko for this idea!
    if not customIcon or not customIcon.Cooldown then return end

    if customIcon.Cooldown:IsShown() then
        customIcon.Icon:SetDesaturated(true)
    else
        customIcon.Icon:SetDesaturated(false)
    end
end

local function FetchItemData(itemId)
    local itemCount = C_Item.GetItemCount(itemId)
    if itemId == 224464 or itemId == 5512 then itemCount = C_Item.GetItemCount(itemId, false, true) end
    local startTime, durationTime = C_Item.GetItemCooldown(itemId)
    return itemCount, startTime, durationTime
end

local function CreateCustomItemIcon(itemId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.CooldownManager.ItemSpell
    if not itemId then return end
    if not C_Item.GetItemInfo(itemId) then return end

    local customIcon = CreateFrame("Button", "BCDM_Custom_" .. itemId, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end
    customIcon:SetSize(CustomDB.IconSize, CustomDB.IconSize)
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    customIcon:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    customIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    customIcon:RegisterEvent("ITEM_COUNT_CHANGED")
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(CustomDB.FrameStrata or "LOW")

    local HighLevelContainer = CreateFrame("Frame", nil, customIcon)
    HighLevelContainer:SetAllPoints(customIcon)
    HighLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

    customIcon.Charges = HighLevelContainer:CreateFontString(nil, "OVERLAY")
    customIcon.Charges:SetFont(BCDM.Media.Font, CustomDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    customIcon.Charges:SetPoint(CustomDB.Text.Layout[1], customIcon, CustomDB.Text.Layout[2], CustomDB.Text.Layout[3], CustomDB.Text.Layout[4])
    customIcon.Charges:SetTextColor(CustomDB.Text.Colour[1], CustomDB.Text.Colour[2], CustomDB.Text.Colour[3], 1)
    customIcon.Charges:SetText(tostring(select(1, FetchItemData(itemId)) or ""))
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
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "ITEM_COUNT_CHANGED" then
            local itemCount, startTime, durationTime = FetchItemData(itemId)
            if itemCount then
                customIcon.Charges:SetText(tostring(itemCount))
                customIcon.Cooldown:SetCooldown(startTime, durationTime)
                if itemCount <= 0 then
                    customIcon.Icon:SetDesaturated(true)
                    customIcon.Charges:SetText("")
                else
                    customIcon.Icon:SetDesaturated(false)
                    customIcon.Charges:SetText(tostring(itemCount))
                end
                customIcon.Charges:SetAlphaFromBoolean(itemCount > 1, 1, 0)
            end
        end
    end)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    customIcon.Icon:SetTexCoord(iconZoom, 1 - iconZoom, iconZoom, 1 - iconZoom)
    customIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(itemId)))

    return customIcon
end

local function CreateCustomSpellIcon(spellId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.CooldownManager.ItemSpell
    if not spellId then return end
    if not C_SpellBook.IsSpellInSpellBook(spellId) then return end

    local customIcon = CreateFrame("Button", "BCDM_Custom_" .. spellId, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end
    customIcon:SetSize(CustomDB.IconSize, CustomDB.IconSize)
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    customIcon:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
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
                customIcon.Charges:SetText("")
            end
        end
    end)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    customIcon.Icon:SetTexCoord(iconZoom, 1 - iconZoom, iconZoom, 1 - iconZoom)
    customIcon.Icon:SetTexture(C_Spell.GetSpellInfo(spellId).iconID)

    return customIcon
end

local function ResolveItemSpellEntryType(entryId, entryData)
    if entryData and entryData.entryType then
        return entryData.entryType
    end
    if C_Item.GetItemInfo(entryId) then
        return "item"
    end
    if C_Spell.GetSpellInfo(entryId) then
        return "spell"
    end
end

local function CreateCustomIcons(iconTable)
    local Items = BCDM.db.profile.CooldownManager.ItemSpell.ItemsSpells

    wipe(iconTable)

    if Items then
        local items = {}
        for entryId, data in pairs(Items) do
            if data.isActive then
                local entryType = ResolveItemSpellEntryType(entryId, data)
                if entryType then
                    table.insert(items, {id = entryId, index = data.layoutIndex, entryType = entryType})
                end
            end
        end

        table.sort(items, function(a, b) return a.index < b.index end)

        for _, item in ipairs(items) do
            local customItem = nil
            if item.entryType == "spell" then
                customItem = CreateCustomSpellIcon(item.id)
            else
                customItem = CreateCustomItemIcon(item.id)
            end
            if customItem then
                table.insert(iconTable, customItem)
            end
        end
    end
end

local function LayoutCustomItemsSpellsBar()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.ItemSpell
    local customItemBarIcons = {}

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

    if not BCDM.CustomItemSpellBarContainer then
        BCDM.CustomItemSpellBarContainer = CreateFrame("Frame", "BCDM_CustomItemSpellBar", UIParent, "BackdropTemplate")
        BCDM.CustomItemSpellBarContainer:SetSize(1, 1)
    end

    BCDM.CustomItemSpellBarContainer:ClearAllPoints()
    BCDM.CustomItemSpellBarContainer:SetFrameStrata(CustomDB.FrameStrata or "LOW")
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    BCDM.CustomItemSpellBarContainer:SetPoint(containerAnchorFrom, anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    for _, child in ipairs({BCDM.CustomItemSpellBarContainer:GetChildren()}) do child:UnregisterAllEvents() child:Hide() child:SetParent(nil) end

    CreateCustomIcons(customItemBarIcons)

    local iconSize = CustomDB.IconSize
    local iconSpacing = CustomDB.Spacing

    if #customItemBarIcons == 0 then
        BCDM.CustomItemSpellBarContainer:SetSize(1, 1)
    else
        local point = select(1, BCDM.CustomItemSpellBarContainer:GetPoint(1))
        local useCenteredLayout = (point == "TOP" or point == "BOTTOM") and (growthDirection == "LEFT" or growthDirection == "RIGHT")

        local totalWidth, totalHeight = 0, 0
        if useCenteredLayout or growthDirection == "RIGHT" or growthDirection == "LEFT" then
            totalWidth = (#customItemBarIcons * iconSize) + ((#customItemBarIcons - 1) * iconSpacing)
            totalHeight = iconSize
        elseif growthDirection == "UP" or growthDirection == "DOWN" then
            totalWidth = iconSize
            totalHeight = (#customItemBarIcons * iconSize) + ((#customItemBarIcons - 1) * iconSpacing)
        end
        BCDM.CustomItemSpellBarContainer:SetWidth(totalWidth)
        BCDM.CustomItemSpellBarContainer:SetHeight(totalHeight)
    end

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

    local point = select(1, BCDM.CustomItemSpellBarContainer:GetPoint(1))
    local useCenteredLayout = (point == "TOP" or point == "BOTTOM") and (growthDirection == "LEFT" or growthDirection == "RIGHT")

    if useCenteredLayout and #customItemBarIcons > 0 then
        local totalWidth = (#customItemBarIcons * iconSize) + ((#customItemBarIcons - 1) * iconSpacing)
        local startOffset = -(totalWidth / 2) + (iconSize / 2)

        for i, spellIcon in ipairs(customItemBarIcons) do
            spellIcon:SetParent(BCDM.CustomItemSpellBarContainer)
            spellIcon:SetSize(iconSize, iconSize)
            spellIcon:ClearAllPoints()

            local xOffset = startOffset + ((i - 1) * (iconSize + iconSpacing))
            spellIcon:SetPoint("CENTER", BCDM.CustomItemSpellBarContainer, "CENTER", xOffset, 0)
            ApplyCooldownText()
            spellIcon:Show()
        end
    else
        for i, spellIcon in ipairs(customItemBarIcons) do
            spellIcon:SetParent(BCDM.CustomItemSpellBarContainer)
            spellIcon:SetSize(iconSize, iconSize)
            spellIcon:ClearAllPoints()

            if i == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                spellIcon:SetPoint(config.anchor, BCDM.CustomItemSpellBarContainer, config.anchor, 0, 0)
            else
                if growthDirection == "RIGHT" then
                    spellIcon:SetPoint("LEFT", customItemBarIcons[i - 1], "RIGHT", iconSpacing, 0)
                elseif growthDirection == "LEFT" then
                    spellIcon:SetPoint("RIGHT", customItemBarIcons[i - 1], "LEFT", -iconSpacing, 0)
                elseif growthDirection == "UP" then
                    spellIcon:SetPoint("BOTTOM", customItemBarIcons[i - 1], "TOP", 0, iconSpacing)
                elseif growthDirection == "DOWN" then
                    spellIcon:SetPoint("TOP", customItemBarIcons[i - 1], "BOTTOM", 0, -iconSpacing)
                end
            end
            ApplyCooldownText()
            spellIcon:Show()
        end
    end

    BCDM.CustomItemSpellBarContainer:Show()
end

function BCDM:SetupCustomItemsSpellsBar()
    LayoutCustomItemsSpellsBar()
end

function BCDM:UpdateCustomItemsSpellsBar()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.ItemSpell
    if BCDM.CustomItemSpellBarContainer then
        BCDM.CustomItemSpellBarContainer:ClearAllPoints()
        local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
        BCDM.CustomItemSpellBarContainer:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    end
    LayoutCustomItemsSpellsBar()
end

function BCDM:AdjustItemsSpellsLayoutIndex(direction, itemId)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.ItemSpell
    local Items = CustomDB.ItemsSpells

    if not Items then return end

    local currentIndex = Items[itemId].layoutIndex
    local newIndex = currentIndex + direction

    local totalItems = 0

    for _ in pairs(Items) do totalItems = totalItems + 1 end
    if newIndex < 1 or newIndex > totalItems then return end

    for _, data in pairs(Items) do
        if data.layoutIndex == newIndex then
            data.layoutIndex = currentIndex
            break
        end
    end

    Items[itemId].layoutIndex = newIndex
    BCDM:NormalizeItemsSpellsLayoutIndices()

    BCDM:UpdateCustomItemsSpellsBar()
end

function BCDM:NormalizeItemsSpellsLayoutIndices()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.ItemSpell
    local Items = CustomDB.ItemsSpells

    if not Items then return end

    local ordered = {}
    for itemId, data in pairs(Items) do
        ordered[#ordered + 1] = {
            itemId = itemId,
            data = data,
            sortIndex = data.layoutIndex or math.huge,
        }
    end

    table.sort(ordered, function(a, b)
        if a.sortIndex == b.sortIndex then
            return tostring(a.itemId) < tostring(b.itemId)
        end
        return a.sortIndex < b.sortIndex
    end)

    for index, entry in ipairs(ordered) do
        entry.data.layoutIndex = index
    end
end

function BCDM:AdjustItemsSpellsList(itemId, adjustingHow, entryType)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.ItemSpell
    local Items = CustomDB.ItemsSpells

    if not Items then
        Items = {}
        CustomDB.ItemsSpells = Items
    end

    if adjustingHow == "add" then
        local maxIndex = 0
        for _, data in pairs(Items) do
            if data.layoutIndex > maxIndex then
                maxIndex = data.layoutIndex
            end
        end
        local resolvedType = entryType or ResolveItemSpellEntryType(itemId)
        Items[itemId] = { isActive = true, layoutIndex = maxIndex + 1, entryType = resolvedType }
    elseif adjustingHow == "remove" then
        Items[itemId] = nil
    end

    BCDM:NormalizeItemsSpellsLayoutIndices()
    BCDM:UpdateCustomItemsSpellsBar()
end
