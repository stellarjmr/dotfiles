return {
  "folke/sidekick.nvim",
  enabled = true,
  opts = {
    nes = { enabled = false },
    cli = {
      mux = {
        enabled = true,
        backend = "tmux",
      },
      win = {
        layout = "right", ---@type "float"|"left"|"bottom"|"top"|"right"
        split = {
          width = 44,
          height = 10,
        },
      },
    },
    tools = {
      claude = { cmd = { "claude" } },
      codex = { cmd = { "codex", "--enable", "web_search_request" } },
      gemini = { cmd = { "gemini" } },
    },
  },
  keys = {
    {
      "<Esc>",
      "<C-\\><C-n>",
      mode = "t",
      desc = "Exit terminal mode",
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").select({ filter = { installed = true } })
      end,
      desc = "Sidekick Select Tool",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<M-a>",
      function()
        require("sidekick.cli").toggle({ filter = { installed = true } })
      end,
      desc = "Sidekick Toggle CLI",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    -- Example of a keybinding to open Claude directly
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
  },
}
