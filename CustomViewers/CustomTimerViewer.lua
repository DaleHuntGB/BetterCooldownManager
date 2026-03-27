local _, BCDM = ...

local FRAME_NAME = "BCDM_CustomTimerBar"
local activeTimerStates = {}
local timerEventFrame

local function GetCustomTimerDB()
    local cooldownManagerDB = BCDM.db and BCDM.db.profile and BCDM.db.profile.CooldownManager
    if not cooldownManagerDB then
        return nil
    end

    cooldownManagerDB.CustomTimer = cooldownManagerDB.CustomTimer or {}
    local customTimerDB = cooldownManagerDB.CustomTimer
    customTimerDB.Entries = customTimerDB.Entries or {}
    customTimerDB.NextEntryId = math.max(tonumber(customTimerDB.NextEntryId) or 1, 1)
    customTimerDB.Enabled = customTimerDB.Enabled ~= false
    customTimerDB.IconSize = customTimerDB.IconSize or 38
    customTimerDB.IconWidth = customTimerDB.IconWidth or customTimerDB.IconSize
    customTimerDB.IconHeight = customTimerDB.IconHeight or customTimerDB.IconSize
    if customTimerDB.KeepAspectRatio == nil then
        customTimerDB.KeepAspectRatio = true
    end
    customTimerDB.FrameStrata = customTimerDB.FrameStrata or "LOW"
    customTimerDB.Layout = customTimerDB.Layout or { "CENTER", "NONE", "CENTER", 0, 0 }
    customTimerDB.Spacing = customTimerDB.Spacing or 1
    customTimerDB.GrowthDirection = customTimerDB.GrowthDirection or "LEFT"
    customTimerDB.Columns = math.max(0, math.floor(customTimerDB.Columns or 0))

    for index, entry in ipairs(customTimerDB.Entries) do
        entry.uid = tonumber(entry.uid) or index
        entry.name = tostring(entry.name or "")
        entry.spellId = tonumber(entry.spellId)
        entry.duration = tonumber(entry.duration) or 0
        if entry.isActive == nil then
            entry.isActive = true
        end
        entry.layoutIndex = tonumber(entry.layoutIndex) or index
    end

    return customTimerDB
end

local function CreateSpellIDCollection(spellID)
    if not spellID then return nil end

    local collection = {}
    collection[spellID] = true

    if C_Spell and C_Spell.GetOverrideSpell then
        local overrideSpell = C_Spell.GetOverrideSpell(spellID)
        if overrideSpell and overrideSpell > 0 then
            collection[overrideSpell] = true
        end
    end

    if C_Spell and C_Spell.GetBaseSpell then
        local baseSpell = C_Spell.GetBaseSpell(spellID)
        if baseSpell and baseSpell > 0 then
            collection[baseSpell] = true
        end
    end

    return collection
end

local function IsMatchingTimerSpell(configuredSpellId, castSpellId)
    local spellCollection = CreateSpellIDCollection(configuredSpellId)
    return spellCollection and castSpellId and spellCollection[castSpellId] or false
end

local function IsTimerStateActive(state, now)
    now = now or GetTime()
    return state and state.startTime and state.duration and state.duration > 0 and (state.startTime + state.duration) > now
end

local function PurgeExpiredCustomTimers()
    local now = GetTime()
    local didChange = false

    for timerUid, state in pairs(activeTimerStates) do
        if not IsTimerStateActive(state, now) then
            activeTimerStates[timerUid] = nil
            didChange = true
        end
    end

    return didChange
end

local function HasActiveCustomTimers()
    for _ in pairs(activeTimerStates) do
        return true
    end
    return false
end

