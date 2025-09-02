return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "text" },
  dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    callout = {
      abstract = {
        raw = "[!ABSTRACT]",
        rendered = "󰯂 Abstract",
        highlight = "RenderMarkdownInfo",
        category = "obsidian",
      },
      summary = {
        raw = "[!SUMMARY]",
        rendered = "󰯂 Summary",
        highlight = "RenderMarkdownInfo",
        category = "obsidian",
      },
      tldr = { raw = "[!TLDR]", rendered = "󰦩 Tldr", highlight = "RenderMarkdownInfo", category = "obsidian" },
      failure = {
        raw = "[!FAILURE]",
        rendered = " Failure",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      fail = { raw = "[!FAIL]", rendered = " Fail", highlight = "RenderMarkdownError", category = "obsidian" },
      missing = {
        raw = "[!MISSING]",
        rendered = " Missing",
        highlight = "RenderMarkdownError",
        category = "obsidian",
      },
      attention = {
        raw = "[!ATTENTION]",
        rendered = " Attention",
        highlight = "RenderMarkdownWarn",
        category = "obsidian",
      },
      warning = { raw = "[!WARNING]", rendered = " Warning", highlight = "RenderMarkdownWarn", category = "github" },
      danger = { raw = "[!DANGER]", rendered = " Danger", highlight = "RenderMarkdownError", category = "obsidian" },
      error = { raw = "[!ERROR]", rendered = " Error", highlight = "RenderMarkdownError", category = "obsidian" },
      bug = { raw = "[!BUG]", rendered = " Bug", highlight = "RenderMarkdownError", category = "obsidian" },
      quote = { raw = "[!QUOTE]", rendered = " Quote", highlight = "RenderMarkdownQuote", category = "obsidian" },
      cite = { raw = "[!CITE]", rendered = " Cite", highlight = "RenderMarkdownQuote", category = "obsidian" },
      todo = { raw = "[!TODO]", rendered = " Todo", highlight = "RenderMarkdownInfo", category = "obsidian" },
      wip = { raw = "[!WIP]", rendered = "󰦖 WIP", highlight = "RenderMarkdownHint", category = "obsidian" },
      done = { raw = "[!DONE]", rendered = " Done", highlight = "RenderMarkdownSuccess", category = "obsidian" },
    },
    sign = { enabled = true },
    code = {
      width = "block",
      min_width = 80,
      border = "thin",
      left_pad = 1,
      right_pad = 1,
      position = "right",
      language_icon = true,
      language_name = true,
      highlight_inline = "RenderMarkdownCodeInfo",
    },
    heading = {
      icons = { " 󰼏 ", " 󰎨 ", " 󰼑 ", " 󰎲 ", " 󰼓 ", " 󰎴 " },
      border = true,
      render_modes = true,
    },
    checkbox = {
      unchecked = { icon = "󰄱" },
      checked = { icon = "󰄵" },
    },
    pipe_table = {
      alignment_indicator = "─",
      border = { "╭", "┬", "╮", "├", "┼", "┤", "╰", "┴", "╯", "│", "─" },
    },
    link = {
      wiki = { icon = " ", highlight = "RenderMarkdownWikiLink", scope_highlight = "RenderMarkdownWikiLink" },
      image = " ",
      custom = {
        github = { pattern = "github", icon = " " },
        youtube = { pattern = "youtube", icon = " " },
      },
      hyperlink = " ",
    },
    anti_conceal = {
      disabled_modes = { "n" },
      ignore = {
        bullet = true,
        head_border = true,
        head_background = true,
      },
    },
    win_options = { concealcursor = { rendered = "nvc" } },
    completions = {
      blink = { enabled = true },
      lsp = { enabled = true },
    },
  },
}
