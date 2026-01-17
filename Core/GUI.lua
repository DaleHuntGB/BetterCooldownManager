local _, BCDM = ...
local LSM = BCDM.LSM
local AG = BCDM.AG
local isGUIOpen = false
local isUnitDeathKnight = BCDM.IS_DEATHKNIGHT
BCDMGUI = {}

local AnchorPoints = { { ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right", ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right", ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right" }, { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT", } }

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
    ["CHARGED_COMBO_POINTS"] = "Charged Combo Points",
    ["RUNES"] = {
        FROST = "Frost",
        UNHOLY = "Unholy",
        BLOOD = "Blood"
    }
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

local AnchorParents = {
    ["Utility"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    },
    ["Buffs"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
            ["BCDM_CastBar"] = "|cFF8080FFBetter|rCooldownManager: Cast Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CastBar" },
    },
    ["BuffBar"] = {
    {
        ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
        ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
        ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
        ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        ["BCDM_CastBar"] = "|cFF8080FFBetter|rCooldownManager: Cast Bar",
    },
    { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar", "BCDM_CastBar" },
},
    ["Custom"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
    },
    ["Item"] = {
        {
            ["EssentialCooldownViewer"] = "|cFF00AEF7Blizzard|r: Essential Cooldown Viewer",
            ["UtilityCooldownViewer"] = "|cFF00AEF7Blizzard|r: Utility Cooldown Viewer",
            ["BCDM_PowerBar"] = "|cFF8080FFBetter|rCooldownManager: Power Bar",
            ["BCDM_SecondaryPowerBar"] = "|cFF8080FFBetter|rCooldownManager: Secondary Power Bar",
        },
        { "EssentialCooldownViewer", "UtilityCooldownViewer", "BCDM_PowerBar", "BCDM_SecondaryPowerBar" },
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

-- AddOn Developers can you use this to add their own anchors.
-- Merely call BCDMG.AddAnchors("AddOnName", {"ViewerType1", "ViewerType2"}, { ["AnchorKey"] = "Display Name", ... })
function AddAnchors(addOnName, addToTypes, anchorTable)
    if not C_AddOns.IsAddOnLoaded(addOnName) then return end
    if type(addToTypes) ~= "table" or type(anchorTable) ~= "table" then return end
    for _, typeName in ipairs(addToTypes) do
        if AnchorParents[typeName] then
            local displayNames = AnchorParents[typeName][1]
            local keyList = AnchorParents[typeName][2]
            for anchorKey, displayName in pairs(anchorTable) do
                if not displayNames[anchorKey] then
                    displayNames[anchorKey] = displayName
                    table.insert(keyList, anchorKey)
                end
            end
        end
    end
end

BCDMG.AddAnchors = AddAnchors

local function FetchSpellInformation(spellId)
    local spellData = C_Spell.GetSpellInfo(spellId)
    if spellData then
        local spellName = spellData.name
        local icon = spellData.iconID
        return string.format("|T%s:16:16|t %s", icon, spellName)
    end
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

local function DetectSecondaryPower()
    local class = select(2, UnitClass("player"))
    local spec  = GetSpecialization()
    local specID = GetSpecializationInfo(spec)
    if class == "MONK" then
        if specID == 268 then return true end
        if specID == 269 then return true end
    elseif class == "ROGUE" then
        return true
    elseif class == "DRUID" then
        local form = GetShapeshiftFormID()
        if form == 1 then return true end
    elseif class == "PALADIN" then
        return true
    elseif class == "WARLOCK" then
        return true
    elseif class == "MAGE" then
        if specID == 62 then return true end
    elseif class == "EVOKER" then
        return true
    elseif class == "DEATHKNIGHT" then
        return true
    elseif class == "DEMONHUNTER" then
        if specID == 1480 then return true end
    elseif class == "SHAMAN" then
        if specID == 263 then return true end
    end
    return false
end

local function GenerateSupportText(parentFrame)
    local SupportOptions = {
        "Support Me on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Ko-Fi.png:13:18|t |cFF8080FFKo-Fi|r!",
        "Support Me on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Patreon.png:14:14|t |cFF8080FFPatreon|r!",
        "|TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\PayPal.png:20:18|t |cFF8080FFPayPal Donations|r are appreciated!",
        "Join the |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Discord.png:18:18|t |cFF8080FFDiscord|r Community!",
        "Report Issues / Feedback on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\GitHub.png:18:18|t |cFF8080FFGitHub|r!",
        "Follow Me on |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Support\\Twitch.png:18:14|t |cFF8080FFTwitch|r!",
        "|cFF8080FFSupport|r is truly appreciated |TInterface\\AddOns\\UnhaltedUnitFrames\\Media\\Emotes\\peepoLove.png:18:18|t " .. "|cFF8080FFDevelopment|r takes time & effort."
    }
    parentFrame.statustext:SetText(SupportOptions[math.random(1, #SupportOptions)])
end

local function FetchItemInformation(itemId)
    local itemName = C_Item.GetItemInfo(itemId)
    local itemTexture = select(10, C_Item.GetItemInfo(itemId))
    if itemName then
        return string.format("|T%s:16:16|t %s", itemTexture, itemName)
    end
end

local function FetchSpellID(spellIdentifier)
    local spellData = C_Spell.GetSpellInfo(spellIdentifier)
    if spellData then
        return spellData.spellID
    end
end

local function CreateInformationTag(containerParent, labelDescription, textJustification)
    local informationLabel = AG:Create("Label")
    informationLabel:SetText(BCDM.INFOBUTTON .. labelDescription)
    informationLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    informationLabel:SetFullWidth(true)
    informationLabel:SetJustifyH(textJustification or "CENTER")
    informationLabel:SetHeight(24)
    informationLabel:SetJustifyV("MIDDLE")
    containerParent:AddChild(informationLabel)
    return informationLabel
end

local function CreateGlowSettings(containerParent)
    containerParent:ReleaseChildren()

    local GlowEnabledCheckbox = AG:Create("CheckBox")
    GlowEnabledCheckbox:SetLabel("Enable Glow")
    GlowEnabledCheckbox:SetValue(BCDM.db.profile.CooldownManager.General.Glow.Enabled)
    GlowEnabledCheckbox:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.General.Glow.Enabled = value BCDM:UpdateBCDM() CreateGlowSettings(containerParent) RefreshCustomGlowSettings() end)
    GlowEnabledCheckbox:SetRelativeWidth(0.33)
    containerParent:AddChild(GlowEnabledCheckbox)

    local GlowTypeDropdown = AG:Create("Dropdown")
    GlowTypeDropdown:SetLabel("Glow Type")
    GlowTypeDropdown:SetList({ ["PIXEL"] = "Pixel", ["AUTO_CAST"] = "Auto Cast", })
    GlowTypeDropdown:SetValue(BCDM.db.profile.CooldownManager.General.Glow.GlowType)
    GlowTypeDropdown:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.General.Glow.GlowType = value BCDM:UpdateBCDM() CreateGlowSettings(containerParent) end)
    GlowTypeDropdown:SetRelativeWidth(0.33)
    containerParent:AddChild(GlowTypeDropdown)

    local GlowColourPicker = AG:Create("ColorPicker")
    GlowColourPicker:SetLabel("Glow Colour")
    GlowColourPicker:SetColor(unpack(BCDM.db.profile.CooldownManager.General.Glow.Colour))
    GlowColourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) BCDM.db.profile.CooldownManager.General.Glow.Colour = {r, g, b} BCDM:UpdateBCDM() end)
    GlowColourPicker:SetRelativeWidth(0.33)
    containerParent:AddChild(GlowColourPicker)

    if BCDM.db.profile.CooldownManager.General.Glow.GlowType == "PIXEL" then
        local GlowThicknessSlider = AG:Create("Slider")
        GlowThicknessSlider:SetLabel("Thickness")
        GlowThicknessSlider:SetValue(BCDM.db.profile.CooldownManager.General.Glow.Thickness)
        GlowThicknessSlider:SetSliderValues(1, 10, 1)
        GlowThicknessSlider:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.General.Glow.Thickness = value BCDM:UpdateBCDM() end)
        GlowThicknessSlider:SetRelativeWidth(0.33)
        containerParent:AddChild(GlowThicknessSlider)

        local GlowLinesSlider = AG:Create("Slider")
        GlowLinesSlider:SetLabel("Number of Lines")
        GlowLinesSlider:SetValue(BCDM.db.profile.CooldownManager.General.Glow.Lines)
        GlowLinesSlider:SetSliderValues(1, 20, 1)
        GlowLinesSlider:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.General.Glow.Lines = value BCDM:UpdateBCDM() end)
        GlowLinesSlider:SetRelativeWidth(0.33)
        containerParent:AddChild(GlowLinesSlider)

        BCDMGUI.GlowThicknessSlider = GlowThicknessSlider
        BCDMGUI.GlowLinesSlider = GlowLinesSlider
    elseif BCDM.db.profile.CooldownManager.General.Glow.GlowType == "AUTO_CAST" then
        local GlowParticlesSlider = AG:Create("Slider")
        GlowParticlesSlider:SetLabel("Particles")
        GlowParticlesSlider:SetValue(BCDM.db.profile.CooldownManager.General.Glow.Particles)
        GlowParticlesSlider:SetSliderValues(1, 10, 1)
        GlowParticlesSlider:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.General.Glow.Particles = value BCDM:UpdateBCDM() end)
        GlowParticlesSlider:SetRelativeWidth(0.33)
        containerParent:AddChild(GlowParticlesSlider)

        local GlowScaleSlider = AG:Create("Slider")
        GlowScaleSlider:SetLabel("Scale")
        GlowScaleSlider:SetValue(BCDM.db.profile.CooldownManager.General.Glow.Scale)
        GlowScaleSlider:SetSliderValues(0.1, 1, 0.01)
        GlowScaleSlider:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.General.Glow.Scale = value BCDM:UpdateBCDM() end)
        GlowScaleSlider:SetRelativeWidth(0.33)
        GlowScaleSlider:SetIsPercent(true)
        containerParent:AddChild(GlowScaleSlider)

        BCDMGUI.GlowParticlesSlider = GlowParticlesSlider
        BCDMGUI.GlowScaleSlider = GlowScaleSlider
    end

    local GlowFrequencySlider = AG:Create("Slider")
    GlowFrequencySlider:SetLabel("Frequency")
    GlowFrequencySlider:SetValue(BCDM.db.profile.CooldownManager.General.Glow.Frequency)
    GlowFrequencySlider:SetSliderValues(0.05, 1, 0.01)
    GlowFrequencySlider:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.General.Glow.Frequency = value BCDM:UpdateBCDM() end)
    GlowFrequencySlider:SetRelativeWidth(0.33)
    containerParent:AddChild(GlowFrequencySlider)

    function RefreshCustomGlowSettings()
        if BCDM.db.profile.CooldownManager.General.Glow.Enabled then
            GlowTypeDropdown:SetDisabled(false)
            GlowColourPicker:SetDisabled(false)
            GlowFrequencySlider:SetDisabled(false)
            if BCDM.db.profile.CooldownManager.General.Glow.GlowType == "PIXEL" then
                BCDMGUI.GlowThicknessSlider:SetDisabled(false)
                BCDMGUI.GlowLinesSlider:SetDisabled(false)
            elseif BCDM.db.profile.CooldownManager.General.Glow.GlowType == "AUTO_CAST" then
                BCDMGUI.GlowParticlesSlider:SetDisabled(false)
                BCDMGUI.GlowScaleSlider:SetDisabled(false)
            end
        else
            GlowTypeDropdown:SetDisabled(true)
            GlowColourPicker:SetDisabled(true)
            GlowFrequencySlider:SetDisabled(true)
            if BCDM.db.profile.CooldownManager.General.Glow.GlowType == "PIXEL" then
                BCDMGUI.GlowThicknessSlider:SetDisabled(true)
                BCDMGUI.GlowLinesSlider:SetDisabled(true)
            elseif BCDM.db.profile.CooldownManager.General.Glow.GlowType == "AUTO_CAST" then
                BCDMGUI.GlowParticlesSlider:SetDisabled(true)
                BCDMGUI.GlowScaleSlider:SetDisabled(true)
            end
        end
    end

    RefreshCustomGlowSettings()

    return containerParent
end

local function CreateCooldownTextSettings(containerParent)
    local CooldownTextDB = BCDM.db.profile.CooldownManager.General.CooldownText

    local cooldownTextContainer = AG:Create("InlineGroup")
    cooldownTextContainer:SetTitle("Cooldown Text Settings")
    cooldownTextContainer:SetFullWidth(true)
    cooldownTextContainer:SetLayout("Flow")
    containerParent:AddChild(cooldownTextContainer)

    local colourPicker = AG:Create("ColorPicker")
    colourPicker:SetLabel("Text Colour")
    colourPicker:SetColor(unpack(CooldownTextDB.Colour))
    colourPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) CooldownTextDB.Colour = {r, g, b} BCDM:UpdateCooldownViewers() end)
    colourPicker:SetRelativeWidth(0.5)
    cooldownTextContainer:AddChild(colourPicker)

    local scaleByIconSizeCheckbox = AG:Create("CheckBox")
    scaleByIconSizeCheckbox:SetLabel("Scale By Icon Size")
    scaleByIconSizeCheckbox:SetValue(CooldownTextDB.ScaleByIconSize)
    scaleByIconSizeCheckbox:SetCallback("OnValueChanged", function(_, _, value) CooldownTextDB.ScaleByIconSize = value BCDM:UpdateCooldownViewers() end)
    scaleByIconSizeCheckbox:SetRelativeWidth(0.5)
    cooldownTextContainer:AddChild(scaleByIconSizeCheckbox)

    local anchorFromDropdown = AG:Create("Dropdown")
    anchorFromDropdown:SetLabel("Anchor From")
    anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorFromDropdown:SetValue(CooldownTextDB.Layout[1])
    anchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) CooldownTextDB.Layout[1] = value BCDM:UpdateCooldownViewers() end)
    anchorFromDropdown:SetRelativeWidth(0.5)
    cooldownTextContainer:AddChild(anchorFromDropdown)

    local anchorToDropdown = AG:Create("Dropdown")
    anchorToDropdown:SetLabel("Anchor To")
    anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorToDropdown:SetValue(CooldownTextDB.Layout[2])
    anchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) CooldownTextDB.Layout[2] = value BCDM:UpdateCooldownViewers() end)
    anchorToDropdown:SetRelativeWidth(0.5)
    cooldownTextContainer:AddChild(anchorToDropdown)

    local xOffsetSlider = AG:Create("Slider")
    xOffsetSlider:SetLabel("X Offset")
    xOffsetSlider:SetValue(CooldownTextDB.Layout[3])
    xOffsetSlider:SetSliderValues(-100, 100, 1)
    xOffsetSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownTextDB.Layout[3] = value BCDM:UpdateCooldownViewers() end)
    xOffsetSlider:SetRelativeWidth(0.33)
    cooldownTextContainer:AddChild(xOffsetSlider)

    local yOffsetSlider = AG:Create("Slider")
    yOffsetSlider:SetLabel("Y Offset")
    yOffsetSlider:SetValue(CooldownTextDB.Layout[4])
    yOffsetSlider:SetSliderValues(-100, 100, 1)
    yOffsetSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownTextDB.Layout[4] = value BCDM:UpdateCooldownViewers() end)
    yOffsetSlider:SetRelativeWidth(0.33)
    cooldownTextContainer:AddChild(yOffsetSlider)

    local fontSizeSlider = AG:Create("Slider")
    fontSizeSlider:SetLabel("Font Size")
    fontSizeSlider:SetValue(CooldownTextDB.FontSize)
    fontSizeSlider:SetSliderValues(8, 32, 1)
    fontSizeSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownTextDB.FontSize = value BCDM:UpdateCooldownViewers() end)
    fontSizeSlider:SetRelativeWidth(0.33)
    cooldownTextContainer:AddChild(fontSizeSlider)

    return cooldownTextContainer
