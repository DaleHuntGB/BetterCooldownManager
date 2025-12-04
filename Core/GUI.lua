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

local PowerBarParents = {
    {
        ["EssentialCooldownViewer"] = "Essential",
        ["UtilityCooldownViewer"] = "Utility",
    },
    { "EssentialCooldownViewer", "UtilityCooldownViewer"}
}

local PowerBarAnchorToName = {
    ["EssentialCooldownViewer"] = "Essential Cooldown Viewer",
    ["UtilityCooldownViewer"] = "Utility Cooldown Viewer",
}

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

local function DrawGeneralSettings(parentContainer)
    local CooldownManagerDB = BCDM.db.global
    local GeneralDB = CooldownManagerDB.General

    local ScrollFrame = AG:Create("ScrollFrame")
    ScrollFrame:SetLayout("Flow")
    ScrollFrame:SetFullWidth(true)
    ScrollFrame:SetFullHeight(true)
    parentContainer:AddChild(ScrollFrame)

    local OpenEditModeButton = AG:Create("Button")
    OpenEditModeButton:SetText("Toggle Edit Mode")
    OpenEditModeButton:SetRelativeWidth(0.5)
    OpenEditModeButton:SetCallback("OnClick", function() if EditModeManagerFrame:IsShown() then EditModeManagerFrame:Hide() else EditModeManagerFrame:Show() end end)
    ScrollFrame:AddChild(OpenEditModeButton)

    local OpenCDMSettingsButton = AG:Create("Button")
    OpenCDMSettingsButton:SetText("Advanced Settings")
    OpenCDMSettingsButton:SetRelativeWidth(0.5)
    OpenCDMSettingsButton:SetCallback("OnClick", function() if CooldownViewerSettings:IsShown() then CooldownViewerSettings:Hide() else CooldownViewerSettings:Show() end end)
    ScrollFrame:AddChild(OpenCDMSettingsButton)

    local CooldownManagerFontDropdown = AG:Create("LSM30_Font")
    CooldownManagerFontDropdown:SetLabel("Font")
    CooldownManagerFontDropdown:SetList(LSM:HashTable("font"))
    CooldownManagerFontDropdown:SetValue(GeneralDB.Font)
    CooldownManagerFontDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) GeneralDB.Font = value BCDM:RefreshAllViewers() end)
    CooldownManagerFontDropdown:SetRelativeWidth(0.33)
    ScrollFrame:AddChild(CooldownManagerFontDropdown)

    local CooldownManagerFontFlagDropdown = AG:Create("Dropdown")
    CooldownManagerFontFlagDropdown:SetLabel("Font Flag")
    CooldownManagerFontFlagDropdown:SetList({
        ["NONE"] = "None",
        ["OUTLINE"] = "Outline",
        ["THICKOUTLINE"] = "Thick Outline",
        ["MONOCHROME"] = "Monochrome",
    })
    CooldownManagerFontFlagDropdown:SetValue(GeneralDB.FontFlag)
    CooldownManagerFontFlagDropdown:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.FontFlag = value BCDM:RefreshAllViewers() end)
    CooldownManagerFontFlagDropdown:SetRelativeWidth(0.33)
    ScrollFrame:AddChild(CooldownManagerFontFlagDropdown)

    local CooldownManagerIconZoomSlider = AG:Create("Slider")
    CooldownManagerIconZoomSlider:SetLabel("Icon Zoom")
    CooldownManagerIconZoomSlider:SetValue(GeneralDB.IconZoom)
    CooldownManagerIconZoomSlider:SetSliderValues(0, 1, 0.01)
    CooldownManagerIconZoomSlider:SetIsPercent(true)
    CooldownManagerIconZoomSlider:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.IconZoom = value BCDM:RefreshAllViewers() end)
    CooldownManagerIconZoomSlider:SetRelativeWidth(0.33)
    ScrollFrame:AddChild(CooldownManagerIconZoomSlider)

    local CooldownTextContainer = AG:Create("InlineGroup")
    CooldownTextContainer:SetTitle("Cooldown Text Settings")
    CooldownTextContainer:SetFullWidth(true)
    CooldownTextContainer:SetLayout("Flow")
    ScrollFrame:AddChild(CooldownTextContainer)

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
    CooldownText_OffsetX:SetSliderValues(-200, 200, 1)
    CooldownText_OffsetX:SetRelativeWidth(0.33)
    CooldownText_OffsetX:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.Anchors[3] = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_OffsetX)

    local CooldownText_OffsetY = AG:Create("Slider")
    CooldownText_OffsetY:SetLabel("Offset Y")
    CooldownText_OffsetY:SetValue(GeneralDB.CooldownText.Anchors[4])
    CooldownText_OffsetY:SetSliderValues(-200, 200, 1)
    CooldownText_OffsetY:SetRelativeWidth(0.33)
    CooldownText_OffsetY:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.Anchors[4] = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_OffsetY)

    local CooldownText_FontSize = AG:Create("Slider")
    CooldownText_FontSize:SetLabel("Font Size")
    CooldownText_FontSize:SetValue(GeneralDB.CooldownText.FontSize)
    CooldownText_FontSize:SetSliderValues(8, 40, 1)
    CooldownText_FontSize:SetRelativeWidth(0.33)
    CooldownText_FontSize:SetCallback("OnValueChanged", function(_, _, value) GeneralDB.CooldownText.FontSize = value BCDM:RefreshAllViewers() end)
    CooldownTextContainer:AddChild(CooldownText_FontSize)

    return ScrollFrame
