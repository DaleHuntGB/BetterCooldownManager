local _, BCDM = ...
local AG = LibStub("AceGUI-3.0")
local OpenedGUI = false
local GUIFrame = nil
local LSM = BCDM.LSM

local Anchors = {
    {
        ["TOPLEFT"] = "Top Left",
        ["TOP"] = "Top",
        ["TOPRIGHT"] = "Top Right",
        ["LEFT"] = "Left",
        ["CENTER"] = "Center",
        ["RIGHT"] = "Right",
        ["BOTTOMLEFT"] = "Bottom Left",
        ["BOTTOM"] = "Bottom",
        ["BOTTOMRIGHT"] = "Bottom Right",
    },
    { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" }
}

local PowerNames = {
    [0] = "Mana",
    [1] = "Rage",
    [2] = "Focus",
    [3] = "Energy",
    [4] = "Combo Points",
    [5] = "Runes",
    [6] = "Runic Power",
    [7] = "Soul Shards",
    [8] = "Astral Power",
    [9] = "Holy Power",
    [11] = "Maelstrom",
    [12] = "Chi",
    [13] = "Insanity",
    [16] = "Arcane Charges",
    [17] = "Fury",
    [18] = "Pain",
    [19] = "Essence",
    [20] = "Maelstrom",
    ["STAGGER"] = "Stagger",
    ["SOUL"] = "Soul",
    ["RUNE_RECHARGE"] = "Rune on Cooldown",
}

local ClassToPrettyClass = {
    ["DEATHKNIGHT"] = "|cFFC41E31Death Knight|r",
    ["DRUID"]       = "|cFFFF7C0ADruid|r",
    ["HUNTER"]      = "|cFFABD473Hunter|r",
    ["MAGE"]        = "|cFF69CCF0Mage|r",
    ["MONK"]        = "|cFF00FF96Monk|r",
    ["PALADIN"]     = "|cFFF58CBAPaladin|r",
    ["PRIEST"]      = "|cFFFFFFFFPriest|r",
    ["ROGUE"]       = "|cFFFFF569Rogue|r",
    ["SHAMAN"]      = "|cFF0070D0Shaman|r",
    ["WARLOCK"]     = "|cFF9482C9Warlock|r",
    ["WARRIOR"]     = "|cFFC79C6EWarrior|r",
    ["DEMONHUNTER"] = "|cFFA330C9Demon Hunter|r",
    ["EVOKER"]      = "|cFF33937FEvoker|r",
}

local ParentAnchors = {
    Utility = {
        {
            ["EssentialCooldownViewer"] = "Essential",
            ["BCDM_PowerBar"] = "Power Bar",
            ["BCDM_SecondaryPowerBar"] = "Secondary Bar",
        },
        { "EssentialCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" }
    },
    Buffs = {
        {
            ["EssentialCooldownViewer"] = "Essential",
            ["UtilityCooldownViewer"]   = "Utility",
            ["BCDM_PowerBar"]           = "Power Bar",
            ["BCDM_SecondaryPowerBar"]           = "Secondary Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" }
    },
    Defensives = {
        {
            ["EssentialCooldownViewer"] = "Essential",
            ["UtilityCooldownViewer"]   = "Utility",
            ["BCDM_PowerBar"]           = "Power Bar",
            ["BCDM_SecondaryPowerBar"]           = "Secondary Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" }
    },
    CastBar = {
        {
            ["EssentialCooldownViewer"] = "Essential",
            ["UtilityCooldownViewer"]   = "Utility",
            ["BCDM_PowerBar"]           = "Power Bar",
            ["BCDM_SecondaryPowerBar"]           = "Secondary Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" }
    },
    PowerBar = {
        {
            ["EssentialCooldownViewer"] = "Essential",
            ["UtilityCooldownViewer"]   = "Utility",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer" }
    },
    SecondaryBar = {
        {
            ["EssentialCooldownViewer"] = "Essential",
            ["UtilityCooldownViewer"]   = "Utility",
            ["BCDM_PowerBar"]           = "Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar" }
    },

}

local function FetchEditModeLayouts()
    local allLayouts = {}
    local layoutInfo = C_EditMode.GetLayouts()

    if layoutInfo and layoutInfo.layouts then
        for layoutID, info in pairs(layoutInfo.layouts) do
            allLayouts[layoutID] = info.layoutName
        end
    end

    return allLayouts
end

local function FetchSpellInformation(spellId)
    local spellData = C_Spell.GetSpellInfo(spellId)
    if spellData then
        local spellName = spellData.name
        local icon = spellData.iconID
        return string.format("|T%s:20:20|t %s", icon, spellName)
    end
end

local function AddAnchor(anchorGroup, key, label)
    for _, existingKey in ipairs(anchorGroup[2]) do if existingKey == key then return end end
    anchorGroup[1][key] = label
    table.insert(anchorGroup[2], key)
end

local function CreateInfoTag(Description)
    local InfoDesc = AG:Create("Label")
    InfoDesc:SetText(BCDM.InfoButton .. Description)
    InfoDesc:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    InfoDesc:SetFullWidth(true)
    InfoDesc:SetJustifyH("CENTER")
    InfoDesc:SetHeight(24)
    InfoDesc:SetJustifyV("MIDDLE")
    return InfoDesc
end

local function DeepDisable(widget, disabled, skipWidget)
    if widget == skipWidget then return end
    if widget.SetDisabled then widget:SetDisabled(disabled) end
    if widget.children then
        for _, child in ipairs(widget.children) do
            DeepDisable(child, disabled, skipWidget)
        end
    end
end

local function DrawGeneralSettings(parentContainer)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local OpenEditModeButton = AG:Create("Button")
    OpenEditModeButton:SetText("Toggle Edit Mode")
    OpenEditModeButton:SetRelativeWidth(0.33)
    OpenEditModeButton:SetCallback("OnClick", function() if EditModeManagerFrame:IsShown() then EditModeManagerFrame:Hide() else EditModeManagerFrame:Show() end end)
    ScrollFrame:AddChild(OpenEditModeButton)

    local OpenCDMSettingsButton = AG:Create("Button")
    OpenCDMSettingsButton:SetText("Advanced Settings")
    OpenCDMSettingsButton:SetRelativeWidth(0.33)
    OpenCDMSettingsButton:SetCallback("OnClick", function() if CooldownViewerSettings:IsShown() then CooldownViewerSettings:Hide() else CooldownViewerSettings:Show() end end)
    ScrollFrame:AddChild(OpenCDMSettingsButton)

    local CooldownManagerIconZoomSlider = AG:Create("Slider")
    CooldownManagerIconZoomSlider:SetLabel("Icon Zoom")
    CooldownManagerIconZoomSlider:SetValue(GeneralDB.IconZoom)
    CooldownManagerIconZoomSlider:SetSliderValues(0, 1, 0.01)
    CooldownManagerIconZoomSlider:SetIsPercent(true)
    CooldownManagerIconZoomSlider:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.IconZoom = value BCDM:RefreshAllViewers() end)
    CooldownManagerIconZoomSlider:SetRelativeWidth(0.33)
    ScrollFrame:AddChild(CooldownManagerIconZoomSlider)

    local EditModeSettings = AG:Create("InlineGroup")
    EditModeSettings:SetTitle("Edit Mode Settings")
    EditModeSettings:SetFullWidth(true)
    EditModeSettings:SetLayout("Flow")
    ScrollFrame:AddChild(EditModeSettings)

    local AutoEditModeInfoTag = CreateInfoTag("This setting will automatically apply the selected |cFF8080FFEdit Mode Layout|r when logging in.\nThe layouts shown will only be those that you have created/imported.")
    EditModeSettings:AddChild(AutoEditModeInfoTag)

    local AutoSetEditMode = AG:Create("CheckBox")
    AutoSetEditMode:SetLabel("Automatically Apply Edit Mode")
    AutoSetEditMode:SetValue(BCDM.db.global.AutomaticallySetEditMode)
    AutoSetEditMode:SetRelativeWidth(0.5)
    AutoSetEditMode:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.global.AutomaticallySetEditMode = value BCDM:SetEditMode(BCDM.db.global.LayoutNumber) BCDM:UpdateBCDM() LayoutNumber:SetDisabled(not value) end)
    EditModeSettings:AddChild(AutoSetEditMode)

    LayoutNumber = AG:Create("Dropdown")
    LayoutNumber:SetLabel("Edit Mode Layout")
    LayoutNumber:SetList(FetchEditModeLayouts())
    LayoutNumber:SetValue(BCDM.db.global.LayoutNumber)
    LayoutNumber:SetRelativeWidth(0.5)
    LayoutNumber:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.global.LayoutNumber = value BCDM:SetEditMode(value) end)
    LayoutNumber:SetDisabled(not BCDM.db.global.AutomaticallySetEditMode)
    EditModeSettings:AddChild(LayoutNumber)

    local FontContainer = AG:Create("InlineGroup")
    FontContainer:SetTitle("Font Settings")
    FontContainer:SetFullWidth(true)
    FontContainer:SetLayout("Flow")
    ScrollFrame:AddChild(FontContainer)

    local CooldownManagerFontDropdown = AG:Create("LSM30_Font")
    CooldownManagerFontDropdown:SetLabel("Font")
    CooldownManagerFontDropdown:SetList(LSM:HashTable("font"))
    CooldownManagerFontDropdown:SetValue(GeneralDB.Font)
    CooldownManagerFontDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) GeneralDB.Font = value BCDM:UpdateBCDM() end)
    CooldownManagerFontDropdown:SetRelativeWidth(0.5)
    FontContainer:AddChild(CooldownManagerFontDropdown)

    local CooldownManagerFontFlagDropdown = AG:Create("Dropdown")
    CooldownManagerFontFlagDropdown:SetLabel("Font Flag")
    CooldownManagerFontFlagDropdown:SetList({
        ["NONE"] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
    })
    CooldownManagerFontFlagDropdown:SetValue(GeneralDB.FontFlag)
    CooldownManagerFontFlagDropdown:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.FontFlag = value BCDM:UpdateBCDM() end)
    CooldownManagerFontFlagDropdown:SetRelativeWidth(0.5)
    FontContainer:AddChild(CooldownManagerFontFlagDropdown)

    local FontShadowsContainer = AG:Create("InlineGroup")
    FontShadowsContainer:SetTitle("Font Shadows")
    FontShadowsContainer:SetFullWidth(true)
    FontShadowsContainer:SetLayout("Flow")
    FontContainer:AddChild(FontShadowsContainer)

    local FontShadowColour = AG:Create("ColorPicker")
    FontShadowColour:SetLabel("Shadow Colour")
    FontShadowColour:SetColor(unpack(GeneralDB.Shadows.Colour))
    FontShadowColour:SetRelativeWidth(0.33)
    FontShadowColour:SetCallback("OnValueChanged", function(_, _, r, g, b) GeneralDB.Shadows.Colour = {r, g, b} BCDM:UpdateBCDM() end)
    FontShadowsContainer:AddChild(FontShadowColour)

    local FontShadowOffsetX = AG:Create("Slider")
    FontShadowOffsetX:SetLabel("Shadow Offset X")
    FontShadowOffsetX:SetValue(GeneralDB.Shadows.OffsetX)
    FontShadowOffsetX:SetSliderValues(-10, 10, 0.1)
    FontShadowOffsetX:SetRelativeWidth(0.33)
    FontShadowOffsetX:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.Shadows.OffsetX = value BCDM:UpdateBCDM() end)
    FontShadowsContainer:AddChild(FontShadowOffsetX)

    local FontShadowOffsetY = AG:Create("Slider")
    FontShadowOffsetY:SetLabel("Shadow Offset Y")
    FontShadowOffsetY:SetValue(GeneralDB.Shadows.OffsetY)
    FontShadowOffsetY:SetSliderValues(-10, 10, 0.1)
    FontShadowOffsetY:SetRelativeWidth(0.33)
    FontShadowOffsetY:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.Shadows.OffsetY = value BCDM:UpdateBCDM() end)
    FontShadowsContainer:AddChild(FontShadowOffsetY)

    local CooldownTextContainer = AG:Create("InlineGroup")
    CooldownTextContainer:SetTitle("Cooldown Text Settings")
    CooldownTextContainer:SetFullWidth(true)
    CooldownTextContainer:SetLayout("Flow")
    ScrollFrame:AddChild(CooldownTextContainer)

    local CooldownTextContainerInfoTag = CreateInfoTag("These settings only apply to |cFF8080FFEssential|r, |cFF8080FFUtility|r & |cFF8080FFBuffs|r Cooldown Viewers.")
    CooldownTextContainer:AddChild(CooldownTextContainerInfoTag)

    local CooldownText_AnchorFrom = AG:Create("Dropdown")
    CooldownText_AnchorFrom:SetLabel("Anchor From")
    CooldownText_AnchorFrom:SetList(Anchors[1], Anchors[2])
    CooldownText_AnchorFrom:SetValue(GeneralDB.CooldownText.Anchors[1])
    CooldownText_AnchorFrom:SetRelativeWidth(0.33)
    CooldownText_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.Anchors[1] = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_AnchorFrom)

    local CooldownText_AnchorTo = AG:Create("Dropdown")
    CooldownText_AnchorTo:SetLabel("Anchor To")
    CooldownText_AnchorTo:SetList(Anchors[1], Anchors[2])
    CooldownText_AnchorTo:SetValue(GeneralDB.CooldownText.Anchors[2])
    CooldownText_AnchorTo:SetRelativeWidth(0.33)
    CooldownText_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.Anchors[2] = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_AnchorTo)

    local CooldownText_Colour = AG:Create("ColorPicker")
    CooldownText_Colour:SetLabel("Font Colour")
    CooldownText_Colour:SetColor(unpack(GeneralDB.CooldownText.Colour))
    CooldownText_Colour:SetRelativeWidth(0.33)
    CooldownText_Colour:SetCallback("OnValueChanged", function(_, _, r, g, b) GeneralDB.CooldownText.Colour = {r, g, b} BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_Colour)

    local CooldownText_OffsetX = AG:Create("Slider")
    CooldownText_OffsetX:SetLabel("Offset X")
    CooldownText_OffsetX:SetValue(GeneralDB.CooldownText.Anchors[3])
    CooldownText_OffsetX:SetSliderValues(-200, 200, 0.1)
    CooldownText_OffsetX:SetRelativeWidth(0.33)
    CooldownText_OffsetX:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.Anchors[3] = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_OffsetX)

    local CooldownText_OffsetY = AG:Create("Slider")
    CooldownText_OffsetY:SetLabel("Offset Y")
    CooldownText_OffsetY:SetValue(GeneralDB.CooldownText.Anchors[4])
    CooldownText_OffsetY:SetSliderValues(-200, 200, 0.1)
    CooldownText_OffsetY:SetRelativeWidth(0.33)
    CooldownText_OffsetY:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.Anchors[4] = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_OffsetY)

    local CooldownText_FontSize = AG:Create("Slider")
    CooldownText_FontSize:SetLabel("Font Size")
    CooldownText_FontSize:SetValue(GeneralDB.CooldownText.FontSize)
    CooldownText_FontSize:SetSliderValues(8, 40, 0.1)
    CooldownText_FontSize:SetRelativeWidth(0.33)
    CooldownText_FontSize:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.FontSize = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_FontSize)

    local CustomColoursContainer = AG:Create("InlineGroup")
    CustomColoursContainer:SetTitle("Power Colours")
    CustomColoursContainer:SetFullWidth(true)
    CustomColoursContainer:SetLayout("Flow")
    ScrollFrame:AddChild(CustomColoursContainer)

    local DefaultColours = {
        PrimaryPower = {
            [0] = {0, 0, 1},            -- Mana
            [1] = {1, 0, 0},            -- Rage
            [2] = {1, 0.5, 0.25},       -- Focus
            [3] = {1, 1, 0},            -- Energy
            [6] = {0, 0.82, 1},         -- Runic Power
            [8] = {0.75, 0.52, 0.9},     -- Lunar Power
            [11] = {0, 0.5, 1},         -- Maelstrom
            [13] = {0.4, 0, 0.8},       -- Insanity
            [17] = {0.79, 0.26, 0.99},  -- Fury
            [18] = {1, 0.61, 0}         -- Pain
        },
        SecondaryPower = {
            [Enum.PowerType.Chi]           = {0.00, 1.00, 0.59, 1.0 },
            [Enum.PowerType.ComboPoints]   = {1.00, 0.96, 0.41, 1.0 },
            [Enum.PowerType.HolyPower]     = {0.95, 0.90, 0.60, 1.0 },
            [Enum.PowerType.ArcaneCharges] = {0.10, 0.10, 0.98, 1.0},
            [Enum.PowerType.Essence]       = { 0.20, 0.58, 0.50, 1.0 },
            [Enum.PowerType.SoulShards]    = { 0.58, 0.51, 0.79, 1.0 },
            STAGGER                        = { 0.00, 1.00, 0.59, 1.0 },
            [Enum.PowerType.Runes]         = { 0.77, 0.12, 0.23, 1.0 },
            SOUL                           = { 0.29, 0.42, 1.00, 1.0},
            [Enum.PowerType.Maelstrom]     = { 0.25, 0.50, 0.80, 1.0},
            RUNE_RECHARGE                 = { 0.5, 0.5, 0.5, 1.0 }
        }
    }

    local PrimaryColoursContainer = AG:Create("InlineGroup")
    PrimaryColoursContainer:SetTitle("Primary Colours")
    PrimaryColoursContainer:SetFullWidth(true)
    PrimaryColoursContainer:SetLayout("Flow")
    CustomColoursContainer:AddChild(PrimaryColoursContainer)

    local PowerOrder = {0, 1, 2, 3, 6, 8, 11, 13, 17, 18}
    for _, powerType in ipairs(PowerOrder) do
        local powerColour = BCDM.db.profile.General.CustomColours.PrimaryPower[powerType]
        local PowerColour = AG:Create("ColorPicker")
        PowerColour:SetLabel(PowerNames[powerType])
        local R, G, B = unpack(powerColour)
        PowerColour:SetColor(R, G, B)
        PowerColour:SetCallback("OnValueChanged", function(widget, _, r, g, b) BCDM.db.profile.General.CustomColours.PrimaryPower[powerType] = {r, g, b} BCDM:UpdateBCDM() end)
        PowerColour:SetHasAlpha(false)
        PowerColour:SetRelativeWidth(0.19)
        PrimaryColoursContainer:AddChild(PowerColour)
    end

    local SecondaryColoursContainer = AG:Create("InlineGroup")
    SecondaryColoursContainer:SetTitle("Secondary Colours")
    SecondaryColoursContainer:SetFullWidth(true)
    SecondaryColoursContainer:SetLayout("Flow")
    CustomColoursContainer:AddChild(SecondaryColoursContainer)

    local SecondaryPowerOrder = { Enum.PowerType.Chi, Enum.PowerType.ComboPoints, Enum.PowerType.HolyPower, Enum.PowerType.ArcaneCharges, Enum.PowerType.Essence, Enum.PowerType.SoulShards, "STAGGER", Enum.PowerType.Runes, "RUNE_RECHARGE", "SOUL", Enum.PowerType.Maelstrom, }
    for _, powerType in ipairs(SecondaryPowerOrder) do
        local powerColour = BCDM.db.profile.General.CustomColours.SecondaryPower[powerType]
        local PowerColour = AG:Create("ColorPicker")
        PowerColour:SetLabel(PowerNames[powerType] or tostring(powerType))
        local R, G, B = unpack(powerColour)
        PowerColour:SetColor(R, G, B)
        PowerColour:SetCallback("OnValueChanged", function(widget, _, r, g, b) BCDM.db.profile.General.CustomColours.SecondaryPower[powerType] = {r, g, b} BCDM:UpdateBCDM() end)
        PowerColour:SetHasAlpha(false)
        PowerColour:SetRelativeWidth(0.15)
        SecondaryColoursContainer:AddChild(PowerColour)
    end

    local ResetPowerColoursButton = AG:Create("Button")
    ResetPowerColoursButton:SetText("Reset Power Colours")
    ResetPowerColoursButton:SetRelativeWidth(1)
    ResetPowerColoursButton:SetCallback("OnClick", function()
        BCDM.db.profile.General.CustomColours.PrimaryPower = BCDM:CopyTable(DefaultColours.PrimaryPower)
        BCDM.db.profile.General.CustomColours.SecondaryPower = BCDM:CopyTable(DefaultColours.SecondaryPower)
        BCDM:UpdateBCDM()
    end)
    CustomColoursContainer:AddChild(ResetPowerColoursButton)

    local SupportMeContainer = AG:Create("InlineGroup")
    SupportMeContainer:SetTitle("How To Support " .. BCDM.AddOnName .. " Development")
    SupportMeContainer:SetLayout("Flow")
    SupportMeContainer:SetFullWidth(true)
    ScrollFrame:AddChild(SupportMeContainer)

    local KoFiInteractive = AG:Create("InteractiveLabel")
    KoFiInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Ko-Fi.png:16:21|t |cFF8080FFKo-Fi|r")
    KoFiInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    KoFiInteractive:SetJustifyV("MIDDLE")
    KoFiInteractive:SetRelativeWidth(0.33)
    KoFiInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Ko-Fi", "https://ko-fi.com/unhalted") end)
    KoFiInteractive:SetCallback("OnEnter", function() KoFiInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Ko-Fi.png:16:21|t |cFFCCCCCCKo-Fi|r") end)
    KoFiInteractive:SetCallback("OnLeave", function() KoFiInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Ko-Fi.png:16:21|t |cFF8080FFKo-Fi|r") end)
    SupportMeContainer:AddChild(KoFiInteractive)

    local PayPalInteractive = AG:Create("InteractiveLabel")
    PayPalInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\PayPal.png:23:21|t |cFF8080FFPayPal|r")
    PayPalInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    PayPalInteractive:SetJustifyV("MIDDLE")
    PayPalInteractive:SetRelativeWidth(0.33)
    PayPalInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on PayPal", "https://www.paypal.com/paypalme/dhunt1911") end)
    PayPalInteractive:SetCallback("OnEnter", function() PayPalInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\PayPal.png:23:21|t |cFFCCCCCCPayPal|r") end)
    PayPalInteractive:SetCallback("OnLeave", function() PayPalInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\PayPal.png:23:21|t |cFF8080FFPayPal|r") end)
    SupportMeContainer:AddChild(PayPalInteractive)

    local TwitchInteractive = AG:Create("InteractiveLabel")
    TwitchInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Twitch.png:25:21|t |cFF8080FFTwitch|r")
    TwitchInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    TwitchInteractive:SetJustifyV("MIDDLE")
    TwitchInteractive:SetRelativeWidth(0.33)
    TwitchInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Twitch", "https://www.twitch.tv/unhaltedgb") end)
    TwitchInteractive:SetCallback("OnEnter", function() TwitchInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Twitch.png:25:21|t |cFFCCCCCCTwitch|r") end)
    TwitchInteractive:SetCallback("OnLeave", function() TwitchInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Twitch.png:25:21|t |cFF8080FFTwitch|r") end)
    SupportMeContainer:AddChild(TwitchInteractive)

    local DiscordInteractive = AG:Create("InteractiveLabel")
    DiscordInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Discord.png:21:21|t |cFF8080FFDiscord|r")
    DiscordInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    DiscordInteractive:SetJustifyV("MIDDLE")
    DiscordInteractive:SetRelativeWidth(0.33)
    DiscordInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Discord", "https://discord.gg/UZCgWRYvVE") end)
    DiscordInteractive:SetCallback("OnEnter", function() DiscordInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Discord.png:21:21|t |cFFCCCCCCDiscord|r") end)
    DiscordInteractive:SetCallback("OnLeave", function() DiscordInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Discord.png:21:21|t |cFF8080FFDiscord|r") end)
    SupportMeContainer:AddChild(DiscordInteractive)

    local PatreonInteractive = AG:Create("InteractiveLabel")
    PatreonInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Patreon.png:21:21|t |cFF8080FFPatreon|r")
    PatreonInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    PatreonInteractive:SetJustifyV("MIDDLE")
    PatreonInteractive:SetRelativeWidth(0.33)
    PatreonInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Patreon", "https://www.patreon.com/unhalted") end)
    PatreonInteractive:SetCallback("OnEnter", function() PatreonInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Patreon.png:21:21|t |cFFCCCCCCPatreon|r") end)
    PatreonInteractive:SetCallback("OnLeave", function() PatreonInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Patreon.png:21:21|t |cFF8080FFPatreon|r") end)
    SupportMeContainer:AddChild(PatreonInteractive)

    local GithubInteractive = AG:Create("InteractiveLabel")
    GithubInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Github.png:21:21|t |cFF8080FFGithub|r")
    GithubInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    GithubInteractive:SetJustifyV("MIDDLE")
    GithubInteractive:SetRelativeWidth(0.33)
    GithubInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Github", "https://github.com/dalehuntgb/BetterCooldownManager") end)
    GithubInteractive:SetCallback("OnEnter", function() GithubInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Github.png:21:21|t |cFFCCCCCCGithub|r") end)
    GithubInteractive:SetCallback("OnLeave", function() GithubInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Github.png:21:21|t |cFF8080FFGithub|r") end)
    SupportMeContainer:AddChild(GithubInteractive)

    ScrollFrame:DoLayout()

    return ScrollFrame
end

local function DrawCooldownSettings(parentContainer, cooldownViewer)
    local CooldownManagerDB = BCDM.db.profile
    local CooldownViewerDB = CooldownManagerDB[BCDM.CooldownViewerToDB[cooldownViewer]]
    local isEssential = (cooldownViewer == "EssentialCooldownViewer")
    local isUtility = (cooldownViewer == "UtilityCooldownViewer")
    local isBuffs = (cooldownViewer == "BuffIconCooldownViewer")

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    if isBuffs then
        local ToggleContainer = AG:Create("InlineGroup")
        ToggleContainer:SetTitle("Toggles")
        ToggleContainer:SetFullWidth(true)
        ToggleContainer:SetLayout("Flow")
        ScrollFrame:AddChild(ToggleContainer)

        local CentreBuffsHorizontally = AG:Create("CheckBox")
        CentreBuffsHorizontally:SetLabel("Centre Buffs Horizontally")
        CentreBuffsHorizontally:SetValue(CooldownViewerDB.CentreHorizontally)
        CentreBuffsHorizontally:SetRelativeWidth(1)
        CentreBuffsHorizontally:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.CentreHorizontally = value BCDM:UpdateCentreBuffs() end)
        CentreBuffsHorizontally:SetCallback("OnEnter", function() GameTooltip:SetOwner(CentreBuffsHorizontally.frame, "ANCHOR_CURSOR") GameTooltip:SetText("Thank you |cFF8080FFLazarpaky|r for this addition!") end)
        CentreBuffsHorizontally:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        ToggleContainer:AddChild(CentreBuffsHorizontally)
    end

    if not isEssential then
        local UtilityBuffsInfoTag = CreateInfoTag("Edit Mode |cFF8080FFPositioning|r & |cFF8080FFAnchoring|r will be overwritten by these settings.")
        ScrollFrame:AddChild(UtilityBuffsInfoTag)
    end

    local LayoutContainer = AG:Create("InlineGroup")
    LayoutContainer:SetTitle("Layout Settings")
    LayoutContainer:SetFullWidth(true)
    LayoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(LayoutContainer)
    if not isEssential then
        local AnchorParentInfoTag = CreateInfoTag("The |cFF8080FFAnchor Parent|r Frame must be set to an existing frame. You can use the |cFF8080FFParent Selector|r dropdown to select some more common frames.")
        LayoutContainer:AddChild(AnchorParentInfoTag)
    end

    local Viewer_AnchorFrom = AG:Create("Dropdown")
    Viewer_AnchorFrom:SetLabel("Anchor From")
    Viewer_AnchorFrom:SetList(Anchors[1], Anchors[2])
    Viewer_AnchorFrom:SetValue(CooldownViewerDB.Anchors[1])
    Viewer_AnchorFrom:SetRelativeWidth(isEssential and 0.5 or 0.25)
    Viewer_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[1] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_AnchorFrom)

    if not isEssential then
        local Viewer_AnchorParent = AG:Create("EditBox")
        Viewer_AnchorParent:SetLabel("Anchor Parent Frame")
        Viewer_AnchorParent:SetText(CooldownViewerDB.Anchors[2])
        Viewer_AnchorParent:SetRelativeWidth(0.25)
        Viewer_AnchorParent:SetCallback("OnEnterPressed", function(_, _, value) CooldownViewerDB.Anchors[2] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
        LayoutContainer:AddChild(Viewer_AnchorParent)

        if C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") then
            AddAnchor(ParentAnchors.Utility, "UUF_Player", "|cFF8080FFUnhalted|r Unit Frames - Player")
            AddAnchor(ParentAnchors.Utility, "UUF_Target", "|cFF8080FFUnhalted|r Unit Frames - Target")

            AddAnchor(ParentAnchors.Buffs, "UUF_Player", "|cFF8080FFUnhalted|r Unit Frames - Player")
            AddAnchor(ParentAnchors.Buffs, "UUF_Target", "|cFF8080FFUnhalted|r Unit Frames - Target")
        end

        local ParentSelector = AG:Create("Dropdown")
        ParentSelector:SetLabel("Parent Selector")
        ParentSelector:SetList(ParentAnchors[isUtility and "Utility" or "Buffs"][1], ParentAnchors[isUtility and "Utility" or "Buffs"][2])
        ParentSelector:SetValue(CooldownViewerDB.Anchors[2])
        ParentSelector:SetRelativeWidth(0.25)
        ParentSelector:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[2] = value Viewer_AnchorParent:SetText(value) BCDM:UpdateCooldownViewer(cooldownViewer) end)
        LayoutContainer:AddChild(ParentSelector)
    end

    local Viewer_AnchorTo = AG:Create("Dropdown")
    Viewer_AnchorTo:SetLabel("Anchor To")
    Viewer_AnchorTo:SetList(Anchors[1], Anchors[2])
    Viewer_AnchorTo:SetValue(isEssential and CooldownViewerDB.Anchors[2] or CooldownViewerDB.Anchors[3])
    Viewer_AnchorTo:SetRelativeWidth(isEssential and 0.5 or 0.25)
    Viewer_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[isEssential and 2 or 3] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_AnchorTo)

    local Viewer_OffsetX = AG:Create("Slider")
    Viewer_OffsetX:SetLabel("Offset X")
    Viewer_OffsetX:SetValue(isEssential and CooldownViewerDB.Anchors[3] or CooldownViewerDB.Anchors[4])
    Viewer_OffsetX:SetSliderValues(-2000, 2000, 1)
    Viewer_OffsetX:SetRelativeWidth(0.25)
    Viewer_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[isEssential and 3 or 4] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_OffsetX)

    local Viewer_OffsetY = AG:Create("Slider")
    Viewer_OffsetY:SetLabel("Offset Y")
    Viewer_OffsetY:SetValue(isEssential and CooldownViewerDB.Anchors[4] or CooldownViewerDB.Anchors[5])
    Viewer_OffsetY:SetSliderValues(-2000, 2000, 1)
    Viewer_OffsetY:SetRelativeWidth(0.25)
    Viewer_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[isEssential and 4 or 5] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_OffsetY)

    local Viewer_IconWidth = AG:Create("Slider")
    Viewer_IconWidth:SetLabel("Icon Width")
    Viewer_IconWidth:SetValue(CooldownViewerDB.IconSize[1])
    Viewer_IconWidth:SetSliderValues(16, 128, 1)
    Viewer_IconWidth:SetRelativeWidth(0.25)
    Viewer_IconWidth:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.IconSize[1] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_IconWidth)

    local Viewer_IconHeight = AG:Create("Slider")
    Viewer_IconHeight:SetLabel("Icon Height")
    Viewer_IconHeight:SetValue(CooldownViewerDB.IconSize[2])
    Viewer_IconHeight:SetSliderValues(16, 128, 1)
    Viewer_IconHeight:SetRelativeWidth(0.25)
    Viewer_IconHeight:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.IconSize[2] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_IconHeight)

    local ChargesContainer = AG:Create("InlineGroup")
    ChargesContainer:SetTitle("Charges Settings")
    ChargesContainer:SetFullWidth(true)
    ChargesContainer:SetLayout("Flow")
    ScrollFrame:AddChild(ChargesContainer)

    local Charges_AnchorFrom = AG:Create("Dropdown")
    Charges_AnchorFrom:SetLabel("Anchor From")
    Charges_AnchorFrom:SetList(Anchors[1], Anchors[2])
    Charges_AnchorFrom:SetValue(CooldownViewerDB.Count.Anchors[1])
    Charges_AnchorFrom:SetRelativeWidth(0.33)
    Charges_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[1] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    ChargesContainer:AddChild(Charges_AnchorFrom)

    local Charges_AnchorTo = AG:Create("Dropdown")
    Charges_AnchorTo:SetLabel("Anchor To")
    Charges_AnchorTo:SetList(Anchors[1], Anchors[2])
    Charges_AnchorTo:SetValue(CooldownViewerDB.Count.Anchors[2])
    Charges_AnchorTo:SetRelativeWidth(0.33)
    Charges_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[2] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    ChargesContainer:AddChild(Charges_AnchorTo)

    local Charges_Colour = AG:Create("ColorPicker")
    Charges_Colour:SetLabel("Font Colour")
    Charges_Colour:SetColor(unpack(CooldownViewerDB.Count.Colour))
    Charges_Colour:SetRelativeWidth(0.33)
    Charges_Colour:SetCallback("OnValueChanged", function(_, _, r, g, b) CooldownViewerDB.Count.Colour = {r, g, b} BCDM:UpdateCooldownViewer(cooldownViewer) end)
    ChargesContainer:AddChild(Charges_Colour)

    local Charges_OffsetX = AG:Create("Slider")
    Charges_OffsetX:SetLabel("Offset X")
    Charges_OffsetX:SetValue(CooldownViewerDB.Count.Anchors[3])
    Charges_OffsetX:SetSliderValues(-200, 200, 1)
    Charges_OffsetX:SetRelativeWidth(0.33)
    Charges_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[3] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    ChargesContainer:AddChild(Charges_OffsetX)

    local Charges_OffsetY = AG:Create("Slider")
    Charges_OffsetY:SetLabel("Offset Y")
    Charges_OffsetY:SetValue(CooldownViewerDB.Count.Anchors[4])
    Charges_OffsetY:SetSliderValues(-200, 200, 1)
    Charges_OffsetY:SetRelativeWidth(0.33)
    Charges_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[4] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    ChargesContainer:AddChild(Charges_OffsetY)

    local Charges_FontSize = AG:Create("Slider")
    Charges_FontSize:SetLabel("Font Size")
    Charges_FontSize:SetValue(CooldownViewerDB.Count.FontSize)
    Charges_FontSize:SetSliderValues(8, 40, 1)
    Charges_FontSize:SetRelativeWidth(0.33)
    Charges_FontSize:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.FontSize = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    ChargesContainer:AddChild(Charges_FontSize)

    return ScrollFrame
end

local function DrawDefensiveSettings(parentContainer)
    local CooldownManagerDB = BCDM.db.profile
    local CooldownViewerDB = CooldownManagerDB[BCDM.CooldownViewerToDB["DefensiveCooldownViewer"]]

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local LayoutContainer = AG:Create("InlineGroup")
    LayoutContainer:SetTitle("Layout Settings")
    LayoutContainer:SetFullWidth(true)
    LayoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(LayoutContainer)

    local Viewer_AnchorFrom = AG:Create("Dropdown")
    Viewer_AnchorFrom:SetLabel("Anchor From")
    Viewer_AnchorFrom:SetList(Anchors[1], Anchors[2])
    Viewer_AnchorFrom:SetValue(CooldownViewerDB.Anchors[1])
    Viewer_AnchorFrom:SetRelativeWidth(0.5)
    Viewer_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[1] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(Viewer_AnchorFrom)

    local Viewer_AnchorTo = AG:Create("Dropdown")
    Viewer_AnchorTo:SetLabel("Anchor To")
    Viewer_AnchorTo:SetList(Anchors[1], Anchors[2])
    Viewer_AnchorTo:SetValue(CooldownViewerDB.Anchors[3])
    Viewer_AnchorTo:SetRelativeWidth(0.5)
    Viewer_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[3] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(Viewer_AnchorTo)

    local Viewer_AnchorParent = AG:Create("EditBox")
    Viewer_AnchorParent:SetLabel("Anchor Parent Frame")
    Viewer_AnchorParent:SetText(CooldownViewerDB.Anchors[2])
    Viewer_AnchorParent:SetRelativeWidth(0.5)
    Viewer_AnchorParent:SetCallback("OnEnterPressed", function(_, _, value) CooldownViewerDB.Anchors[2] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(Viewer_AnchorParent)

    if C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") then
        AddAnchor(ParentAnchors.Defensives, "UUF_Player", "|cFF8080FFUnhalted|r Unit Frames - Player")
        AddAnchor(ParentAnchors.Defensives, "UUF_Target", "|cFF8080FFUnhalted|r Unit Frames - Target")
    end

    local ParentSelector = AG:Create("Dropdown")
    ParentSelector:SetLabel("Parent Selector")
    ParentSelector:SetList(ParentAnchors.Defensives[1], ParentAnchors.Defensives[2])
    ParentSelector:SetValue(CooldownViewerDB.Anchors[2])
    ParentSelector:SetRelativeWidth(0.5)
    ParentSelector:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[2] = value Viewer_AnchorParent:SetText(value) BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(ParentSelector)

    local GrowthDirection = AG:Create("Dropdown")
    GrowthDirection:SetLabel("Growth Direction")
    GrowthDirection:SetList({ ["LEFT"] = "Left", ["RIGHT"] = "Right", })
    GrowthDirection:SetValue(CooldownViewerDB.GrowthDirection)
    GrowthDirection:SetRelativeWidth(1)
    GrowthDirection:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.GrowthDirection = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(GrowthDirection)

    local Viewer_OffsetX = AG:Create("Slider")
    Viewer_OffsetX:SetLabel("Offset X")
    Viewer_OffsetX:SetValue(CooldownViewerDB.Anchors[4])
    Viewer_OffsetX:SetSliderValues(-2000, 2000, 1)
    Viewer_OffsetX:SetRelativeWidth(0.25)
    Viewer_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[4] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(Viewer_OffsetX)

    local Viewer_OffsetY = AG:Create("Slider")
    Viewer_OffsetY:SetLabel("Offset Y")
    Viewer_OffsetY:SetValue(CooldownViewerDB.Anchors[5])
    Viewer_OffsetY:SetSliderValues(-2000, 2000, 1)
    Viewer_OffsetY:SetRelativeWidth(0.25)
    Viewer_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[5] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(Viewer_OffsetY)

    local Viewer_IconWidth = AG:Create("Slider")
    Viewer_IconWidth:SetLabel("Icon Width")
    Viewer_IconWidth:SetValue(CooldownViewerDB.IconSize[1])
    Viewer_IconWidth:SetSliderValues(16, 128, 1)
    Viewer_IconWidth:SetRelativeWidth(0.25)
    Viewer_IconWidth:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.IconSize[1] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(Viewer_IconWidth)

    local Viewer_IconHeight = AG:Create("Slider")
    Viewer_IconHeight:SetLabel("Icon Height")
    Viewer_IconHeight:SetValue(CooldownViewerDB.IconSize[2])
    Viewer_IconHeight:SetSliderValues(16, 128, 1)
    Viewer_IconHeight:SetRelativeWidth(0.25)
    Viewer_IconHeight:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.IconSize[2] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    LayoutContainer:AddChild(Viewer_IconHeight)

    local ChargesContainer = AG:Create("InlineGroup")
    ChargesContainer:SetTitle("Charges Settings")
    ChargesContainer:SetFullWidth(true)
    ChargesContainer:SetLayout("Flow")
    ScrollFrame:AddChild(ChargesContainer)

    local Charges_AnchorFrom = AG:Create("Dropdown")
    Charges_AnchorFrom:SetLabel("Anchor From")
    Charges_AnchorFrom:SetList(Anchors[1], Anchors[2])
    Charges_AnchorFrom:SetValue(CooldownViewerDB.Count.Anchors[1])
    Charges_AnchorFrom:SetRelativeWidth(0.33)
    Charges_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[1] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    ChargesContainer:AddChild(Charges_AnchorFrom)

    local Charges_AnchorTo = AG:Create("Dropdown")
    Charges_AnchorTo:SetLabel("Anchor To")
    Charges_AnchorTo:SetList(Anchors[1], Anchors[2])
    Charges_AnchorTo:SetValue(CooldownViewerDB.Count.Anchors[2])
    Charges_AnchorTo:SetRelativeWidth(0.33)
    Charges_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[2] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    ChargesContainer:AddChild(Charges_AnchorTo)

    local Charges_Colour = AG:Create("ColorPicker")
    Charges_Colour:SetLabel("Font Colour")
    Charges_Colour:SetColor(unpack(CooldownViewerDB.Count.Colour))
    Charges_Colour:SetRelativeWidth(0.33)
    Charges_Colour:SetCallback("OnValueChanged", function(_, _, r, g, b) CooldownViewerDB.Count.Colour = {r, g, b} BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    ChargesContainer:AddChild(Charges_Colour)

    local Charges_OffsetX = AG:Create("Slider")
    Charges_OffsetX:SetLabel("Offset X")
    Charges_OffsetX:SetValue(CooldownViewerDB.Count.Anchors[3])
    Charges_OffsetX:SetSliderValues(-200, 200, 1)
    Charges_OffsetX:SetRelativeWidth(0.33)
    Charges_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[3] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    ChargesContainer:AddChild(Charges_OffsetX)

    local Charges_OffsetY = AG:Create("Slider")
    Charges_OffsetY:SetLabel("Offset Y")
    Charges_OffsetY:SetValue(CooldownViewerDB.Count.Anchors[4])
    Charges_OffsetY:SetSliderValues(-200, 200, 1)
    Charges_OffsetY:SetRelativeWidth(0.33)
    Charges_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.Anchors[4] = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    ChargesContainer:AddChild(Charges_OffsetY)

    local Charges_FontSize = AG:Create("Slider")
    Charges_FontSize:SetLabel("Font Size")
    Charges_FontSize:SetValue(CooldownViewerDB.Count.FontSize)
    Charges_FontSize:SetSliderValues(8, 40, 1)
    Charges_FontSize:SetRelativeWidth(0.33)
    Charges_FontSize:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Count.FontSize = value BCDM:UpdateCooldownViewer("DefensiveCooldownViewer") end)
    ChargesContainer:AddChild(Charges_FontSize)

    local SupportedDefensivesContainer = AG:Create("InlineGroup")
    SupportedDefensivesContainer:SetTitle("Defensives")
    SupportedDefensivesContainer:SetFullWidth(true)
    SupportedDefensivesContainer:SetLayout("Flow")
    ScrollFrame:AddChild(SupportedDefensivesContainer)

    local SupportedDefensiveContainerInfoTag = CreateInfoTag("Below are all the abilities for " .. ClassToPrettyClass[select(2, UnitClass("player"))] .. ". Check the ones you want to track in the |cFF8080FFDefensive Cooldown Viewer|r.")
    SupportedDefensivesContainer:AddChild(SupportedDefensiveContainerInfoTag)

    local playerClass = select(2, UnitClass("player"))

    local classContainer = AG:Create("InlineGroup")
    classContainer:SetTitle(ClassToPrettyClass[playerClass])
    classContainer:SetFullWidth(true)
    classContainer:SetLayout("Flow")
    SupportedDefensivesContainer:AddChild(classContainer)

    for spellID in pairs(BCDM.DefensiveSpells[playerClass]) do
        local DefensiveAbilityCheckBox = AG:Create("CheckBox")
        DefensiveAbilityCheckBox:SetLabel(FetchSpellInformation(spellID))
        DefensiveAbilityCheckBox:SetRelativeWidth(0.33)
        DefensiveAbilityCheckBox:SetValue(CooldownManagerDB.Defensive.DefensiveSpells[select(2, UnitClass("player"))][spellID] or false)
        DefensiveAbilityCheckBox:SetCallback("OnValueChanged", function(_, _, value) CooldownManagerDB.Defensive.DefensiveSpells[select(2, UnitClass("player"))][spellID] = value BCDM:ResetCustomIcons() end)
        DefensiveAbilityCheckBox:SetCallback("OnEnter", function() GameTooltip:SetOwner(DefensiveAbilityCheckBox.frame, "ANCHOR_CURSOR") GameTooltip:SetSpellByID(spellID) end)
        DefensiveAbilityCheckBox:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        classContainer:AddChild(DefensiveAbilityCheckBox)
    end

    ScrollFrame:DoLayout()

    return ScrollFrame
end

local function DrawPowerBarSettings(parentContainer)
    local PowerBarDB = BCDM.db.profile.PowerBar

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local TextureColourContainer = AG:Create("InlineGroup")
    TextureColourContainer:SetTitle("Texture & Colour Settings")
    TextureColourContainer:SetFullWidth(true)
    TextureColourContainer:SetLayout("Flow")
    ScrollFrame:AddChild(TextureColourContainer)

    local ForegroundTextureDropdown = AG:Create("LSM30_Statusbar")
    ForegroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    ForegroundTextureDropdown:SetLabel("Foreground Texture")
    ForegroundTextureDropdown:SetValue(PowerBarDB.FGTexture)
    ForegroundTextureDropdown:SetRelativeWidth(0.5)
    ForegroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) PowerBarDB.FGTexture = value BCDM:UpdatePowerBar() end)
    TextureColourContainer:AddChild(ForegroundTextureDropdown)

    local BackgroundTextureDropdown = AG:Create("LSM30_Statusbar")
    BackgroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    BackgroundTextureDropdown:SetLabel("Background Texture")
    BackgroundTextureDropdown:SetValue(PowerBarDB.BGTexture)
    BackgroundTextureDropdown:SetRelativeWidth(0.5)
    BackgroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) PowerBarDB.BGTexture = value BCDM:UpdatePowerBar() end)
    TextureColourContainer:AddChild(BackgroundTextureDropdown)

    FGColour = AG:Create("ColorPicker")
    FGColour:SetLabel("Foreground Colour")
    FGColour:SetColor(unpack(PowerBarDB.FGColour))
    FGColour:SetRelativeWidth(0.33)
    FGColour:SetCallback("OnValueChanged", function(_, _, r, g, b, a) PowerBarDB.FGColour = {r, g, b, a} BCDM:UpdatePowerBar() end)
    FGColour:SetDisabled(PowerBarDB.ColourByPower)
    TextureColourContainer:AddChild(FGColour)

    local BGColour = AG:Create("ColorPicker")
    BGColour:SetLabel("Background Colour")
    BGColour:SetColor(unpack(PowerBarDB.BGColour))
    BGColour:SetRelativeWidth(0.33)
    BGColour:SetCallback("OnValueChanged", function(_, _, r, g, b,  a) PowerBarDB.BGColour = {r, g, b, a} BCDM:UpdatePowerBar() end)
    TextureColourContainer:AddChild(BGColour)

    local ColourPowerBarByPower = AG:Create("CheckBox")
    ColourPowerBarByPower:SetLabel("Colour by Type")
    ColourPowerBarByPower:SetValue(PowerBarDB.ColourByPower)
    ColourPowerBarByPower:SetRelativeWidth(0.33)
    ColourPowerBarByPower:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColourByPower = value BCDM:UpdatePowerBar() FGColour:SetDisabled(value) end)
    TextureColourContainer:AddChild(ColourPowerBarByPower)

    local LayoutContainer = AG:Create("InlineGroup")
    LayoutContainer:SetTitle("Layout Settings")
    LayoutContainer:SetFullWidth(true)
    LayoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(LayoutContainer)

    local PowerBar_AnchorFrom = AG:Create("Dropdown")
    PowerBar_AnchorFrom:SetLabel("Anchor From")
    PowerBar_AnchorFrom:SetList(Anchors[1], Anchors[2])
    PowerBar_AnchorFrom:SetValue(PowerBarDB.Anchors[1])
    PowerBar_AnchorFrom:SetRelativeWidth(0.33)
    PowerBar_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Anchors[1] = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_AnchorFrom)

    local PowerBar_AnchorParent = AG:Create("Dropdown")
    PowerBar_AnchorParent:SetLabel("Anchor Parent Frame")
    PowerBar_AnchorParent:SetList(ParentAnchors.PowerBar[1], ParentAnchors.PowerBar[2])
    PowerBar_AnchorParent:SetValue(PowerBarDB.Anchors[2])
    PowerBar_AnchorParent:SetRelativeWidth(0.33)
    PowerBar_AnchorParent:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Anchors[2] = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_AnchorParent)

    local PowerBar_AnchorTo = AG:Create("Dropdown")
    PowerBar_AnchorTo:SetLabel("Anchor To")
    PowerBar_AnchorTo:SetList(Anchors[1], Anchors[2])
    PowerBar_AnchorTo:SetValue(PowerBarDB.Anchors[3])
    PowerBar_AnchorTo:SetRelativeWidth(0.33)
    PowerBar_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Anchors[3] = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_AnchorTo)

    local PowerBar_OffsetX = AG:Create("Slider")
    PowerBar_OffsetX:SetLabel("Offset X")
    PowerBar_OffsetX:SetValue(PowerBarDB.Anchors[4])
    PowerBar_OffsetX:SetSliderValues(-2000, 2000, 0.1)
    PowerBar_OffsetX:SetRelativeWidth(0.33)
    PowerBar_OffsetX:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Anchors[4] = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_OffsetX)

    local PowerBar_OffsetY = AG:Create("Slider")
    PowerBar_OffsetY:SetLabel("Offset Y")
    PowerBar_OffsetY:SetValue(PowerBarDB.Anchors[5])
    PowerBar_OffsetY:SetSliderValues(-2000, 2000, 0.1)
    PowerBar_OffsetY:SetRelativeWidth(0.33)
    PowerBar_OffsetY:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Anchors[5] = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_OffsetY)

    local PowerBar_Height = AG:Create("Slider")
    PowerBar_Height:SetLabel("Height")
    PowerBar_Height:SetValue(PowerBarDB.Height)
    PowerBar_Height:SetSliderValues(5, 50, 0.1)
    PowerBar_Height:SetRelativeWidth(0.33)
    PowerBar_Height:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Height = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_Height)

    local TextContainer = AG:Create("InlineGroup")
    TextContainer:SetTitle("Text Settings")
    TextContainer:SetFullWidth(true)
    TextContainer:SetLayout("Flow")
    ScrollFrame:AddChild(TextContainer)

    local Text_AnchorFrom = AG:Create("Dropdown")
    Text_AnchorFrom:SetLabel("Anchor From")
    Text_AnchorFrom:SetList(Anchors[1], Anchors[2])
    Text_AnchorFrom:SetValue(PowerBarDB.Text.Anchors[1])
    Text_AnchorFrom:SetRelativeWidth(0.5)
    Text_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[1] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_AnchorFrom)

    local Text_AnchorTo = AG:Create("Dropdown")
    Text_AnchorTo:SetLabel("Anchor To")
    Text_AnchorTo:SetList(Anchors[1], Anchors[2])
    Text_AnchorTo:SetValue(PowerBarDB.Text.Anchors[2])
    Text_AnchorTo:SetRelativeWidth(0.5)
    Text_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[2] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_AnchorTo)

    Text_Colour = AG:Create("ColorPicker")
    Text_Colour:SetLabel("Font Colour")
    Text_Colour:SetColor(unpack(PowerBarDB.Text.Colour))
    Text_Colour:SetRelativeWidth(0.5)
    Text_Colour:SetCallback("OnValueChanged", function(_, _, r, g, b) PowerBarDB.Text.Colour = {r, g, b} BCDM:UpdatePowerBar() end)
    Text_Colour:SetDisabled(PowerBarDB.Text.ColourByPower)
    TextContainer:AddChild(Text_Colour)

    local ColourPowerTextByPower = AG:Create("CheckBox")
    ColourPowerTextByPower:SetLabel("Colour by Type")
    ColourPowerTextByPower:SetValue(PowerBarDB.Text.ColourByPower)
    ColourPowerTextByPower:SetRelativeWidth(0.5)
    ColourPowerTextByPower:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.ColourByPower = value BCDM:UpdatePowerBar() Text_Colour:SetDisabled(value) end)
    TextContainer:AddChild(ColourPowerTextByPower)

    local Text_OffsetX = AG:Create("Slider")
    Text_OffsetX:SetLabel("Offset X")
    Text_OffsetX:SetValue(PowerBarDB.Text.Anchors[3])
    Text_OffsetX:SetSliderValues(-200, 200, 0.1)
    Text_OffsetX:SetRelativeWidth(0.33)
    Text_OffsetX:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[3] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_OffsetX)

    local Text_OffsetY = AG:Create("Slider")
    Text_OffsetY:SetLabel("Offset Y")
    Text_OffsetY:SetValue(PowerBarDB.Text.Anchors[4])
    Text_OffsetY:SetSliderValues(-200, 200, 0.1)
    Text_OffsetY:SetRelativeWidth(0.33)
    Text_OffsetY:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[4] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_OffsetY)

    local Text_FontSize = AG:Create("Slider")
    Text_FontSize:SetLabel("Font Size")
    Text_FontSize:SetValue(PowerBarDB.Text.FontSize)
    Text_FontSize:SetSliderValues(8, 40, 0.1)
    Text_FontSize:SetRelativeWidth(0.33)
    Text_FontSize:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.FontSize = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_FontSize)

    return ScrollFrame