end

local function CreateGeneralSettings(parentContainer)
    local GeneralDB = BCDM.db.profile.General
    local CooldownManagerDB = BCDM.db.profile.CooldownManager

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

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
            RUNE_RECHARGE                 = { 0.5, 0.5, 0.5, 1.0 },
            CHARGED_COMBO_POINTS           = { 0.25, 0.5, 1.00, 1.0}
        }
    }

    local PrimaryColoursContainer = AG:Create("InlineGroup")
    PrimaryColoursContainer:SetTitle("Primary Colours")
    PrimaryColoursContainer:SetFullWidth(true)
    PrimaryColoursContainer:SetLayout("Flow")
    CustomColoursContainer:AddChild(PrimaryColoursContainer)

    local PowerOrder = {0, 1, 2, 3, 6, 8, 11, 13, 17, 18}
    for _, powerType in ipairs(PowerOrder) do
        local powerColour = BCDM.db.profile.General.Colours.PrimaryPower[powerType]
        local PowerColour = AG:Create("ColorPicker")
        PowerColour:SetLabel(PowerNames[powerType])
        local R, G, B = unpack(powerColour)
        PowerColour:SetColor(R, G, B)
        PowerColour:SetCallback("OnValueChanged", function(widget, _, r, g, b) BCDM.db.profile.General.Colours.PrimaryPower[powerType] = {r, g, b} BCDM:UpdateBCDM() end)
        PowerColour:SetHasAlpha(false)
        PowerColour:SetRelativeWidth(0.19)
        PrimaryColoursContainer:AddChild(PowerColour)
    end

    local SecondaryColoursContainer = AG:Create("InlineGroup")
    SecondaryColoursContainer:SetTitle("Secondary Colours")
    SecondaryColoursContainer:SetFullWidth(true)
    SecondaryColoursContainer:SetLayout("Flow")
    CustomColoursContainer:AddChild(SecondaryColoursContainer)

    local SecondaryPowerOrder = { Enum.PowerType.Chi, Enum.PowerType.ComboPoints, Enum.PowerType.HolyPower, Enum.PowerType.ArcaneCharges, Enum.PowerType.Essence, Enum.PowerType.SoulShards, "STAGGER", Enum.PowerType.Runes, "RUNE_RECHARGE", "SOUL", Enum.PowerType.Maelstrom, "CHARGED_COMBO_POINTS" }
    for _, powerType in ipairs(SecondaryPowerOrder) do
        local powerColour = BCDM.db.profile.General.Colours.SecondaryPower[powerType]
        local PowerColour = AG:Create("ColorPicker")
        PowerColour:SetLabel(PowerNames[powerType] or tostring(powerType))
        local R, G, B = unpack(powerColour)
        PowerColour:SetColor(R, G, B)
        PowerColour:SetCallback("OnValueChanged", function(widget, _, r, g, b) BCDM.db.profile.General.Colours.SecondaryPower[powerType] = {r, g, b} BCDM:UpdateBCDM() end)
        PowerColour:SetHasAlpha(false)
        PowerColour:SetRelativeWidth(0.15)
        SecondaryColoursContainer:AddChild(PowerColour)
    end

    if isUnitDeathKnight then
        local runeColourContainer = AG:Create("InlineGroup")
        runeColourContainer:SetTitle("Death Knight Rune Colours")
        runeColourContainer:SetFullWidth(true)
        runeColourContainer:SetLayout("Flow")
        CustomColoursContainer:AddChild(runeColourContainer)
        for _, runeType in ipairs({"FROST", "UNHOLY", "BLOOD"}) do
            local powerColour = BCDM.db.profile.General.Colours.SecondaryPower.RUNES[runeType]
            local PowerColour = AG:Create("ColorPicker")
            PowerColour:SetLabel("Rune: " .. PowerNames["RUNES"][runeType])
            local R, G, B = unpack(powerColour)
            PowerColour:SetColor(R, G, B)
            PowerColour:SetCallback("OnValueChanged", function(widget, _, r, g, b) BCDM.db.profile.General.Colours.SecondaryPower.RUNES[runeType] = {r, g, b} BCDM:UpdateBCDM() end)
            PowerColour:SetHasAlpha(false)
            PowerColour:SetRelativeWidth(0.32)
            runeColourContainer:AddChild(PowerColour)
        end
    end

    local ResetPowerColoursButton = AG:Create("Button")
    ResetPowerColoursButton:SetText("Reset Power Colours")
    ResetPowerColoursButton:SetRelativeWidth(1)
    ResetPowerColoursButton:SetCallback("OnClick", function()
        BCDM.db.profile.General.Colours.PrimaryPower = BCDM:CopyTable(DefaultColours.PrimaryPower)
        BCDM.db.profile.General.Colours.SecondaryPower = BCDM:CopyTable(DefaultColours.SecondaryPower)
        BCDM:UpdateBCDM()
    end)
    CustomColoursContainer:AddChild(ResetPowerColoursButton)

    local SupportMeContainer = AG:Create("InlineGroup")
    SupportMeContainer:SetTitle("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Emotes\\peepoLove.png:18:18|t  How To Support " .. BCDM.PRETTY_ADDON_NAME .. " Development")
    SupportMeContainer:SetLayout("Flow")
    SupportMeContainer:SetFullWidth(true)
    ScrollFrame:AddChild(SupportMeContainer)

    local KoFiInteractive = AG:Create("InteractiveLabel")
    KoFiInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Ko-Fi.png:16:21|t |cFF8080FFKo-Fi|r")
    KoFiInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    KoFiInteractive:SetJustifyV("MIDDLE")
    KoFiInteractive:SetRelativeWidth(0.33)
    KoFiInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Ko-Fi", "https://ko-fi.com/unhalted") end)
    KoFiInteractive:SetCallback("OnEnter", function() KoFiInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Ko-Fi.png:16:21|t |cFFFFFFFFKo-Fi|r") end)
    KoFiInteractive:SetCallback("OnLeave", function() KoFiInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Ko-Fi.png:16:21|t |cFF8080FFKo-Fi|r") end)
    SupportMeContainer:AddChild(KoFiInteractive)

    local PayPalInteractive = AG:Create("InteractiveLabel")
    PayPalInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\PayPal.png:23:21|t |cFF8080FFPayPal|r")
    PayPalInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    PayPalInteractive:SetJustifyV("MIDDLE")
    PayPalInteractive:SetRelativeWidth(0.33)
    PayPalInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on PayPal", "https://www.paypal.com/paypalme/dhunt1911") end)
    PayPalInteractive:SetCallback("OnEnter", function() PayPalInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\PayPal.png:23:21|t |cFFFFFFFFPayPal|r") end)
    PayPalInteractive:SetCallback("OnLeave", function() PayPalInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\PayPal.png:23:21|t |cFF8080FFPayPal|r") end)
    SupportMeContainer:AddChild(PayPalInteractive)

    local TwitchInteractive = AG:Create("InteractiveLabel")
    TwitchInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Twitch.png:25:21|t |cFF8080FFTwitch|r")
    TwitchInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    TwitchInteractive:SetJustifyV("MIDDLE")
    TwitchInteractive:SetRelativeWidth(0.33)
    TwitchInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Twitch", "https://www.twitch.tv/unhaltedgb") end)
    TwitchInteractive:SetCallback("OnEnter", function() TwitchInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Twitch.png:25:21|t |cFFFFFFFFTwitch|r") end)
    TwitchInteractive:SetCallback("OnLeave", function() TwitchInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Twitch.png:25:21|t |cFF8080FFTwitch|r") end)
    SupportMeContainer:AddChild(TwitchInteractive)

    local DiscordInteractive = AG:Create("InteractiveLabel")
    DiscordInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Discord.png:21:21|t |cFF8080FFDiscord|r")
    DiscordInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    DiscordInteractive:SetJustifyV("MIDDLE")
    DiscordInteractive:SetRelativeWidth(0.33)
    DiscordInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Discord", "https://discord.gg/UZCgWRYvVE") end)
    DiscordInteractive:SetCallback("OnEnter", function() DiscordInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Discord.png:21:21|t |cFFFFFFFFDiscord|r") end)
    DiscordInteractive:SetCallback("OnLeave", function() DiscordInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Discord.png:21:21|t |cFF8080FFDiscord|r") end)
    SupportMeContainer:AddChild(DiscordInteractive)

    local PatreonInteractive = AG:Create("InteractiveLabel")
    PatreonInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Patreon.png:21:21|t |cFF8080FFPatreon|r")
    PatreonInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    PatreonInteractive:SetJustifyV("MIDDLE")
    PatreonInteractive:SetRelativeWidth(0.33)
    PatreonInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Patreon", "https://www.patreon.com/unhalted") end)
    PatreonInteractive:SetCallback("OnEnter", function() PatreonInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Patreon.png:21:21|t |cFFFFFFFFPatreon|r") end)
    PatreonInteractive:SetCallback("OnLeave", function() PatreonInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Patreon.png:21:21|t |cFF8080FFPatreon|r") end)
    SupportMeContainer:AddChild(PatreonInteractive)

    local GithubInteractive = AG:Create("InteractiveLabel")
    GithubInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Github.png:21:21|t |cFF8080FFGithub|r")
    GithubInteractive:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    GithubInteractive:SetJustifyV("MIDDLE")
    GithubInteractive:SetRelativeWidth(0.33)
    GithubInteractive:SetCallback("OnClick", function() BCDM:OpenURL("Support Me on Github", "https://github.com/dalehuntgb/BetterCooldownManager") end)
    GithubInteractive:SetCallback("OnEnter", function() GithubInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Github.png:21:21|t |cFFFFFFFFGithub|r") end)
    GithubInteractive:SetCallback("OnLeave", function() GithubInteractive:SetText("|TInterface\\AddOns\\BetterCooldownManager\\Media\\Support\\Github.png:21:21|t |cFF8080FFGithub|r") end)
    SupportMeContainer:AddChild(GithubInteractive)

    ScrollFrame:DoLayout()
end

local function CreateGlobalSettings(parentContainer)
    local GeneralDB = BCDM.db.profile.General
    local CooldownManagerDB = BCDM.db.profile.CooldownManager

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local globalSettingsContainer = AG:Create("InlineGroup")
    globalSettingsContainer:SetTitle("Global Settings")
    globalSettingsContainer:SetFullWidth(true)
    globalSettingsContainer:SetLayout("Flow")
    ScrollFrame:AddChild(globalSettingsContainer)

    local enableCDMSkinningCheckbox = AG:Create("CheckBox")
    enableCDMSkinningCheckbox:SetLabel("Enable Skinning - |cFFFF4040Reload|r Required.")
    enableCDMSkinningCheckbox:SetValue(BCDM.db.profile.CooldownManager.Enable)
    enableCDMSkinningCheckbox:SetCallback("OnValueChanged", function(_, _, value)
        StaticPopupDialogs["BCDM_RELOAD_UI"] = {
            text = "You must reload to apply this change, do you want to reload now?",
            button1 = "Reload Now",
            button2 = "Later",
            showAlert = true,
            OnAccept = function() BCDM.db.profile.CooldownManager.Enable = value ReloadUI() end,
            OnCancel = function() enableCDMSkinningCheckbox:SetValue(BCDM.db.profile.CooldownManager.Enable) globalSettingsContainer:DoLayout() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("BCDM_RELOAD_UI")
    end)
    enableCDMSkinningCheckbox:SetRelativeWidth(1)
    globalSettingsContainer:AddChild(enableCDMSkinningCheckbox)

    local iconZoomSlider = AG:Create("Slider")
    iconZoomSlider:SetLabel("Icon Zoom")
    iconZoomSlider:SetValue(CooldownManagerDB.General.IconZoom)
    iconZoomSlider:SetSliderValues(0, 1, 0.01)
    iconZoomSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownManagerDB.General.IconZoom = value BCDM:UpdateCooldownViewers() end)
    iconZoomSlider:SetRelativeWidth(0.5)
    iconZoomSlider:SetIsPercent(true)
    globalSettingsContainer:AddChild(iconZoomSlider)

    local borderSizeSlider = AG:Create("Slider")
    borderSizeSlider:SetLabel("Border Size")
    borderSizeSlider:SetValue(CooldownManagerDB.General.BorderSize)
    borderSizeSlider:SetSliderValues(1, 3, 1)
    borderSizeSlider:SetCallback("OnValueChanged", function(_, _, value) CooldownManagerDB.General.BorderSize = value BCDM:UpdateCooldownViewers() end)
    borderSizeSlider:SetRelativeWidth(0.5)
    globalSettingsContainer:AddChild(borderSizeSlider)

    local FontContainer = AG:Create("InlineGroup")
    FontContainer:SetTitle("Font Settings")
    FontContainer:SetFullWidth(true)
    FontContainer:SetLayout("Flow")
    globalSettingsContainer:AddChild(FontContainer)

    local CooldownManagerFontDropdown = AG:Create("LSM30_Font")
    CooldownManagerFontDropdown:SetLabel("Font")
    CooldownManagerFontDropdown:SetList(LSM:HashTable("font"))
    CooldownManagerFontDropdown:SetValue(GeneralDB.Fonts.Font)
    CooldownManagerFontDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) GeneralDB.Fonts.Font = value BCDM:UpdateBCDM() end)
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
    CooldownManagerFontFlagDropdown:SetValue(GeneralDB.Fonts.FontFlag)
    CooldownManagerFontFlagDropdown:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.Fonts.FontFlag = value BCDM:UpdateBCDM() end)
    CooldownManagerFontFlagDropdown:SetRelativeWidth(0.5)
    FontContainer:AddChild(CooldownManagerFontFlagDropdown)

    local FontShadowsContainer = AG:Create("InlineGroup")
    FontShadowsContainer:SetTitle("Font Shadows")
    FontShadowsContainer:SetFullWidth(true)
    FontShadowsContainer:SetLayout("Flow")
    FontContainer:AddChild(FontShadowsContainer)

    local FontShadowEnabled = AG:Create("CheckBox")
    FontShadowEnabled:SetLabel("Enable")
    FontShadowEnabled:SetValue(GeneralDB.Fonts.Shadow.Enabled)
    FontShadowEnabled:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.Fonts.Shadow.Enabled = value RefreshShadowSettings() BCDM:UpdateBCDM() end)
    FontShadowEnabled:SetRelativeWidth(0.25)
    FontShadowsContainer:AddChild(FontShadowEnabled)

    local FontShadowColour = AG:Create("ColorPicker")
    FontShadowColour:SetLabel("Shadow Colour")
    FontShadowColour:SetColor(unpack(GeneralDB.Fonts.Shadow.Colour))
    FontShadowColour:SetRelativeWidth(0.25)
    FontShadowColour:SetCallback("OnValueChanged", function(_, _, r, g, b) GeneralDB.Fonts.Shadow.Colour = {r, g, b} BCDM:UpdateBCDM() end)
    FontShadowsContainer:AddChild(FontShadowColour)

    local FontShadowOffsetX = AG:Create("Slider")
    FontShadowOffsetX:SetLabel("Shadow Offset X")
    FontShadowOffsetX:SetValue(GeneralDB.Fonts.Shadow.OffsetX)
    FontShadowOffsetX:SetSliderValues(-10, 10, 0.1)
    FontShadowOffsetX:SetRelativeWidth(0.25)
    FontShadowOffsetX:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.Fonts.Shadow.OffsetX = value BCDM:UpdateBCDM() end)
    FontShadowsContainer:AddChild(FontShadowOffsetX)

    local FontShadowOffsetY = AG:Create("Slider")
    FontShadowOffsetY:SetLabel("Shadow Offset Y")
    FontShadowOffsetY:SetValue(GeneralDB.Fonts.Shadow.OffsetY)
    FontShadowOffsetY:SetSliderValues(-10, 10, 0.1)
    FontShadowOffsetY:SetRelativeWidth(0.25)
    FontShadowOffsetY:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.Fonts.Shadow.OffsetY = value BCDM:UpdateBCDM() end)
    FontShadowsContainer:AddChild(FontShadowOffsetY)

    function RefreshShadowSettings()
        local enabled = GeneralDB.Fonts.Shadow.Enabled
        FontShadowColour:SetDisabled(not enabled)
        FontShadowOffsetX:SetDisabled(not enabled)
        FontShadowOffsetY:SetDisabled(not enabled)
    end

    RefreshShadowSettings()

    local TextureContainer = AG:Create("InlineGroup")
    TextureContainer:SetTitle("Texture Settings")
    TextureContainer:SetFullWidth(true)
    TextureContainer:SetLayout("Flow")
    globalSettingsContainer:AddChild(TextureContainer)

    local ForegroundTextureDropdown = AG:Create("LSM30_Statusbar")
    ForegroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    ForegroundTextureDropdown:SetLabel("Foreground Texture")
    ForegroundTextureDropdown:SetValue(BCDM.db.profile.General.Textures.Foreground)
    ForegroundTextureDropdown:SetRelativeWidth(0.5)
    ForegroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) BCDM.db.profile.General.Textures.Foreground = value BCDM:ResolveLSM() BCDM:UpdateBCDM() end)
    TextureContainer:AddChild(ForegroundTextureDropdown)

    local BackgroundTextureDropdown = AG:Create("LSM30_Statusbar")
    BackgroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    BackgroundTextureDropdown:SetLabel("Background Texture")
    BackgroundTextureDropdown:SetValue(BCDM.db.profile.General.Textures.Background)
    BackgroundTextureDropdown:SetRelativeWidth(0.5)
    BackgroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) BCDM.db.profile.General.Textures.Background = value BCDM:ResolveLSM() BCDM:UpdateBCDM() end)
    TextureContainer:AddChild(BackgroundTextureDropdown)

    local CustomGlowContainer = AG:Create("InlineGroup")
    CustomGlowContainer:SetTitle("Custom Glow Settings")
    CustomGlowContainer:SetFullWidth(true)
    CustomGlowContainer:SetLayout("Flow")
    globalSettingsContainer:AddChild(CustomGlowContainer)

    CreateGlowSettings(CustomGlowContainer)

    CreateCooldownTextSettings(globalSettingsContainer)

    ScrollFrame:DoLayout()

    return parentContainer
end

local function CreateEditModeManagerSettings(parentContainer)
    local EditModeManagerDB = BCDM.db.profile.EditModeManager

    local editModeManagerContainer = AG:Create("InlineGroup")
    editModeManagerContainer:SetTitle("Edit Mode Manager Settings")
    editModeManagerContainer:SetFullWidth(true)
    editModeManagerContainer:SetLayout("Flow")
    parentContainer:AddChild(editModeManagerContainer)

    local layoutContainer = AG:Create("InlineGroup")
    layoutContainer:SetTitle("Layouts")
    layoutContainer:SetFullWidth(true)
    layoutContainer:SetLayout("Flow")
    editModeManagerContainer:AddChild(layoutContainer)

    local raidLayoutDropdown = {}
    local specLayoutDropdown = {}
    local layoutOrder = {"LFR", "Normal", "Heroic", "Mythic"}
    local numSpecs = GetNumSpecializations()

    local function RefreshRaidLayoutSettings()
        local isDisabled = not EditModeManagerDB.SwapOnInstanceDifficulty
        for i = 1, #layoutOrder do
            raidLayoutDropdown[i]:SetDisabled(isDisabled)
        end
    end

    local function RefreshSpecializationSettings()
        local isDisabled = not EditModeManagerDB.SwapOnSpecializationChange
        for i = 1, numSpecs do
            specLayoutDropdown[i]:SetDisabled(isDisabled)
        end
    end

    local raidDifficultyContainer = AG:Create("InlineGroup")
    raidDifficultyContainer:SetTitle("Raid Difficulty Settings")
    raidDifficultyContainer:SetFullWidth(true)
    raidDifficultyContainer:SetLayout("Flow")
    layoutContainer:AddChild(raidDifficultyContainer)

    CreateInformationTag(raidDifficultyContainer, "Define |cFF8080FFEdit Mode Layouts|r for Different Raid Difficulties.")

    local swapOnInstanceDifficultyCheckbox = AG:Create("CheckBox")
    swapOnInstanceDifficultyCheckbox:SetLabel("Swap on Instance Difficulty")
    swapOnInstanceDifficultyCheckbox:SetValue(EditModeManagerDB.SwapOnInstanceDifficulty)
    swapOnInstanceDifficultyCheckbox:SetCallback("OnValueChanged", function(_, _, value)
        EditModeManagerDB.SwapOnInstanceDifficulty = value
        RefreshRaidLayoutSettings()
        BCDM:UpdateLayout()
        BCDM:UpdateBCDM()
    end)
    swapOnInstanceDifficultyCheckbox:SetRelativeWidth(1)
    raidDifficultyContainer:AddChild(swapOnInstanceDifficultyCheckbox)

    local AvailableLayouts = BCDM:GetLayouts()

    for i, layoutType in ipairs(layoutOrder) do
        raidLayoutDropdown[i] = AG:Create("Dropdown")
        raidLayoutDropdown[i]:SetLabel(layoutType .. " Layout")
        raidLayoutDropdown[i]:SetList(AvailableLayouts)
        raidLayoutDropdown[i]:SetText(EditModeManagerDB.RaidLayouts[layoutType])
        raidLayoutDropdown[i]:SetRelativeWidth(0.5)
        raidLayoutDropdown[i]:SetCallback("OnEnterPressed", function(self)
            local input = self:GetText()
            EditModeManagerDB.RaidLayouts[layoutType] = input
            BCDM:UpdateLayout()
            BCDM:UpdateBCDM()
        end)
        raidDifficultyContainer:AddChild(raidLayoutDropdown[i])
    end

    local specializationContainer = AG:Create("InlineGroup")
    specializationContainer:SetTitle("Specialization Settings")
    specializationContainer:SetFullWidth(true)
    specializationContainer:SetLayout("Flow")
    layoutContainer:AddChild(specializationContainer)

    CreateInformationTag(specializationContainer, "Define |cFF8080FFEdit Mode Layouts|r for Different Specializations.")

    local swapOnSpecializationChangeCheckbox = AG:Create("CheckBox")
    swapOnSpecializationChangeCheckbox:SetLabel("Swap on Specialization Change")
    swapOnSpecializationChangeCheckbox:SetValue(EditModeManagerDB.SwapOnSpecializationChange)
    swapOnSpecializationChangeCheckbox:SetCallback("OnValueChanged", function(_, _, value)
        EditModeManagerDB.SwapOnSpecializationChange = value
        RefreshSpecializationSettings()
        BCDM:UpdateLayout()
        BCDM:UpdateBCDM()
    end)
    swapOnSpecializationChangeCheckbox:SetRelativeWidth(1)
    specializationContainer:AddChild(swapOnSpecializationChangeCheckbox)

    for i = 1, numSpecs do
        local _, specName = GetSpecializationInfo(i)
        specLayoutDropdown[i] = AG:Create("Dropdown")
        specLayoutDropdown[i]:SetLabel(specName .. " Layout")
        specLayoutDropdown[i]:SetList(AvailableLayouts)
        specLayoutDropdown[i]:SetText(EditModeManagerDB.SpecializationLayouts[i])
        specLayoutDropdown[i]:SetRelativeWidth(numSpecs == 2 and 0.5 or numSpecs == 3 and 0.33 or 0.25)
        specLayoutDropdown[i]:SetCallback("OnEnterPressed", function(self)
            local input = self:GetText()
            EditModeManagerDB.SpecializationLayouts[i] = input
            BCDM:UpdateLayout()
            BCDM:UpdateBCDM()
        end)
        specializationContainer:AddChild(specLayoutDropdown[i])
    end

    RefreshRaidLayoutSettings()
    RefreshSpecializationSettings()
end

local function CreateCooldownViewerTextSettings(parentContainer, viewerType)
    local isViewerBuffBar = viewerType == "BuffBar"
    local textContainer = AG:Create("InlineGroup")
    textContainer:SetTitle("Text Settings")
    textContainer:SetFullWidth(true)
    textContainer:SetLayout("Flow")
    parentContainer:AddChild(textContainer)

    if not isViewerBuffBar then
        local anchorFromDropdown = AG:Create("Dropdown")
        anchorFromDropdown:SetLabel("Anchor From")
        anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        anchorFromDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Layout[1])
        anchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Layout[1] = value BCDM:UpdateCooldownViewer(viewerType) end)
        anchorFromDropdown:SetRelativeWidth(0.5)
        textContainer:AddChild(anchorFromDropdown)

        local anchorToDropdown = AG:Create("Dropdown")
        anchorToDropdown:SetLabel("Anchor To")
        anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        anchorToDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Layout[2])
        anchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Layout[2] = value BCDM:UpdateCooldownViewer(viewerType) end)
        anchorToDropdown:SetRelativeWidth(0.5)
        textContainer:AddChild(anchorToDropdown)

        local xOffsetSlider = AG:Create("Slider")
        xOffsetSlider:SetLabel("X Offset")
        xOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Layout[3])
        xOffsetSlider:SetSliderValues(-500, 500, 0.1)
        xOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Layout[3] = value BCDM:UpdateCooldownViewer(viewerType) end)
        xOffsetSlider:SetRelativeWidth(0.5)
        textContainer:AddChild(xOffsetSlider)

        local yOffsetSlider = AG:Create("Slider")
        yOffsetSlider:SetLabel("Y Offset")
        yOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Layout[4])
        yOffsetSlider:SetSliderValues(-500, 500, 0.1)
        yOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Layout[4] = value BCDM:UpdateCooldownViewer(viewerType) end)
        yOffsetSlider:SetRelativeWidth(0.5)
        textContainer:AddChild(yOffsetSlider)

        local fontSizeSlider = AG:Create("Slider")
        fontSizeSlider:SetLabel("Font Size")
        fontSizeSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.FontSize)
        fontSizeSlider:SetSliderValues(6, 72, 1)
        fontSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.FontSize = value BCDM:UpdateCooldownViewer(viewerType) end)
        fontSizeSlider:SetRelativeWidth(0.5)
        textContainer:AddChild(fontSizeSlider)

        local colourPicker = AG:Create("ColorPicker")
        colourPicker:SetLabel("Font Colour")
        local r, g, b = unpack(BCDM.db.profile.CooldownManager[viewerType].Text.Colour)
        colourPicker:SetColor(r, g, b)
        colourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b) BCDM.db.profile.CooldownManager[viewerType].Text.Colour = {r, g, b} BCDM:UpdateCooldownViewer(viewerType) end)
        colourPicker:SetRelativeWidth(0.5)
        textContainer:AddChild(colourPicker)
    else
        local nameContainer = AG:Create("InlineGroup")
        nameContainer:SetTitle("Name Text Settings")
        nameContainer:SetFullWidth(true)
        nameContainer:SetLayout("Flow")
        textContainer:AddChild(nameContainer)

        local name_toggleCheckbox = AG:Create("CheckBox")
        name_toggleCheckbox:SetLabel("Enable Name Text")
        name_toggleCheckbox:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Enabled)
        name_toggleCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Enabled = value BCDM:UpdateCooldownViewer(viewerType) RefreshBuffBarTextGUISettings() end)
        name_toggleCheckbox:SetRelativeWidth(1)
        nameContainer:AddChild(name_toggleCheckbox)

        local name_AnchorFromDropdown = AG:Create("Dropdown")
        name_AnchorFromDropdown:SetLabel("Anchor From")
        name_AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        name_AnchorFromDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[1])
        name_AnchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[1] = value BCDM:UpdateCooldownViewer(viewerType) end)
        name_AnchorFromDropdown:SetRelativeWidth(0.5)
        nameContainer:AddChild(name_AnchorFromDropdown)

        local name_AnchorToDropdown = AG:Create("Dropdown")
        name_AnchorToDropdown:SetLabel("Anchor To")
        name_AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        name_AnchorToDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[2])
        name_AnchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[2] = value BCDM:UpdateCooldownViewer(viewerType) end)
        name_AnchorToDropdown:SetRelativeWidth(0.5)
        nameContainer:AddChild(name_AnchorToDropdown)

        local name_XOffsetSlider = AG:Create("Slider")
        name_XOffsetSlider:SetLabel("X Offset")
        name_XOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[3])
        name_XOffsetSlider:SetSliderValues(-500, 500, 0.1)
        name_XOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[3] = value BCDM:UpdateCooldownViewer(viewerType) end)
        name_XOffsetSlider:SetRelativeWidth(0.5)
        nameContainer:AddChild(name_XOffsetSlider)

        local name_YOffsetSlider = AG:Create("Slider")
        name_YOffsetSlider:SetLabel("Y Offset")
        name_YOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[4])
        name_YOffsetSlider:SetSliderValues(-500, 500, 0.1)
        name_YOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Layout[4] = value BCDM:UpdateCooldownViewer(viewerType) end)
        name_YOffsetSlider:SetRelativeWidth(0.5)
        nameContainer:AddChild(name_YOffsetSlider)

        local name_FontSizeSlider = AG:Create("Slider")
        name_FontSizeSlider:SetLabel("Font Size")
        name_FontSizeSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.FontSize)
        name_FontSizeSlider:SetSliderValues(6, 72, 1)
        name_FontSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.FontSize = value BCDM:UpdateCooldownViewer(viewerType) end)
        name_FontSizeSlider:SetRelativeWidth(0.5)
        nameContainer:AddChild(name_FontSizeSlider)

        local name_ColourPicker = AG:Create("ColorPicker")
        name_ColourPicker:SetLabel("Font Colour")
        local name_r, name_g, name_b = unpack(BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Colour)
        name_ColourPicker:SetColor(name_r, name_g, name_b)
        name_ColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b) BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Colour = {r, g, b} BCDM:UpdateCooldownViewer(viewerType) end)
        name_ColourPicker:SetRelativeWidth(0.5)
        nameContainer:AddChild(name_ColourPicker)

        local durationContainer = AG:Create("InlineGroup")
        durationContainer:SetTitle("Duration Text Settings")
        durationContainer:SetFullWidth(true)
        durationContainer:SetLayout("Flow")
        textContainer:AddChild(durationContainer)

        local duration_toggleCheckbox = AG:Create("CheckBox")
        duration_toggleCheckbox:SetLabel("Enable Duration Text")
        duration_toggleCheckbox:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Enabled)
        duration_toggleCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Enabled = value BCDM:UpdateCooldownViewer(viewerType) RefreshBuffBarTextGUISettings() end)
        duration_toggleCheckbox:SetRelativeWidth(1)
        durationContainer:AddChild(duration_toggleCheckbox)

        local duration_AnchorFromDropdown = AG:Create("Dropdown")
        duration_AnchorFromDropdown:SetLabel("Anchor From")
        duration_AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        duration_AnchorFromDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[1])
        duration_AnchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[1] = value BCDM:UpdateCooldownViewer(viewerType) end)
        duration_AnchorFromDropdown:SetRelativeWidth(0.5)
        durationContainer:AddChild(duration_AnchorFromDropdown)

        local duration_AnchorToDropdown = AG:Create("Dropdown")
        duration_AnchorToDropdown:SetLabel("Anchor To")
        duration_AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
        duration_AnchorToDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[2])
        duration_AnchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[2] = value BCDM:UpdateCooldownViewer(viewerType) end)
        duration_AnchorToDropdown:SetRelativeWidth(0.5)
        durationContainer:AddChild(duration_AnchorToDropdown)

        local duration_XOffsetSlider = AG:Create("Slider")
        duration_XOffsetSlider:SetLabel("X Offset")
        duration_XOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[3])
        duration_XOffsetSlider:SetSliderValues(-500, 500, 0.1)
        duration_XOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[3] = value BCDM:UpdateCooldownViewer(viewerType) end)
        duration_XOffsetSlider:SetRelativeWidth(0.5)
        durationContainer:AddChild(duration_XOffsetSlider)

        local duration_YOffsetSlider = AG:Create("Slider")
        duration_YOffsetSlider:SetLabel("Y Offset")
        duration_YOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[4])
        duration_YOffsetSlider:SetSliderValues(-500, 500, 0.1)
        duration_YOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Layout[4] = value BCDM:UpdateCooldownViewer(viewerType) end)
        duration_YOffsetSlider:SetRelativeWidth(0.5)
        durationContainer:AddChild(duration_YOffsetSlider)

        local duration_FontSizeSlider = AG:Create("Slider")
        duration_FontSizeSlider:SetLabel("Font Size")
        duration_FontSizeSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Text.Duration.FontSize)
        duration_FontSizeSlider:SetSliderValues(6, 72, 1)
        duration_FontSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Text.Duration.FontSize = value BCDM:UpdateCooldownViewer(viewerType) end)
        duration_FontSizeSlider:SetRelativeWidth(0.5)
        durationContainer:AddChild(duration_FontSizeSlider)

        local duration_ColourPicker = AG:Create("ColorPicker")
        duration_ColourPicker:SetLabel("Font Colour")
        local duration_r, duration_g, duration_b = unpack(BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Colour)
        duration_ColourPicker:SetColor(duration_r, duration_g, duration_b)
        duration_ColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b) BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Colour = {r, g, b} BCDM:UpdateCooldownViewer(viewerType) end)
        duration_ColourPicker:SetRelativeWidth(0.5)
        durationContainer:AddChild(duration_ColourPicker)

        function RefreshBuffBarTextGUISettings()
            local nameEnabled = BCDM.db.profile.CooldownManager[viewerType].Text.SpellName.Enabled
            name_AnchorFromDropdown:SetDisabled(not nameEnabled)
            name_AnchorToDropdown:SetDisabled(not nameEnabled)
            name_XOffsetSlider:SetDisabled(not nameEnabled)
            name_YOffsetSlider:SetDisabled(not nameEnabled)
            name_FontSizeSlider:SetDisabled(not nameEnabled)
            name_ColourPicker:SetDisabled(not nameEnabled)

            local durationEnabled = BCDM.db.profile.CooldownManager[viewerType].Text.Duration.Enabled
            duration_AnchorFromDropdown:SetDisabled(not durationEnabled)
            duration_AnchorToDropdown:SetDisabled(not durationEnabled)
            duration_XOffsetSlider:SetDisabled(not durationEnabled)
            duration_YOffsetSlider:SetDisabled(not durationEnabled)
            duration_FontSizeSlider:SetDisabled(not durationEnabled)
            duration_ColourPicker:SetDisabled(not durationEnabled)
        end
        RefreshBuffBarTextGUISettings()
    end

    return textContainer
