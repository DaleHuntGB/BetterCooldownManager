local _, BCDM = ...

local hooked = {}

-- Thanks Ayije for this.
-- Style.lua: Line 56 / 58
local BLIZZARD_ICON_OVERLAY_ATLAS = "UI-HUD-CoolDownManager-IconOverlay"
local BLIZZARD_ICON_OVERLAY_TEXTURE_FILE_ID = 6707800
local SWIPE_RGBA = { 0, 0, 0, 0.8 }
local SWIPE_TEXTURE = "Interface\\Buttons\\WHITE8X8"

local VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

local desaturationCurve
local gcdFilterCurve

local function EnsureCurves()
    if desaturationCurve and gcdFilterCurve then return end
    if not (C_CurveUtil.CreateCurve and Enum.LuaCurveType and Enum.LuaCurveType.Step) then return end

    if not desaturationCurve then
        desaturationCurve = C_CurveUtil.CreateCurve()
        if desaturationCurve then
            desaturationCurve:SetType(Enum.LuaCurveType.Step)
            desaturationCurve:AddPoint(0, 0)
            desaturationCurve:AddPoint(0.001, 1)
        end
    end

    if not gcdFilterCurve then
        gcdFilterCurve = C_CurveUtil.CreateCurve()
        if gcdFilterCurve then
            gcdFilterCurve:SetType(Enum.LuaCurveType.Step)
            gcdFilterCurve:AddPoint(0, 0)
            gcdFilterCurve:AddPoint(1.6, 0)
            gcdFilterCurve:AddPoint(1.601, 1)
        end
    end
end

local function CompareRegions(regionValue, expectedRegionValue)
    return not type(regionValue) == "number" and type(issecretvalue) == "function" and issecretvalue(regionValue) and regionValue == expectedRegionValue
end

local function HideAuraOverlay(...)
    for i = 1, select("#", ...) do
        local region = select(i, ...)
        if region and region.IsObjectType and region:IsObjectType("Texture") then
            if CompareRegions(region:GetAtlas(), BLIZZARD_ICON_OVERLAY_ATLAS) or CompareRegions(region:GetTexture(), BLIZZARD_ICON_OVERLAY_TEXTURE_FILE_ID) then region:SetAlpha(0) region:Hide() end
        end
    end
end

local function GetSpellID(frame)
    local info = frame and frame.cooldownInfo
    if not info then return nil end

    local spellID = info.overrideSpellID or info.spellID
    if issecretvalue(spellID) then return nil end
    if type(spellID) ~= "number" or spellID <= 0 then return nil end

    return spellID
end

local function ClearCooldown(cooldown)
    if cooldown and cooldown.Clear then cooldown:Clear() end
end

local function SetCooldownFromDurationObject(cooldown, durationObject)
    if not (cooldown and cooldown.SetCooldownFromDurationObject and durationObject) then return false end
    local ok = pcall(cooldown.SetCooldownFromDurationObject, cooldown, durationObject, false)
    if ok then return true end
    ok = pcall(cooldown.SetCooldownFromDurationObject, cooldown, durationObject)
    return ok
end

local function SetIconDesaturation(icon, value)
    if not icon then return end

    if icon.SetDesaturation then icon:SetDesaturation(value) return end
    if icon.SetDesaturated then icon:SetDesaturated(value > 0) end
end

local function CalculateFallbackDesaturation(cooldownInfo)
    if not cooldownInfo then return 0 end

    local startTime = cooldownInfo.startTime or 0
    local duration = cooldownInfo.duration or 0
    local remaining = (startTime + duration) - GetTime()
    local threshold = cooldownInfo.isOnGCD and 1.6 or 0.001
    if remaining > threshold then return 1 end

    return 0
end

