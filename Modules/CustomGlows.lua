local _, BCDM = ...
local LibCustomGlow = LibStub("LibCustomGlow-1.0")

local activeGlows = {}

local function NormalizeValue(value, defaultValue)
    if value == nil then
        return defaultValue
    end
    return value
end

local function NormalizeColor(color, fallback)
    if type(color) ~= "table" then
        color = fallback or { 1, 1, 1, 1 }
    end
    local fallbackColor = fallback or { 1, 1, 1, 1 }
    return {
        NormalizeValue(color[1], fallbackColor[1]),
        NormalizeValue(color[2], fallbackColor[2]),
        NormalizeValue(color[3], fallbackColor[3]),
        NormalizeValue(color[4], fallbackColor[4]),
    }
end

local function NormalizeGlowType(glowType)
    if not glowType then
        return nil
    end
    local normalized = tostring(glowType):lower()
    if normalized == "none" or normalized == "disabled" or normalized == "off" then
        return "None"
    end
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

function BCDM:NormalizeGlowSettings()
    if not BCDM.db or not BCDM.db.profile or not BCDM.db.profile.CooldownManager then
        return nil
    end

    local general = BCDM.db.profile.CooldownManager.General
    general.Glow = general.Glow or {}

    local glow = general.Glow

    local legacyType = glow.GlowType
    if glow.Type == nil and legacyType ~= nil then
        glow.Type = NormalizeGlowType(legacyType)
    end

    glow.Enabled = NormalizeValue(glow.Enabled, true)
    glow.Type = glow.Type or "None"
    -- Migrate old SwipeColor to new format
    if glow.SwipeColor and not glow.BuffSwipeColor then
        glow.BuffSwipeColor = glow.SwipeColor
        glow.CooldownSwipeColor = glow.SwipeColor
    end
    glow.BuffSwipeColor = NormalizeColor(glow.BuffSwipeColor, { 0, 0, 0, 0.8 })
    glow.CooldownSwipeColor = NormalizeColor(glow.CooldownSwipeColor, { 0, 0, 0, 0.8 })

    local legacyColor = glow.Colour
    glow.Pixel = glow.Pixel or {}
    glow.Pixel.Color = NormalizeColor(glow.Pixel.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Pixel.Lines = NormalizeValue(glow.Pixel.Lines or glow.Lines, 5)
    glow.Pixel.Frequency = NormalizeValue(glow.Pixel.Frequency or glow.Frequency, 0.25)
    glow.Pixel.Length = NormalizeValue(glow.Pixel.Length, 2)
    glow.Pixel.Thickness = NormalizeValue(glow.Pixel.Thickness or glow.Thickness, 1)
    glow.Pixel.XOffset = NormalizeValue(glow.Pixel.XOffset or glow.XOffset, -1)
    glow.Pixel.YOffset = NormalizeValue(glow.Pixel.YOffset or glow.YOffset, -1)
    glow.Pixel.Border = NormalizeValue(glow.Pixel.Border, false)

    glow.Autocast = glow.Autocast or {}
    glow.Autocast.Color = NormalizeColor(glow.Autocast.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Autocast.Particles = NormalizeValue(glow.Autocast.Particles or glow.Particles, 10)
    glow.Autocast.Frequency = NormalizeValue(glow.Autocast.Frequency or glow.Frequency, 0.25)
    glow.Autocast.Scale = NormalizeValue(glow.Autocast.Scale or glow.Scale, 1)
    glow.Autocast.XOffset = NormalizeValue(glow.Autocast.XOffset or glow.XOffset, -1)
    glow.Autocast.YOffset = NormalizeValue(glow.Autocast.YOffset or glow.YOffset, -1)

    glow.Proc = glow.Proc or {}
    glow.Proc.Color = NormalizeColor(glow.Proc.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Proc.StartAnim = NormalizeValue(glow.Proc.StartAnim, true)
    glow.Proc.Duration = NormalizeValue(glow.Proc.Duration, 1)
    glow.Proc.XOffset = NormalizeValue(glow.Proc.XOffset, 0)
    glow.Proc.YOffset = NormalizeValue(glow.Proc.YOffset, 0)

    glow.Button = glow.Button or {}
    glow.Button.Color = NormalizeColor(glow.Button.Color or legacyColor, { 1, 1, 1, 1 })
    glow.Button.Frequency = NormalizeValue(glow.Button.Frequency, 0.125)

    return glow
end

function BCDM:GetCustomGlowSettings()
    return self:NormalizeGlowSettings()
end

local function IsCooldownViewerChild(frame)
    if not frame or not frame.GetParent then
        return false
    end

    local parent = frame:GetParent()
    if not parent then
        return false
    end

    for _, viewerName in ipairs(BCDM.CooldownManagerViewers or {}) do
        if parent == _G[viewerName] then
            return true
        end
    end

    return false
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

    -- If type is "None", don't apply any glow effect (Blizzard's is already hidden)
    if glowType == "None" then
        frame.BCDMGlowType = glowType
        activeGlows[frame] = true
        return
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

local function HideBlizzardSpellAlert(frame)
    if not frame then return end
    
    -- Hide the SpellActivationAlert overlay (yellow glow)
    if frame.SpellActivationAlert then
        frame.SpellActivationAlert:Hide()
        frame.SpellActivationAlert:SetAlpha(0)
    end
    
    -- Also try to hide any overlay glow frames
    if frame.overlay then
        frame.overlay:Hide()
        frame.overlay:SetAlpha(0)
    end
    
    -- Hide ActionButton overlay glow
    if frame.SpellHighlightTexture then
        frame.SpellHighlightTexture:Hide()
        frame.SpellHighlightTexture:SetAlpha(0)
    end
    
    -- Try to stop the overlay glow using Blizzard's function
    if ActionButton_HideOverlayGlow then
        pcall(ActionButton_HideOverlayGlow, frame)
    end
    
    -- Hide the ants animation if present
    if frame.SpellActivationAlert and frame.SpellActivationAlert.ants then
        frame.SpellActivationAlert.ants:Hide()
    end
    
    -- Hide innerGlow and outerGlow
    if frame.SpellActivationAlert then
        if frame.SpellActivationAlert.innerGlow then
            frame.SpellActivationAlert.innerGlow:Hide()
        end
        if frame.SpellActivationAlert.outerGlow then
            frame.SpellActivationAlert.outerGlow:Hide()
        end
        if frame.SpellActivationAlert.innerGlowOver then
            frame.SpellActivationAlert.innerGlowOver:Hide()
        end
        if frame.SpellActivationAlert.outerGlowOver then
            frame.SpellActivationAlert.outerGlowOver:Hide()
        end
    end
    
    -- Search for any child frame that might be the glow overlay
    for _, child in ipairs({frame:GetChildren()}) do
        local name = child:GetName()
        if name and (name:find("Overlay") or name:find("Glow") or name:find("Alert") or name:find("Highlight")) then
            child:Hide()
            child:SetAlpha(0)
        end
        -- Also check for unnamed frames with glow-like textures
        if child.GetObjectType and child:GetObjectType() == "Frame" then
            for _, region in ipairs({child:GetRegions()}) do
                if region.GetTexture then
                    local tex = region:GetTexture()
                    if tex and type(tex) == "string" and (tex:find("Glow") or tex:find("overlay") or tex:find("SpellActivation")) then
                        region:Hide()
                        region:SetAlpha(0)
                    end
                end
            end
        end
    end
    
    -- Hide any regions on the frame itself that look like glows
    for _, region in ipairs({frame:GetRegions()}) do
        if region.GetTexture then
            local tex = region:GetTexture()
            if tex and type(tex) == "string" and (tex:find("Glow") or tex:find("overlay") or tex:find("SpellActivation") or tex:find("IconAlert")) then
                region:Hide()
                region:SetAlpha(0)
            end
        end
    end
end

-- Continuously monitor and hide yellow glows on cooldown viewer icons
local function SetupContinuousGlowHiding()
    local hideFrame = CreateFrame("Frame")
    local elapsed = 0
    local interval = 0.016 -- ~60fps
    
    -- Function to apply custom swipe color (only when enabled)
    local function ApplySwipeColor(cooldown)
        if not cooldown or not cooldown.SetSwipeColor then return end
        
        local glow = BCDM:GetCustomGlowSettings()
        
        -- Only apply custom color if enabled
        if glow and glow.Enabled then
            -- Use BuffSwipeColor as the single color for all swipes
            local c = glow.BuffSwipeColor or {0, 0, 0, 0.8}
            
            -- Set flag to prevent recursive calls
            cooldown.BCDMSettingColor = true
            cooldown:SetSwipeColor(c[1], c[2], c[3], c[4])
            cooldown.BCDMSettingColor = nil
        end
        -- If disabled, don't do anything - let Blizzard handle it naturally
    end
    
    -- Hook the Cooldown SetCooldown function to change color immediately after Blizzard sets it
    local hookedCooldowns = {}
    local function HookCooldown(cooldown)
        if not cooldown or hookedCooldowns[cooldown] then return end
        hookedCooldowns[cooldown] = true
        
        if cooldown.SetCooldown then
            hooksecurefunc(cooldown, "SetCooldown", function(self)
                ApplySwipeColor(self)
            end)
        end
        
        if cooldown.SetCooldownDuration then
            hooksecurefunc(cooldown, "SetCooldownDuration", function(self)
                ApplySwipeColor(self)
            end)
        end
        
        -- Hook SetSwipeColor to override Blizzard's color changes
        hooksecurefunc(cooldown, "SetSwipeColor", function(self)
            -- Skip if we're the ones setting the color
            if self.BCDMSettingColor then return end
            
            -- Apply our color immediately after Blizzard sets theirs
            ApplySwipeColor(self)
        end)
    end
    
    hideFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed < interval then return end
        elapsed = 0
        
        local glow = BCDM:GetCustomGlowSettings()
        
        -- Only process if enabled
        if not glow or not glow.Enabled then return end
        
        for _, viewerName in ipairs(BCDM.CooldownManagerViewers or {}) do
            local viewer = _G[viewerName]
            if viewer then
                for _, child in ipairs({viewer:GetChildren()}) do
                    if child and child.Cooldown then
                        -- Hook the cooldown if not already hooked
                        HookCooldown(child.Cooldown)
                        
                        if child:IsShown() then
                            ApplySwipeColor(child.Cooldown)
                            HideBlizzardSpellAlert(child)
                        end
                    end
                end
            end
        end
    end)
end

function BCDM:SetupCustomGlows()
    if self.CustomGlowHooksSet then
        return
    end

    self.CustomGlowHooksSet = true

    -- Setup continuous monitoring to hide Blizzard's yellow glow
    SetupContinuousGlowHiding()

    if not ActionButtonSpellAlertManager then
        return
    end

    hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, frame)
        if not frame or not IsCooldownViewerChild(frame) then
            return
        end

        -- Always hide Blizzard's yellow glow
        HideBlizzardSpellAlert(frame)

        local glow = BCDM:GetCustomGlowSettings()
        if not glow or not glow.Enabled then
            return
        end

        frame.BCDMActiveGlow = true

        C_Timer.After(0, function()
            if frame.BCDMActiveGlow then
                HideBlizzardSpellAlert(frame)
                BCDM:StartCustomGlow(frame)
            end
        end)
    end)

    hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", function(_, frame)
        if not frame or not frame.BCDMActiveGlow then
            return
        end

        frame.BCDMActiveGlow = nil
        BCDM:StopCustomGlow(frame)
    end)
end
