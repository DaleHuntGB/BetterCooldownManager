local _, BCDM = ...
BCDM.CustomFrames = BCDM.CustomFrames or {}

local CustomSpells = {
    -- Monk
    ["MONK"] = {
        ["BREWMASTER"] = {
            [115203] = { isActive = true, layoutIndex = 1 },        -- Fortifying Brew
            [1241059] = { isActive = true, layoutIndex = 2 },       -- Celestial Infusion
            [322507] = { isActive = true, layoutIndex = 3 },        -- Celestial Brew
        },
        ["WINDWALKER"] = {
            [115203] = { isActive = true, layoutIndex = 1 },        -- Fortifying Brew
            [122470] = { isActive = true, layoutIndex = 2 },        -- Touch of Karma
        },
        ["MISTWEAVER"] = {
            [115203] = { isActive = true, layoutIndex = 1 },        -- Fortifying Brew
        },
    },
    -- Demon Hunter
    ["DEMONHUNTER"] = {
        ["HAVOC"] = {
            [196718] = { isActive = true, layoutIndex = 1 },        -- Darkness
            [198589] = { isActive = true, layoutIndex = 2 },        -- Blur
        },
        ["VENGEANCE"] = {
            [196718] = { isActive = true, layoutIndex = 1 },        -- Darkness
            [203720] = { isActive = true, layoutIndex = 2 },        -- Demon Spikes
        },
        ["DEVOURER"] = {
            [196718] = { isActive = true, layoutIndex = 1 },        -- Darkness
            [198589] = { isActive = true, layoutIndex = 2 },        -- Blur
        },
    },
    -- Death Knight
    ["DEATHKNIGHT"] = {
        ["BLOOD"] = {
            [55233] = { isActive = true, layoutIndex = 1 },         -- Vampiric Blood
            [48707] = { isActive = true, layoutIndex = 2 },         -- Anti-Magic Shell
            [51052] = { isActive = true, layoutIndex = 3 },         -- Anti-Magic Zone
            [49039] = { isActive = true, layoutIndex = 4 },         -- Lichborne
            [48792] = { isActive = true, layoutIndex = 5 },         -- Icebound Fortitude
        },
        ["UNHOLY"] = {
            [48707] = { isActive = true, layoutIndex = 1 },         -- Anti-Magic Shell
            [51052] = { isActive = true, layoutIndex = 2 },         -- Anti-Magic Zone
            [49039] = { isActive = true, layoutIndex = 3 },         -- Lichborne
            [48792] = { isActive = true, layoutIndex = 4 },         -- Icebound Fortitude
        },
        ["FROST"] = {
            [48707] = { isActive = true, layoutIndex = 1 },         -- Anti-Magic Shell
            [51052] = { isActive = true, layoutIndex = 2 },         -- Anti-Magic Zone
            [49039] = { isActive = true, layoutIndex = 3 },         -- Lichborne
            [48792] = { isActive = true, layoutIndex = 4 },         -- Icebound Fortitude
        }
    },
    -- Mage
    ["MAGE"] = {
        ["FROST"] = {
            [342245] = { isActive = true, layoutIndex = 1 },        -- Alter Time
            [11426] = { isActive = true, layoutIndex = 2 },         -- Ice Barrier
            [45438] = { isActive = true, layoutIndex = 3 },         -- Ice Block
        },
        ["FIRE"] = {
            [342245] = { isActive = true, layoutIndex = 1 },        -- Alter Time
            [235313] = { isActive = true, layoutIndex = 2 },        -- Blazing Barrier
            [45438] = { isActive = true, layoutIndex = 3 },         -- Ice Block
        },
        ["ARCANE"] = {
            [342245] = { isActive = true, layoutIndex = 1 },        -- Alter Time
            [235450] = { isActive = true, layoutIndex = 2 },        -- Prismatic Barrier
            [45438] = { isActive = true, layoutIndex = 3 },         -- Ice Block
        },
    },
    -- Paladin
    ["PALADIN"] = {
        ["RETRIBUTION"] = {
            [1022] = { isActive = true, layoutIndex = 1 },          -- Blessing of Protection
            [642] = { isActive = true, layoutIndex = 2 },           -- Divine Shield
            [403876] = { isActive = true, layoutIndex = 3 },        -- Divine Protection
            [6940] = { isActive = true, layoutIndex = 4 },          -- Blessing of Sacrifice
            [633] = { isActive = true, layoutIndex = 5 },           -- Lay on Hands
        },
        ["HOLY"] = {
            [1022] = { isActive = true, layoutIndex = 1 },          -- Blessing of Protection
            [642] = { isActive = true, layoutIndex = 2 },           -- Divine Shield
            [403876] = { isActive = true, layoutIndex = 3 },        -- Divine Protection
            [6940] = { isActive = true, layoutIndex = 4 },          -- Blessing of Sacrifice
            [633] = { isActive = true, layoutIndex = 5 },           -- Lay on Hands
        },
        ["PROTECTION"] = {
            [1022] = { isActive = true, layoutIndex = 1 },          -- Blessing of Protection
            [642] = { isActive = true, layoutIndex = 2 },           -- Divine Shield
            [6940] = { isActive = true, layoutIndex = 3 },          -- Blessing of Sacrifice
            [86659] = { isActive = true, layoutIndex = 4 },         -- Guardian of Ancient Kings
            [31850] = { isActive = true, layoutIndex = 5 },         -- Ardent Defender
            [204018] = { isActive = true, layoutIndex = 6 },        -- Blessing of Spellwarding
            [633] = { isActive = true, layoutIndex = 7 },           -- Lay on Hands
        }
    },
    -- Shaman
    ["SHAMAN"] = {
        ["ELEMENTAL"] = {
            [108271] = { isActive = true, layoutIndex = 1 },        -- Astral Shift
        },
        ["ENHANCEMENT"] = {
            [108271] = { isActive = true, layoutIndex = 1 },        -- Astral Shift
        },
        ["RESTORATION"] = {
            [108271] = { isActive = true, layoutIndex = 1 },        -- Astral Shift
        }
    },
    -- Druid
    ["DRUID"] = {
        ["GUARDIAN"] = {
            [22812] = { isActive = true, layoutIndex = 1 },         -- Barkskin
            [61336] = { isActive = true, layoutIndex = 2 },         -- Survival Instincts
        },
        ["FERAL"] = {
            [22812] = { isActive = true, layoutIndex = 1 },         -- Barkskin
            [61336] = { isActive = true, layoutIndex = 2 },         -- Survival Instincts
        },
        ["RESTORATION"] = {
            [22812] = { isActive = true, layoutIndex = 1 },         -- Barkskin
        },
        ["BALANCE"] = {
            [22812] = { isActive = true, layoutIndex = 1 },         -- Barkskin
        },
    },
    -- Evoker
    ["EVOKER"] = {
        ["DEVASTATION"] = {
            [363916] = { isActive = true, layoutIndex = 1 },        -- Obsidian Scales
            [374227] = { isActive = true, layoutIndex = 2 },        -- Zephyr
        },
        ["AUGMENTATION"] = {
            [363916] = { isActive = true, layoutIndex = 1 },        -- Obsidian Scales
            [374227] = { isActive = true, layoutIndex = 2 },        -- Zephyr
        },
        ["PRESERVATION"] = {
            [363916] = { isActive = true, layoutIndex = 1 },        -- Obsidian Scales
            [374227] = { isActive = true, layoutIndex = 2 },        -- Zephyr
        }
    },
    -- Warrior
    ["WARRIOR"] = {
        ["ARMS"] = {
            [23920] = { isActive = true, layoutIndex = 1 },         -- Spell Reflection
            [97462] = { isActive = true, layoutIndex = 2 },         -- Rallying Cry
            [118038] = { isActive = true, layoutIndex = 3 },        -- Die by the Sword
        },
        ["FURY"] = {
            [23920] = { isActive = true, layoutIndex = 1 },         -- Spell Reflection
            [97462] = { isActive = true, layoutIndex = 2 },         -- Rallying Cry
            [184364] = { isActive = true, layoutIndex = 3 },        -- Enraged Regeneration
        },
        ["PROTECTION"] = {
            [23920] = { isActive = true, layoutIndex = 1 },         -- Spell Reflection
            [97462] = { isActive = true, layoutIndex = 2 },         -- Rallying Cry
            [871] = { isActive = true, layoutIndex = 3 },           -- Shield Wall
        },

    },
    -- Priest
    ["PRIEST"] = {
        ["SHADOW"] = {
            [47585] = { isActive = true, layoutIndex = 1 },         -- Dispersion
            [19236] = { isActive = true, layoutIndex = 2 },         -- Desperate Prayer
            [586] = { isActive = true, layoutIndex = 3 },           -- Fade
        },
        ["DISCIPLINE"] = {
            [19236] = { isActive = true, layoutIndex = 1 },         -- Desperate Prayer
            [586] = { isActive = true, layoutIndex = 2 },           -- Fade
        },
        ["HOLY"] = {
            [19236] = { isActive = true, layoutIndex = 1 },         -- Desperate Prayer
            [586] = { isActive = true, layoutIndex = 2 },           -- Fade
        },
    },
    -- Warlock
    ["WARLOCK"] = {
        ["DESTRUCTION"] = {
            [104773] = { isActive = true, layoutIndex = 1 },        -- Unending Resolve
            [108416] = { isActive = true, layoutIndex = 2 },        -- Dark Pact
        },
        ["AFFLICTION"] = {
            [104773] = { isActive = true, layoutIndex = 1 },        -- Unending Resolve
            [108416] = { isActive = true, layoutIndex = 2 },        -- Dark Pact
        },
        ["DEMONOLOGY"] = {
            [104773] = { isActive = true, layoutIndex = 1 },        -- Unending Resolve
            [108416] = { isActive = true, layoutIndex = 2 },        -- Dark Pact
        },
    },
    -- Hunter
    ["HUNTER"] = {
        ["SURVIVAL"] = {
            [186265] = { isActive = true, layoutIndex = 1 },        -- Aspect of the Turtle
            [264735] = { isActive = true, layoutIndex = 2 },        -- Survival of the Fittest
            [109304] = { isActive = true, layoutIndex = 3 },        -- Exhilaration
            [272682] = { isActive = true, layoutIndex = 4 },        -- Command Pet: Master's Call
            [272678] = { isActive = true, layoutIndex = 5 },        -- Command Pet: Primal Rage
        },
        ["MARKSMANSHIP"] = {
            [186265] = { isActive = true, layoutIndex = 1 },        -- Aspect of the Turtle
            [264735] = { isActive = true, layoutIndex = 2 },        -- Survival of the Fittest
            [109304] = { isActive = true, layoutIndex = 3 },        -- Exhilaration
        },
        ["BEASTMASTERY"] = {
            [186265] = { isActive = true, layoutIndex = 1 },        -- Aspect of the Turtle
            [264735] = { isActive = true, layoutIndex = 2 },        -- Survival of the Fittest
            [109304] = { isActive = true, layoutIndex = 3 },        -- Exhilaration
            [272682] = { isActive = true, layoutIndex = 4 },        -- Command Pet: Master's Call
            [272678] = { isActive = true, layoutIndex = 5 },        -- Command Pet: Primal Rage
        },
    },
    -- Rogue
    ["ROGUE"] = {
        ["OUTLAW"] = {
            [31224] = { isActive = true, layoutIndex = 1 },         -- Cloak of Shadows
            [1966] = { isActive = true, layoutIndex = 2 },          -- Feint
            [5277] = { isActive = true, layoutIndex = 3 },          -- Evasion
            [185311] = { isActive = true, layoutIndex = 4 },        -- Crimson Vial
        },
        ["ASSASSINATION"] = {
            [31224] = { isActive = true, layoutIndex = 1 },         -- Cloak of Shadows
            [1966] = { isActive = true, layoutIndex = 2 },          -- Feint
            [5277] = { isActive = true, layoutIndex = 3 },          -- Evasion
            [185311] = { isActive = true, layoutIndex = 4 },        -- Crimson Vial
        },
        ["SUBTLETY"] = {
            [31224] = { isActive = true, layoutIndex = 1 },         -- Cloak of Shadows
            [1966] = { isActive = true, layoutIndex = 2 },          -- Feint
            [5277] = { isActive = true, layoutIndex = 3 },          -- Evasion
            [185311] = { isActive = true, layoutIndex = 4 },        -- Crimson Vial
        },
    }
}

