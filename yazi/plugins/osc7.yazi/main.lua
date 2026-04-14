--- @since 26.1.22
-- Emit OSC 7 on every directory change so Ghostty (and other OSC-7 aware
-- terminals) track yazi's current working directory. New splits/tabs
-- created by the terminal then inherit the directory you are browsing,
-- instead of the directory where yazi was launched.

local M = {}

local function url_encode(path)
	return (path:gsub("([^%w%-%._~/])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

-- URI scheme and host are both deliberate:
--
-- Scheme: `kitty-shell-cwd`. Ghostty's OSC 7 validator accepts only
-- `file` or `kitty-shell-cwd`; the latter is what Ghostty's own zsh
-- shell integration emits, and it is the well-trodden path.
--
-- Host: literal `localhost`. Ghostty validates that the hostname is
-- local by comparing against `gethostname(3)`, whose value on macOS
-- depends on scutil state and can differ from `hostname -s` in ways
-- that vary by machine. The validator special-cases `localhost` as
-- always-local, so using it makes the URI machine-agnostic.
local function emit(path)
	if not path or #path == 0 then
		return
	end
	local tty = io.open("/dev/tty", "w")
	if not tty then
		return
	end
	tty:write("\27]7;kitty-shell-cwd://localhost" .. url_encode(path) .. "\7")
	tty:flush()
	tty:close()
end

-- ps.sub callbacks run in async context where `cx` is not directly
-- accessible; ya.sync wraps a block so we can read the current cwd safely.
local get_cwd = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

function M:setup()
	ps.sub("cd", function()
		emit(get_cwd())
	end)
end

return M
