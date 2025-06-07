local storage = nil

pcall(function()
    storage = require('openmw.storage')
end)

-- Debug module to centralize all logging functionality for Buff Timers
local Debug = {}

-- Main logging function that checks if debug is enabled before printing
function Debug.log(module, message)
    if storage then
        local settings = storage.playerSection("SettingsBuffTimersDebug")
        local debugEnabled = settings and settings:get("enableDebugLogging")
        
        -- Always print this to see what's happening
        if module == "SETTINGS_CHECK" then
            print("[BuffTimer:SETTINGS_CHECK] Debug enabled: " .. tostring(debugEnabled))
        end
        
        if debugEnabled then
            print("[BuffTimer:" .. module .. "] " .. tostring(message))
        end
    end
end

-- Frame-based logging for high-frequency updates (UI refreshes, animations, etc.)
-- This is separate from regular debug logging to avoid spamming the console
function Debug.frameLog(module, message)
    if storage then
        local settings = storage.playerSection("SettingsBuffTimersDebug")
        local frameEnabled = settings and settings:get("enableFrameLogging")
        if frameEnabled then
            print("[BuffTimer:FRAME:" .. module .. "] " .. tostring(message))
        end
    end
end

-- Shorthand for specific module logs
function Debug.ui(message)
    Debug.log("UI", message)
end

function Debug.effects(message)
    Debug.log("EFFECTS", message)
end

function Debug.radial(message)
    Debug.log("RADIAL", message)
end

function Debug.update(message)
    Debug.log("UPDATE", message)
end

-- Function to report errors that will always print regardless of debug setting
function Debug.error(module, message)
    print("[BuffTimer:ERROR:" .. module .. "] " .. tostring(message))
end

-- Function to report warnings that will always print regardless of debug setting
function Debug.warning(module, message)
    print("[BuffTimer:WARNING:" .. module .. "] " .. tostring(message))
end

-- Utility function to create a conditional print function
-- This can be used to replace direct print() calls
function Debug.createPrinter(module)
    return function(message)
        Debug.log(module, message)
    end
end

-- Function to check if debug logging is enabled
function Debug.isEnabled()
    local settings = storage.playerSection("SettingsBuffTimersDebug")
    return settings and settings:get("enableDebugLogging")
end

-- Function to check if frame logging is enabled
function Debug.isFrameLoggingEnabled()
    local settings = storage.playerSection("SettingsBuffTimersDebug")
    return settings and settings:get("enableFrameLogging")
end

return Debug 