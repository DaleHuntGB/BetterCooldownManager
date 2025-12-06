local _, BCDM = ...

BCDM.LSM = LibStub("LibSharedMedia-3.0")
BCDM.InfoButton = "|A:glueannouncementpopup-icon-info:16:16|a "

BCDMG = BCDMG or {}

BCDM.AddOnName = C_AddOns.GetAddOnMetadata("BetterCooldownManager", "Title")

BCDM.Icon = "Interface\\AddOns\\BetterCooldownManager\\Media\\Logo.png"

if BCDM.LSM then BCDM.LSM:Register("statusbar", "Better Blizzard", [[Interface\AddOns\BetterCooldownManager\Media\BetterBlizzard.blp]]) end

BCDM.CooldownViewerToDB = {
    ["EssentialCooldownViewer"] = "Essential",
    ["UtilityCooldownViewer"] = "Utility",
    ["BuffIconCooldownViewer"] = "Buffs",
}

function BCDM:Print(MSG)
    print(BCDM.AddOnName..": "..MSG)
end

local function PixelPerfect(value)
    if not value then return 0 end
    local _, screenHeight = GetPhysicalScreenSize()
    local uiScale = UIParent:GetEffectiveScale()
    local pixelSize = 768 / screenHeight / uiScale
    return pixelSize * math.floor(value / pixelSize + 0.5333)
end

function BCDM:AddPixelBorder(frame)
    if not frame then return end

    local borderSize = 1
    local borderColour = { r = 0, g = 0, b = 0 }

    frame._borderSegments = frame._borderSegments or {}

    local borderAnchor = frame.Icon or frame
    local borderInset = PixelPerfect(-1)

    if #frame._borderSegments == 0 then
        local function CreateLine() return frame:CreateTexture(nil, "OVERLAY") end
        local topBorder = CreateLine()
        topBorder:SetPoint("TOPLEFT", borderAnchor, "TOPLEFT", PixelPerfect(borderInset), PixelPerfect(-borderInset))
        topBorder:SetPoint("TOPRIGHT", borderAnchor, "TOPRIGHT", PixelPerfect(-borderInset), PixelPerfect(-borderInset))

        local bottomBorder = CreateLine()
        bottomBorder:SetPoint("BOTTOMLEFT", borderAnchor, "BOTTOMLEFT", PixelPerfect(borderInset), PixelPerfect(borderInset))
        bottomBorder:SetPoint("BOTTOMRIGHT", borderAnchor, "BOTTOMRIGHT", PixelPerfect(-borderInset), PixelPerfect(borderInset))

        local leftBorder = CreateLine()
        leftBorder:SetPoint("TOPLEFT", borderAnchor, "TOPLEFT", PixelPerfect(borderInset), PixelPerfect(-borderInset))
        leftBorder:SetPoint("BOTTOMLEFT", borderAnchor, "BOTTOMLEFT", PixelPerfect(borderInset), PixelPerfect(borderInset))

        local rightBorder = CreateLine()
        rightBorder:SetPoint("TOPRIGHT", borderAnchor, "TOPRIGHT", PixelPerfect(-borderInset), PixelPerfect(-borderInset))
        rightBorder:SetPoint("BOTTOMRIGHT", borderAnchor, "BOTTOMRIGHT", PixelPerfect(-borderInset), PixelPerfect(borderInset))

        frame._borderSegments = { topBorder, bottomBorder, leftBorder, rightBorder }
    end

    local top, bottom, left, right = unpack(frame._borderSegments)

    if top and bottom and left and right then
        top:SetHeight(PixelPerfect(borderSize))
        bottom:SetHeight(PixelPerfect(borderSize))
        left:SetWidth(PixelPerfect(borderSize))
        right:SetWidth(PixelPerfect(borderSize))
        for _, line in ipairs(frame._borderSegments) do
            line:SetColorTexture(borderColour.r, borderColour.g, borderColour.b, 1)
            line:SetShown(borderSize > 0)
        end
    end
end

function BCDM:SetupSlashCommands()
    SLASH_BCDM1 = "/bcdm"
    SlashCmdList["BCDM"] = function(msg)
        if msg == "" or msg == "gui" or msg == "options" then BCDM:CreateGUI() end
    end
    BCDM:Print("'|cFF8080FF/bcdm|r' for in-game configuration.")
end

function BCDM:ResolveMedia()
    local LSM = BCDM.LSM
    local GeneralDB = BCDM.db.profile.General
    local PowerBarDB = BCDM.db.profile.PowerBar
    local CastBarDB = BCDM.db.profile.CastBar
    BCDM.Media = BCDM.Media or {}
    BCDM.Media.Font = LSM:Fetch("font", GeneralDB.Font) or STANDARD_TEXT_FONT
    BCDM.Media.PowerBarFGTexture = LSM:Fetch("statusbar", PowerBarDB.FGTexture) or "Interface\\Buttons\\WHITE8X8"
    BCDM.Media.PowerBarBGTexture = LSM:Fetch("statusbar", PowerBarDB.BGTexture) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
    BCDM.Media.CastBarFGTexture = LSM:Fetch("statusbar", CastBarDB.FGTexture) or "Interface\\Buttons\\WHITE8X8"
    BCDM.Media.CastBarBGTexture = LSM:Fetch("statusbar", CastBarDB.BGTexture) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
end

function BCDM:UpdateBCDM()
    BCDM:UpdatePowerBar()
    BCDM:UpdateSecondaryPowerBar()
    BCDM:RefreshAllViewers()
end

function BCDM:CreatePrompt(title, text, onAccept, onCancel, acceptText, cancelText)
    StaticPopupDialogs["BCDM_PROMPT_DIALOG"] = {
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
    local promptDialog = StaticPopup_Show("BCDM_PROMPT_DIALOG", title, text)
    if promptDialog then
        promptDialog.data = { onAccept = onAccept, onCancel = onCancel }
        promptDialog:SetFrameStrata("TOOLTIP")
    end
    return promptDialog
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