return {
  "zbirenbaum/copilot.lua",
  opts = {
    disable_limit_reached_message = true,
    filetypes = {
      ["*"] = false, -- disable for all other filetypes and ignore default `filetypes`
      python = true,
      lua = true,
      markdown = true,
    },
  },
}
