--- keybindings
local cmd_ctrl = { "cmd", "ctrl" }
local cmd_shift = { "cmd", "shift" }
local ctrl_alt = { "ctrl", "alt" }
local ctrl_shift = { "ctrl", "shift" }
local alt_shift = { "alt", "shift" }
local ctrl = { "ctrl" }

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

--- center window
hs.hotkey.bind(ctrl_alt, "C", function()
	local win = hs.window.focusedWindow()
	if win then
		win:centerOnScreen()
	end
end)

--- auto-center kitty windows on launch
-- local function centerKittyWindow(target, attempt)
-- 	attempt = attempt or 1
-- 	if attempt > 8 or not target then
-- 		return
-- 	end
--
-- 	-- target can be an app or a window
-- 	local win = target.mainWindow and target:mainWindow() or target
-- 	if win then
-- 		win:centerOnScreen(nil, true)
-- 		return
-- 	end
--
-- 	hs.timer.doAfter(0.2, function()
-- 		centerKittyWindow(target, attempt + 1)
-- 	end)
-- end
--
-- local kittyWatcher = hs.application.watcher.new(function(appName, event, app)
-- 	if appName == "kitty" and event == hs.application.watcher.launched then
-- 		hs.timer.doAfter(0.3, function()
-- 			centerKittyWindow(app)
-- 		end)
-- 	end
-- end)
-- kittyWatcher:start()
--
-- local kittyWindowFilter = hs.window.filter.new("kitty")
-- kittyWindowFilter:subscribe(hs.window.filter.windowCreated, function(win)
-- 	hs.timer.doAfter(0.1, function()
-- 		centerKittyWindow(win)
-- 	end)
-- end)

--- resize Zen windows on creation/focus
local zenWindowSizeRatio = { width = 0.6, height = 0.85 }
local zenWindowUnitRect = hs.geometry.rect(
	(1 - zenWindowSizeRatio.width) / 2,
	(1 - zenWindowSizeRatio.height) / 2,
	zenWindowSizeRatio.width,
	zenWindowSizeRatio.height
)
local zenResizeMaxAttempts = 6

local function resizeZenWindow(winId, attempt)
	attempt = attempt or 1
	if not winId or attempt > zenResizeMaxAttempts then
		return
	end

	local win = hs.window.get(winId)
	if not win then
		return
	end

	local screen = win:screen()
	if not screen then
		hs.timer.doAfter(0.3, function()
			resizeZenWindow(winId, attempt + 1)
		end)
		return
	end

	if not win:isStandard() then
		hs.timer.doAfter(0.3, function()
			resizeZenWindow(winId, attempt + 1)
		end)
		return
	end

	win:moveToUnit(zenWindowUnitRect, 0)

	hs.timer.doAfter(0.15, function()
		local liveWin = hs.window.get(winId)
		if not liveWin then
			return
		end

		local liveScreen = liveWin:screen()
		if not liveScreen then
			return
		end

		local frame = liveWin:frame()
		local screenFrame = liveScreen:frame()
		local targetW = screenFrame.w * zenWindowSizeRatio.width
		local targetH = screenFrame.h * zenWindowSizeRatio.height

		if math.abs(frame.w - targetW) > 1 or math.abs(frame.h - targetH) > 1 then
			resizeZenWindow(winId, attempt + 1)
		end
	end)
end

local zenWindowFilter = hs.window.filter.new("Zen")
zenWindowFilter:subscribe({
	hs.window.filter.windowCreated,
	-- hs.window.filter.windowFocused,
}, function(win)
	if not win then
		return
	end

	hs.timer.doAfter(0.1, function()
		local winId = win:id()
		if not winId then
			return
		end

		resizeZenWindow(winId)
	end)
end)

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

--- Open new zotero window
hs.hotkey.bind({ "ctrl" }, "return", function()
	local zoteroApp = hs.application.find("Zotero")
	if not zoteroApp then
		hs.application.launchOrFocus("Zotero")
		return
	end

	if zoteroApp:isHidden() then
		zoteroApp:unhide()
	end

	if #zoteroApp:allWindows() == 0 then
		if not zoteroApp:selectMenuItem({ "File", "New Window" }) then
			hs.execute("/usr/bin/open -a Zotero")
		end
	end

	zoteroApp:setFrontmost()
end)

--- Open new browser window
hs.hotkey.bind(alt_shift, "return", function()
	local zenApp = hs.application.find("Zen")
	if zenApp and #zenApp:allWindows() > 0 then
		zenApp:setFrontmost()
	else
		if zenApp then
			zenApp:selectMenuItem({ "File", "New Window" })
			zenApp:setFrontmost()
		end
	end
end)

