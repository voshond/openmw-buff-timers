local core = require("openmw.core")
local storage = require('openmw.storage')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local settings = storage.playerSection("SettingsBuffTimers")

-- Register the main settings page
I.Settings.registerPage {
    key = "SettingsBuffTimers",
    l10n = "SettingsBuffTimers",
    name = "voshond's Buff Timers",
    description = "Settings for the Buff Timer mod that displays active spell effects with radial countdown timers."
}

-- Register main settings group
I.Settings.registerGroup {
    key = "SettingsBuffTimersMain",
    page = "SettingsBuffTimers",
    l10n = "SettingsBuffTimers",
    name = "Main Settings",
    permanentStorage = true,
    description = [[
    Configure the main behavior of the Buff Timer system.
    
    The mod displays active buffs and debuffs in the top-right corner with radial countdown overlays.
    Icons show remaining time and change color based on urgency (green → yellow → red).
    ]],
    settings = {
        {
            key = "enableMod",
            renderer = "checkbox",
            name = "Enable Buff Timers",
            description = "Master switch to enable or disable the entire buff timer system.",
            default = true
        },
        {
            key = "iconSize",
            renderer = "number",
            name = "Icon Size",
            description = "Controls the size of buff/debuff icons. Higher values create larger icons.",
            default = 24,
            argument = {
                min = 16,
                max = 64,
            },
        },
        {
            key = "updateInterval",
            renderer = "number",
            name = "Update Interval (seconds)",
            description = "How often the buff display updates. Lower values are more responsive but use more CPU.",
            default = 0.5,
            argument = {
                min = 0.1,
                max = 2.0,
                step = 0.1,
            },
        },
        {
            key = "enableRadialSwipe",
            renderer = "checkbox",
            name = "Enable Radial Countdown",
            description = "Show radial countdown overlay on buff icons. Disable for better performance.",
            default = true
        },
    },
}

-- Register visual settings group
I.Settings.registerGroup {
    key = "SettingsBuffTimersVisual",
    page = "SettingsBuffTimers",
    l10n = "SettingsBuffTimers",
    name = "Visual Settings",
    permanentStorage = true,
    description = "Control the appearance and visual effects of buff timers.",
    settings = {
        {
            key = "showTimeText",
            renderer = "checkbox",
            name = "Show Time Text",
            description = "Display remaining time as text on each buff icon.",
            default = true
        },
        {
            key = "showEffectNames",
            renderer = "checkbox",
            name = "Show Effect Names",
            description = "Display abbreviated effect names on buff icons.",
            default = true
        },
        {
            key = "textSize",
            renderer = "number",
            name = "Effect Name Text Size",
            description = "Controls the font size of effect names displayed on buff icons.",
            default = 8,
            argument = {
                min = 6,
                max = 16,
            },
        },
        {
            key = "timerTextSize",
            renderer = "number",
            name = "Timer Text Size",
            description = "Controls the font size of timer text displayed on buff icons.",
            default = 10,
            argument = {
                min = 6,
                max = 16,
            },
        },
        {
            key = "radialOpacity",
            renderer = "number",
            name = "Radial Overlay Opacity",
            description = "Controls how visible the radial countdown overlay is. Higher values are more opaque.",
            default = 90,
            argument = {
                min = 30,
                max = 100,
            },
        },
    },
}

-- Register debug settings group
I.Settings.registerGroup {
    key = "SettingsBuffTimersDebug",
    page = "SettingsBuffTimers",
    l10n = "SettingsBuffTimers",
    name = "Debug Options",
    permanentStorage = true,
    description = "Debug and troubleshooting options for developers and advanced users.",
    settings = {
        {
            key = "enableDebugLogging",
            renderer = "checkbox",
            name = "Enable Debug Logging",
            description = "If enabled, debug messages will be shown in the console. Useful for troubleshooting but may impact performance.",
            default = false
        },
        {
            key = "enableFrameLogging",
            renderer = "checkbox",
            name = "Enable Frame Logging",
            description = "If enabled, logs high-frequency updates like UI refreshes. Warning: Can be extremely verbose!",
            default = false
        },

    },
}

return settings 