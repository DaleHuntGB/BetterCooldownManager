local _, BCDM = ...
local LEMO = LibStub("LibEditModeOverride-1.0")

function BCDM:SetupEventManager()
    local BCDMEventManager = CreateFrame("Frame", "BCDMEventManagerFrame")
    BCDMEventManager:RegisterEvent("PLAYER_ENTERING_WORLD")
    BCDMEventManager:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    BCDMEventManager:RegisterEvent("TRAIT_CONFIG_UPDATED")
    BCDMEventManager:SetScript("OnEvent", function() C_Timer.After(0.5, function() 
        BCDM:UpdateBCDM() 
        if not InCombatLockdown() then 
            pcall(LEMO.ApplyChanges, LEMO)
        end 
    end) end)
end