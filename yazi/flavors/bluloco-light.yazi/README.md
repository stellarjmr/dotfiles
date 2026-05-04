# Bluloco Light - Yazi Flavor

A light [Yazi](https://github.com/sxyazi/yazi) flavor based on the [Bluloco](https://github.com/uloco/theme-bluloco) color scheme.

## Preview

This flavor brings Bluloco's colorful light palette to Yazi's file manager interface.

## Installation

### Yazi Package Manager

```sh
ya pkg add stellarjmr/bluloco-light
```

### Manual Installation

Copy the `bluloco-light.yazi` directory to:
- Linux/macOS: `~/.config/yazi/flavors/`
- Windows: `%APPDATA%\\yazi\\config\\flavors\\`

## Usage

Add the following to your `~/.config/yazi/theme.toml`:

```toml
[flavor]
light = "bluloco-light"
```

Or use it as both your light and dark flavor:

```toml
[flavor]
dark = "bluloco-light"
light = "bluloco-light"
```

## Color Palette

This flavor uses the Bluloco light palette:

- Background: `#e5e5e5`
- Foreground: `#3b3f4c`
- Red: `#b52a1d`
- Yellow: `#aa5d00`
- Green: `#2f8a00`
- Blue: `#1e78c2`
- Purple: `#a626a4`
- Accent: `#9a6700`

## Credits

- Bluloco color scheme by [uloco](https://github.com/uloco)
- Yazi file manager by [sxyazi](https://github.com/sxyazi)

## License

MIT License - see [LICENSE](LICENSE) file for details.
