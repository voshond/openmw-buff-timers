local ui = require("openmw.ui")
local self = require("openmw.self")
local types = require("openmw.types")
local util = require("openmw.util")
local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local time = require("openmw_aux.time")
local storage = require("openmw.storage")

-- Load the actual debug module
local Debug = require("scripts.bufftimers.bt_debug")

Debug.ui("Starting script load...")
Debug.ui("All modules loaded successfully")
Debug.ui("Debug module loaded")

-- Load settings module to register the settings page
local playerSettings = nil
pcall(function()
    require("scripts.bufftimers.bt_settings")
    playerSettings = storage.playerSection("SettingsBuffTimers")
    Debug.ui("Settings module loaded successfully")
end)

-- Buff Timer UI Implementation
-- Based on omwMagicTimeHud for spell handling and voshondsQuickSelect for UI patterns

Debug.ui("Script starting - basic test")
Debug.ui("Script loading...")

local mfxRecord = core.magic.effects.records
local xy = util.vector2

-- UI Configuration constants
local PADDING = 4

-- Function to get current settings values (reads fresh each time)
local function getIconSize()
    local settings = storage.playerSection("SettingsBuffTimersMain")
    return settings:get("iconSize")
end

local function getTextSize()
    local settings = storage.playerSection("SettingsBuffTimersVisual")
    return settings:get("textSize")
end

local function getTimerTextSize()
    local settings = storage.playerSection("SettingsBuffTimersVisual")
    return settings:get("timerTextSize")
end

local function getUpdateInterval()
    local settings = storage.playerSection("SettingsBuffTimersMain")
    return settings:get("updateInterval")
end

local function isModEnabled()
    local settings = storage.playerSection("SettingsBuffTimersMain")
    return settings:get("enableMod")
end

local function isRadialSwipeEnabled()
    local settings = storage.playerSection("SettingsBuffTimersMain")
    return settings:get("enableRadialSwipe")
end

local function isTimeTextEnabled()
    local settings = storage.playerSection("SettingsBuffTimersVisual")
    return settings:get("showTimeText")
end

local function isEffectNamesEnabled()
    local settings = storage.playerSection("SettingsBuffTimersVisual")
    return settings:get("showEffectNames")
end

local function getRadialOpacity()
    local settings = storage.playerSection("SettingsBuffTimersVisual")
    return settings:get("radialOpacity")
end

Debug.ui("Settings functions initialized")

-- Colors
local colorIcon = util.color.rgb(1.0, 1.0, 1.0) -- Full brightness white for crisp icons
local colorText = util.color.hex('dfc89e')
local colorBackground = util.color.rgba(0, 0, 0, 0.7)

-- UI Layout
local screenSize = ui.screenSize()
-- Position at top-right - calculate position so container doesn't go off-screen
-- We'll position it and let the container align itself properly
local rootPosition = xy(screenSize.x - 400, 50) -- Give enough space for the container

Debug.ui("Screen size: " .. screenSize.x .. "x" .. screenSize.y)
Debug.ui("Root position: " .. rootPosition.x .. ", " .. rootPosition.y)

-- Texture cache to avoid recreating textures
local textureCache = {}

local function getTexture(path)
    if not textureCache[path] and path then
        Debug.ui("Loading texture: " .. path)
        textureCache[path] = ui.texture({ path = path })
    end
    return textureCache[path]
end

-- Radial Swipe Implementation
local radialSwipe = {}

radialSwipe.createRadialWipe = function(effect)
    if not effect then return nil end
    if not effect.duration or not effect.durationLeft or effect.durationLeft <= 0 then return nil end
    
    -- Use the inverted atlas so overlay grows as time runs out (like a countdown timer)
    local myAtlas = 'textures/radial/partial_invert.png' -- 4096x4096 atlas with 360 frames
    local offset = 204 -- each square is 204 x 204
    local durL = effect.durationLeft
    local dur = effect.duration
    local maxDegree = 360
    
    -- Calculate position in atlas (0-359)
    local position = math.floor(maxDegree - ((durL / dur) * maxDegree))
    position = math.max(0, math.min(359, position)) -- Clamp to valid range
    
    local col = position % 20 -- X position in 20x20 grid
    local colOffset = col * offset
    local row = math.floor(position / 20) -- Y position in 20x20 grid  
    local rowOffset = row * offset
    
    Debug.radial("Duration: " .. dur .. "s, Left: " .. durL .. "s, Position: " .. position .. ", Col: " .. col .. ", Row: " .. row)
    
    local texture = ui.texture {
        path = myAtlas,
        offset = util.vector2(colOffset, rowOffset),
        size = util.vector2(204, 204),
    }
    
    return texture
