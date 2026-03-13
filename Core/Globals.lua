local _, BCDM = ...
BCDMG = BCDMG or {}

BCDM.IS_DEATHKNIGHT = select(2, UnitClass("player")) == "DEATHKNIGHT"
BCDM.IS_MONK = select(2, UnitClass("player")) == "MONK"

BCDM.CooldownManagerViewers = { "EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", }

BCDM.CooldownManagerViewerToDBViewer = {
    EssentialCooldownViewer = "Essential",
    UtilityCooldownViewer = "Utility",
    BuffIconCooldownViewer = "Buffs",
}

BCDM.DBViewerToCooldownManagerViewer = {
    Essential = "EssentialCooldownViewer",
    Utility = "UtilityCooldownViewer",
    Buffs = "BuffIconCooldownViewer",
}

BCDM.LSM = LibStub("LibSharedMedia-3.0")
BCDM.LDS = LibStub("LibDualSpec-1.0")
BCDM.LEMO = LibStub("LibEditModeOverride-1.0")
BCDM.AG = LibStub("AceGUI-3.0")

BCDM.INFOBUTTON = "|TInterface\\AddOns\\BetterCooldownManager\\Media\\InfoButton.png:16:16|t "
BCDM.ADDON_NAME = C_AddOns.GetAddOnMetadata("BetterCooldownManager", "Title")
BCDM.ADDON_VERSION = C_AddOns.GetAddOnMetadata("BetterCooldownManager", "Version")
BCDM.ADDON_AUTHOR = C_AddOns.GetAddOnMetadata("BetterCooldownManager", "Author")
BCDM.ADDON_LOGO = "|TInterface\\AddOns\\BetterCooldownManager\\Media\\Logo.png:16:16|t"
BCDM.PRETTY_ADDON_NAME = BCDM.ADDON_LOGO .. " " .. BCDM.ADDON_NAME

BCDM.CAST_BAR_TEST_MODE = false

if BCDM.LSM then BCDM.LSM:Register("statusbar", "Better Blizzard", [[Interface\AddOns\BetterCooldownManager\Media\BetterBlizzard.blp]]) end

function BCDM:PrettyPrint(MSG) print(BCDM.ADDON_NAME .. ":|r " .. MSG) end

function BCDM:ResolveLSM()
    local LSM = BCDM.LSM
    local General = BCDM.db.profile.General
    BCDM.Media = BCDM.Media or {}
    BCDM.Media.Font = LSM:Fetch("font", General.Fonts.Font) or STANDARD_TEXT_FONT
    BCDM.Media.Foreground = LSM:Fetch("statusbar", General.Textures.Foreground) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
    BCDM.Media.Background = LSM:Fetch("statusbar", General.Textures.Background) or "Interface\\Buttons\\WHITE8X8"
    BCDM.BACKDROP = { bgFile = BCDM.Media.Background, edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = {left = 0, right = 0, top = 0, bottom = 0} }
end

local function SetupSlashCommands()
    SLASH_BCDM1 = "/bcdm"
    SLASH_BCDM2 = "/bettercooldownmanager"
    SLASH_BCDM3 = "/cdm"
    SLASH_BCDM4 = "/bcm"
    SlashCmdList["BCDM"] = function() BCDM:CreateGUI() end
    if BCDM.db.global.DisplayLoginMessage then BCDM:PrettyPrint("'|cFF8080FF/bcdm|r' for in-game configuration.") end

    SLASH_BCDMRELOAD1 = "/rl"
    SlashCmdList["BCDMRELOAD"] = function() C_UI.Reload() end
end

local function PixelPerfect(value)
    if not value then return 0 end
    local _, screenHeight = GetPhysicalScreenSize()
    local uiScale = UIParent:GetEffectiveScale()
    local pixelSize = 768 / screenHeight / uiScale
    return pixelSize * math.floor(value / pixelSize + 0.5333)
end

