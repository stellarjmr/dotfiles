return {
  {
    "catppuccin/nvim",
    config = function()
      require("catppuccin").setup({
        flavour = "auto",
        background = {
          light = "latte",
          dark = "mocha",
        },
        transparent_background = true,
        term_colors = true,
        no_italic = true,
        specs = {
          "akinsho/bufferline.nvim",
          init = function()
            local bufline = require("catppuccin.groups.integrations.bufferline")
            function bufline.get()
              return bufline.get_theme()
            end
          end,
        },
      })
    end,
  },
  {
    "neanias/everforest-nvim",
    version = false,
    config = function()
      require("everforest").setup({
        background = "hard", -- "hard", "medium" or "soft"
        transparent_background_level = 2,
        italics = false,
        disable_italic_comments = false,
      })
    end,
  },
  {
    "uloco/bluloco.nvim",
    lazy = false,
    priority = 1000,
    enabled = false,
    dependencies = { "rktjmp/lush.nvim" },
    config = function()
      require("bluloco").setup({
        style = "auto",
        transparent = true,
        italics = false,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}
