-- Skip this spec when running inside Ghostty; the tmux-specific spec handles that case.
if vim.env.TERM == "xterm-ghostty" then
  return {}
end

local function kitty_prefix(listen_on)
  if listen_on ~= nil and listen_on ~= "" then
    return string.format("kitty @ --to %s", vim.fn.shellescape(listen_on))
  end
  return "kitty @"
end

local function kitty_ls(listen_on)
  local output = vim.fn.system(kitty_prefix(listen_on) .. " ls")
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local ok, decoded = pcall(vim.fn.json_decode, output)
  if not ok then
    return nil
  end

  return decoded
end

local function kitty_window_info(window_id, listen_on)
  if window_id == nil then
    return nil
  end

  local listing = kitty_ls(listen_on)
  if listing == nil then
    return nil
  end

  for _, os_window in ipairs(listing) do
    for _, tab in ipairs(os_window.tabs or {}) do
      for _, window in ipairs(tab.windows or {}) do
        if window.id == window_id then
          return window
        end
      end
    end
  end

  return nil
end

local function kitty_find_window_by_title(title, listen_on)
  local listing = kitty_ls(listen_on)
  if listing == nil then
    return nil
  end

  for _, os_window in ipairs(listing) do
    for _, tab in ipairs(os_window.tabs or {}) do
      for _, window in ipairs(tab.windows or {}) do
        if window.title == title then
          return window.id
        end
      end
    end
  end

  return nil
end

local function update_slime_config(window_id, listen_on)
  vim.g.slime_default_config = {
    window_id = window_id,
    listen_on = listen_on,
  }
  vim.b.slime_config = vim.g.slime_default_config
end

local function ensure_ipython_window()
  local listen_on = (vim.g.slime_default_config or {}).listen_on
    or vim.env.KITTY_LISTEN_ON
    or "unix:/tmp/mykitty"

  local window_id = (vim.g.slime_default_config or {}).window_id
  if kitty_window_info(window_id, listen_on) ~= nil then
    update_slime_config(window_id, listen_on)
    return window_id
  end

  local current_window_id = tonumber(vim.env.KITTY_WINDOW_ID)
  local current_window = kitty_window_info(current_window_id, listen_on)
  local current_columns = current_window and current_window.columns or nil
  local match_flag = current_window_id and string.format("--match window_id:%s ", current_window_id) or "--self "
  local cwd = vim.fn.getcwd()
  local python = vim.fn.expand("~/conda/envs/ovito/bin/python")
  local base_cmd = kitty_prefix(listen_on)
  -- Force tab into splits layout so vsplit is honored
  if current_window_id ~= nil then
    vim.fn.system(string.format("%s goto-layout --match window_id:%s splits", base_cmd, current_window_id))
  else
    vim.fn.system(base_cmd .. " goto-layout splits")
  end

  -- Prefer side-by-side (vsplit -> left/right)
  local function launch_ipython(location)
    local cmd = string.format(
      "launch --type=window %s--location=%s --bias=30 --cwd %s --title %s %s -m IPython",
      match_flag,
      location,
      vim.fn.shellescape(cwd),
      vim.fn.shellescape("nvim-ipython"),
      vim.fn.shellescape(python)
    )
    local output = vim.fn.system(base_cmd .. " " .. cmd)
    if vim.v.shell_error ~= 0 then
      return nil, nil, output
    end

    local win_id = tonumber(output:match("%d+")) or kitty_find_window_by_title("nvim-ipython", listen_on)
    if win_id == nil then
      return nil, nil, "Could not determine kitty window id"
    end

    -- Let kitty update ls before querying columns
    vim.cmd("sleep 40m")
    local info = kitty_window_info(win_id, listen_on)
    -- Retry once if not yet visible
    if info == nil then
      vim.cmd("sleep 40m")
      info = kitty_window_info(win_id, listen_on)
    end

    return win_id, info, nil
  end

  local chosen_window_id, ipy_window, launch_err = nil, nil, nil

  -- Only try vsplit (side-by-side). If it fails, surface error.
  chosen_window_id, ipy_window, launch_err = launch_ipython("vsplit")

  if chosen_window_id == nil or ipy_window == nil then
    local err_msg = launch_err or "unknown error"
    -- Surface remote control failures directly
    local check_output = vim.fn.system(base_cmd .. " ls")
    if vim.v.shell_error ~= 0 then
      err_msg = string.format("remote control failed on %s: %s", listen_on, check_output)
    end
    vim.notify("Failed to launch kitty window for IPython: " .. err_msg, vim.log.levels.ERROR)
    return nil
  end

  if current_columns ~= nil and ipy_window.columns ~= nil then
    local target_cols = math.floor(current_columns * 0.3)
    local delta = target_cols - ipy_window.columns
    if delta ~= 0 then
      vim.fn.system(string.format(
        "%s resize-window --match id:%s --axis=horizontal --increment=%d",
        kitty_prefix(listen_on),
        chosen_window_id,
        delta
      ))
    end
  end

  -- Return focus to the original window after spawning the REPL
  if current_window_id ~= nil then
    vim.fn.system(string.format(
      "%s focus-window --match id:%s",
      kitty_prefix(listen_on),
      current_window_id
    ))
  end

  update_slime_config(chosen_window_id, listen_on)
  return chosen_window_id
