local _, BCDM = ...
BCDM.ItemFrames = BCDM.ItemFrames or {}

local CustomItems = {
    [241292] = false, -- Draught of Rampant Abandon
    [241308] = true, -- Light's Potential
    [241304] = true, -- Silvermoon Healing Potion
    [241300] = false, -- Lightfused Mana Potion
    [241296] = false, -- Potion of Zealotry
    [241294] = false, -- Potion of Devoured Dreams
    [241286] = false, -- Light's Preservation
    [241288] = false, -- Potion of Recklessness
    [241302] = false, -- Void-Shrouded Tincture
}

BCDM.CustomItems = CustomItems

function CreateItemIcon(itemId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local ItemDB = CooldownManagerDB.Items
    if not itemId then return end
    if not C_Item.GetItemInfo(itemId) then return end

    local customItemIcon = CreateFrame("Button", "BCDM_Item_" .. itemId, UIParent, "BackdropTemplate")
    customItemIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customItemIcon:SetBackdropBorderColor(0, 0, 0, 1)
    customItemIcon:SetSize(ItemDB.IconSize[1], ItemDB.IconSize[2])
    customItemIcon:SetPoint(unpack(ItemDB.Anchors))
    customItemIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customItemIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    customItemIcon:RegisterEvent("ITEM_COUNT_CHANGED")

    local HighLevelContainer = CreateFrame("Frame", nil, customItemIcon)
    HighLevelContainer:SetAllPoints(customItemIcon)
    HighLevelContainer:SetFrameLevel(customItemIcon:GetFrameLevel() + 999)

    customItemIcon.Count = HighLevelContainer:CreateFontString(nil, "OVERLAY")
    customItemIcon.Count:SetFont(BCDM.Media.Font, ItemDB.Count.FontSize, GeneralDB.FontFlag)
    customItemIcon.Count:SetPoint(ItemDB.Count.Anchors[1], customItemIcon, ItemDB.Count.Anchors[2], ItemDB.Count.Anchors[3], ItemDB.Count.Anchors[4])
    customItemIcon.Count:SetTextColor(ItemDB.Count.Colour[1], ItemDB.Count.Colour[2], ItemDB.Count.Colour[3], 1)
    customItemIcon.Count:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
    customItemIcon.Count:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)

    customItemIcon.Cooldown = CreateFrame("Cooldown", nil, customItemIcon, "CooldownFrameTemplate")
    customItemIcon.Cooldown:SetAllPoints(customItemIcon)
    customItemIcon.Cooldown:SetDrawEdge(false)
    customItemIcon.Cooldown:SetDrawSwipe(true)
    customItemIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customItemIcon.Cooldown:SetHideCountdownNumbers(false)
    customItemIcon.Cooldown:SetReverse(false)

    customItemIcon:HookScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "ITEM_COUNT_CHANGED" then
            local itemCount = C_Item.GetItemCount(itemId)
            local startTime, durationTime = C_Item.GetItemCooldown(itemId)
            if itemCount then
                customItemIcon.Count:SetText(tostring(itemCount))
                customItemIcon.Cooldown:SetCooldown(startTime, durationTime)
                if itemCount <= 0 then
                    customItemIcon.Icon:SetDesaturated(true)
                    customItemIcon.Count:SetText("")
                else
                    customItemIcon.Icon:SetDesaturated(false)
                    customItemIcon.Count:SetText(tostring(itemCount))
                end
            end
        end
    end)

    customItemIcon.Icon = customItemIcon:CreateTexture(nil, "BACKGROUND")
    customItemIcon.Icon:SetPoint("TOPLEFT", customItemIcon, "TOPLEFT", 1, -1)
    customItemIcon.Icon:SetPoint("BOTTOMRIGHT", customItemIcon, "BOTTOMRIGHT", -1, 1)
    customItemIcon.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
    customItemIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(itemId)))

    return customItemIcon
end

local LayoutConfig = {
    TOPLEFT     = { anchor="TOPLEFT",   offsetMultiplier=0   },
    TOP         = { anchor="TOP",       offsetMultiplier=0   },
    TOPRIGHT    = { anchor="TOPRIGHT",  offsetMultiplier=0   },
    BOTTOMLEFT  = { anchor="TOPLEFT",   offsetMultiplier=1   },
    BOTTOM      = { anchor="TOP",       offsetMultiplier=1   },
    BOTTOMRIGHT = { anchor="TOPRIGHT",  offsetMultiplier=1   },
    CENTER      = { anchor="CENTER",    offsetMultiplier=0.5, isCenter=true },
    LEFT        = { anchor="LEFT",      offsetMultiplier=0.5, isCenter=true },
    RIGHT       = { anchor="RIGHT",     offsetMultiplier=0.5, isCenter=true },
}

