local _, BCDM = ...
local pendingViewerPositionRefresh

local function ShouldSkin()
    if not BCDM.db.profile.CooldownManager.Enable then return false end
    if C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI[1].private.skins.blizzard.cooldownManager then return false end
    if C_AddOns.IsAddOnLoaded("MasqueBlizzBars") then return false end
    return true
end

local function NudgeViewer(viewerName, xOffset, yOffset)
    local viewerFrame = _G[viewerName]
    if not viewerFrame then return end
    local point, relativeTo, relativePoint, currentX, currentY = viewerFrame:GetPoint(1)
    viewerFrame:ClearAllPoints()
    viewerFrame:SetPoint(point, relativeTo, relativePoint, currentX + xOffset, currentY + yOffset)
end

local function PositionViewer(viewerName)
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local viewerSettings = cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]]
    local viewerFrame = _G[viewerName]
    if not viewerFrame or not viewerSettings then return end

    viewerFrame:ClearAllPoints()
    if viewerName == "UtilityCooldownViewer" or viewerName == "BuffIconCooldownViewer" then
        local anchorParent = viewerSettings.Layout[2] == "NONE" and UIParent or (BCDM.GetEffectiveAnchorFrame and BCDM:GetEffectiveAnchorFrame(viewerSettings.Layout[2])) or _G[viewerSettings.Layout[2]]
        viewerFrame:SetPoint(viewerSettings.Layout[1], anchorParent, viewerSettings.Layout[3], viewerSettings.Layout[4], viewerSettings.Layout[5])
    else
        viewerFrame:SetPoint(viewerSettings.Layout[1], UIParent, viewerSettings.Layout[2], viewerSettings.Layout[3], viewerSettings.Layout[4])
    end
    viewerFrame:SetFrameStrata("LOW")
    NudgeViewer(viewerName, -0.1, 0)
end

local function Position()
    PositionViewer("EssentialCooldownViewer")
    if BCDM.RefreshAppendedViewerPosition then
        BCDM:RefreshAppendedViewerPosition("Essential")
    end

    PositionViewer("UtilityCooldownViewer")
    if BCDM.RefreshAppendedViewerPosition then
        BCDM:RefreshAppendedViewerPosition("Utility")
    end

    PositionViewer("BuffIconCooldownViewer")
end

local function StyleViewerIcons(viewerName)
    if not ShouldSkin() then return end

    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local viewerSettings = cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]]
    local viewerFrame = _G[viewerName]
    if not viewerFrame or not viewerSettings then return end

    local iconWidth, iconHeight = BCDM:GetIconDimensions(viewerSettings)
    local borderSize = cooldownManagerSettings.General.BorderSize
    local iconZoomAmount = cooldownManagerSettings.General.IconZoom * 0.5
    local childCount = viewerFrame:GetNumChildren()

    for i = 1, childCount do
        local childFrame = select(i, viewerFrame:GetChildren())
        if childFrame then
            if childFrame.Icon then
                BCDM:StripTextures(childFrame.Icon)
                BCDM:ApplyIconTexCoord(childFrame.Icon, iconWidth, iconHeight, iconZoomAmount)
            end
            if childFrame.Cooldown then
                childFrame.Cooldown:ClearAllPoints()
                childFrame.Cooldown:SetPoint("TOPLEFT", childFrame, "TOPLEFT", borderSize, -borderSize)
                childFrame.Cooldown:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", -borderSize, borderSize)
                childFrame.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
                childFrame.Cooldown:SetDrawEdge(false)
                childFrame.Cooldown:SetDrawSwipe(true)
                childFrame.Cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
            end
            if childFrame.CooldownFlash then childFrame.CooldownFlash:SetAlpha(0) end
            if childFrame.DebuffBorder then childFrame.DebuffBorder:SetAlpha(0) end
            childFrame:SetSize(iconWidth, iconHeight)
            BCDM:AddBorder(childFrame)
            if not childFrame.layoutIndex then childFrame:SetShown(false) end
        end
    end
end

local function StyleIcons()
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        StyleViewerIcons(viewerName)
    end
end

local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() if InCombatLockdown() then return end BCDM:RefreshCooldownManagerViewerPositions() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() if InCombatLockdown() then return end BCDM.LEMO:LoadLayouts() BCDM:RefreshCooldownManagerViewerPositions() end)
    hooksecurefunc(CooldownViewerSettings, "RefreshLayout", function() if InCombatLockdown() then return end BCDM:UpdateBCDM() end)
end