end

radialSwipe.createOverlay = function(atlasTexture, iconSize, durationLeft, originalDuration)
    if not atlasTexture then return nil end
    
    -- Calculate how much time is left as a percentage
    local timePercent = durationLeft / originalDuration
    
    -- Color coding based on time remaining
    local overlayColor
    local overlayAlpha
    
    -- Get opacity setting (default to 90%)
    local baseOpacity = getRadialOpacity()
    baseOpacity = baseOpacity / 100.0 -- Convert percentage to decimal
    
    if timePercent > 0.5 then
        -- Green for >50% time remaining
        overlayColor = util.color.rgb(0.1, 1.0, 0.1)
        overlayAlpha = baseOpacity
    elseif timePercent > 0.25 then
        -- Yellow for 25-50% time remaining  
        overlayColor = util.color.rgb(1.0, 1.0, 0.1)
        overlayAlpha = baseOpacity
    else
        -- Red for <25% time remaining
        overlayColor = util.color.rgb(1.0, 0.1, 0.1)
        overlayAlpha = math.min(1.0, baseOpacity + 0.05) -- Slightly more opaque for urgency
    end
    
    local radialSwipeOverlay = {
        name = "RadialSwipe",
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(iconSize, iconSize),
            visible = true,
            alpha = overlayAlpha,
            inheritAlpha = false,
            resource = atlasTexture,
            color = overlayColor,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center
        }
    }
    return radialSwipeOverlay
end



-- Create the main UI container
Debug.ui("Creating UI root...")
local root = nil

-- Try to create UI with error handling
local function createUI()
    local success, result = pcall(function()
        -- Calculate position with padding from edges
        local screenSize = ui.screenSize()
        local paddingRight = 4
        local paddingTop = 4
        local relativeX = (screenSize.x - paddingRight) / screenSize.x
        local relativeY = paddingTop / screenSize.y
        
        return ui.create{
            layer = 'HUD',
            props = { 
                relativePosition = util.vector2(relativeX, relativeY), -- Top-right with padding
                anchor = util.vector2(1, 0), -- Anchor to top-right of container
                visible = true
            },
            template = I.MWUI.templates.padding,
            content = ui.content{{
                name = 'buffContainer',
                type = ui.TYPE.Flex,
                props = {
                    align = ui.ALIGNMENT.End, -- Align to right
                    arrange = ui.ALIGNMENT.End, -- Arrange from right
                    horizontal = true,
                    -- Dynamic size - will be updated based on actual buff count
                    size = xy(800, getIconSize()),
                }
            }}
        }
    end)
    
    if success then
        Debug.ui("UI created successfully with padding")
        return result
    else
        Debug.error("UI", "Failed to create UI: " .. tostring(result))
        return nil
    end
end

root = createUI()

-- Function to format duration into readable time
local function formatDuration(seconds)
    if seconds >= 86400 then
        -- Show days for very long durations (86400 seconds = 1 day)
        local days = math.floor(seconds / 86400)
        return string.format("%dd", days)
    elseif seconds >= 3600 then
        -- Show hours for long durations (3600 seconds = 1 hour)
        local hours = math.floor(seconds / 3600)
        return string.format("%dh", hours)
    elseif seconds >= 60 then
        -- Show just minutes for medium durations
        local minutes = math.floor(seconds / 60)
        return string.format("%dm", minutes)
    else
        -- Show just seconds for short durations
        return string.format("%ds", math.floor(seconds))
    end
end

