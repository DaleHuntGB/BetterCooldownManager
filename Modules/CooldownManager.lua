local _, BCDM = ...
local CooldownViewerToDB = BCDM.CooldownViewerToDB
local CooldownManagerViewers = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
}

local IconPerCooldownViewer = {
    ["EssentialCooldownViewer"] = 0,
    ["UtilityCooldownViewer"] = 0,
    ["BuffIconCooldownViewer"] = 0,
}

local function StripTextures(textureToStrip)
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
        for _, textureRegion in ipairs({ textureParent:GetRegions() }) do
            if textureRegion:IsObjectType("Texture") and textureRegion ~= textureToStrip and textureRegion:IsShown() then
                textureRegion:SetTexture(nil)
                textureRegion:Hide()
            end
        end
    end
end

local function SizeIconsInCooldownViewer(viewerName)
    local CooldownManagerDB = BCDM.db.profile
    local CooldownViewerDB = CooldownManagerDB[CooldownViewerToDB[viewerName]]
    local IconSize = CooldownViewerDB.IconSize
    if not viewerName then return end
    local viewer = _G[viewerName]
    if not viewer then return end
    local icons = {viewer:GetChildren()}
    if viewerName == "BuffIconCooldownViewer" then
        for i, icon in ipairs(icons) do
            if not icon.layoutIndex and not icon:GetID() then
                icon._creationOrder = icon._creationOrder or i
            end
        end
    end
    table.sort(icons, function(a, b) local la = a.layoutIndex or a:GetID() or a._creationOrder or 0 local lb = b.layoutIndex or b:GetID() or b._creationOrder or 0 return la < lb end)
    for _, icon in ipairs(icons) do
        if icon then
            icon:SetSize(IconSize[1], IconSize[2])
        end
    end
end

local function AdjustChargeCount(cooldownViewer)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownViewerDB = CooldownManagerDB[CooldownViewerToDB[cooldownViewer]]
    for _, child in ipairs({ _G[cooldownViewer]:GetChildren() }) do
        if child and child.ChargeCount and child.ChargeCount.Current then
            local current = child.ChargeCount.Current
            current:SetFont(BCDM.Media.Font, CooldownViewerDB.Count.FontSize, GeneralDB.FontFlag)
            current:ClearAllPoints()
            current:SetPoint(CooldownViewerDB.Count.Anchors[1], child, CooldownViewerDB.Count.Anchors[2], CooldownViewerDB.Count.Anchors[3], CooldownViewerDB.Count.Anchors[4])
            current:SetTextColor(CooldownViewerDB.Count.Colour[1], CooldownViewerDB.Count.Colour[2], CooldownViewerDB.Count.Colour[3], 1)
            current:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
            current:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        end
    end
    for _, child in ipairs({ _G[cooldownViewer]:GetChildren() }) do
        if child and child.Applications then
            local max = child.Applications.Applications
            max:SetFont(BCDM.Media.Font, CooldownViewerDB.Count.FontSize, GeneralDB.FontFlag)
            max:ClearAllPoints()
            max:SetPoint(CooldownViewerDB.Count.Anchors[1], child, CooldownViewerDB.Count.Anchors[2], CooldownViewerDB.Count.Anchors[3], CooldownViewerDB.Count.Anchors[4])
            max:SetTextColor(CooldownViewerDB.Count.Colour[1], CooldownViewerDB.Count.Colour[2], CooldownViewerDB.Count.Colour[3], 1)
            max:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
            max:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        end
    end
end

local function UpdateIconZoom()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    for _, cooldownViewer in ipairs(CooldownManagerViewers) do
        for _, viewerChild in ipairs({_G[cooldownViewer]:GetChildren()}) do
            if viewerChild and viewerChild.Icon then
                viewerChild.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
            end
        end
    end
end