local function StyleChargeText(textRegion, viewerSettings, generalSettings, childFrame)
    if not textRegion or not viewerSettings or not childFrame then return end

    textRegion:SetFont(BCDM.Media.Font, viewerSettings.Text.FontSize, generalSettings.Fonts.FontFlag)
    textRegion:ClearAllPoints()
    textRegion:SetPoint(viewerSettings.Text.Layout[1], childFrame, viewerSettings.Text.Layout[2], viewerSettings.Text.Layout[3], viewerSettings.Text.Layout[4])
    textRegion:SetTextColor(viewerSettings.Text.Colour[1], viewerSettings.Text.Colour[2], viewerSettings.Text.Colour[3], 1)
    if generalSettings.Fonts.Shadow.Enabled then
        textRegion:SetShadowColor(generalSettings.Fonts.Shadow.Colour[1], generalSettings.Fonts.Shadow.Colour[2], generalSettings.Fonts.Shadow.Colour[3], generalSettings.Fonts.Shadow.Colour[4])
        textRegion:SetShadowOffset(generalSettings.Fonts.Shadow.OffsetX, generalSettings.Fonts.Shadow.OffsetY)
    else
        textRegion:SetShadowColor(0, 0, 0, 0)
        textRegion:SetShadowOffset(0, 0)
    end
    textRegion:SetDrawLayer("OVERLAY")
end

local function StyleViewerChargeCount(viewerName)
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local generalSettings = BCDM.db.profile.General
    local viewerSettings = cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]]
    local viewerFrame = _G[viewerName]
    if not viewerFrame or not viewerSettings then return end

    local childCount = viewerFrame:GetNumChildren()
    for i = 1, childCount do
        local childFrame = select(i, viewerFrame:GetChildren())
        if childFrame and childFrame.ChargeCount and childFrame.ChargeCount.Current then
            StyleChargeText(childFrame.ChargeCount.Current, viewerSettings, generalSettings, childFrame)
        end
        if childFrame and childFrame.Applications and childFrame.Applications.Applications then
            StyleChargeText(childFrame.Applications.Applications, viewerSettings, generalSettings, childFrame)
        end
    end
end

local function StyleChargeCount()
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        StyleViewerChargeCount(viewerName)
    end
end

local centerBuffsUpdateThrottle = 0.01
local nextcenterBuffsUpdate = 0

local function CenterBuffs()
    local currentTime = GetTime()
    if currentTime < nextcenterBuffsUpdate then return end
    nextcenterBuffsUpdate = currentTime + centerBuffsUpdateThrottle
    local visibleBuffIcons = {}

    local childCount = BuffIconCooldownViewer:GetNumChildren()
    for i = 1, childCount do
        local childFrame = select(i, BuffIconCooldownViewer:GetChildren())
        if childFrame and childFrame.Icon and childFrame:IsShown() then
            table.insert(visibleBuffIcons, childFrame)
        end
    end

    table.sort(visibleBuffIcons, function(a, b) return (a.layoutIndex or 0) < (b.layoutIndex or 0) end)

    local visibleCount = #visibleBuffIcons
    if visibleCount == 0 then return 0 end

    local iconWidth = visibleBuffIcons[1]:GetWidth()
    local iconHeight = visibleBuffIcons[1]:GetHeight()
    local startX = 0
    local startY = 0
    local iconSpacing = 0

    if BuffIconCooldownViewer.isHorizontal then
        iconSpacing = BuffIconCooldownViewer.childXPadding or 0
        local totalWidth = (visibleCount * iconWidth) + ((visibleCount - 1) * iconSpacing)
        startX = -totalWidth / 2 + iconWidth / 2
    else
        iconSpacing = BuffIconCooldownViewer.childYPadding or 0
        local totalHeight = (visibleCount * iconHeight) + ((visibleCount - 1) * iconSpacing)
        startY = totalHeight / 2 - iconHeight / 2
    end

    for index, iconFrame in ipairs(visibleBuffIcons) do
        if BuffIconCooldownViewer.isHorizontal then
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint("CENTER", BuffIconCooldownViewer, "CENTER", startX + (index - 1) * (iconWidth + iconSpacing), 0)
        else
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint("CENTER", BuffIconCooldownViewer, "CENTER", 0, startY - (index - 1) * (iconHeight + iconSpacing))
        end
    end

    return visibleCount
end

local centerBuffsEventFrame = CreateFrame("Frame")

local function SetupCenterBuffs()
    local buffsSettings = BCDM.db.profile.CooldownManager.Buffs

    if buffsSettings.CenterBuffs then
        centerBuffsEventFrame:SetScript("OnUpdate", CenterBuffs)
    else
        centerBuffsEventFrame:SetScript("OnUpdate", nil)
        centerBuffsEventFrame:Hide()
    end
end

