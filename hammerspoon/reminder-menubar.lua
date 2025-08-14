-- Reminders for Hammerspoon

local remindersMenubar = hs.menubar.new()

local REMINDERS_ICON = "􀷾" -- checklist
local INBOX_ICON = "􀐚" -- tray
local TODO_ICON = "􀀀" -- circle icon

local function getReminders()
	local script = [[
        tell application "Reminders"
            try
                set activeReminders to (reminders of list "Inbox" whose completed is false)
                if activeReminders is not {} then
                    set reminderNames to {}
                    repeat with reminderItem in activeReminders
                        set end of reminderNames to name of reminderItem
                    end repeat
                    set AppleScript's text item delimiters to "\n"
                    return reminderNames as string
                else
                    return "No Todos!"
                end if
            on error
                return "Error accessing Reminders"
            end try
        end tell
    ]]

	local success, result = hs.applescript(script)
	if success then
		return result
	else
		return "Error accessing Reminders"
	end
end

local function markReminderDone(reminderName)
	local script = string.format(
		[[
        tell application "Reminders"
            try
                set activeReminders to (reminders of list "Inbox" whose completed is false)
                repeat with reminderItem in activeReminders
                    if name of reminderItem is "%s" then
                        set completed of reminderItem to true
                        exit repeat
                    end if
                end repeat
            on error
                -- error handling
            end try
        end tell
    ]],
		reminderName:gsub('"', '\\"')
	)
	hs.applescript(script)
end

local function openReminders()
	hs.application.launchOrFocus("Reminders")
end

local function updateMenubar()
	if not remindersMenubar then
		return
	end

	local styledTitle = hs.styledtext.new(REMINDERS_ICON, {
		font = { name = "SF Pro Display", size = 14 },
		color = { white = 1.0 },
	})

	remindersMenubar:setTitle(styledTitle)

	local reminderList = getReminders()
	local menuItems = {}

	table.insert(menuItems, {
		title = hs.styledtext.new(INBOX_ICON .. " Inbox", {
			font = { name = "SF Pro Display", size = 13, style = "bold" },
			color = { red = 0.37, green = 0.56, blue = 0.35 },
		}),
		disabled = true,
	})

	table.insert(menuItems, { title = "-" })

	if reminderList == "No Todos!" or reminderList == "Error accessing Reminders" then
		table.insert(menuItems, {
			title = "  No Todos!",
			disabled = true,
		})
	else
		for line in reminderList:gmatch("[^\r\n]+") do
			if line and line:len() > 0 then
				table.insert(menuItems, {
					title = hs.styledtext.new(TODO_ICON .. "  " .. line, {
						font = { name = "SF Pro Display", size = 12 },
						color = { red = 0.37, green = 0.56, blue = 0.35 },
					}),
					fn = function()
						markReminderDone(line)
					end,
				})
			end
		end
	end

	table.insert(menuItems, { title = "-" })

	table.insert(menuItems, {
		title = "Open Reminders",
		fn = openReminders,
	})

	table.insert(menuItems, {
		title = "Refresh",
		fn = function()
			updateMenubar()
		end,
	})

	remindersMenubar:setMenu(menuItems)
end

local function start()
	if remindersMenubar then
		remindersMenubar:setClickCallback(function() end)

		updateMenubar()
	end
end

local function stop()
	if remindersMenubar then
		remindersMenubar:delete()
		remindersMenubar = nil
	end
	print("Reminders menubar stopped")
end

local function restart()
	stop()
	remindersMenubar = hs.menubar.new()
	start()
end

local M = {}
M.start = start
M.stop = stop
M.restart = restart
M.updateMenubar = updateMenubar

start()

return M
