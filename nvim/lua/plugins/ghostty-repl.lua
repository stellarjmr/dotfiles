return {
  "stellarjmr/ghostty-repl.nvim",
  enabled = vim.fn.has("mac") == 1,
  ft = "python",
  opts = {
    python_path = "~/conda/envs/ovito/bin/python",
    split_direction = "right",
    split_size = 30,
    keymaps = {
      send_cell = "<leader>sc",
      send_line = "<leader>sl",
      send_selection = "<leader>ss",
      send_file = "<leader>sf",
      close_repl = "<leader>rq",
    },
  },
}
