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
    BCDM:PrettyPrint("'|cFF8080FF/bcdm|r' for in-game configuration.")

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
        for _, textureRegion in ipairs({ textureParent:GetRegions() }) do
            if textureRegion:IsObjectType("Texture") and textureRegion ~= textureToStrip and textureRegion:IsShown() then
                textureRegion:SetTexture(nil)
                textureRegion:Hide()
            end
        end
    end
end

function BCDM:Init()
    SetupSlashCommands()
    BCDM:ResolveLSM()
    if C_AddOns.IsAddOnLoaded("Blizzard_CooldownViewer") then C_AddOns.LoadAddOn("Blizzard_CooldownViewer") end
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
    BCDM:UpdateCustomCooldownViewer()
    BCDM:UpdateAdditionalCustomCooldownViewer()
    BCDM:UpdateCustomItemBar()
    BCDM:UpdateCustomItemsSpellsBar()
    BCDM:UpdateTrinketBar()
    BCDM:UpdateKeybinds()
end

function BCDM:CreateCooldownViewerOverlays()
    local OVERLAY_COLOUR = { 64/255, 128/255, 255/255, 1 }
    if _G["EssentialCooldownViewer"] then
        local EssentialCooldownViewerOverlay = CreateFrame("Frame", "BCDM_EssentialCooldownViewerOverlay", UIParent, "BackdropTemplate")
        EssentialCooldownViewerOverlay:SetPoint("TOPLEFT", _G["EssentialCooldownViewer"], "TOPLEFT", -8, 8)
        EssentialCooldownViewerOverlay:SetPoint("BOTTOMRIGHT", _G["EssentialCooldownViewer"], "BOTTOMRIGHT", 8, -8)
        EssentialCooldownViewerOverlay:SetBackdrop({ edgeFile = "Interface\\AddOns\\BetterCooldownManager\\Media\\Glow.tga", edgeSize = 8, insets = {left = -8, right = -8, top = -8, bottom = -8} })
        EssentialCooldownViewerOverlay:SetBackdropColor(0, 0, 0, 0)
        EssentialCooldownViewerOverlay:SetBackdropBorderColor(unpack(OVERLAY_COLOUR))
        EssentialCooldownViewerOverlay:Hide()
        BCDM.EssentialCooldownViewerOverlay = EssentialCooldownViewerOverlay
    end

    if _G["UtilityCooldownViewer"] then
        local UtilityCooldownViewerOverlay = CreateFrame("Frame", "BCDM_UtilityCooldownViewerOverlay", UIParent, "BackdropTemplate")
        UtilityCooldownViewerOverlay:SetPoint("TOPLEFT", _G["UtilityCooldownViewer"], "TOPLEFT", -8, 8)
        UtilityCooldownViewerOverlay:SetPoint("BOTTOMRIGHT", _G["UtilityCooldownViewer"], "BOTTOMRIGHT", 8, -8)
        UtilityCooldownViewerOverlay:SetBackdrop({ edgeFile = "Interface\\AddOns\\BetterCooldownManager\\Media\\Glow.tga", edgeSize = 8, insets = {left = -8, right = -8, top = -8, bottom = -8} })
        UtilityCooldownViewerOverlay:SetBackdropColor(0, 0, 0, 0)
        UtilityCooldownViewerOverlay:SetBackdropBorderColor(unpack(OVERLAY_COLOUR))
        UtilityCooldownViewerOverlay:Hide()
        BCDM.UtilityCooldownViewerOverlay = UtilityCooldownViewerOverlay
    end

    if _G["BuffIconCooldownViewer"] then
        local BuffIconCooldownViewerOverlay = CreateFrame("Frame", "BCDM_BuffIconCooldownViewerOverlay", UIParent, "BackdropTemplate")
        BuffIconCooldownViewerOverlay:SetPoint("TOPLEFT", _G["BuffIconCooldownViewer"], "TOPLEFT", -8, 8)
        BuffIconCooldownViewerOverlay:SetPoint("BOTTOMRIGHT", _G["BuffIconCooldownViewer"], "BOTTOMRIGHT", 8, -8)
        BuffIconCooldownViewerOverlay:SetBackdrop({ edgeFile = "Interface\\AddOns\\BetterCooldownManager\\Media\\Glow.tga", edgeSize = 8, insets = {left = -8, right = -8, top = -8, bottom = -8} })
        BuffIconCooldownViewerOverlay:SetBackdropColor(0, 0, 0, 0)
        BuffIconCooldownViewerOverlay:SetBackdropBorderColor(unpack(OVERLAY_COLOUR))
        BuffIconCooldownViewerOverlay:Hide()
        BCDM.BuffIconCooldownViewerOverlay = BuffIconCooldownViewerOverlay
    end
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
    StaticPopupDialogs["UUF_URL_POPUP"] = {
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
    local urlDialog = StaticPopup_Show("UUF_URL_POPUP")
    if urlDialog then
        urlDialog:SetFrameStrata("TOOLTIP")
    end
    return urlDialog
end

function BCDM:CreatePrompt(title, text, onAccept, onCancel, acceptText, cancelText)
    StaticPopupDialogs["UUF_PROMPT_DIALOG"] = {
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
    local promptDialog = StaticPopup_Show("UUF_PROMPT_DIALOG", title, text)
    if promptDialog then
        promptDialog.data = { onAccept = onAccept, onCancel = onCancel }
        promptDialog:SetFrameStrata("TOOLTIP")
    end
    return promptDialog
end

function BCDM:AdjustSpellLayoutIndex(direction, spellId, customDB)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager[customDB]
    local playerClass = select(2, UnitClass("player"))
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()
    local DefensiveSpells = CustomDB.Spells

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

function BCDM:AdjustSpellList(spellId, adjustingHow, customDB)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager[customDB]
    local playerClass = select(2, UnitClass("player"))
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()
    local DefensiveSpells = CustomDB.Spells

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
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
        },
        { "EssentialCooldownViewer", "NONE", "BCDM_PowerBar", "BCDM_SecondaryPowerBar"},
    },
    ["Buffs"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
            ["BCDM_CastBar"] = "|cFF8080FFBetter|rCooldownManager: Cast Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CastBar" },
    },
    ["BuffBar"] = {
    {
        ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
        ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
        ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
        ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
        ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        ["BCDM_CastBar"] = "|cFF8080FFBetter|rCooldownManager: Cast Bar",
    },
    { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CastBar" },
    },
    ["Custom"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    },
    ["AdditionalCustom"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    },
    ["Item"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    },
    ["Trinket"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    },
    ["ItemSpell"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["NONE"] = "|cFF00AEF7Blizzard|r: UIParent",
            ["PlayerFrame"] = "|cFF00AEF7Blizzard|r: Player Frame",
            ["TargetFrame"] = "|cFF00AEF7Blizzard|r: Target Frame",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "NONE", "PlayerFrame", "TargetFrame", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    },
    ["Power"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_SecondaryPowerBar" },
    },
    ["SecondaryPower"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar"},
    },
    ["CastBar"] =
    {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    }
}