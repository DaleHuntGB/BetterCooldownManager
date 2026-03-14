local _, BCDM = ...

local customIconPool

local VIEWER_KEY               = "CustomViewer"
local VIEWER_FRAME_NAME        = "BCDM_CustomViewer"
local LEGACY_MIGRATION_VERSION = 1
local VIEWER_SCHEMA_VERSION    = 1
local TRINKET_SLOTS = { 13, 14 }

local CUSTOM_VIEWER_SETTING_KEYS = {
    "IconSize", "IconWidth", "IconHeight", "KeepAspectRatio",
    "FrameStrata", "Layout", "Spacing", "GrowthDirection", "Columns",
    "OffsetByParentHeight", "HideZeroCharges", "ShowItemQualityBorder",
    "AutoDetectUsableTrinkets", "Text",
}

local function GetCustomRootDB()
    return BCDM.db.profile.CooldownManager[VIEWER_KEY]
end

local function BuildCustomViewerFrameName(viewerID)
    return viewerID == 1 and VIEWER_FRAME_NAME or (VIEWER_FRAME_NAME .. "_" .. viewerID)
end

local function BuildCustomViewerName(viewerID)
    return "Custom Viewer " .. tostring(viewerID)
end

local function GetDefaultCustomViewerDB()
    local customDefaults = BCDM:GetDefaultDB().profile.CooldownManager[VIEWER_KEY]
    local defaultViewer  = customDefaults and customDefaults.Viewers and customDefaults.Viewers[1]
    return defaultViewer or customDefaults
end

local function EnsureCustomViewerCollectionDefaults(customRootDB)
    if type(customRootDB) ~= "table" then return end
    local defaultViewer = GetDefaultCustomViewerDB()

    customRootDB.Viewers = customRootDB.Viewers or {}
    if #customRootDB.Viewers == 0 then
        customRootDB.Viewers[1] = BCDM:CopyTable(defaultViewer)
    end

    local usedIDs         = {}
    local nextGeneratedID = 1

    for index, viewerData in ipairs(customRootDB.Viewers) do
        if type(viewerData) ~= "table" then
            viewerData = {}
        end

        for key, defaultValue in pairs(defaultViewer) do
            if viewerData[key] == nil then
                viewerData[key] = BCDM:CopyTable(defaultValue)
            end
        end

        if type(viewerData.Layout) ~= "table" then
            viewerData.Layout = BCDM:CopyTable(defaultViewer.Layout)
        else
            viewerData.Layout[1] = viewerData.Layout[1] or defaultViewer.Layout[1]
            viewerData.Layout[2] = viewerData.Layout[2] or defaultViewer.Layout[2]
            viewerData.Layout[3] = viewerData.Layout[3] or defaultViewer.Layout[3]
            viewerData.Layout[4] = tonumber(viewerData.Layout[4]) or defaultViewer.Layout[4]
            viewerData.Layout[5] = tonumber(viewerData.Layout[5]) or defaultViewer.Layout[5]
        end

        if type(viewerData.Text) ~= "table" then
            viewerData.Text = BCDM:CopyTable(defaultViewer.Text)
        else
            for key, defaultValue in pairs(defaultViewer.Text) do
                if viewerData.Text[key] == nil then
                    viewerData.Text[key] = BCDM:CopyTable(defaultValue)
                end
            end

            viewerData.Text.FontSize = tonumber(viewerData.Text.FontSize) or defaultViewer.Text.FontSize

            if type(viewerData.Text.Colour) ~= "table" then
                viewerData.Text.Colour = BCDM:CopyTable(defaultViewer.Text.Colour)
            else
                for colourIndex = 1, #defaultViewer.Text.Colour do
                    viewerData.Text.Colour[colourIndex] = tonumber(viewerData.Text.Colour[colourIndex]) or defaultViewer.Text.Colour[colourIndex]
                end
            end

            if type(viewerData.Text.Layout) ~= "table" then
                viewerData.Text.Layout = BCDM:CopyTable(defaultViewer.Text.Layout)
            else
                viewerData.Text.Layout[1] = viewerData.Text.Layout[1] or defaultViewer.Text.Layout[1]
                viewerData.Text.Layout[2] = viewerData.Text.Layout[2] or defaultViewer.Text.Layout[2]
                viewerData.Text.Layout[3] = viewerData.Text.Layout[3] or defaultViewer.Text.Layout[3]
                viewerData.Text.Layout[4] = tonumber(viewerData.Text.Layout[4]) or defaultViewer.Text.Layout[4]
                viewerData.Text.Layout[5] = tonumber(viewerData.Text.Layout[5]) or defaultViewer.Text.Layout[5]
            end
        end

        viewerData.IconSize   = tonumber(viewerData.IconSize)   or defaultViewer.IconSize
        viewerData.IconWidth  = tonumber(viewerData.IconWidth)  or defaultViewer.IconWidth
        viewerData.IconHeight = tonumber(viewerData.IconHeight) or defaultViewer.IconHeight
        viewerData.Spacing    = tonumber(viewerData.Spacing)    or defaultViewer.Spacing
        viewerData.Columns    = tonumber(viewerData.Columns)    or defaultViewer.Columns

        customRootDB.Viewers[index] = viewerData

        local id = tonumber(viewerData.ViewerID)
        id = id and math.floor(id) or nil
        if not id or id < 1 or usedIDs[id] then
            while usedIDs[nextGeneratedID] do nextGeneratedID = nextGeneratedID + 1 end
            id = nextGeneratedID
        end
        usedIDs[id]       = true
        nextGeneratedID   = math.max(nextGeneratedID, id + 1)

        viewerData.ViewerID    = id
        viewerData.Name        = viewerData.Name        or BuildCustomViewerName(id)
        viewerData.FrameName   = viewerData.FrameName   or BuildCustomViewerFrameName(id)
        viewerData.ItemsSpells = viewerData.ItemsSpells or {}
    end

    local selectedID = tonumber(BCDM.SelectedCustomViewerID) or tonumber(customRootDB.ActiveViewerID)
    if not selectedID or not usedIDs[selectedID] then
        selectedID = customRootDB.Viewers[1].ViewerID
    end
    BCDM.SelectedCustomViewerID = selectedID

    customRootDB.ActiveViewerID      = nil
    customRootDB.NextViewerID        = nil
    customRootDB.ViewerSchemaVersion = VIEWER_SCHEMA_VERSION
end

