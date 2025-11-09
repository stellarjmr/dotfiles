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
    local focusedApp = hs.application.frontmostApplication()
    local focusedAppName = focusedApp and focusedApp:name() or nil

    if menubar and #apps > 0 then
        -- Build styled text with different colors for focused/unfocused apps
        local styledText = nil

        for i, appName in ipairs(apps) do
            local icon = icon_map[appName] or ":default:"
            local isFocused = (appName == focusedAppName)

            -- Create styled segment for this icon with more noticeable color difference
            local segment = hs.styledtext.new(icon, {
                font = { name = "sketchybar-app-font", size = 15 },
                baselineOffset = -5.0,
                color = isFocused and { white = 1.0 } or { white = 0.75 }  -- Bright white for focused, dimmed for others
            })

            if styledText == nil then
                styledText = segment
            else
                styledText = styledText .. segment
            end

            -- Add spacing between icons (except after the last one)
            if i < #apps then
                local spacer = hs.styledtext.new(" ", {
                    font = { name = "sketchybar-app-font", size = 15 },
                    baselineOffset = -5.0,
                    kerning = -1.0
                })
                styledText = styledText .. spacer
            end
        end

        menubar:setTitle(styledText)
    elseif menubar then
        menubar:setTitle("")
    end
end

-- Initial update
updateMenubar()

-- Track last focused app to avoid unnecessary updates
local lastFocusedApp = nil

-- Fast polling timer for focus changes (0.1 second)
local focusTimer = hs.timer.doEvery(0.1, function()
    local currentFocused = hs.application.frontmostApplication()
    local currentName = currentFocused and currentFocused:name() or nil

    if currentName ~= lastFocusedApp then
        lastFocusedApp = currentName
        updateMenubar()
    end
end)

-- Watch for application events
local appWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if eventType == hs.application.watcher.launched or
       eventType == hs.application.watcher.terminated or
       eventType == hs.application.watcher.hidden or
       eventType == hs.application.watcher.unhidden or
       eventType == hs.application.watcher.activated then  -- Update on focus change
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
    hs.window.filter.windowUnminimized,
    hs.window.filter.windowFocused  -- Add focus event for faster response
}, function()
    updateMenubar()
end)

-- Optional: Click on menubar to refresh manually (removed to reduce padding)
-- menubar:setClickCallback(function()
--     updateMenubar()
-- end)

print("App icons menubar loaded successfully")
