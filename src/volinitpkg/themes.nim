import std/os, std/strutils, std/parsecfg
import config, layout, ansi

type
  ThemePack* = ref object
    name*: string
    description*: string
    palette*: Palette
    heroArt*: string
    compactArt*: string
    monogramArt*: string
    isBuiltin*: bool

proc getBuiltinThemes*(defaultBanner: string): seq[ThemePack] =
  let greenTheme = ThemePack(
    name: "chip-green",
    description: "Default PCB green / grey theme",
    palette: getThemePalette("chip-green"),
    heroArt: defaultBanner,
    compactArt: defaultBanner,
    monogramArt: defaultBanner,
    isBuiltin: true
  )
  let monoTheme = ThemePack(
    name: "mono",
    description: "Monochrome, no ANSI colors",
    palette: getThemePalette("mono"),
    heroArt: defaultBanner,
    compactArt: defaultBanner,
    monogramArt: defaultBanner,
    isBuiltin: true
  )
  let synthwaveTheme = ThemePack(
    name: "synthwave",
    description: "Neon grid, retrowave palette",
    palette: getThemePalette("synthwave"),
    heroArt: defaultBanner,
    compactArt: defaultBanner,
    monogramArt: defaultBanner,
    isBuiltin: true
  )
  return @[greenTheme, monoTheme, synthwaveTheme]

proc loadPaletteFromConfig*(path: string): Palette =
  var dict: parsecfg.Config
  result = Palette(title: "", name: "", handle: "", info: "", bg: "", reset: "\x1b[0m")
  if not fileExists(path): return result
  try:
    dict = loadConfig(path)
  except:
    return result

  let title = dict.getSectionValue("colors", "title")
  if title != "": result.title = title.strip(chars={'"'})
  let name = dict.getSectionValue("colors", "name")
  if name != "": result.name = name.strip(chars={'"'})
  let handle = dict.getSectionValue("colors", "handle")
  if handle != "": result.handle = handle.strip(chars={'"'})
  let info = dict.getSectionValue("colors", "info")
  if info != "": result.info = info.strip(chars={'"'})
  let bg = dict.getSectionValue("colors", "bg")
  if bg != "": result.bg = bg.strip(chars={'"'})
  return result

proc isSafeArt*(art: string): bool =
  for c in art:
    if c.ord < 32 and c != '\n' and c != '\x1b':
      return false
  return true

proc loadUserTheme*(themesDir, name: string, defaultBanner: string): ThemePack =
  let themeDir = themesDir / name
  if not dirExists(themeDir): return nil
  
  let packPath = themeDir / "pack.toml"
  if not fileExists(packPath): return nil
  
  var dict: parsecfg.Config
  try:
    dict = loadConfig(packPath)
  except:
    stderr.writeLine("volinit: malformed pack.toml in theme " & name)
    return nil
  
  let tName = dict.getSectionValue("theme", "name").strip(chars={'"'})
  let tDesc = dict.getSectionValue("theme", "description").strip(chars={'"'})
  
  let palettePath = themeDir / "palette.toml"
  let palette = if fileExists(palettePath): loadPaletteFromConfig(palettePath) else: getThemePalette("chip-green")
  
  var heroArt = defaultBanner
  var compactArt = defaultBanner
  var monogramArt = defaultBanner
  
  let artDir = themeDir / "art"
  if dirExists(artDir):
    if fileExists(artDir / "hero.txt"):
      let c = readFile(artDir / "hero.txt")
      if isSafeArt(c): heroArt = c
      else: stderr.writeLine("volinit: unsafe characters in hero.txt of theme " & name)
    if fileExists(artDir / "compact.txt"):
      let c = readFile(artDir / "compact.txt")
      if isSafeArt(c): compactArt = c
      else: stderr.writeLine("volinit: unsafe characters in compact.txt of theme " & name)
    if fileExists(artDir / "monogram.txt"):
      let c = readFile(artDir / "monogram.txt")
      if isSafeArt(c): monogramArt = c
      else: stderr.writeLine("volinit: unsafe characters in monogram.txt of theme " & name)

  return ThemePack(
    name: if tName != "": tName else: name,
    description: tDesc,
    palette: palette,
    heroArt: heroArt,
    compactArt: compactArt,
    monogramArt: monogramArt,
    isBuiltin: false
  )

proc getAllThemes*(defaultBanner: string): seq[ThemePack] =
  var themes: seq[ThemePack] = @[]
  
  let configHome = getEnv("XDG_CONFIG_HOME", getHomeDir() / ".config")
  let themesDir = configHome / "volinit" / "themes"
  
  if dirExists(themesDir):
    for kind, path in walkDir(themesDir):
      if kind == pcDir:
        let tName = path.extractFilename()
        let tp = loadUserTheme(themesDir, tName, defaultBanner)
        if tp != nil: themes.add(tp)
        
  for bt in getBuiltinThemes(defaultBanner):
    themes.add(bt)
    
  return themes

proc getTheme*(name: string, defaultBanner: string): ThemePack =
  let configHome = getEnv("XDG_CONFIG_HOME", getHomeDir() / ".config")
  let themesDir = configHome / "volinit" / "themes"
  
  let ut = loadUserTheme(themesDir, name, defaultBanner)
  if ut != nil: return ut
  
  for bt in getBuiltinThemes(defaultBanner):
    if bt.name == name: return bt
    
  return nil
