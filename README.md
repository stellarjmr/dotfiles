
# dotfiles for main configurations

## ghostty
![Image](./sample_img/ui.png)
## hammerspoon

```bash
defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"
```

### Config Management
- `cmd + ctrl + h` - Reload Hammerspoon config

### Window Movement
- `cmd + ctrl + left/right/up/down` - Move window in direction (40px horizontal, 20px vertical)

### Window Positioning
- `ctrl + alt + c` - Center window on screen

### Window Resizing
- `ctrl + alt + =` - Enlarge window (grow from center)
- `ctrl + alt + -` - Shrink window (shrink to center)
- `alt + shift + left` - Resize window left edge
- `alt + shift + right` - Resize window right edge
- `alt + shift + up` - Resize window top edge
- `alt + shift + down` - Resize window bottom edge

### Application Launching
- `alt + return` - Open/focus Ghostty terminal
- `alt + shift + return` - Open/focus Zen browser
- `cmd + ctrl + return` - Open/focus VS Code
- `ctrl + F` - Toggle Finder

### Open Selected File in Finder
- `cmd + shift + z` - Open selected file in Zed
- `cmd + shift + x` - Open selected file in Ovito
- `cmd + shift + v` - Open selected file in VESTA
- `cmd + shift + c` - Open selected file in VS Code

### Debug
- `cmd + alt + ctrl + S` - Show frontmost app name