function LayoutItemIcons()
    local ItemDB = BCDM.db.profile.Items
    local icons = BCDM.ItemBar
    if #icons == 0 then return end
    if not BCDM.ItemContainer then BCDM.ItemContainer = CreateFrame("Frame", "ItemCooldownViewer", UIParent) end

    local ItemContainer = BCDM.ItemContainer
    local spacing = ItemDB.Spacing
    local iconW   = icons[1]:GetWidth()
    local iconH   = icons[1]:GetHeight()
    local totalW  = (iconW + spacing) * #icons - spacing

    ItemContainer:SetSize(totalW, iconH)
    local layoutConfig = LayoutConfig[ItemDB.Anchors[1]]

    local offsetX = totalW * layoutConfig.offsetMultiplier
    if layoutConfig.isCenter then offsetX = offsetX - iconW / 2 end

    ItemContainer:ClearAllPoints()
    ItemContainer:SetPoint(ItemDB.Anchors[1], ItemDB.Anchors[2], ItemDB.Anchors[3], ItemDB.Anchors[4], ItemDB.Anchors[5])

    local growLeft  = (ItemDB.GrowthDirection == "LEFT")
    for i, icon in ipairs(icons) do
        icon:ClearAllPoints()
        if i == 1 then
            if growLeft then
                icon:SetPoint("RIGHT", ItemContainer, "RIGHT", 0, 0)
            else
                icon:SetPoint("LEFT", ItemContainer, "LEFT", 0, 0)
            end
        else
            local previousIcon = icons[i-1]
            if growLeft then
                icon:SetPoint("RIGHT", previousIcon, "LEFT", -spacing, 0)
            else
                icon:SetPoint("LEFT", previousIcon, "RIGHT", spacing, 0)
            end
        end
    end

    ItemContainer:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    ItemContainer:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            BCDM:ResetItemIcons()
        end
    end)
end

function BCDM:SetupItemIcons()
    local CooldownManagerDB = BCDM.db.profile
    wipe(BCDM.ItemFrames)
    wipe(BCDM.ItemBar)
    local spellList = CooldownManagerDB.Items.CustomItems or {}
    for spellId, isActive in pairs(spellList) do
        if spellId and isActive then
            local frame = CreateItemIcon(spellId)
            BCDM.ItemFrames[spellId] = frame
            table.insert(BCDM.ItemBar, frame)
        end
    end
    LayoutItemIcons()
end

function BCDM:ResetItemIcons()
    local CooldownManagerDB = BCDM.db.profile
    -- Can we even destroy frames?
    for spellId, frame in pairs(BCDM.ItemFrames) do
        if frame then
            frame:Hide()
            frame:ClearAllPoints()
            frame:SetParent(nil)
            frame:UnregisterAllEvents()
            frame:SetScript("OnUpdate", nil)
            frame:SetScript("OnEvent", nil)
        end
        _G["BCDM_Item_" .. spellId] = nil
    end
    wipe(BCDM.ItemFrames)
    wipe(BCDM.ItemBar)
    local spellList = CooldownManagerDB.Items.CustomItems or {}
    for spellId, isActive in pairs(spellList) do
        if spellId and isActive then
            local frame = CreateItemIcon(spellId)
            BCDM.ItemFrames[spellId] = frame
            table.insert(BCDM.ItemBar, frame)
        end
    end
    LayoutItemIcons()
end

function BCDM:UpdateItemIcons()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local ItemDB = CooldownManagerDB.Items
    BCDM.ItemContainer:ClearAllPoints()
    BCDM.ItemContainer:SetPoint(ItemDB.Anchors[1], ItemDB.Anchors[2], ItemDB.Anchors[3], ItemDB.Anchors[4], ItemDB.Anchors[5])
    for _, icon in ipairs(BCDM.ItemBar) do
        if icon then
            icon:SetSize(ItemDB.IconSize[1], ItemDB.IconSize[2])
            icon.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
            icon.Count:ClearAllPoints()
            icon.Count:SetFont(BCDM.Media.Font, ItemDB.Count.FontSize, GeneralDB.FontFlag)
            icon.Count:SetPoint(ItemDB.Count.Anchors[1], icon, ItemDB.Count.Anchors[2], ItemDB.Count.Anchors[3], ItemDB.Count.Anchors[4])
            icon.Count:SetTextColor(ItemDB.Count.Colour[1], ItemDB.Count.Colour[2], ItemDB.Count.Colour[3], 1)
            icon.Count:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
            icon.Count:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        end
    end
    LayoutItemIcons()
end

local SpellsChangedEventFrame = CreateFrame("Frame")
SpellsChangedEventFrame:RegisterEvent("SPELLS_CHANGED")
SpellsChangedEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "SPELLS_CHANGED" then
        if InCombatLockdown() then return end
        BCDM:ResetItemIcons()
    end
end)

function BCDM:CopyCustomItemsToDB()
    local profileDB = BCDM.db.profile
    local sourceTable = CustomItems
    if not profileDB.Items.CustomItems then profileDB.Items.CustomItems = {} end
    local classDB = profileDB.Items.CustomItems
    for itemId, value in pairs(sourceTable) do
        if classDB[itemId] == nil then
            classDB[itemId] = value
        end
    end
end

function BCDM:AddCustomItem(itemId)
    if itemId == nil then return end
    if not itemId then return end
    local profileDB = BCDM.db.profile
    if not profileDB.Items.CustomItems then profileDB.Items.CustomItems = {} end
    profileDB.Items.CustomItems[itemId] = true
    BCDM:ResetItemIcons()
end

function BCDM:RemoveCustomItem(itemId)
    if itemId == nil then return end
    if not itemId then return end
    local profileDB = BCDM.db.profile
    if not profileDB.Items.CustomItems then profileDB.Items.CustomItems = {} end
    profileDB.Items.CustomItems[itemId] = nil
    BCDM:ResetItemIcons()
end
