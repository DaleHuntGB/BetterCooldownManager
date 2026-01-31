local _, BCDM = ...

local DEFENSIVE_SPELLS = {
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

local ITEMS = {
    [241304] = { isActive = true, layoutIndex = 1 }, -- Silvermoon Healing Potion
    [241308] = { isActive = true, layoutIndex = 2 }, -- Light's Potential
    [5512]   = { isActive = true, layoutIndex = 3 }, -- Healthstone
}

local RACIALS = {
    [59752]  = { isActive = true, layoutIndex = 1 },  -- Will to Survive
    [20594]  = { isActive = true, layoutIndex = 2 },  -- Stoneform
    [58984]  = { isActive = true, layoutIndex = 3 },  -- Shadowmeld
    [20589]  = { isActive = true, layoutIndex = 4 },  -- Escape Artist
    [28880]  = { isActive = true, layoutIndex = 5 },  -- Gift of the Naaru
    [68992]  = { isActive = true, layoutIndex = 6 },  -- Darkflight
    [20572]  = { isActive = true, layoutIndex = 7 },  -- Blood Fury
    [7744]   = { isActive = true, layoutIndex = 8 },  -- Will of the Forsaken
    [20549]  = { isActive = true, layoutIndex = 9 }, -- War Stomp
    [26297]  = { isActive = true, layoutIndex = 10 }, -- Berserking
    [202719] = { isActive = true, layoutIndex = 11 }, -- Arcane Torrent
    [69070]  = { isActive = true, layoutIndex = 12 }, -- Rocket Jump
    [69041]  = { isActive = true, layoutIndex = 13 }, -- Rocket Barrage
    [256948] = { isActive = true, layoutIndex = 14 }, -- Spatial Rift
    [255647] = { isActive = true, layoutIndex = 15 }, -- Light's Judgment
    [287712] = { isActive = true, layoutIndex = 16 }, -- Haymaker
    [265221] = { isActive = true, layoutIndex = 17 }, -- Fireblood
    [291944] = { isActive = true, layoutIndex = 18 }, -- Regeneratin'
    [312411] = { isActive = true, layoutIndex = 19 }, -- Bag of Tricks
    [312924] = { isActive = true, layoutIndex = 20 }, -- Hyper Organic Light Originator
    [107079] = { isActive = true, layoutIndex = 21 }, -- Quaking Palm
    [368970] = { isActive = true, layoutIndex = 22 }, -- Tail Swipe
    [357214] = { isActive = true, layoutIndex = 23 }, -- Wing Buffet
    [436344] = { isActive = true, layoutIndex = 24 }, -- Azerite Surge
    [1237885] = { isActive = true, layoutIndex = 25 }, -- Thorn Bloom
}

function BCDM:AddRecommendedItems()
    local CooldownManagerDB = BCDM.db.profile
    if not CooldownManagerDB then return end

    local CustomDB = CooldownManagerDB.CooldownManager.Item
    if not ITEMS or type(ITEMS) ~= "table" then return end
    if not CustomDB then CustomDB = {} CooldownManagerDB.CooldownManager.Item = CustomDB end
    if not CustomDB.Items then CustomDB.Items = {} end

    for itemId, data in pairs(ITEMS) do
        if itemId and data and not CustomDB.Items[itemId] then
            CustomDB.Items[itemId] = data
        end
    end
end

function BCDM:FetchData(options)
    options = options or {}
    local includeSpells = options.includeSpells
    local includeItems = options.includeItems
    local dataList = {}

    local _, playerClass = UnitClass("player")
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()

    if includeSpells and DEFENSIVE_SPELLS[playerClass] and DEFENSIVE_SPELLS[playerClass][playerSpecialization] then
        for spellId, data in pairs(DEFENSIVE_SPELLS[playerClass][playerSpecialization]) do
            dataList[#dataList + 1] = { id = spellId, data = data, entryType = "spell", groupOrder = 1 }
        end
        for racialId, data in pairs(RACIALS) do
            dataList[#dataList + 1] = { id = racialId, data = data, entryType = "spell", groupOrder = 2 }
        end
    end

    if includeItems and ITEMS then
        for itemId, data in pairs(ITEMS) do
            dataList[#dataList + 1] = { id = itemId, data = data, entryType = "item", groupOrder = 3 }
        end
    end

    table.sort(dataList, function(a, b)
        local aOrder = a.groupOrder or 99
        local bOrder = b.groupOrder or 99
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
        local aIndex = a.data and a.data.layoutIndex or math.huge
        local bIndex = b.data and b.data.layoutIndex or math.huge
        if aIndex == bIndex then
            return a.id < b.id
        end
        return aIndex < bIndex
    end)

    return dataList
end

function BCDM:AddRecommendedSpells(customDB)
    local CooldownManagerDB = BCDM.db.profile
    local CustomDB = CooldownManagerDB.CooldownManager[customDB]
    local _, playerClass = UnitClass("player")
    local playerSpecialization = select(2, GetSpecializationInfo(GetSpecialization())):gsub(" ", ""):upper()
    if DEFENSIVE_SPELLS[playerClass] and DEFENSIVE_SPELLS[playerClass][playerSpecialization] then
        for spellId, data in pairs(DEFENSIVE_SPELLS[playerClass][playerSpecialization]) do
            if not CustomDB.Spells[playerClass] then CustomDB.Spells[playerClass] = {} end
            if not CustomDB.Spells[playerClass][playerSpecialization] then CustomDB.Spells[playerClass][playerSpecialization] = {} end
            if not CustomDB.Spells[playerClass][playerSpecialization][spellId] then
                CustomDB.Spells[playerClass][playerSpecialization][spellId] = data
            end
        end
    end
end

-- Event Check to see what trinkets are equipped. Update DB if not present else toggle isActive.
local trinketCheckEvent = CreateFrame("Frame")
trinketCheckEvent:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
trinketCheckEvent:RegisterEvent("PLAYER_LOGIN")
trinketCheckEvent:RegisterEvent("PLAYER_ENTERING_WORLD")
trinketCheckEvent:SetScript("OnEvent", function(self, event, slot)
    if InCombatLockdown() then return end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function() BCDM:FetchEquippedTrinkets() end)
        return
    elseif event == "PLAYER_EQUIPMENT_CHANGED" and (slot == 13 or slot == 14) then
        BCDM:FetchEquippedTrinkets()
    end
end)

function BCDM:FetchEquippedTrinkets()
    if InCombatLockdown() then return end
    if not BCDM.db.profile.CooldownManager.Trinket.Enabled then return end
    local trinketProfile = BCDM.db.profile.CooldownManager.Trinket
    local equippedItemIds = { GetInventoryItemID("player", 13), GetInventoryItemID("player", 14) }
    local usableCount = 0

    for itemId in pairs(trinketProfile.Trinkets) do trinketProfile.Trinkets[itemId] = nil end

    for slotIndex, itemId in ipairs(equippedItemIds) do
        if itemId and C_Item.IsUsableItem(itemId) then
            trinketProfile.Trinkets[itemId] = { isActive = true, layoutIndex = slotIndex }
            usableCount = usableCount + 1
            if BCDM.TrinketBarContainer then BCDM.TrinketBarContainer:Show() end
        end
    end

    if usableCount == 0 then if BCDM.TrinketBarContainer then BCDM.TrinketBarContainer:Hide() end return end

    BCDM:UpdateCooldownViewer("Trinket")
end
