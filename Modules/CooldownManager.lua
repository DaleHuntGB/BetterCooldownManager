local _, BCDM = ...
local LEMO = LibStub("LibEditModeOverride-1.0")

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

-- local function FetchClassColour()
--     local CooldownManagerDB = BCDM.db.profile
--     local GeneralDB = CooldownManagerDB.General
--     local BuffBarDB = CooldownManagerDB.CooldownManager.BuffBar
--     if BuffBarDB then
--         if BuffBarDB.ColourByClass then
--             local _, class = UnitClass("player")
--             local classColour = RAID_CLASS_COLORS[class]
--             if classColour then return classColour.r, classColour.g, classColour.b, 1 end
--         else
--             return BuffBarDB.ForegroundColour[1], BuffBarDB.ForegroundColour[2], BuffBarDB.ForegroundColour[3], BuffBarDB.ForegroundColour[4]
--         end
--     end
-- end

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

-- local function StyleBuffsBars()
--     local GeneralDB = BCDM.db.profile.General
--     local GeneralCooldownManagerSetting = BCDM.db.profile.CooldownManager.General
--     local BuffBarDB = BCDM.db.profile.CooldownManager.BuffBar
--     local buffBarChildren = {_G["BuffBarCooldownViewer"]:GetChildren()}

--     for _, childFrame in ipairs(buffBarChildren) do
--         local buffBar = childFrame.Bar
--         local buffIcon = childFrame.Icon
--         if childFrame.DebuffBorder then childFrame.DebuffBorder:SetAlpha(0) end

--         -- if BuffBarDB.MatchWidthOfAnchor then
--         --     local anchorFrame = _G[BuffBarDB.Layout[2]]
--         --     if anchorFrame then
--         --         local anchorWidth = anchorFrame:GetWidth()
--         --         childFrame:SetWidth(anchorWidth)
--         --         _G["BuffBarCooldownViewer"]:SetWidth(anchorWidth)
--         --     end
--         -- else
--             -- childFrame:SetWidth(BuffBarDB.Width)
--             -- _G["BuffBarCooldownViewer"]:SetWidth(BuffBarDB.Width)
--         -- end
--         -- childFrame:SetHeight(BuffBarDB.Height)

--         if childFrame.Bar then
--             childFrame.Bar:ClearAllPoints()
--             childFrame.Bar:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 0, 0)
--             childFrame.Bar:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", 0, 0)
--             childFrame.Bar:SetStatusBarTexture(BCDM.Media.Foreground)
--             childFrame.Bar:SetStatusBarColor(FetchClassColour())
--             childFrame.Bar.Pip:SetAlpha(0)
--         end

--         if buffBar then
--             buffBar:ClearAllPoints()
--             buffBar:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 0, 0)
--             buffBar:SetPoint("BOTTOMRIGHT", childFrame, "BOTTOMRIGHT", 0, 0)
--             buffBar.BarBG:SetPoint("TOPLEFT", buffBar, "TOPLEFT", 0, 0)
--             buffBar.BarBG:SetPoint("BOTTOMRIGHT", buffBar, "BOTTOMRIGHT", 0, 0)
--             buffBar.BarBG:SetTexture(BCDM.Media.Background)
--             buffBar.BarBG:SetVertexColor(BuffBarDB.BackgroundColour[1], BuffBarDB.BackgroundColour[2], BuffBarDB.BackgroundColour[3], BuffBarDB.BackgroundColour[4])

--             if buffIcon then
--                 if not BuffBarDB.Icon.Enabled then buffIcon:Hide() else buffIcon:Show() end
--                 BCDM:StripTextures(buffIcon.Icon)
--                 buffIcon.Icon:SetSize(BuffBarDB.Height, BuffBarDB.Height)
--                 buffIcon.Icon:ClearAllPoints()
--                 if BuffBarDB.Icon.Layout == "LEFT" then
--                     buffIcon.Icon:SetPoint("RIGHT", buffBar, "LEFT", 1, 0)
--                 else
--                     buffIcon.Icon:SetPoint("LEFT", buffBar, "RIGHT", -1, 0)
--                 end
--                 buffIcon.Icon:SetTexCoord(GeneralCooldownManagerSetting.IconZoom * 0.5, 1 - GeneralCooldownManagerSetting.IconZoom * 0.5, GeneralCooldownManagerSetting.IconZoom * 0.5, 1 - GeneralCooldownManagerSetting.IconZoom * 0.5)
--             end

