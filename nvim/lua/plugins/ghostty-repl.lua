local delimiter = "# %%"
local state = {
  repl_id = nil,
  python = nil,
}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function system_with_input(cmd, input)
  local output = vim.fn.system(cmd, input)
  local code = vim.v.shell_error
  return code, output
end

local function run_osascript(script, args)
  local cmd = { "osascript", "-" }
  for _, arg in ipairs(args or {}) do
    table.insert(cmd, arg)
  end

  local code, output = system_with_input(cmd, script)
  return code == 0, trim(output)
end

local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

local function shell_quote(value)
  return vim.fn.shellescape(value)
end

local function cmd_ok(argv)
  local code = vim.fn.system(argv)
  return vim.v.shell_error == 0
end

local function detect_ipython_python()
  if state.python then
    return state.python
  end

  local conda_base = vim.fn.expand("~/conda")
  local candidates = { conda_base .. "/bin/python" }
  local envs_dir = conda_base .. "/envs"

  if vim.fn.isdirectory(envs_dir) == 1 then
    for _, name in ipairs(vim.fn.readdir(envs_dir)) do
      table.insert(candidates, envs_dir .. "/" .. name .. "/bin/python")
    end
  end

  for _, py in ipairs(candidates) do
    if vim.fn.executable(py) == 1 and cmd_ok({ py, "-c", "import IPython" }) then
      state.python = py
      return py
    end
  end

  return nil
end

