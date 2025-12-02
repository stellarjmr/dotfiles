-- Combined Mail and WeChat menubar for Hammerspoon

local menubar = hs.menubar.new()
local updateTimer = nil

local MAIL_UNREAD_ICON = "􀍜" -- envelope.badge
local MAIL_READ_ICON = "􀍖" -- envelope
local WECHAT_UNREAD_ICON = "􁒙" -- chat bubble badge
local WECHAT_READ_ICON = "􀌥" -- chat bubble

local BASE_STYLE = {
	font = { name = "SF Pro Display", size = 14 },
	color = { white = 1.0 },
	baselineOffset = -2.0,
}
local UNREAD_COLOR = { red = 0.902, green = 0.494, blue = 0.502 }

local lastMailCount = 0
local lastWeChatCount = 0

local function getMailUnreadCount()
	local script = [[
        tell application "Mail"
            try
                get the unread count of inbox
            on error
                return 0
            end try
        end tell
    ]]

	local success, result = hs.osascript.applescript(script)
	if success then
		return tonumber(result) or 0
	else
		return 0
	end
end

local function getWeChatUnreadCount()
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

local function openMail()
	hs.application.launchOrFocus("Mail")
end

local function openWeChat()
	hs.application.launchOrFocus("WeChat")
end

local function smartOpen()
	if lastWeChatCount > 0 then
		openWeChat()
	elseif lastMailCount > 0 then
		openMail()
	else
		openMail()
	end
end

local function updateMenubar()
	if not menubar then
		return
	end

	lastMailCount = getMailUnreadCount()
	lastWeChatCount = getWeChatUnreadCount()

	local mailTitle = lastMailCount > 0 and (MAIL_UNREAD_ICON .. " " .. lastMailCount) or MAIL_READ_ICON
	local wechatTitle = lastWeChatCount > 0 and (WECHAT_UNREAD_ICON .. " " .. lastWeChatCount) or WECHAT_READ_ICON

	local mailColor = lastMailCount > 0 and UNREAD_COLOR or BASE_STYLE.color
	local wechatColor = lastWeChatCount > 0 and UNREAD_COLOR or BASE_STYLE.color
	local mailStyled = hs.styledtext.new(mailTitle, {
		font = BASE_STYLE.font,
		color = mailColor,
		baselineOffset = BASE_STYLE.baselineOffset,
	})
	local spacerStyled = hs.styledtext.new("  ", BASE_STYLE)
	local wechatStyled = hs.styledtext.new(wechatTitle, {
		font = BASE_STYLE.font,
		color = wechatColor,
		baselineOffset = BASE_STYLE.baselineOffset,
	})
	local styledTitle = mailStyled .. spacerStyled .. wechatStyled

	menubar:setTitle(styledTitle)

	local menuItems = {
		{
			title = string.format("Mail: %d", lastMailCount),
			disabled = true,
		},
		{
			title = string.format("WeChat: %d", lastWeChatCount),
			disabled = true,
		},
		{
			title = "-",
		},
		{
			title = "Open Mail",
			fn = openMail,
		},
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

	menubar:setMenu(menuItems)
end

local function start()
	if menubar then
		menubar:setClickCallback(smartOpen)

		updateMenubar()

		if updateTimer then
			updateTimer:stop()
		end
		updateTimer = hs.timer.doEvery(30, updateMenubar)

		print("Mail/WeChat menubar started")
	end
end

local function stop()
	if updateTimer then
		updateTimer:stop()
		updateTimer = nil
	end
	if menubar then
		menubar:delete()
		menubar = nil
	end
	print("Mail/WeChat menubar stopped")
end

local function restart()
	stop()
	menubar = hs.menubar.new()
	start()
end

local M = {}
M.start = start
M.stop = stop
M.restart = restart

start()

return M
