local _, BCDM = ...
local LibCustomGlow = LibStub("LibCustomGlow-1.0")

local activeGlows = {}

local function ValueOrDefault(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    return value
end

local function CopyColorOrDefault(color, fallback)
    if type(color) ~= "table" then
        color = fallback or { 1, 1, 1, 1 }
    end
    local fallbackColor = fallback or { 1, 1, 1, 1 }
    return {
        ValueOrDefault(color[1], fallbackColor[1]),
        ValueOrDefault(color[2], fallbackColor[2]),
        ValueOrDefault(color[3], fallbackColor[3]),
        ValueOrDefault(color[4], fallbackColor[4]),
    }
end

local function ResolveGlowType(glowType)
    if not glowType then
        return nil
    end
    local normalized = tostring(glowType):lower()
    if normalized == "pixel" or normalized == "pixelglow" or normalized == "pix" or normalized == "pixel_glow" then
        return "Pixel"
    end
    if normalized == "autocast" or normalized == "autocastglow" or normalized == "autocast_glow" then
        return "Autocast"
    end
    if normalized == "proc" or normalized == "procglow" or normalized == "proc_glow" then
        return "Proc"
    end
    if normalized == "button" or normalized == "buttonglow" or normalized == "actionbuttonglow" or normalized == "action_button_glow" then
        return "Button"
    end
    return nil
end

-- Fold current settings and older saved-variable shapes into one structure so
-- the glow application code can read a single predictable table.
function BCDM:GetGlowSettingsWithDefaults()
    if not BCDM.db or not BCDM.db.profile or not BCDM.db.profile.CooldownManager then
        return nil
    end

    local general = BCDM.db.profile.CooldownManager.General
    general.Glow = general.Glow or {}

    local glow = general.Glow

    local legacyType = glow.GlowType
    if glow.Type == nil and legacyType ~= nil then
        glow.Type = ResolveGlowType(legacyType)
    end

    glow.Enabled = ValueOrDefault(glow.Enabled, true)
    glow.Type = glow.Type or "Pixel"

    local legacyColor = glow.Colour
    glow.Pixel = glow.Pixel or {}
    glow.Pixel.Color = CopyColorOrDefault(glow.Pixel.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Pixel.Lines = ValueOrDefault(glow.Pixel.Lines or glow.Lines, 5)
    glow.Pixel.Frequency = ValueOrDefault(glow.Pixel.Frequency or glow.Frequency, 0.25)
    glow.Pixel.Length = ValueOrDefault(glow.Pixel.Length, 2)
    glow.Pixel.Thickness = ValueOrDefault(glow.Pixel.Thickness or glow.Thickness, 1)
    glow.Pixel.XOffset = ValueOrDefault(glow.Pixel.XOffset or glow.XOffset, -1)
    glow.Pixel.YOffset = ValueOrDefault(glow.Pixel.YOffset or glow.YOffset, -1)
    glow.Pixel.Border = ValueOrDefault(glow.Pixel.Border, false)

    glow.Autocast = glow.Autocast or {}
    glow.Autocast.Color = CopyColorOrDefault(glow.Autocast.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Autocast.Particles = ValueOrDefault(glow.Autocast.Particles or glow.Particles, 10)
    glow.Autocast.Frequency = ValueOrDefault(glow.Autocast.Frequency or glow.Frequency, 0.25)
    glow.Autocast.Scale = ValueOrDefault(glow.Autocast.Scale or glow.Scale, 1)
    glow.Autocast.XOffset = ValueOrDefault(glow.Autocast.XOffset or glow.XOffset, -1)
    glow.Autocast.YOffset = ValueOrDefault(glow.Autocast.YOffset or glow.YOffset, -1)

    glow.Proc = glow.Proc or {}
    glow.Proc.Color = CopyColorOrDefault(glow.Proc.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Proc.StartAnim = ValueOrDefault(glow.Proc.StartAnim, true)
    glow.Proc.Duration = ValueOrDefault(glow.Proc.Duration, 1)
    glow.Proc.XOffset = ValueOrDefault(glow.Proc.XOffset, 0)
    glow.Proc.YOffset = ValueOrDefault(glow.Proc.YOffset, 0)

    glow.Button = glow.Button or {}
    glow.Button.Color = CopyColorOrDefault(glow.Button.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Button.Frequency = ValueOrDefault(glow.Button.Frequency, 0.125)

    return glow
end

function BCDM:NormalizeGlowSettings()
    return self:GetGlowSettingsWithDefaults()
end

function BCDM:GetCustomGlowSettings()
    return self:GetGlowSettingsWithDefaults()
end

local function GetCooldownViewerChild(frame)
    if not frame or not frame.GetParent then return nil end

    local current = frame
    while current and current.GetParent do
        local parent = current:GetParent()
        if not parent then return nil end

        for _, viewerName in ipairs(BCDM.CooldownManagerViewers or {}) do
            if parent == _G[viewerName] then return current end
        end

        current = parent
    end

    return nil
end

local function GetGlowTarget(frame)
    if not frame then return nil end

    return GetCooldownViewerChild(frame)
end

function BCDM:StartCustomGlow(frame)
    if not frame then
        return
    end

    local glow = self:GetCustomGlowSettings()
    if not glow or not glow.Enabled then
        return
    end

    local glowType = glow.Type or "Pixel"
    if frame.BCDMGlowType and frame.BCDMGlowType ~= glowType then
        self:StopCustomGlow(frame)
    end

    if glowType == "Pixel" then
        local settings = glow.Pixel
        LibCustomGlow.PixelGlow_Start(frame, settings.Color, settings.Lines, settings.Frequency, settings.Length, settings.Thickness, settings.XOffset, settings.YOffset, settings.Border, "BCDM", 1)
    elseif glowType == "Autocast" then
        local settings = glow.Autocast
        LibCustomGlow.AutoCastGlow_Start(frame, settings.Color, settings.Particles, settings.Frequency, settings.Scale, settings.XOffset, settings.YOffset, "BCDM", 1)
    elseif glowType == "Proc" then
        local settings = glow.Proc
        LibCustomGlow.ProcGlow_Start(frame, {
            key = "BCDM",
            frameLevel = 1,
            color = settings.Color,
            startAnim = settings.StartAnim,
            duration = settings.Duration,
            xOffset = settings.XOffset,
            yOffset = settings.YOffset,
        })
    elseif glowType == "Button" then
        local settings = glow.Button
        LibCustomGlow.ButtonGlow_Start(frame, settings.Color, settings.Frequency, 1)
    end

    frame.BCDMGlowType = glowType
    activeGlows[frame] = true
end

function BCDM:StopCustomGlow(frame)
    if not frame or not frame.BCDMGlowType then
        return
    end

    if frame.BCDMGlowType == "Pixel" then
        LibCustomGlow.PixelGlow_Stop(frame, "BCDM")
    elseif frame.BCDMGlowType == "Autocast" then
        LibCustomGlow.AutoCastGlow_Stop(frame, "BCDM")
    elseif frame.BCDMGlowType == "Proc" then
        LibCustomGlow.ProcGlow_Stop(frame, "BCDM")
    elseif frame.BCDMGlowType == "Button" then
        LibCustomGlow.ButtonGlow_Stop(frame)
    end

    frame.BCDMGlowType = nil
    activeGlows[frame] = nil
end

function BCDM:StopAllCustomGlows()
    for frame in pairs(activeGlows) do
        self:StopCustomGlow(frame)
    end
end

function BCDM:RefreshCustomGlows()
    local glow = self:GetCustomGlowSettings()
    if not glow or not glow.Enabled then
        self:StopAllCustomGlows()
        return
    end

    for frame in pairs(activeGlows) do
        self:StartCustomGlow(frame)
    end
end

function BCDM:SetupCustomGlows()
    if self.CustomGlowHooksSet then
        return
    end

    self.CustomGlowHooksSet = true

    if not ActionButtonSpellAlertManager then
        return
    end

    hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, frame)
        local activeGlowTarget = GetGlowTarget(frame)
        if not activeGlowTarget then
            return
        end

        local glow = BCDM:GetCustomGlowSettings()
        if not glow or not glow.Enabled then
            return
        end

        if activeGlowTarget.BCDMActiveGlow then
            return
        end

        activeGlowTarget.BCDMActiveGlow = true
        if activeGlowTarget.SpellActivationAlert then
            activeGlowTarget.SpellActivationAlert:Hide()
        end

        C_Timer.After(0, function()
            if activeGlowTarget.BCDMActiveGlow then
                BCDM:StartCustomGlow(activeGlowTarget)
            end
        end)
    end)

    hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", function(_, frame)
        local activeGlowTarget = GetGlowTarget(frame)
        if not activeGlowTarget or not activeGlowTarget.BCDMActiveGlow then
            return
        end

        activeGlowTarget.BCDMActiveGlow = nil
        BCDM:StopCustomGlow(activeGlowTarget)
    end)
end
