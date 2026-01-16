local _, BCDM = ...
local Serialize = LibStub:GetLibrary("AceSerializer-3.0")
local Compress = LibStub:GetLibrary("LibDeflate")

function BCDM:ExportSavedVariables()
    local profileData = { profile = BCDM.db.profile, }
    local SerializedInfo = Serialize:Serialize(profileData)
    local CompressedInfo = Compress:CompressDeflate(SerializedInfo)
    local EncodedInfo = Compress:EncodeForPrint(CompressedInfo)
    EncodedInfo = "!BCDM_"..EncodedInfo
    return EncodedInfo
end

function BCDM:ImportSavedVariables(EncodedInfo, profileName)
    local DecodedInfo = Compress:DecodeForPrint(EncodedInfo:sub(6))
    local DecompressedInfo = Compress:DecompressDeflate(DecodedInfo)
    local success, data = Serialize:Deserialize(DecompressedInfo)
    if not success or type(data) ~= "table" or EncodedInfo:sub(1, 5) ~= "!BCDM_" then print("|cFF8080FFUnhalted|r Unit Frames: Invalid Import String.") return end

    if profileName then
        BCDM.db:SetProfile(profileName)
        wipe(BCDM.db.profile)

        if type(data.profile) == "table" then
            for key, value in pairs(data.profile) do
                BCDM.db.profile[key] = value
            end
        end

        BCDMG.RefreshProfiles()

        UIParent:SetScale(BCDM.db.profile.General.UIScale or 1)
    else
        StaticPopupDialogs["BCDM_IMPORT_NEW_PROFILE"] = {
            text = BCDM.ADDON_NAME.." - ".."Profile Name?",
            button1 = "Import",
            button2 = "Cancel",
            hasEditBox = true,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function(self)
                local editBox = self.editBox or self.EditBox
                local newProfileName = editBox:GetText() or string.format("Imported_%s-%s-%s", date("%d"), date("%m"), date("%Y"))
                if not newProfileName or newProfileName == "" then BCDM:Print("Please enter a valid profile name.") return end

                BCDM.db:SetProfile(newProfileName)
                wipe(BCDM.db.profile)

                if type(data.profile) == "table" then
                    for key, value in pairs(data.profile) do
                        BCDM.db.profile[key] = value
                    end
                end

                BCDMG.RefreshProfiles()

            end,
        }
        StaticPopup_Show("BCDM_IMPORT_NEW_PROFILE")
    end

end

function BCDMG:ExportBCDM(profileKey)
    local profile = BCDM.db.profiles[profileKey]
    if not profile then return nil end

    local profileData = { profile = profile, }

    local SerializedInfo = Serialize:Serialize(profileData)
    local CompressedInfo = Compress:CompressDeflate(SerializedInfo)
    local EncodedInfo = Compress:EncodeForPrint(CompressedInfo)
    EncodedInfo = "!BCDM_" .. EncodedInfo
    return EncodedInfo
end

function BCDMG:ImportBCDM(importString, profileKey)
    local DecodedInfo = Compress:DecodeForPrint(importString:sub(6))
    local DecompressedInfo = Compress:DecompressDeflate(DecodedInfo)
    local success, profileData = Serialize:Deserialize(DecompressedInfo)

    if not success or type(profileData) ~= "table" then print("|cFF8080FFUnhalted|r Unit Frames: Invalid Import String.") return end

    if type(profileData.profile) == "table" then
        BCDM.db.profiles[profileKey] = profileData.profile
        BCDM.db:SetProfile(profileKey)
    end
end