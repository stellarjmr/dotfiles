local M = {}

local BUNDLE_ID = "com.izual.Easydict"
local APP_NAME = "Easydict"
local IDLE_SECONDS = 90

local idleTimer = nil
local eventtap = nil
local watcher = nil
local launching = false
local replaying = false

local function getApp()
	return hs.application.get(BUNDLE_ID)
end

local function scheduleIdleQuit()
	if idleTimer then
		idleTimer:stop()
	end
	idleTimer = hs.timer.doAfter(IDLE_SECONDS, function()
		local app = getApp()
		if not app then
			return
		end
		local front = hs.application.frontmostApplication()
		if front and front:bundleID() == BUNDLE_ID then
			scheduleIdleQuit()
			return
		end
		app:kill()
	end)
end

local function replayAltA()
	replaying = true
	hs.eventtap.keyStroke({ "alt" }, "a", 10000)
	scheduleIdleQuit()
end

local function launchAndReplay()
	if launching then
		return
	end
	launching = true
	hs.task.new("/usr/bin/open", function() end, { "-g", "-a", APP_NAME }):start()
	local attempts = 0
	local pollTimer
	pollTimer = hs.timer.doEvery(0.05, function()
		attempts = attempts + 1
		if getApp() then
			pollTimer:stop()
			hs.timer.doAfter(0.3, function()
				launching = false
				replayAltA()
			end)
			return
		end
		if attempts >= 100 then
			pollTimer:stop()
			launching = false
		end
	end)
end

function M.start()
	eventtap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local flags = event:getFlags()
		if not flags.alt or flags.cmd or flags.ctrl or flags.shift or flags.fn then
			return false
		end
		if event:getKeyCode() ~= hs.keycodes.map.a then
			return false
		end

		if replaying then
			replaying = false
			return false
		end

		local front = hs.application.frontmostApplication()
		local passthroughApps = {
			["com.apple.Safari"] = true,
			["app.zen-browser.zen"] = true,
		}
		if front and passthroughApps[front:bundleID()] then
			local target = front
			hs.timer.doAfter(0, function()
				hs.eventtap.event.newKeyEvent({ "alt" }, "a", true):post(target)
				hs.eventtap.event.newKeyEvent({ "alt" }, "a", false):post(target)
			end)
			return true
		end

		if getApp() then
			scheduleIdleQuit()
			return false
		end

		launchAndReplay()
		return true
	end)
	eventtap:start()

	watcher = hs.application.watcher.new(function(appName, eventType, appObject)
		local bid = appObject and appObject:bundleID()
		if bid ~= BUNDLE_ID and appName ~= APP_NAME then
			return
		end
		if eventType == hs.application.watcher.launched and not launching then
			scheduleIdleQuit()
		end
	end)
	watcher:start()
end

M.start()

return M
