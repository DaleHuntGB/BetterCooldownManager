local _, BCDM = ...

local TRINKET_SLOTS = { 13, 14 }

local trinketBarUpdatePending = false

local function RefreshAppendedAnchorDependents()
    if BCDM.UpdatePowerBar then
        BCDM:UpdatePowerBar()
    end
    if BCDM.UpdateSecondaryPowerBar then
        BCDM:UpdateSecondaryPowerBar()
    end
    if BCDM.UpdateCastBar then
        BCDM:UpdateCastBar()
    end
end

local function RefreshTrinketAnchorConsumers()
    if BCDM.RefreshCooldownManagerViewerPositions then
        BCDM:RefreshCooldownManagerViewerPositions()
    end
    if BCDM.RefreshExternalCDMAnchors then
        BCDM:RefreshExternalCDMAnchors()
    end
    if BCDM.RefreshCooldownViewerOverlays then
        BCDM:RefreshCooldownViewerOverlays()
    end
end

local function RefreshTrinketCustomViewerAnchors()
    if BCDM.UpdateCustomViewer then
        BCDM:UpdateCustomViewer()
    end
end

local function GetAppendTarget()
    local CustomDB = BCDM.db.profile.CooldownManager.Trinket
    return CustomDB and CustomDB.AppendTo or "NONE"
end

local function GetAppendSide()
    local CustomDB = BCDM.db.profile.CooldownManager.Trinket
    return (CustomDB and CustomDB.AppendSide) or "RIGHT"
end

local function BuildTrinketAnchorRefreshKey(customDB, effectiveLayout, visibleCount)
    local appendTargetViewer = BCDM:GetTrinketAppendTargetViewerName()
    if appendTargetViewer and visibleCount > 0 then
        return table.concat({
            "append",
            appendTargetViewer,
            GetAppendSide(),
            visibleCount,
            effectiveLayout.iconWidth,
            effectiveLayout.iconHeight,
            effectiveLayout.iconSpacing,
        }, ":")
    end

    return table.concat({
        "standalone",
        customDB.Layout[1] or "TOPLEFT",
        customDB.Layout[2] or "NONE",
        customDB.Layout[3] or "TOPLEFT",
        customDB.Layout[4] or 0,
        customDB.Layout[5] or 0,
        effectiveLayout.growthDirection or "RIGHT",
        visibleCount,
        effectiveLayout.iconWidth,
        effectiveLayout.iconHeight,
        effectiveLayout.iconSpacing,
    }, ":")
end

local function BuildTrinketAppendStateKey(visibleCount)
    local appendTargetViewer = BCDM:GetTrinketAppendTargetViewerName()
    if appendTargetViewer and visibleCount > 0 then
        return appendTargetViewer
    end
    return "NONE"
end

local function RefreshTrinketDependents(container, anchorRefreshKey, appendStateKey)
    if not container then return end

    local anchorChanged = container.LastAnchorRefreshKey ~= anchorRefreshKey
    local appendStateChanged = container.LastAppendStateKey ~= appendStateKey

    container.LastAnchorRefreshKey = anchorRefreshKey
    container.LastAppendStateKey = appendStateKey

    if anchorChanged then
        RefreshTrinketAnchorConsumers()
        RefreshAppendedAnchorDependents()
    end

    if appendStateChanged then
        RefreshTrinketCustomViewerAnchors()
    end
end

local function ShouldShowPassiveTrinkets()
    local CustomDB = BCDM.db.profile.CooldownManager.Trinket
    return CustomDB.ShowPassive ~= false
end

local function ResolveTrinketAnchorParent(layoutParent)
    if layoutParent == "NONE" or not layoutParent or not _G[layoutParent] then
        return UIParent
    end
    return _G[layoutParent]
end

function BCDM:GetTrinketAppendTargetViewerName()
    local appendTarget = GetAppendTarget()
    if appendTarget == "Essential" then
        return "EssentialCooldownViewer"
    elseif appendTarget == "Utility" then
        return "UtilityCooldownViewer"
    end
    return nil
end

function BCDM:IsTrinketBarAppendedToViewer(viewerType)
    local appendTarget = GetAppendTarget()
    return appendTarget ~= "NONE" and appendTarget == viewerType