-- Function to get specific effect display name
local function getEffectDisplayName(effect)
    local effectRecord = mfxRecord[effect.id]
    if not effectRecord then
        return effect.id
    end
    
    local baseName = effectRecord.name or effect.id
    
    -- Debug logging to see what we're working with
    Debug.effects("Effect ID: " .. tostring(effect.id))
    Debug.effects("Effect attribute: " .. tostring(effect.attribute))
    Debug.effects("Effect affectedAttribute: " .. tostring(effect.affectedAttribute))
    Debug.effects("Base name: " .. tostring(baseName))
    
    -- Special handling for attribute-based effects
    if effect.id == "fortifyattribute" then
        local attributeNames = {
            [0] = "Strength",
            [1] = "Intelligence", 
            [2] = "Willpower",
            [3] = "Agility",
            [4] = "Speed",
            [5] = "Endurance",
            [6] = "Personality",
            [7] = "Luck"
        }
        
        -- String to attribute mapping for when we get string names instead of IDs
        local stringToAttribute = {
            ["strength"] = "Str",
            ["intelligence"] = "Int",
            ["willpower"] = "Will", 
            ["agility"] = "Agi",
            ["speed"] = "Spd",
            ["endurance"] = "End",
            ["personality"] = "Pers",
            ["luck"] = "Luck"
        }
        
        -- Try different possible attribute field names
        local attrId = effect.attribute or effect.affectedAttribute or effect.attributeId
        if attrId then
            local attrName
            if type(attrId) == "number" then
                -- Numeric ID
                attrName = attributeNames[attrId] or ("Attr" .. attrId)
            elseif type(attrId) == "string" then
                -- String name - convert to proper case
                attrName = stringToAttribute[string.lower(attrId)] or string.gsub(attrId, "^%l", string.upper)
            else
                attrName = "Attr" .. tostring(attrId)
            end
            Debug.effects("Found attribute ID " .. tostring(attrId) .. " -> " .. attrName)
            return attrName -- Just return the attribute name, no "Fortify" prefix
        else
            Debug.effects("No attribute ID found in effect")
        end
    end
    
    -- Special handling for skill-based effects
    if effect.id == "fortifyskill" then
        local skillId = effect.skill or effect.affectedSkill or effect.skillId
        if skillId then
            return "Skill " .. skillId
        end
    end
    
    -- Remove "Fortify Attribute" fallback since we want to see the specific attribute
    if baseName == "Fortify Attribute" then
        return "Unknown Attr"
    end
    
    return baseName
end

