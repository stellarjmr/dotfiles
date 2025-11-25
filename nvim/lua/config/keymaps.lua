-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

local function tmux_navigate(direction, tmux_flag)
  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. direction)
  if vim.api.nvim_get_current_win() == current_win and vim.env.TMUX then
    vim.fn.system({ "tmux", "select-pane", "-" .. tmux_flag })
  end
end

local nav_keys = {
  { "<M-h>", "h", "L", "Go to left split/pane" },
  { "<M-j>", "j", "D", "Go to lower split/pane" },
  { "<M-k>", "k", "U", "Go to upper split/pane" },
  { "<M-l>", "l", "R", "Go to right split/pane" },
  { "<A-h>", "h", "L", "Go to left split/pane" },
  { "<A-j>", "j", "D", "Go to lower split/pane" },
  { "<A-k>", "k", "U", "Go to upper split/pane" },
  { "<A-l>", "l", "R", "Go to right split/pane" },
}

for _, key in ipairs(nav_keys) do
  map("n", key[1], function()
    tmux_navigate(key[2], key[3])
  end, { silent = true, desc = key[4] })
end

local function tmux_resize(axis, delta)
  if not vim.env.TMUX then
    return
  end

  local amount = math.abs(delta)
  local is_increase = delta > 0
  local function tmux_flag(flag)
    local output = vim.fn.system({ "tmux", "display-message", "-p", flag })
    if vim.v.shell_error ~= 0 then
      return nil
    end
    return vim.trim(output) == "1"
  end

  local direction
  if axis == "width" then
    local at_right = tmux_flag("#{pane_at_right}")
    if at_right == nil then
      return
    end
    if is_increase then
      direction = at_right and "-L" or "-R"
    else
      direction = at_right and "-R" or "-L"
    end
  else
    local at_bottom = tmux_flag("#{pane_at_bottom}")
    if at_bottom == nil then
      return
    end
    if is_increase then
      direction = at_bottom and "-U" or "-D"
    else
      direction = at_bottom and "-D" or "-U"
    end
  end

  vim.fn.system({ "tmux", "resize-pane", direction, tostring(amount) })
end

local function resize_split(axis, delta)
  local sign = delta > 0 and "+" or "-"
  local amount = math.abs(delta)

  if axis == "width" then
    local has_vertical_split = vim.fn.winnr("h") ~= 0 or vim.fn.winnr("l") ~= 0
    if has_vertical_split then
      vim.cmd("vertical resize " .. sign .. amount)
      return
    end
  else
    local has_horizontal_split = vim.fn.winnr("j") ~= 0 or vim.fn.winnr("k") ~= 0
    if has_horizontal_split then
      vim.cmd("resize " .. sign .. amount)
      return
    end
  end

  tmux_resize(axis, delta)
end

local resize_keys = {
  { { "<M-->", "<A-->" }, "width", -5, "Shrink split width" },
  { { "<M-=>", "<A-=>" }, "width", 5, "Grow split width" },
  { { "<M-_>", "<A-_>", "<M-S-->", "<A-S-->" }, "height", -1, "Shrink split height" },
  { { "<M-+>", "<A-+>", "<M-S-=>", "<A-S-=>" }, "height", 1, "Grow split height" },
}

for _, entry in ipairs(resize_keys) do
  for _, key in ipairs(entry[1]) do
    map("n", key, function()
      resize_split(entry[2], entry[3])
    end, { silent = true, desc = entry[4] })
  end
end

-- quick "cd" shortcuts; update the list below to your frequently used directories
local cd_targets = {
  "~/Documents/PDRA/NU", -- 1
  "~/Downloads", -- 2
  "~/Desktop", -- 3
  "~/.config", -- 4
  -- add more entries as needed
}

for idx, path in ipairs(cd_targets) do
  map("n", "<leader>cd" .. idx, function()
    local expanded = vim.fn.expand(path)
    if vim.fn.isdirectory(expanded) == 0 then
      vim.notify("Directory not found: " .. expanded, vim.log.levels.ERROR)
      return
    end
    vim.cmd("cd " .. vim.fn.fnameescape(expanded))
    vim.notify("cwd: " .. expanded)
  end, { silent = true, desc = "cd -> " .. path })
end

-- redo
map("n", "<S-r>", "<C-r>", { desc = "Redo", remap = true })
-- copy, paste, and delete
map({ "n", "v", "x" }, "<C-a>", "gg0vG$", { noremap = true, silent = true, desc = "Select all" })
map(
  "i",
  "<C-p>",
  "<C-r><C-p>+",
  { noremap = true, silent = true, desc = "Paste from clipboard from within insert mode" }
)
map({ "n", "v" }, "d", '"_d')
map("n", "#", "^")
map("n", "^", "#")
map("n", "<leader>h", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("help " .. word)
end, { desc = "Help for word under cursor" })

-- replace word under cursor
map("n", "sw", function()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end

  local replace = vim.fn.input("Replace '" .. word .. "' with: ")
  if replace == "" then
    return
  end

  -- Escape special characters properly
  local search = vim.fn.escape(word, "/\\")
  local escaped_replace = vim.fn.escape(replace, "/\\&")

  -- Execute with word boundaries and case-sensitive (I flag)
  vim.cmd(string.format("%%s/\\<%s\\>/%s/gI", search, escaped_replace))
end, { desc = "Replace word under cursor globally" })
-- Search and replace word
map("n", "sa", function()
  local input = vim.fn.input("Search and replace: ")
  if input == "" then
    return
  end

  -- Split on first space only (so replacement can contain spaces)
  local search, replace = input:match("^(%S+)%s+(.*)$")
  if not search or not replace then
    vim.notify("Usage: search_term replacement_term", vim.log.levels.WARN)
    return
  end

  -- Escape special characters properly
  -- For very magic mode, we need to escape special regex chars in search
  search = vim.fn.escape(search, "/\\")
  replace = vim.fn.escape(replace, "/\\&")

  -- Execute with word boundaries (\< \>) and case-sensitive (I flag)
  -- Use \< \> for word boundaries (they work without \v)
  vim.cmd(string.format("%%s/\\<%s\\>/%s/gI", search, replace))
end, { desc = "Search and replace globally (whole word)" })