end

local function DrawCooldownSettings(parentContainer, cooldownViewer)
    local CooldownManagerDB = BCDM.db.global
    local CooldownViewerDB = CooldownManagerDB[BCDM.CooldownViewerToDB[cooldownViewer]]
    local isEssential = (cooldownViewer == "EssentialCooldownViewer")

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
    Viewer_AnchorFrom:SetRelativeWidth(isEssential and 0.5 or 0.33)
    Viewer_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[1] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_AnchorFrom)

    if not isEssential then
        local Viewer_AnchorParent = AG:Create("EditBox")
        Viewer_AnchorParent:SetLabel("Anchor Parent Frame")
        Viewer_AnchorParent:SetText(CooldownViewerDB.Anchors[2])
        Viewer_AnchorParent:SetRelativeWidth(0.33)
        Viewer_AnchorParent:SetCallback("OnEnterPressed", function(_, _, value) CooldownViewerDB.Anchors[2] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
        LayoutContainer:AddChild(Viewer_AnchorParent)
    end

    local Viewer_AnchorTo = AG:Create("Dropdown")
    Viewer_AnchorTo:SetLabel("Anchor To")
    Viewer_AnchorTo:SetList(Anchors[1], Anchors[2])
    Viewer_AnchorTo:SetValue(CooldownViewerDB.Anchors[3])
    Viewer_AnchorTo:SetRelativeWidth(isEssential and 0.5 or 0.33)
    Viewer_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[3] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_AnchorTo)

    local Viewer_OffsetX = AG:Create("Slider")
    Viewer_OffsetX:SetLabel("Offset X")
    Viewer_OffsetX:SetValue(CooldownViewerDB.Anchors[4])
    Viewer_OffsetX:SetSliderValues(-2000, 2000, 1)
    Viewer_OffsetX:SetRelativeWidth(0.25)
    Viewer_OffsetX:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[4] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
    LayoutContainer:AddChild(Viewer_OffsetX)

    local Viewer_OffsetY = AG:Create("Slider")
    Viewer_OffsetY:SetLabel("Offset Y")
    Viewer_OffsetY:SetValue(CooldownViewerDB.Anchors[5])
    Viewer_OffsetY:SetSliderValues(-2000, 2000, 1)
    Viewer_OffsetY:SetRelativeWidth(0.25)
    Viewer_OffsetY:SetCallback("OnValueChanged", function(_, _, value) CooldownViewerDB.Anchors[5] = value BCDM:UpdateCooldownViewer(cooldownViewer) end)
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