BCDM.CustomSpells = CustomSpells

function CreateCustomIcon(spellId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.Custom
    if not spellId then return end
    -- if not C_SpellBook.IsSpellKnown(spellId, Enum.SpellBookSpellBank.Player) and not C_SpellBook.IsSpellKnown(spellId, Enum.SpellBookSpellBank.Pet) then return end
    if not C_SpellBook.IsSpellInSpellBook(spellId) then return end

    local customSpellIcon = CreateFrame("Button", "BCDM_Custom_" .. spellId, UIParent, "BackdropTemplate")
    customSpellIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customSpellIcon:SetBackdropBorderColor(0, 0, 0, 1)
    customSpellIcon:SetSize(CustomDB.IconSize[1], CustomDB.IconSize[2])
    customSpellIcon:SetPoint(unpack(CustomDB.Anchors))
    customSpellIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    customSpellIcon:RegisterEvent("PLAYER_ENTERING_WORLD")
    customSpellIcon:RegisterEvent("SPELL_UPDATE_CHARGES")

    local HighLevelContainer = CreateFrame("Frame", nil, customSpellIcon)
    HighLevelContainer:SetAllPoints(customSpellIcon)
    HighLevelContainer:SetFrameLevel(customSpellIcon:GetFrameLevel() + 999)

    customSpellIcon.Charges = HighLevelContainer:CreateFontString(nil, "OVERLAY")
    customSpellIcon.Charges:SetFont(BCDM.Media.Font, CustomDB.Count.FontSize, GeneralDB.FontFlag)
    customSpellIcon.Charges:SetPoint(CustomDB.Count.Anchors[1], customSpellIcon, CustomDB.Count.Anchors[2], CustomDB.Count.Anchors[3], CustomDB.Count.Anchors[4])
    customSpellIcon.Charges:SetTextColor(CustomDB.Count.Colour[1], CustomDB.Count.Colour[2], CustomDB.Count.Colour[3], 1)
    customSpellIcon.Charges:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
    customSpellIcon.Charges:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)

    customSpellIcon.Cooldown = CreateFrame("Cooldown", nil, customSpellIcon, "CooldownFrameTemplate")
    customSpellIcon.Cooldown:SetAllPoints(customSpellIcon)
    customSpellIcon.Cooldown:SetDrawEdge(false)
    customSpellIcon.Cooldown:SetDrawSwipe(true)
    customSpellIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customSpellIcon.Cooldown:SetHideCountdownNumbers(false)
    customSpellIcon.Cooldown:SetReverse(false)

    customSpellIcon:HookScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_ENTERING_WORLD" or event == "SPELL_UPDATE_CHARGES" then
            local spellCharges = C_Spell.GetSpellCharges(spellId)
            if spellCharges then
                customSpellIcon.Charges:SetText(tostring(spellCharges.currentCharges))
                customSpellIcon.Cooldown:SetCooldown(spellCharges.cooldownStartTime, spellCharges.cooldownDuration)
            else
                local cooldownData = C_Spell.GetSpellCooldown(spellId)
                customSpellIcon.Cooldown:SetCooldown(cooldownData.startTime, cooldownData.duration)
            end
        end
    end)

    customSpellIcon.Icon = customSpellIcon:CreateTexture(nil, "BACKGROUND")
    customSpellIcon.Icon:SetPoint("TOPLEFT", customSpellIcon, "TOPLEFT", 1, -1)
    customSpellIcon.Icon:SetPoint("BOTTOMRIGHT", customSpellIcon, "BOTTOMRIGHT", -1, 1)
    customSpellIcon.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
    customSpellIcon.Icon:SetTexture(C_Spell.GetSpellInfo(spellId).iconID)

    return customSpellIcon
