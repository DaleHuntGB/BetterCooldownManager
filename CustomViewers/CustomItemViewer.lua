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
    local Viewer = _G["BCDM_CustomItemBar"]
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

local function ShouldRefreshItemCooldownFrame(cooldownFrame, hasActiveCooldown, startTime, durationTime)
    if not cooldownFrame then
        return false
    end

    local oldStart, oldDuration = cooldownFrame:GetCooldownTimes()
    oldStart = tonumber(oldStart) or 0
    oldDuration = tonumber(oldDuration) or 0

    if hasActiveCooldown then
        if oldStart <= 0 or oldDuration <= 0 then
            return true
        end
        -- GetCooldownTimes returns milliseconds, SetCooldown uses seconds.
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

local function HasTrackedPotionEntries(items)
    if not items then return false end
    for itemId, data in pairs(items) do
        if data and data.isActive and IsPotionItem(itemId) then
            return true
        end
    end
    return false
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

local function ParseClassSpecFilterValue(value)
    if not value then return end
    local normalizedValue = tostring(value):upper()
    local classToken, specToken = string.match(normalizedValue, "^(%u+):([%u%d_]+)$")
    if not classToken or not specToken then return end
    return classToken, (BCDM:NormalizeSpecToken(specToken) or specToken)
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

local function CreateCustomIcon(itemId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.CooldownManager.Item
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
    local iconWidth, iconHeight = BCDM:GetIconDimensions(CustomDB)
    customIcon:SetSize(iconWidth, iconHeight)
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    customIcon:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    customIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    customIcon:RegisterEvent("ITEM_COUNT_CHANGED")
    customIcon:RegisterEvent("ITEM_PUSH")
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
    customIcon.Cooldown:SetDrawBling(false)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)

    customIcon.QualityAtlas = HighLevelContainer:CreateTexture(nil, "OVERLAY")
    customIcon.QualityAtlas:Hide()
    ApplyItemQualityAtlas(customIcon, itemId, CustomDB, iconWidth, iconHeight)

    customIcon:SetScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "ITEM_COUNT_CHANGED" then
            local itemCount, startTime, durationTime = FetchItemData(itemId)
            if itemCount then
                local hasActiveCooldown = (startTime and durationTime and startTime > 0 and durationTime > 0) or false
                customIcon.Charges:SetText(tostring(itemCount))
                if C_Item.IsUsableItem(itemId) then
                    local shouldRefreshCooldown = ShouldRefreshItemCooldownFrame(customIcon.Cooldown, hasActiveCooldown, startTime, durationTime)
                    if hasActiveCooldown and shouldRefreshCooldown then
                        local durationObject = C_DurationUtil.CreateDuration()
                        durationObject:SetTimeFromStart(startTime, durationTime)
                        customIcon.Cooldown:SetCooldownFromDurationObject(durationObject, true)
                    elseif not hasActiveCooldown and event ~= "ITEM_COUNT_CHANGED" and shouldRefreshCooldown then
                        -- Avoid cooldown flicker from transient ITEM_COUNT_CHANGED updates.
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
                    SetIconDesaturation(customIcon.Icon, CalculateFallbackDesaturation(startTime, durationTime))
                else
                    SetIconDesaturation(customIcon.Icon, 0)
                end
                if not C_Item.IsUsableItem(itemId) then customIcon.Icon:SetVertexColor(0.5, 0.5, 0.5) else customIcon.Icon:SetVertexColor(1, 1, 1) end
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

    local onEvent = customIcon:GetScript("OnEvent")
    if onEvent then
        onEvent(customIcon, "PLAYER_ENTERING_WORLD")
    end

    return customIcon
end