local function UpdateTimerTickerState()
    if not timerEventFrame then
        return
    end

    if HasActiveCustomTimers() then
        if not timerEventFrame:GetScript("OnUpdate") then
            timerEventFrame:SetScript("OnUpdate", function(self, elapsed)
                self.BCDMElapsed = (self.BCDMElapsed or 0) + elapsed
                if self.BCDMElapsed < 0.1 then
                    return
                end

                self.BCDMElapsed = 0
                if PurgeExpiredCustomTimers() then
                    BCDM:UpdateCustomTimerViewer()
                end

                if not HasActiveCustomTimers() then
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
    else
        timerEventFrame:SetScript("OnUpdate", nil)
        timerEventFrame.BCDMElapsed = 0
    end
end

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
    local cooldownManagerDB = BCDM.db.profile.CooldownManager
    local generalDB = BCDM.db.profile.General
    local cooldownTextDB = cooldownManagerDB.General.CooldownText
    if not viewer then return end

    local icons = viewer.ActiveIcons or { viewer:GetChildren() }
    for _, icon in ipairs(icons) do
        if icon and icon.Cooldown then
            local textRegion = FetchCooldownTextRegion(icon.Cooldown)
            if textRegion then
                if cooldownTextDB.ScaleByIconSize then
                    local iconWidth = icon:GetWidth()
                    local scaleFactor = iconWidth / 36
                    textRegion:SetFont(BCDM.Media.Font, cooldownTextDB.FontSize * scaleFactor, generalDB.Fonts.FontFlag)
                else
                    textRegion:SetFont(BCDM.Media.Font, cooldownTextDB.FontSize, generalDB.Fonts.FontFlag)
                end

                textRegion:SetTextColor(cooldownTextDB.Colour[1], cooldownTextDB.Colour[2], cooldownTextDB.Colour[3], 1)
                textRegion:ClearAllPoints()
                textRegion:SetPoint(cooldownTextDB.Layout[1], icon, cooldownTextDB.Layout[2], cooldownTextDB.Layout[3], cooldownTextDB.Layout[4])

                if generalDB.Fonts.Shadow.Enabled then
                    textRegion:SetShadowColor(
                        generalDB.Fonts.Shadow.Colour[1],
                        generalDB.Fonts.Shadow.Colour[2],
                        generalDB.Fonts.Shadow.Colour[3],
                        generalDB.Fonts.Shadow.Colour[4]
                    )
                    textRegion:SetShadowOffset(generalDB.Fonts.Shadow.OffsetX, generalDB.Fonts.Shadow.OffsetY)
                else
                    textRegion:SetShadowColor(0, 0, 0, 0)
                    textRegion:SetShadowOffset(0, 0)
                end
            end
        end
    end
end

local function BuildCustomTimerStyleSignature(customDB)
    local cooldownManagerDB = BCDM.db.profile.CooldownManager
    local generalDB = BCDM.db.profile.General
    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)

    return table.concat({
        tostring(iconWidth or ""),
        tostring(iconHeight or ""),
        tostring(customDB.KeepAspectRatio and 1 or 0),
        tostring(customDB.FrameStrata or ""),
        tostring(cooldownManagerDB.General.BorderSize or ""),
        tostring(cooldownManagerDB.General.IconZoom or ""),
        tostring(BCDM.Media and BCDM.Media.Font or ""),
        tostring(generalDB.Fonts and generalDB.Fonts.FontFlag or ""),
        tostring(cooldownManagerDB.General.CooldownText and cooldownManagerDB.General.CooldownText.FontSize or ""),
    }, "::")
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

local function CreateCustomTimerIcon(customDB, entry)
    local spellData = entry and entry.spellId and C_Spell.GetSpellInfo(entry.spellId)
    if not spellData then
        return nil
    end

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
    customIcon.BCDMIconType = "spell"
    customIcon.BCDMSpellId = entry.spellId
    customIcon.BCDMTimerUid = entry.uid

    customIcon.Cooldown = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
    customIcon.Cooldown:SetAllPoints(customIcon)
    customIcon.Cooldown:SetDrawEdge(false)
    customIcon.Cooldown:SetDrawSwipe(true)
    customIcon.Cooldown:SetDrawBling(false)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(true)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)
    customIcon.Icon:SetTexture(spellData.iconID)
    customIcon.Icon:SetVertexColor(1, 1, 1)

    customIcon.BCDMActivate = function(self)
        if self.BCDMIsActive then
            return
        end

        self.BCDMIsActive = true
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

    customIcon.BCDMRefresh = function(self, timerState)
        if not timerState then
            self.Cooldown:SetCooldownFromDurationObject(C_DurationUtil.CreateDuration(), true)
            return
        end

        local durationObject = C_DurationUtil.CreateDuration()
        durationObject:SetTimeFromStart(timerState.startTime, timerState.duration)
        self.Cooldown:SetCooldownFromDurationObject(durationObject, true)
    end

    customIcon:BCDMActivate()

    return customIcon
end

local function ActivateCachedIcon(customIcon)
    if customIcon and customIcon.BCDMActivate then
        customIcon:BCDMActivate()
    end
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

local function ReleaseTimerIcons(container)
    if not container then
        return
    end

    if container.IconCache then
        for _, customIcon in pairs(container.IconCache) do
            DeactivateCachedIcon(customIcon)
        end
        wipe(container.IconCache)
    end

    container.ActiveIcons = nil
    container.StyleSignature = nil
