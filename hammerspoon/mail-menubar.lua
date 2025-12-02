-- Mail Unread Count for Hammerspoon
local mailMenubar = hs.menubar.new()
local updateTimer = nil

local MAIL_UNREAD_ICON = "􀍜" -- envelope.badge
local MAIL_READ_ICON = "􀍖" -- envelope

local function getUnreadCount()
	local script = [[
        tell application "Mail"
            try
                get the unread count of inbox
            on error
                return 0
            end try
        end tell
    ]]

	local success, result = hs.applescript(script)
	if success then
		return tonumber(result) or 0
	else
		return 0
	end
end

local function openMail()
	hs.application.launchOrFocus("Mail")
end

local function updateMenubar()
	if not mailMenubar then
		return
	end

	local unreadCount = getUnreadCount()
	local title = ""

	if unreadCount > 0 then
		title = MAIL_UNREAD_ICON .. " " .. unreadCount
	else
		title = MAIL_READ_ICON
	end

	local styledTitle = hs.styledtext.new(title, {
		font = { name = "SF Pro Display", size = 14 },
		color = { white = 1.0 },
		baselineOffset = -2.0,
	})

	mailMenubar:setTitle(styledTitle)

	local menuItems = {
		{
			title = "Open Mail",
			fn = openMail,
		},
		{
			title = "-",
		},
		{
			title = "Refresh",
			fn = function()
				updateMenubar()
			end,
		},
	}

	mailMenubar:setMenu(menuItems)
end

local function start()
	if mailMenubar then
		mailMenubar:setClickCallback(openMail)

		updateMenubar()

		if updateTimer then
			updateTimer:stop()
		end
		updateTimer = hs.timer.doEvery(30, updateMenubar)

		print("Mail menubar started")
	end
end

local function stop()
	if updateTimer then
		updateTimer:stop()
		updateTimer = nil
	end
	if mailMenubar then
		mailMenubar:delete()
		mailMenubar = nil
	end
	print("Mail menubar stopped")
end

local function restart()
	stop()
	mailMenubar = hs.menubar.new()
	start()
end

local M = {}
M.start = start
M.stop = stop
M.restart = restart

start()

return M