local function UpdateIconDesaturation(frame, cooldownInfo, durationObject, hasChargeSource)
    local icon = frame and frame.Icon
    if not icon then return end

    if cooldownInfo and cooldownInfo.isOnGCD then SetIconDesaturation(icon, 0) return end

    if durationObject and not hasChargeSource then
        if durationObject.EvaluateRemainingDuration then
            if desaturationCurve then
                SetIconDesaturation(icon, durationObject:EvaluateRemainingDuration(desaturationCurve, 0) or 0)
            else
                SetIconDesaturation(icon, CalculateFallbackDesaturation(cooldownInfo))
            end
            return
        end

        SetIconDesaturation(icon, CalculateFallbackDesaturation(cooldownInfo))
        return
    end

    SetIconDesaturation(icon, 0)
end

local function ApplyCooldownStyle(cooldown)
    if not cooldown then return end
    cooldown:SetDrawSwipe(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(true)
    cooldown:SetReverse(false)
    cooldown:SetSwipeColor(SWIPE_RGBA[1], SWIPE_RGBA[2], SWIPE_RGBA[3], SWIPE_RGBA[4])
    if cooldown.SetSwipeTexture then cooldown:SetSwipeTexture(SWIPE_TEXTURE) end
    if cooldown.SetUseAuraDisplayTime then cooldown:SetUseAuraDisplayTime(false) end
    if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(false) end
end

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return nil end

    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then return region end
    end

    return nil
end

local function ApplyCooldownTextStyle(parentFrame, cooldown)
    if not (parentFrame and cooldown) then return end
    if not BCDM.db.profile.CooldownManager then return end

    local profileDB = BCDM.db.profile
    local generalDB = profileDB.General
    local cooldownTextDB = profileDB.CooldownManager.General and profileDB.CooldownManager.General.CooldownText
    local textRegion = FetchCooldownTextRegion(cooldown)

    if not (generalDB and cooldownTextDB and textRegion) then return end

    local fontSize = cooldownTextDB.FontSize or 15
    if cooldownTextDB.ScaleByIconSize then local iconWidth = parentFrame:GetWidth() or 36 fontSize = fontSize * (iconWidth / 36) end

    local textColor = cooldownTextDB.Colour or { 1, 1, 1 }
    local textLayout = cooldownTextDB.Layout or { "CENTER", "CENTER", 0, 0 }

    textRegion:SetFont((BCDM.Media and BCDM.Media.Font) or STANDARD_TEXT_FONT, fontSize, generalDB.Fonts and generalDB.Fonts.FontFlag or "OUTLINE")
    textRegion:SetTextColor(textColor[1] or 1, textColor[2] or 1, textColor[3] or 1, 1)
    textRegion:ClearAllPoints()
    textRegion:SetPoint(textLayout[1] or "CENTER", parentFrame, textLayout[2] or "CENTER", textLayout[3] or 0, textLayout[4] or 0)

    local shadowDB = generalDB.Fonts and generalDB.Fonts.Shadow
    if shadowDB and shadowDB.Enabled then
        local shadowColor = shadowDB.Colour or { 0, 0, 0, 1 }
        textRegion:SetShadowColor( shadowColor[1] or 0, shadowColor[2] or 0, shadowColor[3] or 0, shadowColor[4] or 1 )
        textRegion:SetShadowOffset(shadowDB.OffsetX or 1, shadowDB.OffsetY or -1)
    else
        textRegion:SetShadowColor(0, 0, 0, 0)
        textRegion:SetShadowOffset(0, 0)
    end
end

local function ApplyAuraState(frame, spellID)
    local cooldown = frame and frame.Cooldown
    if not cooldown then return end

    local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    local durationObject = C_Spell.GetSpellCooldownDuration(spellID)

    local hasChargeSource = false
    if frame and type(frame.HasVisualDataSource_Charges) == "function" then hasChargeSource = not not frame:HasVisualDataSource_Charges() end

    local chargeDurationObject = hasChargeSource and C_Spell.GetSpellChargeDuration(spellID)

    UpdateIconDesaturation(frame, cooldownInfo, durationObject, hasChargeSource)

    local appliedDurationObject = false
    if hasChargeSource and chargeDurationObject then
        appliedDurationObject = SetCooldownFromDurationObject(cooldown, chargeDurationObject)
    elseif not hasChargeSource and durationObject then
        appliedDurationObject = SetCooldownFromDurationObject(cooldown, durationObject)
    end

    if appliedDurationObject then return end
    if cooldownInfo and cooldownInfo.isOnGCD then
        ClearCooldown(cooldown)
    elseif cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration then
        cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
    else
        ClearCooldown(cooldown)
    end
end

local function ProcessCooldownFrame(frame)
    if not BCDM.db.profile.CooldownManager.General.DisableAuraOverlay then return end
    if not (frame and frame.Cooldown) then return end
    if frame.Cooldown.BCDMBypassHook then return end

    local cooldown = frame.Cooldown
    local spellID = GetSpellID(frame)

    cooldown.BCDMBypassHook = true

    local ok, err = pcall(function()
        HideAuraOverlay(frame:GetRegions())
        ApplyCooldownStyle(cooldown)

        if spellID then
            ApplyAuraState(frame, spellID)
        else
            ClearCooldown(cooldown)
            SetIconDesaturation(frame.Icon, 0)
        end

        ApplyCooldownTextStyle(frame, cooldown)
    end)

    cooldown.BCDMBypassHook = false
end

local function OnCooldownChanged(cooldown)
    if not BCDM.db.profile.CooldownManager.General.DisableAuraOverlay then return end
    if not cooldown or cooldown.BCDMBypassHook then return end

    local parent = cooldown.BCDMParentFrame
    if not parent then return end

    ProcessCooldownFrame(parent)
end

local function HookCooldownFrame(cooldown, parent)
    if not cooldown or hooked[cooldown] then return end
    if not parent or not parent.cooldownInfo then return end

    hooked[cooldown] = true
    cooldown.BCDMParentFrame = parent
    cooldown.BCDMBypassHook = false

    hooksecurefunc(cooldown, "SetCooldown", OnCooldownChanged)

    if cooldown.SetCooldownFromDurationObject then
        hooksecurefunc(cooldown, "SetCooldownFromDurationObject", OnCooldownChanged)
    end

    hooksecurefunc(cooldown, "SetSwipeColor", OnCooldownChanged)

    local icon = parent.Icon
    if icon and not parent.BCDMDesaturationHooked then
        parent.BCDMDesaturationHooked = true
        hooksecurefunc(icon, "SetDesaturated", function() ProcessCooldownFrame(parent) end)
        if icon.SetDesaturation then
            hooksecurefunc(icon, "SetDesaturation", function() ProcessCooldownFrame(parent) end)
        end
    end
end

local function ScanCooldownFrames()
    for _, viewerName in ipairs(VIEWERS) do
        local viewer = _G[viewerName]
        if viewer then
            for _, child in ipairs({ viewer:GetChildren() }) do
                if child and child.Cooldown and child.cooldownInfo then
                    HookCooldownFrame(child.Cooldown, child)
                    ProcessCooldownFrame(child)
                end
            end
        end
    end
end

local function EnsureEventFrame()
    eventFrame:SetScript("OnEvent", function(_, event, addon) if event == "ADDON_LOADED" then if addon == "Blizzard_CooldownViewer" then C_Timer.After(0.5, ScanCooldownFrames) end return end C_Timer.After(0.1, ScanCooldownFrames) end)
end

local function EnableAuraOverlayRemoval()
    EnsureCurves()
    local eventFrame = CreateFrame("Frame")
    eventFrame:UnregisterAllEvents()
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    C_Timer.After(0.5, ScanCooldownFrames)
end

function BCDM:DisableAuraOverlay()
    if not BCDM.db or not BCDM.db.profile or not BCDM.db.profile.CooldownManager then return end
    if BCDM.db.profile.CooldownManager.General.DisableAuraOverlay then EnableAuraOverlayRemoval() end
end
