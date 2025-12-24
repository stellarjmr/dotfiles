local zotero = {}

local bundleID = "org.zotero.zotero"
local normalMode = true

-- Adjust these if your Zotero uses different shortcuts to move focus left.
local focusLeftMods = { "shift" }
local focusLeftKey = "F6"
local focusRightTabs = 4

local scrollAmount = 100
local jumpScrollAmount = 20000
local jumpScrollRepeats = 6
local ggTimeout = 0.35

local keyTap
local appWatcher
local gPending = false
local gTimer

local textRoles = {
	AXTextArea = true,
	AXTextField = true,
	AXSearchField = true,
	AXComboBox = true,
	AXTextView = true,
}

local function isZoteroFrontmost()
	local app = hs.application.frontmostApplication()
	return app and app:bundleID() == bundleID
end

local function focusedElement()
	local system = hs.axuielement.systemWideElement()
	if not system then
		return nil
	end
	return system:attributeValue("AXFocusedUIElement")
end

local function hasRoleInHierarchy(elem, roles, maxDepth)
	local current = elem
	local depth = 0

	while current and depth < (maxDepth or 6) do
		local role = current:attributeValue("AXRole")
		if role and roles[role] then
			return true
		end

		local subrole = current:attributeValue("AXSubrole")
		if subrole and roles[subrole] then
			return true
		end

		current = current:attributeValue("AXParent")
		depth = depth + 1
	end

	return false
end

local function isTextInput(elem)
	return elem and hasRoleInHierarchy(elem, textRoles, 4)
end

local function isPdfViewer(elem)
	return elem and hasRoleInHierarchy(elem, { AXWebArea = true }, 6)
end

local function hasModifiers(flags)
	return flags.cmd or flags.alt or flags.ctrl or flags.shift
end

local function sendKey(mods, key)
	hs.eventtap.keyStroke(mods, key, 0)
end

local function scroll(amount)
	hs.eventtap.scrollWheel({ 0, amount }, {}, "pixel")
end

local function jumpScroll(direction)
	for _ = 1, jumpScrollRepeats do
		scroll(direction * jumpScrollAmount)
	end
end

local function clearGPending()
	gPending = false
	if gTimer then
		gTimer:stop()
		gTimer = nil
	end
end

keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
	if not normalMode or not isZoteroFrontmost() then
		return false
	end

	local flags = event:getFlags()
	local chars = event:getCharacters()
	if not chars then
		return false
	end

	if chars ~= "g" then
		clearGPending()
	end

	if chars == "G" then
		if flags.shift and not (flags.cmd or flags.alt or flags.ctrl) then
			local elem = focusedElement()
			if isTextInput(elem) then
				return false
			end
			sendKey({}, "end")
			jumpScroll(-1)
			return true
		end
		return false
	end

	if hasModifiers(flags) then
		return false
	end

	if chars == "g" then
		local elem = focusedElement()
		if isTextInput(elem) then
			clearGPending()
			return false
		end

		if gPending then
			clearGPending()
			sendKey({}, "home")
			jumpScroll(1)
		else
			gPending = true
			if gTimer then
				gTimer:stop()
			end
			gTimer = hs.timer.doAfter(ggTimeout, function()
				gPending = false
				gTimer = nil
			end)
		end
		return true
	end

	if chars == "j" or chars == "k" or chars == "h" or chars == "l" then
		local elem = focusedElement()
		if isTextInput(elem) then
			return false
		end

		if chars == "j" then
			if isPdfViewer(elem) then
				scroll(-scrollAmount)
			else
				sendKey({}, "down")
			end
			return true
		elseif chars == "k" then
			if isPdfViewer(elem) then
				scroll(scrollAmount)
			else
				sendKey({}, "up")
			end
			return true
		elseif chars == "h" then
			sendKey(focusLeftMods, focusLeftKey)
			return true
		elseif chars == "l" then
			for _ = 1, focusRightTabs do
				sendKey({}, "tab")
			end
			return true
		end
	end

	return false
end)

local function enable()
	if keyTap then
		keyTap:start()
	end
end

local function disable()
	if keyTap then
		keyTap:stop()
	end
	clearGPending()
end

function zotero.start()
	if appWatcher then
		return
	end

	appWatcher = hs.application.watcher.new(function(_, event, app)
		if not app or app:bundleID() ~= bundleID then
			return
		end

		if event == hs.application.watcher.activated then
			enable()
		elseif event == hs.application.watcher.deactivated or event == hs.application.watcher.terminated then
			disable()
		end
	end)

	appWatcher:start()

	if isZoteroFrontmost() then
		enable()
	else
		disable()
	end
end

function zotero.stop()
	if appWatcher then
		appWatcher:stop()
		appWatcher = nil
	end

	disable()
end

zotero.start()

return zotero
