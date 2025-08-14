# Window management with Hammerspoon

## Installation

### With Homebrew
```bash
brew install hammerspoon --cask
```

### Hammerspoon official website
[url](https://www.hammerspoon.org/)

## Git clone the repository to your prefer config directory

### If you want use XDG_CONFIG_HOME environment variable
```bash
cd ~/.config
git clone https://github.com/chenzhiminlr/MW-spoons.git hammerspoon

defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"
```

## Shortcut keys

```
ctrl + cmd + H - reload Hammerspoon config
ctrl + alt + up/down/left/right - move window to the left/right/up/down half of the screen
alt + shift + up/down/left/right - resize window when already in the left/right/up/down half of the screen
ctrl + alt + minus - shrink window
ctrl + alt + equal - expand window
cmd + ctrl + up/down/left/right - move window to direction
```