local function SkinCooldownManager()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    C_CVar.SetCVar("cooldownViewerEnabled", 1)
    SizeIconsInCooldownViewer("EssentialCooldownViewer")
    SizeIconsInCooldownViewer("UtilityCooldownViewer")
    SizeIconsInCooldownViewer("BuffIconCooldownViewer")
    for _, cooldownViewer in ipairs(CooldownManagerViewers) do
        for _, viewerChild in ipairs({_G[cooldownViewer]:GetChildren()}) do
            if viewerChild and not viewerChild.isSkinned then
                -- Skin Icon, Strip Textures
                if viewerChild.Icon then
                    StripTextures(viewerChild.Icon)
                    viewerChild.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
                    viewerChild.isSkinned = true
                end
                -- Skin Cooldown
                if viewerChild.Cooldown then
                    viewerChild.Cooldown:ClearAllPoints()
                    viewerChild.Cooldown:SetPoint("TOPLEFT", viewerChild, "TOPLEFT", 0, 0)
                    viewerChild.Cooldown:SetPoint("BOTTOMRIGHT", viewerChild, "BOTTOMRIGHT", 0, 0)
                    viewerChild.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
                    viewerChild.Cooldown:SetDrawEdge(false)
                    viewerChild.Cooldown:SetDrawSwipe(true)
                    viewerChild.Cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
                end
                if viewerChild.CooldownFlash then
                    viewerChild.CooldownFlash:SetAlpha(0)
                end
                -- Add Border
                BCDM:AddPixelBorder(viewerChild)
            end
        end
    end
    AdjustChargeCount("EssentialCooldownViewer")
    AdjustChargeCount("UtilityCooldownViewer")
    AdjustChargeCount("BuffIconCooldownViewer")
end

local function NudgeViewer(viewerName, xOffset, yOffset)
    local viewer = _G[viewerName]
    if not viewer then return end
    local point, relativeTo, relativePoint, xOfs, yOfs = viewer:GetPoint(1)
    viewer:ClearAllPoints()
    viewer:SetPoint(point, relativeTo, relativePoint, xOfs + xOffset, yOfs + yOffset)
end

local function PositionCooldownViewers()
    local EssentialCooldownViewer = _G["EssentialCooldownViewer"]
    local UtilityCooldownViewer = _G["UtilityCooldownViewer"]
    local BuffIconCooldownViewer = _G["BuffIconCooldownViewer"]
    local CooldownManagerDB = BCDM.db.profile
    local EssentialDB = CooldownManagerDB.Essential
    local UtilityDB = CooldownManagerDB.Utility
    local BuffsDB = CooldownManagerDB.Buffs
    if EssentialCooldownViewer then
        EssentialCooldownViewer:ClearAllPoints()
        EssentialCooldownViewer:SetPoint(EssentialDB.Anchors[1], UIParent, EssentialDB.Anchors[2], EssentialDB.Anchors[3], EssentialDB.Anchors[4])
        NudgeViewer("EssentialCooldownViewer", -0.1, 0)
    end
    if UtilityCooldownViewer then
        UtilityCooldownViewer:ClearAllPoints()
        local anchorParent = UtilityDB.Anchors[2] or "UIParent"
        UtilityCooldownViewer:SetPoint(UtilityDB.Anchors[1], _G[anchorParent], UtilityDB.Anchors[3], UtilityDB.Anchors[4], UtilityDB.Anchors[5])
        NudgeViewer("UtilityCooldownViewer", 0, 0)
    end
    if BuffIconCooldownViewer then
        BuffIconCooldownViewer:ClearAllPoints()
        local anchorParent = BuffsDB.Anchors[2] or "UIParent"
        BuffIconCooldownViewer:SetPoint(BuffsDB.Anchors[1], _G[anchorParent], BuffsDB.Anchors[3], BuffsDB.Anchors[4], BuffsDB.Anchors[5])
        NudgeViewer("BuffIconCooldownViewer", 0, 0)
    end
end

local function AdjustCooldownManagerStrata()
    _G["EssentialCooldownViewer"]:SetFrameStrata("LOW")
    _G["UtilityCooldownViewer"]:SetFrameStrata("LOW")
    _G["BuffIconCooldownViewer"]:SetFrameStrata("LOW")
end

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return end
    if cooldown.FUIText then
        return cooldown.FUIText
    end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            cooldown.FUIText = region
            return region
        end
    end
end

local function ApplyCooldownText(cooldownViewer)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = GeneralDB.CooldownText
    local Viewer = _G[cooldownViewer]
    if not Viewer then return end
    for _, icon in ipairs({ Viewer:GetChildren() }) do
        if icon and icon.Cooldown then
            local textRegion = FetchCooldownTextRegion(icon.Cooldown)
            if textRegion then
                textRegion:SetFont(BCDM.Media.Font, CooldownTextDB.FontSize, GeneralDB.FontFlag)
                textRegion:SetTextColor(CooldownTextDB.Colour[1], CooldownTextDB.Colour[2], CooldownTextDB.Colour[3], 1)
                textRegion:ClearAllPoints()
                textRegion:SetPoint(CooldownTextDB.Anchors[1], icon, CooldownTextDB.Anchors[2], CooldownTextDB.Anchors[3], CooldownTextDB.Anchors[4])
                textRegion:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
                textRegion:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
            end
        end
    end
