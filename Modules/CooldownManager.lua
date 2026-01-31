local _, BCDM = ...

local buffBarResizeTimer = nil

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

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function FetchClassColour()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local BuffBarDB = CooldownManagerDB.CooldownManager.BuffBar
    if BuffBarDB then
        if BuffBarDB.ColourByClass then
            local _, class = UnitClass("player")
            local classColour = RAID_CLASS_COLORS[class]
            if classColour then return classColour.r, classColour.g, classColour.b, 1 end
        else
            return BuffBarDB.ForegroundColour[1], BuffBarDB.ForegroundColour[2], BuffBarDB.ForegroundColour[3],
                BuffBarDB.ForegroundColour[4]
        end
    end
end

local function ApplyCooldownText(cooldownViewer)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = CooldownManagerDB.CooldownManager.General.CooldownText
    local Viewer = _G[cooldownViewer]
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
                textRegion:SetPoint(CooldownTextDB.Layout[1], icon, CooldownTextDB.Layout[2], CooldownTextDB.Layout[3],
                    CooldownTextDB.Layout[4])
                if GeneralDB.Fonts.Shadow.Enabled then
                    textRegion:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2],
                        GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                    textRegion:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
                else
                    textRegion:SetShadowColor(0, 0, 0, 0)
                    textRegion:SetShadowOffset(0, 0)
                end
            end
        end
    end
end

-- Hide stack/charge count elements on a BuffBar frame
-- BuffBar uses custom Name/Duration text instead of Blizzard's charge/stack displays
-- Based on frame structure analysis: childFrame.Icon.Applications is the FontString that displays stack counts
local function HideBuffBarStackCharges(childFrame)
    if not childFrame then return end

    -- Hide the stack/charge count FontString on the Icon container
    -- This is the ONLY element that displays stacks/charges on BuffBar frames
    if childFrame.Icon and childFrame.Icon.Applications then
        pcall(function() childFrame.Icon.Applications:Hide() end)
    end
end

