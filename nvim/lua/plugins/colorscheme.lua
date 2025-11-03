return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
  {
    "sainnhe/everforest",
    enabled = true,
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.background = "dark"
      vim.g.everforest_background = "hard"
      vim.g.everforest_transparent_background = 2
      vim.g.everforest_current_word = "bold"
      vim.g.everforest_enable_italic = 1
      vim.cmd.colorscheme("everforest")
    end,
  },
}
