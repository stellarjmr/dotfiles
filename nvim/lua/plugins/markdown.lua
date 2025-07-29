return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "text" },
  -- event = { "BufReadPre" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" }, -- if you use standalone mini plugins
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
  -- lazy = true,
}