end

local function DrawCastBarSettings(parentContainer)

    local CastBarDB = BCDM.db.profile.CastBar

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local TextureColourContainer = AG:Create("InlineGroup")
    TextureColourContainer:SetTitle("Texture & Colour Settings")
    TextureColourContainer:SetFullWidth(true)
    TextureColourContainer:SetLayout("Flow")
    ScrollFrame:AddChild(TextureColourContainer)

    local ForegroundTextureDropdown = AG:Create("LSM30_Statusbar")
    ForegroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    ForegroundTextureDropdown:SetLabel("Foreground Texture")
    ForegroundTextureDropdown:SetValue(CastBarDB.FGTexture)
    ForegroundTextureDropdown:SetRelativeWidth(0.5)
    ForegroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) CastBarDB.FGTexture = value BCDM:UpdateCastBar() end)
    TextureColourContainer:AddChild(ForegroundTextureDropdown)

    local BackgroundTextureDropdown = AG:Create("LSM30_Statusbar")
    BackgroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    BackgroundTextureDropdown:SetLabel("Background Texture")
    BackgroundTextureDropdown:SetValue(CastBarDB.BGTexture)
    BackgroundTextureDropdown:SetRelativeWidth(0.5)
    BackgroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) CastBarDB.BGTexture = value BCDM:UpdateCastBar() end)
    TextureColourContainer:AddChild(BackgroundTextureDropdown)

    FGColour = AG:Create("ColorPicker")
    FGColour:SetLabel("Foreground Colour")
    FGColour:SetColor(unpack(CastBarDB.FGColour))
    FGColour:SetRelativeWidth(0.33)
    FGColour:SetCallback("OnValueChanged", function(_, _, r, g, b, a) CastBarDB.FGColour = {r, g, b, a} BCDM:UpdateCastBar() end)
    FGColour:SetDisabled(CastBarDB.ColourByClass)
    TextureColourContainer:AddChild(FGColour)

    local BGColour = AG:Create("ColorPicker")
    BGColour:SetLabel("Background Colour")
    BGColour:SetColor(unpack(CastBarDB.BGColour))
    BGColour:SetRelativeWidth(0.33)
    BGColour:SetCallback("OnValueChanged", function(_, _, r, g, b,  a) CastBarDB.BGColour = {r, g, b, a} BCDM:UpdateCastBar() end)
    TextureColourContainer:AddChild(BGColour)

    local ColourCastBarByClass = AG:Create("CheckBox")
    ColourCastBarByClass:SetLabel("Colour by Class")
    ColourCastBarByClass:SetValue(CastBarDB.ColourByClass)
    ColourCastBarByClass:SetRelativeWidth(0.33)
    ColourCastBarByClass:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.ColourByClass = value BCDM:UpdateCastBar() FGColour:SetDisabled(value) end)
    TextureColourContainer:AddChild(ColourCastBarByClass)

    local LayoutContainer = AG:Create("InlineGroup")
    LayoutContainer:SetTitle("Layout Settings")
    LayoutContainer:SetFullWidth(true)
    LayoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(LayoutContainer)

    local CastBar_AnchorFrom = AG:Create("Dropdown")
    CastBar_AnchorFrom:SetLabel("Anchor From")
    CastBar_AnchorFrom:SetList(Anchors[1], Anchors[2])
    CastBar_AnchorFrom:SetValue(CastBarDB.Anchors[1])
    CastBar_AnchorFrom:SetRelativeWidth(0.33)
    CastBar_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Anchors[1] = value BCDM:UpdateCastBar() end)
    LayoutContainer:AddChild(CastBar_AnchorFrom)

    local CastBar_AnchorParent = AG:Create("Dropdown")
    CastBar_AnchorParent:SetLabel("Anchor Parent Frame")
    CastBar_AnchorParent:SetList(ParentAnchors.CastBar[1], ParentAnchors.CastBar[2])
    CastBar_AnchorParent:SetValue(CastBarDB.Anchors[2])
    CastBar_AnchorParent:SetRelativeWidth(0.33)
    CastBar_AnchorParent:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Anchors[2] = value BCDM:UpdateCastBar() end)
    LayoutContainer:AddChild(CastBar_AnchorParent)

    local CastBar_AnchorTo = AG:Create("Dropdown")
    CastBar_AnchorTo:SetLabel("Anchor To")
    CastBar_AnchorTo:SetList(Anchors[1], Anchors[2])
    CastBar_AnchorTo:SetValue(CastBarDB.Anchors[3])
    CastBar_AnchorTo:SetRelativeWidth(0.33)
    CastBar_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Anchors[3] = value BCDM:UpdateCastBar() end)
    LayoutContainer:AddChild(CastBar_AnchorTo)

    local CastBar_OffsetX = AG:Create("Slider")
    CastBar_OffsetX:SetLabel("Offset X")
    CastBar_OffsetX:SetValue(CastBarDB.Anchors[4])
    CastBar_OffsetX:SetSliderValues(-2000, 2000, 0.1)
    CastBar_OffsetX:SetRelativeWidth(0.33)
    CastBar_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Anchors[4] = value BCDM:UpdateCastBar() end)
    LayoutContainer:AddChild(CastBar_OffsetX)

    local CastBar_OffsetY = AG:Create("Slider")
    CastBar_OffsetY:SetLabel("Offset Y")
    CastBar_OffsetY:SetValue(CastBarDB.Anchors[5])
    CastBar_OffsetY:SetSliderValues(-2000, 2000, 0.1)
    CastBar_OffsetY:SetRelativeWidth(0.33)
    CastBar_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Anchors[5] = value BCDM:UpdateCastBar() end)
    LayoutContainer:AddChild(CastBar_OffsetY)

    local CastBar_Height = AG:Create("Slider")
    CastBar_Height:SetLabel("Height")
    CastBar_Height:SetValue(CastBarDB.Height)
    CastBar_Height:SetSliderValues(5, 50, 0.1)
    CastBar_Height:SetRelativeWidth(0.33)
    CastBar_Height:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Height = value BCDM:UpdateCastBar() end)
    LayoutContainer:AddChild(CastBar_Height)

    local TextContainer = AG:Create("InlineGroup")
    TextContainer:SetTitle("Text Settings")
    TextContainer:SetFullWidth(true)
    TextContainer:SetLayout("Flow")
    ScrollFrame:AddChild(TextContainer)

    local SpellNameContainer = AG:Create("InlineGroup")
    SpellNameContainer:SetTitle("Spell Name Settings")
    SpellNameContainer:SetFullWidth(true)
    SpellNameContainer:SetLayout("Flow")
    TextContainer:AddChild(SpellNameContainer)

    local SpellName_AnchorFrom = AG:Create("Dropdown")
    SpellName_AnchorFrom:SetLabel("Anchor From")
    SpellName_AnchorFrom:SetList(Anchors[1], Anchors[2])
    SpellName_AnchorFrom:SetValue(CastBarDB.SpellName.Anchors[1])
    SpellName_AnchorFrom:SetRelativeWidth(0.33)
    SpellName_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.SpellName.Anchors[1] = value BCDM:UpdateCastBar() end)
    SpellNameContainer:AddChild(SpellName_AnchorFrom)

    local SpellName_AnchorTo = AG:Create("Dropdown")
    SpellName_AnchorTo:SetLabel("Anchor To")
    SpellName_AnchorTo:SetList(Anchors[1], Anchors[2])
    SpellName_AnchorTo:SetValue(CastBarDB.SpellName.Anchors[2])
    SpellName_AnchorTo:SetRelativeWidth(0.33)
    SpellName_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.SpellName.Anchors[2] = value BCDM:UpdateCastBar() end)
    SpellNameContainer:AddChild(SpellName_AnchorTo)

    SpellName_Colour = AG:Create("ColorPicker")
    SpellName_Colour:SetLabel("Font Colour")
    SpellName_Colour:SetColor(unpack(CastBarDB.SpellName.Colour))
    SpellName_Colour:SetRelativeWidth(0.33)
    SpellName_Colour:SetCallback("OnValueChanged", function(_, _, r, g, b) CastBarDB.SpellName.Colour = {r, g, b} BCDM:UpdateCastBar() end)
    SpellNameContainer:AddChild(SpellName_Colour)

    local SpellName_OffsetX = AG:Create("Slider")
    SpellName_OffsetX:SetLabel("Offset X")
    SpellName_OffsetX:SetValue(CastBarDB.SpellName.Anchors[3])
    SpellName_OffsetX:SetSliderValues(-200, 200, 0.1)
    SpellName_OffsetX:SetRelativeWidth(0.33)
    SpellName_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.SpellName.Anchors[3] = value BCDM:UpdateCastBar() end)
    SpellNameContainer:AddChild(SpellName_OffsetX)

    local SpellName_OffsetY = AG:Create("Slider")
    SpellName_OffsetY:SetLabel("Offset Y")
    SpellName_OffsetY:SetValue(CastBarDB.SpellName.Anchors[4])
    SpellName_OffsetY:SetSliderValues(-200, 200, 0.1)
    SpellName_OffsetY:SetRelativeWidth(0.33)
    SpellName_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.SpellName.Anchors[4] = value BCDM:UpdateCastBar() end)
    SpellNameContainer:AddChild(SpellName_OffsetY)

    local SpellName_FontSize = AG:Create("Slider")
    SpellName_FontSize:SetLabel("Font Size")
    SpellName_FontSize:SetValue(CastBarDB.SpellName.FontSize)
    SpellName_FontSize:SetSliderValues(8, 40, 0.1)
    SpellName_FontSize:SetRelativeWidth(0.33)
    SpellName_FontSize:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.SpellName.FontSize = value BCDM:UpdateCastBar() end)
    SpellNameContainer:AddChild(SpellName_FontSize)

    local DurationContainer = AG:Create("InlineGroup")
    DurationContainer:SetTitle("Duration Settings")
    DurationContainer:SetFullWidth(true)
    DurationContainer:SetLayout("Flow")
    TextContainer:AddChild(DurationContainer)

    local Duration_AnchorFrom = AG:Create("Dropdown")
    Duration_AnchorFrom:SetLabel("Anchor From")
    Duration_AnchorFrom:SetList(Anchors[1], Anchors[2])
    Duration_AnchorFrom:SetValue(CastBarDB.Duration.Anchors[1])
    Duration_AnchorFrom:SetRelativeWidth(0.33)
    Duration_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Duration.Anchors[1] = value BCDM:UpdateCastBar() end)
    DurationContainer:AddChild(Duration_AnchorFrom)

    local Duration_AnchorTo = AG:Create("Dropdown")
    Duration_AnchorTo:SetLabel("Anchor To")
    Duration_AnchorTo:SetList(Anchors[1], Anchors[2])
    Duration_AnchorTo:SetValue(CastBarDB.Duration.Anchors[2])
    Duration_AnchorTo:SetRelativeWidth(0.33)
    Duration_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Duration.Anchors[2] = value BCDM:UpdateCastBar() end)
    DurationContainer:AddChild(Duration_AnchorTo)

    Duration_Colour = AG:Create("ColorPicker")
    Duration_Colour:SetLabel("Font Colour")
    Duration_Colour:SetColor(unpack(CastBarDB.Duration.Colour))
    Duration_Colour:SetRelativeWidth(0.33)
    Duration_Colour:SetCallback("OnValueChanged", function(_, _, r, g, b) CastBarDB.Duration.Colour = {r, g, b} BCDM:UpdateCastBar() end)
    Duration_Colour:SetDisabled(CastBarDB.Duration.ColourByPower)
    DurationContainer:AddChild(Duration_Colour)

    local Duration_OffsetX = AG:Create("Slider")
    Duration_OffsetX:SetLabel("Offset X")
    Duration_OffsetX:SetValue(CastBarDB.Duration.Anchors[3])
    Duration_OffsetX:SetSliderValues(-200, 200, 0.1)
    Duration_OffsetX:SetRelativeWidth(0.25)
    Duration_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Duration.Anchors[3] = value BCDM:UpdateCastBar() end)
    DurationContainer:AddChild(Duration_OffsetX)

    local Duration_OffsetY = AG:Create("Slider")
    Duration_OffsetY:SetLabel("Offset Y")
    Duration_OffsetY:SetValue(CastBarDB.Duration.Anchors[4])
    Duration_OffsetY:SetSliderValues(-200, 200, 0.1)
    Duration_OffsetY:SetRelativeWidth(0.25)
    Duration_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Duration.Anchors[4] = value BCDM:UpdateCastBar() end)
    DurationContainer:AddChild(Duration_OffsetY)

    local Duration_FontSize = AG:Create("Slider")
    Duration_FontSize:SetLabel("Font Size")
    Duration_FontSize:SetValue(CastBarDB.Duration.FontSize)
    Duration_FontSize:SetSliderValues(8, 40, 0.1)
    Duration_FontSize:SetRelativeWidth(0.25)
    Duration_FontSize:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Duration.FontSize = value BCDM:UpdateCastBar() end)
    DurationContainer:AddChild(Duration_FontSize)

    local Duration_ExpirationSlider = AG:Create("Slider")
    Duration_ExpirationSlider:SetLabel("Expiration Threshold (seconds)")
    Duration_ExpirationSlider:SetValue(CastBarDB.Duration.ExpirationThreshold)
    Duration_ExpirationSlider:SetSliderValues(0, 10, 0.1)
    Duration_ExpirationSlider:SetRelativeWidth(0.25)
    Duration_ExpirationSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Duration.ExpirationThreshold = value BCDM:UpdateCastBar() end)
    DurationContainer:AddChild(Duration_ExpirationSlider)

    ScrollFrame:DoLayout()

    return ScrollFrame
