local _, BCDM = ...

local LAB = LibStub and LibStub("LibActionButton-1.0", true)
local pressedHighlightsByButton = {}
local trackedHighlightIcons = setmetatable({}, { __mode = "k" })
local activeHighlightedIcons = setmetatable({}, { __mode = "k" })
local defaultHooksInstalled = false
local labCallbacksRegistered = false
local elvUICallbacksRegistered = false
local dominosCallbacksRegistered = false
local buttonHookEventFrame

local function GetHighlightDB()
    local globalDB = BCDM.db and BCDM.db.global
    if not globalDB then
        return nil
    end

    globalDB.CooldownButtonHighlight = globalDB.CooldownButtonHighlight or {}
    local highlightDB = globalDB.CooldownButtonHighlight

    if highlightDB.Border == true then
        highlightDB.Style = "Border"
    end
    highlightDB.Border = nil

    if highlightDB.Enabled == nil then highlightDB.Enabled = false end
    if not highlightDB.Style then highlightDB.Style = "Blizzard" end
    if highlightDB.Opacity == nil then highlightDB.Opacity = 0.35 end
    if type(highlightDB.Colour) ~= "table" then highlightDB.Colour = {1, 1, 1} end

    return highlightDB
end

local function IsEnabled()
    local highlightDB = GetHighlightDB()
    return highlightDB and highlightDB.Enabled
end

local function GetViewerNames()
    return {
        "EssentialCooldownViewer",
        "UtilityCooldownViewer",
        "CDMGroups_Essential",
        "CDMGroups_Utility",
    }
end

local function CreateSpellIDCollection(spellID)
    if not spellID then return nil end

    local collection = {}
    collection[spellID] = true

    if C_Spell and C_Spell.GetOverrideSpell then
        local overrideSpell = C_Spell.GetOverrideSpell(spellID)
        if overrideSpell and overrideSpell > 0 then
            collection[overrideSpell] = true
        end
    end

    if C_Spell and C_Spell.GetBaseSpell then
        local baseSpell = C_Spell.GetBaseSpell(spellID)
        if baseSpell and baseSpell > 0 then
            collection[baseSpell] = true
        end
    end

    return collection
end

local function GetSpellIDFromCooldownId(cooldownID)
    if not cooldownID or type(cooldownID) ~= "number" or not C_CooldownViewer or not C_CooldownViewer.GetCooldownViewerCooldownInfo then
        return nil
    end

    local cooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    return cooldownInfo and cooldownInfo.spellID or nil
end

