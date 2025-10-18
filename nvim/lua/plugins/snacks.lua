return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = function()
    -- Define your project folders here
    local project_folders = {
      "~/Documents/PDRA/NU/Oxide/scripts",
      "~/Documents/PDRA/NU/KTaNbCl/scripts",
      "~/Documents/PDRA/NU/NaZrSOClBr/scripts",
      "~/Documents/PDRA/NU/Na3PS4/scripts",
      "~/Documents/PDRA/NU/SiGe/scripts",
    }

    return {
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
        math = {
          enabled = true,
          latex = {
            font_size = "Large",
            packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools" },
          },
        },
      },
      picker = {
        sources = {
          explorer = {
            enable = false,
            --- float explorer
            -- layout = {
            --   { preview = true },
            --   layout = {
            --     box = "horizontal",
            --     width = 0.8,
            --     height = 0.8,
            --     {
            --       box = "vertical",
            --       border = "rounded",
            --       title = "{source} {live} {flags}",
            --       title_pos = "center",
            --       { win = "input", height = 1, border = "bottom" },
            --       { win = "list", border = "none" },
            --     },
            --     { win = "preview", border = "rounded", width = 0.7, title = "{preview}" },
            --   },
            -- },
            --- normal explorer
            layout = {
              layout = {
                position = "left",
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
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            {
              icon = " ",
              key = "p",
              desc = "Projects",
              action = function()
                vim.ui.select(project_folders, {
                  prompt = "Select Project:",
                }, function(choice)
                  if choice then
                    local expanded_path = vim.fn.expand(choice)
                    vim.cmd("cd " .. vim.fn.fnameescape(expanded_path))
                    Snacks.dashboard.pick("files", { cwd = expanded_path })
                  end
                end)
              end,
            },
            {
              icon = " ",
              key = "o",
              desc = "Notes",
              action = ":lua Snacks.dashboard.pick('files', {cwd = '~/Documents/Notes'})",
            },
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
          {
            icon = " ",
            title = "Recent Files",
            section = "recent_files",
            indent = 2,
            padding = 1,
            gap = 0,
            pane = 2,
          },
          { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1, gap = 0, pane = 2 },
          {
            icon = " ",
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
    }
  end,
}
