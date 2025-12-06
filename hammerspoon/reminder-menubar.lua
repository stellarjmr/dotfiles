-- Reminders for Hammerspoon

local remindersMenubar = hs.menubar.new()

local REMINDERS_ICON = "􀷾" -- checklist
local INBOX_ICON = "􀐚" -- tray
local TODO_ICON = "􀀀" -- circle icon
local REFRESH_ICON = "􂣼" -- arrow.triangle.2.circlepath
local OPEN_ICON = "􀷾" -- reuse checklist for consistency
local TODO_MAX_CHARS = 10
local ICON_STYLE = {
	font = { name = "SF Pro Display", size = 14 }, -- SF Symbols-friendly for menubar
	baselineOffset = -2.0, -- nudge to align with other SF Symbol menubar icons
}
local MENU_FONT_DEFAULT = { name = "SF Pro Display", size = 14 }
local MENU_FONT_SMALL = { name = "SF Pro Display", size = 13 }

local function styledMenuText(text, opts)
	local o = opts or {}
	local style = {
		font = o.font or MENU_FONT_DEFAULT,
		color = o.color or { red = 0.0, green = 0.0, blue = 0.0 },
		baselineOffset = ICON_STYLE.baselineOffset,
	}
	return hs.styledtext.new(text, style)
end

local function truncateText(str, maxChars)
	if not str then
		return ""
	end
	local maxc = maxChars or TODO_MAX_CHARS
	if utf8.len(str) and utf8.len(str) > maxc then
		local cut = utf8.offset(str, maxc + 1)
		if cut then
			return string.sub(str, 1, cut - 1) .. "…"
		end
	end
	return str
end

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

	local styledTitle = hs.styledtext.new(REMINDERS_ICON, ICON_STYLE)

	remindersMenubar:setTitle(styledTitle)

	local reminderList = getReminders()
	local menuItems = {}

	table.insert(menuItems, {
		title = styledMenuText(INBOX_ICON .. " Inbox", {
			font = { name = "SF Pro Display", size = 14, style = "bold" },
		}),
	})

	table.insert(menuItems, { title = "-" })

	if reminderList == "No Todos!" or reminderList == "Error accessing Reminders" then
		table.insert(menuItems, {
			title = styledMenuText("􀷾  No Todos!", { font = MENU_FONT_SMALL }),
			disabled = true,
		})
	else
		for line in reminderList:gmatch("[^\r\n]+") do
			if line and line:len() > 0 then
				local displayText = truncateText(line, TODO_MAX_CHARS)
				table.insert(menuItems, {
					title = styledMenuText(TODO_ICON .. "  " .. displayText, {
						font = MENU_FONT_SMALL,
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
		title = styledMenuText(OPEN_ICON .. " Open Reminders"),
		fn = openReminders,
	})

	table.insert(menuItems, {
		title = styledMenuText(REFRESH_ICON .. " Refresh"),
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
