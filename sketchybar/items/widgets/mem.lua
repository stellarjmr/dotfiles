local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
sbar.exec(
	"killall memory_pressure >/dev/null; $CONFIG_DIR/helpers/event_providers/memory_pressure/bin/memory_pressure memory_pressure_update 5.0"
)

local memory_pressure = sbar.add("graph", "widgets.memory_pressure", 42, {
	position = "right",
	graph = { color = colors.green },
	background = {
		height = 22,
		color = { alpha = 0 },
		border_color = { alpha = 0 },
		drawing = true,
	},
	icon = { string = icons.memory, color = colors.white },
	label = {
		string = "ram ??%",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		align = "right",
		padding_right = 0,
		width = 0,
		y_offset = 4,
	},
	padding_right = settings.paddings + 6,
})

local memory_usage = "??"

memory_pressure:subscribe("memory_pressure_update", function(env)
	-- Also available: env.user_load, env.sys_load
	sbar.exec(
		"vm_stat | awk '/Pages free/ {free=$3} /Pages active/ {active=$3} /Pages inactive/ {inactive=$3} /Pages speculative/ {spec=$3} /Pages wired/ {wired=$3} END {total=free+active+inactive+spec+wired; used=active+wired; if(total>0) print int((used/total)*100); else print 0}'",
		function(mem_info)
			local mem_usage = tonumber(mem_info)
			memory_pressure:push({ (mem_usage - 20.) / 100. })
			if mem_usage then
				memory_usage = tostring(mem_usage)
			else
				memory_usage = "??"
			end
		end
	)

	memory_pressure:set({
		label = "ram " .. memory_usage .. "%",
	})
end)

memory_pressure:subscribe("mouse.clicked", function(env)
	sbar.exec("open -a 'Activity Monitor'")
end)

-- Background around the cpu item
sbar.add("bracket", "widgets.mem.bracket", { memory_pressure.name }, {
	background = { color = colors.bg1 },
})

-- Background around the cpu item
sbar.add("item", "widgets.mem.padding", {
	position = "right",
	width = settings.group_paddings,
})
