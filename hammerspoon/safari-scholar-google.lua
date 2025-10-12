-- Automatically handle iCloud Private Relay dialog for scholar.google.com in Safari

local module = {}

-- Track which tabs have already been processed to avoid repeated attempts
local processedTabs = {}

-- AppleScript to get current Safari URL
local getSafariURLScript = [[
    tell application "Safari"
        if (count of windows) > 0 then
            try
                set currentURL to URL of current tab of front window
                return currentURL
            on error
                return ""
            end try
        else
            return ""
        end if
    end tell
]]

-- AppleScript to trigger the menu action
local triggerReloadAndShowIPScript = [[
    tell application "System Events"
        tell process "Safari"
            try
                click menu item "Reload and Show IP Address" of menu "View" of menu bar 1
                return "success"
            on error errMsg
                return "error: " & errMsg
            end try
        end tell
    end tell
]]

-- AppleScript to click Continue button in the dialog
local clickContinueScript = [[
    tell application "System Events"
        tell process "Safari"
            repeat with i from 1 to 30
                if exists button "Continue" of front window then
                    click button "Continue" of front window
                    return "clicked"
                end if
                delay 0.05
            end repeat
            return "not found"
        end tell
    end tell
]]

-- Function to check if URL contains scholar.google.com
local function isScholarGoogle(url)
	if not url or url == "" then
		return false
	end
	return string.find(url, "scholar%.google%.com") ~= nil
end

-- Function to handle the scholar.google.com workflow
local function handleScholarGoogle()
	-- Get current Safari URL
	local ok, url = hs.osascript.applescript(getSafariURLScript)

	if not ok or not url or url == "" then
		return
	end

	-- Check if it's scholar.google.com
	if isScholarGoogle(url) then
		-- Create a unique identifier for this tab
		local tabId = url

		-- Check if we've already processed this tab recently
		if processedTabs[tabId] and (os.time() - processedTabs[tabId]) < 60 then
			-- Skip if processed within the last 60 seconds
			return
		end

		-- hs.alert.show("Handling iCloud Private Relay for Scholar...")

		-- Mark this tab as processed
		processedTabs[tabId] = os.time()

		-- Trigger the menu action immediately
		local menuOk, menuResult = hs.osascript.applescript(triggerReloadAndShowIPScript)

		if menuOk and menuResult == "success" then
			-- Click Continue button immediately (AppleScript will poll for it)
			hs.timer.doAfter(0.05, function()
				local btnOk, btnResult = hs.osascript.applescript(clickContinueScript)

				if btnOk and btnResult == "clicked" then
					-- hs.alert.show("Scholar access enabled!")
				else
					-- Fallback: try pressing Return key (often works for default button)
					hs.eventtap.keyStroke({}, "return")
				end
			end)
		end
	end
end

-- Set up Safari window filter to monitor window focus
function module.start()
	-- Monitor Safari window focus events
	module.safariFilter = hs.window.filter.new("Safari")

	module.safariFilter:subscribe({
		hs.window.filter.windowFocused,
		hs.window.filter.windowCreated,
	}, function(window, appName, event)
		-- Minimal delay to ensure URL is available
		hs.timer.doAfter(0.05, handleScholarGoogle)
	end)

	-- Also check more frequently when Safari is frontmost (in case of navigation within tabs)
	module.timer = hs.timer.new(0.5, function()
		local safari = hs.application.find("Safari")
		if safari and safari:isFrontmost() then
			handleScholarGoogle()
		end
	end)
	module.timer:start()
end

function module.stop()
	if module.safariFilter then
		module.safariFilter:unsubscribeAll()
		module.safariFilter = nil
	end
	if module.timer then
		module.timer:stop()
		module.timer = nil
	end
	processedTabs = {}
end

return module
