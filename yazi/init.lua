require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})
require("starship"):setup()

Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)

if os.getenv("YAZI_MAX_CURRENT") == "1" then
	local ok, toggle = pcall(require, "toggle-pane")
	if ok and toggle then
		toggle:entry("max-current")
	end
end
