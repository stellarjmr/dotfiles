return {
  "hkupty/iron.nvim",
  ft = "python",
  lazy = true,
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")

    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = {
          python = {
            format = require("iron.fts.common").bracketed_paste,
            command = { "ipython", "--no-autoindent" },
            block_dividers = { "# %%", "#%%" },
          },
        },
        preferred = {
          python = "ipython",
        },
        repl_open_cmd = view.split.vertical.rightbelow("%20"),
      },
      keymaps = {
        toggle_repl = "<space>rr",
        restart_repl = "<space>rR",
        send_motion = "<leader>sc",
        visual_send = "<space>sc",
        send_file = "<leader>sf",
        send_line = "<leader>sl",
        send_code_block = "<space>sb",
        send_code_block_and_move = "<space>sN",
        cr = "<leader>s<cr>",
        interrupt = "<leader>s<space>",
        exit = "<leader>sq",
        clear = "<leader>cl",
      },
      highlight = {
        italic = false,
      },
      ignore_blank_lines = true,
    })
    vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>")
    vim.keymap.set("n", "<space>rh", "<cmd>IronHide<cr>")

    -- Auto-close iron REPL when quitting
    vim.api.nvim_create_autocmd("BufWinEnter", {
      callback = function(args)
        local bufname = vim.api.nvim_buf_get_name(args.buf)
        if bufname:match("iron://") then
          -- Set buffer options to auto-close
          vim.bo[args.buf].buftype = "nofile"
          vim.bo[args.buf].bufhidden = "hide"
          vim.bo[args.buf].buflisted = false
          vim.bo[args.buf].swapfile = false
        end
      end,
    })

    -- Auto-hide REPL before quitting
    vim.api.nvim_create_autocmd("QuitPre", {
      callback = function()
        vim.cmd("silent! IronHide")
      end,
    })
  end,
}
