local _, BCDM = ...

local FRAME_NAME_PREFIX = "BCDM_CustomItemSpellBar"
local DEFAULT_CONTAINER_NAME = "Container"
local ADDON_PREFIX = "|cFF8080FFBCDM|r: "

local HEALTHSTONE_BASE_ID = 5512
local HEALTHSTONE_GLUTTONY_ID = 224464
local PACT_OF_GLUTTONY_SPELL_ID = 386689

local LEGACY_VIEWER_DEFAULTS = {
    Custom = {
        IconSize = 38,
        IconWidth = 38,
        IconHeight = 38,
        KeepAspectRatio = true,
        FrameStrata = "LOW",
        Layout = {"CENTER", "NONE", "CENTER", 0, 0},
        Spacing = 1,
        GrowthDirection = "RIGHT",
        Columns = 0,
        Text = {
            FontSize = 12,
            Colour = {1, 1, 1},
            Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2},
        },
    },
    AdditionalCustom = {
        IconSize = 38,
        IconWidth = 38,
        IconHeight = 38,
        KeepAspectRatio = true,
        FrameStrata = "LOW",
        Layout = {"CENTER", "NONE", "CENTER", 0, 0},
        Spacing = 1,
        GrowthDirection = "RIGHT",
        Columns = 0,
        Text = {
            FontSize = 12,
            Colour = {1, 1, 1},
            Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2},
        },
    },
    Item = {
        IconSize = 38,
        IconWidth = 38,
        IconHeight = 38,
        KeepAspectRatio = true,
        FrameStrata = "LOW",
        Layout = {"CENTER", "NONE", "CENTER", 0, 0},
        Spacing = 1,
        GrowthDirection = "LEFT",
        Columns = 0,
        OffsetByParentHeight = true,
        HideZeroCharges = false,
        ShowItemQualityBorder = true,
        Text = {
            FontSize = 12,
            Colour = {1, 1, 1},
            Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2},
        },
    },
    ItemSpell = {
        IconSize = 38,
        IconWidth = 38,
        IconHeight = 38,
        KeepAspectRatio = true,
        FrameStrata = "LOW",
        Layout = {"CENTER", "NONE", "CENTER", 0, 0},
        Spacing = 1,
        GrowthDirection = "LEFT",
        Columns = 0,
        OffsetByParentHeight = true,
        HideZeroCharges = false,
        ShowItemQualityBorder = true,
        Text = {
            FontSize = 12,
            Colour = {1, 1, 1},
            Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2},
        },
    },
}

local CONTAINER_SETTING_KEYS = {
    "IconSize",
    "IconWidth",
    "IconHeight",
    "KeepAspectRatio",
    "FrameStrata",
    "Layout",
    "Spacing",
    "GrowthDirection",
    "Columns",
    "OffsetByParentHeight",
    "HideZeroCharges",
    "IncludeUsableTrinkets",
    "ShowItemQualityBorder",
    "Text",
}

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return end
    if cooldown.BCDMCachedTextRegion then
        return cooldown.BCDMCachedTextRegion
    end

    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            cooldown.BCDMCachedTextRegion = region
            return region
        end
    end
end

local function ApplyCooldownText(viewer)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = CooldownManagerDB.CooldownManager.General.CooldownText
    if not viewer then return end

    local icons = viewer.ActiveIcons or { viewer:GetChildren() }
    for _, icon in ipairs(icons) do
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
                    textRegion:SetShadowColor(
                        GeneralDB.Fonts.Shadow.Colour[1],
                        GeneralDB.Fonts.Shadow.Colour[2],
                        GeneralDB.Fonts.Shadow.Colour[3],
                        GeneralDB.Fonts.Shadow.Colour[4]
                    )
                    textRegion:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
                else
                    textRegion:SetShadowColor(0, 0, 0, 0)
                    textRegion:SetShadowOffset(0, 0)
                end
            end
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
    if BCDM:IsSecretValue(startTime) or BCDM:IsSecretValue(duration) then return 0 end
    local remaining = (startTime + duration) - GetTime()
    return remaining > 0.001 and 1 or 0
end

local function GetReadableNumber(value)
    if type(value) ~= "number" then return nil end
    if BCDM:IsSecretValue(value) then return nil end
    return value
end

local function HasReadableActiveCooldown(startTime, duration)
    startTime = GetReadableNumber(startTime)
    duration = GetReadableNumber(duration)

    if startTime == nil or duration == nil then
        return false, nil, nil
    end

    return startTime > 0 and duration > 0, startTime, duration
end

local GetTrackedSpellOverrideId

local function IsTrackedSpellCooldownUpdate(spellId, updatedSpellId, updatedBaseSpellId)
    if updatedSpellId == nil and updatedBaseSpellId == nil then
        return true
    end

    if updatedSpellId == spellId or updatedBaseSpellId == spellId then
        return true
    end

    if GetTrackedSpellOverrideId then
        local overrideSpellId = GetTrackedSpellOverrideId(spellId)
        if overrideSpellId and (updatedSpellId == overrideSpellId or updatedBaseSpellId == overrideSpellId) then
            return true
        end
    end

    return false
end

GetTrackedSpellOverrideId = (C_Spell and C_Spell.GetOverrideSpell) or FindSpellOverrideByID

