--- @since 26.04.03
-- Open AI coding tools in a new terminal tab from yazi.

local M = {}

local state = {
	default_tool = "claude",
	tools = {
		claude = { cmd = "claude" },
		codex  = { cmd = "codex" },
		amp    = { cmd = "amp" },
		gemini = { cmd = "gemini" },
		aider  = { cmd = "aider" },
	},
	terminal = nil, -- nil = auto-detect
}

local cached_terminal = nil
local cached_kitty_listen = nil

local KITTY_SOCKET_CANDIDATES = {
	"unix:/tmp/mykitty",
}

local function verify_kitty_socket(sock)
	local child = Command("kitty")
		:arg({ "@", "--to", sock, "ls" })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if child then
		local output = child:wait_with_output()
		if output and output.status and output.status.success then
			return true
		end
	end
	return false
end

local function find_kitty_socket()
	-- Try configured socket first
	if state.kitty_listen_on then
		return state.kitty_listen_on
	end
	-- Try known socket paths (verified with kitty @ ls)
	for _, sock in ipairs(KITTY_SOCKET_CANDIDATES) do
		if verify_kitty_socket(sock) then
			return sock
		end
	end
	-- Try glob /tmp/kitty-* and verify each
	local child = Command("sh")
		:arg({ "-c", "ls /tmp/kitty-* 2>/dev/null" })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if child then
		local output = child:wait_with_output()
		if output and output.status and output.status.success and output.stdout then
			for path in string.gmatch(output.stdout, "[^\n]+") do
				path = string.gsub(path, "%s+$", "")
				if #path > 0 then
					local sock = "unix:" .. path
					if verify_kitty_socket(sock) then
						return sock
					end
				end
			end
		end
	end
	return nil
end

local get_target_dir = ya.sync(function()
	local h = cx.active.current.hovered
	if h and h.cha.is_dir then
		return tostring(h.url)
	end
	return tostring(cx.active.current.cwd)
end)

local function shell_escape(s)
	return "'" .. string.gsub(s, "'", "'\\''") .. "'"
end

local function applescript_escape(s)
	s = string.gsub(s, "\\", "\\\\")
	s = string.gsub(s, '"', '\\"')
	return '"' .. s .. '"'
end

local function read_env(name)
	local child = Command("printenv")
		:arg({ name })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return nil
	end
	local output = child:wait_with_output()
	if output and output.status and output.status.success and output.stdout then
		local val = string.gsub(output.stdout, "%s+$", "")
		if #val > 0 then
			return val
		end
	end
	return nil
end

local function detect_terminal()
	if state.terminal then
		return state.terminal
	end

	if cached_terminal then
		return cached_terminal
	end

	local term = read_env("TERM_PROGRAM")
	if term == "kitty" then
		cached_terminal = "kitty"
		cached_kitty_listen = read_env("KITTY_LISTEN_ON") or find_kitty_socket()
	elseif term == "WezTerm" then
		cached_terminal = "wezterm"
	elseif term == "ghostty" then
		cached_terminal = "ghostty"
	elseif term == "iTerm.app" then
		cached_terminal = "iterm"
	elseif read_env("TMUX") then
		cached_terminal = "tmux"
	end

	-- Fallback: probe kitty socket when env detection fails
	if not cached_terminal then
		local sock = find_kitty_socket()
		if sock then
			-- Verify it's a live kitty by trying kitty @ ls
			local child = Command("kitty")
				:arg({ "@", "--to", sock, "ls" })
				:stdout(Command.PIPED)
				:stderr(Command.PIPED)
				:spawn()
			if child then
				local output = child:wait_with_output()
				if output and output.status and output.status.success then
					cached_terminal = "kitty"
					cached_kitty_listen = sock
				end
			end
		end
	end

	return cached_terminal
end

local function open_kitty(dir, cmd)
	if not cached_kitty_listen then
		return false, "kitty socket not found (add to kitty.conf: allow_remote_control yes, listen_on unix:/tmp/mykitty)"
	end

	-- Step 1: Launch a new tab with the user's default shell
	local child, err = Command("kitty")
		:arg({ "@", "--to", cached_kitty_listen, "launch", "--type=tab", "--cwd", dir })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return false, "Failed to spawn kitty: " .. (err or "unknown error")
	end
	local output = child:wait_with_output()
	if not output or not output.status.success then
		return false, "kitty launch failed on " .. cached_kitty_listen
	end

	-- Step 2: Send the command to the newly created tab
	local child2, err2 = Command("kitty")
		:arg({ "@", "--to", cached_kitty_listen, "send-text", "--match", "recent:0", cmd .. "; exit\r" })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child2 then
		return false, "Failed to send text: " .. (err2 or "unknown error")
	end
	child2:wait()
	return true
