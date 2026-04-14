# osc7.yazi

A tiny [Yazi](https://github.com/sxyazi/yazi) plugin that emits the `OSC 7`
escape sequence whenever you change directories inside yazi.

## Why

Some terminals (notably **Ghostty**) track the current working directory
purely through `OSC 7` reports from the shell's integration hooks. While
yazi is running in the foreground, the shell is suspended and never emits
`OSC 7`, so opening a new split/tab from the terminal inherits the
directory where yazi was originally launched — not the directory you are
currently browsing.

Kitty sidesteps this by reading the foreground process's cwd directly from
the OS, but Ghostty does not. This plugin fixes the experience on Ghostty
(and any other OSC 7-aware terminal) by making yazi itself report its cwd.

## Install

With `ya pkg`:

```sh
ya pkg add stellarjmr/osc7
```

Or clone manually into your plugins directory:

```sh
git clone https://github.com/stellarjmr/osc7.yazi.git \
  ~/.config/yazi/plugins/osc7.yazi
```

## Usage

Add to `~/.config/yazi/init.lua`:

```lua
require("osc7"):setup()
```

That's it. Open yazi, navigate around, then create a new terminal split —
it will open in yazi's current directory.


## How it works

The plugin subscribes to yazi's `cd` event and writes

```
ESC ] 7 ; kitty-shell-cwd://<hostname>/<url-encoded-path> BEL
```

directly to `/dev/tty` (yazi owns stdout for its TUI). Ghostty (and kitty)
update their tracked cwd accordingly, so the next split/tab created by the
terminal inherits the directory you are browsing inside yazi.

### Why `kitty-shell-cwd://localhost/…`?

Ghostty validates every OSC 7 URI in its `io_handler` with these rules
(verified against the error strings compiled into the Ghostty binary):

1. Scheme **must** be `file` or `kitty-shell-cwd`.
2. URI **must** contain a hostname.
3. The hostname **must** be local, compared against Ghostty's internal
   `gethostname(3)` result.

Ghostty's own zsh shell integration emits `kitty-shell-cwd://$HOST$PWD`
and relies on `$HOST` matching the machine's kernel hostname. On macOS
that value depends on `scutil` state (HostName / LocalHostName /
ComputerName), which varies from machine to machine — one Mac reports
`Zhimin-Mac-Studio`, another reports `Zhimin-MacBook-Pro.local`, and
`hostname -s` isn't always the same as what Ghostty compares against.
Matching it reliably from a Lua plugin is a portability mess.

Ghostty's OSC 7 validator special-cases the literal string `localhost`
as always-local, so the plugin just writes `kitty-shell-cwd://localhost/…`.
This is scheme-valid, host-valid, and machine-agnostic.

## License

MIT
