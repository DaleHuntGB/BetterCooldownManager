local _, BCDM = ...

BCDM.Defaults = {
    global = {
        UseGlobalProfile = false,
        GlobalProfile = "Default",
    },
    profile = {
        General = {
            Font = "Friz Quadrata TT",
            FontFlag = "OUTLINE",
            IconZoom = 0.1,
            CooldownText = {
                FontSize = 15,
                Colour = {1, 1, 1},
                Anchors = {"CENTER", "CENTER", 0, 0}
            },
            CustomColours = {
                PrimaryPower = {
                    [0] = {0, 0, 1},            -- Mana
                    [1] = {1, 0, 0},            -- Rage
                    [2] = {1, 0.5, 0.25},       -- Focus
                    [3] = {1, 1, 0},            -- Energy
                    [6] = {0, 0.82, 1},         -- Runic Power
                    [8] = {0.75, 0.52, 0.9},     -- Lunar Power
                    [11] = {0, 0.5, 1},         -- Maelstrom
                    [13] = {0.4, 0, 0.8},       -- Insanity
                    [17] = {0.79, 0.26, 0.99},  -- Fury
                    [18] = {1, 0.61, 0}         -- Pain
                },
                SecondaryPower = {
                    [Enum.PowerType.Chi]           = {0.00, 1.00, 0.59 },
                    [Enum.PowerType.ComboPoints]   = {1.00, 0.96, 0.41 },
                    [Enum.PowerType.HolyPower]     = {0.95, 0.90, 0.60 },
                    [Enum.PowerType.ArcaneCharges] = {0.10, 0.10, 0.98},
                    [Enum.PowerType.Essence]       = { 0.20, 0.58, 0.50 },
                    [Enum.PowerType.SoulShards]    = { 0.58, 0.51, 0.79 },
                    STAGGER                        = { 0.00, 1.00, 0.59 },
                    [Enum.PowerType.Runes]         = { 0.77, 0.12, 0.23 },
                    SOUL                           = { 0.29, 0.42, 1.00},
                    [Enum.PowerType.Maelstrom]     = { 0.25, 0.50, 0.80},
                }
            }
        },
        CastBar = {
            Height = 24,
            FGTexture = "Blizzard Raid Bar",
            BGTexture = "Solid",
            FGColour = {255/255, 204/255, 64/255, 1},
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
            Count = {
                FontSize = 12,
                Colour = {1, 1, 1},
                Anchors = {"BOTTOMRIGHT", "BOTTOMRIGHT", 0, 3}
            },
        },
        PowerBar = {
            Height = 13,
            FGTexture = "Blizzard Raid Bar",
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
            FGTexture = "Blizzard Raid Bar",
            BGTexture = "Solid",
            FGColour = {0/255, 122/255, 204/255, 1},
            BGColour = {20/255, 20/255, 20/255, 1},
            Anchors = {"BOTTOM", "EssentialCooldownViewer", "TOP", 0, 2},
            ColourByPower = true,
        }
    }
}