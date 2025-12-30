-- ~/.hammerspoon/ghostty.lua
-- Standalone Ghostty side windows: Alt+E left, Alt+D right (no split, keep main window)

local M = {}

-- ====== Fixed parameters ======
local MAIN_COLS = 125
local SIDE_COLS = 45

-- ====== Visual/tolerance parameters (tweakable) ======
local GAP = 10 -- gap between main and side window (px)
local OUTER = 10 -- margin to screen usable edges (px)
local MIN_SIDE_W = 200 -- minimum side window width (px)

local GHOSTTY_APP = "Ghostty"
local OPEN_BIN = "/usr/bin/open"

-- ====== Internal state ======
local leftWinId = nil
local rightWinId = nil
local leftAppPid = nil
local rightAppPid = nil
local pending = nil -- { side="left/right", mainId=... }

local wf = nil -- window filter
local started = false

local hotkeyLeft = nil
local hotkeyRight = nil
local hotkeysEnabled = false

-- ====== Helpers ======
local function isGhostty(win)
	return win and win:application() and win:application():name() == GHOSTTY_APP and win:isStandard()
end

local function focusedGhosttyWindow()
	local w = hs.window.focusedWindow()
	if isGhostty(w) then
		return w
	end
	return nil
end

local function getWinById(id)
	if not id then
		return nil
	end
	local w = hs.window.get(id)
	if isGhostty(w) then
		return w
	end
	return nil
end

local function maybeQuitApp(pid)
	if not pid then
		return
	end
	hs.timer.doAfter(0.2, function()
		local app = hs.application.get(pid)
		if not app then
			return
		end
		local wins = app:allWindows() or {}
		if #wins == 0 then
			if app.kill then
				local ok = app:kill()
				if ok then
					return
				end
			end
			hs.task.new("/bin/kill", nil, { "-TERM", tostring(pid) }):start()
		end
	end)
end

local function clamp(val, lo, hi)
	if val < lo then
		return lo
	end
	if val > hi then
		return hi
	end
	return val
end

local function calcSideWidthPx(mainFrameW)
	-- Convert cols to pixels based on the main window ratio (stable if main stays fixed).
	local w = math.floor(mainFrameW * (SIDE_COLS / MAIN_COLS) + 0.5)
	if w < MIN_SIDE_W then
		w = MIN_SIDE_W
	end
	return w
end

local function placeSide(mainW, sideW, side)
	local mf = mainW:frame()
	local sf = mainW:screen():frame() -- usable area (no menubar/Dock)

	local sideWpx = calcSideWidthPx(mf.w)

	local x
	if side == "right" then
		x = mf.x + mf.w + GAP
		x = clamp(x, sf.x + OUTER, (sf.x + sf.w - OUTER) - sideWpx)
	else
		x = mf.x - GAP - sideWpx
		x = clamp(x, sf.x + OUTER, (sf.x + sf.w - OUTER) - sideWpx)
	end

	local y = clamp(mf.y, sf.y + OUTER, sf.y + sf.h - OUTER - mf.h)
	local h = mf.h

	sideW:setFrame({ x = x, y = y, w = sideWpx, h = h }, 0)
end

local function setHotkeysEnabled(enabled)
	if enabled == hotkeysEnabled then
		return
	end
	hotkeysEnabled = enabled
	if not hotkeyLeft or not hotkeyRight then
		return
	end
	if enabled then
		hotkeyLeft:enable()
		hotkeyRight:enable()
	else
		hotkeyLeft:disable()
		hotkeyRight:disable()
	end
end

local function openGhosttyApp(newInstance)
	local args = { "-a", GHOSTTY_APP }
	if newInstance then
		args = { "-na", GHOSTTY_APP }
	end
	hs.task.new(OPEN_BIN, nil, args):start()
end

local function launchGhosttyWindow()
	local app = hs.application.find(GHOSTTY_APP)
	if app then
		local menuCandidates = {
			{ "Shell", "New Window" },
			{ "Shell", "New OS Window" },
			{ "File", "New Window" },
		}
		for _, path in ipairs(menuCandidates) do
			if app:selectMenuItem(path) then
				return
			end
		end
	end
	if app then
		openGhosttyApp(true)
	else
		openGhosttyApp(false)
	end
end

local function ensureSide(side)
	local mainW = focusedGhosttyWindow()
	if not mainW then
		return
	end

	local id = (side == "left") and leftWinId or rightWinId
	local sw = getWinById(id)

	if sw then
		-- Already exists: re-align (do not move main window).
		placeSide(mainW, sw, side)
		sw:focus()
		return
	end

	-- Create a new OS window and place it when windowCreated fires.
	pending = { side = side, mainId = mainW:id() }
	launchGhosttyWindow()

	-- Fallback in case the event does not fire and pending gets stuck.
	hs.timer.doAfter(0.6, function()
		if pending and pending.mainId == mainW:id() and pending.side == side then
			pending = nil
		end
	end)
end

-- ====== Public: init & hotkeys ======
function M.start(opts)
	if started then
		return
	end
	started = true
	opts = opts or {}

	-- Allow override from init.lua (optional).
	GAP = opts.gap or GAP
	OUTER = opts.outer or OUTER
	MIN_SIDE_W = opts.min_side_w or MIN_SIDE_W

	-- Subscribe to Ghostty window creation events (event-driven, light weight).
	wf = hs.window.filter.new({ GHOSTTY_APP }) -- only visible Ghostty windows (faster, cleaner)
	wf:subscribe(hs.window.filter.windowCreated, function(w)
		if not pending then
			return
		end
		if not isGhostty(w) then
			return
		end
		if w:id() == pending.mainId then
			return
		end

		local mainW = hs.window.get(pending.mainId)
		if not isGhostty(mainW) then
			pending = nil
			return
		end

		if pending.side == "left" then
			leftWinId = w:id()
			leftAppPid = w:application():pid()
			placeSide(mainW, w, "left")
		else
			rightWinId = w:id()
			rightAppPid = w:application():pid()
			placeSide(mainW, w, "right")
		end

		w:focus()
		pending = nil
	end)

	wf:subscribe(hs.window.filter.windowDestroyed, function(w)
		local id = w:id()
		if id == leftWinId then
			leftWinId = nil
			maybeQuitApp(leftAppPid)
			leftAppPid = nil
			return
		end
		if id == rightWinId then
			rightWinId = nil
			maybeQuitApp(rightAppPid)
			rightAppPid = nil
		end
	end)

	wf:subscribe(hs.window.filter.windowFocused, function()
		setHotkeysEnabled(true)
	end)
	wf:subscribe(hs.window.filter.windowUnfocused, function()
		setHotkeysEnabled(false)
	end)

	-- Hotkeys: Alt+E left, Alt+D right (only enabled when Ghostty is focused)
	hotkeyLeft = hs.hotkey.new({ "alt" }, "e", function()
		ensureSide("left")
	end)
	hotkeyRight = hs.hotkey.new({ "alt" }, "d", function()
		ensureSide("right")
	end)
	setHotkeysEnabled(focusedGhosttyWindow() ~= nil)
end

M.start()

return M
