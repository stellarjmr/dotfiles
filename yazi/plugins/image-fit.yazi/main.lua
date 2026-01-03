--- @since 25.12.29
-- Upscale images to fit the preview area using macOS sips.

local M = {}

local function max_pixels(area)
	local cw, ch = rt.term.cell_size()
	if cw and ch then
		return math.max(1, math.floor(area.w * cw)), math.max(1, math.floor(area.h * ch))
	end

	return rt.preview.max_width, rt.preview.max_height
end

local function fit_size(info, max_w, max_h)
	local scale = math.min(max_w / info.w, max_h / info.h)
	if scale <= 0 then
		return max_w, max_h
	end

	return math.max(1, math.floor(info.w * scale)), math.max(1, math.floor(info.h * scale))
end

local function show_original(job)
	local _, err = ya.image_show(job.file.url, job.area)
	ya.preview_widget(job, err)
end

function M:peek(job)
	local info = ya.image_info(job.file.url)
	if not info or info.w == 0 or info.h == 0 then
		return show_original(job)
	end

	local max_w, max_h = max_pixels(job.area)
	local w, h = fit_size(info, max_w, max_h)

	local tmp = os.tmpname() .. ".png"
	local status, err = Command("sips"):arg({
		"-s",
		"format",
		"png",
		"-z",
		tostring(h),
		tostring(w),
		tostring(job.file.url),
		"--out",
		tmp,
	}):status()

	if not status then
		return show_original(job)
	elseif not status.success then
		return show_original(job)
	end

	local _, show_err = ya.image_show(Url(tmp), job.area)
	ya.preview_widget(job, show_err)
end

function M:seek() end

function M:spot(job)
	local info = ya.image_info(job.file.url)
	if not info then
		return require("file"):spot(job)
	end

	local rows = {
		ui.Row({ "Image" }):style(ui.Style():fg("green")),
		ui.Row { "  Format:", tostring(info.format) },
		ui.Row { "  Size:", string.format("%dx%d", info.w, info.h) },
		ui.Row { "  Color:", tostring(info.color) },
		ui.Row {},
	}

	ya.spot_table(
		job,
		ui.Table(ya.list_merge(rows, require("file"):spot_base(job)))
			:area(ui.Pos { "center", w = 60, h = 20 })
			:row(job.skip)
			:row(1)
			:col(1)
			:col_style(th.spot.tbl_col)
			:cell_style(th.spot.tbl_cell)
			:widths { ui.Constraint.Length(14), ui.Constraint.Fill(1) }
	)
end

return M