function BCDM:AddBorder(parentFrame)
    if not parentFrame then return end
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize or 1
    local borderColour = { r = 0, g = 0, b = 0, a = 1 }
    local borderInset = PixelPerfect(0)
    parentFrame.BCDMBorders = parentFrame.BCDMBorders or {}
    local borderAnchor = parentFrame.Icon or parentFrame
    if #parentFrame.BCDMBorders == 0 then
        local function CreateBorderLine() return parentFrame:CreateTexture(nil, "OVERLAY") end
        local topBorder = CreateBorderLine()
        topBorder:SetPoint("TOPLEFT", borderAnchor, "TOPLEFT", borderInset, -borderInset)
        topBorder:SetPoint("TOPRIGHT", borderAnchor, "TOPRIGHT", -borderInset, -borderInset)
        local bottomBorder = CreateBorderLine()
        bottomBorder:SetPoint("BOTTOMLEFT", borderAnchor, "BOTTOMLEFT", borderInset, borderInset)
        bottomBorder:SetPoint("BOTTOMRIGHT", borderAnchor, "BOTTOMRIGHT", -borderInset, borderInset)
        local leftBorder = CreateBorderLine()
        leftBorder:SetPoint("TOPLEFT", borderAnchor, "TOPLEFT", borderInset, -borderInset)
        leftBorder:SetPoint("BOTTOMLEFT", borderAnchor, "BOTTOMLEFT", borderInset, borderInset)
        local rightBorder = CreateBorderLine()
        rightBorder:SetPoint("TOPRIGHT", borderAnchor, "TOPRIGHT", -borderInset, -borderInset)
        rightBorder:SetPoint("BOTTOMRIGHT", borderAnchor, "BOTTOMRIGHT", -borderInset, borderInset)
        parentFrame.BCDMBorders = { topBorder, bottomBorder, leftBorder, rightBorder }
    end
    local top, bottom, left, right = unpack(parentFrame.BCDMBorders)
    if top and bottom and left and right then
        local pixelSize = PixelPerfect(borderSize)
        top:SetHeight(pixelSize)
        bottom:SetHeight(pixelSize)
        left:SetWidth(pixelSize)
        right:SetWidth(pixelSize)
        local shouldShow = borderSize > 0
        for _, border in ipairs(parentFrame.BCDMBorders) do
            border:SetColorTexture(borderColour.r, borderColour.g, borderColour.b, borderColour.a)
            border:SetShown(shouldShow)
        end
    end
end

function BCDM:StripTextures(textureToStrip)
    if not textureToStrip then return end
    if textureToStrip.GetMaskTexture then
        local i = 1
        local textureMask = textureToStrip:GetMaskTexture(i)
        while textureMask do
            textureToStrip:RemoveMaskTexture(textureMask)
            i = i + 1
            textureMask = textureToStrip:GetMaskTexture(i)
        end
    end
    local textureParent = textureToStrip:GetParent()
    if textureParent then
        local regionCount = textureParent:GetNumRegions()
        for i = 1, regionCount do
            local textureRegion = select(i, textureParent:GetRegions())
            if textureRegion:IsObjectType("Texture") and textureRegion ~= textureToStrip and textureRegion:IsShown() then
                textureRegion:SetTexture(nil)
                textureRegion:Hide()
            end
        end
    end
end

-- Shared UI helpers live here so each module does not need its own copy of the
-- same region lookup, desaturation fallback, or cooldown-change check.
function BCDM:GetFrameRegionByType(parentFrame, regionType)
    if not parentFrame or not regionType then return end
    local regionCount = parentFrame:GetNumRegions()
    if not regionCount or regionCount <= 0 then return end
    for i = 1, regionCount do
        local region = select(i, parentFrame:GetRegions())
        if region and region:GetObjectType() == regionType then
            return region
        end
    end
end

function BCDM:SetIconDesaturation(icon, value)
    if not icon then return end
    if icon.SetDesaturation then
        icon:SetDesaturation(value)
        return
    end
    if icon.SetDesaturated then
        icon:SetDesaturated(value > 0)
    end
end

function BCDM:ShouldRefreshCooldownFrame(cooldownFrame, hasActiveCooldown, startTime, durationTime)
    if not cooldownFrame then return false end

    local oldStart, oldDuration = cooldownFrame:GetCooldownTimes()
    oldStart = tonumber(oldStart) or 0
    oldDuration = tonumber(oldDuration) or 0

    if hasActiveCooldown then
        if oldStart <= 0 or oldDuration <= 0 then
            return true
        end

        local oldEnd = (oldStart + oldDuration) / 1000
        local newEnd = (startTime or 0) + (durationTime or 0)
        return math.abs(oldEnd - newEnd) > 0.01
    end

    return oldStart > 0 and oldDuration > 0
end

function BCDM:IsOnUseTrinket(itemId)
    if not itemId then return false end
    local spellName, spellID = C_Item.GetItemSpell(itemId)
    return (spellID and spellID > 0) or (spellName and spellName ~= "")
end

-- Reapply countdown text styling after Blizzard or another addon recreates the
-- cooldown fontstring, or after icon sizing changes alter the desired scale.
function BCDM:ApplyCooldownText(viewer)
    local Viewer = type(viewer) == "string" and _G[viewer] or viewer
    if not Viewer then return end

    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = CooldownManagerDB.CooldownManager.General.CooldownText
    local childCount = Viewer:GetNumChildren()

    for i = 1, childCount do
        local icon = select(i, Viewer:GetChildren())
        if icon and icon.Cooldown then
            local textRegion = BCDM:GetFrameRegionByType(icon.Cooldown, "FontString")
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

