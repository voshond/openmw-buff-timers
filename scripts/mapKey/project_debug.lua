local core = require("openmw.core")
local storage = require("openmw.storage")
local settings = require("scripts.mapkey.mk_settings")

local Debug = {}

-- Function to print debug messages from the Map Key mod
function Debug.log(message)
    -- Only print if debug logging is enabled in settings
    if settings:get("enableDebugLogging") then
        print("[MapKey]: " .. message)
    end
end

-- Shorthand function for debug logging with prefix
function Debug.mapKey(message)
    Debug.log(message)
end

-- Log version information on startup
Debug.log("Map Key Debug Module Loaded")

return Debug