local function CreateCustomIcons(iconTable, visibleItemIds)
    local CustomDB = BCDM.db.profile.CooldownManager.Item
    local Items = CustomDB.Items
    local playerClass = select(2, UnitClass("player"))
    local specIndex = GetSpecialization()
    local specID, specName = specIndex and GetSpecializationInfo(specIndex)
    local playerSpecialization = BCDM:NormalizeSpecToken(specName, specID, specIndex)

    local isWarlock = select(2, UnitClass("player")) == "WARLOCK"
    local pactOfGluttony = C_SpellBook.IsSpellKnown(386689)

    local healthstoneBaseId = 5512
    local healthstoneGluttonyId = 224464
    local activeHealthstoneId = nil
    if isWarlock then
        activeHealthstoneId = pactOfGluttony and healthstoneGluttonyId or healthstoneBaseId
    end

    wipe(iconTable)
    if visibleItemIds then wipe(visibleItemIds) end

    if Items then
        local items = {}
        local potionGroups = {}
        local healthstoneIndex = nil
        for itemId, data in pairs(Items) do
            local layoutIndex = data.layoutIndex or math.huge
            local isEntryEnabled = data.isActive and IsEntryEnabledForPlayerSpec(data, playerClass, playerSpecialization)
            if isWarlock and (itemId == healthstoneBaseId or itemId == healthstoneGluttonyId) then
                if isEntryEnabled then
                    healthstoneIndex = math.min(healthstoneIndex or math.huge, layoutIndex)
                end
            elseif isEntryEnabled then
                local isPotionEntry = SelectPotionRankCandidate(potionGroups, itemId, layoutIndex)
                if (not isPotionEntry) and ShouldShowItem(CustomDB, itemId) then
                    table.insert(items, {id = itemId, index = layoutIndex})
                end
            end
        end
        for _, potionGroup in pairs(potionGroups) do
            local selected = potionGroup.selected
            if selected and selected.count > 0 then
                table.insert(items, {id = selected.id, index = potionGroup.index or math.huge})
            end
        end
        if isWarlock and healthstoneIndex and activeHealthstoneId then
            if ShouldShowItem(CustomDB, activeHealthstoneId) then
                table.insert(items, {id = activeHealthstoneId, index = healthstoneIndex})
            end
        end

        table.sort(items, function(a, b) return a.index < b.index end)

        for _, item in ipairs(items) do
            local customItem = CreateCustomIcon(item.id)
            if customItem then
                table.insert(iconTable, customItem)
                if visibleItemIds then visibleItemIds[item.id] = true end
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

local function RequestDeferredContainerUpdate(container)
    if not container or container.PendingRefresh then
        return
    end

    container.PendingRefresh = true
    C_Timer.After(0, function()
        container.PendingRefresh = false
        BCDM:UpdateCustomItemBar()
    end)
end

