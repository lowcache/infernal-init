import std/os, std/strutils, std/parsecfg

type
  Palette* = ref object
    title*: string
    name*: string
    handle*: string
    info*: string
    bg*: string
    reset*: string

  ConfigDisplay* = object
    mode*: string
    theme*: string
    animate*: bool
    demo*: bool

  ConfigIdentity* = object
    handle*: string
    tagline*: string
    user*: string
    wordmark*: string

  ConfigMetadata* = object
    show_os*: bool
    show_git*: bool
    show_battery*: bool

  Config* = ref object
    display*: ConfigDisplay
    identity*: ConfigIdentity
    metadata*: ConfigMetadata
    palette*: Palette

let
  themeChipGreen = Palette(title: "\x1b[38;2;170;215;30m", name: "\x1b[38;2;200;205;200m", handle: "\x1b[38;2;205;185;100m", info: "\x1b[38;2;150;170;150m", bg: "", reset: "\x1b[0m")
  themeMono = Palette(title: "", name: "", handle: "", info: "", bg: "", reset: "")
  # synthwave: pick 4 sane TrueColor values
  themeSynthwave = Palette(title: "\x1b[38;2;255;105;180m", name: "\x1b[38;2;0;255;255m", handle: "\x1b[38;2;255;215;0m", info: "\x1b[38;2;155;89;182m", bg: "", reset: "\x1b[0m")

proc getThemePalette*(themeName: string): Palette =
  case themeName
  of "mono": themeMono
  of "synthwave": themeSynthwave
  else: themeChipGreen

proc initDefaultConfig*(): Config =
  result = Config(
    display: ConfigDisplay(mode: "auto", theme: "chip-green", animate: false, demo: false),
    identity: ConfigIdentity(handle: "@lowcache", tagline: "LowCache, High Throughput", user: "", wordmark: "LowCache"),
    metadata: ConfigMetadata(show_os: true, show_git: false, show_battery: false),
    palette: themeChipGreen
  )

proc parseBoolStr(s: string, default: bool): bool =
  let clean = s.strip(chars = {'"'})
  if clean.toLowerAscii() == "true": return true
  if clean.toLowerAscii() == "false": return false
  return default

proc cleanVal(s: string): string =
  result = s.strip(chars = {'"'})

proc loadConfigFile*(cfg: Config, path: string) =
  if not fileExists(path): return
  var dict: parsecfg.Config
  try:
    dict = loadConfig(path)
  except:
    stderr.writeLine("volinit: malformed config file " & path)
    return

  let displaySec = dict.getSectionValue("display", "mode")
  if displaySec != "": cfg.display.mode = cleanVal(displaySec)
  let displayTheme = dict.getSectionValue("display", "theme")
  if displayTheme != "": cfg.display.theme = cleanVal(displayTheme)
  let displayAnimate = dict.getSectionValue("display", "animate")
  if displayAnimate != "": cfg.display.animate = parseBoolStr(displayAnimate, cfg.display.animate)
  let displayDemo = dict.getSectionValue("display", "demo")
  if displayDemo != "": cfg.display.demo = parseBoolStr(displayDemo, cfg.display.demo)

  let idHandle = dict.getSectionValue("identity", "handle")
  if idHandle != "": cfg.identity.handle = cleanVal(idHandle)
  let idTagline = dict.getSectionValue("identity", "tagline")
  if idTagline != "": cfg.identity.tagline = cleanVal(idTagline)
  let idUser = dict.getSectionValue("identity", "user")
  if idUser != "": cfg.identity.user = cleanVal(idUser)
  let idWordmark = dict.getSectionValue("identity", "wordmark")
  if idWordmark != "": cfg.identity.wordmark = cleanVal(idWordmark)

  let metaOs = dict.getSectionValue("metadata", "show_os")
  if metaOs != "": cfg.metadata.show_os = parseBoolStr(metaOs, cfg.metadata.show_os)
  let metaGit = dict.getSectionValue("metadata", "show_git")
  if metaGit != "": cfg.metadata.show_git = parseBoolStr(metaGit, cfg.metadata.show_git)
  let metaBat = dict.getSectionValue("metadata", "show_battery")
  if metaBat != "": cfg.metadata.show_battery = parseBoolStr(metaBat, cfg.metadata.show_battery)

proc loadEnvVars*(cfg: Config) =
  let envMode = getEnv("VOLINIT_MODE")
  if envMode != "": cfg.display.mode = envMode
  let envTheme = getEnv("VOLINIT_THEME")
  if envTheme != "": cfg.display.theme = envTheme
  let envAnimate = getEnv("VOLINIT_ANIMATE")
  if envAnimate != "": cfg.display.animate = parseBoolStr(envAnimate, cfg.display.animate)
