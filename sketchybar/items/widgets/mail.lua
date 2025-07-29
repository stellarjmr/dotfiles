local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local mail = sbar.add("item", "mail", {
	position = "right",
	icon = {
		string = icons.mail.mail,
		color = colors.blue,
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
		padding_right = 4,
	},
	background = {
		color = colors.bg2,
		border_color = colors.black,
		border_width = 1,
		corner_radius = 6,
	},
	padding_left = 4,
	padding_right = 0,
	update_freq = 60,
	click_script = "open -a Mail",
})

mail:subscribe("routine", function()
	sbar.exec("osascript -e 'tell application \"Mail\" to get the unread count of inbox'", function(result)
		local unread_count = tonumber(result:match("%d+")) or 0

		if unread_count > 0 then
			mail:set({
				icon = {
					string = icons.mail.mail_unread,
					color = colors.red,
				},
				label = {
					string = tostring(unread_count),
				},
				background = {
					color = colors.bg2,
					border_color = colors.red,
				},
			})
		else
			mail:set({
				icon = {
					color = colors.blue,
				},
				label = {
					string = "",
				},
				background = {
					color = colors.bg2,
					border_color = colors.black,
				},
			})
		end
	end)
end)

mail:subscribe("mouse.entered", function()
	mail:set({
		background = {
			color = colors.bg1,
		},
	})
end)

mail:subscribe("mouse.exited", function()
	mail:set({
		background = {
			color = colors.bg2,
		},
	})
end)

mail:subscribe("forced", function()
	mail:set({
		icon = {
			string = icons.mail,
		},
	})
end)
