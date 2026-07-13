# volinit Themes

volinit ships with built-in themes and supports user-provided theme packs.

## Built-in Themes

- **chip-green** (default) - PCB green and grey aesthetic
- **synthwave** - Neon grid, retrowave palette
- **mono** - Monochrome, no ANSI colors

## Installing a Theme

Theme packs are simply directories containing a `pack.toml`, `palette.toml`, and an `art/` folder.
To install a theme, place its folder into `~/.config/volinit/themes/`.

```
~/.config/volinit/themes/my-theme/
  pack.toml
  palette.toml
  art/
    hero.txt
    compact.txt
    monogram.txt
```

To run with your new theme:
`volinit --theme my-theme`

## Community Themes

(To submit a theme, see [CONTRIBUTING.md](CONTRIBUTING.md))

*None yet! Be the first to contribute one.*