-- Function to create a buff icon with timer
local function createBuffIcon(effectId, durationLeft, effect)
    Debug.ui("Creating buff icon for effect: " .. tostring(effectId))
    
    if not mfxRecord[effectId] then
        Debug.warning("UI", "No record found for effect ID: " .. tostring(effectId))
        return nil
    end
    
    if not mfxRecord[effectId].icon then
        Debug.warning("UI", "No icon found for effect ID: " .. tostring(effectId))
        return nil
    end
    
    Debug.ui("Effect icon path: " .. mfxRecord[effectId].icon)
    
    local iconTexture = getTexture(mfxRecord[effectId].icon)
    if not iconTexture then
        Debug.error("UI", "Failed to load texture for effect: " .. tostring(effectId))
        return nil
    end
    
    -- Get current settings values
    local currentIconSize = getIconSize()
    local currentTextSize = getTextSize()
    local currentTimerTextSize = getTimerTextSize()
    
    -- Icon padding like voshondsQuickSelect (2px padding on each side)
    local iconPadding = 2
    local innerIconSize = xy(currentIconSize - iconPadding * 2, currentIconSize - iconPadding * 2)
    local xyIcon = xy(currentIconSize, currentIconSize)
    
    -- Get specific effect name using the enhanced function
    local effectName = getEffectDisplayName(effect)
    
    -- Split into words for multi-line display
    local words = {}
    for word in string.gmatch(effectName, "%S+") do
        table.insert(words, word)
    end
    
    -- Filter out common prefixes to show more meaningful words
    local commonPrefixes = {
        ["Fortify"] = true,
        ["Summon"] = true,
        ["Restore"] = false,
        ["Drain"] = false,
        ["Damage"] = false,
        ["Resist"] = false,
        ["Weakness"] = false,
        ["Absorb"] = false,
        ["Reflect"] = false,
        ["Shield"] = false,
        ["Spell"] = true
    }
    
    -- Remove common prefixes if there are more words after them
    local filteredWords = {}
    for i, word in ipairs(words) do
        if not (commonPrefixes[word] and #words > 1) then
            table.insert(filteredWords, word)
        end
    end
    
    -- Use filtered words, fallback to original if empty
    if #filteredWords == 0 then
        filteredWords = words
    end
    
    -- Create first line text (always show first filtered word)
    local firstWord = filteredWords[1] or effectName
    if string.len(firstWord) > 12 then
        firstWord = string.sub(firstWord, 1, 10) .. ".."
    end
    
    local firstLineText = {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = firstWord,
            textSize = currentTextSize - 2,
            relativePosition = util.vector2(0.05, 0.05), -- Top-left corner
            anchor = util.vector2(0.05, 0.05),
            arrange = ui.ALIGNMENT.Start,
            align = ui.ALIGNMENT.Start,
            textColor = util.color.rgb(1, 1, 1),
            textShadow = true,
            textShadowColor = util.color.rgb(0, 0, 0)
        }
    }
    
    -- Create second line text (if there's a second filtered word)
    local secondLineText = nil
    if filteredWords[2] then
        local secondWord = filteredWords[2]
        if string.len(secondWord) > 12 then
            secondWord = string.sub(secondWord, 1, 10) .. ".."
        end
        
        secondLineText = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text = secondWord,
                textSize = currentTextSize - 2,
                relativePosition = util.vector2(0.05, 0.30), -- More padding between lines
                anchor = util.vector2(0.05, 0.30),
                arrange = ui.ALIGNMENT.Start,
                align = ui.ALIGNMENT.Start,
                textColor = util.color.rgb(1, 1, 1),
                textShadow = true,
                textShadowColor = util.color.rgb(0, 0, 0)
            }
        }
    end
    
    -- Create timer text (bottom-right)
    local timerText = {
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            text = formatDuration(durationLeft),
            textSize = currentTimerTextSize,
            relativePosition = util.vector2(0.8, 0.8), -- Bottom-right corner
            anchor = util.vector2(0.8, 0.8),
            arrange = ui.ALIGNMENT.End,
            align = ui.ALIGNMENT.End,
            textColor = colorText,
            textShadow = true,
            textShadowColor = util.color.rgb(0, 0, 0)
        }
    }
    
    -- Create the main icon with proper sizing and centering
    local mainIcon = {
        type = ui.TYPE.Image,
        props = {
            resource = iconTexture,
            size = innerIconSize, -- Smaller size to account for padding
            color = colorIcon,
            alpha = durationLeft <= 10 and (math.floor(durationLeft * 2) % 2 == 0 and 0.5 or 1.0) or 1.0,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center
        }
    }
    
    -- Create radial swipe overlay (if enabled in settings)
    local radialTexture = nil
    local radialOverlay = nil
    if isRadialSwipeEnabled() and effect.duration then
        radialTexture = radialSwipe.createRadialWipe(effect)
        if radialTexture then
            radialOverlay = radialSwipe.createOverlay(radialTexture, innerIconSize.x, effect.durationLeft, effect.duration)
            Debug.radial("Created radial swipe overlay for effect: " .. effectId .. " (Size: " .. innerIconSize.x .. "px, Color based on " .. math.floor((effect.durationLeft/effect.duration)*100) .. "% remaining)")
        else
            Debug.warning("RADIAL", "Failed to create radial swipe for effect: " .. effectId)
        end
    end
    
    -- Build content array for the container
    local contentElements = {mainIcon}
    
    -- Add radial overlay if available (should be behind text)
    if radialOverlay then
        table.insert(contentElements, radialOverlay)
    end
    
    -- Add text elements on top (if enabled in settings)
    if isEffectNamesEnabled() then
        table.insert(contentElements, firstLineText)
        if secondLineText then
            table.insert(contentElements, secondLineText)
        end
    end
    
    if isTimeTextEnabled() then
        table.insert(contentElements, timerText)
    end
    
    -- Create bordered container using MWUI borders template like voshondsQuickSelect
    local buffIcon = {
        type = ui.TYPE.Container,
        template = I.MWUI.templates.borders,
        content = ui.content{
            {
                props = {
                    size = xyIcon,
                },
                content = ui.content(contentElements)
            }
        },
        props = {
            size = xyIcon,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center
        }
    }
    
    Debug.ui("Created buff icon successfully with duration: " .. formatDuration(durationLeft))
    return {
        effectId = effectId,
        durationLeft = durationLeft,
        originalDuration = effect.duration, -- Store original duration for radial swipe updates
        icon = buffIcon,
        text = timerText,
        firstLineText = firstLineText,
        secondLineText = secondLineText,
        radialOverlay = radialOverlay -- Store reference for updates
    }
end

-- Active buff tracking
local activeBuffs = {}

