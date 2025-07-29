-- ~/.config/nvim/lua/plugins/conform.lua
return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      -- python = { "black" },
      sh = { "shfmt" },
      -- tex = { "tex-fmt" },
    },
    format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
  },
}
