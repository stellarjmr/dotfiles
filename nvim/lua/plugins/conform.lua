-- lua/plugins/conform.lua
return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
      ["_"] = { "trim_whitespace" },
      lua = { "stylua" },
      python = { "ruff_format" },
      sh = { "shfmt" },
      tex = { "tex-fmt" },
    })
  end,
}
