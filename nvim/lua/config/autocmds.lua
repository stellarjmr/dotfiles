-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "txt" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Disable automatic formatting options for all file types
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

-- Automatically returns to the dashboard when the buffer is empty
vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("bufdelpost_autocmd", {}),
  desc = "BufDeletePost User autocmd",
  callback = function()
    vim.schedule(function()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "BufDeletePost",
      })
    end)
  end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "BufDeletePost",
  group = vim.api.nvim_create_augroup("dashboard_delete_buffers", {}),
  desc = "Open Dashboard when no available buffers",
  callback = function(ev)
    local deleted_name = vim.api.nvim_buf_get_name(ev.buf)
    local deleted_ft = vim.api.nvim_get_option_value("filetype", { buf = ev.buf })
    local deleted_bt = vim.api.nvim_get_option_value("buftype", { buf = ev.buf })
    local dashboard_on_empty = deleted_name == "" and deleted_ft == "" and deleted_bt == ""

    if dashboard_on_empty then
      vim.cmd(":lua Snacks.dashboard()")
    end
  end,
})