local function GetCustomViewerDB(viewerID, methodViewerID)
    local customRootDB = GetCustomRootDB()

    EnsureCustomViewerCollectionDefaults(customRootDB)

    local viewers = customRootDB.Viewers

    if viewerID == nil and methodViewerID == nil then return viewers end

    local resolvedViewerID = tonumber(methodViewerID) or tonumber(viewerID) or tonumber(BCDM.SelectedCustomViewerID)

    for _, viewerData in ipairs(viewers) do
        if viewerData.ViewerID == resolvedViewerID then
            return viewerData
        end
    end

    return viewers[1]
end


local function ResolveAnchorParent(anchorName)
    if not anchorName or anchorName == "NONE" then return UIParent end
    return (BCDM:GetEffectiveAnchorFrame(anchorName)) or _G[anchorName] or UIParent
end


local function CalculateFallbackDesaturation(startTime, duration)
    if not startTime or not duration then return 0 end
    if BCDM:IsSecretValue(startTime) or BCDM:IsSecretValue(duration) then return 0 end
    return ((startTime + duration) - GetTime()) > 0.001 and 1 or 0
end

local function UpdateSpellIconDesaturation(customIcon, spellId)
    if not customIcon or not customIcon.Icon then return end
    local desaturationCurve, gcdFilterCurve = BCDM:GetCooldownDesaturationCurves()

    local cooldownData = C_Spell.GetSpellCooldown(spellId)
    if cooldownData and cooldownData.isOnGCD then
        BCDM:SetIconDesaturation(customIcon.Icon, 0)
        return
    end

    local spellCharges  = C_Spell.GetSpellCharges(spellId)
    local currentCharges
    if spellCharges and type(spellCharges.currentCharges) == "number" and not BCDM:IsSecretValue(spellCharges.currentCharges) then
        currentCharges = spellCharges.currentCharges
    end
    if currentCharges then
        if currentCharges > 0 then
            BCDM:SetIconDesaturation(customIcon.Icon, 0)
            return
        end
        local chargeDuration = C_Spell.GetSpellChargeDuration and C_Spell.GetSpellChargeDuration(spellId)
        if chargeDuration and type(chargeDuration.EvaluateRemainingDuration) == "function" then
            BCDM:SetIconDesaturation(customIcon.Icon, (desaturationCurve and chargeDuration:EvaluateRemainingDuration(desaturationCurve, 0)) or CalculateFallbackDesaturation(spellCharges.cooldownStartTime, spellCharges.cooldownDuration))
        else
            BCDM:SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(spellCharges.cooldownStartTime, spellCharges.cooldownDuration))
        end
        return
    end

    local durationObject = C_Spell.GetSpellCooldownDuration and C_Spell.GetSpellCooldownDuration(spellId)
    if durationObject and type(durationObject.EvaluateRemainingDuration) == "function" then
        local curve = (cooldownData and cooldownData.isOnGCD) and gcdFilterCurve or desaturationCurve
        BCDM:SetIconDesaturation(customIcon.Icon, (curve and durationObject:EvaluateRemainingDuration(curve, 0)) or 0)
    else
        BCDM:SetIconDesaturation(customIcon.Icon, cooldownData and CalculateFallbackDesaturation(cooldownData.startTime, cooldownData.duration) or 0)
    end
end


local function FetchItemData(itemId)
    local itemCount = C_Item.GetItemCount(itemId)
    if itemId == 224464 or itemId == 5512 then itemCount = C_Item.GetItemCount(itemId, false, true) end
    local startTime, durationTime = C_Item.GetItemCooldown(itemId)
    return itemCount, startTime, durationTime
end

local function ShouldShowItem(customDB, itemId)
    if not customDB.HideZeroCharges then return true end
    local itemCount = select(1, FetchItemData(itemId))
    return itemCount == nil or itemCount > 0
end


local function UpdateCustomItemIcon(customIcon)
    local entryId = customIcon and customIcon.EntryID
    if not customIcon or not customIcon.Cooldown or not customIcon.Icon or not entryId then return end

    local itemCount, startTime, durationTime = FetchItemData(entryId)
    if itemCount == nil then return end

    local hasActiveCooldown = (startTime and durationTime and startTime > 0 and durationTime > 0) or false
    if C_Item.IsUsableItem(entryId) then
        local shouldRefreshCooldown = BCDM:ShouldRefreshCooldownFrame(customIcon.Cooldown, hasActiveCooldown, startTime, durationTime)
        if hasActiveCooldown and shouldRefreshCooldown then
            customIcon.Cooldown:SetCooldown(startTime, durationTime)
        elseif not hasActiveCooldown and shouldRefreshCooldown then
            customIcon.Cooldown:SetCooldown(0, 0)
        end
    end

    customIcon.Charges:SetText(itemCount > 0 and tostring(itemCount) or "")

    if BCDM:IsSecretValue(startTime) or BCDM:IsSecretValue(durationTime) then
        BCDM:SetIconDesaturation(customIcon.Icon, 0)
    elseif hasActiveCooldown then
        BCDM:SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(startTime, durationTime))
    else
        BCDM:SetIconDesaturation(customIcon.Icon, 0)
    end

    local channel = C_Item.IsUsableItem(entryId) and 1 or 0.5
    customIcon.Icon:SetVertexColor(channel, channel, channel)
    customIcon.Charges:SetAlphaFromBoolean(itemCount > 1, 1, 0)
end

local function UpdateCustomSpellIcon(customIcon)
    local entryId = customIcon and customIcon.EntryID
    if not customIcon or not customIcon.Cooldown or not entryId then return end

    local spellCharges = C_Spell.GetSpellCharges(entryId)
    if spellCharges then
        customIcon.Charges:SetText(C_Spell.GetSpellDisplayCount(entryId) or "")
        customIcon.Cooldown:SetCooldown(spellCharges.cooldownStartTime, spellCharges.cooldownDuration)
    else
        local cooldownData = C_Spell.GetSpellCooldown(entryId)
        customIcon.Cooldown:SetCooldown(cooldownData.startTime, cooldownData.duration)
        customIcon.Charges:SetText("")
    end
    UpdateSpellIconDesaturation(customIcon, entryId)
end

local function RefreshCustomViewerContainerIcons(container)
    if not container then return end
    local childCount = container:GetNumChildren()
    for i = 1, childCount do
        local customIcon = select(i, container:GetChildren())
        if customIcon and customIcon.EntryType == "item" then
            UpdateCustomItemIcon(customIcon)
        elseif customIcon and customIcon.EntryType == "spell" then
            UpdateCustomSpellIcon(customIcon)
        end
    end
end


