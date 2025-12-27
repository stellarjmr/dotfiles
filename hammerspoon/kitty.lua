-- ~/.hammerspoon/kitty.lua
-- Standalone kitty side windows: Alt+E left (yazi), Alt+D right (no split, keep main window)

local M = {}

-- ====== Fixed parameters ======
local MAIN_COLS = 125
local MAIN_ROWS = 35
local SIDE_COLS = 40

-- ====== Visual/tolerance parameters (tweakable) ======
local GAP = 10 -- gap between main and side window (px)
local OUTER = 10 -- margin to screen usable edges (px)
local MIN_SIDE_W = 200 -- minimum side window width (px)

-- kitty executable path (default install location)
local KITTY_BIN = "/Applications/kitty.app/Contents/MacOS/kitty"
local KITTEN_BIN = "/opt/homebrew/bin/kitten"

-- ====== Internal state ======
local leftWinId = nil
local rightWinId = nil
local leftAppPid = nil
local rightAppPid = nil
local pending = nil -- { side="left/right", mainId=... }

local wf = nil -- window filter
local started = false

local cachedSocketPath = nil

-- ====== Helpers ======
local function isKitty(win)
	return win and win:application() and win:application():name() == "kitty" and win:isStandard()
end

local function focusedKittyWindow()
	local w = hs.window.focusedWindow()
	if isKitty(w) then
		return w
	end
	return nil
end

local function getWinById(id)
	if not id then
		return nil
	end
	local w = hs.window.get(id)
	if isKitty(w) then
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

local function hasKitten()
	return hs.fs.attributes(KITTEN_BIN) ~= nil
end

local function findSocketPath()
	if cachedSocketPath then
		return cachedSocketPath
	end
	local path = hs.execute("ls /tmp/kitty* 2>/dev/null | head -1 | tr -d '\\n'")
	if path and path ~= "" then
		cachedSocketPath = path
	end
	return cachedSocketPath
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

local function launchKittyWindowDirect(cmd, env)
	-- Don't use --geometry (not supported on macOS); just create a new OS window.
	local args = { "--detach" }
	if cmd and #cmd > 0 then
		for i = 1, #cmd do
			table.insert(args, cmd[i])
		end
	end
	local task = hs.task.new(KITTY_BIN, nil, args)
	if env and task.setEnvironment then
		task:setEnvironment(env)
	end
	task:start()
end

local function launchKittyWindow(cmd, env)
	local socketPath = findSocketPath()
	if socketPath and hasKitten() then
		local args = { "@", "--to", "unix:" .. socketPath, "launch", "--type=os-window", "--cwd=current" }
		if env then
			for key, value in pairs(env) do
				table.insert(args, "--env")
				table.insert(args, key .. "=" .. value)
			end
		end
		if cmd and #cmd > 0 then
			for i = 1, #cmd do
				table.insert(args, cmd[i])
			end
		end
		local task = hs.task.new(KITTEN_BIN, function(exitCode, _, _)
			if exitCode ~= 0 then
				cachedSocketPath = nil
				launchKittyWindowDirect(cmd, env)
			end
		end, args)
		task:start()
		return
	end
	launchKittyWindowDirect(cmd, env)
end

local function ensureSide(side)
	local mainW = focusedKittyWindow()
	if not mainW then
		hs.alert.show("Focus the main kitty window first")
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
	if side == "left" then
		launchKittyWindow({ "yazi" }, { YAZI_MAX_CURRENT = "1" })
	else
		launchKittyWindow()
	end

	-- Fallback in case the event does not fire and pending gets stuck.
	hs.timer.doAfter(0.6, function()
		if pending and pending.mainId == mainW:id() and pending.side == side then
			pending = nil
			hs.alert.show("No new kitty window detected (make sure kitty can open a new window)")
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
	-- If you want to override cols later, expose them here:
	-- MAIN_COLS = opts.main_cols or MAIN_COLS
	-- SIDE_COLS = opts.side_cols or SIDE_COLS

	-- Subscribe to kitty window creation events (event-driven, light weight).
	wf = hs.window.filter.new({ "kitty" }) -- only visible kitty windows (faster, cleaner)
	wf:subscribe(hs.window.filter.windowCreated, function(w)
		if not pending then
			return
		end
		if not isKitty(w) then
			return
		end
		if w:id() == pending.mainId then
			return
		end

		local mainW = hs.window.get(pending.mainId)
		if not isKitty(mainW) then
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

	-- Hotkeys: Alt+E left, Alt+D right
	hs.hotkey.bind({ "alt" }, "e", function()
		ensureSide("left")
	end)
	hs.hotkey.bind({ "alt" }, "d", function()
		ensureSide("right")
	end)
end

M.start()

return M