local function StyleBuffsBars()
    local GeneralDB = BCDM.db.profile.General
    local GeneralCooldownManagerSetting = BCDM.db.profile.CooldownManager.General
    local BuffBarDB = BCDM.db.profile.CooldownManager.BuffBar
    local buffBarChildren = { _G["BuffBarCooldownViewer"]:GetChildren() }

    for _, childFrame in ipairs(buffBarChildren) do
        local buffBar = childFrame.Bar
        local buffIcon = childFrame.Icon
        if childFrame.DebuffBorder then childFrame.DebuffBorder:SetAlpha(0) end

        -- Hide stack/charge counts (BuffBar uses custom Name/Duration text instead)
        HideBuffBarStackCharges(childFrame)

        if BuffBarDB.MatchWidthOfAnchor then
            local anchorFrame = _G[BuffBarDB.Layout[2]]
            if anchorFrame then
                local anchorWidth = anchorFrame:GetWidth()
                childFrame:SetWidth(anchorWidth)
                _G["BuffBarCooldownViewer"]:SetWidth(anchorWidth)
            end
        else
            childFrame:SetWidth(BuffBarDB.Width)
            _G["BuffBarCooldownViewer"]:SetWidth(BuffBarDB.Width)
        end
        childFrame:SetHeight(BuffBarDB.Height)

        if childFrame.Bar then
            -- Bar positioning handled in buffIcon section to account for icon placement
            childFrame.Bar:SetStatusBarTexture(BCDM.Media.Foreground)
            childFrame.Bar:SetStatusBarColor(FetchClassColour())
            childFrame.Bar.Pip:SetAlpha(0)
        end

        if buffBar then
            -- Bar positioning handled in buffIcon section to account for icon placement
            buffBar.BarBG:SetPoint("TOPLEFT", buffBar, "TOPLEFT", 0, 0)
            buffBar.BarBG:SetPoint("BOTTOMRIGHT", buffBar, "BOTTOMRIGHT", 0, 0)
            buffBar.BarBG:SetTexture(BCDM.Media.Background)
            buffBar.BarBG:SetVertexColor(BuffBarDB.BackgroundColour[1], BuffBarDB.BackgroundColour[2],
                BuffBarDB.BackgroundColour[3], BuffBarDB.BackgroundColour[4])

            if buffIcon and buffIcon.Icon then
                buffIcon.Icon:ClearAllPoints()
                buffBar:ClearAllPoints()

                -- Always strip Blizzard textures (border/glow) regardless of visibility
                BCDM:StripTextures(buffIcon.Icon)

                -- Use BCDM setting to control icon visibility (overrides Blizzard's Edit Mode)
                if not BuffBarDB.Icon.Enabled then
                    -- Hide icon, bar fills entire childFrame
                    buffIcon.Icon:Hide()
                    buffBar:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 0, 0)
                    buffBar:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", 0, 0)
                else
                    -- Show and style icon, position bar accordingly
                    buffIcon.Icon:Show()
                    buffIcon.Icon:SetSize(BuffBarDB.Height, BuffBarDB.Height)

                    if BuffBarDB.Icon.Layout == "LEFT" then
                        -- Icon on left side of childFrame
                        buffIcon.Icon:SetPoint("LEFT", childFrame, "LEFT", 0, 0)
                        -- Bar fills space from icon's right edge to childFrame's right edge
                        buffBar:SetPoint("TOPLEFT", buffIcon.Icon, "TOPRIGHT", 0, 0)
                        buffBar:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", 0, 0)
                    else
                        -- Icon on right side of childFrame
                        buffIcon.Icon:SetPoint("RIGHT", childFrame, "RIGHT", 0, 0)
                        -- Bar fills space from childFrame's left edge to icon's left edge
                        buffBar:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 0, 0)
                        buffBar:SetPoint("BOTTOMRIGHT", buffIcon.Icon, "BOTTOMLEFT", 0, 0)
                    end

                    buffIcon.Icon:SetTexCoord(GeneralCooldownManagerSetting.IconZoom * 0.5,
                        1 - GeneralCooldownManagerSetting.IconZoom * 0.5, GeneralCooldownManagerSetting.IconZoom * 0.5,
                        1 - GeneralCooldownManagerSetting.IconZoom * 0.5)
                end
            end

            if buffBar.Name then
                if not BuffBarDB.Text.SpellName.Enabled then buffBar.Name:Hide() else buffBar.Name:Show() end
                buffBar.Name:ClearAllPoints()
                buffBar.Name:SetPoint(BuffBarDB.Text.SpellName.Layout[1], buffBar, BuffBarDB.Text.SpellName.Layout[2],
                    BuffBarDB.Text.SpellName.Layout[3], BuffBarDB.Text.SpellName.Layout[4])
                buffBar.Name:SetFont(BCDM.Media.Font, BuffBarDB.Text.SpellName.FontSize, GeneralDB.Fonts.FontFlag)
                buffBar.Name:SetTextColor(BuffBarDB.Text.SpellName.Colour[1], BuffBarDB.Text.SpellName.Colour[2],
                    BuffBarDB.Text.SpellName.Colour[3], 1)
                if GeneralDB.Fonts.Shadow.Enabled then
                    buffBar.Name:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2],
                        GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                    buffBar.Name:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
                else
                    buffBar.Name:SetShadowColor(0, 0, 0, 0)
                    buffBar.Name:SetShadowOffset(0, 0)
                end
            end

            if buffBar.Duration then
                if not BuffBarDB.Text.Duration.Enabled then buffBar.Duration:Hide() else buffBar.Duration:Show() end
                buffBar.Duration:ClearAllPoints()
                buffBar.Duration:SetPoint(BuffBarDB.Text.Duration.Layout[1], buffBar, BuffBarDB.Text.Duration.Layout[2],
                    BuffBarDB.Text.Duration.Layout[3], BuffBarDB.Text.Duration.Layout[4])
                buffBar.Duration:SetFont(BCDM.Media.Font, BuffBarDB.Text.Duration.FontSize, GeneralDB.Fonts.FontFlag)
                buffBar.Duration:SetTextColor(BuffBarDB.Text.Duration.Colour[1], BuffBarDB.Text.Duration.Colour[2],
                    BuffBarDB.Text.Duration.Colour[3], 1)
                if GeneralDB.Fonts.Shadow.Enabled then
                    buffBar.Duration:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2],
                        GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
                    buffBar.Duration:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
                else
                    buffBar.Duration:SetShadowColor(0, 0, 0, 0)
                    buffBar.Duration:SetShadowOffset(0, 0)
                end
            end
        end
        BCDM:AddBorder(buffBar)
        BCDM:AddBorder(buffIcon)
    end