-- Function to update buff display
local function updateBuffDisplay()
    -- Check if mod is enabled
    if not isModEnabled() then
        return
    end
    
    Debug.frameLog("UPDATE", "Updating buff display...")
    
    if not root then
        Debug.warning("UPDATE", "Root UI not available, skipping update")
        return
    end
    
    local newBuffs = {}
    local buffIndex = 1
    
    -- Get active spells and their effects
    local activeSpells = types.Actor.activeSpells(self)
    if not activeSpells then
        Debug.frameLog("EFFECTS", "No active spells found")
        return
    end
    
    Debug.frameLog("EFFECTS", "Processing active spells...")
    
    -- Process each active spell's effects
    for _, activeSpell in pairs(activeSpells) do
        if activeSpell.effects then
            Debug.frameLog("EFFECTS", "Found spell with effects")
            for _, effect in pairs(activeSpell.effects) do
                if effect.duration and effect.durationLeft and effect.durationLeft > 0 then
                    Debug.frameLog("EFFECTS", "Found effect with duration: " .. effect.id .. " (" .. effect.durationLeft .. "s)")
                    
                                        -- Create unique buff identifier that includes attribute for fortifyattribute effects
                    local buffId = effect.id
                    if effect.id == "fortifyattribute" then
                        local attrId = effect.attribute or effect.affectedAttribute or effect.attributeId
                        if attrId then
                            buffId = effect.id .. "_" .. tostring(attrId)
                        end
                    end
                    
                    -- Check if we already have this buff
                    local existingBuff = nil
                    for _, buff in pairs(activeBuffs) do
                        if buff.buffId == buffId then
                            existingBuff = buff
                            break
                        end
                    end
                    
                    if existingBuff then
                        -- Update existing buff
                        Debug.frameLog("UPDATE", "Updating existing buff")
                        existingBuff.durationLeft = effect.durationLeft
                        existingBuff.text.props.text = formatDuration(effect.durationLeft)
                        -- Update alpha for blinking when low
                        existingBuff.icon.props.alpha = effect.durationLeft <= 10 and 
                            (math.floor(effect.durationLeft * 2) % 2 == 0 and 0.5 or 1.0) or 1.0
                        
                        -- Update radial swipe overlay
                        if existingBuff.radialOverlay and existingBuff.originalDuration then
                            local updatedRadialTexture = radialSwipe.createRadialWipe(effect)
                            if updatedRadialTexture then
                                existingBuff.radialOverlay.props.resource = updatedRadialTexture
                                
                                -- Update color based on time remaining
                                local timePercent = effect.durationLeft / existingBuff.originalDuration
                                if timePercent > 0.5 then
                                    existingBuff.radialOverlay.props.color = util.color.rgb(0.1, 1.0, 0.1)
                                    existingBuff.radialOverlay.props.alpha = 0.9
                                elseif timePercent > 0.25 then
                                    existingBuff.radialOverlay.props.color = util.color.rgb(1.0, 1.0, 0.1)
                                    existingBuff.radialOverlay.props.alpha = 0.9
                                else
                                    existingBuff.radialOverlay.props.color = util.color.rgb(1.0, 0.1, 0.1)
                                    existingBuff.radialOverlay.props.alpha = 0.95
                                end
                                
                                Debug.frameLog("RADIAL", "Updated radial swipe for existing buff (" .. math.floor(timePercent*100) .. "% remaining)")
                            end
                        end
                        
                        -- Update effect name text with current effect data
                        local effectName = getEffectDisplayName(effect)
                        local words = {}
                        for word in string.gmatch(effectName, "%S+") do
                            table.insert(words, word)
                        end
                        
                        -- Filter out common prefixes
                        local commonPrefixes = {
                            ["Fortify"] = true,
                            ["Summon"] = true,
                            ["Restore"] = false,
                            ["Drain"] = false,
                            ["Damage"] = false,
                            ["Resist"] = false,
                            ["Weakness"] = false,
                            ["Absorb"] = false,
                            ["Reflect"] = false,
                            ["Shield"] = false,
                            ["Spell"] = true
                        }
                        
                        local filteredWords = {}
                        for i, word in ipairs(words) do
                            if not (commonPrefixes[word] and #words > 1) then
                                table.insert(filteredWords, word)
                            end
                        end
                        
                        if #filteredWords == 0 then
                            filteredWords = words
                        end
                        
                        -- Update first line text
                        local firstWord = filteredWords[1] or effectName
                        if string.len(firstWord) > 12 then
                            firstWord = string.sub(firstWord, 1, 10) .. ".."
                        end
                        existingBuff.firstLineText.props.text = firstWord
                        
                        -- Update second line text if it exists
                        if existingBuff.secondLineText and filteredWords[2] then
                            local secondWord = filteredWords[2]
                            if string.len(secondWord) > 12 then
                                secondWord = string.sub(secondWord, 1, 10) .. ".."
                            end
                            existingBuff.secondLineText.props.text = secondWord
                        end
                        
                        newBuffs[buffIndex] = existingBuff
                    else
                        -- Create new buff
                        Debug.update("Creating new buff with ID: " .. buffId)
                        local newBuff = createBuffIcon(effect.id, effect.durationLeft, effect)
                        if newBuff then
                            newBuff.buffId = buffId -- Store the unique buff ID
                            newBuffs[buffIndex] = newBuff
                        end
                    end
                    
                    buffIndex = buffIndex + 1
                end
            end
        end
    end
    
    -- Update active buffs
    activeBuffs = newBuffs
    
    -- Sort buffs by duration (oldest first = rightmost position)
    table.sort(activeBuffs, function(a, b)
        return a.durationLeft > b.durationLeft -- Longest duration first (rightmost)
    end)
    
    Debug.update("Found " .. #activeBuffs .. " active buffs")
    
    -- Create UI content array (reverse order since we want oldest on right)
    local contentArray = {}
    for i = #activeBuffs, 1, -1 do -- Reverse iteration for right-to-left display
        local buff = activeBuffs[i]
        if i < #activeBuffs then
            -- Add padding between icons
            table.insert(contentArray, { props = { size = xy(PADDING, PADDING) } })
        end
        table.insert(contentArray, buff.icon)
    end
    
    -- Update the UI
    if root and root.layout and root.layout.content and root.layout.content['buffContainer'] then
        Debug.frameLog("UI", "Updating UI with " .. #contentArray .. " elements")
        root.layout.content['buffContainer'].content = ui.content(contentArray)
        root:update()
        Debug.frameLog("UI", "UI updated successfully")
    else
        Debug.warning("UI", "UI structure not available for update")
    end
end

-- Function to recreate UI when settings change (defined after updateBuffDisplay)
local function onSettingsChanged()
    print("[BuffTimer] Settings changed - redrawing buff display") -- Always print this
    
    Debug.ui("Settings changed - redrawing buff display")
    
    -- Completely destroy and recreate the UI like voshondsQuickSelect does
    if root then
        pcall(function() 
            root:destroy() 
            root = nil
        end)
    end
    
    -- Clear all existing buffs so they get recreated with new settings
    activeBuffs = {}
    
    -- Recreate the UI with fresh settings
    root = createUI()
    
    -- Redraw the buff display with current settings
    updateBuffDisplay()
end

-- Initialize the buff timer system
local function initialize()
    Debug.ui("Initializing buff display system")
    
    -- Check if mod is enabled
    if not isModEnabled() then
        Debug.ui("Mod is disabled in settings, skipping initialization")
        return
    end
    
    -- Initial update after a short delay
    async:newUnsavableSimulationTimer(1.0, function()
        Debug.ui("Running initial update")
        updateBuffDisplay()
        
        -- Start continuous updates using time.runRepeatedly
        local updateInterval = getUpdateInterval()
        Debug.ui("Starting continuous updates every " .. updateInterval .. " seconds")
        local stopTimer = time.runRepeatedly(updateBuffDisplay, updateInterval)
        Debug.ui("Continuous update timer started")
    end)
end

-- Start the system
Debug.ui("Starting initialization")
initialize()

-- Subscribe to settings changes (must be after all functions are defined)
pcall(function()
    -- Subscribe to all our settings sections like voshondsQuickSelect does
    local mainSettings = storage.playerSection("SettingsBuffTimersMain")
    local visualSettings = storage.playerSection("SettingsBuffTimersVisual") 
    local debugSettings = storage.playerSection("SettingsBuffTimersDebug")
    
    mainSettings:subscribe(async:callback(onSettingsChanged))
    visualSettings:subscribe(async:callback(onSettingsChanged))
    debugSettings:subscribe(async:callback(onSettingsChanged))
    
    Debug.ui("Subscribed to all settings sections for buff display redraw")
end) 