end

local function CreateCooldownViewerSpellSettings(parentContainer, containerToRefresh)
    local SpellDB = BCDM.db.profile.CooldownManager.Custom.Spells

    local playerClass = select(2, UnitClass("player"))
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()

    local addSpellEditBox = AG:Create("EditBox")
    addSpellEditBox:SetLabel("Add Spell by ID or Spell Name")
    addSpellEditBox:SetRelativeWidth(0.5)
    addSpellEditBox:SetCallback("OnEnterPressed", function(self)
        local input = self:GetText()
        local spellId = FetchSpellID(input)
        if spellId then
            BCDM:AdjustSpellList(spellId, "add")
            BCDM:UpdateCooldownViewer("Custom")
            parentContainer:ReleaseChildren()
            CreateCooldownViewerSpellSettings(parentContainer, containerToRefresh)
            self:SetText("")
        end
    end)
    parentContainer:AddChild(addSpellEditBox)

    local addRecommendedButton = AG:Create("Button")
    addRecommendedButton:SetText("Add Recommended Spells")
    addRecommendedButton:SetRelativeWidth(0.5)
    addRecommendedButton:SetCallback("OnClick", function()
        BCDM:AddRecommendedSpells()
        BCDM:UpdateCooldownViewer("Custom")
        parentContainer:ReleaseChildren()
        CreateCooldownViewerSpellSettings(parentContainer, containerToRefresh)
    end)
    parentContainer:AddChild(addRecommendedButton)

    if SpellDB[playerClass] and SpellDB[playerClass][playerSpecialization] then

        local sortedSpells = {}

        for spellId, data in pairs(SpellDB[playerClass][playerSpecialization]) do table.insert(sortedSpells, {id = spellId, data = data}) end
        table.sort(sortedSpells, function(a, b) return a.data.layoutIndex < b.data.layoutIndex end)

        for _, spell in ipairs(sortedSpells) do
            local spellId = spell.id
            local data = spell.data

            local spellCheckbox = AG:Create("CheckBox")
            spellCheckbox:SetLabel("[" .. data.layoutIndex .. "] " .. FetchSpellInformation(spellId))
            spellCheckbox:SetValue(data.isActive)
            spellCheckbox:SetCallback("OnValueChanged", function(_, _, value) SpellDB[playerClass][playerSpecialization][spellId].isActive = value BCDM:UpdateCooldownViewer("Custom") end)
            spellCheckbox:SetRelativeWidth(0.6)
            parentContainer:AddChild(spellCheckbox)

            local moveUpButton = AG:Create("Button")
            moveUpButton:SetText("Up")
            moveUpButton:SetRelativeWidth(0.1333)
            moveUpButton:SetCallback("OnClick", function() BCDM:AdjustSpellLayoutIndex(-1, spellId) parentContainer:ReleaseChildren() CreateCooldownViewerSpellSettings(parentContainer, containerToRefresh) end)
            parentContainer:AddChild(moveUpButton)

            local moveDownButton = AG:Create("Button")
            moveDownButton:SetText("Down")
            moveDownButton:SetRelativeWidth(0.1333)
            moveDownButton:SetCallback("OnClick", function() BCDM:AdjustSpellLayoutIndex(1, spellId) parentContainer:ReleaseChildren() CreateCooldownViewerSpellSettings(parentContainer, containerToRefresh) end)
            parentContainer:AddChild(moveDownButton)

            local removeSpellButton = AG:Create("Button")
            removeSpellButton:SetText("X")
            removeSpellButton:SetRelativeWidth(0.1333)
            removeSpellButton:SetCallback("OnClick", function()
                BCDM:AdjustSpellList(spellId, "remove")
                BCDM:UpdateCooldownViewer("Custom")
                parentContainer:ReleaseChildren()
                CreateCooldownViewerSpellSettings(parentContainer, containerToRefresh)
            end)
            parentContainer:AddChild(removeSpellButton)
        end
    end

    containerToRefresh:DoLayout()

    return parentContainer
