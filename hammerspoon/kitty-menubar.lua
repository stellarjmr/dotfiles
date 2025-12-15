-- Kitty tabs menubar
-- Displays kitty tabs with icons similar to tmux configuration

local menubar = hs.menubar.new()
if menubar then
	menubar:setMenu({})
end

-- Icon mapping based on window/process name
local iconMap = {
	["zsh"] = " ",
	["bash"] = " ",
	["fish"] = "󰈺 ",
	["sh"] = " ",
	["yazi"] = "󰇥 ",
	["ssh"] = "󰢹 ",
	["vim"] = " ",
	["nvim"] = " ",
	["python"] = " ",
	["python3"] = " ",
	["python3.9"] = " ",
	["python3.10"] = " ",
	["python3.11"] = " ",
	["python3.12"] = " ",
	["lazygit"] = "󰊢 ",
	["ruby"] = " ",
	["fzf"] = " ",
	["node"] = "󰫢 ",
	["codex"] = "󰧑 ",
	["claude"] = " ",
	["amp"] = "󰧑 ",
	["multi_window"] = "󱂬 ",
	["default"] = "󰄛 ",
}

local function getIconForName(name)
	if not name then
		return iconMap["default"]
	end
	local lowerName = string.lower(name)

	-- Check for exact match first
	if iconMap[lowerName] then
		return iconMap[lowerName]
	end

	-- Check for partial matches (e.g., "codex" in window title)
	for key, icon in pairs(iconMap) do
		if string.find(lowerName, key, 1, true) then
			return icon
		end
	end

	return iconMap["default"]
end

-- Cache socket path and prevent overlapping requests
local cachedSocketPath = nil
local pendingTask = nil

local function findSocketPath()
	local files = hs.execute("ls /tmp/kitty* 2>/dev/null | head -1 | tr -d '\\n'")
	if files and files ~= "" then
		cachedSocketPath = files
	end
	return cachedSocketPath
end

-- Async fetch kitty tabs
local function fetchKittyTabsAsync(callback)
	-- Skip if a request is already in flight
	if pendingTask and pendingTask:isRunning() then
		return
	end

	local kittyApp = hs.application.find("kitty")
	if not kittyApp then
		callback(nil)
		return
	end

	local socketPath = cachedSocketPath or findSocketPath()
	if not socketPath then
		callback(nil)
		return
	end

	pendingTask = hs.task.new("/opt/homebrew/bin/kitten", function(exitCode, stdOut, stdErr)
		pendingTask = nil
		if exitCode ~= 0 or not stdOut or stdOut == "" then
			cachedSocketPath = nil
			callback(nil)
			return
		end
		local ok, data = pcall(hs.json.decode, stdOut)
		if ok and data then
			callback(data)
		else
			callback(nil)
		end
	end, { "@", "--to", "unix:" .. socketPath, "ls" })

	pendingTask:start()
end

local function renderMenubar(data)
	if not data or #data == 0 then
		if menubar then
			menubar:setTitle("")
		end
		return
	end

	local styledText = nil

	-- Iterate through OS windows
	for _, osWindow in ipairs(data) do
		if osWindow.is_focused then
			local tabs = osWindow.tabs or {}

			for tabIdx, tab in ipairs(tabs) do
				local isFocused = tab.is_focused or tab.is_active
				local tabTitle = tab.title or ""
				local windowCount = #(tab.windows or {})

				-- Get foreground process from the active window in the tab
				local processName = tabTitle
				if tab.windows then
					for _, win in ipairs(tab.windows) do
						if win.is_focused or win.is_active then
							if win.foreground_processes and #win.foreground_processes > 0 then
								local fg = win.foreground_processes[1]
								if fg.cmdline and #fg.cmdline > 0 then
									local cmd = fg.cmdline[1]
									processName = cmd:match("([^/]+)$") or cmd
								end
							elseif win.title then
								processName = win.title
							end
							break
						end
					end
				end

				local icon = getIconForName(processName)

				if windowCount > 1 then
					icon = iconMap["multi_window"]
				end

				local indexSegment = hs.styledtext.new(tostring(tabIdx), {
					font = { name = "0xProto Nerd Font", size = 12 },
					baselineOffset = -2.0,
					color = isFocused and { white = 1.0 } or { white = 0.8 },
				})

				local iconSegment = hs.styledtext.new(icon, {
					font = { name = "0xProto Nerd Font", size = 14 },
					baselineOffset = -3.0,
					color = isFocused and { white = 1.0 } or { white = 0.8 },
				})

				local spacer = hs.styledtext.new(" ", {
					font = { size = 10 },
				})

				if styledText == nil then
					styledText = indexSegment .. spacer .. iconSegment
				else
					styledText = styledText
						.. hs.styledtext.new("  ", { font = { size = 10 } })
						.. indexSegment
						.. spacer
						.. iconSegment
				end
			end
			break
		end
	end

	if styledText then
		menubar:setTitle(styledText)
	else
		menubar:setTitle("")
	end
end

local function updateMenubar()
	local kittyApp = hs.application.find("kitty")
	if not kittyApp or not menubar then
		if menubar then
			menubar:setTitle("")
		end
		return
	end

	fetchKittyTabsAsync(renderMenubar)
end

-- Initial update
updateMenubar()

-- Fast polling timer for tab changes (0.2 second)
local updateTimer = hs.timer.doEvery(0.2, updateMenubar)

-- Watch for kitty focus changes
local kittyWatcher = hs.application.watcher.new(function(appName, eventType, app)
	if appName == "kitty" then
		if
			eventType == hs.application.watcher.launched
			or eventType == hs.application.watcher.terminated
			or eventType == hs.application.watcher.activated
			or eventType == hs.application.watcher.deactivated
		then
			updateMenubar()
		end
	end
end)
kittyWatcher:start()

-- Watch kitty window events
local kittyWindowFilter = hs.window.filter.new("kitty")
kittyWindowFilter:subscribe({
	hs.window.filter.windowFocused,
	hs.window.filter.windowUnfocused,
	hs.window.filter.windowCreated,
	hs.window.filter.windowDestroyed,
}, function()
	updateMenubar()
end)

print("Kitty menubar loaded successfully")