end

local function GetAppendedViewerDB()
    local appendTarget = GetAppendTarget()
    if appendTarget ~= "Essential" and appendTarget ~= "Utility" then
        return nil, nil
    end

    local viewerName = BCDM.DBViewerToCooldownManagerViewer[appendTarget]
    return BCDM.db.profile.CooldownManager[appendTarget], viewerName and _G[viewerName]
end

local function GetViewerReferenceIconSize(viewerFrame, viewerDB)
    if viewerFrame then
        local childCount = viewerFrame:GetNumChildren()
        for i = 1, childCount do
            local childFrame = select(i, viewerFrame:GetChildren())
            if childFrame and childFrame.Icon then
                local width = childFrame:GetWidth()
                local height = childFrame:GetHeight()
                if width and width > 0 and height and height > 0 then
                    return width, height
                end
            end
        end
    end

    return BCDM:GetIconDimensions(viewerDB)
end

local function GetEffectiveTrinketLayout(customDB)
    local growthDirection = customDB.GrowthDirection or "RIGHT"
    local appendedViewerDB, appendedViewerFrame = GetAppendedViewerDB()
    if not appendedViewerDB then
        local iconWidth, iconHeight = BCDM:GetIconDimensions(customDB)
        return {
            growthDirection = growthDirection,
            iconWidth = iconWidth,
            iconHeight = iconHeight,
            iconSpacing = customDB.Spacing or 0,
            frameStrata = customDB.FrameStrata or "LOW",
        }
    end

    growthDirection = GetAppendSide()

    local iconWidth, iconHeight = GetViewerReferenceIconSize(appendedViewerFrame, appendedViewerDB)
    local iconSpacing = customDB.Spacing or 0
    if appendedViewerFrame then
        iconSpacing = appendedViewerFrame.childXPadding or iconSpacing
    end

    return {
        growthDirection = growthDirection,
        iconWidth = iconWidth,
        iconHeight = iconHeight,
        iconSpacing = iconSpacing,
        frameStrata = (appendedViewerFrame and appendedViewerFrame:GetFrameStrata()) or appendedViewerDB.FrameStrata or customDB.FrameStrata or "LOW",
    }
end

local function PositionAppendedTrinketBar(container, customDB, gap)
    local viewerName = BCDM:GetTrinketAppendTargetViewerName()
    local viewerFrame = viewerName and _G[viewerName]
    if not viewerFrame then
        return false
    end

    local growthDirection = GetAppendSide()
    gap = gap or customDB.Spacing or 0

    container:ClearAllPoints()
    if growthDirection == "LEFT" then
        container:SetPoint("RIGHT", viewerFrame, "LEFT", -gap, 0)
    else
        container:SetPoint("LEFT", viewerFrame, "RIGHT", gap, 0)
    end

    return true
end

local function EnsureTrinketContainer()
    if BCDM.TrinketBarContainer then
        return BCDM.TrinketBarContainer
    end

    local container = CreateFrame("Frame", "BCDM_TrinketBar", UIParent, "BackdropTemplate")
    container:SetSize(1, 1)
    BCDM.TrinketBarContainer = container
    return container
end

local function CreateTrinketIcon(slotID)
    local customIcon = CreateFrame("Button", nil, EnsureTrinketContainer(), "BackdropTemplate")
    customIcon.slotID = slotID
    customIcon.itemId = nil
    customIcon.isOnUse = false

    local highLevelContainer = CreateFrame("Frame", nil, customIcon)
    highLevelContainer:SetAllPoints(customIcon)
    highLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

    customIcon.Cooldown = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
    customIcon.Cooldown:SetAllPoints(customIcon)
    customIcon.Cooldown:SetDrawEdge(false)
    customIcon.Cooldown:SetDrawSwipe(true)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)
    customIcon.Cooldown:SetDrawBling(false)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    customIcon:EnableMouse(false)

    return customIcon
end

local function EnsureTrinketIcons()
    BCDM.TrinketBarFrames = BCDM.TrinketBarFrames or {}

    for _, slotID in ipairs(TRINKET_SLOTS) do
        if not BCDM.TrinketBarFrames[slotID] then
            BCDM.TrinketBarFrames[slotID] = CreateTrinketIcon(slotID)
        end
    end

    return BCDM.TrinketBarFrames
