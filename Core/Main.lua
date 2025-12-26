local _, BCDM = ...
local AddOn = LibStub("AceAddon-3.0"):NewAddon("BetterCooldownManager")

function AddOn:OnInitialize()
    BCDM.db = LibStub("AceDB-3.0"):New("BetterCDMDB", BCDM.Defaults, true)
    for key, value in pairs(BCDM.Defaults) do
        if BCDM.db.profile[key] == nil then
            BCDM.db.profile[key] = value
        end
    end
    if BCDM.db.global.UseGlobalProfile then BCDM.db:SetProfile(BCDM.db.global.GlobalProfile or "Default") end
end

local WaitForAddOns = CreateFrame("Frame")
WaitForAddOns:RegisterEvent("PLAYER_LOGIN")
WaitForAddOns:SetScript("OnEvent", function(self)
    if C_AddOns.IsAddOnLoaded("UnhaltedUnitFrames") then
        BCDM:SetupCustomIcons()
        BCDM:SetupAdditionalCustomIcons()
        BCDM:SetupItemIcons()
    end
    self:UnregisterEvent("PLAYER_LOGIN")
end)

function AddOn:OnEnable()
    BCDM:SetupSlashCommands()
    BCDM:ResolveMedia()
    BCDM:SetEditMode(BCDM.db.global.LayoutNumber)
    BCDM:SetupCooldownManager()
    BCDM:SetupPowerBar()
    BCDM:SetupSecondaryPowerBar()
    BCDM:SetupCastBar()
end