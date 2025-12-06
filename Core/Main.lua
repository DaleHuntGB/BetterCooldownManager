local _, BCDM = ...
local AddOn = LibStub("AceAddon-3.0"):NewAddon("BetterCooldownManager")

function AddOn:OnInitialize()
    BCDM.db = LibStub("AceDB-3.0"):New("BetterCDMDB", BCDM.Defaults, true)
    for key, value in pairs(BCDM.Defaults) do
        if BCDM.db.profile[key] == nil then
            BCDM.db.profile[key] = value
        end
    end
    if BCDM.db.profile.UseGlobalProfile then BCDM.db:SetProfile(BCDM.db.profile.GlobalProfile or "Default") end
end

function AddOn:OnEnable()
    BCDM:SetupSlashCommands()
    BCDM:ResolveMedia()
    BCDM:SetupCooldownManager()
    BCDM:SetupPowerBar()
    BCDM:SetupSecondaryPowerBar()
    BCDM:SetupCastBar()
end