end

local LayoutConfig = {
    TOPLEFT     = { anchor="TOPLEFT",   offsetMultiplier=0   },
    TOP         = { anchor="TOP",       offsetMultiplier=0   },
    TOPRIGHT    = { anchor="TOPRIGHT",  offsetMultiplier=0   },
    BOTTOMLEFT  = { anchor="TOPLEFT",   offsetMultiplier=1   },
    BOTTOM      = { anchor="TOP",       offsetMultiplier=1   },
    BOTTOMRIGHT = { anchor="TOPRIGHT",  offsetMultiplier=1   },
    CENTER      = { anchor="CENTER",    offsetMultiplier=0.5, isCenter=true },
    LEFT        = { anchor="LEFT",      offsetMultiplier=0.5, isCenter=true },
    RIGHT       = { anchor="RIGHT",     offsetMultiplier=0.5, isCenter=true },
}

function LayoutCustomIcons()
    local CustomDB = BCDM.db.profile.Custom
    local icons = BCDM.CustomBar
    if not BCDM.CustomContainer then BCDM.CustomContainer = CreateFrame("Frame", "CustomCooldownViewer", UIParent) end
    if #icons == 0 then return end

    local CustomContainer = BCDM.CustomContainer
    local spacing = CustomDB.Spacing
    local iconW   = icons[1]:GetWidth()
    local iconH   = icons[1]:GetHeight()
    local totalW  = (iconW + spacing) * #icons - spacing

    CustomContainer:SetSize(totalW, iconH)
    local layoutConfig = LayoutConfig[CustomDB.Anchors[1]]

    local offsetX = totalW * layoutConfig.offsetMultiplier
    if layoutConfig.isCenter then offsetX = offsetX - iconW / 2 end

    CustomContainer:ClearAllPoints()
    CustomContainer:SetPoint(CustomDB.Anchors[1], CustomDB.Anchors[2], CustomDB.Anchors[3], CustomDB.Anchors[4], CustomDB.Anchors[5])

    local growLeft  = (CustomDB.GrowthDirection == "LEFT")
    for i, icon in ipairs(icons) do
        icon:ClearAllPoints()
        if i == 1 then
            if growLeft then
                icon:SetPoint("RIGHT", CustomContainer, "RIGHT", 0, 0)
            else
                icon:SetPoint("LEFT", CustomContainer, "LEFT", 0, 0)
            end
        else
            local previousIcon = icons[i-1]
            if growLeft then
                icon:SetPoint("RIGHT", previousIcon, "LEFT", -spacing, 0)
            else
                icon:SetPoint("LEFT", previousIcon, "RIGHT", spacing, 0)
            end
        end
    end

    CustomContainer:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    CustomContainer:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            BCDM:ResetCustomIcons()
        end
    end)
