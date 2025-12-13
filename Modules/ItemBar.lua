local _, BCDM = ...
BCDM.ItemFrames = BCDM.ItemFrames or {}

local PetFrameEventFrame = CreateFrame("Frame")
PetFrameEventFrame:RegisterEvent("UNIT_PET")

local CustomItems = {
    [241292] = { isActive = false, layoutIndex = 1 }, -- Draught of Rampant Abandon
    [241308] = { isActive = true, layoutIndex = 2 }, -- Light's Potential
    [241304] = { isActive = true, layoutIndex = 3 }, -- Silvermoon Healing Potion
    [241300] = { isActive = false, layoutIndex = 4 }, -- Lightfused Mana Potion
    [241296] = { isActive = false, layoutIndex = 5 }, -- Potion of Zealotry
    [241294] = { isActive = false, layoutIndex = 6 }, -- Potion of Devoured Dreams
    [241286] = { isActive = false, layoutIndex = 7 }, -- Light's Preservation
    [241288] = { isActive = false, layoutIndex = 8 }, -- Potion of Recklessness
    [241302] = { isActive = false, layoutIndex = 9 }, -- Void-Shrouded Tincture
}

BCDM.CustomItems = CustomItems

local function FetchItemData(itemId)
    local itemCount = C_Item.GetItemCount(itemId)
    local startTime, durationTime = C_Item.GetItemCooldown(itemId)
    return itemCount, startTime, durationTime
end

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
    local itemCount = FetchItemData(itemId)
    customItemIcon.Count:SetText(tostring(itemCount))

    customItemIcon.Cooldown = CreateFrame("Cooldown", nil, customItemIcon, "CooldownFrameTemplate")
    customItemIcon.Cooldown:SetAllPoints(customItemIcon)
    customItemIcon.Cooldown:SetDrawEdge(false)
    customItemIcon.Cooldown:SetDrawSwipe(true)
    customItemIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customItemIcon.Cooldown:SetHideCountdownNumbers(false)
    customItemIcon.Cooldown:SetReverse(false)

    customItemIcon:HookScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "ITEM_COUNT_CHANGED" then
            local _itemCount, startTime, durationTime = FetchItemData(itemId)
            if _itemCount then
                customItemIcon.Count:SetText(tostring(_itemCount))
                customItemIcon.Cooldown:SetCooldown(startTime, durationTime)
                if _itemCount <= 0 then
                    customItemIcon.Icon:SetDesaturated(true)
                    customItemIcon.Count:SetText("")
                else
                    customItemIcon.Icon:SetDesaturated(false)
                    customItemIcon.Count:SetText(tostring(_itemCount))
                end
            end
        end
    end)

    customItemIcon.Icon = customItemIcon:CreateTexture(nil, "BACKGROUND")
    customItemIcon.Icon:SetPoint("TOPLEFT", customItemIcon, "TOPLEFT", 1, -1)
    customItemIcon.Icon:SetPoint("BOTTOMRIGHT", customItemIcon, "BOTTOMRIGHT", -1, 1)
    customItemIcon.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
    customItemIcon.Icon:SetTexture(select(10, C_Item.GetItemInfo(itemId)))

    if itemCount <= 0 then
        customItemIcon.Icon:SetDesaturated(true)
        customItemIcon.Count:SetText("")
    else
        customItemIcon.Icon:SetDesaturated(false)
        customItemIcon.Count:SetText(tostring(itemCount))
    end

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
    if not BCDM.ItemContainer then BCDM.ItemContainer = CreateFrame("Frame", "ItemCooldownViewer", UIParent) end
    if #icons == 0 then return end

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

local function AdjustForPetFrame()
    if not C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") then return end
    local CooldownManagerDB = BCDM.db.profile
    local ItemDB = CooldownManagerDB.Items
    local hasPet = UnitExists("pet")
    local anchorFrame = ItemDB.Anchors[2]
    if anchorFrame ~= "UUF_Pet" then return end
    if ItemDB.AutomaticallyAdjustPetFrame then
        if not hasPet and anchorFrame == "UUF_Pet" then
            BCDM.ItemContainer:ClearAllPoints()
            BCDM.ItemContainer:SetPoint(ItemDB.Anchors[1], "UUF_Player", ItemDB.Anchors[3], ItemDB.Anchors[4], ItemDB.Anchors[5])
        elseif hasPet and anchorFrame == "UUF_Pet" then
            BCDM.ItemContainer:ClearAllPoints()
            BCDM.ItemContainer:SetPoint(ItemDB.Anchors[1], ItemDB.Anchors[2], ItemDB.Anchors[3], ItemDB.Anchors[4], ItemDB.Anchors[5])
        end
        PetFrameEventFrame:SetScript("OnEvent", function(self, event, ...) if event == "UNIT_PET" then AdjustForPetFrame() end end)
    else
        BCDM.ItemContainer:ClearAllPoints()
        BCDM.ItemContainer:SetPoint(ItemDB.Anchors[1], ItemDB.Anchors[2], ItemDB.Anchors[3], ItemDB.Anchors[4], ItemDB.Anchors[5])
        PetFrameEventFrame:SetScript("OnEvent", nil)
    end
end

