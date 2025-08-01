local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local function parse_string_to_table(s)
	local result = {}
	for line in s:gmatch("([^\n]+)") do
		table.insert(result, line)
	end
	return result
end

local function get_workspace_apps_simple(workspace)
	local file = io.popen("aerospace list-windows --workspace " .. workspace .. " --format '%{app-name}' 2>/dev/null")
	local result = file:read("*a")
	file:close()
	local apps = {}
	local seen = {}
	for app_name in result:gmatch("([^\n]+)") do
		if app_name and app_name ~= "" and not seen[app_name] then
			table.insert(apps, app_name)
			seen[app_name] = true
		end
	end
	return apps
end

local function get_app_icon_simple(app_name)
	return app_icons[app_name] or "󰘔"
end

local file = io.popen("aerospace list-workspaces --all")
local result = file:read("*a")
file:close()

local workspaces = parse_string_to_table(result)
for i, workspace in ipairs(workspaces) do
	local space = sbar.add("item", "space." .. i, {
		icon = {
			string = workspace,
			color = colors.white,
			highlight_color = colors.red,
			font = {
				family = settings.font.text,
				style = settings.font.style_map["Bold"],
				size = 12.0,
			},
		},
		label = {
			color = colors.white,
			font = "sketchybar-app-font:Regular:16.0",
		},
		padding_left = 4,
		padding_right = 4,
		background = {
			color = colors.bg2,
			border_color = colors.bg2,
			border_width = 1,
			corner_radius = 4,
		},
	})

	local function update_space_display()
		local apps = get_workspace_apps_simple(workspace)
		local app_icons_str = ""
		for j, app_name in ipairs(apps) do
			app_icons_str = app_icons_str .. get_app_icon_simple(app_name)
			if j < #apps then
				app_icons_str = app_icons_str .. " "
			end
		end
		space:set({
			label = {
				string = app_icons_str,
			},
		})
	end

	space:subscribe("mouse.clicked", function()
		sbar.exec("aerospace workspace " .. workspace)
	end)

	space:subscribe("aerospace_workspace_change", function(env)
		local selected = env.FOCUSED_WORKSPACE == workspace
		space:set({
			icon = { highlight = selected },
			background = {
				border_color = selected and colors.white or colors.bg2,
				color = selected and colors.bg1 or colors.bg2,
			},
		})

		update_space_display()
	end)
	space:subscribe("routine", update_space_display)
	update_space_display()
end
sbar.add("event", "aerospace_workspace_change")
sbar.add("item", {
	position = "popup.space",
	update_freq = 2,
}):subscribe("routine", function()
	sbar.trigger("aerospace_workspace_change", { FOCUSED_WORKSPACE = "dummy" })
end)