end

function BCDM:SetupCustomIcons()
    local CooldownManagerDB = BCDM.db.profile
    wipe(BCDM.CustomFrames)
    wipe(BCDM.CustomBar)
    local _, class = UnitClass("player")
    local specName = select(2, GetSpecializationInfo(GetSpecialization()))
    local spellList = CooldownManagerDB.Custom.CustomSpells[class][specName:upper()] or {}
    local iconOrder = {}
    for spellId, data in pairs(spellList) do
        if data.isActive then
            table.insert(iconOrder, { spellId = spellId, layoutIndex = data.layoutIndex or 9999 })
        end
    end
    table.sort(iconOrder, function(a, b) return a.layoutIndex < b.layoutIndex end)
    for _, entry in ipairs(iconOrder) do
        local frame = CreateCustomIcon(entry.spellId)
        if frame then
            BCDM.CustomFrames[entry.spellId] = frame
            table.insert(BCDM.CustomBar, frame)
        end
    end
    LayoutCustomIcons()
end

function BCDM:ResetCustomIcons()
    local CooldownManagerDB = BCDM.db.profile
    for spellId, frame in pairs(BCDM.CustomFrames) do
        if frame then
            frame:Hide()
            frame:ClearAllPoints()
            frame:SetParent(nil)
            frame:UnregisterAllEvents()
            frame:SetScript("OnUpdate", nil)
            frame:SetScript("OnEvent", nil)
        end
        _G["BCDM_Custom_" .. spellId] = nil
    end
    wipe(BCDM.CustomFrames)
    wipe(BCDM.CustomBar)
    local _, class = UnitClass("player")
    local specName = select(2, GetSpecializationInfo(GetSpecialization()))
    local spellList = CooldownManagerDB.Custom.CustomSpells[class][specName:upper()] or {}
    local iconOrder = {}
    for spellId, data in pairs(spellList) do
        if data.isActive then
            table.insert(iconOrder, { spellId = spellId, layoutIndex = data.layoutIndex or 9999 })
        end
    end
    table.sort(iconOrder, function(a, b) return a.layoutIndex < b.layoutIndex end)
    for _, entry in ipairs(iconOrder) do
        local frame = CreateCustomIcon(entry.spellId)
        if frame then
            BCDM.CustomFrames[entry.spellId] = frame
            table.insert(BCDM.CustomBar, frame)
        end
    end
    LayoutCustomIcons()
