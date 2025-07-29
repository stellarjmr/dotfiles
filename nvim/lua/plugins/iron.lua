return {
  "hkupty/iron.nvim",
  ft = "python",
  lazy = true,
  config = function()
    local iron = require("iron.core")

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
        repl_open_cmd = "vertical botright 25 split",
      },
      keymaps = {
        toggle_repl = "<space>rr",
        restart_repl = "<space>rR",
        send_motion = "<leader>sc",
        visual_send = "<space>sc",
        send_file = "<leader>sf",
        send_line = "<leader>sl",
        send_paragraph = "<space>sp",
        send_until_cursor = "<space>su",
        send_code_block = "<space>sb",
        send_code_block_and_move = "<space>sN",
        send_mark = "<leader>sm",
        mark_motion = "<leader>mc",
        mark_visual = "<leader>mc",
        remove_mark = "<leader>md",
        cr = "<leader>s<cr>",
        interrupt = "<leader>s<space>",
        exit = "<leader>sq",
        clear = "<leader>cl",
      },
      highlight = {
        italic = true,
      },
      ignore_blank_lines = true,
    })
    vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>")
    vim.keymap.set("n", "<space>rh", "<cmd>IronHide<cr>")
  end,
}
