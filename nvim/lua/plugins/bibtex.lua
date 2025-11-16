-- ============================================================================
-- BibTeX Picker
-- ============================================================================

return {
  "folke/snacks.nvim",
  optional = true,
  opts = function(_, opts)
    -- Inline the bibtex module code
    local M = {}
    local uv = vim.uv or vim.loop

    -- ========================================================================
    -- PARSER MODULE
    -- ========================================================================

    local function read_file(path)
      local fd = uv.fs_open(path, "r", 438)
      if not fd then
        return nil, ("Could not open %s"):format(path)
      end
      local stat = uv.fs_fstat(fd)
      if not stat then
        uv.fs_close(fd)
        return nil, ("Could not stat %s"):format(path)
      end
      local data = uv.fs_read(fd, stat.size, 0)
      uv.fs_close(fd)
      if not data then
        return nil, ("Could not read %s"):format(path)
      end
      return data
    end

    local function count_braces(line)
      local level = 0
      for c in line:gmatch("[{}]") do
        level = level + (c == "{" and 1 or -1)
      end
      return level
    end

    local function parse_value(body, idx)
      local len = #body
      while idx <= len and body:sub(idx, idx):match("%s") do
        idx = idx + 1
      end
      if idx > len then
        return "", idx
      end
      local first = body:sub(idx, idx)
      if first == "{" then
        local depth = 0
        local j = idx
        while j <= len do
          local ch = body:sub(j, j)
          if ch == "{" then
            depth = depth + 1
          elseif ch == "}" then
            depth = depth - 1
            if depth == 0 then
              break
            end
          end
          j = j + 1
        end
        local value = body:sub(idx + 1, j - 1)
        return vim.trim(value), j + 1
      elseif first == '"' then
        local j = idx + 1
        while j <= len do
          local ch = body:sub(j, j)
          local prev = j > 1 and body:sub(j - 1, j - 1) or nil
          if ch == '"' and prev ~= "\\" then
            break
          end
          j = j + 1
        end
        local value = body:sub(idx + 1, j - 1)
        return vim.trim(value), j + 1
      else
        local s, e = body:find("[^,%}]+", idx)
        if not s then
          return "", len + 1
        end
        local value = vim.trim(body:sub(s, e))
        return value, e + 1
      end
    end

    local function parse_fields(body)
      local fields = {}
      local idx = 1
      local len = #body
      while idx <= len do
        local _, next_idx, name = body:find("%s*([%w_%-]+)%s*=", idx)
        if not name then
          break
        end
        idx = next_idx + 1
        local value
        value, idx = parse_value(body, idx)
        if value ~= "" then
          fields[name:lower()] = value
        end
        while idx <= len and body:sub(idx, idx):match("[%s,]") do
          idx = idx + 1
        end
      end
      return fields
    end

    local function parse_entries(text, path)
      local entries = {}
      local lines = vim.split(text, "\n", { plain = true })
      local current
      local brace_level = 0
      for idx, line in ipairs(lines) do
        if not current then
          local entry_type, rest = line:match("^%s*@(%w+)%s*%{(.*)$")
          if entry_type then
            entry_type = entry_type:lower()
            if entry_type ~= "comment" and entry_type ~= "preamble" and entry_type ~= "string" then
              local key = rest:match("^%s*([^,%s]+)")
              if key then
                current = {
                  type = entry_type,
                  key = key,
                  fields = {},
                  file = path,
                  line = idx,
                  lines = { line },
                }
                brace_level = count_braces(line)
              end
            end
          end
        else
          current.lines[#current.lines + 1] = line
          brace_level = brace_level + count_braces(line)
          if brace_level <= 0 then
            local raw = table.concat(current.lines, "\n")
            if not raw:match("\n$") then
              raw = raw .. "\n"
            end
            current.raw = raw
            local body = raw:match("@%w+%s*%b{}")
            if body then
              local inner = body:match("%b{}")
              if inner then
                inner = inner:sub(2, -2)
                inner = inner:gsub("^%s*[^,%s]+%s*,", "", 1)
                current.fields = parse_fields(inner)
              end
            end
            entries[#entries + 1] = {
              key = current.key,
              type = current.type,
              fields = current.fields,
              file = current.file,
              raw = current.raw,
              line = current.line,
            }
            current = nil
            brace_level = 0
          end
        end
      end
      return entries
    end

    local function find_project_files(cfg)
      if cfg.files then
        return vim.deepcopy(cfg.files)
      end
      local cwd = (vim.uv and vim.uv.cwd()) or vim.loop.cwd()
      local opts_find = { path = cwd, type = "file" }
      if cfg.depth ~= nil then
        opts_find.depth = cfg.depth
      end
      local found = vim.fs.find(function(name, _)
        return name:lower():match("%.bib$") ~= nil
      end, opts_find)
      return found
    end

    local function load_entries(cfg)
      local files = {}
      local seen = {}
      for _, path in ipairs(find_project_files(cfg)) do
        if not seen[path] then
          seen[path] = true
          files[#files + 1] = path
        end
      end
      for _, path in ipairs(cfg.global_files or {}) do
        path = vim.fs.normalize(path)
        if not seen[path] then
          seen[path] = true
          files[#files + 1] = path
        end
      end

      local entries = {}
      local errors = {}
      local order = 0
      for _, path in ipairs(files) do
        local text, err = read_file(path)
        if not text then
          errors[#errors + 1] = err or ("Failed to read %s"):format(path)
        else
          local parsed = parse_entries(text, path)
          for _, entry in ipairs(parsed) do
            order = order + 1
            entry.order = order
            entries[#entries + 1] = entry
          end
        end
      end
      return entries, errors
    end

    -- ========================================================================
    -- CONFIG MODULE
    -- ========================================================================

    local config_options = {
      depth = 1,
      files = nil,
      global_files = {},
      search_fields = { "author", "year", "title", "journal", "journaltitle", "editor" },
      format = "%s",
      locale = "en",
      mappings = {},
    }

    local function normalize_files(files)
      if not files then
        return nil
      end
      local ret = {}
      local seen = {}
      for _, file in ipairs(files) do
        if type(file) == "string" and file ~= "" then
          local expanded = file
          if expanded:find("[~$]") then
            local ok, result = pcall(vim.fn.expand, expanded)
            if ok and type(result) == "string" and result ~= "" then
              expanded = result
            end
          end
          local normalized = vim.fs.normalize(expanded)
          if not seen[normalized] then
            seen[normalized] = true
            ret[#ret + 1] = normalized
          end
        end
      end
      return ret
    end

    local function config_setup(setup_opts)
      if not setup_opts then
        return vim.deepcopy(config_options)
      end
      local merged = vim.tbl_deep_extend("force", vim.deepcopy(config_options), setup_opts)
      merged.files = normalize_files(merged.files)
      merged.global_files = normalize_files(merged.global_files) or {}
      config_options = merged
      return vim.deepcopy(config_options)
    end

    local function config_resolve(resolve_opts)
      if not resolve_opts then
        return vim.deepcopy(config_options)
      end
      local merged = vim.tbl_deep_extend("force", vim.deepcopy(config_options), resolve_opts)
      merged.files = normalize_files(merged.files) or merged.files
      merged.global_files = normalize_files(merged.global_files) or merged.global_files
      merged.global_files = merged.global_files or {}
      return merged
    end

    -- ========================================================================
    -- PICKER MODULE
    -- ========================================================================

    local function ensure_snacks(snacks_opts)
      local ok, Snacks = pcall(require, "snacks")
      if not ok or not Snacks.picker then
        if not (snacks_opts and snacks_opts.silent) then
          vim.notify("snacks.nvim with picker module is required", vim.log.levels.ERROR, {
            title = "bibtex",
          })
        end
        return nil
      end
      return Snacks
    end

    local function to_lines(text)
      local lines = vim.split(text, "\n", { plain = true })
      if #lines > 0 and lines[#lines] == "" then
        table.remove(lines)
      end
      return lines
    end

    local function insert_text(picker, text)
      if not text or text == "" then
        return
      end
      local win
      if picker and picker._bibtex_origin_win and vim.api.nvim_win_is_valid(picker._bibtex_origin_win) then
        win = picker._bibtex_origin_win
      elseif picker and picker.main and vim.api.nvim_win_is_valid(picker.main) then
        win = picker.main
      end
      win = win or vim.api.nvim_get_current_win()
      if not vim.api.nvim_win_is_valid(win) then
        return
      end
      local buf = vim.api.nvim_win_get_buf(win)
      local cursor = vim.api.nvim_win_get_cursor(win)
      local row = cursor[1] - 1
      local col = cursor[2]
      local lines = to_lines(text)
      if #lines == 0 then
        return
      end
      local ok = pcall(vim.api.nvim_buf_set_text, buf, row, col, row, col, lines)
      if not ok then
        return
      end
      local final_row = row + (#lines - 1)
      local final_col
      if #lines == 1 then
        final_col = col + #lines[1]
      else
        final_col = #lines[#lines]
      end
      vim.api.nvim_win_set_cursor(win, { final_row + 1, final_col })
    end

    local function make_items(entries)
      local items = {}
      for _, entry in ipairs(entries) do
        local fields = entry.fields or {}
        local author = fields.author or fields.editor or ""
        local year = fields.year or fields.date or ""
        local title = fields.title or ""

        local search_parts = { entry.key }
        for _, field in ipairs({ "author", "year", "title", "journal", "journaltitle", "editor" }) do
          if fields[field] and fields[field] ~= "" then
            table.insert(search_parts, fields[field])
          end
        end
        local search_text = table.concat(search_parts, " ")

        local preview_label = author
        if year ~= "" then
          preview_label = preview_label ~= "" and (preview_label .. " (" .. year .. ")") or year
        end
        if title ~= "" then
          preview_label = preview_label ~= "" and (preview_label .. " — " .. title) or title
        end
        if preview_label == "" then
          preview_label = entry.key
        end

        items[#items + 1] = {
          key = entry.key,
          type = entry.type,
          fields = fields,
          file = entry.file,
          raw = entry.raw,
          line = entry.line,
          entry = entry,
          order = entry.order or 0,
          text = search_text,
          label = entry.key .. " — " .. preview_label,
          preview = {
            text = entry.raw,
            ft = "bib",
          },
        }
      end
      return items
    end

    local function make_actions(cfg)
      local actions = {}

      actions.confirm = function(picker, item)
        if not item then
          return
        end
        local text = item.key
        if cfg.format and cfg.format ~= "" then
          local ok, formatted = pcall(string.format, cfg.format, item.key)
          if ok and formatted then
            text = formatted
          end
        end
        insert_text(picker, text)
        picker:close()
      end

      actions.insert_entry = function(picker, item)
        if not item then
          return
        end
        insert_text(picker, item.raw)
        picker:close()
      end

      actions.open_entry = function(picker, item)
        if not item then
          return
        end
        local file = item.file
        if not file or file == "" then
          vim.notify("Entry has no source file", vim.log.levels.WARN, { title = "bibtex" })
          return
        end
        local line = item.line or 1
        picker:close()
        vim.schedule(function()
          local ok, buf = pcall(vim.fn.bufadd, file)
          if not ok or not buf or buf <= 0 then
            vim.notify("Could not open " .. file, vim.log.levels.ERROR, { title = "bibtex" })
            return
          end
          pcall(vim.fn.bufload, buf)
          vim.api.nvim_set_current_buf(buf)
          vim.api.nvim_win_set_cursor(0, { line, 0 })
        end)
      end

      actions.pick_field = function(picker, item)
        if not item then
          return
        end
        local Snacks = ensure_snacks({ silent = true })
        if not Snacks then
          return
        end

        local fields = {}
        for name, value in pairs(item.fields or {}) do
          fields[#fields + 1] = {
            field = name,
            value = value,
            text = name .. ": " .. value,
            label = name .. ": " .. value,
          }
        end
        table.sort(fields, function(a, b)
          return a.field < b.field
        end)

        if vim.tbl_isempty(fields) then
          vim.notify("No fields available for " .. (item.key or "entry"), vim.log.levels.INFO, { title = "bibtex" })
          return
        end

        local parent_picker = picker
        Snacks.picker({
          title = "BibTeX fields",
          items = fields,
          format = function(field_item)
            return { { field_item.label or field_item.text } }
          end,
          actions = {
            insert_field = function(field_picker, field_item)
              if not field_item then
                return
              end
              insert_text(parent_picker, field_item.value)
              field_picker:close()
            end,
          },
          win = {
            list = {
              keys = {
                ["<CR>"] = "insert_field",
              },
            },
          },
        })
      end

      return actions
    end

    function M.bibtex(bibtex_opts)
      local Snacks = ensure_snacks()
      if not Snacks then
        return
      end

      bibtex_opts = vim.deepcopy(bibtex_opts or {})
      local cfg = config_resolve(bibtex_opts)
      local entries, errors = load_entries(cfg)

      for _, err in ipairs(errors) do
        vim.notify(err, vim.log.levels.WARN, { title = "bibtex" })
      end

      if vim.tbl_isempty(entries) then
        vim.notify("No BibTeX entries found", vim.log.levels.INFO, { title = "bibtex" })
        return
      end

      local items = make_items(entries)
      local actions = make_actions(cfg)
      local origin_win = vim.api.nvim_get_current_win()

      return Snacks.picker({
        title = "BibTeX",
        prompt = " ",
        items = items,
        format = function(item)
          return { { item.label or item.text } }
        end,
        actions = actions,
        preview = "preview",
        win = {
          list = {
            keys = {
              ["<CR>"] = "confirm",
              ["<C-e>"] = "insert_entry",
              ["<C-f>"] = "pick_field",
              ["<C-g>"] = "open_entry",
            },
          },
        },
        on_show = function(picker)
          if origin_win and vim.api.nvim_win_is_valid(origin_win) then
            picker._bibtex_origin_win = origin_win
          end
        end,
      })
    end

    function M.setup(setup_opts)
      config_setup(setup_opts)

      -- Auto-register with snacks if available
      local ok, Snacks = pcall(require, "snacks")
      if ok and Snacks.picker then
        Snacks.picker.bibtex = M.bibtex
      end

      -- Create user command
      vim.api.nvim_create_user_command("Bibtex", function(cmd_opts)
        local cmd_format = cmd_opts.args ~= "" and { format = cmd_opts.args } or nil
        M.bibtex(cmd_format)
      end, {
        desc = "Open the BibTeX picker",
        nargs = "?",
      })
    end

    -- Setup bibtex when snacks loads
    vim.schedule(function()
      M.setup({
        global_files = {
          "~/Zotero/library.bib", -- Configure your .bib file here
        },
        format = "\\cite{%s}", -- "%s" or "\\cite{%s}" to auto-wrap
      })

      -- Add keybinding
      vim.keymap.set("n", "<leader>fb", "<cmd>Bibtex<cr>", { desc = "Find BibTeX citation" })
    end)

    return opts
  end,
}