end

function BCDM:UpdateCustomIcons()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local CustomDB = CooldownManagerDB.Custom
    BCDM.CustomContainer:ClearAllPoints()
    BCDM.CustomContainer:SetPoint(CustomDB.Anchors[1], CustomDB.Anchors[2], CustomDB.Anchors[3], CustomDB.Anchors[4], CustomDB.Anchors[5])
    for _, icon in ipairs(BCDM.CustomBar) do
        if icon then
            icon:SetSize(CustomDB.IconSize[1], CustomDB.IconSize[2])
            icon.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
            icon.Charges:ClearAllPoints()
            icon.Charges:SetFont(BCDM.Media.Font, CustomDB.Count.FontSize, GeneralDB.FontFlag)
            icon.Charges:SetPoint(CustomDB.Count.Anchors[1], icon, CustomDB.Count.Anchors[2], CustomDB.Count.Anchors[3], CustomDB.Count.Anchors[4])
            icon.Charges:SetTextColor(CustomDB.Count.Colour[1], CustomDB.Count.Colour[2], CustomDB.Count.Colour[3], 1)
            icon.Charges:SetShadowColor(GeneralDB.Shadows.Colour[1], GeneralDB.Shadows.Colour[2], GeneralDB.Shadows.Colour[3], GeneralDB.Shadows.Colour[4])
            icon.Charges:SetShadowOffset(GeneralDB.Shadows.OffsetX, GeneralDB.Shadows.OffsetY)
        end
    end
    LayoutCustomIcons()
