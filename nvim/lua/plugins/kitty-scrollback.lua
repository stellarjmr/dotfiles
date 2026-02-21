return {
  "mikesmithgh/kitty-scrollback.nvim",
  lazy = true,
  cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth", "KittyScrollbackGenerateCommandLineEditing" },
  event = { "User KittyScrollbackLaunch" },
  config = function()
    require("kitty-scrollback").setup({
      {
        paste_window = {
          yank_register_enabled = false,
        },
      },
    })
  end,
}