end

local function Position()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    -- _G["BuffBarCooldownViewer"]:SetFrameStrata("LOW")
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        local viewerSettings = cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]]
        local viewerFrame = _G[viewerName]
        if viewerFrame then
            viewerFrame:ClearAllPoints()
            local anchorParent = viewerSettings.Layout[2] == "NONE" and UIParent or _G[viewerSettings.Layout[2]]
            -- Safety check: if anchor parent doesn't exist, fall back to UIParent
            if not anchorParent then
                anchorParent = UIParent
            end
            viewerFrame:SetPoint(viewerSettings.Layout[1], anchorParent, viewerSettings.Layout[3],
                viewerSettings.Layout[4], viewerSettings.Layout[5])
            viewerFrame:SetFrameStrata("LOW")
            NudgeViewer(viewerName, -0.1, 0)
        end
    end
end

local buffBarPositionUpdateThrottle = 0.05
local nextBuffBarPositionUpdate = 0

local function PositionBuffBars()
    local currentTime = GetTime()
    if currentTime < nextBuffBarPositionUpdate then return end
    nextBuffBarPositionUpdate = currentTime + buffBarPositionUpdateThrottle

    local BuffBarDB = BCDM.db.profile.CooldownManager.BuffBar
    local buffBarViewer = _G["BuffBarCooldownViewer"]
    if not buffBarViewer then return end

    local visibleBuffBars = {}

    -- Collect all visible buff bars
    for _, childFrame in ipairs({ buffBarViewer:GetChildren() }) do
        if childFrame and childFrame:IsShown() and childFrame.layoutIndex then
            table.insert(visibleBuffBars, childFrame)

            -- Hide stack/charge counts on each frame update
            -- This catches newly created/recycled frames that Blizzard shows after StyleBuffsBars() runs
            HideBuffBarStackCharges(childFrame)
        end
    end

    -- Sort by layoutIndex to maintain Blizzard's intended order
    table.sort(visibleBuffBars, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    local visibleCount = #visibleBuffBars
    if visibleCount == 0 then return end

    local barHeight = BuffBarDB.Height
    local spacing = BuffBarDB.Spacing
    local growthDirection = BuffBarDB.GrowthDirection or "UP"

    -- Position each buff bar based on growth direction
    for index, barFrame in ipairs(visibleBuffBars) do
        barFrame:ClearAllPoints()

        if growthDirection == "UP" then
            -- First bar at anchor point (BOTTOM of viewer), stack upward
            local yOffset = (index - 1) * (barHeight + spacing)
            barFrame:SetPoint("BOTTOM", buffBarViewer, "BOTTOM", 0, yOffset)
        elseif growthDirection == "DOWN" then
            -- First bar at anchor point (TOP of viewer), stack downward
            local yOffset = -(index - 1) * (barHeight + spacing)
            barFrame:SetPoint("TOP", buffBarViewer, "TOP", 0, yOffset)
        end
    end

    return visibleCount
end

local buffBarEventFrame = CreateFrame("Frame")

local function SetupBuffBarPositioning()
    -- Always run the positioning for buff bars
    buffBarEventFrame:SetScript("OnUpdate", PositionBuffBars)
end

function BCDM:UpdateBuffBarStyle()
    Position()
    StyleBuffsBars()
    PositionBuffBars()
    BCDM:UpdateBuffBarWidth()
end

--[[
local cooldownFrameTbl = {}

for _, child in ipairs({ viewer:GetChildren() }) do
    cooldownFrameTbl[child:GetCooldownFrame()] = true
end

hooksecurefunc("CooldownFrame_Set", function(cooldownFrame)
    if cooldownFrameTbl[cooldownFrame] and cooldownFrame:GetUseAuraDisplayTime() then
        CooldownFrame_Clear(cooldownFrame)
    end
end)
]]

local function StyleIcons()
    if not ShouldSkin() then return end
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        if viewerName ~= "BuffBarCooldownViewer" then
            for _, childFrame in ipairs({ _G[viewerName]:GetChildren() }) do
                if childFrame then
                    if childFrame.Icon then
                        BCDM:StripTextures(childFrame.Icon)
                        local iconZoomAmount = cooldownManagerSettings.General.IconZoom * 0.5
                        childFrame.Icon:SetTexCoord(iconZoomAmount, 1 - iconZoomAmount, iconZoomAmount,
                            1 - iconZoomAmount)
                    end
                    if childFrame.Cooldown then
                        local borderSize = cooldownManagerSettings.General.BorderSize
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
                    childFrame:SetSize(
                    cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].IconSize,
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].IconSize)
                    BCDM:AddBorder(childFrame)
                    if not childFrame.layoutIndex then childFrame:SetShown(false) end
                end
            end
        end
    end
