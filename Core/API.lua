local _, BCDM = ...
local LEMO = BCDM.LEMO
local Serialize = LibStub:GetLibrary("AceSerializer-3.0")
local Compress = LibStub:GetLibrary("LibDeflate")

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
    local DecodedInfo = Compress:DecodeForPrint(importString:sub(7))
    local DecompressedInfo = Compress:DecompressDeflate(DecodedInfo)
    local success, profileData = Serialize:Deserialize(DecompressedInfo)

    if not success or type(profileData) ~= "table" then BCDM:PrettyPrint("Invalid Import String.") return end

    if type(profileData.profile) == "table" then
        BCDM.db.profiles[profileKey] = profileData.profile
        BCDM.db:SetProfile(profileKey)
        LEMO:LoadLayouts()
        BCDM:UpdateBCDM()
        LEMO:ApplyChanges()
    end
end

-- AddOn Developers can you use this to add their own anchors.
-- Merely call BCDMG:AddAnchors("AddOnName", {"ViewerType1", "ViewerType2"}, { ["AnchorKey"] = "Display Name", ... })
function BCDMG:AddAnchors(addOnName, addToTypes, anchorTable)
    if not C_AddOns.IsAddOnLoaded(addOnName) then return end
    if type(addToTypes) ~= "table" or type(anchorTable) ~= "table" then return end
    for _, typeName in ipairs(addToTypes) do
        if BCDM.AnchorParents[typeName] then
            local displayNames = BCDM.AnchorParents[typeName][1]
            local keyList = BCDM.AnchorParents[typeName][2]
            for anchorKey, displayName in pairs(anchorTable) do
                if not displayNames[anchorKey] then
                    displayNames[anchorKey] = displayName
                    table.insert(keyList, anchorKey)
                end
            end
        end
    end
end