end

local function UpdateTrinketData(frame)
    if not frame then return end

    local itemId = GetInventoryItemID("player", frame.slotID)
    frame.itemId = itemId
    frame.isOnUse = false

    if not itemId then
        frame.Icon:SetTexture(nil)
        return
    end

    frame.Icon:SetTexture(C_Item.GetItemIconByID(itemId))
    frame.isOnUse = BCDM:IsOnUseTrinket(itemId)
end

local function ApplyTrinketFrameStyle(frame, frameStrata, iconWidth, iconHeight)
    if not frame then return end

    frame:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    frame:SetBackdropColor(0, 0, 0, 0)

    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    else
        frame:SetBackdropBorderColor(0, 0, 0, 1)
    end

    frame:SetFrameStrata(frameStrata or "LOW")
    frame:SetSize(iconWidth, iconHeight)

    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    frame.Icon:ClearAllPoints()
    frame.Icon:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
    frame.Icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)

    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    BCDM:ApplyIconTexCoord(frame.Icon, iconWidth, iconHeight, iconZoom)
end

local function UpdateTrinketCooldown(frame)
    if not frame or not frame.Cooldown or not frame.Icon then return end

    local hasActiveCooldown = false
    local startTime, durationTime, enable

    if frame.itemId and frame.isOnUse then
        startTime, durationTime, enable = GetInventoryItemCooldown("player", frame.slotID)
        hasActiveCooldown = startTime and durationTime and durationTime > 1.5 and enable == 1
    end

    local shouldRefresh = BCDM:ShouldRefreshCooldownFrame(frame.Cooldown, hasActiveCooldown, startTime, durationTime)
    if shouldRefresh then
        if hasActiveCooldown then
            frame.Cooldown:SetCooldown(startTime, durationTime)
        else
            frame.Cooldown:SetCooldown(0, 0)
        end
    end

    BCDM:SetIconDesaturation(frame.Icon, hasActiveCooldown and 1 or 0)
end

local function UpdateVisibleTrinketCooldowns()
    local frames = BCDM.TrinketBarFrames
    if not frames then return end

    for _, slotID in ipairs(TRINKET_SLOTS) do
        local frame = frames[slotID]
        if frame and frame:IsShown() then
            UpdateTrinketCooldown(frame)
        end
    end
end

local function RequestDeferredTrinketBarUpdate()
    if trinketBarUpdatePending then return end
    trinketBarUpdatePending = true

    C_Timer.After(0, function()
        trinketBarUpdatePending = false
        BCDM:UpdateTrinketBar()
    end)
end

local function HandleTrinketBarEvent(_, event, slotID)
    local CustomDB = BCDM.db.profile.CooldownManager.Trinket
    if not CustomDB or not CustomDB.Enabled then
        if BCDM.TrinketBarContainer then
            BCDM.TrinketBarContainer:Hide()
        end
        return
    end

    if event == "SPELL_UPDATE_COOLDOWN" then
        UpdateVisibleTrinketCooldowns()
        return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" and slotID ~= 13 and slotID ~= 14 then
        return
    end

    RequestDeferredTrinketBarUpdate()
end

local function EnsureTrinketBarEventFrame()
    if BCDM.TrinketBarEventFrame then
        return BCDM.TrinketBarEventFrame
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:SetScript("OnEvent", HandleTrinketBarEvent)

    BCDM.TrinketBarEventFrame = eventFrame
    return eventFrame
end

