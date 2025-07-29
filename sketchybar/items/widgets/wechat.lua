local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local M = {}

M.wechat = sbar.add("item", "widgets.wechat", {
	position = "right",
	icon = {
		string = icons.wechat,
		color = colors.green,
		font = {
			style = settings.font.style_map["Regular"],
			size = 16.0,
		},
	},
	label = {
		string = "",
		color = colors.white,
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		padding_left = 0,
		padding_right = 0,
	},
	background = {
		color = colors.bg2,
		border_color = colors.black,
		border_width = 1,
		corner_radius = 6,
	},
	padding_left = 4,
	padding_right = 0,
	update_freq = 10,
	click_script = "open -a WeChat",
})

M.wechat:subscribe({ "routine", "power_source_change", "system_woke" }, function()
	sbar.exec("lsappinfo -all list | grep wechat", function(wechat_notify)
		-- local icon = icons_map["WeChat"]
		local icon = icons.wechat
		local label = ""

		local notify_num = wechat_notify:match('"StatusLabel"=%{ "label"="?(.-)"? %}')

		if notify_num == nil or notify_num == "" then
			M.wechat:set({
				icon = {
					string = icon,
					color = colors.green,
					font = {
						style = settings.font.style_map["Bold"],
						size = 16.0,
					},
				},
				label = { drawing = false },
			})
			sbar.exec("sketchybar --trigger wechat_notify_trigger POPUP=false")
		else
			M.wechat:set({
				icon = {
					string = icon,
					color = colors.red,
					font = {
						style = settings.font.style_map["Bold"],
						size = 16.0,
					},
				},
				label = { string = notify_num .. label, drawing = true },
			})
			sbar.exec("sketchybar --trigger wechat_notify_trigger POPUP=true")
		end
	end)
end)

M.wechat:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'WeChat'")
end)

return M
