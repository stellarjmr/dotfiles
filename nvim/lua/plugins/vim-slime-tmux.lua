-- Only activate this tmux-based setup in Ghostty sessions.
if vim.env.TERM ~= "xterm-ghostty" then
  return {}
end

-- tmux-based vim-slime setup for Ghostty sessions.
local function ensure_tmux()
  if vim.env.TMUX == nil then
    vim.notify("vim-slime tmux config requires a tmux session", vim.log.levels.WARN)
    return false
  end

  return true
end

local function ensure_ipython_pane()
  if not ensure_tmux() then
    return nil
  end

  local pane_count_output = vim.fn.system("tmux list-panes -F '#{pane_index}' | wc -l")
  local pane_count = tonumber(pane_count_output:match("%d+")) or 1

  if pane_count < 2 then
    vim.fn.system("tmux split-window -h -d -p 30")
    local ipython_cmd = vim.fn.expand("~/conda/envs/ovito/bin/python -m IPython")
    vim.fn.system(string.format("tmux send-keys -t '{right-of}' %s C-m", vim.fn.shellescape(ipython_cmd)))
    vim.fn.system("sleep 0.5")
  end

  return true
end

local function close_repl_pane()
  if not ensure_tmux() then
    return
  end

  local current_pane = vim.fn.system("tmux display-message -p '#{pane_index}'"):gsub("%s+", "")
  local all_panes = vim.fn.system("tmux list-panes -F '#{pane_index}'")
  local panes = vim.split(all_panes, "\n", { trimempty = true })

  if #panes < 2 then
    return
  end

  for _, pane in ipairs(panes) do
    if pane ~= current_pane then
      vim.fn.system(string.format("tmux send-keys -t %s 'exit' C-m", pane))
      vim.defer_fn(function()
        vim.fn.system(string.format("tmux kill-pane -t %s", pane))
      end, 300)
      break
    end
  end
end

return {
  "jpalardy/vim-slime",
  enabled = true,
  ft = { "python" },
  keys = {
    {
      "<leader>sc",
      function()
        if not ensure_ipython_pane() then
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
        if not ensure_ipython_pane() then
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
        if not ensure_ipython_pane() then
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
        if not ensure_ipython_pane() then
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
    if not ensure_tmux() then
      return
    end

    vim.g.slime_target = "tmux"
    vim.g.slime_default_config = {
      socket_name = "default",
      target_pane = "{right-of}",
    }
    vim.g.slime_dont_ask_default = 1
    vim.g.slime_bracketed_paste = 1
    vim.g.slime_cell_delimiter = "# %%"

    vim.api.nvim_create_user_command("SlimeClose", close_repl_pane, {})
    vim.keymap.set("n", "<leader>rq", close_repl_pane, { desc = "Close REPL pane" })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = close_repl_pane,
    })
  end,
}
