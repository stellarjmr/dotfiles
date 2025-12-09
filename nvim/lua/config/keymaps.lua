-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- alt+w to close buffer, alt+q to quit
map("n", "<A-w>", ":bd<CR>", { noremap = true, silent = true })
map("n", "<A-q>", ":q<CR>", { noremap = true, silent = true })

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
-- use kitty clipboard integration if available
-- map({ "n", "v", "x" }, "<C-a>", "gg0vG$", { noremap = true, silent = true, desc = "Select all" })
-- map(
--   "i",
--   "<C-p>",
--   "<C-r><C-p>+",
--   { noremap = true, silent = true, desc = "Paste from clipboard from within insert mode" }
-- )
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

-- Go to buffer index
local function goto_buffer_by_index(idx)
  if vim.fn.exists(":BufferLineGoToBuffer") > 0 then
    vim.cmd("BufferLineGoToBuffer " .. idx)
    return
  end

  local bufs = vim.t.bufs or vim.api.nvim_list_bufs()
  local listed = {}
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      listed[#listed + 1] = buf
    end
  end

  local target = listed[idx]
  if target then
    vim.cmd("buffer " .. target)
  else
    vim.notify("No buffer at position " .. idx, vim.log.levels.WARN)
  end
end

for i = 1, 9 do
  local desc = "Go to buffer " .. i
  for _, prefix in ipairs({ "<A-", "<M-" }) do
    local key = prefix .. i .. ">"
    map("n", key, function()
      goto_buffer_by_index(i)
    end, { silent = true, desc = desc })
  end
end