local function FetchEquippedOnUseTrinkets()
    local equippedTrinkets = {}
    for _, slotID in ipairs(TRINKET_SLOTS) do
        local itemId = GetInventoryItemID("player", slotID)
        if itemId and BCDM:IsOnUseTrinket(itemId) then
            equippedTrinkets[#equippedTrinkets + 1] = { itemId = itemId, slotID = slotID }
        end
    end
    return equippedTrinkets
end

local POTION_CLASS_ID    = (Enum.ItemClass.Consumable)         or 0
local POTION_SUBCLASS_ID = (Enum.ItemConsumableSubclass.Potion) or 1

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

local function BuildProfessionAtlasFromRank(itemId, rank)
    if not rank or rank <= 0 then return end
    local expansionID = select(15, C_Item.GetItemInfo(itemId))
    return expansionID == 11
        and ("Professions-Icon-Quality-12-Tier" .. rank .. "-Small")
        or  ("Professions-Icon-Quality-Tier"    .. rank .. "-Small")
end

local function FetchPotionProfessionRank(itemId)
    if not itemId then return 0 end
    local _, itemLink = C_Item.GetItemInfo(itemId)
    local atlasName   = ParseProfessionAtlasFromItemLink(itemLink)
    local parsedRank  = atlasName and tonumber(string.match(atlasName, "Tier(%d+)"))
    if parsedRank then return parsedRank end

    local itemInfo = itemLink or itemId

    if C_TradeSkillUI.GetItemCraftedQualityByItemInfo then
        local rank = C_TradeSkillUI.GetItemCraftedQualityByItemInfo(itemInfo) or (itemInfo ~= itemId and C_TradeSkillUI.GetItemCraftedQualityByItemInfo(itemId))
        if rank then return rank end
    end

    if C_TradeSkillUI.GetItemReagentQualityByItemInfo then
        local rank = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemInfo) or (itemInfo ~= itemId and C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemId))
        if rank then return rank end
    end
    return
end

local function ResolveItemQualityAtlas(itemId)
    if not itemId then return end
    local _, itemLink    = C_Item.GetItemInfo(itemId)
    local atlasFromLink  = ParseProfessionAtlasFromItemLink(itemLink)
    if atlasFromLink then return atlasFromLink end
    return BuildProfessionAtlasFromRank(itemId, FetchPotionProfessionRank(itemId))
end

local function SelectPotionRankCandidate(potionGroups, itemId, layoutIndex)
    if not IsPotionItem(itemId) then return end

    local itemName = C_Item.GetItemInfo(itemId)
    if not itemName then return end

    local itemCount = select(1, FetchItemData(itemId)) or 0
    local group     = potionGroups[itemName]
    if not group then
        group = { index = layoutIndex, selected = nil }
        potionGroups[itemName] = group
    else
        group.index = math.min(group.index or layoutIndex, layoutIndex)
    end

    local candidate = { id = itemId, count = itemCount, rank = FetchPotionProfessionRank(itemId) }
    local selected  = group.selected

    if not selected then
        group.selected = candidate
        return true
    end

    local candidateAvailable = candidate.count > 0
    local selectedAvailable  = selected.count  > 0

    if candidateAvailable ~= selectedAvailable then
        if candidateAvailable then group.selected = candidate end
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
    local normalizedValue         = tostring(value):upper()
    local classToken, specToken   = string.match(normalizedValue, "^(%u+):([%u%d_]+)$")
    if not classToken or not specToken then return end
    return classToken, (BCDM:NormalizeSpecToken(specToken) or specToken)
end

local function IsEntryEnabledForPlayerSpec(entryData, playerClass, playerSpecialization)
    local classSpecFilters  = entryData and entryData.classSpecFilters
    if type(classSpecFilters) ~= "table" then return true end

    local hasActiveFilter      = false
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


local function AcquireIconFrame()
    if not customIconPool then
        customIconPool = CreateFramePool("Button", UIParent, "BackdropTemplate", function(pool, iconFrame)
            iconFrame:UnregisterAllEvents()
            iconFrame:SetScript("OnEvent", nil)
            iconFrame.EntryID   = nil
            iconFrame.EntryType = nil
            iconFrame:Hide()
            iconFrame:ClearAllPoints()
            if iconFrame.Cooldown then iconFrame.Cooldown:SetCooldown(0, 0) end
        end)
    end

    local customIcon = customIconPool:Acquire()
    if not customIcon.Cooldown then
        local HighLevelContainer = CreateFrame("Frame", nil, customIcon)
        HighLevelContainer:SetAllPoints(customIcon)
        HighLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

        customIcon.Charges      = HighLevelContainer:CreateFontString(nil, "OVERLAY")

        customIcon.Cooldown     = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
        customIcon.Cooldown:SetAllPoints(customIcon)
        customIcon.Cooldown:SetDrawEdge(false)
        customIcon.Cooldown:SetDrawSwipe(true)
        customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
        customIcon.Cooldown:SetHideCountdownNumbers(false)
        customIcon.Cooldown:SetReverse(false)

        customIcon.QualityAtlas = HighLevelContainer:CreateTexture(nil, "OVERLAY")
        customIcon.Icon         = customIcon:CreateTexture(nil, "BACKGROUND")
    end
    return customIcon
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

    local iconSize  = math.min(iconWidth or customIcon:GetWidth() or 0, iconHeight or customIcon:GetHeight() or 0)
    local atlasSize = math.max(10, math.floor(iconSize * 0.42))
    customIcon.QualityAtlas:ClearAllPoints()
    customIcon.QualityAtlas:SetPoint("TOPLEFT", customIcon, "TOPLEFT", 0, 0)
    customIcon.QualityAtlas:SetSize(atlasSize, atlasSize)
    customIcon.QualityAtlas:SetAtlas(atlasName)
    customIcon.QualityAtlas:Show()
end