end

local function CreateCooldownViewerItemSettings(parentContainer, containerToRefresh)
    local ItemDB = BCDM.db.profile.CooldownManager.Item.Items

    local addItemEditBox = AG:Create("EditBox")
    addItemEditBox:SetLabel("Add Item by ID or Item Name")
    addItemEditBox:SetRelativeWidth(0.5)
    addItemEditBox:SetCallback("OnEnterPressed", function(self)
        local input = self:GetText()
        local itemId = tonumber(input)
        if itemId then
            BCDM:AdjustItemList(itemId, "add")
            BCDM:UpdateCooldownViewer("Item")
            parentContainer:ReleaseChildren()
            CreateCooldownViewerItemSettings(parentContainer, containerToRefresh)
            self:SetText("")
        end
    end)
    parentContainer:AddChild(addItemEditBox)

    local addRecommendedButton = AG:Create("Button")
    addRecommendedButton:SetText("Add Recommended Items")
    addRecommendedButton:SetRelativeWidth(0.5)
    addRecommendedButton:SetCallback("OnClick", function()
        BCDM:AddRecommendedItems()
        BCDM:UpdateCooldownViewer("Item")
        parentContainer:ReleaseChildren()
        CreateCooldownViewerItemSettings(parentContainer, containerToRefresh)
    end)
    parentContainer:AddChild(addRecommendedButton)

    if ItemDB then

        local sortedItems = {}

        for spellId, data in pairs(ItemDB) do table.insert(sortedItems, {id = spellId, data = data}) end
        table.sort(sortedItems, function(a, b) return a.data.layoutIndex < b.data.layoutIndex end)

        for _, item in ipairs(sortedItems) do
            local itemId = item.id
            local data = item.data

            local itemCheckbox = AG:Create("CheckBox")
            itemCheckbox:SetLabel("[" .. data.layoutIndex .. "] " .. FetchItemInformation(itemId))
            itemCheckbox:SetValue(data.isActive)
            itemCheckbox:SetCallback("OnValueChanged", function(_, _, value) ItemDB[itemId].isActive = value BCDM:UpdateCooldownViewer("Item") end)
            itemCheckbox:SetRelativeWidth(0.6)
            parentContainer:AddChild(itemCheckbox)

            local moveUpButton = AG:Create("Button")
            moveUpButton:SetText("Up")
            moveUpButton:SetRelativeWidth(0.1333)
            moveUpButton:SetCallback("OnClick", function() BCDM:AdjustItemLayoutIndex(-1, itemId) parentContainer:ReleaseChildren() CreateCooldownViewerItemSettings(parentContainer, containerToRefresh) end)
            parentContainer:AddChild(moveUpButton)

            local moveDownButton = AG:Create("Button")
            moveDownButton:SetText("Down")
            moveDownButton:SetRelativeWidth(0.1333)
            moveDownButton:SetCallback("OnClick", function() BCDM:AdjustItemLayoutIndex(1, itemId) parentContainer:ReleaseChildren() CreateCooldownViewerItemSettings(parentContainer, containerToRefresh) end)
            parentContainer:AddChild(moveDownButton)

            local removeItemButton = AG:Create("Button")
            removeItemButton:SetText("X")
            removeItemButton:SetRelativeWidth(0.1333)
            removeItemButton:SetCallback("OnClick", function()
                BCDM:AdjustItemList(itemId, "remove")
                BCDM:UpdateCooldownViewer("Item")
                parentContainer:ReleaseChildren()
                CreateCooldownViewerItemSettings(parentContainer, containerToRefresh)
            end)
            parentContainer:AddChild(removeItemButton)
        end
    end

    containerToRefresh:DoLayout()

    return parentContainer
end

