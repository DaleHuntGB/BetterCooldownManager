local _, BCDM = ...

-- Get Masque library (optional dependency)
local Masque = LibStub("Masque", true)

-- Store Masque groups
BCDM.MasqueGroups = {}

-- Track which buttons have been added to Masque
local skinnedButtons = {}

local function GetButtonData(button)
    -- Build the button data table that Masque needs
    -- Blizzard's cooldown viewer icons are Frames with .Icon and .Cooldown
    local data = {
        Icon = button.Icon,
        Cooldown = button.Cooldown,
    }
    
    -- Only add these if they exist (Buttons have them, Frames don't)
    if button.GetNormalTexture then data.Normal = button:GetNormalTexture() end
    if button.GetPushedTexture then data.Pushed = button:GetPushedTexture() end
    if button.GetHighlightTexture then data.Highlight = button:GetHighlightTexture() end
    if button.Border then data.Border = button.Border end
    if button.IconBorder then data.Border = button.IconBorder end
    
    return data
end

function BCDM:SetupMasque()
    if not Masque then return end
    
    -- Create groups for each viewer type
    BCDM.MasqueGroups.Essential = Masque:Group("BetterCooldownManager", "Essential")
    BCDM.MasqueGroups.Utility = Masque:Group("BetterCooldownManager", "Utility")
    BCDM.MasqueGroups.Buffs = Masque:Group("BetterCooldownManager", "Buffs")
    BCDM.MasqueGroups.Custom = Masque:Group("BetterCooldownManager", "Custom")
    BCDM.MasqueGroups.AdditionalCustom = Masque:Group("BetterCooldownManager", "Additional Custom")
    BCDM.MasqueGroups.Trinket = Masque:Group("BetterCooldownManager", "Trinket")
    BCDM.MasqueGroups.ItemSpell = Masque:Group("BetterCooldownManager", "Item Spells")
    
    BCDM:PrettyPrint("Masque support enabled.")
end

function BCDM:AddButtonToMasque(button, groupName)
    if not Masque then return end
    if not button then return end
    if not BCDM.MasqueGroups[groupName] then return end
    
    -- Skip if already skinned
    if skinnedButtons[button] then return end
    
    local buttonData = GetButtonData(button)
    BCDM.MasqueGroups[groupName]:AddButton(button, buttonData, "Action")
    skinnedButtons[button] = groupName
end

function BCDM:RemoveButtonFromMasque(button)
    if not Masque then return end
    if not button then return end
    
    local groupName = skinnedButtons[button]
    if groupName and BCDM.MasqueGroups[groupName] then
        BCDM.MasqueGroups[groupName]:RemoveButton(button)
        skinnedButtons[button] = nil
    end
end

function BCDM:SkinViewerWithMasque(viewerName)
    if not Masque then return end
    
    local viewerFrame = _G[viewerName]
    if not viewerFrame then return end
    
    local groupName = BCDM.CooldownManagerViewerToDBViewer[viewerName]
    if not groupName then return end
    
    for _, childFrame in ipairs({ viewerFrame:GetChildren() }) do
        if childFrame and childFrame.Icon then
            BCDM:AddButtonToMasque(childFrame, groupName)
        end
    end
end

function BCDM:SkinAllViewersWithMasque()
    if not Masque then return end
    
    -- Skin main viewers
    for _, viewerName in ipairs(BCDM.CooldownManagerViewers) do
        BCDM:SkinViewerWithMasque(viewerName)
    end
    
    -- Skin custom viewers
    if BCDM.CustomCooldownViewerContainer then
        for _, childFrame in ipairs({ BCDM.CustomCooldownViewerContainer:GetChildren() }) do
            if childFrame and childFrame.Icon then
                BCDM:AddButtonToMasque(childFrame, "Custom")
            end
        end
    end
    
    if BCDM.AdditionalCustomCooldownViewerContainer then
        for _, childFrame in ipairs({ BCDM.AdditionalCustomCooldownViewerContainer:GetChildren() }) do
            if childFrame and childFrame.Icon then
                BCDM:AddButtonToMasque(childFrame, "AdditionalCustom")
            end
        end
    end
    
    -- Skin trinket bar
    if BCDM.TrinketBar then
        for _, childFrame in ipairs({ BCDM.TrinketBar:GetChildren() }) do
            if childFrame and childFrame.Icon then
                BCDM:AddButtonToMasque(childFrame, "Trinket")
            end
        end
    end
end

function BCDM:IsMasqueEnabled()
    return Masque ~= nil
end

function BCDM:ReskinMasque()
    if not Masque then return end
    
    -- Force reskin all groups
    for groupName, group in pairs(BCDM.MasqueGroups) do
        if group.ReSkin then
            group:ReSkin()
        end
    end
end
