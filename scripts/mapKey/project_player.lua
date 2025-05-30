local core = require("openmw.core")
local async = require('openmw.async')
local input = require("openmw.input")
local ui = require("openmw.ui")
local settings = require("scripts.mapkey.mk_settings")
local Debug = require("scripts.mapkey.mk_debug")
local I = require("openmw.interfaces")
local self = require("openmw.self")

-- Main MapKey module
local MapKey = {}

-- Function to open the map
local function openMap()
    Debug.mapKey("Opening map via hotkey")

    -- Only open map if not in combat or other restricted UI modes
    if not I.UI.getMode() or I.UI.getMode() == "MenuMode" then
        I.UI.setMode("Map")
        Debug.mapKey("Map opened successfully")
    else
        Debug.mapKey("Cannot open map in UI mode: " .. I.UI.getMode())
    end
end

-- Initialize function
local function onInit()
    Debug.mapKey("Map Key mod initialized!")

    -- Register the OpenMap trigger in the input system
    input.registerTrigger {
        key = "OpenMap",
        l10n = "SettingsMapKey", -- Use same context as our settings
        name = "Open Map",
        description = "Opens the map screen with a single key press"
    }

    -- Register our handler using async:callback pattern
    input.registerTriggerHandler("OpenMap", async:callback(openMap))
end

-- Clean up function for when script is unloaded
local function onSave()
    Debug.mapKey("Map Key onSave called")
    return {}
end

-- Load function to restore state
local function onLoad(data)
    Debug.mapKey("Map Key onLoad called")
    -- Initialize when loading a save
    onInit()
    return {}
end

return {
    interfaceName = "MapKey",
    interface = MapKey,
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad
    }
}
