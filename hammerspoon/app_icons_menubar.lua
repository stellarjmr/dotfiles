-- Load icon mappings
local icon_map = require("icon_map")

-- Create menubar item
local menubar = hs.menubar.new()
-- Remove the menu to reduce right padding
if menubar then
    menubar:setMenu({})
end

-- Function to get all applications with visible windows
local function getVisibleApps()
    local apps = {}
    local seenApps = {}

    for _, win in ipairs(hs.window.visibleWindows()) do
        local app = win:application()
        local title = win:title()

        -- Skip windows without titles (like Finder's desktop)
        -- or windows that are not standard (dialogs, etc.)
        if app and title and title ~= "" and win:isStandard() then
            local appName = app:name()
            -- Only add each app once
            if not seenApps[appName] then
                table.insert(apps, appName)
                seenApps[appName] = true
            end
        end
    end

    return apps
end

-- Function to update menubar with app icons
local function updateMenubar()
    local apps = getVisibleApps()
    local icons = {}

    -- Get icon for each app
    for _, appName in ipairs(apps) do
        local icon = icon_map[appName] or ":default:"
        table.insert(icons, icon)
    end

    -- Join icons with minimal spacing
    local iconString = table.concat(icons, " ")

    if menubar then
        -- Create styled text with custom font and baseline offset
        local styledText = hs.styledtext.new(iconString, {
            font = { name = "sketchybar-app-font", size = 15 },
            baselineOffset = -5.0,
            kerning = -1.0  -- Reduce space between characters
        })
        menubar:setTitle(styledText)
    end
end

-- Initial update
updateMenubar()

-- Watch for application events
local appWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if eventType == hs.application.watcher.launched or
       eventType == hs.application.watcher.terminated or
       eventType == hs.application.watcher.hidden or
       eventType == hs.application.watcher.unhidden then
        updateMenubar()
    end
end)
appWatcher:start()

-- Watch for window creation and destruction
local windowFilter = hs.window.filter.new()
windowFilter:subscribe({
    hs.window.filter.windowCreated,
    hs.window.filter.windowDestroyed,
    hs.window.filter.windowVisible,
    hs.window.filter.windowHidden,
    hs.window.filter.windowMinimized,
    hs.window.filter.windowUnminimized
}, function()
    updateMenubar()
end)

-- Optional: Click on menubar to refresh manually (removed to reduce padding)
-- menubar:setClickCallback(function()
--     updateMenubar()
-- end)

print("App icons menubar loaded successfully")