local function CreateCooldownViewerSettings(parentContainer, viewerType)
    local hasAnchorParent = viewerType == "Utility" or viewerType == "Buffs" or viewerType == "BuffBar" or viewerType == "Custom" or viewerType == "Item"
    local isViewerBuffBar = viewerType == "BuffBar"
    local isCustomViewer = viewerType == "Custom" or viewerType == "Item"

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    if viewerType == "Buffs" then
        local toggleContainer = AG:Create("InlineGroup")
        toggleContainer:SetTitle("Buff Viewer Settings")
        toggleContainer:SetFullWidth(true)
        toggleContainer:SetLayout("Flow")
        ScrollFrame:AddChild(toggleContainer)

        local centerBuffsCheckbox = AG:Create("CheckBox")
        centerBuffsCheckbox:SetLabel("Center Buffs (Horizontally) - |cFFFF4040Reload|r Required.")
        centerBuffsCheckbox:SetValue(BCDM.db.profile.CooldownManager.Buffs.CenterBuffs)
        centerBuffsCheckbox:SetCallback("OnValueChanged", function(_, _, value)
            StaticPopupDialogs["BCDM_RELOAD_UI"] = {
                text = "You must reload to apply this change, do you want to reload now?",
                button1 = "Reload Now",
                button2 = "Later",
                showAlert = true,
                OnAccept = function() BCDM.db.profile.CooldownManager.Buffs.CenterBuffs = value ReloadUI() end,
                OnCancel = function() centerBuffsCheckbox:SetValue(BCDM.db.profile.CooldownManager.Buffs.CenterBuffs) toggleContainer:DoLayout() end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("BCDM_RELOAD_UI")
        end)
        centerBuffsCheckbox:SetRelativeWidth(1)
        toggleContainer:AddChild(centerBuffsCheckbox)
    end

    local foregroundColourPicker;

    if viewerType == "BuffBar" then
        local toggleContainer = AG:Create("InlineGroup")
        toggleContainer:SetTitle("Buff Bar Viewer Settings")
        toggleContainer:SetFullWidth(true)
        toggleContainer:SetLayout("Flow")
        ScrollFrame:AddChild(toggleContainer)

        local matchWidthOfAnchorCheckBox = AG:Create("CheckBox")
        matchWidthOfAnchorCheckBox:SetLabel("Match Width of Anchor")
        matchWidthOfAnchorCheckBox:SetValue(BCDM.db.profile.CooldownManager.BuffBar.MatchWidthOfAnchor)
        matchWidthOfAnchorCheckBox:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.BuffBar.MatchWidthOfAnchor = value BCDM:UpdateCooldownViewer("BuffBar") RefreshBuffBarGUISettings() end)
        matchWidthOfAnchorCheckBox:SetRelativeWidth(0.5)
        toggleContainer:AddChild(matchWidthOfAnchorCheckBox)

        local colourByClassCheckbox = AG:Create("CheckBox")
        colourByClassCheckbox:SetLabel("Colour Bar by Class")
        colourByClassCheckbox:SetValue(BCDM.db.profile.CooldownManager.BuffBar.ColourByClass)
        colourByClassCheckbox:SetCallback("OnValueChanged", function(_, _, value) BCDM.db.profile.CooldownManager.BuffBar.ColourByClass = value BCDM:UpdateCooldownViewer("BuffBar") RefreshBuffBarGUISettings() end)
        colourByClassCheckbox:SetRelativeWidth(0.5)
        toggleContainer:AddChild(colourByClassCheckbox)

        foregroundColourPicker = AG:Create("ColorPicker")
        foregroundColourPicker:SetLabel("Foreground Colour")
        local r, g, b = unpack(BCDM.db.profile.CooldownManager.BuffBar.ForegroundColour)
        foregroundColourPicker:SetColor(r, g, b)
        foregroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.CooldownManager.BuffBar.ForegroundColour = {r, g, b, a} BCDM:UpdateCooldownViewer("BuffBar") end)
        foregroundColourPicker:SetRelativeWidth(0.5)
        foregroundColourPicker:SetHasAlpha(false)
        toggleContainer:AddChild(foregroundColourPicker)

        local backgroundColourPicker = AG:Create("ColorPicker")
        backgroundColourPicker:SetLabel("Background Colour")
        local br, bg, bb = unpack(BCDM.db.profile.CooldownManager.BuffBar.BackgroundColour)
        backgroundColourPicker:SetColor(br, bg, bb)
        backgroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.CooldownManager.BuffBar.BackgroundColour = {r, g, b, a} BCDM:UpdateCooldownViewer("BuffBar") end)
        backgroundColourPicker:SetRelativeWidth(0.5)
        backgroundColourPicker:SetHasAlpha(true)
        toggleContainer:AddChild(backgroundColourPicker)
    end

    local layoutContainer = AG:Create("InlineGroup")
    layoutContainer:SetTitle("Layout & Positioning")
    layoutContainer:SetFullWidth(true)
    layoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(layoutContainer)

    if viewerType ~= "Custom" then CreateInformationTag(layoutContainer, "|cFFFFCC00Padding|r is handled by |cFF00B0F7Blizzard|r, not |cFF8080FFBetter|rCooldownManager.") end

    local anchorFromDropdown = AG:Create("Dropdown")
    anchorFromDropdown:SetLabel("Anchor From")
    anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorFromDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Layout[1])
    anchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Layout[1] = value BCDM:UpdateCooldownViewer(viewerType) end)
    anchorFromDropdown:SetRelativeWidth(hasAnchorParent and 0.33 or 0.5)
    layoutContainer:AddChild(anchorFromDropdown)

    if hasAnchorParent then
        AddAnchors("MidnightSimpleUnitFrames", {"Utility", "Custom"}, { ["MSUF_player"] = "|cFFFFD700Midnight|rSimpleUnitFrames: Player Frame", ["MSUF_target"] = "|cFFFFD700Midnight|rSimpleUnitFrames: Target Frame", })
        local anchorToParentDropdown = AG:Create("Dropdown")
        anchorToParentDropdown:SetLabel("Anchor To Parent")
        anchorToParentDropdown:SetList(AnchorParents[viewerType][1], AnchorParents[viewerType][2])
        anchorToParentDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Layout[2])
        anchorToParentDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Layout[2] = value BCDM:UpdateCooldownViewer(viewerType) end)
        anchorToParentDropdown:SetRelativeWidth(0.33)
        layoutContainer:AddChild(anchorToParentDropdown)
    end

    local anchorToDropdown = AG:Create("Dropdown")
    anchorToDropdown:SetLabel("Anchor To")
    anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorToDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].Layout[hasAnchorParent and 3 or 2])
    anchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Layout[hasAnchorParent and 3 or 2] = value BCDM:UpdateCooldownViewer(viewerType) end)
    anchorToDropdown:SetRelativeWidth(hasAnchorParent and 0.33 or 0.5)
    layoutContainer:AddChild(anchorToDropdown)

    if isCustomViewer then
        local growthDirectionDropdown = AG:Create("Dropdown")
        growthDirectionDropdown:SetLabel("Growth Direction")
        growthDirectionDropdown:SetList({["LEFT"] = "Left", ["RIGHT"] = "Right", ["UP"] = "Up", ["DOWN"] = "Down"}, {"UP", "DOWN", "LEFT", "RIGHT"})
        growthDirectionDropdown:SetValue(BCDM.db.profile.CooldownManager[viewerType].GrowthDirection)
        growthDirectionDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].GrowthDirection = value BCDM:UpdateCooldownViewer(viewerType) end)
        growthDirectionDropdown:SetRelativeWidth(0.5)
        layoutContainer:AddChild(growthDirectionDropdown)

        local spacingSlider = AG:Create("Slider")
        spacingSlider:SetLabel("Icon Spacing")
        spacingSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Spacing)
        spacingSlider:SetSliderValues(-1, 32, 1)
        spacingSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Spacing = value BCDM:UpdateCooldownViewer(viewerType) end)
        spacingSlider:SetRelativeWidth(0.5)
        layoutContainer:AddChild(spacingSlider)
    end

    local xOffsetSlider = AG:Create("Slider")
    xOffsetSlider:SetLabel("X Offset")
    xOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Layout[hasAnchorParent and 4 or 3])
    xOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    xOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Layout[hasAnchorParent and 4 or 3] = value BCDM:UpdateCooldownViewer(viewerType) end)
    xOffsetSlider:SetRelativeWidth(isViewerBuffBar and 0.5 or 0.33)
    layoutContainer:AddChild(xOffsetSlider)

    local yOffsetSlider = AG:Create("Slider")
    yOffsetSlider:SetLabel("Y Offset")
    yOffsetSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].Layout[hasAnchorParent and 5 or 4])
    yOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    yOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].Layout[hasAnchorParent and 5 or 4] = value BCDM:UpdateCooldownViewer(viewerType) end)
    yOffsetSlider:SetRelativeWidth(isViewerBuffBar and 0.5 or 0.33)
    layoutContainer:AddChild(yOffsetSlider)

    local widthSlider;

    if isViewerBuffBar then
        widthSlider = AG:Create("Slider")
        widthSlider:SetLabel("Width")
        widthSlider:SetValue(BCDM.db.profile.CooldownManager.BuffBar.Width)
        widthSlider:SetSliderValues(50, 1000, 1)
        widthSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager.BuffBar.Width = value BCDM:UpdateCooldownViewer(viewerType) end)
        widthSlider:SetRelativeWidth(0.5)
        layoutContainer:AddChild(widthSlider)

        local heightSlider = AG:Create("Slider")
        heightSlider:SetLabel("Height")
        heightSlider:SetValue(BCDM.db.profile.CooldownManager.BuffBar.Height)
        heightSlider:SetSliderValues(5, 500, 1)
        heightSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager.BuffBar.Height = value BCDM:UpdateCooldownViewer(viewerType) end)
        heightSlider:SetRelativeWidth(0.5)
        layoutContainer:AddChild(heightSlider)
    end

    if not isViewerBuffBar then
        local iconSizeSlider = AG:Create("Slider")
        iconSizeSlider:SetLabel("Icon Size")
        iconSizeSlider:SetValue(BCDM.db.profile.CooldownManager[viewerType].IconSize)
        iconSizeSlider:SetSliderValues(16, 128, 1)
        iconSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager[viewerType].IconSize = value BCDM:UpdateCooldownViewer(viewerType) end)
        iconSizeSlider:SetRelativeWidth(0.33)
        layoutContainer:AddChild(iconSizeSlider)
    end

    local iconPositionDropdown;

    if isViewerBuffBar then
        local iconContainer = AG:Create("InlineGroup")
        iconContainer:SetTitle("Icon Settings")
        iconContainer:SetFullWidth(true)
        iconContainer:SetLayout("Flow")
        ScrollFrame:AddChild(iconContainer)

        local enableIconCheckBox = AG:Create("CheckBox")
        enableIconCheckBox:SetLabel("Enable Icon")
        enableIconCheckBox:SetValue(BCDM.db.profile.CooldownManager.BuffBar.Icon.Enabled)
        enableIconCheckBox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager.BuffBar.Icon.Enabled = value BCDM:UpdateCooldownViewer(viewerType) RefreshBuffBarGUISettings() end)
        enableIconCheckBox:SetRelativeWidth(0.5)
        iconContainer:AddChild(enableIconCheckBox)

        iconPositionDropdown = AG:Create("Dropdown")
        iconPositionDropdown:SetLabel("Icon Position")
        iconPositionDropdown:SetList({["LEFT"] = "Left", ["RIGHT"] = "Right"}, {"LEFT", "RIGHT"})
        iconPositionDropdown:SetValue(BCDM.db.profile.CooldownManager.BuffBar.Icon.Layout)
        iconPositionDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CooldownManager.BuffBar.Icon.Layout = value BCDM:UpdateCooldownViewer(viewerType) end)
        iconPositionDropdown:SetRelativeWidth(0.5)
        iconContainer:AddChild(iconPositionDropdown)
    end

    CreateCooldownViewerTextSettings(ScrollFrame, viewerType)

    if viewerType == "Custom" then
        local spellContainer = AG:Create("InlineGroup")
        spellContainer:SetTitle("Custom Spells")
        spellContainer:SetFullWidth(true)
        spellContainer:SetLayout("Flow")
        ScrollFrame:AddChild(spellContainer)
        CreateCooldownViewerSpellSettings(spellContainer, ScrollFrame)
    end

    if viewerType == "Item" then
        local itemContainer = AG:Create("InlineGroup")
        itemContainer:SetTitle("Custom Items")
        itemContainer:SetFullWidth(true)
        itemContainer:SetLayout("Flow")
        ScrollFrame:AddChild(itemContainer)
        CreateCooldownViewerItemSettings(itemContainer, ScrollFrame)
    end

    function RefreshBuffBarGUISettings()
        local matchWidth = BCDM.db.profile.CooldownManager.BuffBar.MatchWidthOfAnchor
        local useClassColour = BCDM.db.profile.CooldownManager.BuffBar.ColourByClass
        local iconEnabled = BCDM.db.profile.CooldownManager.BuffBar.Icon.Enabled
        foregroundColourPicker:SetDisabled(useClassColour)
        widthSlider:SetDisabled(matchWidth)
        iconPositionDropdown:SetDisabled(not iconEnabled)
    end

    if viewerType == "BuffBar" then RefreshBuffBarGUISettings() end

    ScrollFrame:DoLayout()

    return ScrollFrame
end

local function CreatePowerBarTextSettings(parentContainer)
    local textContainer = AG:Create("InlineGroup")
    textContainer:SetTitle("Text Settings")
    textContainer:SetFullWidth(true)
    textContainer:SetLayout("Flow")
    parentContainer:AddChild(textContainer)

    local toggleCheckbox = AG:Create("CheckBox")
    toggleCheckbox:SetLabel("Enable Power Text")
    toggleCheckbox:SetValue(BCDM.db.profile.PowerBar.Text.Enabled)
    toggleCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Text.Enabled = value BCDM:UpdatePowerBar() RefreshPowerBarTextGUISettings() end)
    toggleCheckbox:SetRelativeWidth(1)
    textContainer:AddChild(toggleCheckbox)

    local anchorFromDropdown = AG:Create("Dropdown")
    anchorFromDropdown:SetLabel("Anchor From")
    anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorFromDropdown:SetValue(BCDM.db.profile.PowerBar.Text.Layout[1])
    anchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Text.Layout[1] = value BCDM:UpdatePowerBar() end)
    anchorFromDropdown:SetRelativeWidth(0.5)
    textContainer:AddChild(anchorFromDropdown)

    local anchorToDropdown = AG:Create("Dropdown")
    anchorToDropdown:SetLabel("Anchor To")
    anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorToDropdown:SetValue(BCDM.db.profile.PowerBar.Text.Layout[2])
    anchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Text.Layout[2] = value BCDM:UpdatePowerBar() end)
    anchorToDropdown:SetRelativeWidth(0.5)
    textContainer:AddChild(anchorToDropdown)

    local xOffsetSlider = AG:Create("Slider")
    xOffsetSlider:SetLabel("X Offset")
    xOffsetSlider:SetValue(BCDM.db.profile.PowerBar.Text.Layout[3])
    xOffsetSlider:SetSliderValues(-500, 500, 0.1)
    xOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Text.Layout[3] = value BCDM:UpdatePowerBar() end)
    xOffsetSlider:SetRelativeWidth(0.33)
    textContainer:AddChild(xOffsetSlider)

    local yOffsetSlider = AG:Create("Slider")
    yOffsetSlider:SetLabel("Y Offset")
    yOffsetSlider:SetValue(BCDM.db.profile.PowerBar.Text.Layout[4])
    yOffsetSlider:SetSliderValues(-500, 500, 0.1)
    yOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Text.Layout[4] = value BCDM:UpdatePowerBar() end)
    yOffsetSlider:SetRelativeWidth(0.33)
    textContainer:AddChild(yOffsetSlider)

    local fontSizeSlider = AG:Create("Slider")
    fontSizeSlider:SetLabel("Font Size")
    fontSizeSlider:SetValue(BCDM.db.profile.PowerBar.Text.FontSize)
    fontSizeSlider:SetSliderValues(6, 72, 1)
    fontSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Text.FontSize = value BCDM:UpdatePowerBar() end)
    fontSizeSlider:SetRelativeWidth(0.33)
    textContainer:AddChild(fontSizeSlider)

    function RefreshPowerBarTextGUISettings()
        local enabled = BCDM.db.profile.PowerBar.Text.Enabled
        anchorFromDropdown:SetDisabled(not enabled)
        anchorToDropdown:SetDisabled(not enabled)
        xOffsetSlider:SetDisabled(not enabled)
        yOffsetSlider:SetDisabled(not enabled)
        fontSizeSlider:SetDisabled(not enabled)
    end

    RefreshPowerBarTextGUISettings()

    return textContainer
end

local function CreatePowerBarSettings(parentContainer)
    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local toggleContainer = AG:Create("InlineGroup")
    toggleContainer:SetTitle("Toggles & Colours")
    toggleContainer:SetFullWidth(true)
    toggleContainer:SetLayout("Flow")
    ScrollFrame:AddChild(toggleContainer)

    local enabledCheckbox = AG:Create("CheckBox")
    enabledCheckbox:SetLabel("Enable Power Bar")
    enabledCheckbox:SetValue(BCDM.db.profile.PowerBar.Enabled)
    enabledCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Enabled = value BCDM:UpdatePowerBar() RefreshPowerBarGUISettings() end)
    enabledCheckbox:SetRelativeWidth(1)
    toggleContainer:AddChild(enabledCheckbox)

    local colourByTypeCheckbox = AG:Create("CheckBox")
    colourByTypeCheckbox:SetLabel("Colour By Power Type")
    colourByTypeCheckbox:SetValue(BCDM.db.profile.PowerBar.ColourByType)
    colourByTypeCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.ColourByType = value BCDM:UpdatePowerBar() RefreshPowerBarGUISettings() end)
    colourByTypeCheckbox:SetRelativeWidth(0.25)
    toggleContainer:AddChild(colourByTypeCheckbox)

    local colourByClassCheckbox = AG:Create("CheckBox")
    colourByClassCheckbox:SetLabel("Colour By Class")
    colourByClassCheckbox:SetValue(BCDM.db.profile.PowerBar.ColourByClass)
    colourByClassCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.ColourByClass = value BCDM:UpdatePowerBar() RefreshPowerBarGUISettings() end)
    colourByClassCheckbox:SetRelativeWidth(0.25)
    toggleContainer:AddChild(colourByClassCheckbox)

    local matchAnchorWidthCheckbox = AG:Create("CheckBox")
    matchAnchorWidthCheckbox:SetLabel("Match Width Of Anchor")
    matchAnchorWidthCheckbox:SetValue(BCDM.db.profile.PowerBar.MatchWidthOfAnchor)
    matchAnchorWidthCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.MatchWidthOfAnchor = value BCDM:UpdatePowerBar() RefreshPowerBarGUISettings() end)
    matchAnchorWidthCheckbox:SetRelativeWidth(0.25)
    toggleContainer:AddChild(matchAnchorWidthCheckbox)

    local frequentUpdatesCheckbox = AG:Create("CheckBox")
    frequentUpdatesCheckbox:SetLabel("Frequent Updates")
    frequentUpdatesCheckbox:SetValue(BCDM.db.profile.PowerBar.FrequentUpdates)
    frequentUpdatesCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.FrequentUpdates = value BCDM:UpdatePowerBar() end)
    frequentUpdatesCheckbox:SetRelativeWidth(0.25)
    toggleContainer:AddChild(frequentUpdatesCheckbox)

    local foregroundColourPicker = AG:Create("ColorPicker")
    foregroundColourPicker:SetLabel("Foreground Colour")
    foregroundColourPicker:SetColor(BCDM.db.profile.PowerBar.ForegroundColour[1], BCDM.db.profile.PowerBar.ForegroundColour[2], BCDM.db.profile.PowerBar.ForegroundColour[3], BCDM.db.profile.PowerBar.ForegroundColour[4])
    foregroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.PowerBar.ForegroundColour = {r, g, b, a} BCDM:UpdatePowerBar() end)
    foregroundColourPicker:SetRelativeWidth(0.5)
    foregroundColourPicker:SetHasAlpha(true)
    toggleContainer:AddChild(foregroundColourPicker)

    local backgroundColourPicker = AG:Create("ColorPicker")
    backgroundColourPicker:SetLabel("Background Colour")
    backgroundColourPicker:SetColor(BCDM.db.profile.PowerBar.BackgroundColour[1], BCDM.db.profile.PowerBar.BackgroundColour[2], BCDM.db.profile.PowerBar.BackgroundColour[3], BCDM.db.profile.PowerBar.BackgroundColour[4])
    backgroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.PowerBar.BackgroundColour = {r, g, b, a} BCDM:UpdatePowerBar() end)
    backgroundColourPicker:SetRelativeWidth(0.5)
    backgroundColourPicker:SetHasAlpha(true)
    toggleContainer:AddChild(backgroundColourPicker)

    local layoutContainer = AG:Create("InlineGroup")
    layoutContainer:SetTitle("Layout & Positioning")
    layoutContainer:SetFullWidth(true)
    layoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(layoutContainer)

    local anchorFromDropdown = AG:Create("Dropdown")
    anchorFromDropdown:SetLabel("Anchor From")
    anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorFromDropdown:SetValue(BCDM.db.profile.PowerBar.Layout[1])
    anchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Layout[1] = value BCDM:UpdatePowerBar() end)
    anchorFromDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorFromDropdown)

    local anchorParentDropdown = AG:Create("Dropdown")
    anchorParentDropdown:SetLabel("Anchor Parent")
    anchorParentDropdown:SetList(AnchorParents["Power"][1], AnchorParents["Power"][2])
    anchorParentDropdown:SetValue(BCDM.db.profile.PowerBar.Layout[2])
    anchorParentDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Layout[2] = value BCDM:UpdatePowerBar() end)
    anchorParentDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorParentDropdown)

    local anchorToDropdown = AG:Create("Dropdown")
    anchorToDropdown:SetLabel("Anchor To")
    anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorToDropdown:SetValue(BCDM.db.profile.PowerBar.Layout[3])
    anchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Layout[3] = value BCDM:UpdatePowerBar() end)
    anchorToDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorToDropdown)

    local widthSlider = AG:Create("Slider")
    widthSlider:SetLabel("Width")
    widthSlider:SetValue(BCDM.db.profile.PowerBar.Width)
    widthSlider:SetSliderValues(50, 1000, 1)
    widthSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Width = value BCDM:UpdatePowerBar() end)
    widthSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(widthSlider)

    local heightSlider = AG:Create("Slider")
    heightSlider:SetLabel("Height")
    heightSlider:SetValue(BCDM.db.profile.PowerBar.Height)
    heightSlider:SetSliderValues(5, 500, 1)
    heightSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Height = value BCDM:UpdatePowerBar() end)
    heightSlider:SetRelativeWidth(0.25)
    layoutContainer:AddChild(heightSlider)

    local heightSliderWithoutSecondary = AG:Create("Slider")
    heightSliderWithoutSecondary:SetLabel("Height (No Secondary Power)")
    heightSliderWithoutSecondary:SetValue(BCDM.db.profile.PowerBar.HeightWithoutSecondary)
    heightSliderWithoutSecondary:SetSliderValues(5, 500, 1)
    heightSliderWithoutSecondary:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.HeightWithoutSecondary = value BCDM:UpdatePowerBar() end)
    heightSliderWithoutSecondary:SetRelativeWidth(0.25)
    heightSliderWithoutSecondary:SetDisabled(DetectSecondaryPower())
    layoutContainer:AddChild(heightSliderWithoutSecondary)

    local xOffsetSlider = AG:Create("Slider")
    xOffsetSlider:SetLabel("X Offset")
    xOffsetSlider:SetValue(BCDM.db.profile.PowerBar.Layout[4])
    xOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    xOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Layout[4] = value BCDM:UpdatePowerBar() end)
    xOffsetSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(xOffsetSlider)

    local yOffsetSlider = AG:Create("Slider")
    yOffsetSlider:SetLabel("Y Offset")
    yOffsetSlider:SetValue(BCDM.db.profile.PowerBar.Layout[5])
    yOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    yOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.PowerBar.Layout[5] = value BCDM:UpdatePowerBar() end)
    yOffsetSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(yOffsetSlider)

    local textContainer = CreatePowerBarTextSettings(ScrollFrame)

    function RefreshPowerBarGUISettings()
        if not BCDM.db.profile.PowerBar.Enabled then
            for _, child in ipairs(toggleContainer.children) do
                if child ~= enabledCheckbox then
                    child:SetDisabled(true)
                end
            end
            for _, child in ipairs(layoutContainer.children) do
                child:SetDisabled(true)
            end
            for _, child in ipairs(textContainer.children) do
                child:SetDisabled(true)
            end
        else
            for _, child in ipairs(toggleContainer.children) do
                child:SetDisabled(false)
            end
            for _, child in ipairs(layoutContainer.children) do
                child:SetDisabled(false)
            end
            for _, child in ipairs(textContainer.children) do
                child:SetDisabled(false)
            end
            if BCDM.db.profile.PowerBar.ColourByType or BCDM.db.profile.PowerBar.ColourByClass then
                foregroundColourPicker:SetDisabled(true)
            else
                foregroundColourPicker:SetDisabled(false)
            end
            if BCDM.db.profile.PowerBar.MatchWidthOfAnchor then
                widthSlider:SetDisabled(true)
            else
                widthSlider:SetDisabled(false)
            end
        end
    end

    RefreshPowerBarGUISettings()

    return ScrollFrame