--- Open new terminal window
hs.hotkey.bind({ "alt" }, "return", function()
	local ghosttyApp = hs.application.find("kitty")
	if ghosttyApp and #ghosttyApp:allWindows() > 0 then
		ghosttyApp:setFrontmost()
	else
		if ghosttyApp then
			-- ghosttyApp:selectMenuItem({ "File", "New Window" })
			ghosttyApp:selectMenuItem({ "Shell", "New OS Window" })
			ghosttyApp:setFrontmost()
		end
	end
end)
hs.hotkey.bind(ctrl_alt, "return", function()
	local ghosttyApp = hs.application.find("ghostty")
	if ghosttyApp and #ghosttyApp:allWindows() > 0 then
		ghosttyApp:setFrontmost()
	else
		if ghosttyApp then
			ghosttyApp:selectMenuItem({ "File", "New Window" })
			ghosttyApp:setFrontmost()
		end
	end
end)

--- Open new vscode/zed window
hs.hotkey.bind(cmd_ctrl, "return", function()
	hs.application.launchOrFocus("Zed")
	-- local codeApp = hs.application.find("Code")
	-- if codeApp and #codeApp:allWindows() > 0 then
	-- 	codeApp:setFrontmost()
	-- else
	-- 	if codeApp then
	-- 		codeApp:selectMenuItem({ "File", "New Window" })
	-- 		codeApp:setFrontmost()
	-- 	end
	-- end
end)

--- Open Apps.app
-- hs.hotkey.bind({ "cmd" }, "space", function()
-- 	hs.application.launchOrFocus("Apps.app")
-- end)

--- Toggle Finder
hs.hotkey.bind({ "ctrl" }, "F", function()
	local finder = hs.application.find("Finder")
	local finderWindows = finder:allWindows()
	if #finderWindows == 1 then
		finder:selectMenuItem({ "File", "New Finder Window" })
	end
	if #finderWindows > 1 then
		if finder:isHidden() then
			finder:activate()
			finder:unhide()
			finder:setFrontmost()
		elseif not finder:isFrontmost() then
			finder:activate()
			finder:setFrontmost()
		elseif finder:isFrontmost() then
			finder:hide()
		end
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

local function openSelectedInApp(appName)
	local ok, result = hs.osascript.applescript(finder_selectedItems_script)
	if not (ok and result and result ~= "") then
		return
	end

	-- AppleScript may return a path with trailing newline; trim it to keep open happy
	result = string.gsub(result, "%s+$", "")

	if appName == "Visual Studio Code" then
		local escaped = result:gsub('"', '\\"')
		local osa = string.format(
			[[
tell application "Visual Studio Code"
	activate
	open POSIX file "%s"
end tell
]],
			escaped
		)

		local okExec, err = hs.osascript.applescript(osa)
		if not okExec then
			hs.console.printStyledtext(string.format("[openSelectedInApp] AppleScript error: %s\n", err or "unknown"))
		end
		return
	end

	local cmd = string.format("/usr/bin/open -a %q %q", appName, result)
	local _, ok, _, rc = hs.execute(cmd)
	if not ok then
		hs.console.printStyledtext(
			string.format("openSelectedInApp(%s) failed rc=%s cmd=%s\n", appName, tostring(rc), cmd)
		)
	end
end

hs.hotkey.bind(cmd_shift, "z", function()
	openSelectedInApp("Zed")
end)
hs.hotkey.bind(cmd_shift, "x", function()
	openSelectedInApp("Ovito")
end)
hs.hotkey.bind(cmd_shift, "v", function()
	openSelectedInApp("VESTA")
end)
hs.hotkey.bind(cmd_shift, "c", function()
	openSelectedInApp("Visual Studio Code")
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
local inputEnglish = "com.apple.keylayout.ABC"
local inputPinyin = "com.apple.inputmethod.SCIM.ITABC"

-- Other apps
local englishAppFilter = hs.window.filter.new({
	"Terminal",
	"Safari",
	"Shortcuts",
	"Mail",
	"Keynote",
	"Ghostty",
	"kitty",
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

--- Menu Bar
-- require("safari")
-- require("message")
-- require("calendar-menubar")
-- require("reminder-menubar")
-- require("brew-menubar")
-- require("music-menubar")
require("app_icons_menubar")
require("kitty")
-- require("ghostty")
require("kitty-menubar")
require("safari-scholar-google").start()
require("zotero")