end

local function DrawSecondaryBarSettings(parentContainer)
    local SecondaryBarDB = BCDM.db.profile.SecondaryBar

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local TextureColourContainer = AG:Create("InlineGroup")
    TextureColourContainer:SetTitle("Texture & Colour Settings")
    TextureColourContainer:SetFullWidth(true)
    TextureColourContainer:SetLayout("Flow")
    ScrollFrame:AddChild(TextureColourContainer)

    local ForegroundTextureDropdown = AG:Create("LSM30_Statusbar")
    ForegroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    ForegroundTextureDropdown:SetLabel("Foreground Texture")
    ForegroundTextureDropdown:SetValue(SecondaryBarDB.FGTexture)
    ForegroundTextureDropdown:SetRelativeWidth(0.5)
    ForegroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) SecondaryBarDB.FGTexture = value BCDM:UpdateSecondaryPowerBar() end)
    TextureColourContainer:AddChild(ForegroundTextureDropdown)

    local BackgroundTextureDropdown = AG:Create("LSM30_Statusbar")
    BackgroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    BackgroundTextureDropdown:SetLabel("Background Texture")
    BackgroundTextureDropdown:SetValue(SecondaryBarDB.BGTexture)
    BackgroundTextureDropdown:SetRelativeWidth(0.5)
    BackgroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) SecondaryBarDB.BGTexture = value BCDM:UpdateSecondaryPowerBar() end)
    TextureColourContainer:AddChild(BackgroundTextureDropdown)

    FGColour = AG:Create("ColorPicker")
    FGColour:SetLabel("Foreground Colour")
    FGColour:SetColor(unpack(SecondaryBarDB.FGColour))
    FGColour:SetRelativeWidth(0.33)
    FGColour:SetCallback("OnValueChanged", function(_, _, r, g, b, a) SecondaryBarDB.FGColour = {r, g, b, a} BCDM:UpdateSecondaryPowerBar() end)
    FGColour:SetDisabled(SecondaryBarDB.ColourByPower)
    TextureColourContainer:AddChild(FGColour)

    local BGColour = AG:Create("ColorPicker")
    BGColour:SetLabel("Background Colour")
    BGColour:SetColor(unpack(SecondaryBarDB.BGColour))
    BGColour:SetRelativeWidth(0.33)
    BGColour:SetCallback("OnValueChanged", function(_, _, r, g, b,  a) SecondaryBarDB.BGColour = {r, g, b, a} BCDM:UpdateSecondaryPowerBar() end)
    TextureColourContainer:AddChild(BGColour)

    local ColourSecondaryBarByPower = AG:Create("CheckBox")
    ColourSecondaryBarByPower:SetLabel("Colour by Type")
    ColourSecondaryBarByPower:SetValue(SecondaryBarDB.ColourByPower)
    ColourSecondaryBarByPower:SetRelativeWidth(0.33)
    ColourSecondaryBarByPower:SetCallback("OnValueChanged", function(_, _, value) SecondaryBarDB.ColourByPower = value BCDM:UpdateSecondaryPowerBar() FGColour:SetDisabled(value) end)
    TextureColourContainer:AddChild(ColourSecondaryBarByPower)

    local LayoutContainer = AG:Create("InlineGroup")
    LayoutContainer:SetTitle("Layout Settings")
    LayoutContainer:SetFullWidth(true)
    LayoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(LayoutContainer)

    local SecondaryBar_AnchorFrom = AG:Create("Dropdown")
    SecondaryBar_AnchorFrom:SetLabel("Anchor From")
    SecondaryBar_AnchorFrom:SetList(Anchors[1], Anchors[2])
    SecondaryBar_AnchorFrom:SetValue(SecondaryBarDB.Anchors[1])
    SecondaryBar_AnchorFrom:SetRelativeWidth(0.33)
    SecondaryBar_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) SecondaryBarDB.Anchors[1] = value BCDM:UpdateSecondaryPowerBar() end)
    LayoutContainer:AddChild(SecondaryBar_AnchorFrom)

    local SecondaryBar_AnchorParent = AG:Create("Dropdown")
    SecondaryBar_AnchorParent:SetLabel("Anchor Parent Frame")
    SecondaryBar_AnchorParent:SetList(ParentAnchors.SecondaryBar[1], ParentAnchors.SecondaryBar[2])
    SecondaryBar_AnchorParent:SetValue(SecondaryBarDB.Anchors[2])
    SecondaryBar_AnchorParent:SetRelativeWidth(0.33)
    SecondaryBar_AnchorParent:SetCallback("OnValueChanged", function(_, _, value) SecondaryBarDB.Anchors[2] = value BCDM:UpdateSecondaryPowerBar() end)
    LayoutContainer:AddChild(SecondaryBar_AnchorParent)

    local SecondaryBar_AnchorTo = AG:Create("Dropdown")
    SecondaryBar_AnchorTo:SetLabel("Anchor To")
    SecondaryBar_AnchorTo:SetList(Anchors[1], Anchors[2])
    SecondaryBar_AnchorTo:SetValue(SecondaryBarDB.Anchors[3])
    SecondaryBar_AnchorTo:SetRelativeWidth(0.33)
    SecondaryBar_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) SecondaryBarDB.Anchors[3] = value BCDM:UpdateSecondaryPowerBar() end)
    LayoutContainer:AddChild(SecondaryBar_AnchorTo)

    local SecondaryBar_OffsetX = AG:Create("Slider")
    SecondaryBar_OffsetX:SetLabel("Offset X")
    SecondaryBar_OffsetX:SetValue(SecondaryBarDB.Anchors[4])
    SecondaryBar_OffsetX:SetSliderValues(-2000, 2000, 0.1)
    SecondaryBar_OffsetX:SetRelativeWidth(0.33)
    SecondaryBar_OffsetX:SetCallback("OnValueChanged", function(_, _, value) SecondaryBarDB.Anchors[4] = value BCDM:UpdateSecondaryPowerBar() end)
    LayoutContainer:AddChild(SecondaryBar_OffsetX)

    local SecondaryBar_OffsetY = AG:Create("Slider")
    SecondaryBar_OffsetY:SetLabel("Offset Y")
    SecondaryBar_OffsetY:SetValue(SecondaryBarDB.Anchors[5])
    SecondaryBar_OffsetY:SetSliderValues(-2000, 2000, 0.1)
    SecondaryBar_OffsetY:SetRelativeWidth(0.33)
    SecondaryBar_OffsetY:SetCallback("OnValueChanged", function(_, _, value) SecondaryBarDB.Anchors[5] = value BCDM:UpdateSecondaryPowerBar() end)
    LayoutContainer:AddChild(SecondaryBar_OffsetY)

    local SecondaryBar_Height = AG:Create("Slider")
    SecondaryBar_Height:SetLabel("Height")
    SecondaryBar_Height:SetValue(SecondaryBarDB.Height)
    SecondaryBar_Height:SetSliderValues(5, 50, 0.1)
    SecondaryBar_Height:SetRelativeWidth(0.33)
    SecondaryBar_Height:SetCallback("OnValueChanged", function(_, _, value) SecondaryBarDB.Height = value BCDM:UpdateSecondaryPowerBar() end)
    LayoutContainer:AddChild(SecondaryBar_Height)

    return ScrollFrame
