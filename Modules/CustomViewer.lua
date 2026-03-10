local _, BCDM = ...

local customIconPool
local VIEWER_KEY = "CustomViewer"
local VIEWER_FRAME_NAME = "BCDM_CustomViewer"
local LEGACY_MIGRATION_VERSION = 1
local VIEWER_SCHEMA_VERSION = 1
local TRINKET_SLOTS = { 13, 14 }
local LayoutCustomViewer
local NormalizeCustomViewerLayoutIndices
local RefreshCustomViewerAnchors
local CUSTOM_VIEWER_SETTING_KEYS = {
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
    "ShowItemQualityBorder",
    "AutoDetectUsableTrinkets",
    "Text",
}

local function GetCustomRootDB()
    return BCDM.db.profile.CooldownManager[VIEWER_KEY]
end

local function BuildCustomViewerFrameName(viewerID)
    if viewerID == 1 then
        return VIEWER_FRAME_NAME
    end
    return VIEWER_FRAME_NAME .. "_" .. viewerID
end

local function BuildCustomViewerName(viewerID)
    return "Custom Viewer " .. tostring(viewerID)
end

local function GetDefaultCustomViewerDB()
    local customDefaults = BCDM:GetDefaultDB().profile.CooldownManager[VIEWER_KEY]
    local defaultViewer = customDefaults and customDefaults.Viewers and customDefaults.Viewers[1]
    if defaultViewer then
        return defaultViewer
    end
    return customDefaults
end

local function GetNextAvailableCustomViewerID(viewers)
    local usedIDs = {}

    for _, viewerData in ipairs(viewers or {}) do
        local viewerID = tonumber(viewerData and viewerData.ViewerID)
        viewerID = viewerID and math.floor(viewerID) or nil
        if viewerID and viewerID >= 1 then
            usedIDs[viewerID] = true
        end
    end

    local nextViewerID = 2
    while usedIDs[nextViewerID] do
        nextViewerID = nextViewerID + 1
    end

    return nextViewerID
end

local function ApplyMissingDefaults(targetTable, defaultTable)
    if type(targetTable) ~= "table" or type(defaultTable) ~= "table" then return end

    for key, defaultValue in pairs(defaultTable) do
        if targetTable[key] == nil then
            targetTable[key] = BCDM:CopyTable(defaultValue)
        elseif type(defaultValue) == "table" and type(targetTable[key]) == "table" then
            ApplyMissingDefaults(targetTable[key], defaultValue)
        end
    end
end

local function NormalizeNumericField(container, key, defaultValue)
    if type(container) ~= "table" then return end
    local value = tonumber(container[key])
    container[key] = value or defaultValue
end

local function NormalizeCustomViewerLayout(layout, defaultLayout)
    if type(layout) ~= "table" then
        return BCDM:CopyTable(defaultLayout)
    end

    layout[1] = layout[1] or defaultLayout[1]
    layout[2] = layout[2] or defaultLayout[2]
    layout[3] = layout[3] or defaultLayout[3]
    layout[4] = tonumber(layout[4])
    if layout[4] == nil then
        layout[4] = defaultLayout[4]
    end
    layout[5] = tonumber(layout[5])
    if layout[5] == nil then
        layout[5] = defaultLayout[5]
    end

    return layout
end

local function NormalizeColourField(colour, defaultColour)
    if type(colour) ~= "table" then
        return BCDM:CopyTable(defaultColour)
    end

    for index = 1, #defaultColour do
        local value = tonumber(colour[index])
        colour[index] = value or defaultColour[index]
    end

    return colour
end

local function NormalizeCustomViewerText(textData, defaultTextData)
    if type(textData) ~= "table" then
        return BCDM:CopyTable(defaultTextData)
    end

    ApplyMissingDefaults(textData, defaultTextData)
    NormalizeNumericField(textData, "FontSize", defaultTextData.FontSize)
    textData.Colour = NormalizeColourField(textData.Colour, defaultTextData.Colour)
    textData.Layout = NormalizeCustomViewerLayout(textData.Layout, defaultTextData.Layout)

    return textData
end

local function NormalizeCustomViewerSettings(viewerData)
    if type(viewerData) ~= "table" then
        viewerData = {}
    end

    local defaultViewer = GetDefaultCustomViewerDB()
    ApplyMissingDefaults(viewerData, defaultViewer)

    viewerData.Layout = NormalizeCustomViewerLayout(viewerData.Layout, defaultViewer.Layout)
    viewerData.Text = NormalizeCustomViewerText(viewerData.Text, defaultViewer.Text)

    NormalizeNumericField(viewerData, "IconSize", defaultViewer.IconSize)
    NormalizeNumericField(viewerData, "IconWidth", defaultViewer.IconWidth)
    NormalizeNumericField(viewerData, "IconHeight", defaultViewer.IconHeight)
    NormalizeNumericField(viewerData, "Spacing", defaultViewer.Spacing)
    NormalizeNumericField(viewerData, "Columns", defaultViewer.Columns)

    return viewerData
end