local function DrawPowerBarSettings(parentContainer)
    local PowerBarDB = BCDM.db.global.PowerBar

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
    ForegroundTextureDropdown:SetValue(PowerBarDB.PowerBarFGTexture)
    ForegroundTextureDropdown:SetRelativeWidth(0.5)
    ForegroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) PowerBarDB.PowerBarFGTexture = value BCDM:UpdatePowerBar() end)
    TextureColourContainer:AddChild(ForegroundTextureDropdown)

    local FGColour = AG:Create("ColorPicker")
    FGColour:SetLabel("Foreground Colour")
    FGColour:SetColor(unpack(PowerBarDB.FGColour))
    FGColour:SetRelativeWidth(0.5)
    FGColour:SetCallback("OnValueChanged", function(_, _, r, g, b, a) PowerBarDB.FGColour = {r, g, b, a} BCDM:UpdatePowerBar() end)
    TextureColourContainer:AddChild(FGColour)

    local BackgroundTextureDropdown = AG:Create("LSM30_Statusbar")
    BackgroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    BackgroundTextureDropdown:SetLabel("Background Texture")
    BackgroundTextureDropdown:SetValue(PowerBarDB.PowerBarBGTexture)
    BackgroundTextureDropdown:SetRelativeWidth(0.5)
    BackgroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) PowerBarDB.PowerBarBGTexture = value BCDM:UpdatePowerBar() end)
    TextureColourContainer:AddChild(BackgroundTextureDropdown)

    local BGColour = AG:Create("ColorPicker")
    BGColour:SetLabel("Background Colour")
    BGColour:SetColor(unpack(PowerBarDB.BGColour))
    BGColour:SetRelativeWidth(0.5)
    BGColour:SetCallback("OnValueChanged", function(_, _, r, g, b,  a) PowerBarDB.BGColour = {r, g, b, a} BCDM:UpdatePowerBar() end)
    TextureColourContainer:AddChild(BGColour)

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
    PowerBar_AnchorParent:SetList(PowerBarParents[1], PowerBarParents[2])
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
    PowerBar_OffsetX:SetSliderValues(-2000, 2000, 1)
    PowerBar_OffsetX:SetRelativeWidth(0.33)
    PowerBar_OffsetX:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Anchors[4] = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_OffsetX)

    local PowerBar_OffsetY = AG:Create("Slider")
    PowerBar_OffsetY:SetLabel("Offset Y")
    PowerBar_OffsetY:SetValue(PowerBarDB.Anchors[5])
    PowerBar_OffsetY:SetSliderValues(-2000, 2000, 1)
    PowerBar_OffsetY:SetRelativeWidth(0.33)
    PowerBar_OffsetY:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Anchors[5] = value BCDM:UpdatePowerBar() end)
    LayoutContainer:AddChild(PowerBar_OffsetY)

    local PowerBar_Height = AG:Create("Slider")
    PowerBar_Height:SetLabel("Power Bar Height")
    PowerBar_Height:SetValue(PowerBarDB.Height)
    PowerBar_Height:SetSliderValues(5, 50, 1)
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
    Text_AnchorFrom:SetRelativeWidth(0.33)
    Text_AnchorFrom:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[1] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_AnchorFrom)

    local Text_AnchorTo = AG:Create("Dropdown")
    Text_AnchorTo:SetLabel("Anchor To")
    Text_AnchorTo:SetList(Anchors[1], Anchors[2])
    Text_AnchorTo:SetValue(PowerBarDB.Text.Anchors[2])
    Text_AnchorTo:SetRelativeWidth(0.33)
    Text_AnchorTo:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[2] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_AnchorTo)

    local Text_Colour = AG:Create("ColorPicker")
    Text_Colour:SetLabel("Font Colour")
    Text_Colour:SetColor(unpack(PowerBarDB.Text.Colour))
    Text_Colour:SetRelativeWidth(0.33)
    Text_Colour:SetCallback("OnValueChanged", function(_, _, r, g, b) PowerBarDB.Text.Colour = {r, g, b} BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_Colour)

    local Text_OffsetX = AG:Create("Slider")
    Text_OffsetX:SetLabel("Offset X")
    Text_OffsetX:SetValue(PowerBarDB.Text.Anchors[3])
    Text_OffsetX:SetSliderValues(-200, 200, 1)
    Text_OffsetX:SetRelativeWidth(0.33)
    Text_OffsetX:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[3] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_OffsetX)

    local Text_OffsetY = AG:Create("Slider")
    Text_OffsetY:SetLabel("Offset Y")
    Text_OffsetY:SetValue(PowerBarDB.Text.Anchors[4])
    Text_OffsetY:SetSliderValues(-200, 200, 1)
    Text_OffsetY:SetRelativeWidth(0.33)
    Text_OffsetY:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.Anchors[4] = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_OffsetY)

    local Text_FontSize = AG:Create("Slider")
    Text_FontSize:SetLabel("Font Size")
    Text_FontSize:SetValue(PowerBarDB.Text.FontSize)
    Text_FontSize:SetSliderValues(8, 40, 1)
    Text_FontSize:SetRelativeWidth(0.33)
    Text_FontSize:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Text.FontSize = value BCDM:UpdatePowerBar() end)
    TextContainer:AddChild(Text_FontSize)

    return ScrollFrame
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
        elseif MainGroup == "PowerBar" then
            DrawPowerBarSettings(Wrapper)
        end
    end

    local GUIContainerTabGroup = AG:Create("TabGroup")
    GUIContainerTabGroup:SetLayout("Flow")
    GUIContainerTabGroup:SetTabs({
        { text = "General", value = "General"},
        { text = "Essential", value = "Essential"},
        { text = "Utility", value = "Utility"},
        { text = "Buffs", value = "Buffs"},
        { text = "Power Bar", value = "PowerBar"},
    })
    GUIContainerTabGroup:SetCallback("OnGroupSelected", SelectedGroup)
    GUIContainerTabGroup:SelectTab("General")
    GUIFrame:AddChild(GUIContainerTabGroup)
end