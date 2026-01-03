# image-fit.yazi

Scale images to fit the preview pane by rendering a resized copy and showing it
in Yazi.

## Requirements

- macOS (uses `/usr/bin/sips`)
- Yazi 25.12.29 or newer

## Installation

```sh
ya pkg add stellarjmr/image-fit.yazi
```

## Usage

Add this to `yazi.toml`:

```toml
[plugin]
prepend_previewers = [
  { mime = "image/*", run = "image-fit" },
]
```

## Notes

- The plugin falls back to Yazi's built-in image renderer if `sips` fails.
- This plugin keeps the original aspect ratio. If you want stretch or crop
  behavior, adjust the plugin implementation.