function BCDM:GetIconDimensions(viewerDB)
    if not viewerDB then return 0, 0, true end
    local keepAspect = viewerDB.KeepAspectRatio
    if keepAspect == nil then
        keepAspect = true
    end

    local fallbackSize = viewerDB.IconSize or viewerDB.IconWidth or viewerDB.IconHeight or 32
    if keepAspect then
        return fallbackSize, fallbackSize, true
    end

    local iconWidth = viewerDB.IconWidth or fallbackSize
    local iconHeight = viewerDB.IconHeight or fallbackSize
    return iconWidth, iconHeight, false
end

function BCDM:GetIconTexCoords(width, height, baseZoom)
    local zoom = baseZoom or 0
    if zoom < 0 then zoom = 0 end
    if zoom > 0.49 then zoom = 0.49 end

    local left = zoom
    local right = 1 - zoom
    local top = zoom
    local bottom = 1 - zoom

    if not width or not height or width <= 0 or height <= 0 then
        return left, right, top, bottom
    end

    local aspect = width / height
    local uSpan = right - left
    local vSpan = bottom - top

    if aspect > 1 then
        local targetVSpan = uSpan / aspect
        local extra = (vSpan - targetVSpan) / 2
        if extra > 0 then
            top = top + extra
            bottom = bottom - extra
        end
    elseif aspect < 1 then
        local targetUSpan = vSpan * aspect
        local extra = (uSpan - targetUSpan) / 2
        if extra > 0 then
            left = left + extra
            right = right - extra
        end
    end

    return left, right, top, bottom
end

function BCDM:ApplyIconTexCoord(texture, width, height, baseZoom)
    if not texture then return end
    local left, right, top, bottom = BCDM:GetIconTexCoords(width, height, baseZoom)
    texture:SetTexCoord(left, right, top, bottom)
end

function BCDM:IsSecretValue(value)
    return type(value) == "number" and type(issecretvalue) == "function" and issecretvalue(value)
end

function BCDM:GetCooldownDesaturationCurves()
    if self.CooldownDesaturationCurve and self.CooldownGCDFilterCurve then
        return self.CooldownDesaturationCurve, self.CooldownGCDFilterCurve
    end

    if not (C_CurveUtil and C_CurveUtil.CreateCurve and Enum and Enum.LuaCurveType and Enum.LuaCurveType.Step) then
        return nil, nil
    end

    if not self.CooldownDesaturationCurve then
        self.CooldownDesaturationCurve = C_CurveUtil.CreateCurve()
        if self.CooldownDesaturationCurve then
            self.CooldownDesaturationCurve:SetType(Enum.LuaCurveType.Step)
            self.CooldownDesaturationCurve:AddPoint(0, 0)
            self.CooldownDesaturationCurve:AddPoint(0.001, 1)
        end
    end

    if not self.CooldownGCDFilterCurve then
        self.CooldownGCDFilterCurve = C_CurveUtil.CreateCurve()
        if self.CooldownGCDFilterCurve then
            self.CooldownGCDFilterCurve:SetType(Enum.LuaCurveType.Step)
            self.CooldownGCDFilterCurve:AddPoint(0, 0)
            self.CooldownGCDFilterCurve:AddPoint(1.6, 0)
            self.CooldownGCDFilterCurve:AddPoint(1.601, 1)
        end
    end

    return self.CooldownDesaturationCurve, self.CooldownGCDFilterCurve
end

function BCDM:Init()
    SetupSlashCommands()
    BCDM:ResolveLSM()
    BCDM:NormalizeCustomSpellSpecTokens()
    BCDM:SetupExternalAnchorHooks()
    if not C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then C_AddOns.LoadAddOn("Blizzard_CooldownViewer") end
end

function BCDM:CopyTable(defaultTable)
    if type(defaultTable) ~= "table" then return defaultTable end
    local newTable = {}
    for k, v in pairs(defaultTable) do
        if type(v) == "table" then
            newTable[k] = BCDM:CopyTable(v)
        else
            newTable[k] = v
        end
    end
    return newTable
end

function BCDM:UpdateBCDM()
    BCDM:ResolveLSM()
    BCDM:UpdateCooldownViewer("Essential")
    BCDM:UpdateCooldownViewer("Utility")
    BCDM:UpdateCooldownViewer("Buffs")
    BCDM:UpdatePowerBar()
    BCDM:UpdateSecondaryPowerBar()
    BCDM:UpdateCastBar()
    BCDM:UpdateCustomViewer()
    BCDM:UpdateTrinketBar()
    BCDM:RefreshCustomGlows()
    BCDM:DisableAuraOverlay()
end

local function GetFrameHorizontalExtents(frame)
    if not frame or not frame.IsShown or not frame:IsShown() then return nil, nil end
    local left = frame:GetLeft()
    local right = frame:GetRight()
    if not left or not right then return nil, nil end
    return left, right
