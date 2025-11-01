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