end

function BCDM:UpdateBuffBarWidth()
    local BuffBarDB = BCDM.db.profile.CooldownManager.BuffBar

    -- Cancel existing timer to prevent stacking
    if buffBarResizeTimer then
        buffBarResizeTimer:Cancel()
        buffBarResizeTimer = nil
    end

    if not BuffBarDB.MatchWidthOfAnchor then return end

    -- Check for invalid anchor (NONE or non-existent frame)
    if BuffBarDB.Layout[2] == "NONE" or not _G[BuffBarDB.Layout[2]] then
        return
    end

    local anchorFrame = _G[BuffBarDB.Layout[2]]

    -- Use timer with cancellation like SecondaryPowerBar
    buffBarResizeTimer = C_Timer.After(0.5, function()
        local anchorWidth = anchorFrame:GetWidth()
        _G["BuffBarCooldownViewer"]:SetWidth(anchorWidth)
        for _, childFrame in ipairs({ _G["BuffBarCooldownViewer"]:GetChildren() }) do
            childFrame:SetWidth(anchorWidth)
        end
        buffBarResizeTimer = nil
    end)
end

local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode",
        function()
            if InCombatLockdown() then return end
            Position()
            BCDM:UpdateBuffBarWidth()
        end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode",
        function()
            if InCombatLockdown() then return end
            BCDM.LEMO:LoadLayouts()
            Position()
            BCDM:UpdateBuffBarWidth()
        end)
    hooksecurefunc(CooldownViewerSettings, "RefreshLayout",
        function()
            if InCombatLockdown() then return end
            BCDM:UpdateBCDM()
        end)
end

