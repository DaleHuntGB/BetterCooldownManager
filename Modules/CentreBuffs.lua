local _, BCDM = ...

local floor = math.floor

local function roundPixel(value)
    if not value then return 0 end
    return floor(value + 0.5)
end

local function GetBuffIconFrames()
    if not BuffIconCooldownViewer then
        return {}
    end

    local all = {}

    for _, child in ipairs({ BuffIconCooldownViewer:GetChildren() }) do
        if child then
            local hasIcon    = child.icon or child.Icon
            local hasCooldown = child.cooldown or child.Cooldown

            if hasIcon or hasCooldown then
                table.insert(all, child)
            end
        end
    end

    table.sort(all, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    -- Only keep visible icons
    local visible = {}
    for _, icon in ipairs(all) do
        if icon:IsShown() then
            table.insert(visible, icon)
        end
    end

    return visible
end

local function GetBuffBarFrames()
    if not BuffBarCooldownViewer then
        return {}
    end

    local frames = {}

    -- First, try CooldownViewer API if present
    if BuffBarCooldownViewer.GetItemFrames then
        local ok, items = pcall(BuffBarCooldownViewer.GetItemFrames, BuffBarCooldownViewer)
        if ok and items then
            frames = items
        end
    end

    -- Fallback to raw children scan
    if #frames == 0 then
        local okc, children = pcall(BuffBarCooldownViewer.GetChildren, BuffBarCooldownViewer)
        if okc and children then
            for _, child in ipairs({ children }) do
                if child and child:IsObjectType("Frame") then
                    table.insert(frames, child)
                end
            end
        end
    end

    -- Filter to active/visible frames
    local active = {}
    for _, frame in ipairs(frames) do
        if frame:IsShown() and frame:IsVisible() then
            table.insert(active, frame)
        end
    end

    table.sort(active, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    return active
end

-- Create a unique identifier for an icon/bar based on its properties
local function GetIdentifier(frame)
    local id = nil

    -- Method 1: Check for spellID
    if frame.spellID then
        id = "spell_" .. tostring(frame.spellID)
    end

    -- Method 2: Check for auraInstanceID
    if not id and frame.auraInstanceID then
        id = "aura_" .. tostring(frame.auraInstanceID)
    end

    -- Method 3: Check texture
    if not id then
        local texture = frame.icon or frame.Icon
        if texture and texture.GetTexture then
            local tex = texture:GetTexture()
            if tex then
                id = "tex_" .. tostring(tex)
            end
        end
    end

    -- Method 4: Fall back to the frame itself
    if not id then
        id = "frame_" .. tostring(frame)
    end

    return id
end

--------------------------------------------------------------------------------
-- ICON CENTER MANAGER
--------------------------------------------------------------------------------

local iconState = {
    isInitialized    = false,
    lastCount        = 0,
    lastIconIds      = {},
    fixedIconWidth   = nil,
    fixedIconHeight  = nil,
    fixedSpacing     = nil,
    fastModeFrames   = 0,
}

local ICON_FAST_MODE_DURATION = 10

local function RepositionIcons(icons, iconWidth, iconHeight, spacing)
    local currentCount = #icons

    -- Calculate total width and starting position
    local totalWidth = (currentCount * iconWidth) + ((currentCount - 1) * spacing)
    totalWidth = roundPixel(totalWidth)

    local startX = -totalWidth / 2 + iconWidth / 2
    startX = roundPixel(startX)

    -- Position icons
    for _, icon in ipairs(icons) do
        icon:ClearAllPoints()
    end

    for i, icon in ipairs(icons) do
        local x = startX + (i - 1) * (iconWidth + spacing)
        x = roundPixel(x)
        icon:SetPoint("CENTER", BuffIconCooldownViewer, "CENTER", x, 0)
    end
end

local function UpdateIconsIfNeeded()
    if not BuffIconCooldownViewer then return end

    local icons = GetBuffIconFrames()
    local currentCount = #icons
    local refIcon = icons[1]

    local parentFrame = BuffIconCooldownViewer:GetParent()
    if not parentFrame then return end

    -- 1. Handle empty state
    if currentCount == 0 then
        iconState.lastCount = 0
        iconState.lastIconIds = {}
        iconState.isInitialized = false
        iconState.fastModeFrames = 0
        return
    end
    if not refIcon then return end

    -- Get current dimensions
    local currentIconWidth    = refIcon:GetWidth()
    local currentIconHeight   = refIcon:GetHeight()
    local currentSpacing      = BuffIconCooldownViewer.childXPadding

    if not currentIconWidth or currentIconWidth == 0 then return end

    -- 2. RIGID GEOMETRY LOCKING
    local geometryChanged = false

    if not iconState.isInitialized then
        iconState.fixedIconWidth = currentIconWidth
        iconState.fixedIconHeight = currentIconHeight
        iconState.fixedSpacing = currentSpacing
        iconState.isInitialized = true
        geometryChanged = true
    else
        -- Check for significant change (user changing settings)
        if math.abs(currentIconWidth - iconState.fixedIconWidth) > 1 or
           math.abs(currentIconHeight - iconState.fixedIconHeight) > 1 or
           math.abs(currentSpacing - iconState.fixedSpacing) > 1 then

            iconState.fixedIconWidth = currentIconWidth
            iconState.fixedIconHeight = currentIconHeight
            iconState.fixedSpacing = currentSpacing
            geometryChanged = true
        end
    end

    -- Use stable dimensions for calculations
    local iconWidth = iconState.fixedIconWidth
    local iconHeight = iconState.fixedIconHeight
    local spacing = iconState.fixedSpacing

    -- 3. In fast mode, skip change detection and just reposition
    if iconState.fastModeFrames > 0 then
        iconState.fastModeFrames = iconState.fastModeFrames - 1
        RepositionIcons(icons, iconWidth, iconHeight, spacing)
        return
    end

    -- 4. Normal mode: Check if the actual buffs have changed (by identifier)
    local iconsChanged = false
    if currentCount ~= iconState.lastCount then
        iconsChanged = true
    else
        -- Same count - create identifier sets and compare
        local currentIds = {}
        for _, icon in ipairs(icons) do
            local id = GetIdentifier(icon)
            currentIds[id] = true
        end

        -- Check if all IDs from last set are still present
        for id, _ in pairs(iconState.lastIconIds) do
            if not currentIds[id] then
                iconsChanged = true
                break
            end
        end

        -- Check if any new IDs appeared
        if not iconsChanged then
            for id, _ in pairs(currentIds) do
                if not iconState.lastIconIds[id] then
                    iconsChanged = true
                    break
                end
            end
        end
    end

    -- 5. Check if layout needs updating
    local layoutChanged = iconsChanged or geometryChanged

    if not layoutChanged then
        return
    end

    -- Enter fast mode
    iconState.fastModeFrames = ICON_FAST_MODE_DURATION
    iconState.lastCount = currentCount

    -- Store the current icon IDs for next comparison
    iconState.lastIconIds = {}
    for _, icon in ipairs(icons) do
        local id = GetIdentifier(icon)
        iconState.lastIconIds[id] = true
    end

    -- Reposition
    RepositionIcons(icons, iconWidth, iconHeight, spacing)
end

--------------------------------------------------------------------------------
-- BAR CENTER MANAGER
--------------------------------------------------------------------------------

local barState = {
    isInitialized    = false,
    lastCount        = 0,
    lastBarIds       = {},
    fixedBarWidth    = nil,
    fixedBarHeight   = nil,
    fixedSpacing     = nil,
    fastModeFrames   = 0,
}

local BAR_FAST_MODE_DURATION = 10

local function RepositionBars(bars, barWidth, barHeight, spacing)
    local count = #bars

    -- Clear all points first
    for _, bar in ipairs(bars) do
        bar:ClearAllPoints()
    end

    -- Position bars growing upwards from bottom
    for index, bar in ipairs(bars) do
        local offsetIndex = index - 1
        local y = offsetIndex * (barHeight + spacing)
        y = roundPixel(y)
        bar:SetPoint("BOTTOM", BuffBarCooldownViewer, "BOTTOM", 0, y)
    end
end

local function UpdateBarsIfNeeded()
    if not BuffBarCooldownViewer then return end

    local bars = GetBuffBarFrames()
    local currentCount = #bars
    local refBar = bars[1]

    -- 1. Handle empty state
    if currentCount == 0 then
        barState.lastCount = 0
        barState.lastBarIds = {}
        barState.isInitialized = false
        barState.fastModeFrames = 0
        return
    end
    if not refBar then return end

    -- Get current dimensions
    local currentBarWidth  = refBar:GetWidth()
    local currentBarHeight = refBar:GetHeight()
    local currentSpacing   = BuffBarCooldownViewer.childYPadding

    if not currentBarHeight or currentBarHeight == 0 then return end

    -- 2. RIGID GEOMETRY LOCKING
    local geometryChanged = false

    if not barState.isInitialized then
        barState.fixedBarWidth = currentBarWidth
        barState.fixedBarHeight = currentBarHeight
        barState.fixedSpacing = currentSpacing
        barState.isInitialized = true
        geometryChanged = true
    else
        -- Check for significant change (user changing settings)
        if math.abs(currentBarWidth - barState.fixedBarWidth) > 1 or
           math.abs(currentBarHeight - barState.fixedBarHeight) > 1 or
           math.abs(currentSpacing - barState.fixedSpacing) > 1 then

            barState.fixedBarWidth = currentBarWidth
            barState.fixedBarHeight = currentBarHeight
            barState.fixedSpacing = currentSpacing
            geometryChanged = true
        end
    end

    -- Use stable dimensions for calculations
    local barWidth = barState.fixedBarWidth
    local barHeight = barState.fixedBarHeight
    local spacing = barState.fixedSpacing

    -- 3. In fast mode, skip change detection and just reposition
    if barState.fastModeFrames > 0 then
        barState.fastModeFrames = barState.fastModeFrames - 1
        RepositionBars(bars, barWidth, barHeight, spacing)
        return
    end

    -- 4. Normal mode: Check if the actual bars have changed (by identifier)
    local barsChanged = false
    if currentCount ~= barState.lastCount then
        barsChanged = true
    else
        -- Same count - create identifier sets and compare
        local currentIds = {}
        for _, bar in ipairs(bars) do
            local id = GetIdentifier(bar)
            currentIds[id] = true
        end

        -- Check if all IDs from last set are still present
        for id, _ in pairs(barState.lastBarIds) do
            if not currentIds[id] then
                barsChanged = true
                break
            end
        end

        -- Check if any new IDs appeared
        if not barsChanged then
            for id, _ in pairs(currentIds) do
                if not barState.lastBarIds[id] then
                    barsChanged = true
                    break
                end
            end
        end
    end

    -- 5. Check if layout needs updating
    local layoutChanged = barsChanged or geometryChanged

    if not layoutChanged then
        return
    end

    -- Enter fast mode
    barState.fastModeFrames = BAR_FAST_MODE_DURATION
    barState.lastCount = currentCount

    -- Store the current bar IDs for next comparison
    barState.lastBarIds = {}
    for _, bar in ipairs(bars) do
        local id = GetIdentifier(bar)
        barState.lastBarIds[id] = true
    end

    -- Reposition
    RepositionBars(bars, barWidth, barHeight, spacing)
end

--------------------------------------------------------------------------------
-- HOOK INTO COOLDOWN MANAGER (ONCE)
--------------------------------------------------------------------------------

local hasHookedIcons = false
local hasHookedBars = false

local function HookCooldownManager()
    -- Hook icons
    if not hasHookedIcons and BuffIconCooldownViewer then
        local originalGetChildren = BuffIconCooldownViewer.GetChildren
        if originalGetChildren then
            BuffIconCooldownViewer.GetChildren = function(self)
                iconState.fastModeFrames = ICON_FAST_MODE_DURATION
                return originalGetChildren(self)
            end
            hasHookedIcons = true
        end
    end

    -- Hook bars
    if not hasHookedBars and BuffBarCooldownViewer then
        local originalGetChildren = BuffBarCooldownViewer.GetChildren
        if originalGetChildren then
            BuffBarCooldownViewer.GetChildren = function(self)
                barState.fastModeFrames = BAR_FAST_MODE_DURATION
                return originalGetChildren(self)
            end
            hasHookedBars = true
        end
    end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local updateFrame = CreateFrame("Frame")

function BCDM:SetupCentreBuffs()
    local CooldownManagerDB = BCDM.db.profile
    local BuffsDB = CooldownManagerDB.Buffs
    HookCooldownManager()
    if BuffsDB.CentreHorizontally then
        updateFrame:SetScript("OnUpdate", function(self, elapsed) UpdateIconsIfNeeded() UpdateBarsIfNeeded() end)
        updateFrame:Show()
    else
        updateFrame:SetScript("OnUpdate", nil)
        updateFrame:Hide()
    end
end

function BCDM:UpdateCentreBuffs()
    local CooldownManagerDB = BCDM.db.profile
    local BuffsDB = CooldownManagerDB.Buffs
    if BuffsDB.CentreHorizontally then
        updateFrame:Show()
        updateFrame:SetScript("OnUpdate", function(self, elapsed) UpdateIconsIfNeeded() UpdateBarsIfNeeded() end)
    else
        updateFrame:SetScript("OnUpdate", nil)
        updateFrame:Hide()
    end
end