end

function BCDM:GetEffectiveAnchorWidth(anchorName)
    local anchorFrame = anchorName and _G[anchorName]
    if not anchorFrame then return nil end

    local width = anchorFrame:GetWidth()
    if not width or width <= 0 then
        return width
    end

    if not self.GetTrinketAppendTargetViewerName or not self.TrinketBarContainer then
        return width
    end

    local appendViewerName = self:GetTrinketAppendTargetViewerName()
    if appendViewerName ~= anchorName then
        return width
    end

    local anchorLeft, anchorRight = GetFrameHorizontalExtents(anchorFrame)
    local trinketLeft, trinketRight = GetFrameHorizontalExtents(self.TrinketBarContainer)
    if not anchorLeft or not anchorRight or not trinketLeft or not trinketRight then
        return width
    end

    return math.max(anchorRight, trinketRight) - math.min(anchorLeft, trinketLeft)
end

function BCDM:QueueAnchorWidthUpdate(targetFrame, anchorName, delay)
    if not targetFrame or not anchorName then return end
    C_Timer.After(delay or 0.1, function()
        local anchorFrame = BCDM:GetEffectiveAnchorFrame(anchorName)
        if not anchorFrame then return end
        local anchorWidth = BCDM:GetEffectiveAnchorWidth(anchorName) or anchorFrame:GetWidth()
        if anchorWidth and anchorWidth > 0 then
            targetFrame:SetWidth(anchorWidth)
        end
    end)
end

local function GetViewerBaseAnchor(viewerType)
    local viewerSettings = BCDM.db and BCDM.db.profile and BCDM.db.profile.CooldownManager and BCDM.db.profile.CooldownManager[viewerType]
    if not viewerSettings or not viewerSettings.Layout then return nil end

    if viewerType == "Essential" then
        return {
            point = viewerSettings.Layout[1],
            relativeTo = UIParent,
            relativePoint = viewerSettings.Layout[2],
            x = viewerSettings.Layout[3],
            y = viewerSettings.Layout[4],
        }
    end

    local relativeTo = viewerSettings.Layout[2] == "NONE" and UIParent
        or (BCDM.GetEffectiveAnchorFrame and BCDM:GetEffectiveAnchorFrame(viewerSettings.Layout[2]))
        or _G[viewerSettings.Layout[2]]
    return {
        point = viewerSettings.Layout[1],
        relativeTo = relativeTo,
        relativePoint = viewerSettings.Layout[3],
        x = viewerSettings.Layout[4],
        y = viewerSettings.Layout[5],
    }
end

function BCDM:GetAppendedTrinketHorizontalSpan(viewerType)
    if not self.IsTrinketBarAppendedToViewer or not self:IsTrinketBarAppendedToViewer(viewerType) then
        return 0
    end

    local viewerName = self.DBViewerToCooldownManagerViewer and self.DBViewerToCooldownManagerViewer[viewerType]
    local viewerFrame = viewerName and _G[viewerName]
    local trinketFrame = self.TrinketBarContainer
    if not viewerFrame or not trinketFrame or not trinketFrame:IsShown() then
        return 0
    end

    local viewerLeft, viewerRight = GetFrameHorizontalExtents(viewerFrame)
    local trinketLeft, trinketRight = GetFrameHorizontalExtents(trinketFrame)
    if not viewerLeft or not viewerRight or not trinketLeft or not trinketRight then
        return 0
    end

    local appendSide = self.db and self.db.profile and self.db.profile.CooldownManager
        and self.db.profile.CooldownManager.Trinket and self.db.profile.CooldownManager.Trinket.AppendSide or "RIGHT"

    if appendSide == "LEFT" then
        return math.max(0, viewerLeft - trinketLeft)
    end

    return math.max(0, trinketRight - viewerRight)
end

function BCDM:GetAppendedViewerOffsetX(viewerType)
    local viewerSettings = self.db and self.db.profile and self.db.profile.CooldownManager and self.db.profile.CooldownManager[viewerType]
    if not viewerSettings or not viewerSettings.Layout then return 0 end

    local span = self:GetAppendedTrinketHorizontalSpan(viewerType)
    if span <= 0 then return 0 end

    local appendSide = self.db and self.db.profile and self.db.profile.CooldownManager
        and self.db.profile.CooldownManager.Trinket and self.db.profile.CooldownManager.Trinket.AppendSide or "RIGHT"
    local point = viewerSettings.Layout[1] or "CENTER"

    if point:find("LEFT") then
        return appendSide == "LEFT" and span or 0
    elseif point:find("RIGHT") then
        return appendSide == "RIGHT" and -span or 0
    end

    return appendSide == "LEFT" and (span * 0.5) or -(span * 0.5)
end

