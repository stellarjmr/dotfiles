-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.diagnostic.enable(false)

-- Disable auto-formatting on save (LazyVim's format system)
vim.g.autoformat = false

-- Add personal notes directory so gf/:find can jump there quickly
local notes_dir = vim.fn.expand("~/Documents/Notes")

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("custom_path", { clear = true }),
  callback = function()
    local path = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    if not path then
      return
    end
    -- build a project-specific path list
    local new_path = table.concat({
      ".", -- current buffer dir
      path .. "/**", -- recurse inside the project
      vim.loop.cwd() .. "/**", -- fallback to current working dir
      vim.fn.isdirectory(notes_dir) == 1 and notes_dir .. "/**" or nil,
    }, ",")
    vim.opt_local.path = new_path
  end,
})