local function LayoutTrinketBar()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Trinket
    local showPassive = ShouldShowPassiveTrinkets()
    local effectiveLayout = GetEffectiveTrinketLayout(CustomDB)
    local growthDirection = effectiveLayout.growthDirection
    local container = EnsureTrinketContainer()
    local frames = EnsureTrinketIcons()
    local visibleIcons = {}
    local anchorRefreshKey
    local appendStateKey

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

    container:SetFrameStrata(effectiveLayout.frameStrata)
    if not PositionAppendedTrinketBar(container, CustomDB, effectiveLayout.iconSpacing) then
        container:ClearAllPoints()
        container:SetPoint(containerAnchorFrom, ResolveTrinketAnchorParent(CustomDB.Layout[2]), CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    end

    local iconWidth, iconHeight = effectiveLayout.iconWidth, effectiveLayout.iconHeight
    local iconSpacing = effectiveLayout.iconSpacing

    for _, slotID in ipairs(TRINKET_SLOTS) do
        local frame = frames[slotID]
        frame:SetParent(container)
        UpdateTrinketData(frame)
        ApplyTrinketFrameStyle(frame, effectiveLayout.frameStrata, iconWidth, iconHeight)

        if frame.itemId and (showPassive or frame.isOnUse) then
            frame:Show()
            table.insert(visibleIcons, frame)
        else
            frame:Hide()
            frame.Cooldown:SetCooldown(0, 0)
            BCDM:SetIconDesaturation(frame.Icon, 0)
        end
    end

    if #visibleIcons == 0 then
        container:SetSize(1, 1)
        container:Hide()
        anchorRefreshKey = "hidden"
        appendStateKey = "NONE"
        RefreshTrinketDependents(container, anchorRefreshKey, appendStateKey)
        return
    end

    local point = select(1, container:GetPoint(1))
    local useCenteredLayout = (point == "TOP" or point == "BOTTOM") and (growthDirection == "LEFT" or growthDirection == "RIGHT")

    local totalWidth, totalHeight = 0, 0
    if useCenteredLayout or growthDirection == "RIGHT" or growthDirection == "LEFT" then
        totalWidth = (#visibleIcons * iconWidth) + ((#visibleIcons - 1) * iconSpacing)
        totalHeight = iconHeight
    elseif growthDirection == "UP" or growthDirection == "DOWN" then
        totalWidth = iconWidth
        totalHeight = (#visibleIcons * iconHeight) + ((#visibleIcons - 1) * iconSpacing)
    end
    container:SetSize(totalWidth, totalHeight)

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
        local startOffset = -(totalWidth / 2) + (iconWidth / 2)
        for index, iconFrame in ipairs(visibleIcons) do
            iconFrame:ClearAllPoints()
            local xOffset = startOffset + ((index - 1) * (iconWidth + iconSpacing))
            iconFrame:SetPoint("CENTER", container, "CENTER", xOffset, 0)
        end
    else
        for index, iconFrame in ipairs(visibleIcons) do
            iconFrame:ClearAllPoints()
            if index == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                iconFrame:SetPoint(config.anchor, container, config.anchor, 0, 0)
            elseif growthDirection == "RIGHT" then
                iconFrame:SetPoint("LEFT", visibleIcons[index - 1], "RIGHT", iconSpacing, 0)
            elseif growthDirection == "LEFT" then
                iconFrame:SetPoint("RIGHT", visibleIcons[index - 1], "LEFT", -iconSpacing, 0)
            elseif growthDirection == "UP" then
                iconFrame:SetPoint("BOTTOM", visibleIcons[index - 1], "TOP", 0, iconSpacing)
            elseif growthDirection == "DOWN" then
                iconFrame:SetPoint("TOP", visibleIcons[index - 1], "BOTTOM", 0, -iconSpacing)
            end
        end
    end

    BCDM:ApplyCooldownText("BCDM_TrinketBar")
    UpdateVisibleTrinketCooldowns()
    container:Show()
    anchorRefreshKey = BuildTrinketAnchorRefreshKey(CustomDB, effectiveLayout, #visibleIcons)
    appendStateKey = BuildTrinketAppendStateKey(#visibleIcons)
    RefreshTrinketDependents(container, anchorRefreshKey, appendStateKey)
end

function BCDM:SetupTrinketBar()
    EnsureTrinketBarEventFrame()
    LayoutTrinketBar()
end

function BCDM:UpdateTrinketBar()
    local CustomDB = BCDM.db.profile.CooldownManager.Trinket
    if not CustomDB or not CustomDB.Enabled then
        if BCDM.TrinketBarContainer then
            BCDM.TrinketBarContainer:Hide()
            RefreshTrinketDependents(BCDM.TrinketBarContainer, "hidden", "NONE")
        end
        return
    end

    EnsureTrinketBarEventFrame()
    LayoutTrinketBar()
end