function BCDM:SetupItemIcons()
    local db = BCDM.db.profile
    wipe(BCDM.ItemFrames)
    wipe(BCDM.ItemBar)

    local itemList = db.Items.CustomItems or {}
    local iconOrder = {}

    for itemId, data in pairs(itemList) do
        if data.isActive then
            table.insert(iconOrder, {
                itemId = itemId,
                layoutIndex = data.layoutIndex or 9999
            })
        end
    end

    table.sort(iconOrder, function(a, b)
        return a.layoutIndex < b.layoutIndex
    end)

    for _, entry in ipairs(iconOrder) do
        local frame = CreateItemIcon(entry.itemId)
        if frame then
            BCDM.ItemFrames[entry.itemId] = frame
            table.insert(BCDM.ItemBar, frame)
        end
    end

    LayoutItemIcons()
    AdjustForPetFrame()
end


function BCDM:ResetItemIcons()
    local db = BCDM.db.profile

    for itemId, frame in pairs(BCDM.ItemFrames) do
        if frame then
            frame:Hide()
            frame:ClearAllPoints()
            frame:SetParent(nil)
            frame:UnregisterAllEvents()
            frame:SetScript("OnUpdate", nil)
            frame:SetScript("OnEvent", nil)
        end
        _G["BCDM_Item_" .. itemId] = nil
    end

    wipe(BCDM.ItemFrames)
    wipe(BCDM.ItemBar)

    local itemList = db.Items.CustomItems or {}
    local iconOrder = {}

    for itemId, data in pairs(itemList) do
        if data.isActive then
            table.insert(iconOrder, {
                itemId = itemId,
                layoutIndex = data.layoutIndex or 9999
            })
        end
    end

    table.sort(iconOrder, function(a, b)
        return a.layoutIndex < b.layoutIndex
    end)

    for _, entry in ipairs(iconOrder) do
        local frame = CreateItemIcon(entry.itemId)
        if frame then
            BCDM.ItemFrames[entry.itemId] = frame
            table.insert(BCDM.ItemBar, frame)
        end
    end

    LayoutItemIcons()
    AdjustForPetFrame()
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
    AdjustForPetFrame()
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
    profileDB.Items.CustomItems = profileDB.Items.CustomItems or {}
    local target = profileDB.Items.CustomItems
    for itemId, data in pairs(sourceTable) do
        if target[itemId] == nil then
            local maxIndex = 0
            for _, existing in pairs(target) do
                if existing.layoutIndex and existing.layoutIndex > maxIndex then
                    maxIndex = existing.layoutIndex
                end
            end
            target[itemId] = { isActive = data.isActive, layoutIndex = data.layoutIndex or (maxIndex + 1) }
        end
    end
    local index = 1
    local orderedItems = {}
    for id, data in pairs(target) do
        table.insert(orderedItems, { itemId = id, layoutIndex = data.layoutIndex })
    end
    table.sort(orderedItems, function(a, b) return a.layoutIndex < b.layoutIndex end)
    for _, entry in ipairs(orderedItems) do
        target[entry.itemId].layoutIndex = index
        index = index + 1
    end
end

function BCDM:ResetCustomItems()
    local profileDB = BCDM.db.profile
    profileDB.Items.CustomItems = nil
    BCDM:CopyCustomItemsToDB()
    BCDM:ResetItemIcons()
end

function BCDM:AddCustomItem(itemId)
    if not itemId then return end
    local itemDB = BCDM.db.profile
    itemDB.Items.CustomItems = itemDB.Items.CustomItems or {}
    local items = itemDB.Items.CustomItems
    local maxIndex = 0
    for _, data in pairs(items) do
        if data.layoutIndex and data.layoutIndex > maxIndex then
            maxIndex = data.layoutIndex
        end
    end
    items[itemId] = {
        isActive = true,
        layoutIndex = maxIndex + 1
    }
    BCDM:ResetItemIcons()
end

function BCDM:MoveCustomItem(itemId, delta)
    if not itemId or not delta then return end

    local itemDB = BCDM.db.profile
    local items = itemDB.Items.CustomItems
    if not items or not items[itemId] then return end

    local newIndex = items[itemId].layoutIndex + delta
    if newIndex < 1 then return end

    for _, data in pairs(items) do
        if data.layoutIndex == newIndex then
            data.layoutIndex = items[itemId].layoutIndex
            break
        end
    end

    items[itemId].layoutIndex = newIndex
    BCDM:ResetItemIcons()
end

function BCDM:RemoveCustomItem(itemId)
    if not itemId then return end

    local profileDB = BCDM.db.profile
    if not profileDB.Items.CustomItems then return end
    profileDB.Items.CustomItems[itemId] = nil
    local index = 1
    local sortedItems = {}
    for id, data in pairs(profileDB.Items.CustomItems) do
        table.insert(sortedItems, { itemId = id, layoutIndex = data.layoutIndex })
    end
    table.sort(sortedItems, function(a, b) return a.layoutIndex < b.layoutIndex end)
    for _, entry in ipairs(sortedItems) do
        profileDB.Items.CustomItems[entry.itemId].layoutIndex = index
        index = index + 1
    end
    BCDM:ResetItemIcons()
end
