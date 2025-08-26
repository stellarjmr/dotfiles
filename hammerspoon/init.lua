--- keybindings
local cmd_ctrl = { "cmd", "ctrl" }
local cmd_shift = { "cmd", "shift" }
local ctrl_alt = { "ctrl", "alt" }
local ctrl_shift = { "ctrl", "shift" }
local alt_shift = { "alt", "shift" }

--- reload Hammerspoon config
hs.hotkey.bind(cmd_ctrl, "h", function()
	hs.reload()
end)
hs.alert.show("Config loaded")

--- move window with arrow keys
hs.hotkey.bind(cmd_ctrl, "left", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	f.x = f.x - 40
	win:setFrame(f)
end)

hs.hotkey.bind(cmd_ctrl, "right", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	f.x = f.x + 40
	win:setFrame(f)
end)

hs.hotkey.bind(cmd_ctrl, "down", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	f.y = f.y + 20
	win:setFrame(f)
end)

hs.hotkey.bind(cmd_ctrl, "up", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	f.y = f.y - 20
	win:setFrame(f)
end)

--- resize window

--- enlarge window
hs.hotkey.bind(ctrl_alt, "=", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()
	if (f.x - 20) >= max.x then
		f.x = f.x - 20
	end
	if (f.y - 20) >= max.y then
		f.y = f.y - 20
	end
	f.w = f.w + 40
	f.h = f.h + 40
	win:setFrame(f)
end)

--- shrink window
hs.hotkey.bind(ctrl_alt, "-", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	f.x = f.x + 20
	f.y = f.y + 20
	f.w = f.w - 40
	f.h = f.h - 40
	win:setFrame(f)
end)

--- enlarge window in one direction
hs.hotkey.bind(alt_shift, "right", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	if (f.x - 40) <= 0 then
		f.w = f.w + 40
	else
		f.x = f.x + 40
		f.w = f.w - 40
	end
	win:setFrame(f)
end)
hs.hotkey.bind(alt_shift, "left", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	if (f.x - 40) <= 0 then
		f.w = f.w - 40
	else
		f.x = f.x - 40
		f.w = f.w + 40
	end
	win:setFrame(f)
end)
hs.hotkey.bind(alt_shift, "up", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	if (f.y - 40) <= 0 then
		f.h = f.h - 40
	else
		f.y = f.y - 40
		f.h = f.h + 40
	end
	win:setFrame(f)
end)

hs.hotkey.bind(alt_shift, "down", function()
	local win = hs.window.focusedWindow()
	local f = win:frame()
	if (f.y - 40) <= 0 then
		f.h = f.h + 40
	else
		f.y = f.y + 40
		f.h = f.h - 40
	end
	win:setFrame(f)
end)

--- MacOS Preview
local function isPreviewApp()
	local app = hs.application.frontmostApplication()
	return app and app:bundleID() == "com.apple.Preview"
end

local function sendCmd9()
	hs.eventtap.keyStroke({ "cmd" }, "9")
end

local function windowMoved(win, appName, event)
	if appName == "Preview" and win then
		local currentFrame = win:frame()
		local screen = win:screen():frame()

		local isHalfWidth = math.abs(currentFrame.w - screen.w / 2) < 50
		local isFullHeight = math.abs(currentFrame.h - screen.h) < 100

		if isHalfWidth or isFullHeight then
			hs.timer.doAfter(0.1, function()
				if isPreviewApp() then
					sendCmd9()
				end
			end)
		end
	end
end

local windowFilter = hs.window.filter.new("Preview")
windowFilter:subscribe({
	hs.window.filter.windowMoved,
}, windowMoved)

--- Open new finder window
-- hs.hotkey.bind({ "ctrl" }, "return", function()
-- 	local finderApp = hs.application.find("Finder")
-- 	finderApp:selectMenuItem({ "File", "New Finder Window" })
-- 	finderApp:setFrontmost()
-- end)

--- Open new safari window
-- hs.hotkey.bind(alt_shift, "return", function()
-- 	local safariApp = hs.application.find("Safari")
-- 	safariApp:selectMenuItem({ "File", "New Window" })
-- 	safariApp:setFrontmost()
-- end)

--- Open new zen window
hs.hotkey.bind(alt_shift, "return", function()
	local safariApp = hs.application.find("Zen")
	safariApp:selectMenuItem({ "File", "New Window" })
	safariApp:setFrontmost()
end)

