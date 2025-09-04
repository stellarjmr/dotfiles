--- Safari auto esc
-- local function autoEscAfterSearch()
-- 	local enterTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
-- 		local keyCode = event:getKeyCode()
-- 		if keyCode == 36 then
-- 			local currentApp = hs.application.frontmostApplication()
-- 			if currentApp and currentApp:name() == "Safari" then
-- 				hs.timer.doAfter(1, function()
-- 					hs.eventtap.keyStroke({}, "escape")
-- 				end)
-- 			end
-- 		end
-- 		return false
-- 	end)
--
-- 	enterTap:start()
-- 	return enterTap
-- end
--
-- local safariEscTap = autoEscAfterSearch()
-- safariEscTap:start()
-- return safariEscTap
--- Safari auto esc
local safariEscTap = nil
local pendingTimer = nil

local function autoEscAfterSearch()
	local safariApp = nil
	local lastAppCheck = 0
	local APP_CHECK_INTERVAL = 5

	local enterTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()

		if keyCode ~= 36 then
			return false
		end

		local currentTime = os.time()

		if not safariApp or (currentTime - lastAppCheck) > APP_CHECK_INTERVAL then
			local currentApp = hs.application.frontmostApplication()
			if currentApp and currentApp:name() == "Safari" then
				safariApp = currentApp
				lastAppCheck = currentTime
			else
				safariApp = nil
				return false
			end
		end

		if safariApp and safariApp:isRunning() then
			if pendingTimer then
				pendingTimer:stop()
			end

			pendingTimer = hs.timer.doAfter(1, function()
				local frontApp = hs.application.frontmostApplication()
				if frontApp and frontApp:name() == "Safari" then
					hs.eventtap.keyStroke({}, "escape")
				end
				pendingTimer = nil
			end)
		end

		return false
	end)

	return enterTap
end

if safariEscTap then
	safariEscTap:stop()
end

safariEscTap = autoEscAfterSearch()
safariEscTap:start()

local function cleanup()
	if safariEscTap then
		safariEscTap:stop()
	end
	if pendingTimer then
		pendingTimer:stop()
		pendingTimer = nil
	end
end

hs.safariEscCleanup = cleanup

return safariEscTap