local function NormalizeCustomViewerCollection(customRootDB)
    if type(customRootDB) ~= "table" then return end

    customRootDB.Viewers = customRootDB.Viewers or {}
    if #customRootDB.Viewers == 0 then
        customRootDB.Viewers[1] = BCDM:CopyTable(GetDefaultCustomViewerDB())
    end

    local usedIDs = {}
    local nextGeneratedID = 1

    for index, viewerData in ipairs(customRootDB.Viewers) do
        viewerData = NormalizeCustomViewerSettings(viewerData)
        customRootDB.Viewers[index] = viewerData

        local viewerID = tonumber(viewerData.ViewerID)
        viewerID = viewerID and math.floor(viewerID) or nil
        if not viewerID or viewerID < 1 or usedIDs[viewerID] then
            while usedIDs[nextGeneratedID] do
                nextGeneratedID = nextGeneratedID + 1
            end
            viewerID = nextGeneratedID
        end

        usedIDs[viewerID] = true
        nextGeneratedID = math.max(nextGeneratedID, viewerID + 1)

        viewerData.ViewerID = viewerID
        viewerData.Name = viewerData.Name or BuildCustomViewerName(viewerID)
        viewerData.FrameName = viewerData.FrameName or BuildCustomViewerFrameName(viewerID)
        viewerData.ItemsSpells = viewerData.ItemsSpells or {}
    end

    local selectedViewerID = tonumber(BCDM.SelectedCustomViewerID) or tonumber(customRootDB.ActiveViewerID)
    if not selectedViewerID or not usedIDs[selectedViewerID] then
        selectedViewerID = customRootDB.Viewers[1].ViewerID
    end

    BCDM.SelectedCustomViewerID = selectedViewerID
    customRootDB.ActiveViewerID = nil
    customRootDB.NextViewerID = nil
    customRootDB.ViewerSchemaVersion = VIEWER_SCHEMA_VERSION
end

local function GetCustomViewerEntries()
    local customRootDB = GetCustomRootDB()
    NormalizeCustomViewerCollection(customRootDB)
    return customRootDB.Viewers
end

local function GetCustomViewerDB(viewerID, methodViewerID)
    local viewers = GetCustomViewerEntries()
    local resolvedViewerID = tonumber(methodViewerID) or tonumber(viewerID) or tonumber(BCDM.SelectedCustomViewerID)

    for _, viewerData in ipairs(viewers) do
        if viewerData.ViewerID == resolvedViewerID then
            return viewerData
        end
    end

    return viewers[1]
end

local function ResolveAnchorParent(anchorName)
    if not anchorName or anchorName == "NONE" then
        return UIParent
    end

    return _G[anchorName] or UIParent
end

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function ApplyCooldownText(container)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = CooldownManagerDB.CooldownManager.General.CooldownText
    local Viewer = container or _G[VIEWER_FRAME_NAME]
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

local function UpdateSpellIconDesaturation(customIcon, spellId)
    if not customIcon or not customIcon.Icon then return end
    local desaturationCurve, gcdFilterCurve = BCDM:GetCooldownDesaturationCurves()

    local cooldownData = C_Spell.GetSpellCooldown(spellId)
    if cooldownData and cooldownData.isOnGCD then
        SetIconDesaturation(customIcon.Icon, 0)
        return
    end

    local spellCharges = C_Spell.GetSpellCharges(spellId)
    local currentCharges
    if spellCharges and type(spellCharges.currentCharges) == "number" and not BCDM:IsSecretValue(spellCharges.currentCharges) then
        currentCharges = spellCharges.currentCharges
    end
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
    if not cooldownFrame then return false end
    local oldStart, oldDuration = cooldownFrame:GetCooldownTimes()
    oldStart = tonumber(oldStart) or 0
    oldDuration = tonumber(oldDuration) or 0
    if hasActiveCooldown then
        if oldStart <= 0 or oldDuration <= 0 then return true end
        local oldEnd = (oldStart + oldDuration) / 1000
        local newEnd = (startTime or 0) + (durationTime or 0)
        return math.abs(oldEnd - newEnd) > 0.01
    end
    return oldStart > 0 and oldDuration > 0
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
    if itemCount == nil then return true end
    return itemCount > 0
end

local function IsOnUseTrinket(itemId)
    if not itemId then return false end
    local spellName, spellID = C_Item.GetItemSpell(itemId)
    return (spellID and spellID > 0) or (spellName and spellName ~= "")
end

