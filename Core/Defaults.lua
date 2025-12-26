local _, BCDM = ...

BCDM.Defaults = {
    global = {
        UseGlobalProfile = false,
        GlobalProfile = "Default",
        AutomaticallySetEditMode = false,
        LayoutNumber = 3,
    },
    profile = {
        General = {
            Font = "Friz Quadrata TT",
            FontFlag = "OUTLINE",
            IconZoom = 0.1,
            CooldownText = {
                FontSize = 15,
                Colour = {1, 1, 1},
                Anchors = {"CENTER", "CENTER", 0, 0},
                ScaleByIconSize = false
            },
            Shadows = {
                Colour = {0, 0, 0, 1},
                OffsetX = 0,
                OffsetY = 0
            },
            CustomColours = {
                PrimaryPower = {
                    [0] = {0, 0, 1},                                            -- Mana
                    [1] = {1, 0, 0},                                            -- Rage
                    [2] = {1, 0.5, 0.25},                                       -- Focus
                    [3] = {1, 1, 0},                                            -- Energy
                    [6] = {0, 0.82, 1},                                         -- Runic Power
                    [8] = {0.75, 0.52, 0.9},                                    -- Lunar Power
                    [11] = {0, 0.5, 1},                                         -- Maelstrom
                    [13] = {0.4, 0, 0.8},                                       -- Insanity
                    [17] = {0.79, 0.26, 0.99},                                  -- Fury
                    [18] = {1, 0.61, 0}                                         -- Pain
                },
                SecondaryPower = {
                    [Enum.PowerType.Chi]           = {0.00, 1.00, 0.59, 1.0 },
                    [Enum.PowerType.ComboPoints]   = {1.00, 0.96, 0.41, 1.0 },
                    [Enum.PowerType.HolyPower]     = {0.95, 0.90, 0.60, 1.0 },
                    [Enum.PowerType.ArcaneCharges] = {0.10, 0.10, 0.98, 1.0},
                    [Enum.PowerType.Essence]       = { 0.20, 0.58, 0.50, 1.0 },
                    [Enum.PowerType.SoulShards]    = { 0.58, 0.51, 0.79, 1.0 },
                    [Enum.PowerType.Runes]         = { 0.77, 0.12, 0.23, 1.0 },
                    [Enum.PowerType.Maelstrom]     = { 0.25, 0.50, 0.80, 1.0},
                    SOUL                           = { 0.29, 0.42, 1.00, 1.0},
                    STAGGER                        = { 0.00, 1.00, 0.59, 1.0 },
                    RUNE_RECHARGE                  = { 0.5, 0.5, 0.5, 1.0 }
                }
            }
        },
        CastBar = {
            Height = 24,
            FGTexture = "Better Blizzard",
            BGTexture = "Solid",
            FGColour = {128/255, 128/255, 255/255, 1},
            BGColour = {20/255, 20/255, 20/255, 1},
            Anchors = {"TOP", "UtilityCooldownViewer", "BOTTOM", 0, -2},
            ColourByClass = false,
            SpellName = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"LEFT", "LEFT", 3, 0},
            },
            Duration = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"RIGHT", "RIGHT", -3, 0},
                ExpirationThreshold = 5,
            }
        },
        Essential = {
            IconSize = {42, 42},
            Anchors = {"CENTER", "CENTER", 0, -275.1},
            Count = {
                FontSize = 15,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
        },
        Utility = {
            IconSize = {36, 36},
            Anchors = {"TOP", "EssentialCooldownViewer", "BOTTOM", 0, -3},
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
        },
        Buffs = {
            IconSize = {36, 36},
            Anchors = {"BOTTOM", "BCDM_PowerBar", "TOP", 0, 2},
            CentreHorizontally = false,
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
        },
        Custom = {
            IconSize = {36, 36},
            Anchors = {"BOTTOMRIGHT", "UUF_Player", "TOPRIGHT", 0, 1},
            GrowthDirection = "LEFT",
            Spacing = 1,
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
            CustomSpells = {
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
        },
        AdditionalCustom = {
            IconSize = {36, 36},
            Anchors = {"BOTTOMLEFT", "UUF_Player", "TOPLEFT", 0, 1},
            GrowthDirection = "RIGHT",
            Spacing = 1,
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
            CustomSpells = {
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
        },
        Items = {
            IconSize = {36, 36},
            Anchors = {"TOPLEFT", "UUF_Player", "BOTTOMLEFT", 0, -1},
            GrowthDirection = "RIGHT",
            Spacing = 1,
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
            CustomItems = {
                [241292] = { isActive = false, layoutIndex = 1 },               -- Draught of Rampant Abandon
                [241308] = { isActive = true, layoutIndex = 2 },                -- Light's Potential
                [241304] = { isActive = true, layoutIndex = 3 },                -- Silvermoon Healing Potion
                [241300] = { isActive = false, layoutIndex = 4 },               -- Lightfused Mana Potion
                [241296] = { isActive = false, layoutIndex = 5 },               -- Potion of Zealotry
                [241294] = { isActive = false, layoutIndex = 6 },               -- Potion of Devoured Dreams
                [241286] = { isActive = false, layoutIndex = 7 },               -- Light's Preservation
                [241288] = { isActive = false, layoutIndex = 8 },               -- Potion of Recklessness
                [241302] = { isActive = false, layoutIndex = 9 },               -- Void-Shrouded Tincture
            }
        },
        PowerBar = {
            Height = 13,
            FGTexture = "Better Blizzard",
            BGTexture = "Solid",
            FGColour = {0/255, 122/255, 204/255, 1},
            BGColour = {20/255, 20/255, 20/255, 1},
            Anchors = {"BOTTOM", "EssentialCooldownViewer", "TOP", 0, 2},
            ColourByPower = true,
            Text = {
                FontSize = 18,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOM", "BOTTOM", 0, 3},
                ColourByPower = false
            },
        },
        SecondaryBar = {
            Height = 13,
            FGTexture = "Better Blizzard",
            BGTexture = "Solid",
            FGColour = {0/255, 122/255, 204/255, 1},
            BGColour = {20/255, 20/255, 20/255, 1},
            Anchors = {"BOTTOM", "EssentialCooldownViewer", "TOP", 0, 2},
            ColourByPower = true,
        }
    }
}