-- Load local configuration
local ok, local_config = pcall(require, "config.local_config")
if not ok then
  vim.notify("local_config.lua not found. Copy local_config.example.lua to local_config.lua", vim.log.levels.WARN)
  local_config = {
    project_folders = {},
    todo_section = function()
      return function()
        return {}
      end
    end,
  }
end

-- Main configuration
return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = function()
    -- Detect whether the dashboard window still has room for a second pane.
    local function dashboard_has_pane_space()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype == "snacks_dashboard" then
            return vim.api.nvim_win_get_width(win) > 120
          end
        end
      end
      return vim.o.columns > 120
    end

    return {
      bigfile = { enable = true },
      statuscolumn = { enable = true },
      quickfile = { enable = true },
      terminal = {
        win = {
          keys = {
            term_normal = { "<esc>", "<C-\\><C-n>", mode = "t", desc = "Exit terminal mode" },
          },
        },
      },
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
        win = {
          input = {
            keys = {
              ["<Esc>"] = { "close", mode = { "n", "i" } },
            },
          },
        },
        sources = {
          explorer = {
            enable = false,
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
              icon = " ",
              key = "b",
              desc = "Browser",
              action = function()
                vim.fn.system("open -a 'Zen' 'https://github.com/stellarjmr'")
              end,
              hidden = true,
            },
            {
              icon = " ",
              key = "p",
              desc = "Projects",
              action = function()
                vim.ui.select(local_config.project_folders, {
                  prompt = "Select Project:",
                }, function(choice)
                  if choice then
                    local expanded_path = vim.fn.expand(choice)
                    vim.cmd("cd " .. vim.fn.fnameescape(expanded_path))
                    vim.cmd(":lua Snacks.dashboard.pick('files', { cwd = expanded_path })")
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
          local_config.todo_section({
            file = vim.fn.expand("~/Documents/Notes/todo.md"),
            pane = 2,
            icon = " ",
            title = "My Todos",
            limit = 5,
            indent = 2,
            enabled = function()
              return dashboard_has_pane_space()
            end,
          }),
          {
            icon = " ",
            title = "Recent Files",
            section = "recent_files",
            indent = 2,
            padding = 1,
            gap = 0,
            pane = 2,
            enabled = function()
              return dashboard_has_pane_space()
            end,
          },
          {
            icon = " ",
            title = "Projects",
            section = "projects",
            indent = 2,
            padding = 1,
            gap = 0,
            pane = 2,
            enabled = function()
              return dashboard_has_pane_space()
            end,
          },
          { section = "startup" },
        },
      },
    }
  end,
  keys = {
    {
      "<leader>bg",
      function()
        vim.fn.system("open -a 'Zen' 'https://github.com/stellarjmr'")
      end,
      desc = "Open GitHub in browser",
      mode = "n",
    },
    {
      "<leader>p",
      function()
        vim.ui.select(local_config.project_folders, {
          prompt = "Select Project:",
        }, function(choice)
          if choice then
            local expanded_path = vim.fn.expand(choice)
            vim.cmd("cd " .. vim.fn.fnameescape(expanded_path))
            vim.cmd(":lua Snacks.dashboard.pick('files', { cwd = expanded_path })")
          end
        end)
      end,
      desc = "Open Project Manager",
    },
    {
      "<leader>o",
      function()
        Snacks.picker.pick("files", { cwd = "~/Documents/Notes" })
      end,
      desc = "Open Notes",
    },
    {
      "<leader>fC",
      function()
        Snacks.picker.pick("files", { cwd = "~/.config" })
      end,
      desc = "Find XDG Config File",
    },
    {
      "<leader>fB",
      function()
        local buf = vim.api.nvim_buf_get_name(0)
        if buf == "" then
          vim.notify("No file name for current buffer", vim.log.levels.WARN)
          return
        end
        Snacks.picker.grep({ dirs = { buf } })
      end,
      desc = "Grep Current Buffer",
    },
    {
      "<leader>fd",
      function()
        Snacks.picker.pick("files", {
          cwd = "~/Documents",
          hidden = false,
          -- Add folders to exclude here
          exclude = { "Master", "PhD/Documents", "PDRA/Documents", "GitHub", "Notes" },
        })
      end,
      desc = "Find Documents File",
    },
    {
      "<leader>tt",
      function()
        Snacks.terminal.toggle(nil, {
          win = {
            position = "bottom",
            height = 0.3,
          },
        })
      end,
      desc = "Toggle Terminal (horizontal split)",
    },
    {
      "<leader>tb",
      function()
        Snacks.terminal.toggle("btop", {
          win = {
            position = "float",
            width = 0.7,
            height = 0.71,
            title = " btop ",
          },
        })
      end,
      desc = "Toggle btop (vertical split)",
    },
  },
  config = function(_, opts)
    local function set_snacks_hl()
      -- Keep Snacks windows (e.g. lazygit terminal) using the normal background
      vim.api.nvim_set_hl(0, "SnacksNormal", { link = "Normal" })
      vim.api.nvim_set_hl(0, "SnacksNormalNC", { link = "Normal" })
    end

    require("snacks").setup(opts)

    set_snacks_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("snacks_hl_fix", { clear = true }),
      callback = set_snacks_hl,
    })
  end,
}
