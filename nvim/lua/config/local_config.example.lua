-- Local configuration template (safe to commit)

-- Todo list section completion
local function todo_section(opts)
  opts = opts or {}
  local todo_file = opts.file or vim.fn.expand("~/todo.md")

  return function()
    local items = {}

    table.insert(items, {
      title = opts.title or "Todo List",
      pane = opts.pane or 2,
      icon = opts.icon or " ",
      indent = -2,
      padding = { 0, 1 },
      enabled = opts.enabled,
    })

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

    local todos = {}
    for line in content:gmatch("[^\r\n]+") do
      local checked, text = line:match("^%s*%- %[([%sx])%]%s*(.+)$")
      if text then
        local is_done = checked:lower() == "x"
        local date = text:match("@(%d%d%d%d%-%d%d%-%d%d)") or text:match("due:(%d%d%d%d%-%d%d%-%d%d)")
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

    for i, todo in ipairs(todos) do
      if i <= (opts.limit or 10) then
        local priority_hl = "Normal"
        if todo.priority == "high" then
          priority_hl = "DiagnosticError"
        elseif todo.priority == "medium" then
          priority_hl = "DiagnosticWarn"
        elseif todo.priority == "low" then
          priority_hl = "DiagnosticInfo"
        end

        local icon = todo.done and "✓ " or "○ "
        local icon_hl = todo.done and "DiagnosticOk" or priority_hl
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

        if todo.date then
          table.insert(text_parts, { " " .. todo.date, hl = "Comment" })
        end

        table.insert(items, {
          text = text_parts,
          key = not todo.done and "t" or nil,
          pane = opts.pane or 2,
          indent = opts.indent or 2,
          enabled = opts.enabled,
          action = function()
            vim.cmd("edit " .. todo_file)
          end,
        })
      end
    end

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

return {
  project_folders = {
    "~/path/to/project-one",
    "~/path/to/project-two",
  },
  cd_targets = {
    "~/path/to/frequent-dir-1",
    "~/path/to/frequent-dir-2",
    "~/path/to/frequent-dir-3",
  },
  todo_section = todo_section,
}