end

local function SetCooldownViewerPoints(cooldownViewer)
    local CooldownManagerDB = BCDM.db.profile
    local viewerDB = CooldownManagerDB[CooldownViewerToDB[cooldownViewer]]
    local viewer = _G[cooldownViewer]
    if not viewer then return end
    local point, relativeTo, relativePoint, xOfs, yOfs = viewer:GetPoint(1)
    viewer:ClearAllPoints()
    viewer:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
    viewerDB.Anchors[1] = point
    viewerDB.Anchors[2] = relativePoint
    viewerDB.Anchors[3] = xOfs
    viewerDB.Anchors[4] = yOfs
end

function BCDM:SetupCooldownManager()
    C_CVar.SetCVar("cooldownViewerEnabled", 1)
    PositionCooldownViewers()
    for cooldownViewer, _ in pairs(IconPerCooldownViewer) do ApplyCooldownText(cooldownViewer) end
    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function() PositionCooldownViewers() SizeIconsInCooldownViewer("EssentialCooldownViewer") SizeIconsInCooldownViewer("UtilityCooldownViewer") SizeIconsInCooldownViewer("BuffIconCooldownViewer") BCDM:SetPowerBarWidth() BCDM:SetSecondaryPowerBarWidth() BCDM:SetCastBarWidth() AdjustCooldownManagerStrata() end)
    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function() PositionCooldownViewers() SizeIconsInCooldownViewer("EssentialCooldownViewer") SizeIconsInCooldownViewer("UtilityCooldownViewer") SizeIconsInCooldownViewer("BuffIconCooldownViewer") BCDM:SetPowerBarWidth() BCDM:SetSecondaryPowerBarWidth() BCDM:SetCastBarWidth() AdjustCooldownManagerStrata() end)
    for _, cooldownViewer in ipairs(CooldownManagerViewers) do
        hooksecurefunc(_G[cooldownViewer], "RefreshLayout", function() if InCombatLockdown() then return end SkinCooldownManager() PositionCooldownViewers() SizeIconsInCooldownViewer("EssentialCooldownViewer") SizeIconsInCooldownViewer("UtilityCooldownViewer") SizeIconsInCooldownViewer("BuffIconCooldownViewer") BCDM:UpdateCustomIcons() BCDM:SetPowerBarWidth() BCDM:SetSecondaryPowerBarWidth() BCDM:SetCastBarWidth() AdjustCooldownManagerStrata() BCDM:UpdatePowerBar() BCDM:UpdateSecondaryPowerBar() BCDM:UpdateCastBar() end)
    end
    BCDM:SetupCentreBuffs()
    hooksecurefunc(EssentialCooldownViewer, "OnSystemPositionChange", function(...) SetCooldownViewerPoints("EssentialCooldownViewer") end)
end

function BCDM:UpdateCooldownViewer(cooldownViewer)
    BCDM:ResolveMedia()
    UpdateIconZoom()
    SizeIconsInCooldownViewer(cooldownViewer)
    AdjustChargeCount(cooldownViewer)
    ApplyCooldownText(cooldownViewer)
    AdjustCooldownManagerStrata()
    if _G[cooldownViewer] and _G[cooldownViewer].Layout then _G[cooldownViewer]:Layout() end
    PositionCooldownViewers()
    BCDM:SetPowerBarWidth()
    BCDM:SetSecondaryPowerBarWidth()
    BCDM:SetCastBarWidth()
    if cooldownViewer == "CustomCooldownViewer" then
        BCDM:UpdateCustomIcons()
    end
    if cooldownViewer == "ItemCooldownViewer" then
        BCDM:UpdateItemIcons()
    end
end

function BCDM:RefreshAllViewers()
    BCDM:UpdateCooldownViewer("EssentialCooldownViewer")
    BCDM:UpdateCooldownViewer("UtilityCooldownViewer")
    BCDM:UpdateCooldownViewer("BuffIconCooldownViewer")
    BCDM:UpdateCooldownViewer("CustomCooldownViewer")
end