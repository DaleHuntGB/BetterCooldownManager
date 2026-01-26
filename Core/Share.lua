local _, BCDM = ...
local Serialize = LibStub:GetLibrary("AceSerializer-3.0")
local Compress = LibStub:GetLibrary("LibDeflate")
local LEMO = BCDM.LEMO

function BCDM:ExportSavedVariables()
    local profileData = { profile = BCDM.db.profile, }
    local SerializedInfo = Serialize:Serialize(profileData)
    local CompressedInfo = Compress:CompressDeflate(SerializedInfo)
    local EncodedInfo = Compress:EncodeForPrint(CompressedInfo)
    EncodedInfo = "!BCDM_"..EncodedInfo
    return EncodedInfo
end

function BCDM:ImportSavedVariables(encodedInfo, profileName)
    if type(encodedInfo) ~= "string" or encodedInfo:sub(1, 6) ~= "!BCDM_" then BCDM:PrettyPrint("Invalid Import String.") return end
    local decodedInfo = Compress:DecodeForPrint(encodedInfo:sub(7))
    if not decodedInfo then BCDM:PrettyPrint("Invalid Import String.") return end
    local decompressedInfo = Compress:DecompressDeflate(decodedInfo)
    if not decompressedInfo then BCDM:PrettyPrint("Invalid Import String.") return end
    local success, data = Serialize:Deserialize(decompressedInfo)
    if not success or type(data) ~= "table" then BCDM:PrettyPrint("Invalid Import String.") return end
    if profileName then
        BCDM.db:SetProfile(profileName)
        wipe(BCDM.db.profile)
        for key, value in pairs(data.profile or {}) do
            BCDM.db.profile[key] = value
        end
        BCDMG.RefreshProfiles()
        LEMO:LoadLayouts()
        BCDM:UpdateBCDM()
        LEMO:ApplyChanges()
        return
    end
    StaticPopupDialogs["BCDM_IMPORT_NEW_PROFILE"] = {
        text = BCDM.ADDON_NAME.." - Profile Name?",
        button1 = "Import",
        button2 = "Cancel",
        hasEditBox = true,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function(self)
            local name = self.EditBox:GetText()
            if not name or name == "" then
                BCDM:PrettyPrint("Please enter a valid profile name.")
                return
            end
            BCDM.db:SetProfile(name)
            wipe(BCDM.db.profile)
            for key, value in pairs(data.profile or {}) do
                BCDM.db.profile[key] = value
            end
            BCDMG.RefreshProfiles()
            LEMO:LoadLayouts()
            BCDM:UpdateBCDM()
            LEMO:ApplyChanges()
        end,
    }

    StaticPopup_Show("BCDM_IMPORT_NEW_PROFILE")
end