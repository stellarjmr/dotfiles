-- Calendar menubar styled after Itsycal (static view, no actions)

local calendarMenubar = hs.menubar.new()

local CAL_ICON = "􀧞"
local ICON_STYLE = { font = { name = "SF Pro Display", size = 14 }, baselineOffset = -2.0 }
local TITLE_FONT = { name = "SF Pro Display", size = 14, style = "bold" }
local MENU_FONT_DEFAULT = { name = "SF Pro Display", size = 14 }
local MENU_FONT_SMALL = { name = "SF Pro Display", size = 12 }
local GRID_FONT = { name = "SF Mono", size = 12 }
local TEXT_COLOR = { red = 0.0, green = 0.0, blue = 0.0 }
local TODAY_COLOR = { red = 0.15, green = 0.35, blue = 0.85 }

local function styledMenuText(text, opts)
	local o = opts or {}
	return hs.styledtext.new(text, {
		font = o.font or MENU_FONT_DEFAULT,
		color = o.color or TEXT_COLOR,
		baselineOffset = -2.0,
	})
end

local function styledGridRow(cells)
	local row
	for i, cell in ipairs(cells) do
		local seg = hs.styledtext.new(cell.text, {
			font = GRID_FONT,
			color = cell.highlight and TODAY_COLOR or TEXT_COLOR,
			baselineOffset = -2.0,
		})
		if row then
			row = row .. seg
		else
			row = seg
		end
		if i < #cells then
			row = row .. hs.styledtext.new(" ", { font = GRID_FONT, color = TEXT_COLOR, baselineOffset = -2.0 })
		end
	end
	return row
end

local function buildCalendarRows()
	local now = os.date("*t")
	local firstOfMonth = os.time({ year = now.year, month = now.month, day = 1 })
	local daysInMonth = os.date("*t", os.time({ year = now.year, month = now.month + 1, day = 0 })).day
	local startWeekday = tonumber(os.date("%w", firstOfMonth)) -- 0 = Sun

	local rows = {}
	table.insert(rows, hs.styledtext.new("Su Mo Tu We Th Fr Sa", {
		font = GRID_FONT,
		color = TEXT_COLOR,
		baselineOffset = -2.0,
	}))

	local currentRow = {}
	for _ = 1, startWeekday do
		table.insert(currentRow, { text = "  " })
	end

	for day = 1, daysInMonth do
		table.insert(currentRow, { text = string.format("%2d", day), highlight = (day == now.day) })
		if #currentRow == 7 then
			table.insert(rows, styledGridRow(currentRow))
			currentRow = {}
		end
	end

	if #currentRow > 0 then
		while #currentRow < 7 do
			table.insert(currentRow, { text = "  " })
		end
		table.insert(rows, styledGridRow(currentRow))
	end

	local monthTitle = os.date("%B %Y", firstOfMonth)
	return rows, monthTitle
end

local function getTodayEvents()
	local script = [[
        tell application "Calendar"
            try
                set todayStart to current date
                set time of todayStart to 0
                set todayEnd to todayStart + 1 * days

                set gathered to {}
                repeat with cal in calendars
                    set evts to every event of cal whose (start date < todayEnd) and (end date > todayStart)
                    repeat with ev in evts
                        set isAllDay to allday event of ev
                        if isAllDay then
                            set end of gathered to "All-day  " & (summary of ev)
                        else
                            set end of gathered to (time string of (start date of ev)) & "  " & (summary of ev)
                        end if
                    end repeat
                end repeat

                set AppleScript's text item delimiters to linefeed
                if (count of gathered) = 0 then
                    return ""
                else
                    return gathered as text
                end if
            on error
                return ""
            end try
        end tell
    ]]

	local ok, result = hs.osascript.applescript(script)
	if not ok then
		return { "Calendar access needed" }
	end
	if not result or result == "" then
		return {}
	end

	local events = {}
	for line in tostring(result):gmatch("[^\r\n]+") do
		if line:match("%S") then
			table.insert(events, line)
		end
	end
	return events
end

local function buildMenu()
	local rows, monthTitle = buildCalendarRows()
	local events = getTodayEvents()

	local menu = {
		{ title = styledMenuText(CAL_ICON .. "  " .. monthTitle, { font = TITLE_FONT }) },
		{ title = "-" },
	}

	for _, row in ipairs(rows) do
		table.insert(menu, { title = row })
	end

	table.insert(menu, { title = "-" })
	table.insert(menu, { title = styledMenuText("Today", { font = TITLE_FONT }) })

	if #events == 0 then
		table.insert(menu, { title = styledMenuText("No events", { font = MENU_FONT_SMALL }) })
	else
		for idx, evt in ipairs(events) do
			if idx > 8 then
				table.insert(menu, { title = styledMenuText("…", { font = MENU_FONT_SMALL }) })
				break
			end
			table.insert(menu, { title = styledMenuText(evt, { font = MENU_FONT_SMALL }) })
		end
	end

	return menu
end

local function start()
	if calendarMenubar then
		calendarMenubar:setTitle(hs.styledtext.new(CAL_ICON, ICON_STYLE))
		calendarMenubar:setMenu(buildMenu)
	end
end

local function stop()
	if calendarMenubar then
		calendarMenubar:delete()
		calendarMenubar = nil
	end
end

local function restart()
	stop()
	calendarMenubar = hs.menubar.new()
	start()
end

local M = {}
M.start = start
M.stop = stop
M.restart = restart

start()

return M