local function FetchEquippedOnUseTrinkets()
    local equippedTrinkets = {}
    for _, slotID in ipairs(TRINKET_SLOTS) do
        local itemId = GetInventoryItemID("player", slotID)
        if itemId and IsOnUseTrinket(itemId) then
            equippedTrinkets[#equippedTrinkets + 1] = { itemId = itemId, slotID = slotID }
        end
    end

    return equippedTrinkets
end

local POTION_CLASS_ID = (Enum.ItemClass.Consumable) or 0
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
    if expansionID == 11 then
        return "Professions-Icon-Quality-12-Tier" .. rank .. "-Small"
    end
    return "Professions-Icon-Quality-Tier" .. rank .. "-Small"
end

local function FetchPotionProfessionRank(itemId)
    if not itemId then return 0 end
    local _, itemLink = C_Item.GetItemInfo(itemId)
    local atlasName = ParseProfessionAtlasFromItemLink(itemLink)
    local parsedRank = atlasName and tonumber(string.match(atlasName, "Tier(%d+)"))
    if parsedRank then return parsedRank end

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
    return
end

local function ResolveItemQualityAtlas(itemId)
    if not itemId then return end

    local _, itemLink = C_Item.GetItemInfo(itemId)
    local atlasFromLink = ParseProfessionAtlasFromItemLink(itemLink)
    if atlasFromLink then return atlasFromLink end
    local rank = FetchPotionProfessionRank(itemId)
    return BuildProfessionAtlasFromRank(itemId, rank)
end

local function SelectPotionRankCandidate(potionGroups, itemId, layoutIndex)
    if not IsPotionItem(itemId) then return end

    local itemName = C_Item.GetItemInfo(itemId)
    if not itemName then return end

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

local function AcquireIconFrame()
    if not customIconPool then
        customIconPool = CreateFramePool("Button", UIParent, "BackdropTemplate", function(pool, frame)
            frame:UnregisterAllEvents()
            frame:SetScript("OnEvent", nil)
            frame:Hide()
            frame:ClearAllPoints()
            if frame.Cooldown then frame.Cooldown:SetCooldown(0, 0) end
        end)
    end

    local customIcon = customIconPool:Acquire()
    if not customIcon.Cooldown then
        local HighLevelContainer = CreateFrame("Frame", nil, customIcon)
        HighLevelContainer:SetAllPoints(customIcon)
        HighLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

        customIcon.Charges = HighLevelContainer:CreateFontString(nil, "OVERLAY")

        customIcon.Cooldown = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
        customIcon.Cooldown:SetAllPoints(customIcon)
        customIcon.Cooldown:SetDrawEdge(false)
        customIcon.Cooldown:SetDrawSwipe(true)
        customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
        customIcon.Cooldown:SetHideCountdownNumbers(false)
        customIcon.Cooldown:SetReverse(false)

        customIcon.QualityAtlas = HighLevelContainer:CreateTexture(nil, "OVERLAY")

        customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    end
    return customIcon
end

local function CreateCustomIcon(entryId, entryType, customDB)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = customDB or GetCustomViewerDB()
    if not entryId then return end

    local isItem = entryType == "item"
    if isItem then
        if not C_Item.GetItemInfo(entryId) then return end
    else
        if not C_SpellBook.IsSpellInSpellBook(entryId) then return end
    end

    local customIcon = AcquireIconFrame()
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end
    local iconWidth, iconHeight = BCDM:GetIconDimensions(CustomDB)
    customIcon:SetSize(iconWidth, iconHeight)
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(CustomDB.FrameStrata or "LOW")
    customIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    if isItem then
        customIcon:RegisterEvent("ITEM_COUNT_CHANGED")
    else
        customIcon:RegisterEvent("SPELL_UPDATE_CHARGES")
        customIcon:RegisterEvent("ITEM_PUSH")
    end

    customIcon.Cooldown:SetDrawBling(false)

    customIcon.Charges:ClearAllPoints()
    customIcon.Charges:SetFont(BCDM.Media.Font, CustomDB.Text.FontSize, GeneralDB.Fonts.FontFlag)
    customIcon.Charges:SetPoint(CustomDB.Text.Layout[1], customIcon, CustomDB.Text.Layout[2], CustomDB.Text.Layout[3], CustomDB.Text.Layout[4])
    customIcon.Charges:SetTextColor(CustomDB.Text.Colour[1], CustomDB.Text.Colour[2], CustomDB.Text.Colour[3], 1)
    if isItem then
        customIcon.Charges:SetText(tostring(select(1, FetchItemData(entryId)) or ""))
    end
    if GeneralDB.Fonts.Shadow.Enabled then
        customIcon.Charges:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
        customIcon.Charges:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
    else
        customIcon.Charges:SetShadowColor(0, 0, 0, 0)
        customIcon.Charges:SetShadowOffset(0, 0)
    end

    customIcon.QualityAtlas:Hide()
    if isItem then
        ApplyItemQualityAtlas(customIcon, entryId, CustomDB, iconWidth, iconHeight)
    end

    if isItem then
        customIcon:SetScript("OnEvent", function(self, event, ...)
            if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "ITEM_COUNT_CHANGED" then
                local itemCount, startTime, durationTime = FetchItemData(entryId)
                if itemCount then
                    local hasActiveCooldown = (startTime and durationTime and startTime > 0 and durationTime > 0) or false
                    customIcon.Charges:SetText(tostring(itemCount))
                    if C_Item.IsUsableItem(entryId) then
                        local shouldRefreshCooldown = ShouldRefreshItemCooldownFrame(customIcon.Cooldown, hasActiveCooldown, startTime, durationTime)
                        if hasActiveCooldown and shouldRefreshCooldown then
                            customIcon.Cooldown:SetCooldown(startTime, durationTime)
                        elseif not hasActiveCooldown and event ~= "ITEM_COUNT_CHANGED" and shouldRefreshCooldown then
                            customIcon.Cooldown:SetCooldown(0, 0)
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
                        SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(startTime, durationTime))
                    else
                        SetIconDesaturation(customIcon.Icon, 0)
                    end
                    if not C_Item.IsUsableItem(entryId) then customIcon.Icon:SetVertexColor(0.5, 0.5, 0.5) else customIcon.Icon:SetVertexColor(1, 1, 1) end
                    customIcon.Charges:SetAlphaFromBoolean(itemCount > 1, 1, 0)
                end
            end
        end)
    else
        customIcon:SetScript("OnEvent", function(self, event, ...)
            if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "SPELL_UPDATE_CHARGES" then
                local spellCharges = C_Spell.GetSpellCharges(entryId)
                if spellCharges then
                    customIcon.Charges:SetText(C_Spell.GetSpellDisplayCount(entryId) or "")
                    customIcon.Cooldown:SetCooldown(spellCharges.cooldownStartTime, spellCharges.cooldownDuration)
                else
                    local cooldownData = C_Spell.GetSpellCooldown(entryId)
                    customIcon.Cooldown:SetCooldown(cooldownData.startTime, cooldownData.duration)
                    customIcon.Charges:SetText("")
                end
                UpdateSpellIconDesaturation(self, entryId)
            end
        end)
    end

    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:ClearAllPoints()
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)
    if isItem then
        customIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(entryId)))
    else
        customIcon.Icon:SetTexture(C_Spell.GetSpellInfo(entryId).iconID)
    end

    local onEvent = customIcon:GetScript("OnEvent")
    if onEvent then onEvent(customIcon, "PLAYER_ENTERING_WORLD") end

    return customIcon