end

local function DrawProfileSettings(GUIContainer)
    local profileKeys = {}

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    GUIContainer:AddChild(ScrollFrame)

    local ProfileContainer = AG:Create("InlineGroup")
    ProfileContainer:SetTitle("Profile Management")
    ProfileContainer:SetFullWidth(true)
    ProfileContainer:SetLayout("Flow")
    ScrollFrame:AddChild(ProfileContainer)

    local ActiveProfileHeading = AG:Create("Heading")
    ActiveProfileHeading:SetFullWidth(true)
    ProfileContainer:AddChild(ActiveProfileHeading)

    local function RefreshProfiles()
        wipe(profileKeys)
        local tmp = {}
        for _, name in ipairs(BCDM.db:GetProfiles(tmp, true)) do profileKeys[name] = name end
        local profilesToDelete = {}
        for k, v in pairs(profileKeys) do profilesToDelete[k] = v end
        profilesToDelete[BCDM.db:GetCurrentProfile()] = nil
        SelectProfileDropdown:SetList(profileKeys)
        CopyFromProfileDropdown:SetList(profileKeys)
        DeleteProfileDropdown:SetList(profilesToDelete)
        SelectProfileDropdown:SetValue(BCDM.db:GetCurrentProfile())
        CopyFromProfileDropdown:SetValue(nil)
        DeleteProfileDropdown:SetValue(nil)
        ResetProfileButton:SetText("Reset |cFF8080FF" .. BCDM.db:GetCurrentProfile() .. "|r Profile")
        local isUsingGlobal = BCDM.db.global.UseGlobalProfile
        ActiveProfileHeading:SetText( "Active Profile: |cFFFFFFFF" .. BCDM.db:GetCurrentProfile() .. (isUsingGlobal and " (|cFFFFCC00Global|r)" or "") .. "|r" )
    end

    BCDMG.RefreshProfiles = RefreshProfiles -- Exposed for Share.lua

    SelectProfileDropdown = AG:Create("Dropdown")
    SelectProfileDropdown:SetLabel("Select...")
    SelectProfileDropdown:SetRelativeWidth(0.25)
    SelectProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) BCDM.db:SetProfile(value) BCDM:UpdateBCDM() RefreshProfiles() end)
    ProfileContainer:AddChild(SelectProfileDropdown)

    CopyFromProfileDropdown = AG:Create("Dropdown")
    CopyFromProfileDropdown:SetLabel("Copy From...")
    CopyFromProfileDropdown:SetRelativeWidth(0.25)
    CopyFromProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) BCDM:CreatePrompt("Copy Profile", "Are you sure you want to copy from |cFF8080FF" .. value .. "|r?\nThis will |cFFFF4040overwrite|r your current profile settings.", function() BCDM.db:CopyProfile(value) BCDM:UpdateBCDM() RefreshProfiles() end) end)
    ProfileContainer:AddChild(CopyFromProfileDropdown)

    DeleteProfileDropdown = AG:Create("Dropdown")
    DeleteProfileDropdown:SetLabel("Delete...")
    DeleteProfileDropdown:SetRelativeWidth(0.25)
    DeleteProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) if value ~= BCDM.db:GetCurrentProfile() then BCDM:CreatePrompt("Delete Profile", "Are you sure you want to delete |cFF8080FF" .. value .. "|r?", function() BCDM.db:DeleteProfile(value) BCDM:UpdateBCDM() RefreshProfiles() end) end end)
    ProfileContainer:AddChild(DeleteProfileDropdown)

    ResetProfileButton = AG:Create("Button")
    ResetProfileButton:SetText("Reset |cFF8080FF" .. BCDM.db:GetCurrentProfile() .. "|r Profile")
    ResetProfileButton:SetRelativeWidth(0.25)
    ResetProfileButton:SetCallback("OnClick", function() BCDM.db:ResetProfile() BCDM:ResolveMedia() BCDM:UpdateBCDM() RefreshProfiles() end)
    ProfileContainer:AddChild(ResetProfileButton)

    local CreateProfileEditBox = AG:Create("EditBox")
    CreateProfileEditBox:SetLabel("Profile Name:")
    CreateProfileEditBox:SetText("")
    CreateProfileEditBox:SetRelativeWidth(0.5)
    CreateProfileEditBox:DisableButton(true)
    CreateProfileEditBox:SetCallback("OnEnterPressed", function() CreateProfileEditBox:ClearFocus() end)
    ProfileContainer:AddChild(CreateProfileEditBox)

    local CreateProfileButton = AG:Create("Button")
    CreateProfileButton:SetText("Create Profile")
    CreateProfileButton:SetRelativeWidth(0.5)
    CreateProfileButton:SetCallback("OnClick", function() local profileName = strtrim(CreateProfileEditBox:GetText() or "") if profileName ~= "" then BCDM.db:SetProfile(profileName) BCDM:UpdateBCDM() RefreshProfiles() CreateProfileEditBox:SetText("") end end)
    ProfileContainer:AddChild(CreateProfileButton)

    local GlobalProfileHeading = AG:Create("Heading")
    GlobalProfileHeading:SetText("Global Profile Settings")
    GlobalProfileHeading:SetFullWidth(true)
    ProfileContainer:AddChild(GlobalProfileHeading)

    local GlobalProfileInfoTag = CreateInfoTag("If |cFF8080FFUse Global Profile Settings|r is enabled, the profile selected below will be used as your active profile.\nThis is useful if you want to use the same profile across multiple characters.")
    GlobalProfileInfoTag:SetFullWidth(true)
    ProfileContainer:AddChild(GlobalProfileInfoTag)

    UseGlobalProfileToggle = AG:Create("CheckBox")
    UseGlobalProfileToggle:SetLabel("Use Global Profile Settings")
    UseGlobalProfileToggle:SetValue(BCDM.db.global.UseGlobalProfile)
    UseGlobalProfileToggle:SetRelativeWidth(0.5)
    UseGlobalProfileToggle:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.global.UseGlobalProfile = value if value and BCDM.db.global.GlobalProfile and BCDM.db.global.GlobalProfile ~= "" then BCDM.db:SetProfile(BCDM.db.global.GlobalProfile) end BCDM:UpdateBCDM() GlobalProfileDropdown:SetDisabled(not value) for _, child in ipairs(ProfileContainer.children) do if child ~= UseGlobalProfileToggle and child ~= GlobalProfileDropdown then DeepDisable(child, value) end end RefreshProfiles() end)
    ProfileContainer:AddChild(UseGlobalProfileToggle)

    RefreshProfiles()

    GlobalProfileDropdown = AG:Create("Dropdown")
    GlobalProfileDropdown:SetLabel("Global Profile...")
    GlobalProfileDropdown:SetRelativeWidth(0.5)
    GlobalProfileDropdown:SetList(profileKeys)
    GlobalProfileDropdown:SetValue(BCDM.db.global.GlobalProfile)
    GlobalProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) BCDM.db:SetProfile(value) BCDM.db.global.GlobalProfile = value BCDM:UpdateBCDM() RefreshProfiles() end)
    ProfileContainer:AddChild(GlobalProfileDropdown)

    local SharingContainer = AG:Create("InlineGroup")
    SharingContainer:SetTitle("Profile Sharing")
    SharingContainer:SetFullWidth(true)
    SharingContainer:SetLayout("Flow")
    ScrollFrame:AddChild(SharingContainer)

    local ExportingHeading = AG:Create("Heading")
    ExportingHeading:SetText("Exporting")
    ExportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ExportingHeading)

    local ExportingImportingDesc = CreateInfoTag("You can export your profile by pressing |cFF8080FFExport Profile|r button below & share the string with other " .. BCDM.AddOnName .. " users.")
    SharingContainer:AddChild(ExportingImportingDesc)

    local ExportingEditBox = AG:Create("EditBox")
    ExportingEditBox:SetLabel("Export String...")
    ExportingEditBox:SetText("")
    ExportingEditBox:SetFullWidth(true)
    ExportingEditBox:DisableButton(true)
    ExportingEditBox:SetCallback("OnEnterPressed", function() ExportingEditBox:ClearFocus() end)
    SharingContainer:AddChild(ExportingEditBox)

    local ExportProfileButton = AG:Create("Button")
    ExportProfileButton:SetText("Export Profile")
    ExportProfileButton:SetFullWidth(true)
    ExportProfileButton:SetCallback("OnClick", function() ExportingEditBox:SetText(BCDM:ExportSavedVariables()) ExportingEditBox:HighlightText() ExportingEditBox:SetFocus() end)
    SharingContainer:AddChild(ExportProfileButton)

    local ImportingHeading = AG:Create("Heading")
    ImportingHeading:SetText("Importing")
    ImportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ImportingHeading)

    local ImportingDesc = CreateInfoTag("If you have an exported string, paste it in the |cFF8080FFImport String|r box below & press |cFF8080FFImport Profile|r.")
    SharingContainer:AddChild(ImportingDesc)

    local ImportingEditBox = AG:Create("EditBox")
    ImportingEditBox:SetLabel("Import String...")
    ImportingEditBox:SetText("")
    ImportingEditBox:SetFullWidth(true)
    ImportingEditBox:DisableButton(true)
    ImportingEditBox:SetCallback("OnEnterPressed", function() ImportingEditBox:ClearFocus() end)
    SharingContainer:AddChild(ImportingEditBox)

    local ImportProfileButton = AG:Create("Button")
    ImportProfileButton:SetText("Import Profile")
    ImportProfileButton:SetFullWidth(true)
    ImportProfileButton:SetCallback("OnClick", function() if ImportingEditBox:GetText() ~= "" then BCDM:ImportSavedVariables(ImportingEditBox:GetText()) ImportingEditBox:SetText("") end end)
    SharingContainer:AddChild(ImportProfileButton)
    GlobalProfileDropdown:SetDisabled(not BCDM.db.global.UseGlobalProfile)
    if BCDM.db.global.UseGlobalProfile then for _, child in ipairs(ProfileContainer.children) do if child ~= UseGlobalProfileToggle and child ~= GlobalProfileDropdown then DeepDisable(child, true) end end end

    ScrollFrame:DoLayout()
