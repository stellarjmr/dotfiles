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
      vim.opt.background = "light"
      vim.g.everforest_background = "soft"
      vim.g.everforest_transparent_background = 2
      vim.g.everforest_current_word = "bold"
      vim.g.everforest_enable_italic = 1
      vim.cmd.colorscheme("everforest")
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
}