end

local function ResolveItemSpellEntryType(entryId, entryData)
    if entryData and entryData.entryType then return entryData.entryType end
    if C_Item.GetItemInfo(entryId) then return "item" end
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

local function CreateCustomIcons(iconTable, visibleItemIds, customDB)
    local CustomDB = customDB or GetCustomDB()
    local Items = CustomDB.ItemsSpells
    local playerClass = select(2, UnitClass("player"))
    local specIndex = GetSpecialization()
    local specID, specName = specIndex and GetSpecializationInfo(specIndex)
    local playerSpecialization = BCDM:NormalizeSpecToken(specName, specID, specIndex)

    wipe(iconTable)
    if visibleItemIds then wipe(visibleItemIds) end

    local sortedEntries = {}
    local potionGroups = {}
    local addedItemIds = {}

    if Items then
        for entryId, data in pairs(Items) do
            if data.isActive and IsEntryEnabledForPlayerSpec(data, playerClass, playerSpecialization) then
                local entryType = ResolveItemSpellEntryType(entryId, data)
                if entryType == "item" then
                    local layoutIndex = data.layoutIndex or math.huge
                    local isPotionEntry = SelectPotionRankCandidate(potionGroups, entryId, layoutIndex)
                    if isPotionEntry or not ShouldShowItem(CustomDB, entryId) then
                        entryType = nil
                    end
                end

                if entryType then
                    table.insert(sortedEntries, {
                        id = entryId,
                        index = data.layoutIndex or math.huge,
                        entryType = entryType,
                    })
                end
            end
        end
    end

    for _, potionGroup in pairs(potionGroups) do
        local selected = potionGroup.selected
        if selected and selected.count > 0 then
            table.insert(sortedEntries, {
                id = selected.id,
                index = potionGroup.index or math.huge,
                entryType = "item",
            })
        end
    end

    table.sort(sortedEntries, function(a, b)
        if a.index == b.index then
            return tostring(a.id) < tostring(b.id)
        end
        return a.index < b.index
    end)

    for _, entry in ipairs(sortedEntries) do
        local customItem = CreateCustomIcon(entry.id, entry.entryType, CustomDB)

        if customItem then
            table.insert(iconTable, customItem)
            if entry.entryType == "item" then
                addedItemIds[entry.id] = true
                if visibleItemIds then
                    visibleItemIds[entry.id] = true
                end
            end
        end
    end

    if not CustomDB.AutoDetectUsableTrinkets then return end

    for _, trinketEntry in ipairs(FetchEquippedOnUseTrinkets()) do
        if not addedItemIds[trinketEntry.itemId] then
            local customItem = CreateCustomIcon(trinketEntry.itemId, "item", CustomDB)
            if customItem then
                table.insert(iconTable, customItem)
                addedItemIds[trinketEntry.itemId] = true
                if visibleItemIds then
                    visibleItemIds[trinketEntry.itemId] = true
                end
            end
        end
    end
end

local function RequestDeferredContainerUpdate(container)
    if not container or container.PendingRefresh then
        return
    end

    container.PendingRefresh = true
    C_Timer.After(0, function()
        container.PendingRefresh = false
        LayoutCustomViewer()
    end)
end

