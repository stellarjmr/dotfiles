return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "BufReadPre",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
        },
      })

      -- Custom terminal
      local Terminal = require("toggleterm.terminal").Terminal

      -- btop
      local btop = Terminal:new({
        cmd = "btop",
        hidden = true,
        direction = "float",
        float_opts = {
          border = "curved",
        },
      })

      function _BTOP_TOGGLE()
        btop:toggle()
      end

      -- lazygit
      local lazygit = Terminal:new({
        -- cmd = "lazygit",
        -- hidden terms need high ids otherwise clash with count toggle
        id = 100,
        cmd = [[
          THEME=$(defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo dark || echo light)
          # THEME=dark
          # THEME=light
          XDG_CONFIG_DIR=~/.config
          CONFIG_BASE=${XDG_CONFIG_DIR}/lazygit/config.yml
          CONFIG_THEME=${XDG_CONFIG_DIR}/lazygit/config-${THEME}.yml
          lazygit --use-config-file=${CONFIG_BASE},${CONFIG_THEME}
          ]],
        hidden = true,
        direction = "float",
        float_opts = {
          border = "curved",
        },
      })
      local cmd = vim.api.nvim_create_user_command
      cmd("LazygitOpen", function()
        lazygit:open()
      end, {})
      cmd("LazygitToggle", function()
        lazygit:toggle()
      end, {})
      cmd("LazygitClose", function()
        lazygit:close()
      end, {})

      function _LAZYGIT_TOGGLE()
        lazygit:toggle()
      end

      -- Shortcut bindings (<leader>bt opens btop, <leader>lg opens lazygit)
      vim.keymap.set(
        "n",
        "<leader>bt",
        "<cmd>lua _BTOP_TOGGLE()<CR>",
        { noremap = true, silent = true, desc = "Toggle btop" }
      )
      vim.keymap.set(
        "n",
        "<leader>lg",
        "<cmd>lua _LAZYGIT_TOGGLE()<CR>",
        { noremap = true, silent = true, desc = "Toggle lazygit" }
      )
      -- Quick open terminal
      vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", { desc = "Toggle floating terminal" })
      vim.keymap.set(
        "n",
        "<leader>tt",
        "<cmd>ToggleTerm size=10 direction=horizontal<CR>",
        { desc = "Toggle horizontal terminal" }
      )
      vim.keymap.set(
        "n",
        "<leader>tv",
        "<cmd>ToggleTerm size=44 direction=vertical<CR>",
        { desc = "Toggle vertical terminal" }
      )
      -- Quick return from terminal mode to normal mode
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true, desc = "Terminal normal mode" })
    end,
  },
}