local function AddMatchedIcon(matches, seenIcons, icon)
    if not icon or seenIcons[icon] then
        return
    end

    seenIcons[icon] = true
    matches[#matches + 1] = icon
end

local function CollectDefaultViewerMatches(matches, seenIcons, spellIDCollection)
    if not spellIDCollection then
        return
    end

    for _, viewerName in ipairs(GetViewerNames()) do
        local viewerFrame = _G[viewerName]
        if viewerFrame then
            local cooldownIcons = viewerFrame.ActiveIcons or { viewerFrame:GetChildren() }
            for _, icon in ipairs(cooldownIcons) do
                if icon and icon.Icon and icon.IsShown and icon:IsShown() then
                    local iconSpellID

                    if icon.cooldownID then
                        iconSpellID = GetSpellIDFromCooldownId(icon.cooldownID)
                    end

                    if not iconSpellID and icon.GetSpellID then
                        local isSafe, resolvedSpellID = pcall(icon.GetSpellID, icon)
                        if isSafe and type(resolvedSpellID) == "number" then
                            iconSpellID = resolvedSpellID
                        end
                    end

                    if iconSpellID and spellIDCollection[iconSpellID] then
                        AddMatchedIcon(matches, seenIcons, icon)
                    end
                end
            end
        end
    end
end

local function CustomViewerIconMatches(icon, spellIDCollection, itemIDCollection)
    if not icon or not icon.Icon then
        return false
    end

    if icon.BCDMIconType == "spell" then
        return spellIDCollection and icon.BCDMSpellId and spellIDCollection[icon.BCDMSpellId] or false
    end

    if icon.BCDMIconType == "item" or icon.BCDMIconType == "trinket" then
        if itemIDCollection and icon.BCDMItemId and itemIDCollection[icon.BCDMItemId] then
            return true
        end

        if spellIDCollection and icon.BCDMItemId and C_Item and C_Item.GetItemSpell then
            local _, itemSpellID = C_Item.GetItemSpell(icon.BCDMItemId)
            return itemSpellID and spellIDCollection[itemSpellID] or false
        end
    end

    return false
end

local function CollectCustomViewerMatches(matches, seenIcons, spellIDCollection, itemIDCollection)
    local customFrames = BCDM.CustomItemSpellContainerFrames or {}
    for _, frame in pairs(customFrames) do
        local icons = frame and (frame.ActiveIcons or { frame:GetChildren() }) or nil
        for _, icon in ipairs(icons or {}) do
            if icon and icon.IsShown and icon:IsShown() and CustomViewerIconMatches(icon, spellIDCollection, itemIDCollection) then
                AddMatchedIcon(matches, seenIcons, icon)
            end
        end
    end

    local trinketContainer = BCDM.TrinketBarContainer
    local trinketIcons = trinketContainer and (trinketContainer.ActiveIcons or { trinketContainer:GetChildren() }) or nil
    for _, icon in ipairs(trinketIcons or {}) do
        if icon and icon.IsShown and icon:IsShown() and CustomViewerIconMatches(icon, spellIDCollection, itemIDCollection) then
            AddMatchedIcon(matches, seenIcons, icon)
        end
    end

end

function BCDM:GetCooldownViewerHighlightTargets(button)
    if not button or not button.action then
        return nil
    end

    local actionType, actionID = GetActionInfo(button.action)
    local spellID, itemID

    if actionType == "spell" then
        spellID = actionID
    elseif actionType == "item" then
        itemID = actionID
        if C_Item and C_Item.GetItemSpell then
            local _, itemSpellID = C_Item.GetItemSpell(itemID)
            spellID = itemSpellID or spellID
        end
    elseif actionType == "macro" then
        local macroName = GetActionText(button.action)
        if macroName then
            spellID = GetMacroSpell(macroName)
        end
    end

    if not spellID and not itemID then
        return nil
    end

    local spellIDCollection = spellID and CreateSpellIDCollection(spellID) or nil
    local itemIDCollection = itemID and { [itemID] = true } or nil
    local matches = {}
    local seenIcons = {}

    CollectDefaultViewerMatches(matches, seenIcons, spellIDCollection)
    CollectCustomViewerMatches(matches, seenIcons, spellIDCollection, itemIDCollection)

    return #matches > 0 and matches or nil
end

local function ApplyHighlightAppearance(textureFrame)
    if not textureFrame or not textureFrame.texture then
        return
    end

    local highlightDB = GetHighlightDB()
    local style = highlightDB and highlightDB.Style or "Blizzard"
    local opacity = highlightDB and tonumber(highlightDB.Opacity) or 0.35
    local colour = (highlightDB and highlightDB.Colour) or {1, 1, 1}
    local r = tonumber(colour[1]) or 1
    local g = tonumber(colour[2]) or 1
    local b = tonumber(colour[3]) or 1
    local borderInset = math.max(tonumber(BCDM.db and BCDM.db.profile and BCDM.db.profile.CooldownManager and BCDM.db.profile.CooldownManager.General and BCDM.db.profile.CooldownManager.General.BorderSize) or 0, 0)
    opacity = math.min(math.max(opacity or 0.35, 0), 1)

    textureFrame.texture:ClearAllPoints()
    textureFrame.texture:SetPoint("TOPLEFT", textureFrame, "TOPLEFT", borderInset, -borderInset)
    textureFrame.texture:SetPoint("BOTTOMRIGHT", textureFrame, "BOTTOMRIGHT", -borderInset, borderInset)
    textureFrame:SetAlpha(opacity)

    if style == "Border" then
        textureFrame.texture:SetAtlas(nil)
        textureFrame.texture:SetTexture(nil)
    elseif style == "Flat" then
        textureFrame.texture:SetAtlas(nil)
        textureFrame.texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        textureFrame.texture:SetTexCoord(0, 1, 0, 1)
        textureFrame.texture:SetVertexColor(r, g, b, 1)
        textureFrame.texture:SetBlendMode("ADD")
    else
        textureFrame.texture:SetTexture(nil)
        textureFrame.texture:SetAtlas("UI-HUD-ActionBar-IconFrame-Down", true)
        textureFrame.texture:SetVertexColor(r, g, b, 1)
        textureFrame.texture:SetBlendMode("BLEND")
    end

    if textureFrame.borderLines then
        local topBorder, bottomBorder, leftBorder, rightBorder = unpack(textureFrame.borderLines)
        if topBorder and bottomBorder and leftBorder and rightBorder then
            topBorder:ClearAllPoints()
            topBorder:SetPoint("TOPLEFT", textureFrame, "TOPLEFT", borderInset, -borderInset)
            topBorder:SetPoint("TOPRIGHT", textureFrame, "TOPRIGHT", -borderInset, -borderInset)

            bottomBorder:ClearAllPoints()
            bottomBorder:SetPoint("BOTTOMLEFT", textureFrame, "BOTTOMLEFT", borderInset, borderInset)
            bottomBorder:SetPoint("BOTTOMRIGHT", textureFrame, "BOTTOMRIGHT", -borderInset, borderInset)

            leftBorder:ClearAllPoints()
            leftBorder:SetPoint("TOPLEFT", textureFrame, "TOPLEFT", borderInset, -borderInset)
            leftBorder:SetPoint("BOTTOMLEFT", textureFrame, "BOTTOMLEFT", borderInset, borderInset)

            rightBorder:ClearAllPoints()
            rightBorder:SetPoint("TOPRIGHT", textureFrame, "TOPRIGHT", -borderInset, -borderInset)
            rightBorder:SetPoint("BOTTOMRIGHT", textureFrame, "BOTTOMRIGHT", -borderInset, borderInset)
        end

        for _, borderLine in ipairs(textureFrame.borderLines) do
            borderLine:SetColorTexture(r, g, b, opacity)
            borderLine:SetShown(style == "Border")
        end
    end
end

local function CreateOrGetHighlightFrame(icon)
    if not icon then return nil end
    if icon.BCDMCooldownButtonHighlight then
        ApplyHighlightAppearance(icon.BCDMCooldownButtonHighlight)
        return icon.BCDMCooldownButtonHighlight
    end

    local frame = CreateFrame("Frame", nil, icon)
    frame:SetFrameStrata(icon:GetFrameStrata())
    frame:SetFrameLevel(icon:GetFrameLevel() + 10)
    frame:SetAllPoints(icon)

    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(frame)
    frame.texture = texture
    frame.borderLines = {}

    local topBorder = frame:CreateTexture(nil, "OVERLAY")
    topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    topBorder:SetHeight(1)
    frame.borderLines[#frame.borderLines + 1] = topBorder

    local bottomBorder = frame:CreateTexture(nil, "OVERLAY")
    bottomBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetHeight(1)
    frame.borderLines[#frame.borderLines + 1] = bottomBorder

    local leftBorder = frame:CreateTexture(nil, "OVERLAY")
    leftBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    leftBorder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    leftBorder:SetWidth(1)
    frame.borderLines[#frame.borderLines + 1] = leftBorder

    local rightBorder = frame:CreateTexture(nil, "OVERLAY")
    rightBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetWidth(1)
    frame.borderLines[#frame.borderLines + 1] = rightBorder

    frame:Hide()

    icon.BCDMCooldownButtonHighlight = frame
    trackedHighlightIcons[icon] = true

    ApplyHighlightAppearance(frame)

    return frame
end

local function ToggleHighlight(icon, show)
    if not icon then return end

    local highlightFrame = CreateOrGetHighlightFrame(icon)
    if not highlightFrame then
        return
    end

    if show and IsEnabled() then
        ApplyHighlightAppearance(highlightFrame)
        highlightFrame:Show()
        activeHighlightedIcons[icon] = true
    else
        highlightFrame:Hide()
        activeHighlightedIcons[icon] = nil
    end
end

local function ClearAllHighlights()
    for icon in pairs(activeHighlightedIcons) do
        if icon and icon.BCDMCooldownButtonHighlight then
            icon.BCDMCooldownButtonHighlight:Hide()
        end
        activeHighlightedIcons[icon] = nil
    end
end

local function RefreshHighlightFrames()
    for icon in pairs(trackedHighlightIcons) do
        local highlightFrame = icon and icon.BCDMCooldownButtonHighlight
        if highlightFrame then
            ApplyHighlightAppearance(highlightFrame)
            if not IsEnabled() then
                highlightFrame:Hide()
                activeHighlightedIcons[icon] = nil
            end
        end
    end
end

function BCDM:HandleCooldownButtonHighlightPress(button, isDown)
    if not button then
        return
    end

    if not IsEnabled() then
        if not isDown then
            pressedHighlightsByButton[button] = nil
        end
        return
    end

    if isDown then
        local matchedIcons = self:GetCooldownViewerHighlightTargets(button)
        if not matchedIcons then return end

        pressedHighlightsByButton[button] = matchedIcons

        for _, icon in ipairs(matchedIcons) do
            ToggleHighlight(icon, true)
        end
        return
    end

    local matchedIcons = pressedHighlightsByButton[button]
    pressedHighlightsByButton[button] = nil
    if not matchedIcons then return end

    for _, icon in ipairs(matchedIcons) do
        ToggleHighlight(icon, false)
    end
end

local function HookButtonPreClick(button)
    if not button or button.BCDMCooldownButtonHighlightHooked then
        return
    end

    button:HookScript("PreClick", function(self, _, down)
        BCDM:HandleCooldownButtonHighlightPress(self, down)
    end)
    button.BCDMCooldownButtonHighlightHooked = true
end

local function HookDominosButton(button)
    if not button then
        return
    end

    if button.bind and not button.BCDMCooldownButtonHighlightBindHooked then
        button.bind:HookScript("PreClick", function(_, _, down)
            BCDM:HandleCooldownButtonHighlightPress(button, down)
        end)
        button.BCDMCooldownButtonHighlightBindHooked = true
    end

    HookButtonPreClick(button)
end

local function HookAllLABButtons()
    if not LAB or not LAB.activeButtons then
        return
    end

    for button in pairs(LAB.activeButtons) do
        HookButtonPreClick(button)
    end
end

local function RegisterLABCallbacks()
    if not LAB or labCallbacksRegistered then
        return
    end

    labCallbacksRegistered = true
    LAB:RegisterCallback("OnButtonUpdate", function(_, button)
        HookButtonPreClick(button)
    end)
end

local function RegisterElvUICallbacks()
    if elvUICallbacksRegistered then
        return
    end

    local ElvUI = _G.ElvUI and _G.ElvUI[1]
    local ElvUILAB = ElvUI and ElvUI.Libs and ElvUI.Libs.LAB
    if not ElvUILAB then
        return
    end

    elvUICallbacksRegistered = true
    ElvUILAB:RegisterCallback("OnButtonUpdate", function(_, button)
        HookButtonPreClick(button)
    end)
end

local function HookAllDominosButtons()
    local Dominos = _G.Dominos
    if not Dominos or not Dominos.ActionButtons or not Dominos.ActionButtons.GetAll then
        return
    end

    for button in Dominos.ActionButtons:GetAll() do
        HookDominosButton(button)
    end
end

local function RegisterDominosCallbacks()
    if dominosCallbacksRegistered then
        return
    end

    local Dominos = _G.Dominos
    if not Dominos or not Dominos.RegisterCallback then
        return
    end

    dominosCallbacksRegistered = true
    Dominos:RegisterCallback("LAYOUT_LOADED", function()
        HookAllDominosButtons()
    end)
end

local function InstallDefaultActionButtonHooks()
    if defaultHooksInstalled then
        return
    end

    defaultHooksInstalled = true

    hooksecurefunc("ActionButtonDown", function(id)
        BCDM:HandleCooldownButtonHighlightPress(_G["ActionButton" .. id], true)
    end)

    hooksecurefunc("ActionButtonUp", function(id)
        BCDM:HandleCooldownButtonHighlightPress(_G["ActionButton" .. id], false)
    end)

    hooksecurefunc("MultiActionButtonDown", function(bar, id)
        BCDM:HandleCooldownButtonHighlightPress(_G[bar .. "Button" .. id], true)
    end)

    hooksecurefunc("MultiActionButtonUp", function(bar, id)
        BCDM:HandleCooldownButtonHighlightPress(_G[bar .. "Button" .. id], false)
    end)
end

function BCDM:SetupCooldownButtonHighlight()
    if not buttonHookEventFrame then
        buttonHookEventFrame = CreateFrame("Frame")
        buttonHookEventFrame:RegisterEvent("PLAYER_LOGIN")
        buttonHookEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        buttonHookEventFrame:RegisterEvent("ADDON_LOADED")
        buttonHookEventFrame:SetScript("OnEvent", function(_, event, addonName)
            if event == "ADDON_LOADED" then
                if addonName == "Dominos" then
                    RegisterDominosCallbacks()
                    HookAllDominosButtons()
                elseif addonName == "ElvUI" then
                    RegisterElvUICallbacks()
                end
                return
            end

            RegisterLABCallbacks()
            HookAllLABButtons()
            RegisterElvUICallbacks()
            RegisterDominosCallbacks()
            HookAllDominosButtons()
        end)
    end

    InstallDefaultActionButtonHooks()
    RegisterLABCallbacks()
    HookAllLABButtons()
    RegisterElvUICallbacks()
    RegisterDominosCallbacks()
    HookAllDominosButtons()
    self:UpdateCooldownButtonHighlight()
end

function BCDM:UpdateCooldownButtonHighlight()
    if not GetHighlightDB() then
        return
    end

    RefreshHighlightFrames()
    if not IsEnabled() then
        ClearAllHighlights()
    end
end
