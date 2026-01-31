local _, BCDM = ...

local Defaults = {
    global = {
        UseGlobalProfile = false,
        GlobalProfileName = "Default",
    },
    profile = {
        General = {
            Fonts = {
                Font = "Friz Quadrata TT",
                FontFlag = "OUTLINE",
                Shadow = {
                    Enabled = false,
                    Colour = {0, 0, 0, 1},
                    OffsetX = 1,
                    OffsetY = -1
                }
            },
            Textures = {
                Foreground = "Better Blizzard",
                Background = "Better Blizzard",
            },
            Animation = {
                SmoothBars = false,
            },
            Colours = {
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
                    [Enum.PowerType.Chi]           = {0.71, 1.00, 0.92, 1.0 },
                    [Enum.PowerType.ComboPoints]   = {1.00, 0.96, 0.41, 1.0 },
                    [Enum.PowerType.HolyPower]     = {0.95, 0.90, 0.60, 1.0 },
                    [Enum.PowerType.ArcaneCharges] = {0.10, 0.10, 0.98, 1.0},
                    [Enum.PowerType.Essence]       = { 0.20, 0.58, 0.50, 1.0 },
                    [Enum.PowerType.SoulShards]    = { 0.58, 0.51, 0.79, 1.0 },
                    [Enum.PowerType.Runes]         = { 0.77, 0.12, 0.23, 1.0 },
                    [Enum.PowerType.Maelstrom]     = { 0.25, 0.50, 0.80, 1.0},
                    SOUL                           = { 0.29, 0.42, 1.00, 1.0},
                    STAGGER                        = { 0.00, 1.00, 0.59, 1.0 },
                    RUNE_RECHARGE                  = { 0.5, 0.5, 0.5, 1.0 },
                    ESSENCE_RECHARGE               = { 0.5, 0.5, 0.5, 1.0 },
                    CHARGED_COMBO_POINTS           = { 0.25, 0.5, 1.00, 1.0},
                    RUNES = {
                        FROST = {0.25, 1.00, 1.00, 1.0},
                        UNHOLY = {0.25, 1.00, 0.25, 1.0},
                        BLOOD = {1.00, 0.25, 0.25, 1.0}
                    },
                    STAGGER_COLOURS = {
                        LIGHT = {0.25, 1.00, 0.25, 1.0},
                        MODERATE = {1.00, 1.00, 0.25, 1.0},
                        HEAVY = {1.00, 0.25, 0.25, 1.0}
                    }
                }
            }
        },
        EditModeManager = {
            SwapOnInstanceDifficulty = false,
            SwapOnSpecializationChange = false,
            RaidLayouts = {
                Normal = "",
                Heroic = "",
                Mythic = "",
                LFR = "",
            },
            SpecializationLayouts = {
                [1] = "",
                [2] = "",
                [3] = "",
                [4] = "",
            },
        },
        CooldownManager = {
            Enable = true,
            General = {
                IconZoom = 0.1,
                BorderSize = 1,
                Glow = {
                    Enabled = true,
                    GlowType = "PIXEL",
                    Thickness = 1,
                    Particles = 10,
                    Scale = 1,
                    Colour = {1, 1, 1, 1},
                    Frequency = 0.25,
                    XOffset = -1,
                    YOffset = -1,
                    Lines = 5,
                },
                CooldownText = {
                    FontSize = 15,
                    Colour = {1, 1, 1},
                    Layout = {"CENTER", "CENTER", 0, 0},
                    ScaleByIconSize = false
                },
            },
            Essential = {
                IconSize = 42,
                Layout = {"CENTER", "CENTER", 0, -275.1},
                Text = {
                    FontSize = 15,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
                },
            },
            Utility = {
                IconSize = 36,
                Layout = {"TOP", "EssentialCooldownViewer", "BOTTOM", 0, -1.1},
                Text = {
                    FontSize = 15,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
                },
            },
            Buffs = {
                IconSize = 32,
                CenterBuffs = false,
                Layout = {"BOTTOM", "BCDM_SecondaryPowerBar", "TOP", 0, 1.1},
                Text = {
                    FontSize = 15,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
                },
            },
            BuffBar = {
                Width = 300,
                Height = 24,
                Spacing = 2,
                GrowthDirection = "UP",
                MatchWidthOfAnchor = true,
                ColourByClass = true,
                BackgroundColour = {34/255, 34/255, 34/255, 1},
                ForegroundColour = {34/255, 34/255, 34/255, 1},
                Layout = {"BOTTOM", "EssentialCooldownViewer", "TOP", 0, 1.1},
                Icon = {
                    Enabled = true,
                    Layout = "LEFT",
                },
                Text = {
                    SpellName = {
                        Enabled = true,
                        FontSize = 12,
                        Colour = {1, 1, 1},
                        Layout = {"LEFT", "LEFT", 3, 0}
                    },
                    Duration = {
                        Enabled = true,
                        FontSize = 12,
                        Colour = {1, 1, 1},
                        Layout = {"RIGHT", "RIGHT", -3, 0}
                    },
                }
            },
            Custom = {
                IconSize = 38,
                FrameStrata = "LOW",
                Layout = {"CENTER", "NONE", "CENTER", 0, 0},
                Spacing = 1,
                GrowthDirection = "RIGHT",
                Text = {
                    FontSize = 12,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2}
                },
                Spells = {
                    -- Monk
                    ["MONK"] = {
                        ["BREWMASTER"] = {},
                        ["WINDWALKER"] = {},
                        ["MISTWEAVER"] = {},
                    },
                    -- Demon Hunter
                    ["DEMONHUNTER"] = {
                        ["HAVOC"] = {},
                        ["VENGEANCE"] = {},
                        ["DEVOURER"] = {},
                    },
                    -- Death Knight
                    ["DEATHKNIGHT"] = {
                        ["BLOOD"] = {},
                        ["UNHOLY"] = {},
                        ["FROST"] = {}
                    },
                    -- Mage
                    ["MAGE"] = {
                        ["FROST"] = {},
                        ["FIRE"] = {},
                        ["ARCANE"] = {},
                    },
                    -- Paladin
                    ["PALADIN"] = {
                        ["RETRIBUTION"] = {},
                        ["HOLY"] = {},
                        ["PROTECTION"] = {}
                    },
                    -- Shaman
                    ["SHAMAN"] = {
                        ["ELEMENTAL"] = {},
                        ["ENHANCEMENT"] = {},
                        ["RESTORATION"] = {}
                    },
                    -- Druid
                    ["DRUID"] = {
                        ["GUARDIAN"] = {},
                        ["FERAL"] = {},
                        ["RESTORATION"] = {},
                        ["BALANCE"] = {},
                    },
                    -- Evoker
                    ["EVOKER"] = {
                        ["DEVASTATION"] = {},
                        ["AUGMENTATION"] = {},
                        ["PRESERVATION"] = {}
                    },
                    -- Warrior
                    ["WARRIOR"] = {
                        ["ARMS"] = {},
                        ["FURY"] = {},
                        ["PROTECTION"] = {},
                    },
                    -- Priest
                    ["PRIEST"] = {
                        ["SHADOW"] = {},
                        ["DISCIPLINE"] = {},
                        ["HOLY"] = {},
                    },
                    -- Warlock
                    ["WARLOCK"] = {
                        ["DESTRUCTION"] = {},
                        ["AFFLICTION"] = {},
                        ["DEMONOLOGY"] = {},
                    },
                    -- Hunter
                    ["HUNTER"] = {
                        ["SURVIVAL"] = {},
                        ["MARKSMANSHIP"] = {},
                        ["BEASTMASTERY"] = {},
                    },
                    -- Rogue
                    ["ROGUE"] = {
                        ["OUTLAW"] = {},
                        ["ASSASSINATION"] = {},
                        ["SUBTLETY"] = {},
                    }
                },
            },
            AdditionalCustom = {
                IconSize = 38,
                FrameStrata = "LOW",
                Layout = {"CENTER", "NONE", "CENTER", 0, 0},
                Spacing = 1,
                GrowthDirection = "RIGHT",
                Text = {
                    FontSize = 12,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2}
                },
                Spells = {
                    -- Monk
                    ["MONK"] = {
                        ["BREWMASTER"] = {},
                        ["WINDWALKER"] = {},
                        ["MISTWEAVER"] = {},
                    },
                    -- Demon Hunter
                    ["DEMONHUNTER"] = {
                        ["HAVOC"] = {},
                        ["VENGEANCE"] = {},
                        ["DEVOURER"] = {},
                    },
                    -- Death Knight
                    ["DEATHKNIGHT"] = {
                        ["BLOOD"] = {},
                        ["UNHOLY"] = {},
                        ["FROST"] = {}
                    },
                    -- Mage
                    ["MAGE"] = {
                        ["FROST"] = {},
                        ["FIRE"] = {},
                        ["ARCANE"] = {},
                    },
                    -- Paladin
                    ["PALADIN"] = {
                        ["RETRIBUTION"] = {},
                        ["HOLY"] = {},
                        ["PROTECTION"] = {}
                    },
                    -- Shaman
                    ["SHAMAN"] = {
                        ["ELEMENTAL"] = {},
                        ["ENHANCEMENT"] = {},
                        ["RESTORATION"] = {}
                    },
                    -- Druid
                    ["DRUID"] = {
                        ["GUARDIAN"] = {},
                        ["FERAL"] = {},
                        ["RESTORATION"] = {},
                        ["BALANCE"] = {},
                    },
                    -- Evoker
                    ["EVOKER"] = {
                        ["DEVASTATION"] = {},
                        ["AUGMENTATION"] = {},
                        ["PRESERVATION"] = {}
                    },
                    -- Warrior
                    ["WARRIOR"] = {
                        ["ARMS"] = {},
                        ["FURY"] = {},
                        ["PROTECTION"] = {},
                    },
                    -- Priest
                    ["PRIEST"] = {
                        ["SHADOW"] = {},
                        ["DISCIPLINE"] = {},
                        ["HOLY"] = {},
                    },
                    -- Warlock
                    ["WARLOCK"] = {
                        ["DESTRUCTION"] = {},
                        ["AFFLICTION"] = {},
                        ["DEMONOLOGY"] = {},
                    },
                    -- Hunter
                    ["HUNTER"] = {
                        ["SURVIVAL"] = {},
                        ["MARKSMANSHIP"] = {},
                        ["BEASTMASTERY"] = {},
                    },
                    -- Rogue
                    ["ROGUE"] = {
                        ["OUTLAW"] = {},
                        ["ASSASSINATION"] = {},
                        ["SUBTLETY"] = {},
                    }
                },
            },
            Item = {
                IconSize = 38,
                FrameStrata = "LOW",
                Layout = {"CENTER", "NONE", "CENTER", 0, 0},
                Spacing = 1,
                GrowthDirection = "LEFT",
                OffsetByParentHeight = true,
                Text = {
                    FontSize = 12,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2}
                },
                Items = {},
            },
            Trinket = {
                Enabled = true,
                IconSize = 38,
                FrameStrata = "LOW",
                Layout = {"CENTER", "NONE", "CENTER", 0, 0},
                Spacing = 1,
                GrowthDirection = "LEFT",
                OffsetByParentHeight = true,
                Text = {
                    FontSize = 12,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2}
                },
                Trinkets = {},
            },
            ItemSpell = {
                IconSize = 38,
                FrameStrata = "LOW",
                Layout = {"CENTER", "NONE", "CENTER", 0, 0},
                Spacing = 1,
                GrowthDirection = "LEFT",
                OffsetByParentHeight = true,
                Text = {
                    FontSize = 12,
                    Colour = {1, 1, 1},
                    Layout = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 2}
                },
                ItemsSpells = {},
            },
        },
        PowerBar = {
            Enabled = true,
            Width = 200,
            Height = 13,
            HeightWithoutSecondary = 20,
            MatchWidthOfAnchor = true,
            ColourByType = true,
            ColourByClass = false,
            FrequentUpdates = true,
            FrameStrata = "LOW",
            BackgroundColour = {34/255, 34/255, 34/255, 1},
            ForegroundColour = {34/255, 34/255, 34/255, 1},
            Layout = {"BOTTOM", "EssentialCooldownViewer", "TOP", 0, 1},
            Text = {
                Enabled = true,
                FontSize = 18,
                Colour = {1, 1, 1},
                Layout = {"BOTTOM", "BOTTOM", 0, 1}
            },
        },
        SecondaryPowerBar = {
            Enabled = true,
            Width = 200,
            Height = 13,
            HeightWithoutPrimary = 13,
            MatchWidthOfAnchor = true,
            ColourByType = true,
            ColourByClass = false,
            ColourBySpec = false,
            ColourByState = true,
            FrameStrata = "LOW",
            HideTicks = false,
            SwapToPowerBarPosition = false,
            BackgroundColour = {34/255, 34/255, 34/255, 1},
            ForegroundColour = {34/255, 34/255, 34/255, 1},
            Layout = {"BOTTOM", "BCDM_PowerBar", "TOP", 0, 1},
            Text = {
                Enabled = false,
                FontSize = 12,
                Colour = {1, 1, 1},
                Layout = {"CENTER", "CENTER", 0, 0},
                ShowStaggerDPS = false,
            },
        },
        CastBar = {
            Enabled = true,
            Width = 200,
            Height = 24,
            MatchWidthOfAnchor = true,
            ColourByClass = true,
            FrameStrata = "LOW",
            BackgroundColour = {34/255, 34/255, 34/255, 1},
            ForegroundColour = {34/255, 34/255, 34/255, 1},
            Layout = {"TOP", "UtilityCooldownViewer", "BOTTOM", 0, -1},
            Text = {
                SpellName = {
                    FontSize = 12,
                    Colour = {1, 1, 1},
                    Layout = {"LEFT", "LEFT", 3, 0},
                    MaxCharacters = 12,
                },
                CastTime = {
                    FontSize = 12,
                    Colour = {1, 1, 1},
                    Layout = {"RIGHT", "RIGHT", -3, 0}
                }
            },
            Icon = {
                Enabled = true,
                Layout = "LEFT",
            }
        },
    },
}

function BCDM:GetDefaultDB()
    return Defaults
end