end

local function HideUnusedTimerIcons(container, activeIconKeys)
    if not container or not container.IconCache then
        return
    end

    for cacheKey, customIcon in pairs(container.IconCache) do
        if not activeIconKeys[cacheKey] then
            DeactivateCachedIcon(customIcon)
        end
    end
end

local function GetOrCreateTimerIcon(container, customDB, entry)
    container.IconCache = container.IconCache or {}
    local cacheKey = "timer:" .. tostring(entry.uid or entry.spellId)

    local customIcon = container.IconCache[cacheKey]
    if customIcon then
        ActivateCachedIcon(customIcon)
        return customIcon, cacheKey
    end

    customIcon = CreateCustomTimerIcon(customDB, entry)
    if customIcon then
        container.IconCache[cacheKey] = customIcon
    end

    return customIcon, cacheKey
end

function BCDM:GetCustomTimerEntries()
    local customTimerDB = GetCustomTimerDB()
    return customTimerDB and customTimerDB.Entries or {}
end

function BCDM:GetSortedCustomTimerEntries()
    local ordered = {}
    for _, entry in ipairs(self:GetCustomTimerEntries()) do
        ordered[#ordered + 1] = entry
    end

    table.sort(ordered, function(a, b)
        if a.layoutIndex == b.layoutIndex then
            return (tonumber(a.uid) or 0) < (tonumber(b.uid) or 0)
        end
        return (tonumber(a.layoutIndex) or math.huge) < (tonumber(b.layoutIndex) or math.huge)
    end)

    return ordered
end

function BCDM:NormalizeCustomTimerLayoutIndices()
    for index, entry in ipairs(self:GetSortedCustomTimerEntries()) do
        entry.layoutIndex = index
    end
end

function BCDM:AddCustomTimerEntry(name, spellId, duration)
    local customTimerDB = GetCustomTimerDB()
    spellId = tonumber(spellId)
    duration = tonumber(duration)
    if not customTimerDB or not spellId or not duration or duration <= 0 then
        return nil
    end

    local spellData = C_Spell.GetSpellInfo(spellId)
    if not spellData then
        return nil
    end

    local uid = customTimerDB.NextEntryId
    customTimerDB.NextEntryId = uid + 1
    customTimerDB.Entries[#customTimerDB.Entries + 1] = {
        uid = uid,
        name = strtrim(name or "") ~= "" and strtrim(name) or spellData.name,
        spellId = spellId,
        duration = duration,
        isActive = true,
        layoutIndex = #customTimerDB.Entries + 1,
    }

    self:NormalizeCustomTimerLayoutIndices()
    self:UpdateCustomTimerViewer()

    return uid
end

function BCDM:RemoveCustomTimerEntry(entryUid)
    local customTimerDB = GetCustomTimerDB()
    if not customTimerDB then
        return
    end

    for index, entry in ipairs(customTimerDB.Entries) do
        if entry.uid == tonumber(entryUid) then
            table.remove(customTimerDB.Entries, index)
            activeTimerStates[tonumber(entryUid)] = nil
            break
        end
    end

    self:NormalizeCustomTimerLayoutIndices()
    self:UpdateCustomTimerViewer()
    UpdateTimerTickerState()
end

function BCDM:SetCustomTimerEntryActive(entryUid, isActive)
    for _, entry in ipairs(self:GetCustomTimerEntries()) do
        if entry.uid == tonumber(entryUid) then
            entry.isActive = isActive and true or false
            if not entry.isActive then
                activeTimerStates[entry.uid] = nil
            end
            break
        end
    end

    self:UpdateCustomTimerViewer()
    UpdateTimerTickerState()
end

function BCDM:AdjustCustomTimerLayoutIndex(direction, entryUid)
    local entries = self:GetCustomTimerEntries()
    local currentIndex
    for _, entry in ipairs(entries) do
        if entry.uid == tonumber(entryUid) then
            currentIndex = entry.layoutIndex
            break
        end
    end

    if not currentIndex then
        return
    end

    local newIndex = currentIndex + direction
    if newIndex < 1 or newIndex > #entries then
        return
    end

    for _, entry in ipairs(entries) do
        if entry.layoutIndex == newIndex then
            entry.layoutIndex = currentIndex
            break
        end
    end

    for _, entry in ipairs(entries) do
        if entry.uid == tonumber(entryUid) then
            entry.layoutIndex = newIndex
            break
        end
    end

    self:NormalizeCustomTimerLayoutIndices()
    self:UpdateCustomTimerViewer()
end

function BCDM:GetCustomTimerEntry(entryUid)
    for _, entry in ipairs(self:GetCustomTimerEntries()) do
        if entry.uid == tonumber(entryUid) then
            return entry
        end
    end
end

local function CreateActiveTimerIcons(container, customDB)
    local activeIcons = {}
    local activeIconKeys = {}
    local now = GetTime()

    for _, entry in ipairs(BCDM:GetSortedCustomTimerEntries()) do
        local timerState = activeTimerStates[entry.uid]
        if entry.isActive and IsTimerStateActive(timerState, now) then
            local customIcon, cacheKey = GetOrCreateTimerIcon(container, customDB, entry)
            if customIcon then
                customIcon.BCDMSpellId = entry.spellId
                customIcon.BCDMRefresh(customIcon, timerState)
                activeIcons[#activeIcons + 1] = customIcon
                activeIconKeys[cacheKey] = true
            end
        end
    end

    return activeIcons, activeIconKeys
end

local function LayoutCustomTimerViewer()
    local customDB = GetCustomTimerDB()
    if not customDB then
        return
    end

    if not BCDM.CustomTimerContainer then
        BCDM.CustomTimerContainer = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
        BCDM.CustomTimerContainer:SetSize(1, 1)
    end

    local container = BCDM.CustomTimerContainer
    local styleSignature = BuildCustomTimerStyleSignature(customDB)
    if container.StyleSignature ~= styleSignature then
        ReleaseTimerIcons(container)
        container.IconCache = {}
        container.StyleSignature = styleSignature
    end

    container.IconCache = container.IconCache or {}
    container:ClearAllPoints()
    container:SetFrameStrata(customDB.FrameStrata or "LOW")
    local anchorParent = BCDM:ResolveAnchorFrame(customDB.Layout[2])
    container:SetPoint(customDB.Layout[1], anchorParent, customDB.Layout[3], customDB.Layout[4], customDB.Layout[5])

    local activeIcons, activeIconKeys = CreateActiveTimerIcons(container, customDB)
    HideUnusedTimerIcons(container, activeIconKeys)
    container.ActiveIcons = activeIcons

    local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
    local iconSpacing = customDB.Spacing or 0
    local point = select(1, container:GetPoint(1))
    local growthDirection = customDB.GrowthDirection or "RIGHT"
    local isHorizontalGrowth = growthDirection == "LEFT" or growthDirection == "RIGHT"
    local wrapLimit = GetColumnWrapLimit(customDB)
    local lineLimit = (wrapLimit > 0) and wrapLimit or math.max(#activeIcons, 1)
    local useCenteredLayout = IsCenteredHorizontalLayout(point, growthDirection)

    if #activeIcons == 0 or not customDB.Enabled then
        container:SetSize(1, 1)
        container:Hide()
        ApplyCooldownText(container)
        return
    end

    local lineCount = math.ceil(#activeIcons / lineLimit)
    if isHorizontalGrowth then
        local columnsInRow = math.min(lineLimit, #activeIcons)
        container:SetWidth((columnsInRow * iconWidth) + ((columnsInRow - 1) * iconSpacing))
        container:SetHeight((lineCount * iconHeight) + ((lineCount - 1) * iconSpacing))
    else
        local rowsInColumn = math.min(lineLimit, #activeIcons)
        container:SetWidth((lineCount * iconWidth) + ((lineCount - 1) * iconSpacing))
        container:SetHeight((rowsInColumn * iconHeight) + ((rowsInColumn - 1) * iconSpacing))
    end

    local LayoutConfig = {
        TOPLEFT = { anchor = "TOPLEFT" },
        TOP = { anchor = "TOP" },
        TOPRIGHT = { anchor = "TOPRIGHT" },
        BOTTOMLEFT = { anchor = "BOTTOMLEFT" },
        BOTTOM = { anchor = "BOTTOM" },
        BOTTOMRIGHT = { anchor = "BOTTOMRIGHT" },
        LEFT = { anchor = "LEFT" },
        RIGHT = { anchor = "RIGHT" },
        CENTER = { anchor = "CENTER" },
    }

    if useCenteredLayout then
        local rowCount = math.ceil(#activeIcons / lineLimit)
        local rowDirection = ShouldGrowUp(point) and 1 or -1

        for rowIndex = 1, rowCount do
            local rowStart = ((rowIndex - 1) * lineLimit) + 1
            local rowEnd = math.min(rowStart + lineLimit - 1, #activeIcons)
            local rowIcons = rowEnd - rowStart + 1
            local rowWidth = (rowIcons * iconWidth) + ((rowIcons - 1) * iconSpacing)
            local startOffset = -(rowWidth / 2) + (iconWidth / 2)
            local yOffset = (rowIndex - 1) * (iconHeight + iconSpacing) * rowDirection

            for i = rowStart, rowEnd do
                local timerIcon = activeIcons[i]
                timerIcon:SetParent(container)
                timerIcon:SetSize(iconWidth, iconHeight)
                timerIcon:ClearAllPoints()
                timerIcon:SetPoint("CENTER", container, "CENTER", startOffset + ((i - rowStart) * (iconWidth + iconSpacing)), yOffset)
                timerIcon:Show()
            end
        end
    else
        for index, timerIcon in ipairs(activeIcons) do
            timerIcon:SetParent(container)
            timerIcon:SetSize(iconWidth, iconHeight)
            timerIcon:ClearAllPoints()

            if index == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                timerIcon:SetPoint(config.anchor, container, config.anchor, 0, 0)
            else
                local isWrappedRowStart = (index - 1) % lineLimit == 0
                if isWrappedRowStart then
                    local lineAnchorIcon = activeIcons[index - lineLimit]
                    if isHorizontalGrowth then
                        if ShouldGrowUp(point) then
                            timerIcon:SetPoint("BOTTOM", lineAnchorIcon, "TOP", 0, iconSpacing)
                        else
                            timerIcon:SetPoint("TOP", lineAnchorIcon, "BOTTOM", 0, -iconSpacing)
                        end
                    else
                        if ShouldGrowLeft(point) then
                            timerIcon:SetPoint("RIGHT", lineAnchorIcon, "LEFT", -iconSpacing, 0)
                        else
                            timerIcon:SetPoint("LEFT", lineAnchorIcon, "RIGHT", iconSpacing, 0)
                        end
                    end
                else
                    if growthDirection == "RIGHT" then
                        timerIcon:SetPoint("LEFT", activeIcons[index - 1], "RIGHT", iconSpacing, 0)
                    elseif growthDirection == "LEFT" then
                        timerIcon:SetPoint("RIGHT", activeIcons[index - 1], "LEFT", -iconSpacing, 0)
                    elseif growthDirection == "UP" then
                        timerIcon:SetPoint("BOTTOM", activeIcons[index - 1], "TOP", 0, iconSpacing)
                    elseif growthDirection == "DOWN" then
                        timerIcon:SetPoint("TOP", activeIcons[index - 1], "BOTTOM", 0, -iconSpacing)
                    end
                end
            end

            timerIcon:Show()
        end
    end

    ApplyCooldownText(container)
    container:Show()
end

function BCDM:HandleCustomTimerSpellCast(spellId)
    spellId = tonumber(spellId)
    local customDB = GetCustomTimerDB()
    if not spellId or not customDB or customDB.Enabled == false then
        return
    end

    local didStartTimer = false
    for _, entry in ipairs(self:GetCustomTimerEntries()) do
        if entry.isActive and tonumber(entry.duration) and entry.duration > 0 and IsMatchingTimerSpell(entry.spellId, spellId) then
            activeTimerStates[entry.uid] = {
                startTime = GetTime(),
                duration = tonumber(entry.duration),
            }
            didStartTimer = true
        end
    end

    if didStartTimer then
        self:UpdateCustomTimerViewer()
        UpdateTimerTickerState()
    end
end

function BCDM:SetupCustomTimerViewer()
    GetCustomTimerDB()

    if not timerEventFrame then
        timerEventFrame = CreateFrame("Frame")
        timerEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        timerEventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        timerEventFrame:SetScript("OnEvent", function(_, event, ...)
            if event == "UNIT_SPELLCAST_SUCCEEDED" then
                local unit, _, spellId = ...
                if unit ~= "player" then
                    return
                end
                BCDM:HandleCustomTimerSpellCast(spellId)
                return
            end

            PurgeExpiredCustomTimers()
            BCDM:UpdateCustomTimerViewer()
            UpdateTimerTickerState()
        end)
    end

    self:UpdateCustomTimerViewer()
    UpdateTimerTickerState()
end

function BCDM:UpdateCustomTimerViewer()
    GetCustomTimerDB()
    PurgeExpiredCustomTimers()
    LayoutCustomTimerViewer()
    UpdateTimerTickerState()
end
