return {
  "stellarjmr/notebook_style.nvim",
  build = function(plugin)
    local install = loadfile(plugin.dir .. "/lua/notebook_style/install.lua")()
    install.run(plugin)
  end,
  ft = "python", -- Load only when opening Python files
  opts = {
    manual_render = false,
    filetypes = { "python" },
    -- Choose border style: 'solid', 'dashed', or 'double'
    border_style = "solid",

    -- Customize colors
    colors = {
      border = "#a7c080", -- Dracula comment color
      delimiter = "#e69875", -- Dracula green
    },

    -- Behavior options
    hide_delimiter = true,
    hide_border_in_insert = true,

    -- Cell marker (requires Nerd Font)
    cell_marker = " Cell", --  is Python nerd font icon

    -- Cell width configuration
    cell_width_percentage = 80, -- Use 80% of window width
    min_cell_width = 40,
    max_cell_width = 150,
  },
}