--             if buffBar.Name then
--                 if not BuffBarDB.Text.SpellName.Enabled then buffBar.Name:Hide() else buffBar.Name:Show() end
--                 buffBar.Name:ClearAllPoints()
--                 buffBar.Name:SetPoint(BuffBarDB.Text.SpellName.Layout[1], buffBar, BuffBarDB.Text.SpellName.Layout[2], BuffBarDB.Text.SpellName.Layout[3], BuffBarDB.Text.SpellName.Layout[4])
--                 buffBar.Name:SetFont(BCDM.Media.Font, BuffBarDB.Text.SpellName.FontSize, GeneralDB.Fonts.FontFlag)
--                 buffBar.Name:SetTextColor(BuffBarDB.Text.SpellName.Colour[1], BuffBarDB.Text.SpellName.Colour[2], BuffBarDB.Text.SpellName.Colour[3], 1)
--                 if GeneralDB.Fonts.Shadow.Enabled then
--                     buffBar.Name:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
--                     buffBar.Name:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
--                 else
--                     buffBar.Name:SetShadowColor(0, 0, 0, 0)
--                     buffBar.Name:SetShadowOffset(0, 0)
--                 end
--             end

--             if buffBar.Duration then
--                 if not BuffBarDB.Text.Duration.Enabled then buffBar.Duration:Hide() else buffBar.Duration:Show() end
--                 buffBar.Duration:ClearAllPoints()
--                 buffBar.Duration:SetPoint(BuffBarDB.Text.Duration.Layout[1], buffBar, BuffBarDB.Text.Duration.Layout[2], BuffBarDB.Text.Duration.Layout[3], BuffBarDB.Text.Duration.Layout[4])
--                 buffBar.Duration:SetFont(BCDM.Media.Font, BuffBarDB.Text.Duration.FontSize, GeneralDB.Fonts.FontFlag)
--                 buffBar.Duration:SetTextColor(BuffBarDB.Text.Duration.Colour[1], BuffBarDB.Text.Duration.Colour[2], BuffBarDB.Text.Duration.Colour[3], 1)
--                 if GeneralDB.Fonts.Shadow.Enabled then
--                     buffBar.Duration:SetShadowColor(GeneralDB.Fonts.Shadow.Colour[1], GeneralDB.Fonts.Shadow.Colour[2], GeneralDB.Fonts.Shadow.Colour[3], GeneralDB.Fonts.Shadow.Colour[4])
--                     buffBar.Duration:SetShadowOffset(GeneralDB.Fonts.Shadow.OffsetX, GeneralDB.Fonts.Shadow.OffsetY)
--                 else
--                     buffBar.Duration:SetShadowColor(0, 0, 0, 0)
--                     buffBar.Duration:SetShadowOffset(0, 0)
--                 end
--             end
--         end
--         BCDM:AddBorder(buffBar)
--         BCDM:AddBorder(buffIcon)
--     end
-- end

local function Position()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    -- _G["BuffBarCooldownViewer"]:SetFrameStrata("LOW")
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        local viewerSettings = cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]]
        local viewerFrame = _G[viewerName]
        if viewerFrame and (viewerName == "UtilityCooldownViewer" or viewerName == "BuffIconCooldownViewer") then
            viewerFrame:ClearAllPoints()
            local anchorParent = viewerSettings.Layout[2] == "NONE" and UIParent or _G[viewerSettings.Layout[2]]
            viewerFrame:SetPoint(viewerSettings.Layout[1], anchorParent, viewerSettings.Layout[3], viewerSettings.Layout[4], viewerSettings.Layout[5])
            viewerFrame:SetFrameStrata("LOW")
        elseif viewerFrame then
            viewerFrame:ClearAllPoints()
            viewerFrame:SetPoint(viewerSettings.Layout[1], UIParent, viewerSettings.Layout[3], viewerSettings.Layout[4], viewerSettings.Layout[5])
            viewerFrame:SetFrameStrata("LOW")
        end
        NudgeViewer(viewerName, -0.1, 0)
    end
end

-- function BCDM:UpdateBuffBarStyle()
--     Position()
--     StyleBuffsBars()
-- end

local function StyleIcons()
    if not ShouldSkin() then return end
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        for _, childFrame in ipairs({_G[viewerName]:GetChildren()}) do
            if childFrame then
                if childFrame.Icon then
                    BCDM:StripTextures(childFrame.Icon)
                    local iconZoomAmount = cooldownManagerSettings.General.IconZoom * 0.5
                    childFrame.Icon:SetTexCoord(iconZoomAmount, 1 - iconZoomAmount, iconZoomAmount, 1 - iconZoomAmount)
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
                childFrame:SetSize(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].IconSize, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].IconSize)
                BCDM:AddBorder(childFrame)
                if not childFrame.layoutIndex then childFrame:SetShown(false) end
            end
        end
    end
end