local function CreateCustomIcon(entryId, entryType, customDB)
    local profileDB      = BCDM.db.profile
    local generalDB      = profileDB.General
    local viewerDB       = customDB or GetCustomViewerDB()
    if not entryId then return end

    local isItem = entryType == "item"
    if isItem then
        if not C_Item.GetItemInfo(entryId) then return end
    else
        if not C_SpellBook.IsSpellInSpellBook(entryId) then return end
    end

    local customIcon    = AcquireIconFrame()
    local borderSize    = profileDB.CooldownManager.General.BorderSize
    local iconWidth, iconHeight = BCDM:GetIconDimensions(viewerDB)
    local iconZoom      = profileDB.CooldownManager.General.IconZoom * 0.5

    customIcon:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = borderSize,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    customIcon:SetBackdropBorderColor(0, 0, 0, borderSize > 0 and 1 or 0)
    customIcon:SetSize(iconWidth, iconHeight)
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(viewerDB.FrameStrata or "LOW")
    customIcon.EntryID   = entryId
    customIcon.EntryType = entryType
    customIcon.Cooldown:SetDrawBling(false)

    customIcon.Charges:ClearAllPoints()
    customIcon.Charges:SetFont(BCDM.Media.Font, viewerDB.Text.FontSize, generalDB.Fonts.FontFlag)
    customIcon.Charges:SetPoint(
        viewerDB.Text.Layout[1],
        customIcon,
        viewerDB.Text.Layout[2],
        viewerDB.Text.Layout[3],
        viewerDB.Text.Layout[4]
    )
    customIcon.Charges:SetTextColor(
        viewerDB.Text.Colour[1],
        viewerDB.Text.Colour[2],
        viewerDB.Text.Colour[3],
        1
    )
    if isItem then
        customIcon.Charges:SetText(tostring(select(1, FetchItemData(entryId)) or ""))
    end

    if generalDB.Fonts.Shadow.Enabled then
        customIcon.Charges:SetShadowColor(
            generalDB.Fonts.Shadow.Colour[1],
            generalDB.Fonts.Shadow.Colour[2],
            generalDB.Fonts.Shadow.Colour[3],
            generalDB.Fonts.Shadow.Colour[4]
        )
        customIcon.Charges:SetShadowOffset(
            generalDB.Fonts.Shadow.OffsetX,
            generalDB.Fonts.Shadow.OffsetY
        )
    else
        customIcon.Charges:SetShadowColor(0, 0, 0, 0)
        customIcon.Charges:SetShadowOffset(0, 0)
    end

    customIcon.QualityAtlas:Hide()
    if isItem then
        ApplyItemQualityAtlas(customIcon, entryId, viewerDB, iconWidth, iconHeight)
    end

    customIcon.Icon:ClearAllPoints()
    customIcon.Icon:SetPoint("TOPLEFT",     customIcon, "TOPLEFT",     borderSize,  -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize,  borderSize)
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)

    if isItem then
        customIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(entryId)))
        UpdateCustomItemIcon(customIcon)
    else
        customIcon.Icon:SetTexture(C_Spell.GetSpellInfo(entryId).iconID)
        UpdateCustomSpellIcon(customIcon)
    end

    return customIcon
end


local function ResolveItemSpellEntryType(entryId, entryData)
    if entryData and entryData.entryType then return entryData.entryType end
    if C_Item.GetItemInfo(entryId)   then return "item"  end
    if C_Spell.GetSpellInfo(entryId) then return "spell" end
end

local function HasTrackedPotionEntries(items)
    if not items then return false end
    for entryId, data in pairs(items) do
        if data and data.isActive and ResolveItemSpellEntryType(entryId, data) == "item" and IsPotionItem(entryId) then
            return true
        end
    end
    return false
end

local function HasTrackedItemEntries(items)
    if not items then return false end
    for entryId, data in pairs(items) do
        if data and data.isActive and ResolveItemSpellEntryType(entryId, data) == "item" then
            return true
        end
    end
    return false
end

local function HasTrackedSpellEntries(items)
    if not items then return false end
    for entryId, data in pairs(items) do
        if data and data.isActive and ResolveItemSpellEntryType(entryId, data) == "spell" then
            return true
        end
    end
    return false
end