end

local function kitty_send_text(window_id, listen_on, text)
  local prefix = kitty_prefix(listen_on)
  local cmd = string.format("printf %s | %s send-text --match id:%s --stdin", vim.fn.shellescape(text), prefix, window_id)
  vim.fn.system(cmd)
end

return {
  "jpalardy/vim-slime",
  enabled = true,
  ft = { "python" },
  keys = {
    {
      "<leader>sc",
      function()
        local window_id = ensure_ipython_window()
        if window_id == nil then
          return
        end

        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeSendCell", true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      end,
      desc = "Slime Send Cell",
    },

    {
      "<leader>sl",
      function()
        local window_id = ensure_ipython_window()
        if window_id == nil then
          return
        end

        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeLineSend", true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      end,
      desc = "Slime Send Line",
    },

    {
      "<leader>ss",
      function()
        local window_id = ensure_ipython_window()
        if window_id == nil then
          return
        end

        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeRegionSend", true, false, true)
        vim.api.nvim_feedkeys(keys, "x", false)
      end,
      mode = "v",
      desc = "Slime Send Selection",
    },

    {
      "<leader>sf",
      function()
        local window_id = ensure_ipython_window()
        if window_id == nil then
          return
        end

        local save_cursor = vim.fn.getpos(".")
        vim.cmd("normal! ggVG")
        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeRegionSend", true, false, true)
        vim.api.nvim_feedkeys(keys, "x", false)
        vim.fn.setpos(".", save_cursor)
      end,
      desc = "Slime Send File",
    },
  },
  config = function()
    vim.g.slime_target = "kitty"
    vim.g.slime_default_config = {
      window_id = nil,
      listen_on = vim.env.KITTY_LISTEN_ON or "unix:/tmp/mykitty",
    }
    vim.g.slime_dont_ask_default = 1
    vim.g.slime_bracketed_paste = 1
    vim.g.slime_cell_delimiter = "# %%"

    local function close_repl_window()
      local cfg = vim.b.slime_config or vim.g.slime_default_config
      if cfg == nil or cfg.window_id == nil then
        return
      end

      kitty_send_text(cfg.window_id, cfg.listen_on, "exit\n")
      vim.defer_fn(function()
        vim.fn.system(string.format("%s close-window --match id:%s", kitty_prefix(cfg.listen_on), cfg.window_id))
      end, 300)
    end

    vim.api.nvim_create_user_command("SlimeClose", close_repl_window, {})
    vim.keymap.set("n", "<leader>rq", close_repl_window, { desc = "Close REPL window" })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = close_repl_window,
    })
  end,
}
