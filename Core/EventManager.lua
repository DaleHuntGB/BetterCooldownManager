local _, BCDM = ...
local LEMO = LibStub("LibEditModeOverride-1.0")

function BCDM:SetupEventManager()
    local BCDMEventManager = CreateFrame("Frame", "BCDMEventManagerFrame")
    local updatePending = false
    local throttleTimer = nil

    local function ApplyPendingChanges()
        if InCombatLockdown() then
            updatePending = true
            return
        end

        if updatePending then
            LEMO:ApplyChanges()
            updatePending = false
        end
        throttleTimer = nil
    end

    local function ScheduleUpdate()
        updatePending = true
        if InCombatLockdown() then return end
        if throttleTimer then throttleTimer:Cancel() end
        throttleTimer = C_Timer.After(2, ApplyPendingChanges)
    end

    BCDMEventManager:RegisterEvent("PLAYER_ENTERING_WORLD")
    BCDMEventManager:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    BCDMEventManager:RegisterEvent("TRAIT_CONFIG_UPDATED")
    BCDMEventManager:RegisterEvent("PLAYER_REGEN_ENABLED")
    BCDMEventManager:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_REGEN_ENABLED" then
            if throttleTimer then throttleTimer:Cancel() end
            throttleTimer = C_Timer.After(0.2, ApplyPendingChanges)
            return
        end
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            local unit = ...
            if unit ~= "player" then return end
            BCDM:UpdateBCDM()
            ScheduleUpdate()
        else
            BCDM:UpdateBCDM()
            ScheduleUpdate()
        end
    end)
end
