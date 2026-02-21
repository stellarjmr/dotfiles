return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.diagnostics = opts.diagnostics or {}
      opts.diagnostics.underline = false
      opts.diagnostics.virtual_text = false
      opts.diagnostics.update_in_insert = false
      opts.diagnostics.severity_sort = false
      opts.diagnostics.float = vim.tbl_deep_extend("force", opts.diagnostics.float or {}, {
        source = "if_many",
        border = "rounded",
      })
      opts.servers = opts.servers or {}
      opts.servers.ruff = {
        init_options = {
          settings = {
            lint = {
              ignore = { "E402" },
            },
          },
        },
      }
      opts.servers.tinymist = {
        settings = {
          formatterMode = "typstyle", -- or "typstfmt"
          formatterProseWrap = true, -- wrap lines in content mode
          formatterPrintWidth = 100, -- limit line length to 80 if possible
          formatterIndentSize = 2, -- indentation width
          exportPdf = "onType",
          semanticTokens = "disable",
        },
      }
      return opts
    end,
  },
}