end

local function CreateSecondaryPowerBarTextSettings(parentContainer)
    local textContainer = AG:Create("InlineGroup")
    textContainer:SetTitle("Text Settings")
    textContainer:SetFullWidth(true)
    textContainer:SetLayout("Flow")
    parentContainer:AddChild(textContainer)

    local enabledCheckbox = AG:Create("CheckBox")
    enabledCheckbox:SetLabel("Enable Text")
    enabledCheckbox:SetValue(BCDM.db.profile.SecondaryPowerBar.Text.Enabled)
    enabledCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Text.Enabled = value BCDM:UpdateSecondaryPowerBar() RefreshSecondaryPowerBarTextGUISettings() end)
    enabledCheckbox:SetRelativeWidth(1)
    textContainer:AddChild(enabledCheckbox)

    local anchorFromDropdown = AG:Create("Dropdown")
    anchorFromDropdown:SetLabel("Anchor From")
    anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorFromDropdown:SetValue(BCDM.db.profile.SecondaryPowerBar.Text.Layout[1])
    anchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Text.Layout[1] = value BCDM:UpdateSecondaryPowerBar() end)
    anchorFromDropdown:SetRelativeWidth(0.5)
    textContainer:AddChild(anchorFromDropdown)

    local anchorToDropdown = AG:Create("Dropdown")
    anchorToDropdown:SetLabel("Anchor To")
    anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorToDropdown:SetValue(BCDM.db.profile.SecondaryPowerBar.Text.Layout[2])
    anchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Text.Layout[2] = value BCDM:UpdateSecondaryPowerBar() end)
    anchorToDropdown:SetRelativeWidth(0.5)
    textContainer:AddChild(anchorToDropdown)

    local xOffsetSlider = AG:Create("Slider")
    xOffsetSlider:SetLabel("X Offset")
    xOffsetSlider:SetValue(BCDM.db.profile.SecondaryPowerBar.Text.Layout[3])
    xOffsetSlider:SetSliderValues(-500, 500, 0.1)
    xOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Text.Layout[3] = value BCDM:UpdateSecondaryPowerBar() end)
    xOffsetSlider:SetRelativeWidth(0.33)
    textContainer:AddChild(xOffsetSlider)

    local yOffsetSlider = AG:Create("Slider")
    yOffsetSlider:SetLabel("Y Offset")
    yOffsetSlider:SetValue(BCDM.db.profile.SecondaryPowerBar.Text.Layout[4])
    yOffsetSlider:SetSliderValues(-500, 500, 0.1)
    yOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Text.Layout[4] = value BCDM:UpdateSecondaryPowerBar() end)
    yOffsetSlider:SetRelativeWidth(0.33)
    textContainer:AddChild(yOffsetSlider)

    local fontSizeSlider = AG:Create("Slider")
    fontSizeSlider:SetLabel("Font Size")
    fontSizeSlider:SetValue(BCDM.db.profile.SecondaryPowerBar.Text.FontSize)
    fontSizeSlider:SetSliderValues(6, 72, 1)
    fontSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Text.FontSize = value BCDM:UpdateSecondaryPowerBar() end)
    fontSizeSlider:SetRelativeWidth(0.33)
    textContainer:AddChild(fontSizeSlider)

    function RefreshSecondaryPowerBarTextGUISettings()
        local enabled = BCDM.db.profile.SecondaryPowerBar.Text.Enabled
        anchorFromDropdown:SetDisabled(not enabled)
        anchorToDropdown:SetDisabled(not enabled)
        xOffsetSlider:SetDisabled(not enabled)
        yOffsetSlider:SetDisabled(not enabled)
        fontSizeSlider:SetDisabled(not enabled)
    end

    RefreshSecondaryPowerBarTextGUISettings()

    return textContainer
end

local function CreateSecondaryPowerBarSettings(parentContainer)
    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local toggleContainer = AG:Create("InlineGroup")
    toggleContainer:SetTitle("Toggles & Colours")
    toggleContainer:SetFullWidth(true)
    toggleContainer:SetLayout("Flow")
    ScrollFrame:AddChild(toggleContainer)

    local enabledCheckbox = AG:Create("CheckBox")
    enabledCheckbox:SetLabel("Enable Power Bar")
    enabledCheckbox:SetValue(BCDM.db.profile.SecondaryPowerBar.Enabled)
    enabledCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Enabled = value BCDM:UpdateSecondaryPowerBar() RefreshSecondaryPowerBarGUISettings() end)
    enabledCheckbox:SetRelativeWidth(isUnitDeathKnight and 1 or 0.25)
    toggleContainer:AddChild(enabledCheckbox)

    local colourByTypeCheckbox = AG:Create("CheckBox")
    colourByTypeCheckbox:SetLabel("Colour By Power Type")
    colourByTypeCheckbox:SetValue(BCDM.db.profile.SecondaryPowerBar.ColourByType)
    colourByTypeCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.ColourByType = value BCDM:UpdateSecondaryPowerBar() RefreshSecondaryPowerBarGUISettings() end)
    colourByTypeCheckbox:SetRelativeWidth(isUnitDeathKnight and 0.33 or 0.25)
    toggleContainer:AddChild(colourByTypeCheckbox)

    local colourByClassCheckbox = AG:Create("CheckBox")
    colourByClassCheckbox:SetLabel("Colour By Class")
    colourByClassCheckbox:SetValue(BCDM.db.profile.SecondaryPowerBar.ColourByClass)
    colourByClassCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.ColourByClass = value BCDM:UpdateSecondaryPowerBar() RefreshSecondaryPowerBarGUISettings() end)
    colourByClassCheckbox:SetRelativeWidth(isUnitDeathKnight and 0.33 or 0.25)
    toggleContainer:AddChild(colourByClassCheckbox)

    if isUnitDeathKnight then
        local colourRunesBySpecCheckbox = AG:Create("CheckBox")
        colourRunesBySpecCheckbox:SetLabel("Colour by Specialization")
        colourRunesBySpecCheckbox:SetValue(BCDM.db.profile.SecondaryPowerBar.ColourBySpec)
        colourRunesBySpecCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.ColourBySpec = value BCDM:UpdateSecondaryPowerBar() RefreshSecondaryPowerBarGUISettings() end)
        colourRunesBySpecCheckbox:SetRelativeWidth(0.33)
        toggleContainer:AddChild(colourRunesBySpecCheckbox)
    end

    local matchAnchorWidthCheckbox = AG:Create("CheckBox")
    matchAnchorWidthCheckbox:SetLabel("Match Width Of Anchor")
    matchAnchorWidthCheckbox:SetValue(BCDM.db.profile.SecondaryPowerBar.MatchWidthOfAnchor)
    matchAnchorWidthCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.MatchWidthOfAnchor = value BCDM:UpdateSecondaryPowerBar() RefreshSecondaryPowerBarGUISettings() end)
    matchAnchorWidthCheckbox:SetRelativeWidth(isUnitDeathKnight and 0.33 or 0.25)
    toggleContainer:AddChild(matchAnchorWidthCheckbox)

    local foregroundColourPicker = AG:Create("ColorPicker")
    foregroundColourPicker:SetLabel("Foreground Colour")
    foregroundColourPicker:SetColor(BCDM.db.profile.SecondaryPowerBar.ForegroundColour[1], BCDM.db.profile.SecondaryPowerBar.ForegroundColour[2], BCDM.db.profile.SecondaryPowerBar.ForegroundColour[3], BCDM.db.profile.SecondaryPowerBar.ForegroundColour[4])
    foregroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.SecondaryPowerBar.ForegroundColour = {r, g, b, a} BCDM:UpdateSecondaryPowerBar() end)
    foregroundColourPicker:SetRelativeWidth(0.33)
    foregroundColourPicker:SetHasAlpha(true)
    toggleContainer:AddChild(foregroundColourPicker)

    local backgroundColourPicker = AG:Create("ColorPicker")
    backgroundColourPicker:SetLabel("Background Colour")
    backgroundColourPicker:SetColor(BCDM.db.profile.SecondaryPowerBar.BackgroundColour[1], BCDM.db.profile.SecondaryPowerBar.BackgroundColour[2], BCDM.db.profile.SecondaryPowerBar.BackgroundColour[3], BCDM.db.profile.SecondaryPowerBar.BackgroundColour[4])
    backgroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.SecondaryPowerBar.BackgroundColour = {r, g, b, a} BCDM:UpdateSecondaryPowerBar() end)
    backgroundColourPicker:SetRelativeWidth(0.33)
    backgroundColourPicker:SetHasAlpha(true)
    toggleContainer:AddChild(backgroundColourPicker)

    local layoutContainer = AG:Create("InlineGroup")
    layoutContainer:SetTitle("Layout & Positioning")
    layoutContainer:SetFullWidth(true)
    layoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(layoutContainer)

    local anchorFromDropdown = AG:Create("Dropdown")
    anchorFromDropdown:SetLabel("Anchor From")
    anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorFromDropdown:SetValue(BCDM.db.profile.SecondaryPowerBar.Layout[1])
    anchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Layout[1] = value BCDM:UpdateSecondaryPowerBar() end)
    anchorFromDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorFromDropdown)

    local anchorParentDropdown = AG:Create("Dropdown")
    anchorParentDropdown:SetLabel("Anchor Parent")
    anchorParentDropdown:SetList(AnchorParents["SecondaryPower"][1], AnchorParents["SecondaryPower"][2])
    anchorParentDropdown:SetValue(BCDM.db.profile.SecondaryPowerBar.Layout[2])
    anchorParentDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Layout[2] = value BCDM:UpdateSecondaryPowerBar() end)
    anchorParentDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorParentDropdown)

    local anchorToDropdown = AG:Create("Dropdown")
    anchorToDropdown:SetLabel("Anchor To")
    anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorToDropdown:SetValue(BCDM.db.profile.SecondaryPowerBar.Layout[3])
    anchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Layout[3] = value BCDM:UpdateSecondaryPowerBar() end)
    anchorToDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorToDropdown)

    local widthSlider = AG:Create("Slider")
    widthSlider:SetLabel("Width")
    widthSlider:SetValue(BCDM.db.profile.SecondaryPowerBar.Width)
    widthSlider:SetSliderValues(50, 1000, 1)
    widthSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Width = value BCDM:UpdateSecondaryPowerBar() end)
    widthSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(widthSlider)

    local heightSlider = AG:Create("Slider")
    heightSlider:SetLabel("Height")
    heightSlider:SetValue(BCDM.db.profile.SecondaryPowerBar.Height)
    heightSlider:SetSliderValues(5, 500, 1)
    heightSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Height = value BCDM:UpdateSecondaryPowerBar() end)
    heightSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(heightSlider)

    local xOffsetSlider = AG:Create("Slider")
    xOffsetSlider:SetLabel("X Offset")
    xOffsetSlider:SetValue(BCDM.db.profile.SecondaryPowerBar.Layout[4])
    xOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    xOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Layout[4] = value BCDM:UpdateSecondaryPowerBar() end)
    xOffsetSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(xOffsetSlider)

    local yOffsetSlider = AG:Create("Slider")
    yOffsetSlider:SetLabel("Y Offset")
    yOffsetSlider:SetValue(BCDM.db.profile.SecondaryPowerBar.Layout[5])
    yOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    yOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.SecondaryPowerBar.Layout[5] = value BCDM:UpdateSecondaryPowerBar() end)
    yOffsetSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(yOffsetSlider)

    local textContainer = CreateSecondaryPowerBarTextSettings(ScrollFrame)

    function RefreshSecondaryPowerBarGUISettings()
        if not BCDM.db.profile.SecondaryPowerBar.Enabled then
            for _, child in ipairs(toggleContainer.children) do
                if child ~= enabledCheckbox then
                    child:SetDisabled(true)
                end
            end
            for _, child in ipairs(layoutContainer.children) do
                child:SetDisabled(true)
            end
            for _, child in ipairs(textContainer.children) do
                child:SetDisabled(true)
            end
        else
            for _, child in ipairs(toggleContainer.children) do
                child:SetDisabled(false)
            end
            for _, child in ipairs(layoutContainer.children) do
                child:SetDisabled(false)
            end
            for _, child in ipairs(textContainer.children) do
                child:SetDisabled(false)
            end
            if BCDM.db.profile.SecondaryPowerBar.ColourByType or BCDM.db.profile.SecondaryPowerBar.ColourByClass then
                foregroundColourPicker:SetDisabled(true)
            else
                foregroundColourPicker:SetDisabled(false)
            end
            if BCDM.db.profile.SecondaryPowerBar.MatchWidthOfAnchor then
                widthSlider:SetDisabled(true)
            else
                widthSlider:SetDisabled(false)
            end
        end
        RefreshSecondaryPowerBarTextGUISettings()
    end

    RefreshSecondaryPowerBarGUISettings()

    return ScrollFrame