local function StyleChargeCount()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local generalSettings = BCDM.db.profile.General
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        -- Skip BuffBar - it has custom text structure (SpellName/Duration)
        -- BuffBar stack/charge hiding is handled separately in HideBuffBarStackCharges()
        -- Note: BuffBar frames use Icon.Applications for stack counts, not ChargeCount.Current
        if viewerName ~= "BuffBarCooldownViewer" then
            for _, childFrame in ipairs({ _G[viewerName]:GetChildren() }) do
                if childFrame and childFrame.ChargeCount and childFrame.ChargeCount.Current then
                    local currentChargeText = childFrame.ChargeCount.Current
                    currentChargeText:SetFont(BCDM.Media.Font,
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.FontSize,
                        generalSettings.Fonts.FontFlag)
                    currentChargeText:ClearAllPoints()
                    currentChargeText:SetPoint(
                    cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[1], childFrame,
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[2],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[3],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[4])
                    currentChargeText:SetTextColor(
                    cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[1],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[2],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[3], 1)
                    if generalSettings.Fonts.Shadow.Enabled then
                        currentChargeText:SetShadowColor(generalSettings.Fonts.Shadow.Colour[1],
                            generalSettings.Fonts.Shadow.Colour[2], generalSettings.Fonts.Shadow.Colour[3],
                            generalSettings.Fonts.Shadow.Colour[4])
                        currentChargeText:SetShadowOffset(generalSettings.Fonts.Shadow.OffsetX,
                            generalSettings.Fonts.Shadow.OffsetY)
                    else
                        currentChargeText:SetShadowColor(0, 0, 0, 0)
                        currentChargeText:SetShadowOffset(0, 0)
                    end
                    currentChargeText:SetDrawLayer("OVERLAY")
                end
            end
            for _, childFrame in ipairs({ _G[viewerName]:GetChildren() }) do
                if childFrame and childFrame.Applications then
                    local applicationsText = childFrame.Applications.Applications
                    applicationsText:SetFont(BCDM.Media.Font,
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.FontSize,
                        generalSettings.Fonts.FontFlag)
                    applicationsText:ClearAllPoints()
                    applicationsText:SetPoint(
                    cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[1], childFrame,
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[2],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[3],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[4])
                    applicationsText:SetTextColor(
                    cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[1],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[2],
                        cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[3], 1)
                    if generalSettings.Fonts.Shadow.Enabled then
                        applicationsText:SetShadowColor(generalSettings.Fonts.Shadow.Colour[1],
                            generalSettings.Fonts.Shadow.Colour[2], generalSettings.Fonts.Shadow.Colour[3],
                            generalSettings.Fonts.Shadow.Colour[4])
                        applicationsText:SetShadowOffset(generalSettings.Fonts.Shadow.OffsetX,
                            generalSettings.Fonts.Shadow.OffsetY)
                    else
                        applicationsText:SetShadowColor(0, 0, 0, 0)
                        applicationsText:SetShadowOffset(0, 0)
                    end
                    applicationsText:SetDrawLayer("OVERLAY")
                end
            end
        end
    end
end

local centerBuffsUpdateThrottle = 0.05
local nextcenterBuffsUpdate = 0