local function LayoutCustomItemBar()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Item
    local customItemBarIcons = {}
    local visibleItemIds = {}

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

    if not BCDM.CustomItemBarContainer then
        BCDM.CustomItemBarContainer = CreateFrame("Frame", "BCDM_CustomItemBar", UIParent, "BackdropTemplate")
        BCDM.CustomItemBarContainer:SetSize(1, 1)
    end

    BCDM.CustomItemBarContainer:ClearAllPoints()
    BCDM.CustomItemBarContainer:SetFrameStrata(CustomDB.FrameStrata or "LOW")
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    BCDM.CustomItemBarContainer:SetPoint(containerAnchorFrom, anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])

    if not BCDM.CustomItemBarContainer.HideZeroEventHooked then
        BCDM.CustomItemBarContainer.HideZeroEventHooked = true
        BCDM.CustomItemBarContainer:SetScript("OnEvent", function(self, event, itemId)
            local customDB = BCDM.db.profile.CooldownManager.Item
            local items = customDB.Items
            if not items then return end
            if event == "PLAYER_ENTERING_WORLD" or event == "BAG_UPDATE_DELAYED" then
                RequestDeferredContainerUpdate(self)
                return
            end
            if event == "ITEM_COUNT_CHANGED" or event == "ITEM_PUSH" then
                if not itemId then
                    RequestDeferredContainerUpdate(self)
                    return
                end
                local entry = items[itemId]
                local playerClass = select(2, UnitClass("player"))
                local specIndex = GetSpecialization()
                local specID, specName = specIndex and GetSpecializationInfo(specIndex)
                local playerSpecialization = BCDM:NormalizeSpecToken(specName, specID, specIndex)
                local isWarlock = select(2, UnitClass("player")) == "WARLOCK"
                local isEntryEnabled = entry and entry.isActive and IsEntryEnabledForPlayerSpec(entry, playerClass, playerSpecialization)
                if isEntryEnabled and IsPotionItem(itemId) then
                    RequestDeferredContainerUpdate(self)
                    return
                end
                if not customDB.HideZeroCharges then return end
                if not isEntryEnabled then
                    if isWarlock and (itemId == 224464 or itemId == 5512) then
                        local baseEntry = items[5512]
                        local gluttonyEntry = items[224464]
                        local hasValidBaseEntry = baseEntry and baseEntry.isActive and IsEntryEnabledForPlayerSpec(baseEntry, playerClass, playerSpecialization)
                        local hasValidGluttonyEntry = gluttonyEntry and gluttonyEntry.isActive and IsEntryEnabledForPlayerSpec(gluttonyEntry, playerClass, playerSpecialization)
                        if not (hasValidBaseEntry or hasValidGluttonyEntry) then
                            return
                        end
                    else
                        return
                    end
                end
                local activeItemId = itemId
                if isWarlock and (itemId == 224464 or itemId == 5512) then
                    activeItemId = C_SpellBook.IsSpellKnown(386689) and 224464 or 5512
                end
                local visible = self.VisibleItemIds and self.VisibleItemIds[activeItemId] or false
                local shouldShow = ShouldShowItem(customDB, activeItemId)
                if visible ~= shouldShow then
                    RequestDeferredContainerUpdate(self)
                end
            end
        end)
    end

    local shouldTrackItemCountChanges = CustomDB.HideZeroCharges or HasTrackedPotionEntries(CustomDB.Items)
    if shouldTrackItemCountChanges then
        BCDM.CustomItemBarContainer:RegisterEvent("ITEM_COUNT_CHANGED")
        BCDM.CustomItemBarContainer:RegisterEvent("ITEM_PUSH")
        BCDM.CustomItemBarContainer:RegisterEvent("BAG_UPDATE_DELAYED")
        BCDM.CustomItemBarContainer:RegisterEvent("PLAYER_ENTERING_WORLD")
    else
        BCDM.CustomItemBarContainer:UnregisterEvent("ITEM_COUNT_CHANGED")
        BCDM.CustomItemBarContainer:UnregisterEvent("ITEM_PUSH")
        BCDM.CustomItemBarContainer:UnregisterEvent("BAG_UPDATE_DELAYED")
        BCDM.CustomItemBarContainer:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end

    for _, child in ipairs({BCDM.CustomItemBarContainer:GetChildren()}) do child:UnregisterAllEvents() child:Hide() child:SetParent(nil) end

    CreateCustomIcons(customItemBarIcons, visibleItemIds)
    BCDM.CustomItemBarContainer.VisibleItemIds = visibleItemIds

    local iconWidth, iconHeight = BCDM:GetIconDimensions(CustomDB)
    local iconSpacing = CustomDB.Spacing
    local point = select(1, BCDM.CustomItemBarContainer:GetPoint(1))
    local isHorizontalGrowth = growthDirection == "LEFT" or growthDirection == "RIGHT"
    local wrapLimit = GetColumnWrapLimit(CustomDB)
    local lineLimit = (wrapLimit > 0) and wrapLimit or #customItemBarIcons
    local useCenteredLayout = IsCenteredHorizontalLayout(point, growthDirection)

    if #customItemBarIcons == 0 then
        BCDM.CustomItemBarContainer:SetSize(1, 1)
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
        BCDM.CustomItemBarContainer:SetWidth(totalWidth)
        BCDM.CustomItemBarContainer:SetHeight(totalHeight)
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
                spellIcon:SetParent(BCDM.CustomItemBarContainer)
                spellIcon:SetSize(iconWidth, iconHeight)
                spellIcon:ClearAllPoints()

                local xOffset = startOffset + ((i - rowStart) * (iconWidth + iconSpacing))
                spellIcon:SetPoint("CENTER", BCDM.CustomItemBarContainer, "CENTER", xOffset, yOffset)
                ApplyCooldownText()
                spellIcon:Show()
            end
        end
    else
        for i, spellIcon in ipairs(customItemBarIcons) do
            spellIcon:SetParent(BCDM.CustomItemBarContainer)
            spellIcon:SetSize(iconWidth, iconHeight)
            spellIcon:ClearAllPoints()

            if i == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                spellIcon:SetPoint(config.anchor, BCDM.CustomItemBarContainer, config.anchor, 0, 0)
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
            ApplyCooldownText()
            spellIcon:Show()
        end
    end

    BCDM.CustomItemBarContainer:Show()
end

function BCDM:SetupCustomItemBar()
    LayoutCustomItemBar()
end

function BCDM:UpdateCustomItemBar()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Item
    if BCDM.CustomItemBarContainer then
        BCDM.CustomItemBarContainer:ClearAllPoints()
        local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
        BCDM.CustomItemBarContainer:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    end
    LayoutCustomItemBar()
end

function BCDM:AdjustItemLayoutIndex(direction, itemId)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Item
    local Items = CustomDB.Items

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
    BCDM:NormalizeItemLayoutIndices()

    BCDM:UpdateCustomItemBar()
end

function BCDM:NormalizeItemLayoutIndices()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Item
    local Items = CustomDB.Items

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

function BCDM:AdjustItemList(itemId, adjustingHow)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Item
    local Items = CustomDB.Items

    if not Items then Items = {} end

    if adjustingHow == "add" then
        local maxIndex = 0
        for _, data in pairs(Items) do
            if data.layoutIndex > maxIndex then
                maxIndex = data.layoutIndex
            end
        end
        Items[itemId] = {
            isActive = true,
            layoutIndex = maxIndex + 1,
            classSpecFilters = BCDM:BuildClassSpecFilters(),
        }
    elseif adjustingHow == "remove" then
        Items[itemId] = nil
    end

    BCDM:NormalizeItemLayoutIndices()
    BCDM:UpdateCustomItemBar()
end
