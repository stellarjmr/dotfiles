return {
  {
    "catppuccin/nvim",
    config = function()
      require("catppuccin").setup({
        flavour = "auto", -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = "latte",
          dark = "mocha",
        },
        transparent_background = true,
        term_colors = true,
        no_italic = true,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  -- {
  --   "uloco/bluloco.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   dependencies = { "rktjmp/lush.nvim" },
  --   config = function()
  --     require("bluloco").setup({
  --       style = "auto",
  --       transparent = true,
  --       italics = false,
  --     })
  --     vim.cmd([[colorscheme bluloco]])
  --   end,
  -- },
}
