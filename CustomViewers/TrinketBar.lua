local _, BCDM = ...

local function FetchCooldownTextRegion(cooldown)
    if not cooldown then return end
    for _, region in ipairs({ cooldown:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function ApplyCooldownText()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CooldownTextDB = CooldownManagerDB.CooldownManager.General.CooldownText
    local Viewer = _G["BCDM_TrinketBar"]
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

local function IsCooldownFrameActive(customIcon)
    -- Thanks Mapko for this idea!
    if not customIcon or not customIcon.Cooldown then return end

    if customIcon.Cooldown:IsShown() then
        customIcon.Icon:SetDesaturated(true)
    else
        customIcon.Icon:SetDesaturated(false)
    end
end

local function FetchItemData(itemId)
    local startTime, durationTime = C_Item.GetItemCooldown(itemId)
    return startTime, durationTime
end

local function IsOnUseTrinket(itemId)
    if not itemId then return false end
    local spellName, spellID = C_Item.GetItemSpell(itemId)
    return (spellID and spellID > 0) or (spellName and spellName ~= "")
end

local function FetchEquippedOnUseTrinkets()
    local equipped = {}
    local trinketSlots = { 13, 14 }

    for _, slotID in ipairs(trinketSlots) do
        local itemId = GetInventoryItemID("player", slotID)
        if itemId and IsOnUseTrinket(itemId) then
            equipped[#equipped + 1] = { itemId = itemId, slotID = slotID }
        end
    end

    return equipped
end

local function CreateCustomIcon(itemId, slotID)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.CooldownManager.Trinket
    if not itemId then return end
    if not C_Item.GetItemInfo(itemId) then return end

    local uniqueFrameId = slotID or itemId
    local customIcon = CreateFrame("Button", "BCDM_Custom_Trinket_" .. uniqueFrameId, UIParent, "BackdropTemplate")
    customIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = BCDM.db.profile.CooldownManager.General.BorderSize, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customIcon:SetBackdropColor(0, 0, 0, 0)
    if BCDM.db.profile.CooldownManager.General.BorderSize <= 0 then
        customIcon:SetBackdropBorderColor(0, 0, 0, 0)
    else
        customIcon:SetBackdropBorderColor(0, 0, 0, 1)
    end
    local iconWidth, iconHeight = BCDM:GetIconDimensions(CustomDB)
    customIcon:SetSize(iconWidth, iconHeight)
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    customIcon:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
    customIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    customIcon:EnableMouse(false)
    customIcon:SetFrameStrata(CustomDB.FrameStrata or "LOW")

    local HighLevelContainer = CreateFrame("Frame", nil, customIcon)
    HighLevelContainer:SetAllPoints(customIcon)
    HighLevelContainer:SetFrameLevel(customIcon:GetFrameLevel() + 999)

    customIcon.Cooldown = CreateFrame("Cooldown", nil, customIcon, "CooldownFrameTemplate")
    customIcon.Cooldown:SetAllPoints(customIcon)
    customIcon.Cooldown:SetDrawEdge(false)
    customIcon.Cooldown:SetDrawSwipe(true)
    customIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customIcon.Cooldown:SetHideCountdownNumbers(false)
    customIcon.Cooldown:SetReverse(false)

    customIcon:HookScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" then
            local startTime, durationTime = FetchItemData(itemId)
            if startTime then
                customIcon.Cooldown:SetCooldown(startTime, durationTime)
            end
        end
    end)

    customIcon.Icon = customIcon:CreateTexture(nil, "BACKGROUND")
    local borderSize = BCDM.db.profile.CooldownManager.General.BorderSize
    customIcon.Icon:SetPoint("TOPLEFT", customIcon, "TOPLEFT", borderSize, -borderSize)
    customIcon.Icon:SetPoint("BOTTOMRIGHT", customIcon, "BOTTOMRIGHT", -borderSize, borderSize)
    local iconZoom = BCDM.db.profile.CooldownManager.General.IconZoom * 0.5
    BCDM:ApplyIconTexCoord(customIcon.Icon, iconWidth, iconHeight, iconZoom)
    customIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(itemId)))

    return customIcon
end

local function CreateCustomIcons(iconTable)
    wipe(iconTable)

    local trinkets = FetchEquippedOnUseTrinkets()
    for _, trinketEntry in ipairs(trinkets) do
        local customTrinket = CreateCustomIcon(trinketEntry.itemId, trinketEntry.slotID)
        if customTrinket then
            table.insert(iconTable, customTrinket)
        end
    end
end