end

local function CreateCastBarTextSettings(parentContainer)
    local textContainer = AG:Create("InlineGroup")
    textContainer:SetTitle("Text Settings")
    textContainer:SetFullWidth(true)
    textContainer:SetLayout("Flow")
    parentContainer:AddChild(textContainer)

    local spellNameContainer = AG:Create("InlineGroup")
    spellNameContainer:SetTitle("Spell Name Settings")
    spellNameContainer:SetFullWidth(true)
    spellNameContainer:SetLayout("Flow")
    textContainer:AddChild(spellNameContainer)

    local spellName_AnchorFromDropdown = AG:Create("Dropdown")
    spellName_AnchorFromDropdown:SetLabel("Anchor From")
    spellName_AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    spellName_AnchorFromDropdown:SetValue(BCDM.db.profile.CastBar.Text.SpellName.Layout[1])
    spellName_AnchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.SpellName.Layout[1] = value BCDM:UpdateCastBar() end)
    spellName_AnchorFromDropdown:SetRelativeWidth(0.5)
    spellNameContainer:AddChild(spellName_AnchorFromDropdown)

    local spellName_AnchorToDropdown = AG:Create("Dropdown")
    spellName_AnchorToDropdown:SetLabel("Anchor To")
    spellName_AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    spellName_AnchorToDropdown:SetValue(BCDM.db.profile.CastBar.Text.SpellName.Layout[2])
    spellName_AnchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.SpellName.Layout[2] = value BCDM:UpdateCastBar() end)
    spellName_AnchorToDropdown:SetRelativeWidth(0.5)
    spellNameContainer:AddChild(spellName_AnchorToDropdown)

    local spellName_XOffsetSlider = AG:Create("Slider")
    spellName_XOffsetSlider:SetLabel("X Offset")
    spellName_XOffsetSlider:SetValue(BCDM.db.profile.CastBar.Text.SpellName.Layout[3])
    spellName_XOffsetSlider:SetSliderValues(-500, 500, 0.1)
    spellName_XOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.SpellName.Layout[3] = value BCDM:UpdateCastBar() end)
    spellName_XOffsetSlider:SetRelativeWidth(0.25)
    spellNameContainer:AddChild(spellName_XOffsetSlider)

    local spellName_YOffsetSlider = AG:Create("Slider")
    spellName_YOffsetSlider:SetLabel("Y Offset")
    spellName_YOffsetSlider:SetValue(BCDM.db.profile.CastBar.Text.SpellName.Layout[4])
    spellName_YOffsetSlider:SetSliderValues(-500, 500, 0.1)
    spellName_YOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.SpellName.Layout[4] = value BCDM:UpdateCastBar() end)
    spellName_YOffsetSlider:SetRelativeWidth(0.25)
    spellNameContainer:AddChild(spellName_YOffsetSlider)

    local spellName_FontSizeSlider = AG:Create("Slider")
    spellName_FontSizeSlider:SetLabel("Font Size")
    spellName_FontSizeSlider:SetValue(BCDM.db.profile.CastBar.Text.SpellName.FontSize)
    spellName_FontSizeSlider:SetSliderValues(6, 72, 1)
    spellName_FontSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.SpellName.FontSize = value BCDM:UpdateCastBar() end)
    spellName_FontSizeSlider:SetRelativeWidth(0.25)
    spellNameContainer:AddChild(spellName_FontSizeSlider)

    local spellName_MaxCharactersSlider = AG:Create("Slider")
    spellName_MaxCharactersSlider:SetLabel("Max Characters")
    spellName_MaxCharactersSlider:SetValue(BCDM.db.profile.CastBar.Text.SpellName.MaxCharacters)
    spellName_MaxCharactersSlider:SetSliderValues(0, 24, 1)
    spellName_MaxCharactersSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.SpellName.MaxCharacters = value BCDM:UpdateCastBar() end)
    spellName_MaxCharactersSlider:SetRelativeWidth(0.25)
    spellNameContainer:AddChild(spellName_MaxCharactersSlider)

    local castTimeContainer = AG:Create("InlineGroup")
    castTimeContainer:SetTitle("Cast Time Settings")
    castTimeContainer:SetFullWidth(true)
    castTimeContainer:SetLayout("Flow")
    textContainer:AddChild(castTimeContainer)

    local castTime_AnchorFromDropdown = AG:Create("Dropdown")
    castTime_AnchorFromDropdown:SetLabel("Anchor From")
    castTime_AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    castTime_AnchorFromDropdown:SetValue(BCDM.db.profile.CastBar.Text.CastTime.Layout[1])
    castTime_AnchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.CastTime.Layout[1] = value BCDM:UpdateCastBar() end)
    castTime_AnchorFromDropdown:SetRelativeWidth(0.5)
    castTimeContainer:AddChild(castTime_AnchorFromDropdown)

    local castTime_AnchorToDropdown = AG:Create("Dropdown")
    castTime_AnchorToDropdown:SetLabel("Anchor To")
    castTime_AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    castTime_AnchorToDropdown:SetValue(BCDM.db.profile.CastBar.Text.CastTime.Layout[2])
    castTime_AnchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.CastTime.Layout[2] = value BCDM:UpdateCastBar() end)
    castTime_AnchorToDropdown:SetRelativeWidth(0.5)
    castTimeContainer:AddChild(castTime_AnchorToDropdown)

    local castTime_XOffsetSlider = AG:Create("Slider")
    castTime_XOffsetSlider:SetLabel("X Offset")
    castTime_XOffsetSlider:SetValue(BCDM.db.profile.CastBar.Text.CastTime.Layout[3])
    castTime_XOffsetSlider:SetSliderValues(-500, 500, 0.1)
    castTime_XOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.CastTime.Layout[3] = value BCDM:UpdateCastBar() end)
    castTime_XOffsetSlider:SetRelativeWidth(0.33)
    castTimeContainer:AddChild(castTime_XOffsetSlider)

    local castTime_YOffsetSlider = AG:Create("Slider")
    castTime_YOffsetSlider:SetLabel("Y Offset")
    castTime_YOffsetSlider:SetValue(BCDM.db.profile.CastBar.Text.CastTime.Layout[4])
    castTime_YOffsetSlider:SetSliderValues(-500, 500, 0.1)
    castTime_YOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.CastTime.Layout[4] = value BCDM:UpdateCastBar() end)
    castTime_YOffsetSlider:SetRelativeWidth(0.33)
    castTimeContainer:AddChild(castTime_YOffsetSlider)

    local castTime_FontSizeSlider = AG:Create("Slider")
    castTime_FontSizeSlider:SetLabel("Font Size")
    castTime_FontSizeSlider:SetValue(BCDM.db.profile.CastBar.Text.CastTime.FontSize)
    castTime_FontSizeSlider:SetSliderValues(6, 72, 1)
    castTime_FontSizeSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Text.CastTime.FontSize = value BCDM:UpdateCastBar() end)
    castTime_FontSizeSlider:SetRelativeWidth(0.33)
    castTimeContainer:AddChild(castTime_FontSizeSlider)

    return textContainer
end

local function CreateCastBarSettings(parentContainer)
    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local toggleContainer = AG:Create("InlineGroup")
    toggleContainer:SetTitle("Toggles & Colours")
    toggleContainer:SetFullWidth(true)
    toggleContainer:SetLayout("Flow")
    ScrollFrame:AddChild(toggleContainer)

    local enabledCheckbox = AG:Create("CheckBox")
    enabledCheckbox:SetLabel("Enable Cast Bar")
    enabledCheckbox:SetValue(BCDM.db.profile.CastBar.Enabled)
    enabledCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Enabled = value BCDM:UpdateCastBar() RefreshCastBarGUISettings() end)
    enabledCheckbox:SetRelativeWidth(0.33)
    toggleContainer:AddChild(enabledCheckbox)

    local colourByClassCheckbox = AG:Create("CheckBox")
    colourByClassCheckbox:SetLabel("Colour By Class")
    colourByClassCheckbox:SetValue(BCDM.db.profile.CastBar.ColourByClass)
    colourByClassCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.ColourByClass = value BCDM:UpdateCastBar() RefreshCastBarGUISettings() end)
    colourByClassCheckbox:SetRelativeWidth(0.33)
    toggleContainer:AddChild(colourByClassCheckbox)

    local matchAnchorWidthCheckbox = AG:Create("CheckBox")
    matchAnchorWidthCheckbox:SetLabel("Match Width Of Anchor")
    matchAnchorWidthCheckbox:SetValue(BCDM.db.profile.CastBar.MatchWidthOfAnchor)
    matchAnchorWidthCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.MatchWidthOfAnchor = value BCDM:UpdateCastBar() RefreshCastBarGUISettings() end)
    matchAnchorWidthCheckbox:SetRelativeWidth(0.33)
    toggleContainer:AddChild(matchAnchorWidthCheckbox)

    local foregroundColourPicker = AG:Create("ColorPicker")
    foregroundColourPicker:SetLabel("Foreground Colour")
    foregroundColourPicker:SetColor(BCDM.db.profile.CastBar.ForegroundColour[1], BCDM.db.profile.CastBar.ForegroundColour[2], BCDM.db.profile.CastBar.ForegroundColour[3], BCDM.db.profile.CastBar.ForegroundColour[4])
    foregroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.CastBar.ForegroundColour = {r, g, b, a} BCDM:UpdateCastBar() end)
    foregroundColourPicker:SetRelativeWidth(0.5)
    foregroundColourPicker:SetHasAlpha(true)
    toggleContainer:AddChild(foregroundColourPicker)

    local backgroundColourPicker = AG:Create("ColorPicker")
    backgroundColourPicker:SetLabel("Background Colour")
    backgroundColourPicker:SetColor(BCDM.db.profile.CastBar.BackgroundColour[1], BCDM.db.profile.CastBar.BackgroundColour[2], BCDM.db.profile.CastBar.BackgroundColour[3], BCDM.db.profile.CastBar.BackgroundColour[4])
    backgroundColourPicker:SetCallback("OnValueChanged", function(self, _, r, g, b, a) BCDM.db.profile.CastBar.BackgroundColour = {r, g, b, a} BCDM:UpdateCastBar() end)
    backgroundColourPicker:SetRelativeWidth(0.5)
    backgroundColourPicker:SetHasAlpha(true)
    toggleContainer:AddChild(backgroundColourPicker)

    local layoutContainer = AG:Create("InlineGroup")
    layoutContainer:SetTitle("Layout & Positioning")
    layoutContainer:SetFullWidth(true)
    layoutContainer:SetLayout("Flow")
    ScrollFrame:AddChild(layoutContainer)

    local anchorFromDropdown = AG:Create("Dropdown")
    anchorFromDropdown:SetLabel("Anchor From")
    anchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorFromDropdown:SetValue(BCDM.db.profile.CastBar.Layout[1])
    anchorFromDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Layout[1] = value BCDM:UpdateCastBar() end)
    anchorFromDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorFromDropdown)

    local anchorParentDropdown = AG:Create("Dropdown")
    anchorParentDropdown:SetLabel("Anchor Parent")
    anchorParentDropdown:SetList(AnchorParents["CastBar"][1], AnchorParents["CastBar"][2])
    anchorParentDropdown:SetValue(BCDM.db.profile.CastBar.Layout[2])
    anchorParentDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Layout[2] = value BCDM:UpdateCastBar() end)
    anchorParentDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorParentDropdown)

    local anchorToDropdown = AG:Create("Dropdown")
    anchorToDropdown:SetLabel("Anchor To")
    anchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    anchorToDropdown:SetValue(BCDM.db.profile.CastBar.Layout[3])
    anchorToDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Layout[3] = value BCDM:UpdateCastBar() end)
    anchorToDropdown:SetRelativeWidth(0.33)
    layoutContainer:AddChild(anchorToDropdown)

    local widthSlider = AG:Create("Slider")
    widthSlider:SetLabel("Width")
    widthSlider:SetValue(BCDM.db.profile.CastBar.Width)
    widthSlider:SetSliderValues(50, 1000, 1)
    widthSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Width = value BCDM:UpdateCastBar() end)
    widthSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(widthSlider)

    local heightSlider = AG:Create("Slider")
    heightSlider:SetLabel("Height")
    heightSlider:SetValue(BCDM.db.profile.CastBar.Height)
    heightSlider:SetSliderValues(5, 500, 1)
    heightSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Height = value BCDM:UpdateCastBar() end)
    heightSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(heightSlider)

    local xOffsetSlider = AG:Create("Slider")
    xOffsetSlider:SetLabel("X Offset")
    xOffsetSlider:SetValue(BCDM.db.profile.CastBar.Layout[4])
    xOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    xOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Layout[4] = value BCDM:UpdateCastBar() end)
    xOffsetSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(xOffsetSlider)

    local yOffsetSlider = AG:Create("Slider")
    yOffsetSlider:SetLabel("Y Offset")
    yOffsetSlider:SetValue(BCDM.db.profile.CastBar.Layout[5])
    yOffsetSlider:SetSliderValues(-1000, 1000, 0.1)
    yOffsetSlider:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Layout[5] = value BCDM:UpdateCastBar() end)
    yOffsetSlider:SetRelativeWidth(0.5)
    layoutContainer:AddChild(yOffsetSlider)

    local iconContainer = AG:Create("InlineGroup")
    iconContainer:SetTitle("Icon Settings")
    iconContainer:SetFullWidth(true)
    iconContainer:SetLayout("Flow")
    ScrollFrame:AddChild(iconContainer)

    local enableIconCheckbox = AG:Create("CheckBox")
    enableIconCheckbox:SetLabel("Enable Cast Icon")
    enableIconCheckbox:SetValue(BCDM.db.profile.CastBar.Icon.Enabled)
    enableIconCheckbox:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Icon.Enabled = value BCDM:UpdateCastBar() RefreshCastBarGUISettings() end)
    enableIconCheckbox:SetRelativeWidth(0.5)
    iconContainer:AddChild(enableIconCheckbox)

    local iconLayoutPositionDropdown = AG:Create("Dropdown")
    iconLayoutPositionDropdown:SetLabel("Icon Position")
    iconLayoutPositionDropdown:SetList({ ["LEFT"] = "Left", ["RIGHT"] = "Right" }, { "LEFT", "RIGHT" })
    iconLayoutPositionDropdown:SetValue(BCDM.db.profile.CastBar.Icon.Layout)
    iconLayoutPositionDropdown:SetCallback("OnValueChanged", function(self, _, value) BCDM.db.profile.CastBar.Icon.Layout = value BCDM:UpdateCastBar() end)
    iconLayoutPositionDropdown:SetRelativeWidth(0.5)
    iconContainer:AddChild(iconLayoutPositionDropdown)

    local textContainer = CreateCastBarTextSettings(ScrollFrame)

    function RefreshCastBarGUISettings()
        if not BCDM.db.profile.CastBar.Enabled then
            for _, child in ipairs(toggleContainer.children) do
                if child ~= enabledCheckbox then
                    child:SetDisabled(true)
                end
            end
            for _, child in ipairs(layoutContainer.children) do
                child:SetDisabled(true)
            end
            for _, child in ipairs(iconContainer.children) do
                if child ~= enableIconCheckbox then
                    child:SetDisabled(true)
                end
            end
            for _, child in ipairs(textContainer.children) do
                for _, cousin in ipairs(child.children) do
                    if cousin.SetDisabled then
                        cousin:SetDisabled(true)
                    end
                end
            end
        else
            for _, child in ipairs(toggleContainer.children) do
                child:SetDisabled(false)
            end
            for _, child in ipairs(layoutContainer.children) do
                child:SetDisabled(false)
            end
            for _, child in ipairs(iconContainer.children) do
                if child ~= enableIconCheckbox then
                    child:SetDisabled(false)
                end
            end
            for _, child in ipairs(textContainer.children) do
                for _, cousin in ipairs(child.children) do
                    if cousin.SetDisabled then
                        cousin:SetDisabled(false)
                    end
                end
            end
        end
        if BCDM.db.profile.CastBar.MatchWidthOfAnchor then
            widthSlider:SetDisabled(true)
        else
            widthSlider:SetDisabled(false)
        end
        if BCDM.db.profile.CastBar.ColourByClass then
            foregroundColourPicker:SetDisabled(true)
        else
            foregroundColourPicker:SetDisabled(false)
        end
        if not BCDM.db.profile.CastBar.Icon.Enabled then
            for _, child in ipairs(iconContainer.children) do
                if child ~= enableIconCheckbox then
                    child:SetDisabled(true)
                end
            end
        end
    end

    RefreshCastBarGUISettings()

    ScrollFrame:DoLayout()

    return ScrollFrame