local function SetHooks()
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() if InCombatLockdown() then return end Position() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() if InCombatLockdown() then return end Position() end)
    hooksecurefunc(CooldownViewerSettings, "RefreshLayout", function() if InCombatLockdown() then return end BCDM:UpdateBCDM() end)
end

local function StyleChargeCount()
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local generalSettings = BCDM.db.profile.General
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        for _, childFrame in ipairs({ _G[viewerName]:GetChildren() }) do
            if childFrame and childFrame.ChargeCount and childFrame.ChargeCount.Current then
                local currentChargeText = childFrame.ChargeCount.Current
                currentChargeText:SetFont(BCDM.Media.Font, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.FontSize, generalSettings.Fonts.FontFlag)
                currentChargeText:ClearAllPoints()
                currentChargeText:SetPoint(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[1], childFrame, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[3], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[4])
                currentChargeText:SetTextColor(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[1], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[3], 1)
                if generalSettings.Fonts.Shadow.Enabled then
                    currentChargeText:SetShadowColor(generalSettings.Fonts.Shadow.Colour[1], generalSettings.Fonts.Shadow.Colour[2], generalSettings.Fonts.Shadow.Colour[3], generalSettings.Fonts.Shadow.Colour[4])
                    currentChargeText:SetShadowOffset(generalSettings.Fonts.Shadow.OffsetX, generalSettings.Fonts.Shadow.OffsetY)
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
                applicationsText:SetFont(BCDM.Media.Font, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.FontSize, generalSettings.Fonts.FontFlag)
                applicationsText:ClearAllPoints()
                applicationsText:SetPoint(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[1], childFrame, cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[3], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Layout[4])
                applicationsText:SetTextColor(cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[1], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[2], cooldownManagerSettings[BCDM.CooldownManagerViewerToDBViewer[viewerName]].Text.Colour[3], 1)
                if generalSettings.Fonts.Shadow.Enabled then
                    applicationsText:SetShadowColor(generalSettings.Fonts.Shadow.Colour[1], generalSettings.Fonts.Shadow.Colour[2], generalSettings.Fonts.Shadow.Colour[3], generalSettings.Fonts.Shadow.Colour[4])
                    applicationsText:SetShadowOffset(generalSettings.Fonts.Shadow.OffsetX, generalSettings.Fonts.Shadow.OffsetY)
                else
                    applicationsText:SetShadowColor(0, 0, 0, 0)
                    applicationsText:SetShadowOffset(0, 0)
                end
                applicationsText:SetDrawLayer("OVERLAY")
            end
        end
    end
end

local centerBuffsUpdateThrottle = 0.05
local nextcenterBuffsUpdate = 0

local centerUpdateThrottle = 0.05
local nextCenterUpdate = {}

local function CenterViewer(frameName)
    local key = frameName
    if not nextCenterUpdate[key] then nextCenterUpdate[key] = 0 end
    local currentTime = GetTime()
    if currentTime < nextCenterUpdate[key] then return end
    nextCenterUpdate[key] = currentTime + centerUpdateThrottle
    local frame = _G[frameName]
    if not frame then return 0 end
    local visibleCount = 0
    for _, childFrame in ipairs({ frame:GetChildren() }) do
        if childFrame and childFrame.Icon and childFrame:IsShown() then
            visibleCount = visibleCount + 1
        end
    end
    if visibleCount > 0 then
        BCDM:CenterChildrenRows(frame)
    end
    return visibleCount
end

local function CenterBuffs()
    return CenterViewer("BuffIconCooldownViewer")
end

local function CenterUtility()
    return CenterViewer("UtilityCooldownViewer")
end

local function CenterEssential()
    return CenterViewer("EssentialCooldownViewer")
end

local centerEssentialEventFrame = CreateFrame("Frame")
local centerBuffsEventFrame = CreateFrame("Frame")
local centerUtilityEventFrame = CreateFrame("Frame")

local eventFrames = {
    Buffs = centerBuffsEventFrame,
    Utility = centerUtilityEventFrame,
    Essential = centerEssentialEventFrame,
}

local function SetupCenterViewer(viewerType, centerKey)
    local settings = BCDM.db.profile.CooldownManager[viewerType]
    if settings and settings[centerKey] then
        eventFrames[viewerType]:SetScript("OnUpdate", function() CenterViewer(viewerType == "Buffs" and "BuffIconCooldownViewer" or viewerType .. "CooldownViewer") end)
    else
        eventFrames[viewerType]:SetScript("OnUpdate", nil)
        eventFrames[viewerType]:Hide()
    end
end

local function SetupCenterEssential()
    SetupCenterViewer("Essential", "CenterEssential")
end

local function SetupCenterBuffs()
    SetupCenterViewer("Buffs", "CenterBuffs")