local function LayoutTrinketBar()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Trinket
    local customTrinketIcons = {}

    local growthDirection = CustomDB.GrowthDirection or "RIGHT"

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

    if not BCDM.TrinketBarContainer then
        BCDM.TrinketBarContainer = CreateFrame("Frame", "BCDM_TrinketBar", UIParent, "BackdropTemplate")
        BCDM.TrinketBarContainer:SetSize(1, 1)
    end

    BCDM.TrinketBarContainer:ClearAllPoints()
    BCDM.TrinketBarContainer:SetFrameStrata(CustomDB.FrameStrata or "LOW")
    local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
    BCDM.TrinketBarContainer:SetPoint(containerAnchorFrom, anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])

    for _, child in ipairs({BCDM.TrinketBarContainer:GetChildren()}) do child:UnregisterAllEvents() child:Hide() child:SetParent(nil) end

    CreateCustomIcons(customTrinketIcons)

    local iconWidth, iconHeight = BCDM:GetIconDimensions(CustomDB)
    local iconSpacing = CustomDB.Spacing

    if #customTrinketIcons == 0 then
        BCDM.TrinketBarContainer:SetSize(1, 1)
    else
        local point = select(1, BCDM.TrinketBarContainer:GetPoint(1))
        local useCenteredLayout = (point == "TOP" or point == "BOTTOM") and (growthDirection == "LEFT" or growthDirection == "RIGHT")

        local totalWidth, totalHeight = 0, 0
        if useCenteredLayout or growthDirection == "RIGHT" or growthDirection == "LEFT" then
            totalWidth = (#customTrinketIcons * iconWidth) + ((#customTrinketIcons - 1) * iconSpacing)
            totalHeight = iconHeight
        elseif growthDirection == "UP" or growthDirection == "DOWN" then
            totalWidth = iconWidth
            totalHeight = (#customTrinketIcons * iconHeight) + ((#customTrinketIcons - 1) * iconSpacing)
        end
        BCDM.TrinketBarContainer:SetWidth(totalWidth)
        BCDM.TrinketBarContainer:SetHeight(totalHeight)
    end

    local LayoutConfig = {
        TOPLEFT     = { anchor="TOPLEFT",     xMult=1,  yMult=1  },
        TOP         = { anchor="TOP",         xMult=0,  yMult=1  },
        TOPRIGHT    = { anchor="TOPRIGHT",    xMult=-1, yMult=1  },
        BOTTOMLEFT  = { anchor="BOTTOMLEFT",  xMult=1,  yMult=-1 },
        BOTTOM      = { anchor="BOTTOM",      xMult=0,  yMult=-1 },
        BOTTOMRIGHT = { anchor="BOTTOMRIGHT", xMult=-1, yMult=-1 },
        LEFT        = { anchor="LEFT",        xMult=1,  yMult=0  },
        RIGHT       = { anchor="RIGHT",       xMult=-1, yMult=0  },
        CENTER      = { anchor="CENTER",      xMult=0,  yMult=0  },
    }

    local point = select(1, BCDM.TrinketBarContainer:GetPoint(1))
    local useCenteredLayout = (point == "TOP" or point == "BOTTOM") and (growthDirection == "LEFT" or growthDirection == "RIGHT")

    if useCenteredLayout and #customTrinketIcons > 0 then
        local totalWidth = (#customTrinketIcons * iconWidth) + ((#customTrinketIcons - 1) * iconSpacing)
        local startOffset = -(totalWidth / 2) + (iconWidth / 2)

        for i, spellIcon in ipairs(customTrinketIcons) do
            spellIcon:SetParent(BCDM.TrinketBarContainer)
            spellIcon:SetSize(iconWidth, iconHeight)
            spellIcon:ClearAllPoints()

            local xOffset = startOffset + ((i - 1) * (iconWidth + iconSpacing))
            spellIcon:SetPoint("CENTER", BCDM.TrinketBarContainer, "CENTER", xOffset, 0)
            ApplyCooldownText()
            spellIcon:Show()
        end
    else
        for i, spellIcon in ipairs(customTrinketIcons) do
            spellIcon:SetParent(BCDM.TrinketBarContainer)
            spellIcon:SetSize(iconWidth, iconHeight)
            spellIcon:ClearAllPoints()

            if i == 1 then
                local config = LayoutConfig[point] or LayoutConfig.TOPLEFT
                spellIcon:SetPoint(config.anchor, BCDM.TrinketBarContainer, config.anchor, 0, 0)
            else
                if growthDirection == "RIGHT" then
                    spellIcon:SetPoint("LEFT", customTrinketIcons[i - 1], "RIGHT", iconSpacing, 0)
                elseif growthDirection == "LEFT" then
                    spellIcon:SetPoint("RIGHT", customTrinketIcons[i - 1], "LEFT", -iconSpacing, 0)
                elseif growthDirection == "UP" then
                    spellIcon:SetPoint("BOTTOM", customTrinketIcons[i - 1], "TOP", 0, iconSpacing)
                elseif growthDirection == "DOWN" then
                    spellIcon:SetPoint("TOP", customTrinketIcons[i - 1], "BOTTOM", 0, -iconSpacing)
                end
            end
            ApplyCooldownText()
            spellIcon:Show()
        end
    end

    if CustomDB.Enabled and #customTrinketIcons > 0 then
        BCDM.TrinketBarContainer:Show()
    else
        BCDM.TrinketBarContainer:Hide()
    end
end

function BCDM:SetupTrinketBar()
    LayoutTrinketBar()
end

function BCDM:UpdateTrinketBar()
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager.Trinket
    local isEnabled = CustomDB.Enabled
    if BCDM.TrinketBarContainer and isEnabled then
        BCDM.TrinketBarContainer:ClearAllPoints()
        local anchorParent = CustomDB.Layout[2] == "NONE" and UIParent or _G[CustomDB.Layout[2]]
        BCDM.TrinketBarContainer:SetPoint(CustomDB.Layout[1], anchorParent, CustomDB.Layout[3], CustomDB.Layout[4], CustomDB.Layout[5])
        LayoutTrinketBar()
    else
        if BCDM.TrinketBarContainer then
            BCDM.TrinketBarContainer:Hide()
        end
    end
end

function BCDM:AdjustTrinketLayoutIndex(direction, itemId)
    -- Legacy compatibility: trinket order is now driven by equipment slot (13, 14).
    BCDM:UpdateTrinketBar()
end

function BCDM:AdjustTrinketList(itemId, adjustingHow)
    -- Legacy compatibility: trinket list is now driven by equipped on-use trinkets.
    BCDM:UpdateTrinketBar()
end
