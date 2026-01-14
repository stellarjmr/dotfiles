return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  config = function()
    local open_cmd = [[open -a "Zen" "%s"; osascript -e 'tell application "kitty" to activate']]

    require("typst-preview").setup({
      open_cmd = open_cmd,
      port = 60188,
      -- Avoid auto-downloading bundled binaries; use ones from PATH instead.
      dependencies_bin = {
        ["tinymist"] = "tinymist",
        ["websocat"] = "websocat",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "typst",
      callback = function(ev)
        vim.keymap.set("n", "<leader>tp", "<cmd>TypstPreview<cr>", {
          buffer = ev.buf,
          desc = "Typst preview",
        })
      end,
    })
  end,
}
