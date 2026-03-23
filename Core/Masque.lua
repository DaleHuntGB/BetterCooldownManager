local _, BCDM = ...

local MASQUE_ADDON_NAME = "BetterCooldownManager"
local MASQUE_BUTTON_TYPE = "Aura"

BCDM.MasqueGroupNames = {
    Essential = "Essential",
    Utility = "Utility",
    Buffs = "Buffs",
    Custom = "Custom",
    AdditionalCustom = "Additional Custom",
    Item = "Item",
    Trinket = "Trinkets",
    ItemSpell = "Items & Spells",
}

local function GetMasque()
    if BCDM.MSQ == nil then
        local masque = LibStub("Masque", true)
        BCDM.MSQ = masque or false
    end

    return BCDM.MSQ ~= false and BCDM.MSQ or nil
end

local function ClearIconMasks(texture)
    if not (texture and texture.GetMaskTexture) then return end

    local index = 1
    local textureMask = texture:GetMaskTexture(index)
    while textureMask do
        texture:RemoveMaskTexture(textureMask)
        index = index + 1
        textureMask = texture:GetMaskTexture(index)
    end
end

function BCDM:SetupMasque()
    local masque = GetMasque()
    if not masque then return false end

    self.MasqueGroups = self.MasqueGroups or {}
    self.MasqueButtonGroups = self.MasqueButtonGroups or setmetatable({}, { __mode = "k" })
    return true
end

function BCDM:IsMasqueAvailable()
    return GetMasque() ~= nil
end

function BCDM:IsMasqueEnabled()
    return self:IsMasqueAvailable()
        and self.db
        and self.db.profile
        and self.db.profile.CooldownManager
        and self.db.profile.CooldownManager.General
        and self.db.profile.CooldownManager.General.UseMasque
end

function BCDM:CanMasqueNativeCooldownManager()
    if not self:IsMasqueEnabled() then return false end
    if not (self.db and self.db.profile and self.db.profile.CooldownManager and self.db.profile.CooldownManager.Enable) then return false end
    if C_AddOns.IsAddOnLoaded("MasqueBlizzBars") then return false end
    if C_AddOns.IsAddOnLoaded("ElvUI")
        and ElvUI
        and ElvUI[1]
        and ElvUI[1].private
        and ElvUI[1].private.skins
        and ElvUI[1].private.skins.blizzard
        and ElvUI[1].private.skins.blizzard.cooldownManager
    then
        return false
    end

    return true
end

function BCDM:GetMasqueGroup(groupKey)
    if not self:SetupMasque() then return end

    local group = self.MasqueGroups[groupKey]
    if group then
        return group
    end

    local groupName = self.MasqueGroupNames[groupKey] or groupKey
    group = self.MSQ:Group(MASQUE_ADDON_NAME, groupName, groupKey)
    self.MasqueGroups[groupKey] = group
    return group
end

function BCDM:BuildMasqueRegions(button)
    if not button then return end

    local regions = button.__BCDMMasqueRegions or {}
    wipe(regions)

    if button.Icon then regions.Icon = button.Icon end
    if button.Cooldown then regions.Cooldown = button.Cooldown end

    button.__BCDMMasqueRegions = regions
    return regions
end

function BCDM:PrepareButtonForMasque(button)
    if not button then return end

    if button.Icon then
        ClearIconMasks(button.Icon)
        button.Icon:ClearAllPoints()
        button.Icon:SetAllPoints(button)
    end

    if button.Cooldown then
        button.Cooldown:ClearAllPoints()
        button.Cooldown:SetAllPoints(button)
    end

    if button.BCDMBorders then
        for _, border in ipairs(button.BCDMBorders) do
            border:Hide()
        end
    end

    if button.SetBackdropColor then
        button:SetBackdropColor(0, 0, 0, 0)
    end

    if button.SetBackdropBorderColor then
        button:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

function BCDM:ApplyMasqueButtonTexCoord(button)
    if not (button and button.Icon) then return end

    local iconZoom = 0
    if self.db and self.db.profile and self.db.profile.CooldownManager and self.db.profile.CooldownManager.General then
        iconZoom = (self.db.profile.CooldownManager.General.IconZoom or 0) * 0.5
    end

    local iconWidth = button.Icon:GetWidth()
    local iconHeight = button.Icon:GetHeight()
    if not iconWidth or iconWidth <= 0 then
        iconWidth = button:GetWidth()
    end
    if not iconHeight or iconHeight <= 0 then
        iconHeight = button:GetHeight()
    end

    self:ApplyIconTexCoord(button.Icon, iconWidth, iconHeight, iconZoom)
end

function BCDM:ApplyMasqueToButton(groupKey, button, buttonType)
    if not (groupKey and button and self:IsMasqueEnabled()) then return end

    local group = self:GetMasqueGroup(groupKey)
    if not group then return end

    self:PrepareButtonForMasque(button)
    group:AddButton(button, self:BuildMasqueRegions(button), buttonType or MASQUE_BUTTON_TYPE, true)
    self.MasqueButtonGroups[button] = groupKey
end

function BCDM:RemoveMasqueButton(button)
    if not (button and self.MasqueButtonGroups) then return end

    local groupKey = self.MasqueButtonGroups[button]
    if not groupKey then return end

    local group = self:GetMasqueGroup(groupKey)
    if group then
        group:RemoveButton(button)
    end

    self.MasqueButtonGroups[button] = nil
end

function BCDM:SyncMasqueButtons(groupKey, buttons, buttonType)
    if type(buttons) ~= "table" then return end

    if not self:IsMasqueEnabled() then
        for _, button in ipairs(buttons) do
            self:RemoveMasqueButton(button)
        end
        return
    end

    for _, button in ipairs(buttons) do
        self:ApplyMasqueToButton(groupKey, button, buttonType)
    end

    local group = self:GetMasqueGroup(groupKey)
    if group then
        group:ReSkin(true)
    end

    for _, button in ipairs(buttons) do
        self:ApplyMasqueButtonTexCoord(button)
    end

    C_Timer.After(0, function()
        for _, button in ipairs(buttons) do
            self:ApplyMasqueButtonTexCoord(button)
        end
    end)
end

function BCDM:ClearMasqueContainer(container)
    if not container then return end

    for _, button in ipairs({ container:GetChildren() }) do
        self:RemoveMasqueButton(button)
    end
end

function BCDM:ClearMasqueViewer(viewerName)
    local viewer = type(viewerName) == "string" and _G[viewerName] or viewerName
    if not viewer then return end

    self:ClearMasqueContainer(viewer)
end

function BCDM:DisableMasque()
    if not self.MasqueButtonGroups then return end

    local buttons = {}
    for button in pairs(self.MasqueButtonGroups) do
        buttons[#buttons + 1] = button
    end

    for _, button in ipairs(buttons) do
        self:RemoveMasqueButton(button)
    end
end
