# ai-opener.yazi

Open AI coding tools (Claude, Codex, Amp, Gemini, etc.) in a new terminal tab
from Yazi, with the working directory set to the current cursor position.

## Supported Terminals

- **kitty** — via remote control socket (`kitty @`, requires `listen_on`)
- **WezTerm** — via `wezterm cli` (untested)
- **tmux** — via `tmux new-window`
- **Ghostty** — via AppleScript (macOS, 1.3.0+)
- **iTerm2** — via AppleScript (macOS, untested)

Terminal is auto-detected. On macOS, the frontmost application is checked.
For tmux, the plugin probes the `tmux` command. For kitty, the plugin searches
for a live kitty socket.

## Installation

```sh
ya pkg add stellarjmr/ai-opener
```

## Usage

Add keybindings to `~/.config/yazi/keymap.toml`:

```toml
[[mgr.prepend_keymap]]
on   = "A"
run  = "plugin ai-opener claude"
desc = "Open AI CLI in new tab"

[[mgr.prepend_keymap]]
on   = ["a", "c"]
run  = "plugin ai-opener claude"
desc = "Open Claude Code in new tab"

[[mgr.prepend_keymap]]
on   = ["a", "x"]
run  = "plugin ai-opener codex"
desc = "Open Codex CLI in new tab"

[[mgr.prepend_keymap]]
on   = ["a", "a"]
run  = "plugin ai-opener amp"
desc = "Open Amp in new tab"

[[mgr.prepend_keymap]]
on   = ["a", "g"]
run  = "plugin ai-opener gemini"
desc = "Open Gemini CLI in new tab"
```

## Configuration

Optionally configure the plugin in `~/.config/yazi/init.lua`:

```lua
require("ai-opener"):setup({
    -- Default tool when no argument is provided
    default_tool = "claude",

    -- Override auto-detected terminal
    -- terminal = "kitty",

    -- Custom kitty socket path (default: unix:/tmp/mykitty)
    -- kitty_listen_on = "unix:/tmp/mykitty",

    -- Add custom tools or override built-in ones
    -- tools = {
    --     mycli = { cmd = "my-custom-ai --flag" },
    -- },
})
```

### Built-in Tools

| Name     | Command  |
|----------|----------|
| `claude` | `claude` |
| `codex`  | `codex`  |
| `amp`    | `amp`    |
| `gemini` | `gemini` |
| `aider`  | `aider`  |

## How It Works

1. Resolves the working directory from the hovered item (directory → use it;
   file → use its parent directory)
2. Detects the terminal emulator automatically
3. Opens a new tab in that terminal with the AI tool running in the resolved
   directory
4. The tab closes automatically when the AI tool exits

## Terminal-Specific Notes

- **kitty** requires `allow_remote_control yes` and `listen_on` in `kitty.conf`:
  ```
  allow_remote_control yes
  listen_on unix:/tmp/mykitty
  ```
- **Ghostty** requires version 1.3.0+ for AppleScript tab creation support.
- **tmux** works inside any terminal emulator.
