-- WeChat unread count for Hammerspoon

local wechatMenubar = hs.menubar.new()
local updateTimer = nil

local WECHAT_UNREAD_ICON = "􀌥" -- chat bubble with badge
local WECHAT_READ_ICON = "􀌪" -- chat bubble

local function getUnreadCount()
	local script = [[
        tell application "System Events"
            try
                tell process "Dock"
                    if exists UI element "WeChat" of list 1 then
                        try
                            set badgeValue to value of attribute "AXStatusLabel" of UI element "WeChat" of list 1
                            if badgeValue is missing value then
                                return 0
                            else
                                return badgeValue
                            end if
                        on error
                            return 0
                        end try
                    else
                        return 0
                    end if
                end tell
            on error
                return 0
            end try
        end tell
    ]]

	local success, result = hs.osascript.applescript(script)
	if success then
		if type(result) == "number" then
			return result
		elseif type(result) == "string" then
			local numeric = tonumber(result)
			if numeric then
				return numeric
			elseif result ~= "" then
				return 1
			end
		end
	end

	return 0
end

local function openWeChat()
	hs.application.launchOrFocus("WeChat")
end

local function updateMenubar()
	if not wechatMenubar then
		return
	end

	local unreadCount = getUnreadCount()
	local title = ""

	if unreadCount > 0 then
		title = WECHAT_UNREAD_ICON .. " " .. unreadCount
	else
		title = WECHAT_READ_ICON
	end

	local styledTitle = hs.styledtext.new(title, {
		font = { name = "SF Pro Display", size = 14 },
		color = { white = 1.0 },
		baselineOffset = -2.0,
	})

	wechatMenubar:setTitle(styledTitle)

	local menuItems = {
		{
			title = "Open WeChat",
			fn = openWeChat,
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

	wechatMenubar:setMenu(menuItems)
end

local function start()
	if wechatMenubar then
		wechatMenubar:setClickCallback(openWeChat)

		updateMenubar()

		if updateTimer then
			updateTimer:stop()
		end
		updateTimer = hs.timer.doEvery(30, updateMenubar)

		print("WeChat menubar started")
	end
end

local function stop()
	if updateTimer then
		updateTimer:stop()
		updateTimer = nil
	end
	if wechatMenubar then
		wechatMenubar:delete()
		wechatMenubar = nil
	end
	print("WeChat menubar stopped")
end

local function restart()
	stop()
	wechatMenubar = hs.menubar.new()
	start()
end

local M = {}
M.start = start
M.stop = stop
M.restart = restart

start()

return M