-- local colors = require("colors")
-- local icons = require("icons")
-- local settings = require("settings")
-- local app_icons = require("helpers.app_icons")
--
-- local spaces = {}
--
-- for i = 1, 10, 1 do
-- 	local space = sbar.add("space", "space." .. i, {
-- 		space = i,
-- 		icon = {
-- 			font = { family = settings.font.numbers },
-- 			string = i,
-- 			padding_left = 15,
-- 			padding_right = 8,
-- 			color = colors.white,
-- 			highlight_color = colors.red,
-- 		},
-- 		label = {
-- 			padding_right = 20,
-- 			color = colors.grey,
-- 			highlight_color = colors.white,
-- 			font = "sketchybar-app-font:Regular:16.0",
-- 			y_offset = -1,
-- 		},
-- 		padding_right = 1,
-- 		padding_left = 1,
-- 		background = {
-- 			color = colors.bg1,
-- 			border_width = 1,
-- 			height = 26,
-- 			border_color = colors.black,
-- 		},
-- 		popup = { background = { border_width = 5, border_color = colors.black } },
-- 	})
--
-- 	spaces[i] = space
--
-- 	-- Single item bracket for space items to achieve double border on highlight
-- 	local space_bracket = sbar.add("bracket", { space.name }, {
-- 		background = {
-- 			color = colors.transparent,
-- 			border_color = colors.bg2,
-- 			height = 28,
-- 			border_width = 2,
-- 		},
-- 	})
--
-- 	-- Padding space
-- 	sbar.add("space", "space.padding." .. i, {
-- 		space = i,
-- 		script = "",
-- 		width = settings.group_paddings,
-- 	})
--
-- 	local space_popup = sbar.add("item", {
-- 		position = "popup." .. space.name,
-- 		padding_left = 5,
-- 		padding_right = 0,
-- 		background = {
-- 			drawing = true,
-- 			image = {
-- 				corner_radius = 9,
-- 				scale = 0.2,
-- 			},
-- 		},
-- 	})
--
-- 	space:subscribe("space_change", function(env)
-- 		local selected = env.SELECTED == "true"
-- 		local color = selected and colors.grey or colors.bg2
-- 		space:set({
-- 			icon = { highlight = selected },
-- 			label = { highlight = selected },
-- 			background = { border_color = selected and colors.black or colors.bg2 },
-- 		})
-- 		space_bracket:set({
-- 			background = { border_color = selected and colors.grey or colors.bg2 },
-- 		})
-- 	end)
--
-- 	space:subscribe("mouse.clicked", function(env)
-- 		if env.BUTTON == "other" then
-- 			space_popup:set({ background = { image = "space." .. env.SID } })
-- 			space:set({ popup = { drawing = "toggle" } })
-- 		else
-- 			local op = (env.BUTTON == "right") and "--destroy" or "--focus"
-- 			sbar.exec("yabai -m space " .. op .. " " .. env.SID)
-- 		end
-- 	end)
--
-- 	space:subscribe("mouse.exited", function(_)
-- 		space:set({ popup = { drawing = false } })
-- 	end)
-- end
--
-- local space_window_observer = sbar.add("item", {
-- 	drawing = false,
-- 	updates = true,
-- })
--
-- local spaces_indicator = sbar.add("item", {
-- 	padding_left = -3,
-- 	padding_right = 0,
-- 	icon = {
-- 		padding_left = 8,
-- 		padding_right = 9,
-- 		color = colors.grey,
-- 		string = icons.switch.on,
-- 	},
-- 	label = {
-- 		width = 0,
-- 		padding_left = 0,
-- 		padding_right = 8,
-- 		string = "Spaces",
-- 		color = colors.bg1,
-- 	},
-- 	background = {
-- 		color = colors.with_alpha(colors.grey, 0.0),
-- 		border_color = colors.with_alpha(colors.bg1, 0.0),
-- 	},
-- })
--
-- space_window_observer:subscribe("space_windows_change", function(env)
-- 	local icon_line = ""
-- 	local no_app = true
-- 	for app, count in pairs(env.INFO.apps) do
-- 		no_app = false
-- 		local lookup = app_icons[app]
-- 		local icon = ((lookup == nil) and app_icons["Default"] or lookup)
-- 		icon_line = icon_line .. icon
-- 	end
--
-- 	if no_app then
-- 		icon_line = " —"
-- 	end
-- 	sbar.animate("tanh", 10, function()
-- 		spaces[env.INFO.space]:set({ label = icon_line })
-- 	end)
-- end)
--
-- spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
-- 	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
-- 	spaces_indicator:set({
-- 		icon = currently_on and icons.switch.off or icons.switch.on,
-- 	})
-- end)
--
-- spaces_indicator:subscribe("mouse.entered", function(env)
-- 	sbar.animate("tanh", 30, function()
-- 		spaces_indicator:set({
-- 			background = {
-- 				color = { alpha = 1.0 },
-- 				border_color = { alpha = 1.0 },
-- 			},
-- 			icon = { color = colors.bg1 },
-- 			label = { width = "dynamic" },
-- 		})
-- 	end)
-- end)
--
-- spaces_indicator:subscribe("mouse.exited", function(env)
-- 	sbar.animate("tanh", 30, function()
-- 		spaces_indicator:set({
-- 			background = {
-- 				color = { alpha = 0.0 },
-- 				border_color = { alpha = 0.0 },
-- 			},
-- 			icon = { color = colors.grey },
-- 			label = { width = 0 },
-- 		})
-- 	end)
-- end)
--
-- spaces_indicator:subscribe("mouse.clicked", function(env)
-- 	sbar.trigger("swap_menus_and_spaces")
-- end)
