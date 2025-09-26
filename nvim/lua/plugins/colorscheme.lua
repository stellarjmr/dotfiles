return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "bluloco",
    },
  },
  {
    "neanias/everforest-nvim",
    enabled = false,
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
    enabled = true,
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
    "rebelot/kanagawa.nvim",
    enabled = false,
    opts = {
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
      transparent = false,
      theme = "wave",
    },
  },
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
}
