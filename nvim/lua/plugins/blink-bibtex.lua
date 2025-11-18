-- ============================================================================
-- BibTeX Completion Source for blink.cmp
-- Provides citation completion in .tex files
-- Place this file as: ~/.config/nvim/lua/plugins/blink-bibtex.lua
-- ============================================================================

return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    local uv = vim.uv or vim.loop

    -- ========================================================================
    -- PARSER MODULE (same as before, but simplified)
    -- ========================================================================

    local function read_file(path)
      local fd = uv.fs_open(path, "r", 438)
      if not fd then
        return nil
      end
      local stat = uv.fs_fstat(fd)
      if not stat then
        uv.fs_close(fd)
        return nil
      end
      local data = uv.fs_read(fd, stat.size, 0)
      uv.fs_close(fd)
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
              line = current.line,
            }
            current = nil
            brace_level = 0
          end
        end
      end
      return entries
    end

    -- ========================================================================
    -- CONFIG & FILE LOADING
    -- ========================================================================

    local config = {
      depth = 1,
      files = nil,
      global_files = {
        "~/Zotero/library.bib", -- Configure your .bib file here
      },
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

    local function find_project_files()
      if config.files then
        return vim.deepcopy(config.files)
      end
      local cwd = (vim.uv and vim.uv.cwd()) or vim.loop.cwd()
      local opts_find = { path = cwd, type = "file" }
      if config.depth ~= nil then
        opts_find.depth = config.depth
      end
      local found = vim.fs.find(function(name, _)
        return name:lower():match("%.bib$") ~= nil
      end, opts_find)
      return found
    end

    local function load_entries()
      local files = {}
      local seen = {}
      for _, path in ipairs(find_project_files()) do
        if not seen[path] then
          seen[path] = true
          files[#files + 1] = path
        end
      end

      local normalized_global = normalize_files(config.global_files)
      for _, path in ipairs(normalized_global or {}) do
        if not seen[path] then
          seen[path] = true
          files[#files + 1] = path
        end
      end

      local entries = {}
      for _, path in ipairs(files) do
        local text = read_file(path)
        if text then
          local parsed = parse_entries(text, path)
          for _, entry in ipairs(parsed) do
            entries[#entries + 1] = entry
          end
        end
      end
      return entries
    end

    -- ========================================================================
    -- BLINK.CMP SOURCE
    -- ========================================================================

    local source = {}
    local cache = {}
    local cache_time = 0

    function source:new()
      return setmetatable({}, { __index = source })
    end

    function source:get_trigger_characters()
      return { "{" }
    end

    function source:get_keyword_pattern()
      -- Match citation keys (alphanumeric, hyphens, underscores)
      return [[\w\+]]
    end

    -- Check if we're in a citation context
    function source:is_available()
      -- Only activate in .tex files
      if vim.bo.filetype ~= "tex" then
        return false
      end
      return true
    end

    -- Check if we should trigger completion
    function source:should_show_completion(context)
      if not self:is_available() then
        return false
      end

      -- Get the line up to the cursor
      local line = context.line
      local col = context.cursor[2]
      local before_cursor = line:sub(1, col)

      -- Check if we're inside a citation command
      -- Matches: \cite{, \citep{, \citet{, \autocite{, etc.
      -- Also matches partial: \cite{key1,key2,
      local in_cite = before_cursor:match("\\%w*cite%w*%{[^}]*$")

      return in_cite ~= nil
    end

    function source:get_completions(context, callback)
      if not self:should_show_completion(context) then
        callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
        return
      end

      -- Use cache for 5 seconds
      local now = os.time()
      if cache_time > 0 and (now - cache_time) < 5 and cache.items then
        callback(cache)
        return
      end

      -- Load entries
      local entries = load_entries()
      local items = {}

      for _, entry in ipairs(entries) do
        local fields = entry.fields or {}
        local author = fields.author or fields.editor or ""
        local year = fields.year or fields.date or ""
        local title = fields.title or ""

        -- Truncate for display
        if #author > 40 then
          author = author:sub(1, 37) .. "..."
        end
        if #title > 50 then
          title = title:sub(1, 47) .. "..."
        end

        -- Build documentation (what shows in preview)
        local doc_lines = {}
        table.insert(doc_lines, "**" .. entry.key .. "**")
        table.insert(doc_lines, "")
        if author ~= "" then
          table.insert(doc_lines, "**Author:** " .. author)
        end
        if year ~= "" then
          table.insert(doc_lines, "**Year:** " .. year)
        end
        if title ~= "" then
          table.insert(doc_lines, "**Title:** " .. title)
        end
        if entry.type then
          table.insert(doc_lines, "**Type:** " .. entry.type)
        end
        if entry.file then
          table.insert(doc_lines, "")
          table.insert(doc_lines, "*Source: " .. entry.file .. "*")
        end

        local detail = ""
        if author ~= "" and year ~= "" then
          detail = author .. " (" .. year .. ")"
        elseif author ~= "" then
          detail = author
        elseif year ~= "" then
          detail = year
        end

        table.insert(items, {
          label = entry.key,
          kind = require("blink.cmp.types").CompletionItemKind.Reference,
          detail = detail,
          documentation = {
            kind = "markdown",
            value = table.concat(doc_lines, "\n"),
          },
          insertText = entry.key,
          filterText = entry.key .. " " .. author .. " " .. title .. " " .. year,
          sortText = entry.key,
          data = {
            entry = entry,
          },
        })
      end

      -- Cache the results
      local result = {
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = items,
      }
      cache = result
      cache_time = now

      callback(result)
    end

    function source:resolve(item, callback)
      -- Already have documentation, nothing to resolve
      callback(item)
    end

    -- ========================================================================
    -- REGISTER SOURCE
    -- ========================================================================

    -- Make the source globally available
    package.loaded["blink-bibtex-source"] = source

    -- Register the provider
    opts.sources = opts.sources or {}
    opts.sources.providers = opts.sources.providers or {}
    opts.sources.providers.bibtex = {
      name = "BibTeX",
      module = "blink-bibtex-source",
      enabled = true,
      transform_items = function(_, items)
        -- Sort by relevance (could add frecency here)
        table.sort(items, function(a, b)
          return a.label < b.label
        end)
        return items
      end,
    }

    -- Enable for tex files only
    -- Modify the default sources to include bibtex for tex files
    local original_default = opts.sources.default
    opts.sources.default = function(ctx)
      -- Get the current buffer's filetype
      local bufnr = ctx and ctx.bufnr or vim.api.nvim_get_current_buf()
      local filetype = vim.bo[bufnr].filetype

      if filetype == "tex" then
        return { "lsp", "path", "snippets", "buffer", "bibtex" }
      end

      -- Return original default or standard sources
      if type(original_default) == "function" then
        return original_default(ctx)
      elseif type(original_default) == "table" then
        return original_default
      end
      return { "lsp", "path", "snippets", "buffer" }
    end

    return opts
  end,
}
