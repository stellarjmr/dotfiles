# Task Requirements - Nvim Configuration Migration

## User's Request
Convert Neovim configuration from LazyVim to Kickstart format.

## Critical Rules
1. **NEVER alter original settings** - preserve all existing functionality
2. **DON'T add plugins** that weren't in the original config
3. **DON'T remove plugins** that were in the original config
4. **Remove ALL LazyVim dependencies**, not just the main import:
   - Remove LazyVim-specific events like `LazyFile`
   - Remove LazyVim-specific option extensions (opts functions that extend LazyVim defaults)
   - Remove LazyVim plugin references

## Important: LazyVim Default Plugins
LazyVim automatically loads many default plugins via the `import = "lazyvim.plugins"` line.
When removing LazyVim, these default plugins MUST be restored as explicit plugin files:

### LazyVim Defaults That Were Restored:
- bufferline.nvim (fancy buffer tabs)
- gitsigns.nvim (git indicators)
- which-key.nvim (keymap help)
- noice.nvim (enhanced UI)
- mini.icons (icon support)
- nui.nvim (UI components)
- mini.pairs (auto-pairs)
- mini.ai (enhanced text objects)
- ts-comments.nvim (better comments)

## What to Keep
- All user's custom plugins
- All user's custom settings in lua/config/
- All styling and UI preferences
- Snacks.nvim (already in use)
- ALL LazyVim default plugins (see list above)

## What to Remove
- LazyVim dependency from lua/config/lazy.lua
- LazyVim custom events (LazyFile → BufReadPost, BufNewFile, BufWritePre, etc.)
- LazyVim opts extension patterns (optional = true, etc.)
- LazyVim config blocks in plugin files
- lazyvim.json

## Migration Approach
Convert to Kickstart style:
- Keep existing config/ directory structure
- Only change LazyVim-specific patterns to standard Neovim/lazy.nvim patterns
- Restore LazyVim default plugins as explicit files
- Preserve all original behavior
