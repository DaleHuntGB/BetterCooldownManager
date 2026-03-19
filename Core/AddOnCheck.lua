local _, BCDM = ...

function BCDM:CheckAddOns()
    local UnsupportedAddOns = {
        -- ["CooldownManagerCentered"] = true,
    }

    for AddOnName in pairs(UnsupportedAddOns) do
        if C_AddOns.IsAddOnLoaded(AddOnName) then
            BCDM:PrettyPrint("You are using: ", AddOnName, " which should not be run alongside |cFF8080FFBetter|rCooldownManager. Please |cFFFF4040disable|r it or |cFF8080FFBetter|rCooldownManager to avoid conflicts.")
            BCDM:PrettyPrint("Disabled until this is resolved.")
            return
        end
    end
end