local function CenterBuffs()
    local currentTime = GetTime()
    if currentTime < nextcenterBuffsUpdate then return end
    nextcenterBuffsUpdate = currentTime + centerBuffsUpdateThrottle
    local visibleBuffIcons = {}

    for _, childFrame in ipairs({ BuffIconCooldownViewer:GetChildren() }) do
        if childFrame and childFrame.Icon and childFrame:IsShown() then
            table.insert(visibleBuffIcons, childFrame)
        end
    end

    table.sort(visibleBuffIcons, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    local visibleCount = #visibleBuffIcons
    if visibleCount == 0 then return 0 end

    local iconWidth = visibleBuffIcons[1]:GetWidth()
    local iconSpacing = BuffIconCooldownViewer.childXPadding or 0
    local totalWidth = (visibleCount * iconWidth) + ((visibleCount - 1) * iconSpacing)
    local startX = -totalWidth / 2 + iconWidth / 2

    for index, iconFrame in ipairs(visibleBuffIcons) do
        iconFrame:ClearAllPoints()
        iconFrame:SetPoint("CENTER", BuffIconCooldownViewer, "CENTER", startX + (index - 1) * (iconWidth + iconSpacing),
            0)
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

function BCDM:SkinCooldownManager()
    local LEMO = BCDM.LEMO
    LEMO:LoadLayouts()
    C_CVar.SetCVar("cooldownViewerEnabled", 1)
    StyleIcons()
    StyleChargeCount()
    Position()
    SetHooks()
    SetupCenterBuffs()
    SetupBuffBarPositioning()

    -- Initialize BuffBar styling after a delay to ensure children exist
    if _G["BuffBarCooldownViewer"] and ShouldSkin() then
        C_Timer.After(0.3, function()
            StyleBuffsBars()
            PositionBuffBars()
            BCDM:UpdateBuffBarWidth()
        end)
    end

    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        C_Timer.After(0.1, function() ApplyCooldownText(viewerName) end)
    end

    C_Timer.After(1, function()
        if not InCombatLockdown() then
            LEMO:ApplyChanges()
        end
    end)
end

function BCDM:UpdateCooldownViewer(viewerType)
    if viewerType == "BuffBar" then
        BCDM:UpdateBuffBarStyle()
        return
    end
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local cooldownViewerFrame = _G[BCDM.DBViewerToCooldownManagerViewer[viewerType]]
    if viewerType == "Custom" then
        BCDM:UpdateCustomCooldownViewer()
        return
    end
    if viewerType == "AdditionalCustom" then
        BCDM:UpdateAdditionalCustomCooldownViewer()
        return
    end
    if viewerType == "Item" then
        BCDM:UpdateCustomItemBar()
        return
    end
    if viewerType == "Trinket" then
        BCDM:UpdateTrinketBar()
        return
    end
    if viewerType == "ItemSpell" then
        BCDM:UpdateCustomItemsSpellsBar()
        return
    end
    if viewerType == "Buffs" then SetupCenterBuffs() end


    for _, childFrame in ipairs({ cooldownViewerFrame:GetChildren() }) do
        if childFrame then
            if childFrame.Icon and ShouldSkin() then
                BCDM:StripTextures(childFrame.Icon)
                childFrame.Icon:SetTexCoord(cooldownManagerSettings.General.IconZoom,
                    1 - cooldownManagerSettings.General.IconZoom, cooldownManagerSettings.General.IconZoom,
                    1 - cooldownManagerSettings.General.IconZoom)
            end
            if childFrame.Cooldown then
                childFrame.Cooldown:ClearAllPoints()
                childFrame.Cooldown:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 1, -1)
                childFrame.Cooldown:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", -1, 1)
                childFrame.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
                childFrame.Cooldown:SetDrawEdge(false)
                childFrame.Cooldown:SetDrawSwipe(true)
                childFrame.Cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
            end
            if childFrame.CooldownFlash then childFrame.CooldownFlash:SetAlpha(0) end
            childFrame:SetSize(cooldownManagerSettings[viewerType].IconSize, cooldownManagerSettings[viewerType]
            .IconSize)
        end
    end

    StyleIcons()

    Position()

    StyleChargeCount()

    ApplyCooldownText(BCDM.DBViewerToCooldownManagerViewer[viewerType])

    BCDM:UpdatePowerBarWidth()
    BCDM:UpdateSecondaryPowerBarWidth()
    BCDM:UpdateCastBarWidth()
end

function BCDM:UpdateCooldownViewers()
    BCDM:UpdateCooldownViewer("Essential")
    BCDM:UpdateCooldownViewer("Utility")
    BCDM:UpdateCooldownViewer("Buffs")
    BCDM:UpdateCustomCooldownViewer()
    BCDM:UpdateAdditionalCustomCooldownViewer()
    BCDM:UpdateCustomItemBar()
    BCDM:UpdateCustomItemsSpellsBar()
    BCDM:UpdateTrinketBar()
    BCDM:UpdatePowerBar()
    BCDM:UpdateSecondaryPowerBar()
    BCDM:UpdateCastBar()
end