function BCDM:GetViewerAppendAnchor(viewerType)
    local frameName = "BCDM_" .. viewerType .. "AppendAnchor"
    if self[frameName] then
        return self[frameName]
    end

    local anchor = CreateFrame("Frame", frameName, UIParent)
    anchor:SetSize(1, 1)
    anchor:Hide()
    self[frameName] = anchor
    return anchor
end

function BCDM:GetEffectiveAnchorFrame(anchorName)
    local anchorFrame = anchorName and _G[anchorName]
    if not anchorFrame then return nil end

    if anchorName == "EssentialCooldownViewer" and self.BCDM_EssentialAppendAnchor and self.BCDM_EssentialAppendAnchor:IsShown() then
        return self.BCDM_EssentialAppendAnchor
    end

    if anchorName == "UtilityCooldownViewer" and self.BCDM_UtilityAppendAnchor and self.BCDM_UtilityAppendAnchor:IsShown() then
        return self.BCDM_UtilityAppendAnchor
    end

    return anchorFrame
end

function BCDM:RefreshAppendedViewerPosition(viewerType)
    local viewerName = self.DBViewerToCooldownManagerViewer and self.DBViewerToCooldownManagerViewer[viewerType]
    local viewerFrame = viewerName and _G[viewerName]
    local baseAnchor = GetViewerBaseAnchor(viewerType)
    if not viewerFrame or not baseAnchor then return end

    local appendAnchor = self:GetViewerAppendAnchor(viewerType)
    local span = self:GetAppendedTrinketHorizontalSpan(viewerType)
    if span <= 0 then
        if appendAnchor then
            appendAnchor:Hide()
        end
        viewerFrame:ClearAllPoints()
        viewerFrame:SetPoint(baseAnchor.point, baseAnchor.relativeTo, baseAnchor.relativePoint, (baseAnchor.x or 0) - 0.1, baseAnchor.y or 0)
        return
    end

    local trinketFrame = self.TrinketBarContainer
    local combinedWidth = self:GetEffectiveAnchorWidth(viewerName) or viewerFrame:GetWidth()
    local combinedHeight = math.max(viewerFrame:GetHeight() or 1, (trinketFrame and trinketFrame:GetHeight()) or 1)

    appendAnchor:ClearAllPoints()
    appendAnchor:SetPoint(baseAnchor.point, baseAnchor.relativeTo, baseAnchor.relativePoint, baseAnchor.x or 0, baseAnchor.y or 0)
    appendAnchor:SetSize(combinedWidth or 1, combinedHeight or 1)
    appendAnchor:Show()

    local extraX = self:GetAppendedViewerOffsetX(viewerType)
    viewerFrame:ClearAllPoints()
    viewerFrame:SetPoint(baseAnchor.point, appendAnchor, baseAnchor.point, extraX - 0.1, 0)
end

function BCDM:RefreshAppendedViewerPositions()
    BCDM:RefreshAppendedViewerPosition("Essential")
    BCDM:RefreshAppendedViewerPosition("Utility")
end

function BCDM:SetupExternalAnchorHooks()
    if self.uufAnchorHookInstalled then
        return true
    end

    if not C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") or not UUF or not UUF.CreatePositionController then
        return false
    end

    hooksecurefunc(UUF, "CreatePositionController", function()
        BCDM:RefreshExternalCDMAnchors()
    end)

    self.uufAnchorHookInstalled = true
    return true
end

function BCDM:RefreshExternalCDMAnchors()
    BCDM:SetupExternalAnchorHooks()

    local uufAnchor = _G["UUF_CDMAnchor"]
    if not uufAnchor then return end

    local effectiveAnchor = BCDM:GetEffectiveAnchorFrame("EssentialCooldownViewer") or _G["EssentialCooldownViewer"]
    if not effectiveAnchor then return end

    uufAnchor:ClearAllPoints()
    uufAnchor:SetAllPoints(effectiveAnchor)
    uufAnchor:SetSize(effectiveAnchor:GetWidth() or 1, effectiveAnchor:GetHeight() or 1)
    if effectiveAnchor:IsShown() then
        uufAnchor:Show()
    else
        uufAnchor:Hide()
    end
end

function BCDM:RefreshCooldownViewerOverlay(viewerType)
    local viewerName = self.DBViewerToCooldownManagerViewer and self.DBViewerToCooldownManagerViewer[viewerType]
    local overlay = self[viewerType .. "CooldownViewerOverlay"]
    local viewerFrame = viewerName and self:GetEffectiveAnchorFrame(viewerName)
    if not overlay or not viewerFrame then return end

    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT", viewerFrame, "TOPLEFT", -8, 8)
    overlay:SetPoint("BOTTOMRIGHT", viewerFrame, "BOTTOMRIGHT", 8, -8)
end