local function HandleCustomViewerContainerEvent(self, event, itemId)
    local customDB = self.CustomViewerDB or GetCustomViewerDB(self.ViewerID)
    if not customDB then return end
    local items = customDB and customDB.ItemsSpells

    if event == "PLAYER_EQUIPMENT_CHANGED" then
        if itemId == 13 or itemId == 14 then
            RequestDeferredContainerUpdate(self)
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" or event == "BAG_UPDATE_DELAYED" then
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
        if not (entry and entry.isActive) then return end
        local entryType = ResolveItemSpellEntryType(itemId, entry)
        if entryType ~= "item" then return end
        if IsPotionItem(itemId) then
            RequestDeferredContainerUpdate(self)
            return
        end
        if not customDB.HideZeroCharges then return end
        local visible = self.VisibleItemIds and self.VisibleItemIds[itemId] or false
        local shouldShow = ShouldShowItem(customDB, itemId)
        if visible ~= shouldShow then
            RequestDeferredContainerUpdate(self)
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

    container.ViewerID = viewerData.ViewerID
    container.CustomViewerDB = viewerData
    return container
end

local function UpdateCustomViewerContainerEvents(container, customDB)
    local shouldTrackItemCountChanges = customDB.HideZeroCharges or HasTrackedPotionEntries(customDB.ItemsSpells)
    local shouldTrackEquipmentChanges = customDB.AutoDetectUsableTrinkets

    if shouldTrackItemCountChanges then
        container:RegisterEvent("ITEM_COUNT_CHANGED")
        container:RegisterEvent("ITEM_PUSH")
        container:RegisterEvent("BAG_UPDATE_DELAYED")
        container:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        container:UnregisterEvent("ITEM_COUNT_CHANGED")
        container:UnregisterEvent("ITEM_PUSH")
        container:UnregisterEvent("BAG_UPDATE_DELAYED")
        container:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

    if shouldTrackEquipmentChanges then
        container:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    else
        container:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    end
end