local function CreateCustomIcons(iconTable, visibleItemIds, customDB)
    local viewerDB             = customDB or GetCustomViewerDB()
    local items                = viewerDB.ItemsSpells
    local playerClass          = select(2, UnitClass("player"))
    local specIndex            = GetSpecialization()
    local specID, specName     = specIndex and GetSpecializationInfo(specIndex)
    local playerSpecialization = BCDM:NormalizeSpecToken(specName, specID, specIndex)

    wipe(iconTable)
    if visibleItemIds then wipe(visibleItemIds) end

    local sortedEntries = {}
    local potionGroups  = {}
    local addedItemIds  = {}

    if items then
        for entryId, data in pairs(items) do
            if data.isActive and IsEntryEnabledForPlayerSpec(data, playerClass, playerSpecialization) then
                local entryType = ResolveItemSpellEntryType(entryId, data)
                if entryType == "item" then
                    local layoutIndex   = data.layoutIndex or math.huge
                    local isPotionEntry = SelectPotionRankCandidate(potionGroups, entryId, layoutIndex)
                    if isPotionEntry or not ShouldShowItem(viewerDB, entryId) then
                        entryType = nil
                    end
                end
                if entryType then
                    sortedEntries[#sortedEntries + 1] = {
                        id = entryId,
                        index = data.layoutIndex or math.huge,
                        entryType = entryType,
                    }
                end
            end
        end
    end

    for _, potionGroup in pairs(potionGroups) do
        local selected = potionGroup.selected
        if selected and selected.count > 0 then
            sortedEntries[#sortedEntries + 1] = {
                id = selected.id,
                index = potionGroup.index or math.huge,
                entryType = "item",
            }
        end
    end

    table.sort(sortedEntries, function(a, b)
        return a.index == b.index and tostring(a.id) < tostring(b.id) or a.index < b.index
    end)

    for _, entry in ipairs(sortedEntries) do
        local customItem = CreateCustomIcon(entry.id, entry.entryType, viewerDB)
        if customItem then
            iconTable[#iconTable + 1] = customItem
            if entry.entryType == "item" then
                addedItemIds[entry.id] = true
                if visibleItemIds then visibleItemIds[entry.id] = true end
            end
        end
    end

    if not viewerDB.AutoDetectUsableTrinkets then return end

    for _, trinketEntry in ipairs(FetchEquippedOnUseTrinkets()) do
        if not addedItemIds[trinketEntry.itemId] then
            local customItem = CreateCustomIcon(trinketEntry.itemId, "item", viewerDB)
            if customItem then
                iconTable[#iconTable + 1] = customItem
                addedItemIds[trinketEntry.itemId] = true
                if visibleItemIds then
                    visibleItemIds[trinketEntry.itemId] = true
                end
            end
        end
    end
end


local function RequestDeferredContainerUpdate(container)
    if not container or container.PendingRefresh then return end
    container.PendingRefresh = true
    C_Timer.After(0, function()
        container.PendingRefresh = false
        if BCDM.UpdateCustomViewer then BCDM:UpdateCustomViewer() end
    end)
end

local function HandleCustomViewerContainerEvent(self, event, itemId)
    local customDB = self.CustomViewerDB or GetCustomViewerDB(self.ViewerID)
    if not customDB then return end
    local items = customDB and customDB.ItemsSpells

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if itemId == 13 or itemId == 14 then RequestDeferredContainerUpdate(self) end
        return
    end

    if event == "SPELL_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" or event == "PLAYER_ENTERING_WORLD" then
        RefreshCustomViewerContainerIcons(self)
        return
    end

    if event == "BAG_UPDATE_DELAYED" then
        RequestDeferredContainerUpdate(self)
        return
    end

    if not items then return end

    if event == "ITEM_COUNT_CHANGED" or event == "ITEM_PUSH" then
        if not itemId then
            RequestDeferredContainerUpdate(self)
            return
        end

        local entry = items[itemId]
        if not (entry and entry.isActive) then
            if self.AutoDetectUsableTrinkets and (itemId == GetInventoryItemID("player", 13) or itemId == GetInventoryItemID("player", 14)) then
                RequestDeferredContainerUpdate(self)
            end
            return
        end

        if ResolveItemSpellEntryType(itemId, entry) ~= "item" then return end

        if IsPotionItem(itemId) or self.HasPotionEntries then
            RequestDeferredContainerUpdate(self)
            return
        end

        if not customDB.HideZeroCharges then
            RefreshCustomViewerContainerIcons(self)
            return
        end

        local visible    = self.VisibleItemIds and self.VisibleItemIds[itemId] or false
        local shouldShow = ShouldShowItem(customDB, itemId)
        if visible ~= shouldShow then
            RequestDeferredContainerUpdate(self)
        else
            RefreshCustomViewerContainerIcons(self)
        end
    end
end

local function AcquireCustomViewerContainer(viewerData)
    BCDM.CustomViewerContainers = BCDM.CustomViewerContainers or {}
    local frameName = viewerData.FrameName or BuildCustomViewerFrameName(viewerData.ViewerID)
    local container = BCDM.CustomViewerContainers[frameName]
    if not container then
        container = _G[frameName] or CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
        container:SetSize(1, 1)
        container:SetScript("OnEvent", HandleCustomViewerContainerEvent)
        BCDM.CustomViewerContainers[frameName] = container
    end
    container.ViewerID      = viewerData.ViewerID
    container.CustomViewerDB = viewerData
    return container
end

local function UpdateCustomViewerContainerEvents(container, customDB)
    local hasTrackedItems   = HasTrackedItemEntries(customDB.ItemsSpells) or customDB.AutoDetectUsableTrinkets
    local hasPotionEntries  = HasTrackedPotionEntries(customDB.ItemsSpells)
    local hasTrackedSpells  = HasTrackedSpellEntries(customDB.ItemsSpells)

    container.HasPotionEntries       = hasPotionEntries
    container.AutoDetectUsableTrinkets = customDB.AutoDetectUsableTrinkets

    local function setEvent(event, condition)
        if condition then container:RegisterEvent(event) else container:UnregisterEvent(event) end
    end

    setEvent("ITEM_COUNT_CHANGED",      hasTrackedItems)
    setEvent("ITEM_PUSH",               hasTrackedItems)
    setEvent("BAG_UPDATE_DELAYED",      customDB.HideZeroCharges or hasPotionEntries or customDB.AutoDetectUsableTrinkets)
    setEvent("PLAYER_EQUIPMENT_CHANGED", customDB.AutoDetectUsableTrinkets)
    setEvent("SPELL_UPDATE_COOLDOWN",   hasTrackedItems or hasTrackedSpells)
    setEvent("SPELL_UPDATE_CHARGES",    hasTrackedSpells)
    setEvent("PLAYER_ENTERING_WORLD",   hasTrackedItems or customDB.AutoDetectUsableTrinkets or hasTrackedSpells)
end


local function LayoutCustomViewerContainer(container, customDB)
    local customViewerIcons = {}
    local visibleItemIds    = {}
    local growthDirection   = customDB.GrowthDirection or "RIGHT"

    local containerAnchorFrom = customDB.Layout[1]
    if growthDirection == "UP" then
        local verticalFlipMap = {
            TOPLEFT = "BOTTOMLEFT", TOP = "BOTTOM", TOPRIGHT = "BOTTOMRIGHT",
            BOTTOMLEFT = "TOPLEFT", BOTTOM = "TOP", BOTTOMRIGHT = "TOPRIGHT",
        }
        containerAnchorFrom = verticalFlipMap[customDB.Layout[1]] or customDB.Layout[1]
    end

    container:ClearAllPoints()
    container:SetFrameStrata(customDB.FrameStrata or "LOW")
    container:SetPoint(containerAnchorFrom, ResolveAnchorParent(customDB.Layout[2]), customDB.Layout[3], customDB.Layout[4], customDB.Layout[5])

    UpdateCustomViewerContainerEvents(container, customDB)
    CreateCustomIcons(customViewerIcons, visibleItemIds, customDB)
    container.VisibleItemIds = visibleItemIds

    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
    local iconSpacing           = customDB.Spacing
    local point                 = select(1, container:GetPoint(1))
    local isHorizontalGrowth    = growthDirection == "LEFT" or growthDirection == "RIGHT"
    local wrapLimit             = math.max(0, math.floor(tonumber(customDB.Columns) or 0))
    local lineLimit             = wrapLimit > 0 and wrapLimit or #customViewerIcons
    local useCenteredLayout     = (point == "TOP" or point == "BOTTOM") and isHorizontalGrowth
    local growsUp               = point and point:find("BOTTOM") ~= nil
    local growsLeft             = point and point:find("RIGHT")  ~= nil

    if #customViewerIcons == 0 then
        container:SetSize(1, 1)
        container:Show()
        return
    end

    local lineCount = math.ceil(#customViewerIcons / lineLimit)
    if isHorizontalGrowth then
        local cols = math.min(lineLimit, #customViewerIcons)
        container:SetWidth( (cols      * iconWidth)  + ((cols - 1)      * iconSpacing))
        container:SetHeight((lineCount * iconHeight) + ((lineCount - 1) * iconSpacing))
    else
        local rows = math.min(lineLimit, #customViewerIcons)
        container:SetWidth( (lineCount * iconWidth)  + ((lineCount - 1) * iconSpacing))
        container:SetHeight((rows      * iconHeight) + ((rows - 1)      * iconSpacing))
    end

    if useCenteredLayout then
        local rowDirection = growsUp and 1 or -1
        for rowIndex = 1, math.ceil(#customViewerIcons / lineLimit) do
            local rowStart   = (rowIndex - 1) * lineLimit + 1
            local rowEnd     = math.min(rowStart + lineLimit - 1, #customViewerIcons)
            local rowIcons   = rowEnd - rowStart + 1
            local rowWidth   = rowIcons * iconWidth + (rowIcons - 1) * iconSpacing
            local startOffset = -(rowWidth / 2) + (iconWidth / 2)
            local yOffset     = (rowIndex - 1) * (iconHeight + iconSpacing) * rowDirection

            for i = rowStart, rowEnd do
                local icon = customViewerIcons[i]
                icon:SetParent(container)
                icon:SetSize(iconWidth, iconHeight)
                icon:ClearAllPoints()
                icon:SetPoint(
                    "CENTER",
                    container,
                    "CENTER",
                    startOffset + (i - rowStart) * (iconWidth + iconSpacing),
                    yOffset
                )
                icon:Show()
            end
        end
    else
        local anchorMap = {
            TOPLEFT = "TOPLEFT", TOP = "TOP", TOPRIGHT = "TOPRIGHT",
            BOTTOMLEFT = "BOTTOMLEFT", BOTTOM = "BOTTOM", BOTTOMRIGHT = "BOTTOMRIGHT",
            LEFT = "LEFT", RIGHT = "RIGHT", CENTER = "CENTER",
        }

        for i, icon in ipairs(customViewerIcons) do
            icon:SetParent(container)
            icon:SetSize(iconWidth, iconHeight)
            icon:ClearAllPoints()

            if i == 1 then
                local anchor = anchorMap[point] or "TOPLEFT"
                icon:SetPoint(anchor, container, anchor, 0, 0)
            elseif (i - 1) % lineLimit == 0 then
                local lineAnchorIcon = customViewerIcons[i - lineLimit]
                if isHorizontalGrowth then
                    icon:SetPoint(
                        growsUp and "BOTTOM" or "TOP",
                        lineAnchorIcon,
                        growsUp and "TOP" or "BOTTOM",
                        0,
                        growsUp and iconSpacing or -iconSpacing
                    )
                else
                    icon:SetPoint(
                        growsLeft and "RIGHT" or "LEFT",
                        lineAnchorIcon,
                        growsLeft and "LEFT" or "RIGHT",
                        growsLeft and -iconSpacing or iconSpacing,
                        0
                    )
                end
            else
                local previousIcon = customViewerIcons[i - 1]
                if growthDirection == "RIGHT" then
                    icon:SetPoint("LEFT", previousIcon, "RIGHT", iconSpacing, 0)
                elseif growthDirection == "LEFT" then
                    icon:SetPoint("RIGHT", previousIcon, "LEFT", -iconSpacing, 0)
                elseif growthDirection == "UP" then
                    icon:SetPoint("BOTTOM", previousIcon, "TOP", 0, iconSpacing)
                elseif growthDirection == "DOWN" then
                    icon:SetPoint("TOP", previousIcon, "BOTTOM", 0, -iconSpacing)
                end
            end
            icon:Show()
        end
    end

    BCDM:ApplyCooldownText(container)
    RefreshCustomViewerContainerIcons(container)
    container:Show()
end

local function HideUnusedCustomViewerContainers(activeFrameNames)
    if not BCDM.CustomViewerContainers then return end
    for frameName, container in pairs(BCDM.CustomViewerContainers) do
        if not activeFrameNames[frameName] then
            container:UnregisterEvent("ITEM_COUNT_CHANGED")
            container:UnregisterEvent("ITEM_PUSH")
            container:UnregisterEvent("BAG_UPDATE_DELAYED")
            container:UnregisterEvent("PLAYER_ENTERING_WORLD")
            container:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
            container:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
            container:UnregisterEvent("SPELL_UPDATE_CHARGES")
            container.VisibleItemIds = nil
            container:Hide()
        end
    end
end


local function RefreshCustomViewerAnchors()
    if not BCDM.AnchorParents then return end
    BCDM.DynamicCustomViewerAnchors = BCDM.DynamicCustomViewerAnchors or {}

    for _, anchorType in ipairs({ "CustomViewer", "Trinket" }) do
        local anchorData = BCDM.AnchorParents[anchorType]
        if anchorData then
            local displayNames, keyList = anchorData[1], anchorData[2]
            for anchorKey in pairs(BCDM.DynamicCustomViewerAnchors) do
                displayNames[anchorKey] = nil
                for index = #keyList, 1, -1 do
                    if keyList[index] == anchorKey then table.remove(keyList, index) end
                end
            end
        end
    end

    wipe(BCDM.DynamicCustomViewerAnchors)

    for _, viewerData in ipairs(GetCustomViewerDB()) do
        local frameName = viewerData.FrameName
        if frameName then
            BCDM.DynamicCustomViewerAnchors[frameName] = true
            local displayName = "|cFF8080FFBCDM|r: " .. (viewerData.Name or BuildCustomViewerName(viewerData.ViewerID))
            for _, anchorType in ipairs({ "CustomViewer", "Trinket" }) do
                local anchorData = BCDM.AnchorParents[anchorType]
                if anchorData then
                    local displayNames, keyList = anchorData[1], anchorData[2]
                    displayNames[frameName] = displayName
                    if not tContains(keyList, frameName) then keyList[#keyList + 1] = frameName end
                end
            end
        end
    end
end


local function LayoutCustomViewer()
    local viewers          = GetCustomViewerDB()
    local activeFrameNames = {}

    if customIconPool then customIconPool:ReleaseAll() end
    BCDM.CustomViewerContainer = nil

    for _, viewerData in ipairs(viewers) do
        local container = AcquireCustomViewerContainer(viewerData)
        activeFrameNames[viewerData.FrameName] = true

        if not BCDM.CustomViewerContainer or viewerData.FrameName == VIEWER_FRAME_NAME then
            BCDM.CustomViewerContainer = container
        end

        LayoutCustomViewerContainer(container, viewerData)
    end

    HideUnusedCustomViewerContainers(activeFrameNames)
    RefreshCustomViewerAnchors()
end

BCDM.SetupCustomViewer = LayoutCustomViewer
BCDM.UpdateCustomViewer = LayoutCustomViewer


local function ReindexCustomViewerEntries(viewerID, methodViewerID)
    local viewerDB = GetCustomViewerDB(viewerID, methodViewerID)
    local items    = viewerDB.ItemsSpells
    if not items then return end

    local ordered = {}
    for itemId, data in pairs(items) do
        ordered[#ordered + 1] = { itemId = itemId, data = data, sortIndex = data.layoutIndex or math.huge }
    end

    table.sort(ordered, function(a, b)
        return a.sortIndex == b.sortIndex and tostring(a.itemId) < tostring(b.itemId) or a.sortIndex < b.sortIndex
    end)

    for index, entry in ipairs(ordered) do
        entry.data.layoutIndex = index
    end
end


function BCDM:AdjustCustomViewerLayoutIndex(direction, itemId, viewerID)
    local viewerDB = GetCustomViewerDB(viewerID)
    local items    = viewerDB.ItemsSpells
    if not items or not items[itemId] then return end

    local currentIndex = items[itemId].layoutIndex
    local newIndex     = currentIndex + direction
    local totalItems   = 0
    for _ in pairs(items) do totalItems = totalItems + 1 end
    if newIndex < 1 or newIndex > totalItems then return end

    for _, data in pairs(items) do
        if data.layoutIndex == newIndex then
            data.layoutIndex = currentIndex
            break
        end
    end

    items[itemId].layoutIndex = newIndex
    ReindexCustomViewerEntries(viewerID)
    LayoutCustomViewer()
end

function BCDM:AdjustCustomViewerList(itemId, adjustingHow, entryType, viewerID)
    local viewerDB = GetCustomViewerDB(viewerID)
    local items    = viewerDB.ItemsSpells
    if not items then
        items = {}
        viewerDB.ItemsSpells = items
    end

    if adjustingHow == "add" then
        local maxIndex = 0
        for _, data in pairs(items) do
            if data.layoutIndex > maxIndex then maxIndex = data.layoutIndex end
        end

        local resolvedType = entryType or ResolveItemSpellEntryType(itemId)
        local playerClass  = select(2, UnitClass("player"))
        local filterClass  = resolvedType == "spell" and playerClass or nil
        items[itemId] = {
            isActive         = true,
            layoutIndex      = maxIndex + 1,
            entryType        = resolvedType,
            classSpecFilters = BCDM:BuildClassSpecFilters(filterClass),
            filterClass      = filterClass,
        }
    elseif adjustingHow == "remove" then
        items[itemId] = nil
    end

    ReindexCustomViewerEntries(viewerID)
    LayoutCustomViewer()
end


local function MergeLegacyEntry(targetEntries, entryId, entryData)
    if not entryData then return end
    local existing = targetEntries[entryId]
    if not existing then
        targetEntries[entryId] = entryData
        return
    end
    existing.isActive   = existing.isActive   or entryData.isActive
    existing.entryType  = existing.entryType  or entryData.entryType
    existing.filterClass = existing.filterClass or entryData.filterClass
    if (entryData.layoutIndex or math.huge) < (existing.layoutIndex or math.huge) then
        existing.layoutIndex = entryData.layoutIndex
    end
    if type(entryData.classSpecFilters) == "table" then
        existing.classSpecFilters = existing.classSpecFilters or {}
        for classSpecValue, isEnabled in pairs(entryData.classSpecFilters) do
            if isEnabled then existing.classSpecFilters[classSpecValue] = true end
        end
    end
end

local function ImportLegacyItemEntries(targetEntries, sourceEntries)
    if type(sourceEntries) ~= "table" then return end
    for entryId, data in pairs(sourceEntries) do
        local resolvedType = data.entryType or ResolveItemSpellEntryType(entryId, data)
        if resolvedType then
            MergeLegacyEntry(targetEntries, entryId, {
                isActive         = data.isActive ~= false,
                layoutIndex      = data.layoutIndex or math.huge,
                entryType        = resolvedType,
                classSpecFilters = BCDM:CopyTable(data.classSpecFilters),
                filterClass      = data.filterClass,
            })
        end
    end
end

local function ImportLegacySpellEntries(targetEntries, sourceEntries)
    if type(sourceEntries) ~= "table" then return end
    for classToken, specs in pairs(sourceEntries) do
        for specToken, spells in pairs(specs) do
            local normalizedSpec  = BCDM:NormalizeSpecToken(specToken) or specToken
            local classSpecValue  = classToken .. ":" .. normalizedSpec
            for spellId, data in pairs(spells) do
                MergeLegacyEntry(targetEntries, spellId, {
                    isActive         = data.isActive ~= false,
                    layoutIndex      = data.layoutIndex or math.huge,
                    entryType        = "spell",
                    classSpecFilters = { [classSpecValue] = true },
                    filterClass      = classToken,
                })
            end
        end
    end
end

local function CopyCustomViewerSettings(targetDB, sourceDB)
    if type(targetDB) ~= "table" or type(sourceDB) ~= "table" then return end
    for _, settingKey in ipairs(CUSTOM_VIEWER_SETTING_KEYS) do
        if sourceDB[settingKey] ~= nil then
            targetDB[settingKey] = BCDM:CopyTable(sourceDB[settingKey])
        end
    end
end

function BCDM:GetCustomViewerEntries(viewerID)
    if viewerID == nil then
        return GetCustomViewerDB()
    end
    return GetCustomViewerDB(viewerID)
end

function BCDM:GetSelectedCustomViewerDB(viewerID)
    return GetCustomViewerDB(viewerID or self.SelectedCustomViewerID)
end

function BCDM:SetActiveCustomViewer(viewerID)
    local selectedViewer = GetCustomViewerDB(viewerID)
    if not selectedViewer then return end
    self.SelectedCustomViewerID = selectedViewer.ViewerID
    RefreshCustomViewerAnchors()
end

function BCDM:RenameCustomViewer(viewerID, viewerName)
    local viewerData = GetCustomViewerDB(viewerID)
    if not viewerData then return end
    local normalizedName = type(viewerName) == "string" and strtrim(viewerName) or nil
    viewerData.Name = (normalizedName and normalizedName ~= "") and normalizedName or BuildCustomViewerName(viewerData.ViewerID)
    RefreshCustomViewerAnchors()
end

function BCDM:AddCustomViewer()
    local viewers       = GetCustomViewerDB()
    local usedIDs       = {}
    local nextViewerID  = 2
    local newViewer     = self:CopyTable(GetDefaultCustomViewerDB())

    for _, viewerData in ipairs(viewers) do
        local id = tonumber(viewerData and viewerData.ViewerID)
        id = id and math.floor(id) or nil
        if id and id >= 1 then
            usedIDs[id] = true
        end
    end
    while usedIDs[nextViewerID] do
        nextViewerID = nextViewerID + 1
    end

    newViewer.ViewerID   = nextViewerID
    newViewer.Name       = BuildCustomViewerName(nextViewerID)
    newViewer.FrameName  = BuildCustomViewerFrameName(nextViewerID)

    viewers[#viewers + 1] = newViewer
    EnsureCustomViewerCollectionDefaults(GetCustomRootDB())
    self.SelectedCustomViewerID = nextViewerID
    RefreshCustomViewerAnchors()
    LayoutCustomViewer()
    return newViewer
end

function BCDM:RemoveCustomViewer(viewerID)
    local customRootDB = GetCustomRootDB()
    local viewers      = GetCustomViewerDB()
    if #viewers <= 1 then return false end

    local wasSelected, removeIndex, removeData
    for index, viewerData in ipairs(viewers) do
        if viewerData.ViewerID == viewerID then
            wasSelected  = tonumber(self.SelectedCustomViewerID) == viewerID
            removeIndex  = index
            removeData   = viewerData
            break
        end
    end

    if not removeIndex then return false end
    table.remove(viewers, removeIndex)

    local removedContainer = removeData and removeData.FrameName
        and BCDM.CustomViewerContainers and BCDM.CustomViewerContainers[removeData.FrameName]
    if removedContainer then
        removedContainer:UnregisterEvent("ITEM_COUNT_CHANGED")
        removedContainer:UnregisterEvent("ITEM_PUSH")
        removedContainer:UnregisterEvent("BAG_UPDATE_DELAYED")
        removedContainer:UnregisterEvent("PLAYER_ENTERING_WORLD")
        removedContainer:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
        removedContainer:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
        removedContainer:UnregisterEvent("SPELL_UPDATE_CHARGES")
        removedContainer:Hide()
    end

    local fallbackViewer = viewers[math.max(1, removeIndex - 1)] or viewers[1]
    EnsureCustomViewerCollectionDefaults(customRootDB)
    if wasSelected and fallbackViewer then
        self.SelectedCustomViewerID = fallbackViewer.ViewerID
    end

    RefreshCustomViewerAnchors()
    LayoutCustomViewer()
    return true
end


function BCDM:MigrateCustomViewerData()
    local cooldownManagerDB = self.db and self.db.profile and self.db.profile.CooldownManager
    if not cooldownManagerDB then return end

    if not cooldownManagerDB[VIEWER_KEY] then
        cooldownManagerDB[VIEWER_KEY] = self:CopyTable(self:GetDefaultDB().profile.CooldownManager[VIEWER_KEY])
    end

    local customDB = cooldownManagerDB[VIEWER_KEY]

    if customDB.ViewerSchemaVersion ~= VIEWER_SCHEMA_VERSION or type(customDB.Viewers) ~= "table" or #customDB.Viewers == 0 then
        local primaryViewer = self:CopyTable(GetDefaultCustomViewerDB())
        CopyCustomViewerSettings(primaryViewer, customDB)
        if customDB.ItemsSpells ~= nil then
            primaryViewer.ItemsSpells = self:CopyTable(customDB.ItemsSpells)
        end
        customDB.Viewers = { primaryViewer }
    end

    EnsureCustomViewerCollectionDefaults(customDB)
    local primaryViewer = GetCustomViewerDB(customDB.Viewers[1].ViewerID)

    if customDB.LegacyMigrationVersion ~= LEGACY_MIGRATION_VERSION then
        local settingsSource =
            cooldownManagerDB.ItemSpell
            or cooldownManagerDB.Item
            or cooldownManagerDB.Custom
            or cooldownManagerDB.AdditionalCustom
        if settingsSource then CopyCustomViewerSettings(primaryViewer, settingsSource) end

        if primaryViewer.Layout and primaryViewer.Layout[2] and primaryViewer.Layout[2] ~= "NONE" then
            local removedAnchors = {
                BCDM_CustomCooldownViewer = true, BCDM_AdditionalCustomCooldownViewer = true,
                BCDM_CustomItemBar = true, BCDM_CustomItemSpellBar = true,
            }
            if removedAnchors[primaryViewer.Layout[2]] then primaryViewer.Layout[2] = "NONE" end
        end

        primaryViewer.ItemsSpells = primaryViewer.ItemsSpells or {}
        if next(primaryViewer.ItemsSpells) == nil then
            ImportLegacyItemEntries(
                primaryViewer.ItemsSpells,
                cooldownManagerDB.ItemSpell and cooldownManagerDB.ItemSpell.ItemsSpells
            )
            ImportLegacyItemEntries(
                primaryViewer.ItemsSpells,
                cooldownManagerDB.Item and cooldownManagerDB.Item.Items
            )
            ImportLegacySpellEntries(
                primaryViewer.ItemsSpells,
                cooldownManagerDB.Custom and cooldownManagerDB.Custom.Spells
            )
            ImportLegacySpellEntries(
                primaryViewer.ItemsSpells,
                cooldownManagerDB.AdditionalCustom and cooldownManagerDB.AdditionalCustom.Spells
            )
            ReindexCustomViewerEntries(primaryViewer.ViewerID)
        end

        customDB.LegacyMigrationVersion = LEGACY_MIGRATION_VERSION
    end

    EnsureCustomViewerCollectionDefaults(customDB)
    RefreshCustomViewerAnchors()
end

BCDM.SetupCustomItemsSpellsBar         = LayoutCustomViewer
BCDM.UpdateCustomItemsSpellsBar        = LayoutCustomViewer
BCDM.AdjustItemsSpellsLayoutIndex      = BCDM.AdjustCustomViewerLayoutIndex
BCDM.NormalizeItemsSpellsLayoutIndices = ReindexCustomViewerEntries
BCDM.AdjustItemsSpellsList             = BCDM.AdjustCustomViewerList

BCDM.SetupCustomCooldownViewer         = LayoutCustomViewer
BCDM.UpdateCustomCooldownViewer        = LayoutCustomViewer
BCDM.SetupAdditionalCustomCooldownViewer  = LayoutCustomViewer
BCDM.UpdateAdditionalCustomCooldownViewer = LayoutCustomViewer
BCDM.SetupCustomItemBar                = LayoutCustomViewer
BCDM.UpdateCustomItemBar               = LayoutCustomViewer
BCDM.AdjustItemLayoutIndex             = BCDM.AdjustCustomViewerLayoutIndex
BCDM.NormalizeItemLayoutIndices        = ReindexCustomViewerEntries
BCDM.AdjustItemList                    = BCDM.AdjustCustomViewerList
