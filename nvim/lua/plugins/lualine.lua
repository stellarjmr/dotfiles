return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.component_separators = { left = "", right = "" }
    opts.options.section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" }

    -- Add rounded separators to section a (mode) and z (location)
    opts.sections = opts.sections or {}
    opts.sections.lualine_a = {
      { "mode", separator = { left = "\u{e0b6}", right = "\u{e0b4}" }, padding = 1 }
    }
    opts.sections.lualine_z = {
      { "location", separator = { left = "\u{e0b6}", right = "\u{e0b4}" }, padding = 1 }
    }
  end,
}