end

local SpellsChangedEventFrame = CreateFrame("Frame")
SpellsChangedEventFrame:RegisterEvent("SPELLS_CHANGED")
SpellsChangedEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "SPELLS_CHANGED" then
        if InCombatLockdown() then return end
        BCDM:ResetCustomIcons()
    end
end)

function BCDM:CopyCustomSpellsToDB()
    local profileDB = BCDM.db.profile
    local sourceTable = BCDM.CustomSpells
    local _, class = UnitClass("player")
    profileDB.Custom.CustomSpells[class] = profileDB.Custom.CustomSpells[class] or {}
    for specName, spellList in pairs(sourceTable[class] or {}) do
        profileDB.Custom.CustomSpells[class][specName] = profileDB.Custom.CustomSpells[class][specName] or {}
        for spellId, spellData in pairs(spellList) do
            if profileDB.Custom.CustomSpells[class][specName][spellId] == nil then
                local nextIndex = 1
                for _, existingData in pairs(profileDB.Custom.CustomSpells[class][specName]) do
                    if existingData.layoutIndex and existingData.layoutIndex >= nextIndex then
                        nextIndex = existingData.layoutIndex + 1
                    end
                end
                profileDB.Custom.CustomSpells[class][specName][spellId] = { isActive = spellData.isActive, layoutIndex = spellData.layoutIndex or nextIndex, }
            end
        end
    end
    for specName, spellList in pairs(profileDB.Custom.CustomSpells[class] or {}) do
        local layoutIndex = 1
        local orderedSpells = {}
        for id, data in pairs(spellList) do
            table.insert(orderedSpells, { spellId = id, layoutIndex = data.layoutIndex })
        end
        table.sort(orderedSpells, function(a, b) return a.layoutIndex < b.layoutIndex end)
        for _, entry in ipairs(orderedSpells) do
            spellList[entry.spellId].layoutIndex = layoutIndex
            layoutIndex = layoutIndex + 1
        end
    end
