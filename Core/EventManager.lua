local _, BCDM = ...
local LEMO = LibStub("LibEditModeOverride-1.0")

function BCDM:SetupEventManager()
    local BCDMEventManager = CreateFrame("Frame", "BCDMEventManagerFrame")
    BCDMEventManager:RegisterEvent("PLAYER_ENTERING_WORLD")
    BCDMEventManager:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    BCDMEventManager:RegisterEvent("TRAIT_CONFIG_UPDATED")
    BCDMEventManager:RegisterEvent("SPELLS_CHANGED")
    BCDMEventManager:SetScript("OnEvent", function(_, event, ...)
        if InCombatLockdown() then return end
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            local unit = ...
            if unit ~= "player" then return end
            -- Only apply LEMO changes here; wait for SPELLS_CHANGED to update cooldown viewers
            LEMO:ApplyChanges()
        elseif event == "SPELLS_CHANGED" then
            -- Spellbook is now ready - safe to call UpdateBCDM
            BCDM:UpdateBCDM()
        elseif event == "TRAIT_CONFIG_UPDATED" then
            -- Talents changed - wait for SPELLS_CHANGED to fire
            -- (no action needed here, SPELLS_CHANGED will follow)
        else
            -- PLAYER_ENTERING_WORLD
            BCDM:UpdateBCDM()
        end
    end)
end