function BCDM:RefreshCooldownViewerOverlays()
    BCDM:RefreshCooldownViewerOverlay("Essential")
    BCDM:RefreshCooldownViewerOverlay("Utility")
    if BCDM.BuffIconCooldownViewerOverlay and _G["BuffIconCooldownViewer"] then
        BCDM.BuffIconCooldownViewerOverlay:ClearAllPoints()
        BCDM.BuffIconCooldownViewerOverlay:SetPoint("TOPLEFT", _G["BuffIconCooldownViewer"], "TOPLEFT", -8, 8)
        BCDM.BuffIconCooldownViewerOverlay:SetPoint("BOTTOMRIGHT", _G["BuffIconCooldownViewer"], "BOTTOMRIGHT", 8, -8)
    end
end

function BCDM:CreateCooldownViewerOverlays()
    local OVERLAY_COLOUR = { 64/255, 128/255, 255/255, 1 }
    if _G["EssentialCooldownViewer"] then
        local EssentialCooldownViewerOverlay = CreateFrame("Frame", "BCDM_EssentialCooldownViewerOverlay", UIParent, "BackdropTemplate")
        EssentialCooldownViewerOverlay:SetBackdrop({ edgeFile = "Interface\\AddOns\\BetterCooldownManager\\Media\\Glow.tga", edgeSize = 8, insets = {left = -8, right = -8, top = -8, bottom = -8} })
        EssentialCooldownViewerOverlay:SetBackdropColor(0, 0, 0, 0)
        EssentialCooldownViewerOverlay:SetBackdropBorderColor(unpack(OVERLAY_COLOUR))
        EssentialCooldownViewerOverlay:Hide()
        BCDM.EssentialCooldownViewerOverlay = EssentialCooldownViewerOverlay
    end

    if _G["UtilityCooldownViewer"] then
        local UtilityCooldownViewerOverlay = CreateFrame("Frame", "BCDM_UtilityCooldownViewerOverlay", UIParent, "BackdropTemplate")
        UtilityCooldownViewerOverlay:SetBackdrop({ edgeFile = "Interface\\AddOns\\BetterCooldownManager\\Media\\Glow.tga", edgeSize = 8, insets = {left = -8, right = -8, top = -8, bottom = -8} })
        UtilityCooldownViewerOverlay:SetBackdropColor(0, 0, 0, 0)
        UtilityCooldownViewerOverlay:SetBackdropBorderColor(unpack(OVERLAY_COLOUR))
        UtilityCooldownViewerOverlay:Hide()
        BCDM.UtilityCooldownViewerOverlay = UtilityCooldownViewerOverlay
    end

    if _G["BuffIconCooldownViewer"] then
        local BuffIconCooldownViewerOverlay = CreateFrame("Frame", "BCDM_BuffIconCooldownViewerOverlay", UIParent, "BackdropTemplate")
        BuffIconCooldownViewerOverlay:SetBackdrop({ edgeFile = "Interface\\AddOns\\BetterCooldownManager\\Media\\Glow.tga", edgeSize = 8, insets = {left = -8, right = -8, top = -8, bottom = -8} })
        BuffIconCooldownViewerOverlay:SetBackdropColor(0, 0, 0, 0)
        BuffIconCooldownViewerOverlay:SetBackdropBorderColor(unpack(OVERLAY_COLOUR))
        BuffIconCooldownViewerOverlay:Hide()
        BCDM.BuffIconCooldownViewerOverlay = BuffIconCooldownViewerOverlay
    end

    BCDM:RefreshCooldownViewerOverlays()
end

function BCDM:ClearTicks()
    for _, tick in ipairs(BCDM.SecondaryPowerBar.Ticks) do
        tick:Hide()
    end
end

function BCDM:CreateTicks(count)
    BCDM:ClearTicks()
    if not count or count <= 1 then return end
    if count > 10 then count = 10 end
    local width = BCDM.SecondaryPowerBar.Status:GetWidth()
    for i = 1, count - 1 do
        local tick = BCDM.SecondaryPowerBar.Ticks[i]
        if not tick then
            tick = BCDM.SecondaryPowerBar.Status:CreateTexture(nil, "OVERLAY")
            tick:SetColorTexture(0, 0, 0, 1)
            BCDM.SecondaryPowerBar.Ticks[i] = tick
        end
        local tickPosition = (i / count) * width
        tick:ClearAllPoints()
        tick:SetSize(1, BCDM.SecondaryPowerBar:GetHeight() - 2)
        tick:SetPoint("LEFT", BCDM.SecondaryPowerBar.Status, "LEFT", tickPosition - 0.1, 0)
        tick:SetDrawLayer("OVERLAY", 7)
        tick:Show()
    end
end


