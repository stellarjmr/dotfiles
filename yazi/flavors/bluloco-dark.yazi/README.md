# Bluloco Dark - Yazi Flavor

A dark [Yazi](https://github.com/sxyazi/yazi) flavor based on the [Bluloco](https://github.com/uloco/theme-bluloco) color scheme.

## Preview

This flavor brings Bluloco's colorful dark palette to Yazi's file manager interface.

## Installation

### Yazi Package Manager

```sh
ya pkg add stellarjmr/bluloco-dark
```

### Manual Installation

Copy the `bluloco-dark.yazi` directory to:
- Linux/macOS: `~/.config/yazi/flavors/`
- Windows: `%APPDATA%\\yazi\\config\\flavors\\`

## Usage

Add the following to your `~/.config/yazi/theme.toml`:

```toml
[flavor]
dark = "bluloco-dark"
```

Or use it as both your light and dark flavor:

```toml
[flavor]
dark = "bluloco-dark"
light = "bluloco-dark"
```

## Color Palette

This flavor uses the Bluloco dark palette:

- Background: `#282c34`
- Foreground: `#abb2bf`
- Red: `#ff6480`
- Yellow: `#f9c859`
- Green: `#3fc56b`
- Blue: `#10b1fe`
- Purple: `#ff78f8`
- Accent: `#9f7efe`

## Credits

- Bluloco color scheme by [uloco](https://github.com/uloco)
- Yazi file manager by [sxyazi](https://github.com/sxyazi)

## License

MIT License - see [LICENSE](LICENSE) file for details.