end

function BCDM:AddCustomSpell(value)
    if not value then return end
    local info = C_Spell.GetSpellInfo(value)
    local spellId = info and info.spellID or value
    if not spellId then return end
    local profileDB = BCDM.db.profile
    local _, class = UnitClass("player")
    local specName = select(2, GetSpecializationInfo(GetSpecialization())):upper()
    profileDB.Custom.CustomSpells[class] = profileDB.Custom.CustomSpells[class] or {}
    profileDB.Custom.CustomSpells[class][specName] = profileDB.Custom.CustomSpells[class][specName] or {}
    local specTable = profileDB.Custom.CustomSpells[class][specName]
    local maxIndex = 0
    for _, data in pairs(specTable) do
        if data.layoutIndex and data.layoutIndex > maxIndex then
            maxIndex = data.layoutIndex
        end
    end
    local nextIndex = maxIndex + 1
    specTable[spellId] = { isActive = true, layoutIndex = nextIndex, }
    BCDM:ResetCustomIcons()
end

function BCDM:RemoveCustomSpell(value)
    if not value then return end
    local info = C_Spell.GetSpellInfo(value)
    local spellId = info and info.spellID or value
    if not spellId then return end
    local profileDB = BCDM.db.profile
    local _, class = UnitClass("player")
    local specName = select(2, GetSpecializationInfo(GetSpecialization())):upper()
    local specTable = profileDB.Custom.CustomSpells[class] and profileDB.Custom.CustomSpells[class][specName]
    if not specTable then return end
    specTable[spellId] = nil
    local layoutIndex = 1
    local orderedSpells = {}
    for id, data in pairs(specTable) do
        table.insert(orderedSpells, { spellId = id, layoutIndex = data.layoutIndex })
    end
    table.sort(orderedSpells, function(a, b) return a.layoutIndex < b.layoutIndex end)
    for _, entry in ipairs(orderedSpells) do
        specTable[entry.spellId].layoutIndex = layoutIndex
        layoutIndex = layoutIndex + 1
    end
    BCDM:ResetCustomIcons()
end

function BCDM:ResetCustomSpells()
    local profileDB = BCDM.db.profile
    local _, class = UnitClass("player")
    local specName = select(2, GetSpecializationInfo(GetSpecialization())):upper()
    if profileDB.Custom.CustomSpells[class] then
        profileDB.Custom.CustomSpells[class][specName] = nil
    end
    BCDM:CopyCustomSpellsToDB()
    BCDM:ResetCustomIcons()
end

function BCDM:MoveCustomSpell(spellId, value)
    if not spellId or not value then return end
    local profileDB = BCDM.db.profile
    local _, class = UnitClass("player")
    local specName = select(2, GetSpecializationInfo(GetSpecialization())):upper()
    local specTable = profileDB.Custom.CustomSpells[class] and profileDB.Custom.CustomSpells[class][specName]
    if not specTable or not specTable[spellId] then return end
    if specTable[spellId].layoutIndex + value < 1 then return end
    for _, data in pairs(specTable) do
        if data.layoutIndex == specTable[spellId].layoutIndex + value then
            data.layoutIndex = specTable[spellId].layoutIndex
            break
        end
    end
    specTable[spellId].layoutIndex = specTable[spellId].layoutIndex + value
    BCDM:ResetCustomIcons()
end