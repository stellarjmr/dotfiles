return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_c = opts.sections.lualine_c or {}

    -- CLI session status
    table.insert(opts.sections.lualine_x, 2, {
      function()
        local status = require("sidekick.status").cli()
        return " " .. (#status > 1 and #status or "")
      end,
      cond = function()
        return #require("sidekick.status").cli() > 0
      end,
      color = function()
        return "Special"
      end,
    })
  end,
}