end

function BCDM:CreateGUI()
    if OpenedGUI then return end
    if InCombatLockdown() then return end

    OpenedGUI = true
    GUIFrame = AG:Create("Frame")
    GUIFrame:SetTitle("|T" .. BCDM.Icon .. ":16:16|t " .. BCDM.AddOnName)
    GUIFrame:SetLayout("Fill")
    GUIFrame:SetWidth(900)
    GUIFrame:SetHeight(600)
    GUIFrame:EnableResize(true)
    GUIFrame:SetCallback("OnClose", function(widget) AG:Release(widget) OpenedGUI = false BCDM:RefreshAllViewers() end)

    local function SelectedGroup(GUIContainer, _, MainGroup)
        GUIContainer:ReleaseChildren()

        local Wrapper = AG:Create("SimpleGroup")
        Wrapper:SetFullWidth(true)
        Wrapper:SetFullHeight(true)
        Wrapper:SetLayout("Fill")
        GUIContainer:AddChild(Wrapper)

        if MainGroup == "General" then
            DrawGeneralSettings(Wrapper)
        elseif MainGroup == "Essential" then
            DrawCooldownSettings(Wrapper, "EssentialCooldownViewer")
        elseif MainGroup == "Utility" then
            DrawCooldownSettings(Wrapper, "UtilityCooldownViewer")
        elseif MainGroup == "Buffs" then
            DrawCooldownSettings(Wrapper, "BuffIconCooldownViewer")
        elseif MainGroup == "Defensives" then
            DrawDefensiveSettings(Wrapper, "DefensiveCooldownViewer")
        elseif MainGroup == "CastBar" then
            DrawCastBarSettings(Wrapper)
        elseif MainGroup == "PowerBar" then
            DrawPowerBarSettings(Wrapper)
        elseif MainGroup == "SecondaryBar" then
            DrawSecondaryBarSettings(Wrapper)
        elseif MainGroup == "Profiles" then
            DrawProfileSettings(Wrapper)
        end
    end

    local GUIContainerTabGroup = AG:Create("TabGroup")
    GUIContainerTabGroup:SetLayout("Flow")
    GUIContainerTabGroup:SetTabs({
        { text = "General", value = "General"},
        { text = "Essential", value = "Essential"},
        { text = "Utility", value = "Utility"},
        { text = "Buffs", value = "Buffs"},
        { text = "Defensives", value = "Defensives"},
        { text = "Cast Bar", value = "CastBar"},
        { text = "Power Bar", value = "PowerBar"},
        { text = "Secondary Bar", value = "SecondaryBar"},
        { text = "Profiles", value = "Profiles"},
    })
    GUIContainerTabGroup:SetCallback("OnGroupSelected", SelectedGroup)
    GUIContainerTabGroup:SelectTab("General")
    GUIFrame:AddChild(GUIContainerTabGroup)
end