--- Open new ghostty window
-- hs.hotkey.bind({ "alt" }, "return", function()
-- 	local ghosttyApp = hs.application.find("Ghostty")
-- 	ghosttyApp:selectMenuItem({ "File", "New Window" })
-- 	ghosttyApp:setFrontmost()
-- end)

--- Open new kitty window
hs.hotkey.bind({ "alt" }, "return", function()
	local kittyApp = hs.application.find("Kitty")
	kittyApp:selectMenuItem({ "Shell", "New OS Window" })
	kittyApp:setFrontmost()
end)

--- Toggle Finder
hs.hotkey.bind({ "ctrl" }, "F", function()
	local finder = hs.application.find("Finder")
	local finderWindows = finder:allWindows()
	if #finderWindows == 1 then
		finder:selectMenuItem({ "File", "New Finder Window" })
	elseif finder:isHidden() then
		finder:activate()
		finder:unhide()
		finder:setFrontmost()
	elseif finder:isFrontmost() then
		finder:hide()
	end
end)

local finder_selectedItems_script = [[
        tell application "Finder"
            set selectedItems to selection
            if (count of selectedItems) > 0 then
                set selectedFile to POSIX path of (item 1 of selectedItems as alias)
                return selectedFile
            else
                return ""
            end if
        end tell
    ]]

hs.hotkey.bind(cmd_shift, "o", function()
	local ok, result = hs.osascript.applescript(finder_selectedItems_script)
	if ok and result and result ~= "" then
		local command = string.format('open -a "Ovito" "%s"', result)
		hs.task.new("/bin/sh", nil, { "-c", command }):start()
	else
	end
end)
hs.hotkey.bind(cmd_shift, "v", function()
	local ok, result = hs.osascript.applescript(finder_selectedItems_script)
	if ok and result and result ~= "" then
		local command = string.format('open -a "VESTA" "%s"', result)
		hs.task.new("/bin/sh", nil, { "-c", command }):start()
	else
	end
end)
hs.hotkey.bind(cmd_shift, "c", function()
	local ok, result = hs.osascript.applescript(finder_selectedItems_script)
	if ok and result and result ~= "" then
		local command = string.format('open -a "Visual Studio Code" "%s"', result)
		hs.task.new("/bin/sh", nil, { "-c", command }):start()
	else
	end
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", function()
	hs.timer.doAfter(0.5, function()
		local app = hs.application.frontmostApplication()
		if app then
			hs.alert.show("App ID: " .. app:name())
		else
			hs.alert.show("No frontmost application detected")
		end
	end)
end)

--- Auto switch input method
-- show current input method
-- hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "I", function()
-- 	local currentInputMethod = hs.keycodes.currentSourceID()
-- 	hs.alert.show("Current Input Method: " .. currentInputMethod)
-- end)

local inputEnglish = "com.apple.keylayout.ABC"
local inputPinyin = "com.apple.inputmethod.SCIM.ITABC"

-- Spotlight
hs.hotkey.bind({ "cmd" }, "space", function()
	hs.timer.doAfter(0.1, function()
		hs.keycodes.currentSourceID(inputEnglish)
	end)
end)

-- Other apps
local englishAppFilter = hs.window.filter.new({
	"Terminal",
	"Shortcuts",
	"Mail",
	"Keynote",
	"Ghostty",
	"Kitty",
	"Visual Studio Code",
	"Microsoft Word",
	"Microsoft Excel",
	"Microsoft PowerPoint",
})

local pinyinAppFilter = hs.window.filter.new({
	"WeChat",
})

englishAppFilter:subscribe(hs.window.filter.windowFocused, function()
	hs.keycodes.currentSourceID(inputEnglish)
end)
pinyinAppFilter:subscribe(hs.window.filter.windowFocused, function()
	hs.keycodes.currentSourceID(inputPinyin)
end)

--- plugins
hs.loadSpoon("Vifari")
spoon.Vifari:start({
	-- example your local config here
	scrollStep = 150, -- Change scroll step
	mapping = {
		["n"] = { "cmd", "n" }, -- Add new mapping
		-- ["x"] = false, -- Disable a mapping
	},
})

--- Menu Bar
-- require("mail-menubar")
-- require("reminder-menubar")
-- require("brew-menubar")
-- require("music-menubar")
