-- Todo list section completion
local function todo_section(opts)
  opts = opts or {}
  local todo_file = opts.file or vim.fn.expand("~/todo.md")

  return function(self)
    local items = {}

    -- head
    table.insert(items, {
      title = opts.title or "Todo List",
      pane = opts.pane or 2,
      icon = opts.icon or " ",
      indent = -2,
      padding = { 0, 1 },
      enabled = opts.enabled,
    })

    -- read todo file
    local file = io.open(todo_file, "r")
    if not file then
      table.insert(items, {
        text = {
          { "  No todo file found", hl = "Comment" },
          { "  Create: " .. todo_file, hl = "Comment" },
        },
        pane = opts.pane or 2,
        indent = 2,
      })
      return items
    end

    local content = file:read("*all")
    file:close()

    -- parse todo items
    local todos = {}
    for line in content:gmatch("[^\r\n]+") do
      -- : - [ ] or - [x] or - [X]
      local checked, text = line:match("^%s*%- %[([%sx])%]%s*(.+)$")
      if text then
        local is_done = checked:lower() == "x"

        -- try read date (@2024-01-15 or due:2024-01-15)
        local date = text:match("@(%d%d%d%d%-%d%d%-%d%d)") or text:match("due:(%d%d%d%d%-%d%d%-%d%d)")

        -- priority (!high, !medium, !low)
        local priority = text:match("!(%w+)")

        table.insert(todos, {
          text = text,
          done = is_done,
          date = date,
          priority = priority,
          enabled = opts.enabled,
        })
      end
    end

    -- display todo items
    local key_num = 1
    for i, todo in ipairs(todos) do
      if i <= (opts.limit or 10) then

        -- color by priority
        local priority_hl = "Normal"
        if todo.priority == "high" then
          priority_hl = "DiagnosticError"
        elseif todo.priority == "medium" then
          priority_hl = "DiagnosticWarn"
        elseif todo.priority == "low" then
          priority_hl = "DiagnosticInfo"
        end

        local icon = todo.done and "✓ " or "○ "
        local icon_hl = todo.done and 'DiagnosticOk' or priority_hl

        local text_parts = {
          { icon, hl = icon_hl },
          {
            todo.text
              :gsub("@%d%d%d%d%-%d%d%-%d%d", "")
              :gsub("due:%d%d%d%d%-%d%d%-%d%d", "")
              :gsub("!%w+", "")
              :gsub("%s+", " "),
            hl = priority_hl,
          },
        }

        -- add date if exists
        if todo.date then
          table.insert(text_parts, { " " .. todo.date, hl = "Comment" })
        end

        table.insert(items, {
          text = text_parts,
          key = not todo.done and "t" or nil,
          pane = opts.pane or 2,
          indent = opts.indent or 2,
          enabled = opts.enabled,
          action = function()
            -- open todo file
            vim.cmd("edit " .. todo_file)
          end,
        })
      end
    end

    -- statistics info
    local total = #todos
    local done = 0
    for _, todo in ipairs(todos) do
      if todo.done then
        done = done + 1
      end
    end

    table.insert(items, {
      text = {
        { "  ", hl = "Comment" },
        { string.format("Progress: %d/%d completed", done, total), hl = "Comment" },
      },
      pane = opts.pane or 2,
      indent = opts.indent or 2,
      padding = { 1, 0 },
      enabled = opts.enabled,
    })

    return items
  end
end

-- Main configuration
return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>p",
      function()
        -- Define your project folders here (same as in opts)
        local project_folders = {
          "~/Documents/PDRA/NU/Oxide/scripts",
          "~/Documents/PDRA/NU/KTaNbCl/scripts",
          "~/Documents/PDRA/NU/NaZrSOClBr/scripts",
          "~/Documents/PDRA/NU/Na3PS4/scripts",
          "~/Documents/PDRA/NU/SiGe/scripts",
        }
        vim.ui.select(project_folders, {
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
  },
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
          --- empty for better visual separation
          -- {
          --   indent = 2,
          --   pane = 2,
          --   padding = 3,
          --   enabled = function()
          --     return dashboard_has_pane_space()
          --   end,
          -- },
          todo_section({
            file = vim.fn.expand("~/Documents/Notes/todo.md"),
            pane = 2,
            icon = " ",
            title = "My Todos",
            limit = 8,
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
          --- recent notes from ~/Documents/Notes
          -- {
          --   icon = " ",
          --   title = "Recent Notes",
          --   section = "recent_files",
          --   padding = 1,
          --   indent = 2,
          --   gap = 0,
          --   pane = 2,
          --   cwd = "~/Documents/Notes",
          --   enabled = function()
          --     return dashboard_has_pane_space()
          --   end,
          -- },
          { section = "startup" },
        },
      },
    }
  end,
}
