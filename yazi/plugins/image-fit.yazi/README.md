# image-fit

Scale images to fit the preview pane by rendering a resized copy and showing it
in Yazi.

## Requirements

- macOS (uses `/usr/bin/sips`)
- Yazi 25.12.29 or newer

## Installation

```sh
ya pkg add stellarjmr/image-fit
```

`ya` requires package names to be kebab-case, so the repo name must be
`image-fit` (not `image-fit.yazi`).

## Usage

Add this to `yazi.toml`:

```toml
[plugin]
prepend_previewers = [
  { mime = "image/*", run = "image-fit" },
]
```

To let this plugin fit images to the full preview area, add:

```toml
[preview]
# Let images use the full preview area by removing caps.
max_width = 9999
max_height = 9999
```

## Notes

- The plugin falls back to Yazi's built-in image renderer if `sips` fails.
- This plugin keeps the original aspect ratio. If you want stretch or crop
  behavior, adjust the plugin implementation.
