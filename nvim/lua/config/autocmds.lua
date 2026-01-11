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

-- Disable autoformat for python files
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "python" },
  callback = function()
    vim.b.autoformat = false
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

-- Tmux navigation
vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  callback = function()
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then
      dir = vim.fn.getcwd()
    end
    vim.fn.writefile({ dir }, "/tmp/nvim_cwd")
  end,
})

-- Clean up temp file when neovim exits
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    vim.fn.delete("/tmp/nvim_cwd")
  end,
})

-- Function to toggle markdown checkbox
local function toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  local new_line

  if line:match("%- %[ %]") then
    new_line = line:gsub("%- %[ %]", "- [x]", 1)
  elseif line:match("%- %[x%]") or line:match("%- %[X%]") then
    new_line = line:gsub("%- %[[xX]%]", "- [ ]", 1)
  else
    return
  end

  vim.api.nvim_set_current_line(new_line)
end

-- Set up keymap for markdown files only
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.keymap.set("n", "<leader><CR>", toggle_checkbox, { buffer = true, desc = "Toggle checkbox" })
  end,
})

-- Show diagnostics in a floating window on cursor hold
vim.o.updatetime = 500
local aug = vim.api.nvim_create_augroup("DiagFloatOnHold", { clear = true })
vim.api.nvim_create_autocmd("CursorHold", {
  group = aug,
  callback = function()
    vim.diagnostic.open_float(nil, {
      focusable = false,
      scope = "line",
      close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "InsertCharPre", "WinLeave" },
    })
  end,
})

-- Set cursor to bar on exit/suspend to fix terminal cursor issues
-- https://neovim.io/doc/user/faq.html#faq
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  pattern = "*",
  desc = "Restore terminal cursor",
  callback = function()
    -- vim.cmd([[set guicursor=a:ver100-blinkwait1-blinkoff500-blinkon500]])

    -- https://github.com/microsoft/terminal/issues/13420#issuecomment-1501102143
    vim.opt.guicursor = ""
    vim.fn.chansend(vim.v.stderr, "\x1b[ q")
  end,
})

-- Auto-reload buffers when files change on disk
vim.opt.autoread = true
vim.g.autoread_enabled = true

local autoread_group = vim.api.nvim_create_augroup("AutoReadChecktime", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = autoread_group,
  callback = function()
    if vim.g.autoread_enabled then
      vim.cmd("checktime")
    end
  end,
})

vim.keymap.set("n", "<leader>ar", function()
  vim.g.autoread_enabled = not vim.g.autoread_enabled
  vim.opt.autoread = vim.g.autoread_enabled
  local status = vim.g.autoread_enabled and "on" or "off"
  vim.notify("Auto-reload: " .. status)
end, { desc = "Toggle auto-reload" })