end

local function SetupCenterUtility()
    SetupCenterViewer("Utility", "CenterUtility")
end

-- Generic helper to center rows for any container frame that already
-- has its children positioned (groups by vertical offset and centers each row).
function BCDM:CenterChildrenRows(container)
    if not container then return end
    local children = { container:GetChildren() }
    if #children == 0 then return end

    local visibleIcons = {}
    for _, child in ipairs(children) do
        if child and child:IsShown() then
            table.insert(visibleIcons, child)
        end
    end
    if #visibleIcons == 0 then return end

    local cX, cY = container:GetCenter()
    if not cX or not cY then return end

    local rows = {}
    for _, icon in ipairs(visibleIcons) do
        local ix, iy = icon:GetCenter()
        if ix and iy then
            local rowOffset = iy - cY
            local key = tostring(math.floor(rowOffset * 100 + 0.5))
            rows[key] = rows[key] or { offset = rowOffset, icons = {} }
            table.insert(rows[key].icons, icon)
        else
            rows["0"] = rows["0"] or { offset = 0, icons = {} }
            table.insert(rows["0"].icons, icon)
        end
    end

    for _, row in pairs(rows) do
        local rowIcons = row.icons
        local count = #rowIcons
        if count > 0 then
            -- ensure icons are ordered left-to-right by their X coordinate before repositioning
            table.sort(rowIcons, function(a, b)
                local ax, _ = a:GetCenter()
                local bx, _ = b:GetCenter()
                ax = ax or 0
                bx = bx or 0
                return ax < bx
            end)

            local iconWidth = rowIcons[1]:GetWidth()
            -- determine spacing: prefer container.childXPadding, else infer from first two icons if possible
            local spacing = container.childXPadding
            if not spacing or spacing == 0 then
                if count > 1 then
                    local x1, _ = rowIcons[1]:GetCenter()
                    local x2, _ = rowIcons[2]:GetCenter()
                    if x1 and x2 then
                        spacing = (x2 - x1) - iconWidth
                    else
                        spacing = 0
                    end
                else
                    spacing = 0
                end
            end

            local totalWidth = (count * iconWidth) + ((count - 1) * spacing)
            local startX = -totalWidth / 2 + iconWidth / 2
            for idx, iconFrame in ipairs(rowIcons) do
                iconFrame:ClearAllPoints()
                iconFrame:SetPoint("CENTER", container, "CENTER", startX + (idx - 1) * (iconWidth + spacing), row.offset)
            end
        end
    end
end

function BCDM:SkinCooldownManager()
    LEMO:LoadLayouts()
    C_CVar.SetCVar("cooldownViewerEnabled", 1)
    StyleIcons()
    StyleChargeCount()
    Position()
    -- C_Timer.After(1, function() StyleBuffsBars() end)
    SetHooks()
    SetupCenterBuffs()
    SetupCenterUtility()
    SetupCenterEssential()
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do C_Timer.After(0.1, function() ApplyCooldownText(viewerName) end) end
    C_Timer.After(1, function() LEMO:ApplyChanges() end)
end

function BCDM:UpdateCooldownViewer(viewerType)
    -- if viewerType == "BuffBar" then BCDM:UpdateBuffBarStyle() return end
    local cooldownManagerSettings = BCDM.db.profile.CooldownManager
    local cooldownViewerFrame = _G[BCDM.DBViewerToCooldownManagerViewer[viewerType]]
    if viewerType == "Custom" then BCDM:UpdateCustomCooldownViewer() return end
    if viewerType == "AdditionalCustom" then BCDM:UpdateAdditionalCustomCooldownViewer() return end
    if viewerType == "Item" then BCDM:UpdateCustomItemBar() return end
    if viewerType == "Trinket" then BCDM:UpdateTrinketBar() return end
    if viewerType == "ItemSpell" then BCDM:UpdateCustomItemsSpellsBar() return end
    if viewerType == "Utility" then SetupCenterUtility() end
    if viewerType == "Buffs" then SetupCenterBuffs() end
    if viewerType == "Essential" then SetupCenterEssential() end


    for _, childFrame in ipairs({cooldownViewerFrame:GetChildren()}) do
        if childFrame then
            if childFrame.Icon and ShouldSkin() then
                BCDM:StripTextures(childFrame.Icon)
                childFrame.Icon:SetTexCoord(cooldownManagerSettings.General.IconZoom, 1 - cooldownManagerSettings.General.IconZoom, cooldownManagerSettings.General.IconZoom, 1 - cooldownManagerSettings.General.IconZoom)
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
            childFrame:SetSize(cooldownManagerSettings[viewerType].IconSize, cooldownManagerSettings[viewerType].IconSize)
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
