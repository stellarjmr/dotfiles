return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    bigfile = { enable = true },
    statuscolumn = { enable = true },
    quickfile = { enable = true },
    image = {
      doc = {
        enabled = true,
        inline = true,
        float = false,
        max_width = 40,
        max_height = 20,
      },
      convert = {
        notify = false,
      },
    },
    picker = {
      sources = {
        explorer = {
          auto_close = true,
          layout = {
            layout = {
              width = 25,
            },
          },
        },
      },
    },
    dashboard = {
      preset = {
        -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,
        -- Used by the `keys` section to show keymaps.
        -- Set your custom keymaps here.
        -- When using a function, the `items` argument are the default keymaps.
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          {
            icon = "󱁤 ",
            key = "m",
            desc = "Mason",
            action = ":Mason",
          },
          {
            icon = " ",
            key = "x",
            desc = "Extras",
            action = ":LazyExtras",
          },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        header = [[

 ██████╗███████╗███╗   ███╗   ██╗   ██╗     ██████╗
██╔════╝╚══███╔╝████╗ ████║   ██║   ██║     ██╔══██╗
██║       ███╔╝ ██╔████╔██║████████╗██║     ██████╔╝
██║      ███╔╝  ██║╚██╔╝██║██╔═██╔═╝██║     ██╔══██╗
╚██████╗███████╗██║ ╚═╝ ██║██████║  ███████╗██║  ██║
 ╚═════╝╚══════╝╚═╝     ╚═╝╚═════╝  ╚══════╝╚═╝  ╚═╝

              ]],
      },
      sections = {
        { section = "header", indent = 0 },
        { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1, gap = 0 },
        { indent = 2, pane = 2, padding = 3 },
        { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1, gap = 0, pane = 2 },
        { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1, gap = 0, pane = 2 },
        {
          icon = "󰚸 ",
          title = "Recent Notes",
          section = "recent_files",
          padding = 1,
          indent = 2,
          gap = 0,
          pane = 2,
          cwd = "~/Documents/Notes",
        },
        { section = "startup" },
      },
    },
  },
}