end

local function CreateProfileSettings(containerParent)
    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    containerParent:AddChild(ScrollFrame)

    local profileKeys = {}
    local specProfilesList = {}
    local numSpecs = GetNumSpecializations()

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
        GlobalProfileDropdown:SetList(profileKeys)
        DeleteProfileDropdown:SetList(profilesToDelete)
        for i = 1, numSpecs do
            specProfilesList[i]:SetList(profileKeys)
            specProfilesList[i]:SetValue(BCDM.db:GetDualSpecProfile(i))
        end
        SelectProfileDropdown:SetValue(BCDM.db:GetCurrentProfile())
        CopyFromProfileDropdown:SetValue(nil)
        DeleteProfileDropdown:SetValue(nil)
        if not next(profilesToDelete) then
            DeleteProfileDropdown:SetDisabled(true)
        else
            DeleteProfileDropdown:SetDisabled(false)
        end
        ResetProfileButton:SetText("Reset |cFF8080FF" .. BCDM.db:GetCurrentProfile() .. "|r Profile")
        local isUsingGlobal = BCDM.db.global.UseGlobalProfile
        ActiveProfileHeading:SetText( "Active Profile: |cFFFFFFFF" .. BCDM.db:GetCurrentProfile() .. (isUsingGlobal and " (|cFFFFCC00Global|r)" or "") .. "|r" )
        if BCDM.db:IsDualSpecEnabled() then
            SelectProfileDropdown:SetDisabled(true)
            CopyFromProfileDropdown:SetDisabled(true)
            GlobalProfileDropdown:SetDisabled(true)
            DeleteProfileDropdown:SetDisabled(true)
            UseGlobalProfileToggle:SetDisabled(true)
            GlobalProfileDropdown:SetDisabled(true)
        else
            SelectProfileDropdown:SetDisabled(isUsingGlobal)
            CopyFromProfileDropdown:SetDisabled(isUsingGlobal)
            GlobalProfileDropdown:SetDisabled(not isUsingGlobal)
            DeleteProfileDropdown:SetDisabled(isUsingGlobal or not next(profilesToDelete))
            UseGlobalProfileToggle:SetDisabled(false)
            GlobalProfileDropdown:SetDisabled(not isUsingGlobal)
            UseDualSpecializationToggle:SetDisabled(isUsingGlobal)
        end
        ProfileContainer:DoLayout()
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
    ResetProfileButton:SetCallback("OnClick", function() BCDM.db:ResetProfile() BCDM:ResolveLSM() BCDM:UpdateBCDM() RefreshProfiles() end)
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

    CreateInformationTag(ProfileContainer, "If |cFF8080FFUse Global Profile Settings|r is enabled, the profile selected below will be used as your active profile.\nThis is useful if you want to use the same profile across multiple characters.")

    UseGlobalProfileToggle = AG:Create("CheckBox")
    UseGlobalProfileToggle:SetLabel("Use Global Profile Settings")
    UseGlobalProfileToggle:SetValue(BCDM.db.global.UseGlobalProfile)
    UseGlobalProfileToggle:SetRelativeWidth(0.5)
    UseGlobalProfileToggle:SetCallback("OnValueChanged", function(_, _, value) RefreshProfiles() BCDM.db.global.UseGlobalProfile = value if value and BCDM.db.global.GlobalProfile and BCDM.db.global.GlobalProfile ~= "" then BCDM.db:SetProfile(BCDM.db.global.GlobalProfile) BCDM:UpdateBCDM() end GlobalProfileDropdown:SetDisabled(not value) for _, child in ipairs(ProfileContainer.children) do if child ~= UseGlobalProfileToggle and child ~= GlobalProfileDropdown then DeepDisable(child, value, GlobalProfileDropdown) end end BCDM:UpdateBCDM() RefreshProfiles() end)
    ProfileContainer:AddChild(UseGlobalProfileToggle)

    GlobalProfileDropdown = AG:Create("Dropdown")
    GlobalProfileDropdown:SetLabel("Global Profile...")
    GlobalProfileDropdown:SetRelativeWidth(0.5)
    GlobalProfileDropdown:SetList(profileKeys)
    GlobalProfileDropdown:SetValue(BCDM.db.global.GlobalProfile)
    GlobalProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) BCDM.db:SetProfile(value) BCDM.db.global.GlobalProfile = value BCDM:UpdateBCDM() RefreshProfiles() end)
    ProfileContainer:AddChild(GlobalProfileDropdown)

    local SpecProfileContainer = AG:Create("InlineGroup")
    SpecProfileContainer:SetTitle("Specialization Profiles")
    SpecProfileContainer:SetFullWidth(true)
    SpecProfileContainer:SetLayout("Flow")
    ScrollFrame:AddChild(SpecProfileContainer)

    UseDualSpecializationToggle = AG:Create("CheckBox")
    UseDualSpecializationToggle:SetLabel("Enable Specialization Profiles")
    UseDualSpecializationToggle:SetValue(BCDM.db:IsDualSpecEnabled())
    UseDualSpecializationToggle:SetRelativeWidth(1)
    UseDualSpecializationToggle:SetCallback("OnValueChanged", function(_, _, value) BCDM.db:SetDualSpecEnabled(value) for i = 1, numSpecs do specProfilesList[i]:SetDisabled(not value) end RefreshProfiles() BCDM:UpdateBCDM() end)
    UseDualSpecializationToggle:SetDisabled(BCDM.db.global.UseGlobalProfile)
    SpecProfileContainer:AddChild(UseDualSpecializationToggle)

    for i = 1, numSpecs do
        local _, specName = GetSpecializationInfo(i)
        specProfilesList[i] = AG:Create("Dropdown")
        specProfilesList[i]:SetLabel(string.format("%s", specName or ("Spec %d"):format(i)))
        specProfilesList[i]:SetValue(BCDM.db:GetDualSpecProfile(i))
        specProfilesList[i]:SetCallback("OnValueChanged", function(widget, event, value) BCDM.db:SetDualSpecProfile(value, i) end)
        specProfilesList[i]:SetRelativeWidth(numSpecs == 2 and 0.5 or numSpecs == 3 and 0.33 or 0.25)
        specProfilesList[i]:SetDisabled(not BCDM.db:IsDualSpecEnabled() or BCDM.db.global.UseGlobalProfile)
        SpecProfileContainer:AddChild(specProfilesList[i])
    end

    RefreshProfiles()

    local SharingContainer = AG:Create("InlineGroup")
    SharingContainer:SetTitle("Profile Sharing")
    SharingContainer:SetFullWidth(true)
    SharingContainer:SetLayout("Flow")
    ScrollFrame:AddChild(SharingContainer)

    local ExportingHeading = AG:Create("Heading")
    ExportingHeading:SetText("Exporting")
    ExportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ExportingHeading)

    CreateInformationTag(SharingContainer, "You can export your profile by pressing |cFF8080FFExport Profile|r button below & share the string with other |cFF8080FFUnhalted|r Unit Frame users.")

    local ExportingEditBox = AG:Create("EditBox")
    ExportingEditBox:SetLabel("Export String...")
    ExportingEditBox:SetText("")
    ExportingEditBox:SetRelativeWidth(0.7)
    ExportingEditBox:DisableButton(true)
    ExportingEditBox:SetCallback("OnEnterPressed", function() ExportingEditBox:ClearFocus() end)
    ExportingEditBox:SetCallback("OnTextChanged", function() ExportingEditBox:ClearFocus() end)
    SharingContainer:AddChild(ExportingEditBox)

    local ExportProfileButton = AG:Create("Button")
    ExportProfileButton:SetText("Export Profile")
    ExportProfileButton:SetRelativeWidth(0.3)
    ExportProfileButton:SetCallback("OnClick", function() ExportingEditBox:SetText(BCDM:ExportSavedVariables()) ExportingEditBox:HighlightText() ExportingEditBox:SetFocus() end)
    SharingContainer:AddChild(ExportProfileButton)

    local ImportingHeading = AG:Create("Heading")
    ImportingHeading:SetText("Importing")
    ImportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ImportingHeading)

    CreateInformationTag(SharingContainer, "If you have an exported string, paste it in the |cFF8080FFImport String|r box below & press |cFF8080FFImport Profile|r.")

    local ImportingEditBox = AG:Create("EditBox")
    ImportingEditBox:SetLabel("Import String...")
    ImportingEditBox:SetText("")
    ImportingEditBox:SetRelativeWidth(0.7)
    ImportingEditBox:DisableButton(true)
    ImportingEditBox:SetCallback("OnEnterPressed", function() ImportingEditBox:ClearFocus() end)
    ImportingEditBox:SetCallback("OnTextChanged", function() ImportingEditBox:ClearFocus() end)
    SharingContainer:AddChild(ImportingEditBox)

    local ImportProfileButton = AG:Create("Button")
    ImportProfileButton:SetText("Import Profile")
    ImportProfileButton:SetRelativeWidth(0.3)
    ImportProfileButton:SetCallback("OnClick", function() if ImportingEditBox:GetText() ~= "" then BCDM:ImportSavedVariables(ImportingEditBox:GetText()) ImportingEditBox:SetText("") end end)
    SharingContainer:AddChild(ImportProfileButton)
    GlobalProfileDropdown:SetDisabled(not BCDM.db.global.UseGlobalProfile)
    if BCDM.db.global.UseGlobalProfile then for _, child in ipairs(ProfileContainer.children) do if child ~= UseGlobalProfileToggle and child ~= GlobalProfileDropdown then DeepDisable(child, true, GlobalProfileDropdown) end end end

    ScrollFrame:DoLayout()

    return ScrollFrame
end

function BCDM:CreateGUI()
    if isGUIOpen then return end
    if InCombatLockdown() then return end

    isGUIOpen = true

    Container = AG:Create("Frame")
    Container:SetTitle(BCDM.PRETTY_ADDON_NAME)
    Container:SetLayout("Fill")
    Container:SetWidth(900)
    Container:SetHeight(600)
    Container:EnableResize(false)
    Container:SetCallback("OnClose", function(widget) AG:Release(widget) BCDM:UpdateBCDM() isGUIOpen = false BCDM.CAST_BAR_TEST_MODE = false BCDM:CreateTestCastBar() BCDM.EssentialCooldownViewerOverlay:Hide() BCDM.UtilityCooldownViewerOverlay:Hide() BCDM.BuffIconCooldownViewerOverlay:Hide() BCDM.CustomCooldownViewerOverlay:Hide() BCDM.CustomItemBarOverlay:Hide() end)

    local function SelectTab(GUIContainer, _, MainTab)
        GUIContainer:ReleaseChildren()

        local Wrapper = AG:Create("SimpleGroup")
        Wrapper:SetFullWidth(true)
        Wrapper:SetFullHeight(true)
        Wrapper:SetLayout("Fill")
        GUIContainer:AddChild(Wrapper)

        if MainTab == "General" then
            CreateGeneralSettings(Wrapper)
        elseif MainTab == "Global" then
            CreateGlobalSettings(Wrapper)
        elseif MainTab == "EditModeManager" then
            CreateEditModeManagerSettings(Wrapper)
        elseif MainTab == "Essential" then
            CreateCooldownViewerSettings(Wrapper, "Essential")
        elseif MainTab == "Utility" then
            CreateCooldownViewerSettings(Wrapper, "Utility")
        elseif MainTab == "Buffs" then
            CreateCooldownViewerSettings(Wrapper, "Buffs")
        elseif MainTab == "BuffBar" then
            CreateCooldownViewerSettings(Wrapper, "BuffBar")
        elseif MainTab == "Custom" then
            CreateCooldownViewerSettings(Wrapper, "Custom")
        elseif MainTab == "Item" then
            CreateCooldownViewerSettings(Wrapper, "Item")
        elseif MainTab == "PowerBar" then
            CreatePowerBarSettings(Wrapper)
        elseif MainTab == "SecondaryPowerBar" then
            CreateSecondaryPowerBarSettings(Wrapper)
        elseif MainTab == "CastBar" then
            CreateCastBarSettings(Wrapper)
        elseif MainTab == "Profiles" then
            CreateProfileSettings(Wrapper)
        end
        if MainTab == "Buffs" or MainTab == "BuffBar" then CooldownViewerSettings:Show() else CooldownViewerSettings:Hide() end
        if MainTab == "CastBar" then BCDM.CAST_BAR_TEST_MODE = true BCDM:CreateTestCastBar() else BCDM.CAST_BAR_TEST_MODE = false BCDM:CreateTestCastBar() end
        if MainTab == "Essential" then  BCDM.EssentialCooldownViewerOverlay:Show() else BCDM.EssentialCooldownViewerOverlay:Hide() end
        if MainTab == "Utility" then  BCDM.UtilityCooldownViewerOverlay:Show() else BCDM.UtilityCooldownViewerOverlay:Hide() end
        if MainTab == "Buffs" then  BCDM.BuffIconCooldownViewerOverlay:Show() else BCDM.BuffIconCooldownViewerOverlay:Hide() end
        if MainTab == "Custom" then BCDM.CustomCooldownViewerOverlay:Show() else BCDM.CustomCooldownViewerOverlay:Hide() end
        if MainTab == "Item" then  BCDM.CustomItemBarOverlay:Show() else BCDM.CustomItemBarOverlay:Hide() end
        GenerateSupportText(Container)
    end

    local ContainerTabGroup = AG:Create("TabGroup")
    ContainerTabGroup:SetLayout("Flow")
    ContainerTabGroup:SetFullWidth(true)
    ContainerTabGroup:SetTabs({
        { text = "General", value = "General"},
        { text = "Global", value = "Global"},
        { text = "Edit Mode Manager", value = "EditModeManager"},
        { text = "Essential", value = "Essential"},
        { text = "Utility", value = "Utility"},
        { text = "Buffs", value = "Buffs"},
        { text = "Buff Bar", value = "BuffBar"},
        { text = "Custom", value = "Custom"},
        { text = "Item", value = "Item"},
        { text = "Power Bar", value = "PowerBar"},
        { text = "Secondary Power Bar", value = "SecondaryPowerBar"},
        { text = "Cast Bar", value = "CastBar"},
        { text = "Profiles", value = "Profiles"},
    })
    ContainerTabGroup:SetCallback("OnGroupSelected", SelectTab)
    ContainerTabGroup:SelectTab("General")
    Container:AddChild(ContainerTabGroup)
end
