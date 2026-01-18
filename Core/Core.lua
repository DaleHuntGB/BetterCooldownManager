local _, BCDM = ...
local BetterCooldownManager = LibStub("AceAddon-3.0"):NewAddon("BetterCooldownManager")

local SUPPORTED_ADDONS = {
    [1] = "BetterBlizzardFrames",
    [2] = "Cell",
    [3] = "ElvUI",
    [4] = "MidnightSimpleUnitFrames",
    [5] = "UnhaltedUnitFrames",
}

function BetterCooldownManager:OnInitialize()
    BCDM.db = LibStub("AceDB-3.0"):New("BCDMDB", BCDM:GetDefaultDB(), true)
    BCDM.LDS:EnhanceDatabase(BCDM.db, "UnhaltedUnitFrames")
    for k, v in pairs(BCDM:GetDefaultDB()) do
        if BCDM.db.profile[k] == nil then
            BCDM.db.profile[k] = v
        end
    end
    if BCDM.db.global.UseGlobalProfile then BCDM.db:SetProfile(BCDM.db.global.GlobalProfile or "Default") end
    BCDM.db.RegisterCallback(BCDM, "OnProfileChanged", function() BCDM:UpdateBCDM() end)
end

function BetterCooldownManager:OnEnable()
    BCDM:Init()
    BCDM:SetupEventManager()
    BCDM:SkinCooldownManager()
    BCDM:CreatePowerBar()
    BCDM:CreateSecondaryPowerBar()
    BCDM:CreateCastBar()
    for _, AddOn in ipairs(SUPPORTED_ADDONS) do
        EventUtil.ContinueOnAddOnLoaded(AddOn, function()
            BCDM:SetupCustomCooldownViewer()
            BCDM:SetupAdditionalCustomCooldownViewer()
            BCDM:SetupCustomItemBar()
            BCDM:SetupTrinketBar()
            BCDM:CreateCooldownViewerOverlays()
        end)
    end
    BCDM:SetupEditModeManager()
end