local function BuildTrackedSpellEventIds(spellId)
    local trackedSpellIds = {}
    local seenSpellIds = {}

    local function AddTrackedSpellId(candidateSpellId)
        candidateSpellId = tonumber(candidateSpellId)
        if not candidateSpellId or seenSpellIds[candidateSpellId] then
            return
        end

        seenSpellIds[candidateSpellId] = true
        trackedSpellIds[#trackedSpellIds + 1] = candidateSpellId
    end

    AddTrackedSpellId(spellId)

    if GetTrackedSpellOverrideId then
        AddTrackedSpellId(GetTrackedSpellOverrideId(spellId))
    end

    return trackedSpellIds
end

local function AddSpellIconIndexEntry(spellCooldownIndex, spellId, customIcon)
    if not spellCooldownIndex or not spellId or not customIcon then
        return
    end

    local bucket = spellCooldownIndex[spellId]
    if not bucket then
        bucket = {}
        spellCooldownIndex[spellId] = bucket
    end

    bucket[#bucket + 1] = customIcon
end

local function BuildSpellCooldownIndex(activeIcons)
    local spellCooldownIndex = {}
    local spellIcons = {}

    for _, customIcon in ipairs(activeIcons or {}) do
        if customIcon and customIcon.BCDMIsActive and customIcon.BCDMIconType == "spell" and customIcon.BCDMSpellId then
            spellIcons[#spellIcons + 1] = customIcon

            for _, trackedSpellId in ipairs(BuildTrackedSpellEventIds(customIcon.BCDMSpellId)) do
                AddSpellIconIndexEntry(spellCooldownIndex, trackedSpellId, customIcon)
            end
        end
    end

    return spellCooldownIndex, spellIcons
end

local function UpdateSpellIconDesaturation(customIcon, spellId)
    if not customIcon or not customIcon.Icon then return end
    local desaturationCurve, gcdFilterCurve = BCDM:GetCooldownDesaturationCurves()

    local cooldownData = C_Spell.GetSpellCooldown(spellId)
    if cooldownData and cooldownData.isOnGCD then
        SetIconDesaturation(customIcon.Icon, 0)
        return
    end

    local spellCharges = C_Spell.GetSpellCharges(spellId)
    local maxCharges = GetReadableNumber(spellCharges and spellCharges.maxCharges) or 0
    local currentCharges = maxCharges > 1 and GetReadableNumber(spellCharges.currentCharges)
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

local function ShouldRefreshItemCooldownFrame(cooldownFrame, hasActiveCooldown, startTime, durationTime)
    if not cooldownFrame then
        return false
    end

    local oldStart, oldDuration = cooldownFrame:GetCooldownTimes()
    oldStart = GetReadableNumber(tonumber(oldStart)) or 0
    oldDuration = GetReadableNumber(tonumber(oldDuration)) or 0

    if hasActiveCooldown then
        if oldStart <= 0 or oldDuration <= 0 then
            return true
        end

        local hasReadableCooldown, readableStartTime, readableDurationTime = HasReadableActiveCooldown(startTime, durationTime)
        if not hasReadableCooldown then
            return true
        end

        local oldEnd = (oldStart + oldDuration) / 1000
        local newEnd = readableStartTime + readableDurationTime
        return math.abs(oldEnd - newEnd) > 0.01
    end

    return oldStart > 0 and oldDuration > 0
end

local function UpdateCustomSpellIconCooldown(customIcon, spellId)
    if not customIcon or not customIcon.Cooldown or not spellId then
        return
    end

    local spellCharges = C_Spell.GetSpellCharges(spellId)
    local maxCharges = GetReadableNumber(spellCharges and spellCharges.maxCharges) or 0
    local currentCharges = GetReadableNumber(spellCharges and spellCharges.currentCharges)
    local hasCharges = maxCharges > 1

    if hasCharges then
        customIcon.Charges:SetText(C_Spell.GetSpellDisplayCount(spellId))
        if customIcon.CastCount then customIcon.CastCount:SetText("") end
    else
        customIcon.Charges:SetText("")
    end

    local chargeStartTime = hasCharges and spellCharges.cooldownStartTime or 0
    local chargeDuration = hasCharges and spellCharges.cooldownDuration or 0
    local hasReadableChargeCooldown, readableChargeStartTime, readableChargeDuration = HasReadableActiveCooldown(chargeStartTime, chargeDuration)
    local spellChargeCooldown = hasCharges and C_Spell.GetSpellChargeDuration and C_Spell.GetSpellChargeDuration(spellId)
    local hasChargeCooldown = hasCharges and (spellChargeCooldown ~= nil or hasReadableChargeCooldown)

    if hasChargeCooldown then
        if ShouldRefreshItemCooldownFrame(customIcon.Cooldown, true, chargeStartTime, chargeDuration) then
            if spellChargeCooldown then
                customIcon.Cooldown:SetCooldownFromDurationObject(spellChargeCooldown, true)
            elseif hasReadableChargeCooldown then
                local durationObject = C_DurationUtil.CreateDuration()
                durationObject:SetTimeFromStart(readableChargeStartTime, readableChargeDuration)
                customIcon.Cooldown:SetCooldownFromDurationObject(durationObject, true)
            end
        end

        return
    end

    local cooldownData = C_Spell.GetSpellCooldown(spellId)
    local cooldownStartTime = cooldownData and cooldownData.startTime or 0
    local cooldownDuration = cooldownData and cooldownData.duration or 0
    local hasReadableCooldown, readableCooldownStartTime, readableCooldownDuration = HasReadableActiveCooldown(cooldownStartTime, cooldownDuration)
    local spellCooldown = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(spellId)
    local hasCooldown = spellCooldown ~= nil or hasReadableCooldown

    if hasCooldown then
        if ShouldRefreshItemCooldownFrame(customIcon.Cooldown, true, cooldownStartTime, cooldownDuration) then
            if spellCooldown then
                customIcon.Cooldown:SetCooldownFromDurationObject(spellCooldown, true)
            elseif hasReadableCooldown then
                local durationObject = C_DurationUtil.CreateDuration()
                durationObject:SetTimeFromStart(readableCooldownStartTime, readableCooldownDuration)
                customIcon.Cooldown:SetCooldownFromDurationObject(durationObject, true)
            end
        end
    elseif ShouldRefreshItemCooldownFrame(customIcon.Cooldown, false, cooldownStartTime, cooldownDuration) then
        customIcon.Cooldown:SetCooldownFromDurationObject(C_DurationUtil.CreateDuration(), true)
    end
end

local function FetchItemData(itemId)
    local itemCount = C_Item.GetItemCount(itemId)
    if itemId == HEALTHSTONE_GLUTTONY_ID or itemId == HEALTHSTONE_BASE_ID then
        itemCount = C_Item.GetItemCount(itemId, false, true)
    end
    local startTime, durationTime = C_Item.GetItemCooldown(itemId)
    return itemCount, startTime, durationTime
end

local function ShouldShowItem(customDB, itemId)
    if not customDB.HideZeroCharges then return true end
    local itemCount = select(1, FetchItemData(itemId))
    if itemCount == nil then return true end
    return itemCount > 0
end

local POTION_CLASS_ID = (Enum and Enum.ItemClass and Enum.ItemClass.Consumable) or 0
local POTION_SUBCLASS_ID = (Enum and Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Potion) or 1

local function IsPotionItem(itemId)
    if not itemId then return false end
    local _, _, _, _, _, classId, subClassId = C_Item.GetItemInfoInstant(itemId)
    return classId == POTION_CLASS_ID and subClassId == POTION_SUBCLASS_ID
end

local function ParseProfessionAtlasFromItemLink(itemLink)
    if type(itemLink) ~= "string" then return end

    return string.match(itemLink, "|A:(Professions%-[^:|]-Tier%d+):")
        or string.match(itemLink, "(Professions%-ChatIcon%-Quality%-%d+%-Tier%d+)")
        or string.match(itemLink, "(Professions%-ChatIcon%-Quality%-Tier%d+)")
        or string.match(itemLink, "(Professions%-Icon%-Quality%-%d+%-Tier%d+)")
        or string.match(itemLink, "(Professions%-Icon%-Quality%-Tier%d+)")
end

local function ParseProfessionRankFromItemLink(itemLink)
    local atlasName = ParseProfessionAtlasFromItemLink(itemLink)
    local rank = atlasName and string.match(atlasName, "Tier(%d+)")
    return rank and tonumber(rank) or nil
end

local function BuildProfessionAtlasFromRank(itemId, rank)
    if not rank or rank <= 0 then return end

    local expansionID = select(15, C_Item.GetItemInfo(itemId))
    if expansionID == 11 then
        return "Professions-Icon-Quality-12-Tier" .. rank .. "-Small"
    end
    return "Professions-Icon-Quality-Tier" .. rank .. "-Small"
end

local function FetchPotionProfessionRank(itemId)
    if not itemId then
        return 0
    end

    local _, itemLink = C_Item.GetItemInfo(itemId)
    local parsedRank = ParseProfessionRankFromItemLink(itemLink)
    if parsedRank then
        return parsedRank
    end

    if not C_TradeSkillUI then
        return 0
    end

    local itemInfo = itemLink or itemId

    if C_TradeSkillUI.GetItemCraftedQualityByItemInfo then
        local craftedRank = C_TradeSkillUI.GetItemCraftedQualityByItemInfo(itemInfo)
        if craftedRank then return craftedRank end
        if itemInfo ~= itemId then
            craftedRank = C_TradeSkillUI.GetItemCraftedQualityByItemInfo(itemId)
            if craftedRank then return craftedRank end
        end
    end

    if C_TradeSkillUI.GetItemReagentQualityByItemInfo then
        local reagentRank = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemInfo)
        if reagentRank then return reagentRank end
        if itemInfo ~= itemId then
            reagentRank = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemId)
            if reagentRank then return reagentRank end
        end
    end

    return 0
end

local function ResolveItemQualityAtlas(itemId)
    if not itemId then return end

    local _, itemLink = C_Item.GetItemInfo(itemId)
    local atlasFromLink = ParseProfessionAtlasFromItemLink(itemLink)
    if atlasFromLink then
        return atlasFromLink
    end

    local rank = FetchPotionProfessionRank(itemId)
    return BuildProfessionAtlasFromRank(itemId, rank)
end

local function SelectPotionRankCandidate(potionGroups, itemId, layoutIndex)
    if not IsPotionItem(itemId) then
        return false
    end

    local itemName = C_Item.GetItemInfo(itemId)
    if not itemName then
        return false
    end

    local itemCount = select(1, FetchItemData(itemId)) or 0
    local group = potionGroups[itemName]
    if not group then
        group = { index = layoutIndex, selected = nil }
        potionGroups[itemName] = group
    else
        group.index = math.min(group.index or layoutIndex, layoutIndex)
    end

    local candidate = {
        id = itemId,
        count = itemCount,
        rank = FetchPotionProfessionRank(itemId),
    }

    local selected = group.selected
    if not selected then
        group.selected = candidate
        return true
    end

    local candidateAvailable = candidate.count > 0
    local selectedAvailable = selected.count > 0

    if candidateAvailable ~= selectedAvailable then
        if candidateAvailable then
            group.selected = candidate
        end
        return true
    end

    if candidate.rank > selected.rank then
        group.selected = candidate
        return true
    end

    if candidate.rank == selected.rank and candidate.id > selected.id then
        group.selected = candidate
    end

    return true
end

local function ParseClassSpecFilterValue(value)
    if not value then return end
    local normalizedValue = tostring(value):upper()
    local classToken, specToken = string.match(normalizedValue, "^(%u+):([%u%d_]+)$")
    if not classToken or not specToken then return end
    return classToken, (BCDM:NormalizeSpecToken(specToken) or specToken)
end

local function ApplyItemQualityAtlas(customIcon, itemId, customDB, iconWidth, iconHeight)
    if not customIcon or not customIcon.QualityAtlas then return end
    if not itemId or customDB.ShowItemQualityBorder == false then
        customIcon.QualityAtlas:Hide()
        return
    end

    local atlasName = ResolveItemQualityAtlas(itemId)
    if not atlasName then
        customIcon.QualityAtlas:Hide()
        return
    end

    local iconSize = math.min(iconWidth or customIcon:GetWidth() or 0, iconHeight or customIcon:GetHeight() or 0)
    local atlasSize = math.max(10, math.floor(iconSize * 0.42))
    customIcon.QualityAtlas:ClearAllPoints()
    customIcon.QualityAtlas:SetPoint("TOPLEFT", customIcon, "TOPLEFT", 0, 0)
    customIcon.QualityAtlas:SetSize(atlasSize, atlasSize)
    customIcon.QualityAtlas:SetAtlas(atlasName)
    customIcon.QualityAtlas:Show()
end

local function IsEntryEnabledForPlayerSpec(entryData, playerClass, playerSpecialization)
    local classSpecFilters = entryData and entryData.classSpecFilters
    if type(classSpecFilters) ~= "table" then
        return true
    end

    local hasActiveFilter = false
    local hasConfiguredFilters = next(classSpecFilters) ~= nil
    for classSpecValue, isEnabled in pairs(classSpecFilters) do
        if isEnabled then
            hasActiveFilter = true
            local classToken, specToken = ParseClassSpecFilterValue(classSpecValue)
            if classToken and classToken == playerClass and ((not playerSpecialization) or playerSpecialization == specToken) then
                return true
            end
        end
    end

    return not (hasActiveFilter or hasConfiguredFilters)
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

local function HasTrackedPotionEntries(entries)
    if not entries then return false end
    for _, entry in ipairs(entries) do
        if entry and entry.isActive and ResolveItemSpellEntryType(entry.entryId, entry) == "item" and IsPotionItem(entry.entryId) then
            return true
        end
    end
    return false
end

local function HasTrackedHealthstoneEntries(entries)
    if not entries then return false end
    for _, entry in ipairs(entries) do
        if entry and entry.isActive and ResolveItemSpellEntryType(entry.entryId, entry) == "item" then
            if entry.entryId == HEALTHSTONE_BASE_ID or entry.entryId == HEALTHSTONE_GLUTTONY_ID then
                return true
            end
        end
    end
    return false
end

local function IsOnUseTrinket(itemId)
    if not itemId then return false end
    local spellName, spellID = C_Item.GetItemSpell(itemId)
    return (spellID and spellID > 0) or (spellName and spellName ~= "")
end

local function FetchEquippedOnUseTrinkets()
    local equipped = {}
    for _, slotID in ipairs({ 13, 14 }) do
        local itemId = GetInventoryItemID("player", slotID)
        if itemId and IsOnUseTrinket(itemId) then
            equipped[#equipped + 1] = { itemId = itemId, slotID = slotID }
        end
    end
    return equipped
end

local function GetDefaultContainerName(index)
    return string.format("%s %d", DEFAULT_CONTAINER_NAME, index or 1)
end

local function TrimName(name)
    if type(name) ~= "string" then return nil end
    local trimmed = name:match("^%s*(.-)%s*$")
    if trimmed == "" then
        return nil
    end
    return trimmed
end

local function DeepEqual(a, b)
    if type(a) ~= type(b) then
        return false
    end
    if type(a) ~= "table" then
        return a == b
    end

    for key, value in pairs(a) do
        if not DeepEqual(value, b[key]) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

local function SettingsDifferFromDefaults(source, defaults)
    for key, defaultValue in pairs(defaults or {}) do
        local currentValue = source and source[key]
        if type(defaultValue) == "table" then
            if type(currentValue) == "table" then
                if SettingsDifferFromDefaults(currentValue, defaultValue) then
                    return true
                end
            elseif not DeepEqual(defaultValue, {}) then
                return true
            end
        else
            if currentValue ~= nil and currentValue ~= defaultValue then
                return true
            end
        end
    end
    return false
end

local function CopyMissingFields(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then
        return
    end

    for key, defaultValue in pairs(defaults) do
        if type(defaultValue) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = BCDM:CopyTable(defaultValue)
            else
                CopyMissingFields(target[key], defaultValue)
            end
        elseif target[key] == nil then
            target[key] = defaultValue
        end
    end
end

local function CreateEntry(container, entryId, entryType, data, classSpecFilters, filterClass)
    container.NextEntryId = math.max(tonumber(container.NextEntryId) or 1, 1)
    local entry = {
        uid = container.NextEntryId,
        entryId = entryId,
        entryType = entryType,
        isActive = data == nil or data.isActive ~= false,
        layoutIndex = data and data.layoutIndex or (#container.Entries + 1),
        classSpecFilters = classSpecFilters,
        filterClass = filterClass,
    }

    container.NextEntryId = container.NextEntryId + 1
    container.Entries[#container.Entries + 1] = entry
    return entry
end

local function HasLegacySpellEntries(spellDB)
    if type(spellDB) ~= "table" then
        return false
    end

    for _, specs in pairs(spellDB) do
        if type(specs) == "table" then
            for _, spells in pairs(specs) do
                if type(spells) == "table" and next(spells) then
                    return true
                end
            end
        end
    end

    return false
end

local function HasLegacyEntryMap(entries)
    return type(entries) == "table" and next(entries) ~= nil
end

local function GetDefaultContainerTemplate()
    local defaults = BCDM:GetDefaultDB()
    local itemSpellDefaults = defaults and defaults.profile and defaults.profile.CooldownManager and defaults.profile.CooldownManager.ItemSpell
    local template = itemSpellDefaults and itemSpellDefaults.Containers and itemSpellDefaults.Containers[1]
    return BCDM:CopyTable(template or {})
end

local function GetItemSpellFrameworkDB()
    local CooldownManagerDB = BCDM.db and BCDM.db.profile and BCDM.db.profile.CooldownManager
    if not CooldownManagerDB then
        return nil
    end

    if type(CooldownManagerDB.ItemSpell) ~= "table" then
        CooldownManagerDB.ItemSpell = {}
    end

    return CooldownManagerDB.ItemSpell
end

local function CreateContainerSkeleton(containerId, name)
    local container = GetDefaultContainerTemplate()
    container.Id = containerId
    container.Name = name or GetDefaultContainerName(containerId)
    container.NextEntryId = math.max(tonumber(container.NextEntryId) or 1, 1)
    container.Entries = container.Entries or {}
    return container
end

local function CopyLegacyContainerSettings(container, legacyDB)
    for _, key in ipairs(CONTAINER_SETTING_KEYS) do
        if legacyDB[key] ~= nil then
            if type(legacyDB[key]) == "table" then
                container[key] = BCDM:CopyTable(legacyDB[key])
            else
                container[key] = legacyDB[key]
            end
        end
    end
end

local function GetContainerFrameName(containerId)
    return FRAME_NAME_PREFIX .. tostring(containerId)
end

local function GetContainerDisplayName(container, index)
    local name = container and TrimName(container.Name)
    return name or GetDefaultContainerName(index or (container and container.Id) or 1)
end

local function BuildLegacySpellViewerContainer(containerId, name, legacyDB)
    local container = CreateContainerSkeleton(containerId, name)
    CopyLegacyContainerSettings(container, legacyDB)

    for classToken, specs in pairs(legacyDB.Spells or {}) do
        for specToken, spells in pairs(specs or {}) do
            for spellId, data in pairs(spells or {}) do
                CreateEntry(
                    container,
                    spellId,
                    "spell",
                    data,
                    { [classToken .. ":" .. specToken] = true },
                    classToken
                )
            end
        end
    end

    return container
end

local function BuildLegacyEntryViewerContainer(containerId, name, legacyDB, entryField, forcedEntryType)
    local container = CreateContainerSkeleton(containerId, name)
    CopyLegacyContainerSettings(container, legacyDB)

    for entryId, data in pairs(legacyDB[entryField] or {}) do
        local entryType = forcedEntryType or ResolveItemSpellEntryType(entryId, data)
        local classSpecFilters = data.classSpecFilters
        local filterClass = data.filterClass

        if type(classSpecFilters) == "table" then
            classSpecFilters = BCDM:CopyTable(classSpecFilters)
        elseif entryType == "spell" then
            filterClass = filterClass or select(2, UnitClass("player"))
            classSpecFilters = BCDM:BuildClassSpecFilters(filterClass)
        else
            classSpecFilters = BCDM:BuildClassSpecFilters()
        end

        CreateEntry(container, entryId, entryType, data, classSpecFilters, filterClass)
    end

    return container
end

local function RemapAnchorParent(layout, anchorMap, containerFrameName)
    if type(layout) ~= "table" then
        return
    end

    local anchorParent = layout[2]
    if not anchorParent then
        return
    end

    if anchorMap[anchorParent] then
        layout[2] = anchorMap[anchorParent]
    elseif anchorParent:match("^BCDM_") and not _G[anchorParent] then
        layout[2] = "NONE"
    end

    if layout[2] == containerFrameName then
        layout[2] = "NONE"
    end
end

local function MigrateLegacyFramework()
    local CooldownManagerDB = BCDM.db.profile.CooldownManager
    local legacyItemSpellDB = CooldownManagerDB.ItemSpell
    local migratedContainers = {}
    local anchorMap = {}
    local nextContainerId = 1

    local legacyConfigs = {
        {
            key = "Custom",
            displayName = "Custom",
            legacyFrame = "BCDM_CustomCooldownViewer",
            isMeaningful = function(db)
                return HasLegacySpellEntries(db and db.Spells) or SettingsDifferFromDefaults(db or {}, LEGACY_VIEWER_DEFAULTS.Custom)
            end,
            build = function(id, db)
                return BuildLegacySpellViewerContainer(id, "Custom", db)
            end,
        },
        {
            key = "AdditionalCustom",
            displayName = "Additional Custom",
            legacyFrame = "BCDM_AdditionalCustomCooldownViewer",
            isMeaningful = function(db)
                return HasLegacySpellEntries(db and db.Spells) or SettingsDifferFromDefaults(db or {}, LEGACY_VIEWER_DEFAULTS.AdditionalCustom)
            end,
            build = function(id, db)
                return BuildLegacySpellViewerContainer(id, "Additional Custom", db)
            end,
        },
        {
            key = "Item",
            displayName = "Items",
            legacyFrame = "BCDM_CustomItemBar",
            isMeaningful = function(db)
                return HasLegacyEntryMap(db and db.Items) or SettingsDifferFromDefaults(db or {}, LEGACY_VIEWER_DEFAULTS.Item)
            end,
            build = function(id, db)
                return BuildLegacyEntryViewerContainer(id, "Items", db, "Items", "item")
            end,
        },
        {
            key = "ItemSpell",
            displayName = "Items & Spells",
            legacyFrame = "BCDM_CustomItemSpellBar",
            isMeaningful = function(db)
                return HasLegacyEntryMap(db and db.ItemsSpells) or SettingsDifferFromDefaults(db or {}, LEGACY_VIEWER_DEFAULTS.ItemSpell)
            end,
            build = function(id, db)
                return BuildLegacyEntryViewerContainer(id, "Items & Spells", db, "ItemsSpells")
            end,
        },
    }

    for _, config in ipairs(legacyConfigs) do
        local legacyDB = CooldownManagerDB[config.key]
        if type(legacyDB) == "table" and config.isMeaningful(legacyDB) then
            local container = config.build(nextContainerId, legacyDB)
            migratedContainers[#migratedContainers + 1] = container
            anchorMap[config.legacyFrame] = GetContainerFrameName(container.Id)
            nextContainerId = nextContainerId + 1
        end
    end

    if #migratedContainers == 0 then
        migratedContainers[1] = CreateContainerSkeleton(1, GetDefaultContainerName(1))
        nextContainerId = 2
    end

    for index, container in ipairs(migratedContainers) do
        RemapAnchorParent(container.Layout, anchorMap, GetContainerFrameName(container.Id))
        container.Name = GetContainerDisplayName(container, index)
    end

    if CooldownManagerDB.Trinket and type(CooldownManagerDB.Trinket.Layout) == "table" then
        RemapAnchorParent(CooldownManagerDB.Trinket.Layout, anchorMap)
    end

    CooldownManagerDB.ItemSpell = {
        Containers = migratedContainers,
        SelectedContainerId = migratedContainers[1].Id,
        NextContainerId = nextContainerId,
    }
end

local function NormalizeLegacyEntryMap(container, legacyEntries)
    for entryId, data in pairs(legacyEntries or {}) do
        local entryType = ResolveItemSpellEntryType(entryId, data)
        local classSpecFilters = data.classSpecFilters
        local filterClass = data.filterClass

        if type(classSpecFilters) == "table" then
            classSpecFilters = BCDM:CopyTable(classSpecFilters)
        elseif entryType == "spell" then
            filterClass = filterClass or select(2, UnitClass("player"))
            classSpecFilters = BCDM:BuildClassSpecFilters(filterClass)
        else
            classSpecFilters = BCDM:BuildClassSpecFilters()
        end

        CreateEntry(container, entryId, entryType, data, classSpecFilters, filterClass)
    end
end

local function NormalizeContainerEntries(container)
    local seenUids = {}
    local normalized = {}
    local nextEntryId = 1

    if type(container.ItemsSpells) == "table" and next(container.ItemsSpells) then
        container.Entries = container.Entries or {}
        NormalizeLegacyEntryMap(container, container.ItemsSpells)
        container.ItemsSpells = nil
    end

    if type(container.Entries) ~= "table" then
        container.Entries = {}
    end

    for _, entry in ipairs(container.Entries) do
        if type(entry) == "table" then
            entry.entryId = entry.entryId or entry.id
            entry.entryType = ResolveItemSpellEntryType(entry.entryId, entry)
            if entry.entryId and entry.entryType then
                local uid = tonumber(entry.uid) or tonumber(entry.id)
                if not uid or seenUids[uid] then
                    uid = nextEntryId
                end
                seenUids[uid] = true
                nextEntryId = math.max(nextEntryId, uid + 1)

                entry.uid = uid
                entry.isActive = entry.isActive ~= false
                entry.layoutIndex = tonumber(entry.layoutIndex) or (#normalized + 1)
                if type(entry.classSpecFilters) == "table" then
                    entry.classSpecFilters = BCDM:CopyTable(entry.classSpecFilters)
                elseif entry.entryType == "spell" then
                    entry.filterClass = entry.filterClass or select(2, UnitClass("player"))
                    entry.classSpecFilters = BCDM:BuildClassSpecFilters(entry.filterClass)
                else
                    entry.classSpecFilters = BCDM:BuildClassSpecFilters()
                end

                normalized[#normalized + 1] = entry
            end
        end
    end

    table.sort(normalized, function(a, b)
        if a.layoutIndex == b.layoutIndex then
            if a.entryId == b.entryId then
                return a.uid < b.uid
            end
            return a.entryId < b.entryId
        end
        return a.layoutIndex < b.layoutIndex
    end)

    for index, entry in ipairs(normalized) do
        entry.layoutIndex = index
    end

    container.Entries = normalized
    container.NextEntryId = math.max(tonumber(container.NextEntryId) or 1, nextEntryId)
end

local function NormalizeContainer(container, index, seenIds, nextContainerId)
    local template = GetDefaultContainerTemplate()
    CopyMissingFields(container, template)
    NormalizeContainerEntries(container)

    local containerId = tonumber(container.Id)
    if not containerId or seenIds[containerId] then
        containerId = nextContainerId
        nextContainerId = nextContainerId + 1
    end

    seenIds[containerId] = true
    container.Id = containerId
    container.Name = GetContainerDisplayName(container, index)
    container.NextEntryId = math.max(tonumber(container.NextEntryId) or 1, 1)

    return nextContainerId
end

function BCDM:EnsureCustomItemSpellFramework()
    local framework = GetItemSpellFrameworkDB()
    if not framework then
        return nil
    end

    if type(framework.Containers) ~= "table" then
        MigrateLegacyFramework()
        framework = GetItemSpellFrameworkDB()
    end

    framework.Containers = framework.Containers or {}
    if #framework.Containers == 0 then
        framework.Containers[1] = CreateContainerSkeleton(1, GetDefaultContainerName(1))
    end

    local seenIds = {}
    local nextContainerId = math.max(tonumber(framework.NextContainerId) or 1, 1)

    for index, container in ipairs(framework.Containers) do
        if type(container) ~= "table" then
            framework.Containers[index] = CreateContainerSkeleton(nextContainerId, GetDefaultContainerName(index))
            seenIds[nextContainerId] = true
            nextContainerId = nextContainerId + 1
        else
            nextContainerId = NormalizeContainer(container, index, seenIds, nextContainerId)
        end
    end

    framework.NextContainerId = nextContainerId

    local selectedContainerId = tonumber(framework.SelectedContainerId)
    if not selectedContainerId or not seenIds[selectedContainerId] then
        framework.SelectedContainerId = framework.Containers[1].Id
    end

    return framework
end

function BCDM:GetCustomItemSpellContainers()
    local framework = self:EnsureCustomItemSpellFramework()
    return framework and framework.Containers or {}
end

function BCDM:GetCustomItemSpellContainer(containerId)
    local framework = self:EnsureCustomItemSpellFramework()
    if not framework then
        return nil, nil
    end

    if containerId == nil then
        containerId = framework.SelectedContainerId
    end

    containerId = tonumber(containerId)
    for index, container in ipairs(framework.Containers) do
        if container.Id == containerId then
            return container, index
        end
    end
end

function BCDM:GetSelectedCustomItemSpellContainerId()
    local framework = self:EnsureCustomItemSpellFramework()
    return framework and framework.SelectedContainerId or nil
end

function BCDM:SetSelectedCustomItemSpellContainerId(containerId)
    local framework = self:EnsureCustomItemSpellFramework()
    if not framework then
        return
    end

    local container = self:GetCustomItemSpellContainer(containerId)
    if container then
        framework.SelectedContainerId = container.Id
    end
end

function BCDM:GetCustomItemSpellContainerFrameName(containerId)
    local container = containerId
    if type(containerId) ~= "table" then
        container = self:GetCustomItemSpellContainer(containerId)
    end

    if not container then
        return nil
    end

    return GetContainerFrameName(container.Id)
end

function BCDM:GetCustomItemSpellContainerDisplayName(containerId)
    local container, index = self:GetCustomItemSpellContainer(containerId)
    if type(containerId) == "table" then
        container = containerId
    end
    return container and GetContainerDisplayName(container, index)
end

function BCDM:GetCustomItemSpellAnchorParents(currentContainerId)
    local displayNames = {}
    local keyList = {}
    local baseAnchors = BCDM.AnchorParents and BCDM.AnchorParents.ItemSpell

    if baseAnchors then
        for _, anchorKey in ipairs(baseAnchors[2] or {}) do
            keyList[#keyList + 1] = anchorKey
        end
        for anchorKey, label in pairs(baseAnchors[1] or {}) do
            displayNames[anchorKey] = label
        end
    end

    local currentFrameName = currentContainerId and self:GetCustomItemSpellContainerFrameName(currentContainerId) or nil
    for index, container in ipairs(self:GetCustomItemSpellContainers()) do
        local frameName = self:GetCustomItemSpellContainerFrameName(container)
        if frameName and frameName ~= currentFrameName and not displayNames[frameName] then
            displayNames[frameName] = ADDON_PREFIX .. GetContainerDisplayName(container, index)
            keyList[#keyList + 1] = frameName
        end
    end

    return displayNames, keyList
end

function BCDM:GetSortedCustomItemSpellEntries(containerId)
    local container = type(containerId) == "table" and containerId or self:GetCustomItemSpellContainer(containerId)
    if not container then
        return {}
    end

    local ordered = {}
    for _, entry in ipairs(container.Entries or {}) do
        ordered[#ordered + 1] = entry
    end

    table.sort(ordered, function(a, b)
        if a.layoutIndex == b.layoutIndex then
            if a.entryId == b.entryId then
                return a.uid < b.uid
            end
            return a.entryId < b.entryId
        end
        return a.layoutIndex < b.layoutIndex
    end)

    return ordered
end

function BCDM:NormalizeCustomItemSpellLayoutIndices(containerId)
    local container = self:GetCustomItemSpellContainer(containerId)
    if not container then
        return
    end

    local ordered = self:GetSortedCustomItemSpellEntries(container)
    for index, entry in ipairs(ordered) do
        entry.layoutIndex = index
    end
end

function BCDM:AddCustomItemSpellContainer(name)
    local framework = self:EnsureCustomItemSpellFramework()
    if not framework then
        return nil
    end

    local containerId = math.max(tonumber(framework.NextContainerId) or 1, 1)
    local container = CreateContainerSkeleton(containerId, TrimName(name) or GetDefaultContainerName(#framework.Containers + 1))
    framework.Containers[#framework.Containers + 1] = container
    framework.NextContainerId = containerId + 1
    framework.SelectedContainerId = container.Id
    self:UpdateCustomItemsSpellsBar()
    return container.Id
end

function BCDM:RenameCustomItemSpellContainer(containerId, name)
    local container, index = self:GetCustomItemSpellContainer(containerId)
    if not container then
        return
    end

    container.Name = TrimName(name) or GetDefaultContainerName(index)
end

local function ResetRemovedContainerAnchors(deletedFrameName)
    local framework = BCDM:EnsureCustomItemSpellFramework()
    if framework then
        for _, container in ipairs(framework.Containers) do
            if type(container.Layout) == "table" and container.Layout[2] == deletedFrameName then
                container.Layout[2] = "NONE"
            end
        end
    end

    local trinketDB = BCDM.db and BCDM.db.profile and BCDM.db.profile.CooldownManager and BCDM.db.profile.CooldownManager.Trinket
    if trinketDB and type(trinketDB.Layout) == "table" and trinketDB.Layout[2] == deletedFrameName then
        trinketDB.Layout[2] = "NONE"
    end
end

function BCDM:DeleteCustomItemSpellContainer(containerId)
    local framework = self:EnsureCustomItemSpellFramework()
    if not framework or #framework.Containers <= 1 then
        return framework and framework.SelectedContainerId or nil
    end

    local deletedIndex
    local deletedContainer
    for index, container in ipairs(framework.Containers) do
        if container.Id == tonumber(containerId) then
            deletedIndex = index
            deletedContainer = container
            break
        end
    end

    if not deletedIndex then
        return framework.SelectedContainerId
    end

    table.remove(framework.Containers, deletedIndex)
    local fallbackIndex = math.max(1, math.min(deletedIndex, #framework.Containers))
    framework.SelectedContainerId = framework.Containers[fallbackIndex].Id

    local deletedFrameName = self:GetCustomItemSpellContainerFrameName(deletedContainer)
    if deletedFrameName then
        ResetRemovedContainerAnchors(deletedFrameName)
        if self.CustomItemSpellContainerFrames and self.CustomItemSpellContainerFrames[deletedContainer.Id] then
            local frame = self.CustomItemSpellContainerFrames[deletedContainer.Id]
            frame:UnregisterAllEvents()
            ReleaseContainerChildren(frame)
            frame:Hide()
            self.CustomItemSpellContainerFrames[deletedContainer.Id] = nil
        end
    end

    self:UpdateCustomItemsSpellsBar()
    if self.UpdateTrinketBar then
        self:UpdateTrinketBar()
    end

    return framework.SelectedContainerId
end

function BCDM:AdjustCustomItemSpellEntryList(containerId, entryId, adjustingHow, entryType)
    local container = self:GetCustomItemSpellContainer(containerId)
    if not container then
        return
    end

    if adjustingHow == "add" then
        entryType = entryType or ResolveItemSpellEntryType(entryId)
        local classSpecFilters
        local filterClass
        if entryType == "spell" then
            filterClass = select(2, UnitClass("player"))
            classSpecFilters = BCDM:BuildClassSpecFilters(filterClass)
        else
            classSpecFilters = BCDM:BuildClassSpecFilters()
        end

        CreateEntry(container, entryId, entryType, nil, classSpecFilters, filterClass)
    elseif adjustingHow == "remove" then
        local removeIndex
        for index, entry in ipairs(container.Entries) do
            if entry.uid == tonumber(entryId) then
                removeIndex = index
                break
            end
        end
        if removeIndex then
            table.remove(container.Entries, removeIndex)
        end
    end

    self:NormalizeCustomItemSpellLayoutIndices(container.Id)
    self:UpdateCustomItemsSpellsBar()
end

function BCDM:AdjustItemsSpellsList(entryId, adjustingHow, entryType, containerId)
    self:AdjustCustomItemSpellEntryList(containerId or self:GetSelectedCustomItemSpellContainerId(), entryId, adjustingHow, entryType)
end

function BCDM:AdjustCustomItemSpellLayoutIndex(containerId, direction, entryUid)
    local container = self:GetCustomItemSpellContainer(containerId)
    if not container then
        return
    end

    local currentIndex
    for _, entry in ipairs(container.Entries) do
        if entry.uid == tonumber(entryUid) then
            currentIndex = entry.layoutIndex
            break
        end
    end

    if not currentIndex then
        return
    end

    local newIndex = currentIndex + direction
    local totalEntries = #container.Entries
    if newIndex < 1 or newIndex > totalEntries then
        return
    end

    for _, entry in ipairs(container.Entries) do
        if entry.layoutIndex == newIndex then
            entry.layoutIndex = currentIndex
            break
        end
    end

    for _, entry in ipairs(container.Entries) do
        if entry.uid == tonumber(entryUid) then
            entry.layoutIndex = newIndex
            break
        end
    end

    self:NormalizeCustomItemSpellLayoutIndices(container.Id)
    self:UpdateCustomItemsSpellsBar()
end

function BCDM:AdjustItemsSpellsLayoutIndex(direction, entryUid, containerId)
    self:AdjustCustomItemSpellLayoutIndex(containerId or self:GetSelectedCustomItemSpellContainerId(), direction, entryUid)
end

local function BuildTextSettingsSignature(textSettings)
    textSettings = textSettings or {}
    local layout = textSettings.Layout or {}
    local colour = textSettings.Colour or {}

    return table.concat({
        tostring(textSettings.FontSize or ""),
        tostring(colour[1] or ""),
        tostring(colour[2] or ""),
        tostring(colour[3] or ""),
        tostring(layout[1] or ""),
        tostring(layout[2] or ""),
        tostring(layout[3] or ""),
        tostring(layout[4] or ""),
    }, "|")
end

local function BuildFontShadowSignature(shadowSettings)
    shadowSettings = shadowSettings or {}
    local colour = shadowSettings.Colour or {}

    return table.concat({
        tostring(shadowSettings.Enabled and 1 or 0),
        tostring(colour[1] or ""),
        tostring(colour[2] or ""),
        tostring(colour[3] or ""),
        tostring(colour[4] or ""),
        tostring(shadowSettings.OffsetX or ""),
        tostring(shadowSettings.OffsetY or ""),
    }, "|")
end

local function BuildCustomItemSpellStyleSignature(customDB)
    local cooldownManagerDB = BCDM.db.profile.CooldownManager
    local generalDB = BCDM.db.profile.General
    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
    local keepAspectRatio = customDB.KeepAspectRatio
    local showItemQualityBorder = customDB.ShowItemQualityBorder ~= false
    if keepAspectRatio == nil then
        keepAspectRatio = true
    end

    return table.concat({
        tostring(iconWidth or ""),
        tostring(iconHeight or ""),
        tostring(keepAspectRatio and 1 or 0),
        tostring(customDB.FrameStrata or ""),
        tostring(showItemQualityBorder and 1 or 0),
        tostring(cooldownManagerDB.General.BorderSize or ""),
        tostring(cooldownManagerDB.General.IconZoom or ""),
        tostring(BCDM.Media and BCDM.Media.Font or ""),
        tostring(generalDB.Fonts and generalDB.Fonts.FontFlag or ""),
        BuildTextSettingsSignature(customDB.Text),
        BuildFontShadowSignature(generalDB.Fonts and generalDB.Fonts.Shadow),
    }, "::")
end

local function DeactivateCachedIcon(customIcon)
    if not customIcon then
        return
    end

    if customIcon.BCDMDeactivate then
        customIcon:BCDMDeactivate()
        return
    end

    customIcon:UnregisterAllEvents()
    customIcon:Hide()
    customIcon:SetParent(nil)
end

local function ActivateCachedIcon(customIcon)
    if not customIcon then
        return
    end

    if customIcon.BCDMActivate then
        customIcon:BCDMActivate()
    end
end

local function RefreshCustomViewerIcon(customIcon, event, ...)
    if not customIcon or not customIcon.BCDMIsActive then
        return
    end

    local onEvent = customIcon:GetScript("OnEvent")
    if onEvent then
        onEvent(customIcon, event, ...)
    end
end

local function DispatchIndexedSpellIconEvents(frame, event, updatedSpellId, updatedBaseSpellId, refreshAllSpellIcons)
    if not frame or not frame.SpellIcons then
        return
    end

    if refreshAllSpellIcons or (updatedSpellId == nil and updatedBaseSpellId == nil) then
        for _, customIcon in ipairs(frame.SpellIcons) do
            RefreshCustomViewerIcon(customIcon, event, updatedSpellId, updatedBaseSpellId)
        end
        return
    end

    local refreshedIcons = {}
    local function RefreshSpellBucket(spellId)
        local bucket = spellId and frame.SpellCooldownIndex and frame.SpellCooldownIndex[tonumber(spellId)]
        if not bucket then
            return
        end

        for _, customIcon in ipairs(bucket) do
            if customIcon and customIcon.BCDMIsActive and not refreshedIcons[customIcon] and IsTrackedSpellCooldownUpdate(customIcon.BCDMSpellId, updatedSpellId, updatedBaseSpellId) then
                refreshedIcons[customIcon] = true
                RefreshCustomViewerIcon(customIcon, event, updatedSpellId, updatedBaseSpellId)
            end
        end
    end

    RefreshSpellBucket(updatedSpellId)
    RefreshSpellBucket(updatedBaseSpellId)
end

local CustomViewerSpellEventFrame

local function DispatchCustomViewerSpellEvents(event, updatedSpellId, updatedBaseSpellId)
    -- Spell cooldown updates can affect every icon because GCD state is shared.
    local refreshAllSpellIcons = event == "SPELL_UPDATE_COOLDOWN"

    for _, frame in pairs(BCDM.CustomItemSpellContainerFrames or {}) do
        if frame and frame.HasSpellIcons and frame.SpellIcons and #frame.SpellIcons > 0 and frame:IsShown() then
            DispatchIndexedSpellIconEvents(frame, event, updatedSpellId, updatedBaseSpellId, refreshAllSpellIcons)
        end
    end
end

local function EnsureCustomViewerSpellEventFrame()
    if CustomViewerSpellEventFrame then
        return CustomViewerSpellEventFrame
    end

    CustomViewerSpellEventFrame = CreateFrame("Frame")
    CustomViewerSpellEventFrame:SetScript("OnEvent", function(_, event, ...)
        DispatchCustomViewerSpellEvents(event, ...)
    end)

    return CustomViewerSpellEventFrame
end

local function UpdateCustomViewerSpellEventRegistration()
    local spellEventFrame = EnsureCustomViewerSpellEventFrame()
    local hasActiveSpellIcons = false

    for _, frame in pairs(BCDM.CustomItemSpellContainerFrames or {}) do
        if frame and frame.HasSpellIcons and frame.SpellIcons and #frame.SpellIcons > 0 and frame:IsShown() then
            hasActiveSpellIcons = true
            break
        end
    end

    if hasActiveSpellIcons then
        spellEventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        spellEventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
        spellEventFrame:RegisterEvent("SPELL_UPDATE_USES")
    else
        spellEventFrame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
        spellEventFrame:UnregisterEvent("SPELL_UPDATE_CHARGES")
        spellEventFrame:UnregisterEvent("SPELL_UPDATE_USES")
    end
end

local function DispatchContainerIconEvents(frame, event, ...)
    if not frame or not frame.ActiveIcons then
        return
    end

    local updatedSpellId, updatedBaseSpellId = ...

    if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" or event == "SPELL_UPDATE_USES" then
        DispatchIndexedSpellIconEvents(frame, event, updatedSpellId, updatedBaseSpellId)
        return
    end

    for _, customIcon in ipairs(frame.ActiveIcons) do
        if customIcon and customIcon.BCDMIsActive then
            if customIcon.BCDMIconType == "item" then
                if event == "BAG_UPDATE_COOLDOWN" then
                    RefreshCustomViewerIcon(customIcon, event, ...)
                elseif event == "ITEM_COUNT_CHANGED" then
                    local itemId = ...
                    if not itemId or itemId == customIcon.BCDMItemId then
                        RefreshCustomViewerIcon(customIcon, event, ...)
                    end
                end
            elseif customIcon.BCDMIconType == "trinket" then
                if event == "ACTIONBAR_UPDATE_COOLDOWN" then
                    RefreshCustomViewerIcon(customIcon, event, ...)
                end
            end
        end
    end
end

local function GetActiveIconTypeFlags(activeIcons)
    local hasItemIcons, hasSpellIcons, hasTrinketIcons = false, false, false

    for _, customIcon in ipairs(activeIcons or {}) do
        if customIcon and customIcon.BCDMIsActive then
            if customIcon.BCDMIconType == "item" then
                hasItemIcons = true
            elseif customIcon.BCDMIconType == "spell" then
                hasSpellIcons = true
            elseif customIcon.BCDMIconType == "trinket" then
                hasTrinketIcons = true
            end
        end
    end

    return hasItemIcons, hasSpellIcons, hasTrinketIcons
end

local function CreateCustomItemIcon(customDB, entry)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local itemId = entry.entryId
    if not itemId then return end
    if not C_Item.GetItemInfo(itemId) then return end

    local customIcon = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end

    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
    customIcon:SetSize(iconWidth, iconHeight)
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(customDB.FrameStrata or "LOW")

    local highLevelContainer = CreateFrame("Frame", nil, customIcon)
    highLevelContainer:SetAllPoints(customIcon)
    highLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

    customIcon.Charges = highLevelContainer:CreateFontString(nil, "OVERLAY")
    customIcon.Charges:SetFont(BCDM.Media.Font, customDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    customIcon.Charges:SetPoint(customDB.Text.Layout[1], customIcon, customDB.Text.Layout[2], customDB.Text.Layout[3], customDB.Text.Layout[4])
    customIcon.Charges:SetTextColor(customDB.Text.Colour[1], customDB.Text.Colour[2], customDB.Text.Colour[3], 1)
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
    customIcon.Cooldown:SetDrawBling(false)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)
    customIcon.BCDMIconType = "item"
    customIcon.BCDMItemId = itemId

    customIcon.QualityAtlas = highLevelContainer:CreateTexture(nil, "OVERLAY")
    customIcon.QualityAtlas:Hide()
    ApplyItemQualityAtlas(customIcon, itemId, customDB, iconWidth, iconHeight)

    customIcon:SetScript("OnEvent", function(self, event)
        if event == "BAG_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "ITEM_COUNT_CHANGED" then
            local itemCount, startTime, durationTime = FetchItemData(itemId)
            if itemCount then
                local hasActiveCooldown, readableStartTime, readableDurationTime = HasReadableActiveCooldown(startTime, durationTime)
                customIcon.Charges:SetText(tostring(itemCount))
                if C_Item.IsUsableItem(itemId) then
                    local shouldRefreshCooldown = ShouldRefreshItemCooldownFrame(customIcon.Cooldown, hasActiveCooldown, startTime, durationTime)
                    if hasActiveCooldown and shouldRefreshCooldown then
                        local durationObject = C_DurationUtil.CreateDuration()
                        durationObject:SetTimeFromStart(readableStartTime, readableDurationTime)
                        customIcon.Cooldown:SetCooldownFromDurationObject(durationObject, true)
                    elseif not hasActiveCooldown and event ~= "ITEM_COUNT_CHANGED" and shouldRefreshCooldown then
                        customIcon.Cooldown:SetCooldownFromDurationObject(C_DurationUtil.CreateDuration(), true)
                    end
                end

                if itemCount <= 0 then
                    customIcon.Charges:SetText("")
                else
                    customIcon.Charges:SetText(tostring(itemCount))
                end

                if BCDM:IsSecretValue(startTime) or BCDM:IsSecretValue(durationTime) then
                    SetIconDesaturation(customIcon.Icon, 0)
                elseif hasActiveCooldown then
                    SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(readableStartTime, readableDurationTime))
                else
                    SetIconDesaturation(customIcon.Icon, 0)
                end

                if not C_Item.IsUsableItem(itemId) then
                    customIcon.Icon:SetVertexColor(0.5, 0.5, 0.5)
                else
                    customIcon.Icon:SetVertexColor(1, 1, 1)
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
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)
    customIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(itemId)))

    customIcon.BCDMActivate = function(self)
        if self.BCDMIsActive then
            return
        end

        self.BCDMIsActive = true

        RefreshCustomViewerIcon(self, "PLAYER_ENTERING_WORLD")
    end

    customIcon.BCDMDeactivate = function(self)
        if not self.BCDMIsActive then
            return
        end

        self:UnregisterAllEvents()
        self.BCDMIsActive = false
        self:Hide()
        self:SetParent(nil)
    end

    customIcon:BCDMActivate()

    return customIcon
end

local function CreateEquippedTrinketIcon(customDB, itemId)
    local CooldownManagerDB = BCDM.db.profile
    if not itemId then return end
    if not C_Item.GetItemInfo(itemId) then return end

    local customIcon = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end

    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
    customIcon:SetSize(iconWidth, iconHeight)
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(customDB.FrameStrata or "LOW")

    customIcon.Cooldown = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
    customIcon.Cooldown:SetAllPoints(customIcon)
    customIcon.Cooldown:SetDrawEdge(false)
    customIcon.Cooldown:SetDrawSwipe(true)
    customIcon.Cooldown:SetDrawBling(false)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)
    customIcon.BCDMIconType = "trinket"
    customIcon.BCDMItemId = itemId

    customIcon:SetScript("OnEvent", function(self, event)
        if event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" then
            local startTime, durationTime = select(2, FetchItemData(itemId))
            local hasActiveCooldown, readableStartTime, readableDurationTime = HasReadableActiveCooldown(startTime, durationTime)
            if hasActiveCooldown then
                local durationObject = C_DurationUtil.CreateDuration()
                durationObject:SetTimeFromStart(readableStartTime, readableDurationTime)
                customIcon.Cooldown:SetCooldownFromDurationObject(durationObject, true)
                if BCDM:IsSecretValue(startTime) or BCDM:IsSecretValue(durationTime) then
                    SetIconDesaturation(customIcon.Icon, 0)
                else
                    SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(readableStartTime, readableDurationTime))
                end
            else
                customIcon.Cooldown:SetCooldownFromDurationObject(C_DurationUtil.CreateDuration(), true)
                SetIconDesaturation(customIcon.Icon, 0)
            end
        end
    end)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = CooldownManagerDB.CooldownManager.General.IconZoom * 0.5
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)
    customIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(itemId)))

    customIcon.BCDMActivate = function(self)
        if self.BCDMIsActive then
            return
        end

        self.BCDMIsActive = true

        RefreshCustomViewerIcon(self, "PLAYER_ENTERING_WORLD")
    end

    customIcon.BCDMDeactivate = function(self)
        if not self.BCDMIsActive then
            return
        end

        self:UnregisterAllEvents()
        self.BCDMIsActive = false
        self:Hide()
        self:SetParent(nil)
    end

    customIcon:BCDMActivate()

    return customIcon
end

local function CreateCustomSpellIcon(customDB, entry)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local spellId = entry.entryId
    if not spellId then return end
    if not C_SpellBook.IsSpellInSpellBook(spellId) then return end

    local customIcon = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end

    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
    customIcon:SetSize(iconWidth, iconHeight)
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(customDB.FrameStrata or "LOW")

    local highLevelContainer = CreateFrame("Frame", nil, customIcon)
    highLevelContainer:SetAllPoints(customIcon)
    highLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

    customIcon.Charges = highLevelContainer:CreateFontString(nil, "OVERLAY")
    customIcon.Charges:SetFont(BCDM.Media.Font, customDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    customIcon.Charges:SetPoint(customDB.Text.Layout[1], customIcon, customDB.Text.Layout[2], customDB.Text.Layout[3], customDB.Text.Layout[4])
    customIcon.Charges:SetTextColor(customDB.Text.Colour[1], customDB.Text.Colour[2], customDB.Text.Colour[3], 1)
    if GeneralDB.Fonts.Shadow.Enabled then
        customIcon.Charges:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        customIcon.Charges:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
    else
        customIcon.Charges:SetShadowColor(0, 0, 0, 0)
        customIcon.Charges:SetShadowOffset(0, 0)
    end

    customIcon.CastCount = highLevelContainer:CreateFontString(nil, "OVERLAY")
    customIcon.CastCount:SetFont(BCDM.Media.Font, customDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    customIcon.CastCount:SetPoint(customDB.Text.Layout[1], customIcon, customDB.Text.Layout[2], customDB.Text.Layout[3], customDB.Text.Layout[4])
    customIcon.CastCount:SetTextColor(customDB.Text.Colour[1], customDB.Text.Colour[2], customDB.Text.Colour[3], 1)
    if GeneralDB.Fonts.Shadow.Enabled then
        customIcon.CastCount:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        customIcon.CastCount:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
    else
        customIcon.CastCount:SetShadowColor(0, 0, 0, 0)
        customIcon.CastCount:SetShadowOffset(0, 0)
    end
    customIcon.CastCount:SetText("")

    customIcon.Cooldown = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
    customIcon.Cooldown:SetAllPoints(customIcon)
    customIcon.Cooldown:SetDrawEdge(false)
    customIcon.Cooldown:SetDrawSwipe(true)
    customIcon.Cooldown:SetDrawBling(false)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)
    customIcon.BCDMIconType = "spell"
    customIcon.BCDMSpellId = spellId

    customIcon:SetScript("OnEvent", function(self, event, updatedSpellId, updatedBaseSpellId)
        if event == "SPELL_UPDATE_CHARGES" or event == "SPELL_UPDATE_USES" then
            -- Retail can now tell us which spell changed, so skip unrelated invalidations.
            if not IsTrackedSpellCooldownUpdate(spellId, updatedSpellId, updatedBaseSpellId) then
                return
            end
        end

        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "SPELL_UPDATE_CHARGES" then
            UpdateCustomSpellIconCooldown(customIcon, spellId)
            UpdateSpellIconDesaturation(self, spellId)
        end

        if event == "SPELL_UPDATE_USES" then
            local spellCharges = C_Spell.GetSpellCharges(spellId)
            local maxCharges = GetReadableNumber(spellCharges and spellCharges.maxCharges) or 0
            if maxCharges <= 1 then
                local castCount = C_Spell.GetSpellCastCount(spellId)
                local colour = customDB.Text.Colour
                customIcon.CastCount:SetText(castCount)
                customIcon.CastCount:SetTextColor(colour[1], colour[2], colour[3], castCount)
            end
        end
    end)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)
    customIcon.Icon:SetTexture(C_Spell.GetSpellInfo(spellId).iconID)

    customIcon.BCDMActivate = function(self)
        if self.BCDMIsActive then
            return
        end

        self.BCDMIsActive = true

        RefreshCustomViewerIcon(self, "PLAYER_ENTERING_WORLD")
    end

    customIcon.BCDMDeactivate = function(self)
        if not self.BCDMIsActive then
            return
        end

        self:UnregisterAllEvents()
        self.BCDMIsActive = false
        self:Hide()
        self:SetParent(nil)
    end

    customIcon:BCDMActivate()

    return customIcon
end

local function GetPlayerSpecState()
    local playerClass = select(2, UnitClass("player"))
    local specIndex = GetSpecialization()
    local specID, specName = specIndex and GetSpecializationInfo(specIndex)
    local playerSpecialization = BCDM:NormalizeSpecToken(specName, specID, specIndex)
    return playerClass, playerSpecialization
end

local function GetPlayerSpecStateSignature()
    local playerClass, playerSpecialization = GetPlayerSpecState()
    return tostring(playerClass or "") .. ":" .. tostring(playerSpecialization or "")
end

local function GetTrackedHealthstoneInfo(entries, playerClass, playerSpecialization)
    if playerClass ~= "WARLOCK" then
        return nil, nil
    end

    local healthstoneIndex
    for _, entry in ipairs(entries or {}) do
        local entryId = entry and entry.entryId
        if entry and entry.isActive and (entryId == HEALTHSTONE_BASE_ID or entryId == HEALTHSTONE_GLUTTONY_ID) then
            if ResolveItemSpellEntryType(entryId, entry) == "item" and IsEntryEnabledForPlayerSpec(entry, playerClass, playerSpecialization) then
                healthstoneIndex = math.min(healthstoneIndex or math.huge, entry.layoutIndex or math.huge)
            end
        end
    end

    if not healthstoneIndex then
        return nil, nil
    end

    local activeHealthstoneId = C_SpellBook.IsSpellKnown(PACT_OF_GLUTTONY_SPELL_ID) and HEALTHSTONE_GLUTTONY_ID or HEALTHSTONE_BASE_ID
    return activeHealthstoneId, healthstoneIndex
end

local function GetOrCreateCachedCustomIcon(iconCache, cacheKey, iconType, customDB, entryData)
    local customIcon = iconCache and iconCache[cacheKey]
    if customIcon then
        ActivateCachedIcon(customIcon)
        return customIcon
    end

    if iconType == "spell" then
        customIcon = CreateCustomSpellIcon(customDB, entryData)
    elseif iconType == "trinket" then
        customIcon = CreateEquippedTrinketIcon(customDB, entryData.itemId)
    else
        customIcon = CreateCustomItemIcon(customDB, entryData)
    end

    if customIcon and iconCache then
        iconCache[cacheKey] = customIcon
    end

    return customIcon
end

local function CreateCustomIcons(customDB, entries, iconTable, visibleItemIds, iconCache)
    local playerClass, playerSpecialization = GetPlayerSpecState()
    local activeEntries = {}
    local potionGroups = {}
    local activeHealthstoneId, healthstoneIndex = GetTrackedHealthstoneInfo(entries, playerClass, playerSpecialization)
    local activeIconKeys = {}

    wipe(iconTable)
    if visibleItemIds then wipe(visibleItemIds) end

    for _, entry in ipairs(entries or {}) do
        if entry.isActive and IsEntryEnabledForPlayerSpec(entry, playerClass, playerSpecialization) then
            local entryType = ResolveItemSpellEntryType(entry.entryId, entry)
            local layoutIndex = entry.layoutIndex or math.huge

            if entryType == "item" then
                if activeHealthstoneId and (entry.entryId == HEALTHSTONE_BASE_ID or entry.entryId == HEALTHSTONE_GLUTTONY_ID) then
                    entryType = nil
                else
                    local isPotionEntry = SelectPotionRankCandidate(potionGroups, entry.entryId, layoutIndex)
                    if isPotionEntry then
                        entryType = nil
                    elseif not ShouldShowItem(customDB, entry.entryId) then
                        entryType = nil
                    end
                end
            end

            if entryType then
                activeEntries[#activeEntries + 1] = {
                    uid = entry.uid,
                    entryId = entry.entryId,
                    entryType = entryType,
                    layoutIndex = layoutIndex,
                    entry = entry,
                    cacheKey = entryType .. ":" .. tostring(entry.uid or entry.entryId),
                }
            end
        end
    end

    for _, potionGroup in pairs(potionGroups) do
        local selected = potionGroup.selected
        if selected and selected.count > 0 then
            activeEntries[#activeEntries + 1] = {
                entryId = selected.id,
                entryType = "item",
                layoutIndex = potionGroup.index or math.huge,
                entry = { entryId = selected.id, entryType = "item" },
                cacheKey = "potion:" .. tostring(potionGroup.index or math.huge) .. ":" .. tostring(selected.id),
            }
        end
    end

    if activeHealthstoneId and healthstoneIndex and ShouldShowItem(customDB, activeHealthstoneId) then
        activeEntries[#activeEntries + 1] = {
            entryId = activeHealthstoneId,
            entryType = "item",
            layoutIndex = healthstoneIndex,
            entry = { entryId = activeHealthstoneId, entryType = "item" },
            cacheKey = "healthstone:" .. tostring(activeHealthstoneId),
        }
    end

    table.sort(activeEntries, function(a, b)
        if a.layoutIndex == b.layoutIndex then
            local aUid = tonumber(a.uid) or a.entryId
            local bUid = tonumber(b.uid) or b.entryId
            return aUid < bUid
        end
        return a.layoutIndex < b.layoutIndex
    end)

    for _, entry in ipairs(activeEntries) do
        local customIcon = GetOrCreateCachedCustomIcon(iconCache, entry.cacheKey, entry.entryType, customDB, entry.entry)

        if customIcon then
            activeIconKeys[entry.cacheKey] = true
            iconTable[#iconTable + 1] = customIcon
            if entry.entryType ~= "spell" and visibleItemIds then
                visibleItemIds[entry.entryId] = true
            end
        end
    end

    if customDB.IncludeUsableTrinkets then
        for _, trinketEntry in ipairs(FetchEquippedOnUseTrinkets()) do
            local cacheKey = "trinket:" .. tostring(trinketEntry.slotID or 0) .. ":" .. tostring(trinketEntry.itemId)
            local customTrinket = GetOrCreateCachedCustomIcon(iconCache, cacheKey, "trinket", customDB, trinketEntry)
            if customTrinket then
                activeIconKeys[cacheKey] = true
                iconTable[#iconTable + 1] = customTrinket
            end
        end
    end

    return activeIconKeys
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

local function GetOrCreateContainerFrame(container)
    BCDM.CustomItemSpellContainerFrames = BCDM.CustomItemSpellContainerFrames or {}
    local frame = BCDM.CustomItemSpellContainerFrames[container.Id]
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", GetContainerFrameName(container.Id), UIParent, "BackdropTemplate")
    frame:SetSize(1, 1)
    frame.ContainerId = container.Id
    BCDM.CustomItemSpellContainerFrames[container.Id] = frame
    return frame
end

local function ReleaseContainerChildren(frame)
    if not frame then
        return
    end

    if frame.IconCache then
        for _, customIcon in pairs(frame.IconCache) do
            DeactivateCachedIcon(customIcon)
        end
        wipe(frame.IconCache)
    else
        for _, child in ipairs({ frame:GetChildren() }) do
            child:UnregisterAllEvents()
            child:Hide()
            child:SetParent(nil)
        end
    end

    frame.ActiveIcons = nil
    frame.VisibleItemIds = nil
    frame.SpellCooldownIndex = nil
    frame.SpellIcons = nil
    frame.HasSpellIcons = nil
    frame.StyleSignature = nil
    frame.PlayerSpecState = nil
end

local function HideUnusedCachedIcons(frame, activeIconKeys)
    if not frame or not frame.IconCache then
        return
    end

    for cacheKey, customIcon in pairs(frame.IconCache) do
        if not activeIconKeys[cacheKey] then
            DeactivateCachedIcon(customIcon)
        end
    end
end

local function RequestDeferredContainerUpdate(frame)
    if not frame or frame.PendingRefresh then
        return
    end

    frame.PendingRefresh = true
    C_Timer.After(0, function()
        frame.PendingRefresh = false
        BCDM:UpdateCustomItemSpellContainer(frame.ContainerId)
    end)
end

local function SetupFrameEventHandler(frame)
    if frame.HideZeroEventHooked then
        return
    end

    frame.HideZeroEventHooked = true
    frame:SetScript("OnEvent", function(self, event, ...)
        local eventArg1, eventArg2 = ...
        local container = BCDM:GetCustomItemSpellContainer(self.ContainerId)
        if not container then
            return
        end

        if event == "BAG_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
            DispatchContainerIconEvents(self, event, eventArg1, eventArg2)
            return
        end

        if event == "PLAYER_EQUIPMENT_CHANGED" then
            if eventArg1 == 13 or eventArg1 == 14 then
                RequestDeferredContainerUpdate(self)
            end
            return
        end

        if event == "PLAYER_ENTERING_WORLD" or event == "BAG_UPDATE_DELAYED" then
            RequestDeferredContainerUpdate(self)
            return
        end

        if event ~= "ITEM_COUNT_CHANGED" and event ~= "ITEM_PUSH" then
            return
        end

        local itemId = eventArg1
        if not itemId then
            RequestDeferredContainerUpdate(self)
            return
        end

        local playerClass, playerSpecialization = GetPlayerSpecState()
        local activeHealthstoneId, healthstoneIndex = GetTrackedHealthstoneInfo(container.Entries, playerClass, playerSpecialization)

        local hasTrackedItem = false
        local itemIsPotion = false
        for _, entry in ipairs(container.Entries or {}) do
            if entry.isActive and ResolveItemSpellEntryType(entry.entryId, entry) == "item" and IsEntryEnabledForPlayerSpec(entry, playerClass, playerSpecialization) then
                if entry.entryId == itemId then
                    hasTrackedItem = true
                    itemIsPotion = IsPotionItem(itemId)
                    break
                end
            end
        end

        if not hasTrackedItem and activeHealthstoneId and healthstoneIndex and (itemId == HEALTHSTONE_BASE_ID or itemId == HEALTHSTONE_GLUTTONY_ID) then
            hasTrackedItem = true
        end

        if not hasTrackedItem then
            return
        end

        if itemIsPotion or (activeHealthstoneId and (itemId == HEALTHSTONE_BASE_ID or itemId == HEALTHSTONE_GLUTTONY_ID)) then
            RequestDeferredContainerUpdate(self)
            return
        end

        if not container.HideZeroCharges then
            if event == "ITEM_COUNT_CHANGED" then
                DispatchContainerIconEvents(self, event, itemId)
            end
            return
        end

        local activeItemId = activeHealthstoneId and (itemId == HEALTHSTONE_BASE_ID or itemId == HEALTHSTONE_GLUTTONY_ID) and activeHealthstoneId or itemId
        local visible = self.VisibleItemIds and self.VisibleItemIds[activeItemId] or false
        local shouldShow = ShouldShowItem(container, activeItemId)
        if visible ~= shouldShow then
            RequestDeferredContainerUpdate(self)
        elseif event == "ITEM_COUNT_CHANGED" then
            DispatchContainerIconEvents(self, event, itemId)
        end
    end)
end

local function LayoutCustomItemSpellContainer(container)
    if not container then
        return
    end

    local customItemBarIcons = {}
    local visibleItemIds = {}
    local frame = GetOrCreateContainerFrame(container)
    local growthDirection = container.GrowthDirection or "RIGHT"
    local styleSignature = BuildCustomItemSpellStyleSignature(container)
    local playerSpecState = GetPlayerSpecStateSignature()

    -- Spec swaps can change which spells exist in the spellbook, so cached icons
    -- need to be recreated instead of only being re-laid out.
    if frame.StyleSignature ~= styleSignature or frame.PlayerSpecState ~= playerSpecState then
        ReleaseContainerChildren(frame)
        frame.IconCache = {}
    end

    frame.IconCache = frame.IconCache or {}
    frame.StyleSignature = styleSignature
    frame.PlayerSpecState = playerSpecState

    local containerAnchorFrom = container.Layout[1]
    if growthDirection == "UP" then
        local verticalFlipMap = {
            ["TOPLEFT"] = "BOTTOMLEFT",
            ["TOP"] = "BOTTOM",
            ["TOPRIGHT"] = "BOTTOMRIGHT",
            ["BOTTOMLEFT"] = "TOPLEFT",
            ["BOTTOM"] = "TOP",
            ["BOTTOMRIGHT"] = "TOPRIGHT",
        }
        containerAnchorFrom = verticalFlipMap[container.Layout[1]] or container.Layout[1]
    end

    frame:ClearAllPoints()
    frame:SetFrameStrata(container.FrameStrata or "LOW")
    local anchorParent = BCDM:ResolveAnchorFrame(container.Layout[2])
    frame:SetPoint(containerAnchorFrom, anchorParent, container.Layout[3], container.Layout[4], container.Layout[5])

    SetupFrameEventHandler(frame)

    local shouldTrackItemCountChanges = container.HideZeroCharges or HasTrackedPotionEntries(container.Entries) or HasTrackedHealthstoneEntries(container.Entries)
    if shouldTrackItemCountChanges then
        frame:RegisterEvent("ITEM_COUNT_CHANGED")
        frame:RegisterEvent("ITEM_PUSH")
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        frame:UnregisterEvent("ITEM_COUNT_CHANGED")
        frame:UnregisterEvent("ITEM_PUSH")
        frame:UnregisterEvent("BAG_UPDATE_DELAYED")
        frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

    if container.IncludeUsableTrinkets then
        frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    else
        frame:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    end

    local activeIconKeys = CreateCustomIcons(container, container.Entries, customItemBarIcons, visibleItemIds, frame.IconCache)
    HideUnusedCachedIcons(frame, activeIconKeys)

    frame.ActiveIcons = customItemBarIcons
    frame.VisibleItemIds = visibleItemIds
    frame.SpellCooldownIndex, frame.SpellIcons = BuildSpellCooldownIndex(customItemBarIcons)
    local hasItemIcons, hasSpellIcons, hasTrinketIcons = GetActiveIconTypeFlags(customItemBarIcons)
    frame.HasSpellIcons = hasSpellIcons

    local iconWidth, iconHeight = BCDM:GetIconDimensions(container)
    local iconSpacing = container.Spacing
    local point = select(1, frame:GetPoint(1))
    local isHorizontalGrowth = growthDirection == "LEFT" or growthDirection == "RIGHT"
    local wrapLimit = GetColumnWrapLimit(container)
    local lineLimit = (wrapLimit > 0) and wrapLimit or #customItemBarIcons
    local useCenteredLayout = IsCenteredHorizontalLayout(point, growthDirection)

    if #customItemBarIcons == 0 then
        frame:SetSize(1, 1)
    else
        local totalWidth, totalHeight
        local lineCount = math.ceil(#customItemBarIcons / lineLimit)

        if isHorizontalGrowth then
            local columnsInRow = math.min(lineLimit, #customItemBarIcons)
            totalWidth = (columnsInRow * iconWidth) + ((columnsInRow - 1) * iconSpacing)
            totalHeight = (lineCount * iconHeight) + ((lineCount - 1) * iconSpacing)
        else
            local rowsInColumn = math.min(lineLimit, #customItemBarIcons)
            totalWidth = (lineCount * iconWidth) + ((lineCount - 1) * iconSpacing)
            totalHeight = (rowsInColumn * iconHeight) + ((rowsInColumn - 1) * iconSpacing)
        end

        frame:SetWidth(totalWidth)
        frame:SetHeight(totalHeight)
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

    if useCenteredLayout and #customItemBarIcons > 0 then
        local rowCount = math.ceil(#customItemBarIcons / lineLimit)
        local rowDirection = ShouldGrowUp(point) and 1 or -1

        for rowIndex = 1, rowCount do
            local rowStart = ((rowIndex - 1) * lineLimit) + 1
            local rowEnd = math.min(rowStart + lineLimit - 1, #customItemBarIcons)
            local rowIcons = rowEnd - rowStart + 1
            local rowWidth = (rowIcons * iconWidth) + ((rowIcons - 1) * iconSpacing)
            local startOffset = -(rowWidth / 2) + (iconWidth / 2)
            local yOffset = (rowIndex - 1) * (iconHeight + iconSpacing) * rowDirection

            for i = rowStart, rowEnd do
                local spellIcon = customItemBarIcons[i]
                spellIcon:SetParent(frame)
                spellIcon:SetSize(iconWidth, iconHeight)
                spellIcon:ClearAllPoints()

                local xOffset = startOffset + ((i - rowStart) * (iconWidth + iconSpacing))
                spellIcon:SetPoint("CENTER", frame, "CENTER", xOffset, yOffset)
                spellIcon:Show()
            end
        end
    else
        for i, spellIcon in ipairs(customItemBarIcons) do
            spellIcon:SetParent(frame)
            spellIcon:SetSize(iconWidth, iconHeight)
            spellIcon:ClearAllPoints()

            if i == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                spellIcon:SetPoint(config.anchor, frame, config.anchor, 0, 0)
            else
                local isWrappedRowStart = (i - 1) % lineLimit == 0
                if isWrappedRowStart then
                    local lineAnchorIcon = customItemBarIcons[i - lineLimit]
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
                        spellIcon:SetPoint("LEFT", customItemBarIcons[i - 1], "RIGHT", iconSpacing, 0)
                    elseif growthDirection == "LEFT" then
                        spellIcon:SetPoint("RIGHT", customItemBarIcons[i - 1], "LEFT", -iconSpacing, 0)
                    elseif growthDirection == "UP" then
                        spellIcon:SetPoint("BOTTOM", customItemBarIcons[i - 1], "TOP", 0, iconSpacing)
                    elseif growthDirection == "DOWN" then
                        spellIcon:SetPoint("TOP", customItemBarIcons[i - 1], "BOTTOM", 0, -iconSpacing)
                    end
                end
            end
            spellIcon:Show()
        end
    end

    ApplyCooldownText(frame)

    if hasItemIcons or shouldTrackItemCountChanges then
        frame:RegisterEvent("ITEM_COUNT_CHANGED")
    else
        frame:UnregisterEvent("ITEM_COUNT_CHANGED")
    end

    if hasItemIcons then
        frame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    else
        frame:UnregisterEvent("BAG_UPDATE_COOLDOWN")
    end

    if hasTrinketIcons then
        frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    else
        frame:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    end

    frame:Show()
end

local function HideUnusedContainerFrames(activeContainerIds)
    local frames = BCDM.CustomItemSpellContainerFrames or {}
    for containerId, frame in pairs(frames) do
        if not activeContainerIds[containerId] then
            frame:UnregisterAllEvents()
            ReleaseContainerChildren(frame)
            frame:Hide()
        end
    end
end

function BCDM:UpdateCustomItemSpellContainer(containerId)
    local container = self:GetCustomItemSpellContainer(containerId)
    if not container then
        if self.CustomItemSpellContainerFrames and self.CustomItemSpellContainerFrames[tonumber(containerId)] then
            local frame = self.CustomItemSpellContainerFrames[tonumber(containerId)]
            frame:UnregisterAllEvents()
            ReleaseContainerChildren(frame)
            frame:Hide()
        end
        UpdateCustomViewerSpellEventRegistration()
        return
    end

    LayoutCustomItemSpellContainer(container)
    UpdateCustomViewerSpellEventRegistration()
end

function BCDM:SetupCustomItemsSpellsBar()
    self:EnsureCustomItemSpellFramework()
    self:UpdateCustomItemsSpellsBar()
end

function BCDM:UpdateCustomItemsSpellsBar()
    local activeContainerIds = {}
    for _, container in ipairs(self:GetCustomItemSpellContainers()) do
        activeContainerIds[container.Id] = true
        LayoutCustomItemSpellContainer(container)
    end
    HideUnusedContainerFrames(activeContainerIds)
    UpdateCustomViewerSpellEventRegistration()
end
