-- Homebrew Updates for Hammerspoon

local brewMenubar = hs.menubar.new()
local updateTimer = nil

local colors = {
	RED = { red = 1.0, green = 0.0, blue = 0.0 },
	ORANGE = { red = 1.0, green = 0.65, blue = 0.0 },
	YELLOW = { red = 1.0, green = 1.0, blue = 0.0 },
	WHITE = { red = 1.0, green = 1.0, blue = 1.0 },
	GREEN = { red = 0.0, green = 1.0, blue = 0.0 },
}

local CHECK_ICON = "􀐛" -- checkmark

local function getOutdatedCount()
	local task = hs.task.new("/opt/homebrew/bin/brew", function(exitCode, stdOut, stdErr)
		if exitCode == 0 then
			local lines = {}
			for line in stdOut:gmatch("[^\r\n]+") do
				if line:match("%S") then
					table.insert(lines, line)
				end
			end
			local count = #lines
			print("Brew outdated count: " .. count)
			updateMenubarDisplay(count, lines)
		else
			print("Brew command failed: " .. (stdErr or "unknown error"))
			updateMenubarDisplay(-1, {})
		end
	end, { "outdated" })

	task:start()
end

local function getOutdatedCountSync()
	local handle = io.popen("/opt/homebrew/bin/brew outdated 2>/dev/null")
	if not handle then
		handle = io.popen("/usr/local/bin/brew outdated 2>/dev/null")
	end

	if handle then
		local result = handle:read("*a")
		handle:close()

		local count = 0
		local packages = {}

		if result then
			for line in result:gmatch("[^\r\n]+") do
				if line:match("%S") then
					count = count + 1
					local packageName = line:match("^(%S+)")
					if packageName then
						table.insert(packages, packageName)
					end
				end
			end
		end

		return count, packages
	end

	return -1, {}
end

local function getColorForCount(count)
	if count >= 20 then
		return colors.RED
	elseif count >= 10 then
		return colors.ORANGE
	elseif count >= 1 then
		return colors.WHITE
	elseif count == 0 then
		return colors.WHITE
	else
		return colors.WHITE
	end
end

local function updateMenubarDisplay(count, packages)
	if not brewMenubar then
		return
	end

	local displayText = ""
	local color = colors.WHITE

	if count == 0 then
		displayText = CHECK_ICON
		color = colors.WHITE
	elseif count > 0 then
		displayText = CHECK_ICON .. " " .. tostring(count)
		color = getColorForCount(count)
	else
		displayText = "?"
		color = colors.WHITE
	end

	local styledTitle = hs.styledtext.new(displayText, {
		font = { name = "SF Pro Display", size = 14 },
		color = color,
	})

	brewMenubar:setTitle(styledTitle)

	local menuItems = {}

	if count > 0 then
		table.insert(menuItems, {
			title = hs.styledtext.new("􀐚 " .. count .. " packages to update", {
				font = { name = "SF Pro Display", size = 14, style = "bold" },
				color = color,
			}),
			disabled = true,
		})

		table.insert(menuItems, { title = "-" })

		local showCount = math.min(#packages, 10)
		for i = 1, showCount do
			table.insert(menuItems, {
				title = "  " .. packages[i],
				fn = function()
					hs.pasteboard.setContents("brew upgrade " .. packages[i])
					hs.alert.show("Copied: brew upgrade " .. packages[i], 2)
				end,
			})
		end

		if #packages > 10 then
			table.insert(menuItems, {
				title = "  ... and " .. (#packages - 10) .. " more",
				disabled = true,
			})
		end

		table.insert(menuItems, { title = "-" })

		table.insert(menuItems, {
			title = "🔄 Update All",
			fn = function()
				hs.pasteboard.setContents("brew upgrade")
				hs.alert.show("Copied: brew upgrade", 2)
			end,
		})
	else
		table.insert(menuItems, {
			title = "✅ All packages up to date",
			disabled = true,
		})
	end

	table.insert(menuItems, { title = "-" })

	table.insert(menuItems, {
		title = "🔍 Check for Updates",
		fn = function()
			hs.alert.show("Checking for updates...", 1)
			getOutdatedCount()
		end,
	})

	table.insert(menuItems, {
		title = "🍺 Open Homebrew Website",
		fn = function()
			hs.urlevent.openURL("https://brew.sh")
		end,
	})

	brewMenubar:setMenu(menuItems)
end

local function start()
	if brewMenubar then
		local count, packages = getOutdatedCountSync()
		updateMenubarDisplay(count, packages)

		if updateTimer then
			updateTimer:stop()
		end
		updateTimer = hs.timer.doEvery(2 * 60 * 60, getOutdatedCount)

		print("Homebrew menubar started")
	end
end

local function stop()
	if updateTimer then
		updateTimer:stop()
		updateTimer = nil
	end
	if brewMenubar then
		brewMenubar:delete()
		brewMenubar = nil
	end
	print("Homebrew menubar stopped")
end

local function restart()
	stop()
	brewMenubar = hs.menubar.new()
	start()
end

local M = {}
M.start = start
M.stop = stop
M.restart = restart
M.update = getOutdatedCount

start()

return M