local function LayoutCustomViewerContainer(container, customDB)
    local customViewerIcons = {}
    local visibleItemIds = {}

    local growthDirection = customDB.GrowthDirection or "RIGHT"

    local containerAnchorFrom = customDB.Layout[1]
    if growthDirection == "UP" then
        local verticalFlipMap = {
            ["TOPLEFT"] = "BOTTOMLEFT",
            ["TOP"] = "BOTTOM",
            ["TOPRIGHT"] = "BOTTOMRIGHT",
            ["BOTTOMLEFT"] = "TOPLEFT",
            ["BOTTOM"] = "TOP",
            ["BOTTOMRIGHT"] = "TOPRIGHT",
        }
        containerAnchorFrom = verticalFlipMap[customDB.Layout[1]] or customDB.Layout[1]
    end

    container:ClearAllPoints()
    container:SetFrameStrata(customDB.FrameStrata or "LOW")
    local anchorParent = ResolveAnchorParent(customDB.Layout[2])
    container:SetPoint(containerAnchorFrom, anchorParent, customDB.Layout[3], customDB.Layout[4], customDB.Layout[5])

    UpdateCustomViewerContainerEvents(container, customDB)

    CreateCustomIcons(customViewerIcons, visibleItemIds, customDB)
    container.VisibleItemIds = visibleItemIds

    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
    local iconSpacing = customDB.Spacing
    local point = select(1, container:GetPoint(1))
    local isHorizontalGrowth = growthDirection == "LEFT" or growthDirection == "RIGHT"
    local wrapLimit = math.max(0, math.floor(tonumber(customDB.Columns) or 0))
    local lineLimit = (wrapLimit > 0) and wrapLimit or #customViewerIcons
    local useCenteredLayout = (point == "TOP" or point == "BOTTOM") and isHorizontalGrowth
    local growsUp = point and point:find("BOTTOM") ~= nil
    local growsLeft = point and point:find("RIGHT") ~= nil

    if #customViewerIcons == 0 then
        container:SetSize(1, 1)
        container:Show()
        return
    else
        local totalWidth, totalHeight
        local lineCount = math.ceil(#customViewerIcons / lineLimit)

        if isHorizontalGrowth then
            local columnsInRow = math.min(lineLimit, #customViewerIcons)
            totalWidth = (columnsInRow * iconWidth) + ((columnsInRow - 1) * iconSpacing)
            totalHeight = (lineCount * iconHeight) + ((lineCount - 1) * iconSpacing)
        else
            local rowsInColumn = math.min(lineLimit, #customViewerIcons)
            totalWidth = (lineCount * iconWidth) + ((lineCount - 1) * iconSpacing)
            totalHeight = (rowsInColumn * iconHeight) + ((rowsInColumn - 1) * iconSpacing)
        end
        container:SetWidth(totalWidth)
        container:SetHeight(totalHeight)
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

    if useCenteredLayout and #customViewerIcons > 0 then
        local rowCount = math.ceil(#customViewerIcons / lineLimit)
        local rowDirection = growsUp and 1 or -1

        for rowIndex = 1, rowCount do
            local rowStart = ((rowIndex - 1) * lineLimit) + 1
            local rowEnd = math.min(rowStart + lineLimit - 1, #customViewerIcons)
            local rowIcons = rowEnd - rowStart + 1
            local rowWidth = (rowIcons * iconWidth) + ((rowIcons - 1) * iconSpacing)
            local startOffset = -(rowWidth / 2) + (iconWidth / 2)
            local yOffset = (rowIndex - 1) * (iconHeight + iconSpacing) * rowDirection

            for i = rowStart, rowEnd do
                local spellIcon = customViewerIcons[i]
                spellIcon:SetParent(container)
                spellIcon:SetSize(iconWidth, iconHeight)
                spellIcon:ClearAllPoints()

                local xOffset = startOffset + ((i - rowStart) * (iconWidth + iconSpacing))
                spellIcon:SetPoint("CENTER", container, "CENTER", xOffset, yOffset)
                spellIcon:Show()
            end
        end
    else
        for i, spellIcon in ipairs(customViewerIcons) do
            spellIcon:SetParent(container)
            spellIcon:SetSize(iconWidth, iconHeight)
            spellIcon:ClearAllPoints()

            if i == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                spellIcon:SetPoint(config.anchor, container, config.anchor, 0, 0)
            else
                local isWrappedRowStart = (i - 1) % lineLimit == 0
                if isWrappedRowStart then
                    local lineAnchorIcon = customViewerIcons[i - lineLimit]
                    if isHorizontalGrowth then
                        if growsUp then
                            spellIcon:SetPoint("BOTTOM", lineAnchorIcon, "TOP", 0, iconSpacing)
                        else
                            spellIcon:SetPoint("TOP", lineAnchorIcon, "BOTTOM", 0, -iconSpacing)
                        end
                    else
                        if growsLeft then
                            spellIcon:SetPoint("RIGHT", lineAnchorIcon, "LEFT", -iconSpacing, 0)
                        else
                            spellIcon:SetPoint("LEFT", lineAnchorIcon, "RIGHT", iconSpacing, 0)
                        end
                    end
                else
                    if growthDirection == "RIGHT" then
                        spellIcon:SetPoint("LEFT", customViewerIcons[i - 1], "RIGHT", iconSpacing, 0)
                    elseif growthDirection == "LEFT" then
                        spellIcon:SetPoint("RIGHT", customViewerIcons[i - 1], "LEFT", -iconSpacing, 0)
                    elseif growthDirection == "UP" then
                        spellIcon:SetPoint("BOTTOM", customViewerIcons[i - 1], "TOP", 0, iconSpacing)
                    elseif growthDirection == "DOWN" then
                        spellIcon:SetPoint("TOP", customViewerIcons[i - 1], "BOTTOM", 0, -iconSpacing)
                    end
                end
            end
            spellIcon:Show()
        end
    end

    ApplyCooldownText(container)
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
            container.VisibleItemIds = nil
            container:Hide()
        end
    end
end

LayoutCustomViewer = function()
    local viewers = GetCustomViewerEntries()
    local activeFrameNames = {}

    if customIconPool then
        customIconPool:ReleaseAll()
    end

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

function BCDM:AdjustCustomViewerLayoutIndex(direction, itemId, viewerID)
    local CustomDB = GetCustomViewerDB(viewerID)
    local Items = CustomDB.ItemsSpells

    if not Items then return end
    if not Items[itemId] then return end

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
    NormalizeCustomViewerLayoutIndices(viewerID)

    LayoutCustomViewer()
end

NormalizeCustomViewerLayoutIndices = function(viewerID, methodViewerID)
    local CustomDB = GetCustomViewerDB(viewerID, methodViewerID)
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

function BCDM:AdjustCustomViewerList(itemId, adjustingHow, entryType, viewerID)
    local CustomDB = GetCustomViewerDB(viewerID)
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
        local playerClass = select(2, UnitClass("player"))
        local classSpecFilters
        local filterClass
        if resolvedType == "spell" then
            filterClass = playerClass
            classSpecFilters = BCDM:BuildClassSpecFilters(filterClass)
        else
            classSpecFilters = BCDM:BuildClassSpecFilters()
        end
        Items[itemId] = {
            isActive = true,
            layoutIndex = maxIndex + 1,
            entryType = resolvedType,
            classSpecFilters = classSpecFilters,
            filterClass = filterClass,
        }
    elseif adjustingHow == "remove" then
        Items[itemId] = nil
    end

    NormalizeCustomViewerLayoutIndices(viewerID)
    LayoutCustomViewer()
end

local function MergeLegacyEntry(targetEntries, entryId, entryData)
    if not entryData then return end

    local existing = targetEntries[entryId]
    if not existing then
        targetEntries[entryId] = entryData
        return
    end

    existing.isActive = existing.isActive or entryData.isActive
    existing.entryType = existing.entryType or entryData.entryType
    if (entryData.layoutIndex or math.huge) < (existing.layoutIndex or math.huge) then
        existing.layoutIndex = entryData.layoutIndex
    end
    existing.filterClass = existing.filterClass or entryData.filterClass

    if type(entryData.classSpecFilters) == "table" then
        existing.classSpecFilters = existing.classSpecFilters or {}
        for classSpecValue, isEnabled in pairs(entryData.classSpecFilters) do
            if isEnabled then
                existing.classSpecFilters[classSpecValue] = true
            end
        end
    end
end

local function ImportLegacyItemEntries(targetEntries, sourceEntries)
    if type(sourceEntries) ~= "table" then return end

    for entryId, data in pairs(sourceEntries) do
        local resolvedType = data.entryType or ResolveItemSpellEntryType(entryId, data)
        if resolvedType then
            MergeLegacyEntry(targetEntries, entryId, {
                isActive = data.isActive ~= false,
                layoutIndex = data.layoutIndex or math.huge,
                entryType = resolvedType,
                classSpecFilters = BCDM:CopyTable(data.classSpecFilters),
                filterClass = data.filterClass,
            })
        end
    end
end

local function ImportLegacySpellEntries(targetEntries, sourceEntries)
    if type(sourceEntries) ~= "table" then return end

    for classToken, specs in pairs(sourceEntries) do
        for specToken, spells in pairs(specs) do
            local normalizedSpec = BCDM:NormalizeSpecToken(specToken) or specToken
            local classSpecValue = classToken .. ":" .. normalizedSpec
            for spellId, data in pairs(spells) do
                MergeLegacyEntry(targetEntries, spellId, {
                    isActive = data.isActive ~= false,
                    layoutIndex = data.layoutIndex or math.huge,
                    entryType = "spell",
                    classSpecFilters = { [classSpecValue] = true },
                    filterClass = classToken,
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

BCDM.GetCustomViewerEntries = GetCustomViewerEntries
BCDM.GetSelectedCustomViewerDB = GetCustomViewerDB

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
    local viewers = GetCustomViewerEntries()
    local nextViewerID = GetNextAvailableCustomViewerID(viewers)
    local newViewer = self:CopyTable(GetDefaultCustomViewerDB())

    newViewer.ViewerID = nextViewerID
    newViewer.Name = BuildCustomViewerName(nextViewerID)
    newViewer.FrameName = BuildCustomViewerFrameName(nextViewerID)

    viewers[#viewers + 1] = newViewer
    NormalizeCustomViewerCollection(GetCustomRootDB())
    self.SelectedCustomViewerID = nextViewerID
    RefreshCustomViewerAnchors()
    LayoutCustomViewer()
    return newViewer
end

function BCDM:RemoveCustomViewer(viewerID)
    local customRootDB = GetCustomRootDB()
    local viewers = GetCustomViewerEntries()
    if #viewers <= 1 then
        return false
    end

    local wasSelectedViewer = tonumber(self.SelectedCustomViewerID) == viewerID
    local viewerIndexToRemove
    local viewerDataToRemove
    for index, viewerData in ipairs(viewers) do
        if viewerData.ViewerID == viewerID then
            viewerIndexToRemove = index
            viewerDataToRemove = viewerData
            break
        end
    end

    if not viewerIndexToRemove then
        return false
    end

    table.remove(viewers, viewerIndexToRemove)

    local removedFrameName = viewerDataToRemove and viewerDataToRemove.FrameName
    local removedContainer = removedFrameName and BCDM.CustomViewerContainers and BCDM.CustomViewerContainers[removedFrameName]
    if removedContainer then
        removedContainer:UnregisterEvent("ITEM_COUNT_CHANGED")
        removedContainer:UnregisterEvent("ITEM_PUSH")
        removedContainer:UnregisterEvent("BAG_UPDATE_DELAYED")
        removedContainer:UnregisterEvent("PLAYER_ENTERING_WORLD")
        removedContainer:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
        removedContainer:Hide()
    end

    local fallbackViewer = viewers[math.max(1, viewerIndexToRemove - 1)] or viewers[1]
    NormalizeCustomViewerCollection(customRootDB)
    if wasSelectedViewer and fallbackViewer then
        self.SelectedCustomViewerID = fallbackViewer.ViewerID
    end

    RefreshCustomViewerAnchors()
    LayoutCustomViewer()
    return true
end

RefreshCustomViewerAnchors = function()
    if not BCDM.AnchorParents then return end

    BCDM.DynamicCustomViewerAnchors = BCDM.DynamicCustomViewerAnchors or {}

    for _, anchorType in ipairs({ "CustomViewer", "Trinket" }) do
        local anchorData = BCDM.AnchorParents[anchorType]
        if anchorData then
            local displayNames = anchorData[1]
            local keyList = anchorData[2]
            for anchorKey in pairs(BCDM.DynamicCustomViewerAnchors) do
                displayNames[anchorKey] = nil
                for index = #keyList, 1, -1 do
                    if keyList[index] == anchorKey then
                        table.remove(keyList, index)
                    end
                end
            end
        end
    end

    wipe(BCDM.DynamicCustomViewerAnchors)

    for _, viewerData in ipairs(GetCustomViewerEntries()) do
        local frameName = viewerData.FrameName
        if frameName then
            BCDM.DynamicCustomViewerAnchors[frameName] = true
            local displayName = "|cFF8080FFBCDM|r: " .. (viewerData.Name or BuildCustomViewerName(viewerData.ViewerID))
            for _, anchorType in ipairs({ "CustomViewer", "Trinket" }) do
                local anchorData = BCDM.AnchorParents[anchorType]
                if anchorData then
                    local displayNames = anchorData[1]
                    local keyList = anchorData[2]
                    displayNames[frameName] = displayName
                    if not tContains(keyList, frameName) then
                        table.insert(keyList, frameName)
                    end
                end
            end
        end
    end
end

function BCDM:MigrateCustomViewerData()
    local CooldownManagerDB = self.db and self.db.profile and self.db.profile.CooldownManager
    if not CooldownManagerDB then return end

    if not CooldownManagerDB[VIEWER_KEY] then
        CooldownManagerDB[VIEWER_KEY] = self:CopyTable(self:GetDefaultDB().profile.CooldownManager[VIEWER_KEY])
    end

    local CustomDB = CooldownManagerDB[VIEWER_KEY]

    if CustomDB.ViewerSchemaVersion ~= VIEWER_SCHEMA_VERSION or type(CustomDB.Viewers) ~= "table" or #CustomDB.Viewers == 0 then
        local primaryViewer = self:CopyTable(GetDefaultCustomViewerDB())
        CopyCustomViewerSettings(primaryViewer, CustomDB)
        if CustomDB.ItemsSpells ~= nil then
            primaryViewer.ItemsSpells = self:CopyTable(CustomDB.ItemsSpells)
        end
        CustomDB.Viewers = { primaryViewer }
    end

    NormalizeCustomViewerCollection(CustomDB)

    local primaryViewer = GetCustomViewerDB(CustomDB.Viewers[1].ViewerID)

    if CustomDB.LegacyMigrationVersion ~= LEGACY_MIGRATION_VERSION then
        local settingsSource = CooldownManagerDB.ItemSpell or CooldownManagerDB.Item or CooldownManagerDB.Custom or CooldownManagerDB.AdditionalCustom
        if settingsSource then
            CopyCustomViewerSettings(primaryViewer, settingsSource)
        end

        if primaryViewer.Layout and primaryViewer.Layout[2] and primaryViewer.Layout[2] ~= "NONE" then
            local removedAnchors = {
                BCDM_CustomCooldownViewer = true,
                BCDM_AdditionalCustomCooldownViewer = true,
                BCDM_CustomItemBar = true,
                BCDM_CustomItemSpellBar = true,
            }
            if removedAnchors[primaryViewer.Layout[2]] then
                primaryViewer.Layout[2] = "NONE"
            end
        end

        primaryViewer.ItemsSpells = primaryViewer.ItemsSpells or {}
        if next(primaryViewer.ItemsSpells) == nil then
            ImportLegacyItemEntries(primaryViewer.ItemsSpells, CooldownManagerDB.ItemSpell and CooldownManagerDB.ItemSpell.ItemsSpells)
            ImportLegacyItemEntries(primaryViewer.ItemsSpells, CooldownManagerDB.Item and CooldownManagerDB.Item.Items)
            ImportLegacySpellEntries(primaryViewer.ItemsSpells, CooldownManagerDB.Custom and CooldownManagerDB.Custom.Spells)
            ImportLegacySpellEntries(primaryViewer.ItemsSpells, CooldownManagerDB.AdditionalCustom and CooldownManagerDB.AdditionalCustom.Spells)
            NormalizeCustomViewerLayoutIndices(primaryViewer.ViewerID)
        end

        CustomDB.LegacyMigrationVersion = LEGACY_MIGRATION_VERSION
    end

    NormalizeCustomViewerCollection(CustomDB)
    RefreshCustomViewerAnchors()
end

BCDM.SetupCustomItemsSpellsBar = LayoutCustomViewer
BCDM.UpdateCustomItemsSpellsBar = LayoutCustomViewer
BCDM.AdjustItemsSpellsLayoutIndex = BCDM.AdjustCustomViewerLayoutIndex
BCDM.NormalizeItemsSpellsLayoutIndices = NormalizeCustomViewerLayoutIndices
BCDM.AdjustItemsSpellsList = BCDM.AdjustCustomViewerList

BCDM.SetupCustomCooldownViewer = LayoutCustomViewer
BCDM.UpdateCustomCooldownViewer = LayoutCustomViewer
BCDM.SetupAdditionalCustomCooldownViewer = LayoutCustomViewer
BCDM.UpdateAdditionalCustomCooldownViewer = LayoutCustomViewer
BCDM.SetupCustomItemBar = LayoutCustomViewer
BCDM.UpdateCustomItemBar = LayoutCustomViewer
BCDM.AdjustItemLayoutIndex = BCDM.AdjustCustomViewerLayoutIndex
BCDM.NormalizeItemLayoutIndices = NormalizeCustomViewerLayoutIndices
BCDM.AdjustItemList = BCDM.AdjustCustomViewerList
