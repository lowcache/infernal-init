import std/os, std/strutils, std/terminal
import volinitpkg/ansi, volinitpkg/probes, volinitpkg/config, volinitpkg/layout

const
  bannerWide = staticRead("../assets/lowcacheascii")
  titleArt = [
    r"██╗      ██████╗ ██╗    ██╗ ██████╗ █████╗  ██████╗██╗  ██╗███████╗",
    r"██║     ██╔═══██╗██║    ██║██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝",
    r"██║     ██║   ██║██║ █╗ ██║██║     ███████║██║     ███████║█████╗  ",
    r"██║     ██║   ██║██║███╗██║██║     ██╔══██║██║     ██╔══██║██╔══╝  ",
    r"███████╗╚██████╔╝╚███╔███╔╝╚██████╗██║  ██║╚██████╗██║  ██║███████╗",
    r"╚══════╝ ╚═════╝  ╚══╝╚══╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝"
  ]

proc printHelp() =
  stdout.writeLine "Usage: volinit [options]"
  stdout.writeLine "Options:"
  stdout.writeLine "  --mode=MODE      Set layout mode (auto, split-panel, hero, compact, monogram)"
  stdout.writeLine "  --theme=THEME    Set theme (chip-green, mono, synthwave)"
  stdout.writeLine "  --animate        Enable scanline reveal animation"
  stdout.writeLine "  --demo           Render all modes and themes"
  stdout.writeLine "  --version        Print version"
  stdout.writeLine "  --help           Print help"
  quit(0)

proc printVersion() =
  stdout.writeLine "volinit 0.2.0"
  quit(0)

proc parseCliArgs*(cfg: Config) =
  for p in commandLineParams():
    if p.startsWith("--mode="): cfg.display.mode = p[7..^1]
    elif p.startsWith("--theme="): cfg.display.theme = p[8..^1]
    elif p == "--animate": cfg.display.animate = true
    elif p == "--demo": cfg.display.demo = true
    elif p == "--version": printVersion()
    elif p == "--help": printHelp()

proc main() =
  let cfg = initDefaultConfig()
  
  loadConfigFile(cfg, "/etc/volinit/config.toml")
  
  let configHome = getEnv("XDG_CONFIG_HOME", getHomeDir() / ".config")
  loadConfigFile(cfg, configHome / "volinit" / "config.toml")
  
  loadEnvVars(cfg)
  parseCliArgs(cfg)

  var isPipe = not isatty(stdout)
  let termWidth = getTerminalWidth()
  let termHeight = getTerminalHeight()

  var animate = cfg.display.animate
  if isPipe or getEnv("TMUX", "") != "" or getEnv("TERM", "").startsWith("screen"):
    animate = false

  var cells: seq[Cell] = @[]
  
  var user = cfg.identity.user
  if user == "": user = getUser()
  
  cfg.palette = getThemePalette(cfg.display.theme)

  if isPipe:
    cells.add(Cell(content: "user: " & user))
    cells.add(Cell(content: "handle: " & cfg.identity.handle))
    if cfg.metadata.show_os:
      cells.add(Cell(content: "os: " & getOS()))
    cells.add(Cell(content: "tagline: " & cfg.identity.tagline))
    if cfg.metadata.show_git:
      let git = getGit()
      if git != "": cells.add(Cell(content: "git: " & git))
    if cfg.metadata.show_battery:
      let bat = getBattery()
      if bat != "": cells.add(Cell(content: "battery: " & bat))
  else:
    cells.add(Cell(content: cfg.palette.name & user & cfg.palette.reset & " " & cfg.palette.handle & cfg.identity.handle & cfg.palette.reset))
    if cfg.metadata.show_os:
      cells.add(Cell(content: cfg.palette.info & getOS() & cfg.palette.reset))
    cells.add(Cell(content: cfg.palette.info & cfg.identity.tagline & cfg.palette.reset))
    
    if cfg.metadata.show_git:
      let git = getGit()
      if git != "":
        cells.add(Cell(content: cfg.palette.info & git & cfg.palette.reset))
    if cfg.metadata.show_battery:
      let bat = getBattery()
      if bat != "":
        cells.add(Cell(content: cfg.palette.info & bat & cfg.palette.reset))

  if cfg.display.demo:
    isPipe = false
    animate = false
    let modes = ["split-panel", "hero", "compact", "monogram"]
    let themes = ["chip-green", "mono", "synthwave"]
    let osLine = getOS()
    for theme in themes:
      for mode in modes:
        cfg.palette = getThemePalette(theme)
        # rebuild cells per theme; demo always renders in tty (non-pipe) format
        var demoCells: seq[Cell] = @[]
        demoCells.add(Cell(content: cfg.palette.name & user & cfg.palette.reset & " " & cfg.palette.handle & cfg.identity.handle & cfg.palette.reset))
        if cfg.metadata.show_os:
          demoCells.add(Cell(content: cfg.palette.info & osLine & cfg.palette.reset))
        demoCells.add(Cell(content: cfg.palette.info & cfg.identity.tagline & cfg.palette.reset))

        stdout.writeLine("--- DEMO: Mode=" & mode & " Theme=" & theme & " ---")
        var plan = RenderPlan(
          banner: bannerWide,
          titleBlock: @titleArt,
          cells: demoCells,
          palette: cfg.palette,
          mode: mode,
          width: termWidth,
          height: termHeight,
          animate: animate,
          demo: true,
          isPipe: isPipe
        )
        renderPlan(plan)
        stdout.writeLine("")
    return

  var plan = RenderPlan(
    banner: bannerWide,
    titleBlock: @titleArt,
    cells: cells,
    palette: cfg.palette,
    mode: cfg.display.mode,
    width: termWidth,
    height: termHeight,
    animate: animate,
    demo: cfg.display.demo,
    isPipe: isPipe
  )

  renderPlan(plan)

when isMainModule:
  main()
