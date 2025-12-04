return {
  "jpalardy/vim-slime",
  ft = { "python" },
  keys = {
    {
      "<leader>sc",
      function()
        -- Ensure tmux pane with iPython is running
        local function ensure_ipython_pane()
          -- Check if right pane exists
          local check_cmd = "tmux list-panes -F '#{pane_index}' | wc -l"
          local output = vim.fn.system(check_cmd)
          local pane_count = tonumber(output:match("%d+")) or 1

          if pane_count < 2 then
            -- Create a new pane to the right (30% width) and launch iPython
            vim.fn.system("tmux split-window -h -d -p 30")

            -- Send iPython command to the new pane
            local ipython_cmd = "~/conda/envs/ovito/bin/python -m IPython"
            vim.fn.system(string.format("tmux send-keys -t '{right-of}' '%s' C-m", ipython_cmd))

            -- Brief wait for iPython to start
            vim.fn.system("sleep 0.5")
          end
        end

        ensure_ipython_pane()

        -- Send the cell using feedkeys
        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeSendCell", true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      end,
      desc = "Slime Send Cell",
    },

    {
      "<leader>sl",
      function()
        -- Ensure tmux pane with iPython is running
        local function ensure_ipython_pane()
          -- Check if right pane exists
          local check_cmd = "tmux list-panes -F '#{pane_index}' | wc -l"
          local output = vim.fn.system(check_cmd)
          local pane_count = tonumber(output:match("%d+")) or 1

          if pane_count < 2 then
            -- Create a new pane to the right (30% width) and launch iPython
            vim.fn.system("tmux split-window -h -d -p 30")

            -- Send iPython command to the new pane
            local ipython_cmd = "~/conda/envs/ovito/bin/python -m IPython"
            vim.fn.system(string.format("tmux send-keys -t '{right-of}' '%s' C-m", ipython_cmd))

            -- Brief wait for iPython to start
            vim.fn.system("sleep 0.5")
          end
        end

        ensure_ipython_pane()

        -- Send the line using feedkeys
        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeLineSend", true, false, true)
        vim.api.nvim_feedkeys(keys, "m", false)
      end,
      desc = "Slime Send Line",
    },

    {
      "<leader>ss",
      function()
        -- Ensure tmux pane with iPython is running
        local function ensure_ipython_pane()
          -- Check if right pane exists
          local check_cmd = "tmux list-panes -F '#{pane_index}' | wc -l"
          local output = vim.fn.system(check_cmd)
          local pane_count = tonumber(output:match("%d+")) or 1

          if pane_count < 2 then
            -- Create a new pane to the right (30% width) and launch iPython
            vim.fn.system("tmux split-window -h -d -p 30")

            -- Send iPython command to the new pane
            local ipython_cmd = "~/conda/envs/ovito/bin/python -m IPython"
            vim.fn.system(string.format("tmux send-keys -t '{right-of}' '%s' C-m", ipython_cmd))

            -- Brief wait for iPython to start
            vim.fn.system("sleep 0.5")
          end
        end

        ensure_ipython_pane()

        -- Send the selection using feedkeys
        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeRegionSend", true, false, true)
        vim.api.nvim_feedkeys(keys, "x", false)
      end,
      mode = "v",
      desc = "Slime Send Selection",
    },

    {
      "<leader>sf",
      function()
        -- Ensure tmux pane with iPython is running
        local function ensure_ipython_pane()
          -- Check if right pane exists
          local check_cmd = "tmux list-panes -F '#{pane_index}' | wc -l"
          local output = vim.fn.system(check_cmd)
          local pane_count = tonumber(output:match("%d+")) or 1

          if pane_count < 2 then
            -- Create a new pane to the right (30% width) and launch iPython
            vim.fn.system("tmux split-window -h -d -p 30")

            -- Send iPython command to the new pane
            local ipython_cmd = "~/conda/envs/ovito/bin/python -m IPython"
            vim.fn.system(string.format("tmux send-keys -t '{right-of}' '%s' C-m", ipython_cmd))

            -- Brief wait for iPython to start
            vim.fn.system("sleep 0.5")
          end
        end

        ensure_ipython_pane()

        -- Save cursor position
        local save_cursor = vim.fn.getpos(".")

        -- Select entire file and send
        vim.cmd("normal! ggVG")
        local keys = vim.api.nvim_replace_termcodes("<Plug>SlimeRegionSend", true, false, true)
        vim.api.nvim_feedkeys(keys, "x", false)

        -- Restore cursor position
        vim.fn.setpos(".", save_cursor)
      end,
      desc = "Slime Send File",
    },
  },
  config = function()
    vim.g.slime_target = "tmux"
    vim.g.slime_default_config = {
      socket_name = "default",
      target_pane = "{right-of}",
    }
    vim.g.slime_dont_ask_default = 1
    vim.g.slime_bracketed_paste = 1
    vim.g.slime_cell_delimiter = "# %%"

    -- Function to close REPL pane
    local function close_repl_pane()
      if vim.env.TMUX == nil then
        return
      end

      -- Get current pane index (where Neovim is)
      local current_pane = vim.fn.system("tmux display-message -p '#{pane_index}'"):gsub("%s+", "")

      -- List all panes
      local all_panes = vim.fn.system("tmux list-panes -F '#{pane_index}'")
      local panes = vim.split(all_panes, "\n", { trimempty = true })

      if #panes >= 2 then
        -- Find the other pane (not current one)
        for _, pane in ipairs(panes) do
          if pane ~= current_pane then
            -- Send exit to iPython and kill the other pane
            vim.fn.system(string.format("tmux send-keys -t %s 'exit' C-m", pane))
            vim.defer_fn(function()
              vim.fn.system(string.format("tmux kill-pane -t %s", pane))
            end, 300)
            break
          end
        end
      end
    end

    -- Manual command to close REPL
    vim.api.nvim_create_user_command("SlimeClose", close_repl_pane, {})

    -- Keymap to close REPL
    vim.keymap.set("n", "<leader>rq", close_repl_pane, { desc = "Close REPL pane" })

    -- Auto-close REPL when exiting Neovim
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = close_repl_pane,
    })
  end,
}