local function CenterWrappedRows(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end
    local anchorFrame = BCDM.GetEffectiveAnchorFrame and BCDM:GetEffectiveAnchorFrame(viewerName) or viewer

    local iconLimit = viewer.iconLimit
    if not iconLimit or iconLimit <= 0 then return end

    local visibleIcons = {}
    local childCount = viewer:GetNumChildren()
    for i = 1, childCount do
        local childFrame = select(i, viewer:GetChildren())
        if childFrame and childFrame:IsShown() and childFrame.layoutIndex then
            table.insert(visibleIcons, childFrame)
        end
    end

    table.sort(visibleIcons, function(a, b) return (a.layoutIndex or 0) < (b.layoutIndex or 0) end)

    local visibleCount = #visibleIcons
    if visibleCount == 0 then return end

    local iconWidth = visibleIcons[1]:GetWidth()
    local iconHeight = visibleIcons[1]:GetHeight()
    local iconSpacing = viewer.childXPadding or 0
    local rowSpacing = viewer.childYPadding or 0
    local rowHeight = (iconHeight > 0 and iconHeight or iconWidth) + rowSpacing

    local basePoint, _, _, _, baseY = visibleIcons[1]:GetPoint(1)
    if not basePoint or not baseY then return end
    local anchorPoint = "TOP"
    local relativePoint = "TOP"
    local yDirection = -1
    if basePoint and basePoint:find("BOTTOM") then
        anchorPoint = "BOTTOM"
        relativePoint = "BOTTOM"
        yDirection = 1
    end

    local rowCount = math.ceil(visibleCount / iconLimit)
    for rowIndex = 1, rowCount do
        local rowStart = (rowIndex - 1) * iconLimit + 1
        local rowEnd = math.min(rowStart + iconLimit - 1, visibleCount)
        local rowIcons = rowEnd - rowStart + 1
        local rowWidth = (rowIcons * iconWidth) + ((rowIcons - 1) * iconSpacing)
        local startX = -rowWidth / 2 + iconWidth / 2
        local rowY = baseY + yDirection * (rowIndex - 1) * rowHeight

        for index = rowStart, rowEnd do
            local iconFrame = visibleIcons[index]
            iconFrame:ClearAllPoints()
            iconFrame:SetPoint(anchorPoint, anchorFrame, relativePoint, startX + (index - rowStart) * (iconWidth + iconSpacing), rowY)
        end
    end
end

local function CenterWrappedIcons()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local essentialSettings = cooldownManagerSettings.Essential
    local utilitySettings = cooldownManagerSettings.Utility

    if essentialSettings and essentialSettings.CenterHorizontally then CenterWrappedRows("EssentialCooldownViewer") end
    if utilitySettings and utilitySettings.CenterHorizontally then CenterWrappedRows("UtilityCooldownViewer") end
end

local function QueueViewerPositionRefresh()
    if pendingViewerPositionRefresh then return end

    pendingViewerPositionRefresh = CreateFrame("Frame")
    pendingViewerPositionRefresh:RegisterEvent("PLAYER_REGEN_ENABLED")
    pendingViewerPositionRefresh:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        pendingViewerPositionRefresh = nil
        BCDM:RefreshCooldownManagerViewerPositions()
    end)
end

function BCDM:RefreshCooldownManagerViewerPositions()
    if InCombatLockdown() then
        QueueViewerPositionRefresh()
        return
    end

    Position()
    CenterWrappedIcons()
end

function BCDM:SkinCooldownManager()
    local LEMO = BCDM.LEMO
    LEMO:LoadLayouts()
    C_CVar.SetCVar("cooldownViewerEnabled", 1)
    StyleIcons()
    StyleChargeCount()
    BCDM:RefreshCooldownManagerViewerPositions()
    SetHooks()
    SetupCenterBuffs()
    if EssentialCooldownViewer and EssentialCooldownViewer.RefreshLayout then hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", function() CenterWrappedIcons() end) end
    if UtilityCooldownViewer and UtilityCooldownViewer.RefreshLayout then hooksecurefunc(UtilityCooldownViewer, "RefreshLayout", function() CenterWrappedIcons() end) end
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        C_Timer.After(0.1, function() BCDM:ApplyCooldownText(viewerName) end)
    end

    C_Timer.After(1, function()
        if not InCombatLockdown() then
            LEMO:ApplyChanges()
        end
    end)
end

function BCDM:UpdateCooldownViewer(viewerType)
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local viewerName = BCDM.DBViewerToCooldownManagerViewer[viewerType]
    local viewerSettings = cooldownManagerSettings[viewerType]
    if viewerType == "CustomViewer" or viewerType == "Custom" or viewerType == "AdditionalCustom" or viewerType == "Item" or viewerType == "ItemSpell" then
        BCDM:UpdateCustomViewer()
        return
    end
    if viewerType == "Trinket" then BCDM:UpdateTrinketBar() return end
    if viewerType == "Buffs" then SetupCenterBuffs() end
    if not viewerName or not viewerSettings then return end

    StyleViewerIcons(viewerName)

    BCDM:RefreshCooldownManagerViewerPositions()

    StyleViewerChargeCount(viewerName)

    BCDM:ApplyCooldownText(viewerName)

    BCDM:UpdatePowerBarWidth()
    BCDM:UpdateSecondaryPowerBarWidth()
    BCDM:UpdateCastBarWidth()
    if viewerType == "Essential" or viewerType == "Utility" then
        BCDM:RefreshCooldownViewerOverlay(viewerType)
    end

    if BCDM.IsTrinketBarAppendedToViewer and BCDM:IsTrinketBarAppendedToViewer(viewerType) then
        BCDM:UpdateTrinketBar()
    end
end

function BCDM:UpdateCooldownViewers()
    BCDM:UpdateCooldownViewer("Essential")
    BCDM:UpdateCooldownViewer("Utility")
    BCDM:UpdateCooldownViewer("Buffs")
    BCDM:UpdateCustomViewer()
    BCDM:UpdateTrinketBar()
    BCDM:UpdatePowerBar()
    BCDM:UpdateSecondaryPowerBar()
    BCDM:UpdateCastBar()
end