local function visual_selection_text()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_row = start_pos[2]
  local start_col = start_pos[3]
  local end_row = end_pos[2]
  local end_col = end_pos[3]

  if start_row == 0 or end_row == 0 then
    return nil
  end

  if start_row > end_row or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  if #lines == 0 then
    return ""
  end

  lines[1] = string.sub(lines[1], start_col)
  lines[#lines] = string.sub(lines[#lines], 1, end_col)
  return table.concat(lines, "\n") .. "\n"
end

local function current_cell_text()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local start_row = 1
  local end_row = #lines

  -- If cursor is on a delimiter, treat the cell as the one below it
  if vim.startswith(lines[cursor_row], delimiter) then
    start_row = cursor_row + 1
    for row = cursor_row + 1, #lines do
      if vim.startswith(lines[row], delimiter) then
        end_row = row - 1
        break
      end
    end
  else
    for row = cursor_row - 1, 1, -1 do
      if vim.startswith(lines[row], delimiter) then
        start_row = row + 1
        break
      end
    end

    for row = cursor_row + 1, #lines do
      if vim.startswith(lines[row], delimiter) then
        end_row = row - 1
        break
      end
    end
  end

  if end_row < start_row then
    return ""
  end

  return table.concat(vim.list_slice(lines, start_row, end_row), "\n") .. "\n"
end

local function sendable_text(kind)
  if kind == "line" then
    return vim.api.nvim_get_current_line() .. "\n"
  end

  if kind == "selection" then
    return visual_selection_text()
  end

  if kind == "file" then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    return table.concat(lines, "\n") .. "\n"
  end

  if kind == "cell" then
    return current_cell_text()
  end

  return nil
end

local function current_terminal_id()
  local ok, output = run_osascript([[
tell application "Ghostty"
  return id of focused terminal of selected tab of front window
end tell
]])
  if not ok or output == "" then
    return nil
  end
  return output
end

local function terminal_exists(terminal_id)
  if not terminal_id or terminal_id == "" then
    return false
  end

  local ok, output = run_osascript([[
on run argv
  set targetId to item 1 of argv
  tell application "Ghostty"
    try
      set targetTerm to first terminal whose id is targetId
      return "1"
    on error
      return "0"
    end try
  end tell
end run
]], { terminal_id })
  return ok and output == "1"
end

local function focus_terminal(terminal_id)
  if not terminal_id or terminal_id == "" then
    return false, "missing terminal id"
  end

  return run_osascript([[
on run argv
  set targetId to item 1 of argv
  tell application "Ghostty"
    focus (first terminal whose id is targetId)
  end tell
end run
]], { terminal_id })
end

local function close_terminal(terminal_id)
  if not terminal_id or terminal_id == "" then
    return false, "missing terminal id"
  end

  return run_osascript([[
on run argv
  set targetId to item 1 of argv
  tell application "Ghostty"
    close (first terminal whose id is targetId)
  end tell
end run
]], { terminal_id })
end

local function send_text_and_refocus(source_id, repl_id, text)
  return run_osascript([[
on run argv
  set sourceId to item 1 of argv
  set replId to item 2 of argv
  set payload to item 3 of argv
  tell application "Ghostty"
    set replTerm to first terminal whose id is replId
    input text payload to replTerm
    send key "enter" to replTerm
    focus (first terminal whose id is sourceId)
  end tell
end run
]], { source_id, repl_id, text })
end

local function ensure_repl_terminal(source_terminal_id)
  if terminal_exists(state.repl_id) then
    return state.repl_id
  end

  if not source_terminal_id or source_terminal_id == "" then
    notify_error("Ghostty source terminal is unavailable")
    return nil
  end

  local python = detect_ipython_python()
  if not python then
    notify_error("No Python with IPython found under ~/conda")
    return nil
  end

  local cwd = vim.fn.getcwd()
  local init_text = "exec " .. shell_quote(python) .. " -m IPython\n"

  local ok, output = run_osascript([[
on run argv
  set sourceId to item 1 of argv
  set workingDir to item 2 of argv
  set initialInputValue to item 3 of argv
  tell application "Ghostty"
    set cfg to new surface configuration
    set initial working directory of cfg to workingDir
    set initial input of cfg to initialInputValue
    set sourceTerm to first terminal whose id is sourceId
    set replTerm to split sourceTerm direction right with configuration cfg
    return id of replTerm
  end tell
end run
]], { source_terminal_id, cwd, init_text })

  if not ok or output == "" then
    notify_error("Failed to create Ghostty REPL split: " .. output)
    return nil
  end

  state.repl_id = output
  focus_terminal(source_terminal_id)

  -- Resize to ~70/30 via send key (perform action doesn't work for resize_split)
  run_osascript([[
on run argv
  tell application "Ghostty"
    set t to first terminal whose id is (item 1 of argv)
    repeat 40 times
      send key "minus" modifiers "option" to t
    end repeat
  end tell
end run
]], { source_terminal_id })

  return output
end

local function exit_and_close_repl(terminal_id)
  if not terminal_id or terminal_id == "" then
    return false
  end

  if not terminal_exists(terminal_id) then
    state.repl_id = nil
    return true
  end

  local source_id = current_terminal_id()

  -- Send exit() and enter in one call
  run_osascript([[
on run argv
  set targetId to item 1 of argv
  tell application "Ghostty"
    set t to first terminal whose id is targetId
    input text "exit()" to t
    send key "enter" to t
  end tell
end run
]], { terminal_id })

  -- Wait for IPython to exit gracefully
  local exited = vim.wait(1500, function()
    return not terminal_exists(terminal_id)
  end, 50)

  if not exited then
    close_terminal(terminal_id)
  end

  state.repl_id = nil

  -- Refocus the source terminal to avoid keyboard getting stuck
  if source_id then
    focus_terminal(source_id)
  end

  return true
end

local function send_text(kind)
  local text = sendable_text(kind)
  if text == nil then
    notify_error("Unsupported Ghostty send kind: " .. kind)
    return
  end

  local source_terminal_id = current_terminal_id()
  if source_terminal_id == nil then
    notify_error("Could not determine the focused Ghostty terminal")
    return
  end

  local repl_id = ensure_repl_terminal(source_terminal_id)
  if repl_id == nil then
    return
  end

  local ok, err = send_text_and_refocus(source_terminal_id, repl_id, text)
  if not ok then
    notify_error("Failed to send text to Ghostty REPL: " .. err)
  end
end

local function close_repl()
  if state.repl_id == nil then
    return
  end

  exit_and_close_repl(state.repl_id)
end

return {
  {
    dir = vim.fn.stdpath("config"),
    name = "ghostty-repl",
    enabled = vim.fn.has("mac") == 1,
    config = function()
      vim.g.slime_cell_delimiter = delimiter

      vim.keymap.set("n", "<leader>sc", function()
        send_text("cell")
      end, { desc = "Ghostty Send Cell" })

      vim.keymap.set("n", "<leader>sl", function()
        send_text("line")
      end, { desc = "Ghostty Send Line" })

      vim.keymap.set("x", "<leader>ss", function()
        send_text("selection")
      end, { desc = "Ghostty Send Selection" })

      vim.keymap.set("n", "<leader>sf", function()
        send_text("file")
      end, { desc = "Ghostty Send File" })

      vim.api.nvim_create_user_command("SlimeClose", close_repl, {})
      vim.keymap.set("n", "<leader>rq", close_repl, { desc = "Close Ghostty REPL window" })
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          exit_and_close_repl(state.repl_id)
        end,
      })
    end,
  },
}
