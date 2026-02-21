local delimiter = "# %%"
local state = {
  repl_id = nil,
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
  local script = [[
tell application "Ghostty"
  return id of focused terminal of selected tab of front window
end tell
]]

  local ok, output = run_osascript(script)
  if not ok or output == "" then
    return nil
  end

  return output
end

local function terminal_exists(terminal_id)
  if terminal_id == nil or terminal_id == "" then
    return false
  end

  local script = [[
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
]]

  local ok, output = run_osascript(script, { terminal_id })
  return ok and output == "1"
end

local function focus_terminal(terminal_id)
  if terminal_id == nil or terminal_id == "" then
    return false, "missing terminal id"
  end

  local script = [[
on run argv
  set targetId to item 1 of argv
  tell application "Ghostty"
    focus (first terminal whose id is targetId)
  end tell
end run
]]

  return run_osascript(script, { terminal_id })
end

local function input_text_to_terminal(terminal_id, text)
  if terminal_id == nil or terminal_id == "" then
    return false, "missing terminal id"
  end

  local script = [[
on run argv
  set targetId to item 1 of argv
  set payload to item 2 of argv
  tell application "Ghostty"
    input text payload to (first terminal whose id is targetId)
  end tell
end run
]]

  return run_osascript(script, { terminal_id, text })
end

local function send_enter_to_terminal(terminal_id)
  if terminal_id == nil or terminal_id == "" then
    return false, "missing terminal id"
  end

  local script = [[
on run argv
  set targetId to item 1 of argv
  tell application "Ghostty"
    send key "enter" to (first terminal whose id is targetId)
  end tell
end run
]]
  return run_osascript(script, { terminal_id })
end

local function close_terminal(terminal_id)
  if terminal_id == nil or terminal_id == "" then
    return false, "missing terminal id"
  end

  local script = [[
on run argv
  set targetId to item 1 of argv
  tell application "Ghostty"
    close (first terminal whose id is targetId)
  end tell
end run
]]
  return run_osascript(script, { terminal_id })
end

local function ensure_repl_terminal(source_terminal_id)
  if terminal_exists(state.repl_id) then
    return state.repl_id
  end

  if source_terminal_id == nil or source_terminal_id == "" then
    notify_error("Ghostty source terminal is unavailable")
    return nil
  end

  local cwd = vim.fn.getcwd()
  local python = vim.fn.expand("~/conda/bin/python")
  local init_text = "exec " .. shell_quote(python) .. " -m IPython\n"
  local script = [[
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
]]

  local ok, output = run_osascript(script, { source_terminal_id, cwd, init_text })
  if not ok or output == "" then
    notify_error("Failed to create Ghostty REPL split: " .. output)
    return nil
  end

  state.repl_id = output
  focus_terminal(source_terminal_id)
  return output
end

local function request_repl_exit(terminal_id)
  if terminal_id == nil or terminal_id == "" then
    return false, "missing terminal id"
  end

  local ok, err = input_text_to_terminal(terminal_id, "exit()")
  if not ok then
    return false, err
  end

  return send_enter_to_terminal(terminal_id)
end

local function exit_and_close_repl(terminal_id)
  if terminal_id == nil or terminal_id == "" then
    return false
  end

  if not terminal_exists(terminal_id) then
    state.repl_id = nil
    return true
  end

  request_repl_exit(terminal_id)
  vim.wait(150)
  local ok = close_terminal(terminal_id)
  state.repl_id = nil
  return ok
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

  local ok, err = input_text_to_terminal(repl_id, text)
  if not ok then
    notify_error("Failed to send text to Ghostty REPL: " .. err)
    return
  end

  local ok_enter, enter_err = send_enter_to_terminal(repl_id)
  if not ok_enter then
    notify_error("Failed to submit text in Ghostty REPL: " .. enter_err)
  end

  local ok_focus, focus_err = focus_terminal(source_terminal_id)
  if not ok_focus then
    notify_error("Failed to refocus the Ghostty editor split: " .. focus_err)
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
    enabled = true and vim.fn.has("mac") == 1,
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
          state.repl_id = nil
        end,
      })
    end,
  },
}
