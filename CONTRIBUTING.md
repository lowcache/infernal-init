# Contributing to volinit

Contributions are welcome! Please ensure any changes conform to the rules in `.memory/decisions.md`.

## Submitting a Theme Pack

We welcome community themes! To submit your theme pack, please follow this process:

1. Create your theme pack under your local `~/.config/volinit/themes/` directory.
2. Validate your theme by running: `volinit --theme <your-theme-name> --demo`. Ensure all layouts render correctly.
3. Export a preview image of your theme: `volinit export --format svg --output themes/<your-theme-name>/preview.svg`. (Note: The repo currently only supports SVG or Ansi exports). 
4. Fork this repository and add your theme to a `themes/<your-theme-name>` directory. (Note: currently built-ins are managed differently, but you can add your theme here).
5. Add an entry to `THEMES.md` with your theme's name, author, description, and link to your preview image.
6. Open a Pull Request!