end

local function open_wezterm(dir, cmd)
	local child, err = Command("wezterm")
		:arg({ "cli", "spawn", "--cwd", dir, "--", "sh", "-c", cmd })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return false, "Failed to spawn wezterm: " .. (err or "unknown error")
	end
	child:wait()
	return true
end

local function open_tmux(dir, cmd)
	local child, err = Command("tmux")
		:arg({ "new-window", "-c", dir, "sh", "-c", "sleep 0.2 && exec " .. cmd })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return false, "Failed to spawn tmux: " .. (err or "unknown error")
	end
	child:wait()
	return true
end

local function open_ghostty(dir, cmd)
	local script = string.format(
		[[tell application "Ghostty"
	activate
	set cfg to new surface configuration
	set initial working directory of cfg to %s
	set initial input of cfg to %s & "; exit\n"
	new tab with configuration cfg
end tell]],
		applescript_escape(dir),
		applescript_escape(cmd)
	)
	local child, err = Command("osascript")
		:arg({ "-e", script })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return false, "Failed to run osascript: " .. (err or "unknown error")
	end
	child:wait()
	return true
end

local function open_iterm(dir, cmd)
	local full_cmd = "cd " .. shell_escape(dir) .. " && " .. cmd
	local script = string.format(
		[[tell application "iTerm2"
	tell current window
		create tab with default profile
		tell current session
			write text %s
		end tell
	end tell
end tell]],
		applescript_escape(full_cmd)
	)
	local child, err = Command("osascript")
		:arg({ "-e", script })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return false, "Failed to run osascript: " .. (err or "unknown error")
	end
	child:wait()
	return true
end

local openers = {
	kitty   = open_kitty,
	wezterm = open_wezterm,
	tmux    = open_tmux,
	ghostty = open_ghostty,
	iterm   = open_iterm,
}

function M:setup(opts)
	if not opts then
		return
	end
	if opts.default_tool then
		state.default_tool = opts.default_tool
	end
	if opts.terminal then
		state.terminal = opts.terminal
	end
	if opts.kitty_listen_on then
		state.kitty_listen_on = opts.kitty_listen_on
	end
	if opts.tools then
		for name, tool in pairs(opts.tools) do
			state.tools[name] = tool
		end
	end
end

function M:entry(job)
	-- Compatible with yazi passing job as string or table
	if type(job) == "string" then
		job = { args = { job } }
	end
	local tool_name = (job.args and job.args[1]) or state.default_tool
	local tool = state.tools[tool_name]
	if not tool then
		ya.notify({
			title = "ai-opener",
			content = "Unknown tool: " .. tool_name,
			level = "error",
			timeout = 3,
		})
		return
	end

	local dir = get_target_dir()
	if not dir then
		ya.notify({
			title = "ai-opener",
			content = "Cannot determine directory",
			level = "error",
			timeout = 3,
		})
		return
	end

	local terminal = detect_terminal()
	if not terminal then
		ya.notify({
			title = "ai-opener",
			content = "Cannot detect terminal. Set terminal in setup(), e.g. require('ai-opener'):setup({ terminal = 'kitty' })",
			level = "error",
			timeout = 5,
		})
		return
	end

	local opener = openers[terminal]
	if not opener then
		ya.notify({
			title = "ai-opener",
			content = "Unsupported terminal: " .. terminal,
			level = "error",
			timeout = 5,
		})
		return
	end

	local ok, err = opener(dir, tool.cmd)
	if ok then
		ya.notify({
			title = "ai-opener",
			content = tool_name .. " opened via " .. terminal,
			level = "info",
			timeout = 2,
		})
	else
		ya.notify({
			title = "ai-opener",
			content = err or "Failed to open " .. tool_name,
			level = "error",
			timeout = 5,
		})
	end
end

return M
