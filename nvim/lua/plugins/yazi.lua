return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    {
      "<leader>e",
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    {
      "<leader>E",
      "<cmd>Yazi toggle<cr>",
      desc = "Resume the last yazi session",
    },
  },
  ---@type YaziConfig
  opts = {
    open_for_directories = true,
    floating_window_scaling_factor = 0.8,
    yazi_floating_window_winblend = 0,
    keymaps = {
      show_help = "<f1>",
    },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