function BCDM:OpenURL(title, urlText)
    StaticPopupDialogs["BCDM_URL_POPUP"] = {
        text = title or "",
        button1 = CLOSE,
        hasEditBox = true,
        editBoxWidth = 300,
        OnShow = function(self)
            self.EditBox:SetText(urlText or "")
            self.EditBox:SetFocus()
            self.EditBox:HighlightText()
        end,
        OnAccept = function(self) end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    local urlDialog = StaticPopup_Show("BCDM_URL_POPUP")
    if urlDialog then
        urlDialog:SetFrameStrata("TOOLTIP")
    end
    return urlDialog
end

function BCDM:CreatePrompt(title, text, onAccept, onCancel, acceptText, cancelText)
    StaticPopupDialogs["BCDM_PROMPT_DIALOG"] = {
        text = text or "",
        button1 = acceptText or ACCEPT,
        button2 = cancelText or CANCEL,
        OnAccept = function(self, data)
            if data and data.onAccept then
                data.onAccept()
            end
        end,
        OnCancel = function(self, data)
            if data and data.onCancel then
                data.onCancel()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        showAlert = true,
    }
    local promptDialog = StaticPopup_Show("BCDM_PROMPT_DIALOG", title, text)
    if promptDialog then
        promptDialog.data = { onAccept = onAccept, onCancel = onCancel }
        promptDialog:SetFrameStrata("TOOLTIP")
    end
    return promptDialog
end

local function ResolveSpecToken(targetSpec)
    if targetSpec then
        return BCDM:NormalizeSpecToken(targetSpec)
    end
    local specIndex = GetSpecialization()
    if not specIndex then return end
    local specID, specName = GetSpecializationInfo(specIndex)
    return BCDM:NormalizeSpecToken(specName, specID, specIndex)
end

function BCDM:AdjustSpellLayoutIndex(direction, spellId, customDB, targetClass, targetSpec)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager[customDB]
    local playerClass = targetClass or select(2, UnitClass("player"))
    local playerSpecialization = ResolveSpecToken(targetSpec)
    local DefensiveSpells = CustomDB.Spells

    if not playerClass or not playerSpecialization then return end
    if not DefensiveSpells[playerClass] or not DefensiveSpells[playerClass][playerSpecialization] or not DefensiveSpells[playerClass][playerSpecialization][spellId] then return end

    local currentIndex = DefensiveSpells[playerClass][playerSpecialization][spellId].layoutIndex
    local newIndex = currentIndex + direction

    local totalSpells = 0

    for _ in pairs(DefensiveSpells[playerClass][playerSpecialization]) do totalSpells = totalSpells + 1 end
    if newIndex < 1 or newIndex > totalSpells then return end

    for _, data in pairs(DefensiveSpells[playerClass][playerSpecialization]) do
        if data.layoutIndex == newIndex then
            data.layoutIndex = currentIndex
            break
        end
    end

    DefensiveSpells[playerClass][playerSpecialization][spellId].layoutIndex = newIndex
    BCDM:NormalizeSpellLayoutIndices(customDB, playerClass, playerSpecialization)
    if customDB == "Custom" then
        BCDM:UpdateCustomCooldownViewer()
    else
        BCDM:UpdateAdditionalCustomCooldownViewer()
    end
end

function BCDM:NormalizeSpellLayoutIndices(customDB, playerClass, playerSpecialization)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager[customDB]
    local DefensiveSpells = CustomDB.Spells

    if not DefensiveSpells[playerClass] or not DefensiveSpells[playerClass][playerSpecialization] then return end

    local ordered = {}
    for spellId, data in pairs(DefensiveSpells[playerClass][playerSpecialization]) do
        ordered[#ordered + 1] = {
            spellId = spellId,
            data = data,
            sortIndex = data.layoutIndex or math.huge,
        }
    end

    table.sort(ordered, function(a, b)
        if a.sortIndex == b.sortIndex then
            return tostring(a.spellId) < tostring(b.spellId)
        end
        return a.sortIndex < b.sortIndex
    end)

    for index, entry in ipairs(ordered) do
        entry.data.layoutIndex = index
    end
end

function BCDM:AdjustSpellList(spellId, adjustingHow, customDB, targetClass, targetSpec)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager[customDB]
    local playerClass = targetClass or select(2, UnitClass("player"))
    local playerSpecialization = ResolveSpecToken(targetSpec)
    local DefensiveSpells = CustomDB.Spells

    if not playerClass or not playerSpecialization then return end
    if not DefensiveSpells[playerClass] then
        DefensiveSpells[playerClass] = {}
    end
    if not DefensiveSpells[playerClass][playerSpecialization] then
        DefensiveSpells[playerClass][playerSpecialization] = {}
    end

    if adjustingHow == "add" then
        local maxIndex = 0
        for _, data in pairs(DefensiveSpells[playerClass][playerSpecialization]) do
            if data.layoutIndex > maxIndex then
                maxIndex = data.layoutIndex
            end
        end
        DefensiveSpells[playerClass][playerSpecialization][spellId] = { isActive = true, layoutIndex = maxIndex + 1 }
    elseif adjustingHow == "remove" then
        DefensiveSpells[playerClass][playerSpecialization][spellId] = nil
    end

    BCDM:NormalizeSpellLayoutIndices(customDB, playerClass, playerSpecialization)
    BCDM:UpdateAdditionalCustomCooldownViewer()
end


function BCDM:RepositionSecondaryBar()
    local SpecsNeedingAltPower = {
        PALADIN = { 66, 70 },           -- Ret
        SHAMAN  = { 263 },              -- Ele, Enh
        EVOKER  = { 1467, 1473 },       -- Dev, Aug
        WARLOCK = { 265, 266, 267 },    -- Aff, Demo, Dest
    }
    local class = select(2, UnitClass("player"))
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = GetSpecializationInfo(specIndex)
    local classSpecs = SpecsNeedingAltPower[class]
    if not classSpecs then return false end
    for _, requiredSpec in ipairs(classSpecs) do if specID == requiredSpec then return true end end
    return false
end

BCDM.AnchorParents = {
    ["Utility"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
        },
        { "EssentialCooldownViewer", "NONE", "BCDM_PowerBar", "BCDM_SecondaryPowerBar"},
    },
    ["Buffs"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["BCDM_CastBar"] = "|cFF8080FFBCDM|r: Cast Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CastBar" },
    },
    ["CustomViewer"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["BCDM_TrinketBar"] = "|cFF8080FFBCDM|r: Trinket Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_TrinketBar" },
    },
    ["Custom"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["BCDM_AdditionalCustomCooldownViewer"] = "|cFF8080FFBCDM|r: Additional Custom Bar",
            ["BCDM_CustomItemSpellBar"] = "|cFF8080FFBCDM|r: Items/Spells Bar",
            ["BCDM_CustomItemBar"] = "|cFF8080FFBCDM|r: Item Bar",
            ["BCDM_TrinketBar"] = "|cFF8080FFBCDM|r: Trinket Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_AdditionalCustomCooldownViewer", "BCDM_CustomItemBar", "BCDM_CustomItemSpellBar", "BCDM_TrinketBar" },
    },
    ["AdditionalCustom"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["BCDM_CustomCooldownViewer"] = "|cFF8080FFBCDM|r: Custom Bar",
            ["BCDM_CustomItemBar"] = "|cFF8080FFBCDM|r: Item Bar",
            ["BCDM_CustomItemSpellBar"] = "|cFF8080FFBCDM|r: Items/Spells Bar",
            ["BCDM_TrinketBar"] = "|cFF8080FFBCDM|r: Trinket Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CustomCooldownViewer", "BCDM_CustomItemBar", "BCDM_CustomItemSpellBar", "BCDM_TrinketBar" },
    },
    ["Item"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["BCDM_CustomCooldownViewer"] = "|cFF8080FFBCDM|r: Custom Bar",
            ["BCDM_AdditionalCustomCooldownViewer"] = "|cFF8080FFBCDM|r: Additional Custom Bar",
            ["BCDM_CustomItemSpellBar"] = "|cFF8080FFBCDM|r: Items/Spells Bar",
            ["BCDM_TrinketBar"] = "|cFF8080FFBCDM|r: Trinket Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CustomCooldownViewer", "BCDM_AdditionalCustomCooldownViewer", "BCDM_CustomItemSpellBar", "BCDM_TrinketBar" },
    },
    ["Trinket"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["BCDM_CustomViewer"] = "|cFF8080FFBCDM|r: Custom Viewer",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CustomViewer" },
    },
    ["ItemSpell"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
            ["BCDM_CustomCooldownViewer"] = "|cFF8080FFBCDM|r: Custom Bar",
            ["BCDM_AdditionalCustomCooldownViewer"] = "|cFF8080FFBCDM|r: Additional Custom Bar",
            ["BCDM_CustomItemBar"] = "|cFF8080FFBCDM|r: Item Bar",
            ["BCDM_TrinketBar"] = "|cFF8080FFBCDM|r: Trinket Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CustomCooldownViewer", "BCDM_AdditionalCustomCooldownViewer", "BCDM_CustomItemBar", "BCDM_TrinketBar" },
    },
    ["Power"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_SecondaryPowerBar" },
    },
    ["SecondaryPower"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar"},
    },
    ["CastBar"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBCDM|r: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBCDM|r: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    }
}

StaticPopupDialogs["BCDM_RELOAD"] = {
    text = "You must |cFFFF4040reload|r in order for changes to take effect. Do you want to reload now?",
    button1 = "Reload",
    button2 = "Cancel",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
function BCDM:PromptReload()
    StaticPopup_Show("BCDM_RELOAD")
end
