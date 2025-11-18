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

## What to Keep
- All user's custom plugins
- All user's custom settings in lua/config/
- All styling and UI preferences
- Snacks.nvim (already in use)

## What to Remove
- LazyVim dependency
- LazyVim custom events (LazyFile → BufReadPost, BufNewFile, BufWritePre, etc.)
- LazyVim opts extension patterns
- lazyvim.json

## Migration Approach
Convert to Kickstart style:
- Keep existing config/ directory structure
- Only change LazyVim-specific patterns to standard Neovim/lazy.nvim patterns
- Preserve all original behavior
