import std/os, std/strutils, std/terminal
import volinitpkg/ansi, volinitpkg/probes, volinitpkg/config, volinitpkg/layout, volinitpkg/themes
import volinitpkg/export_cmd, volinitpkg/generate_cmd

const
  bannerWide = staticRead("../assets/lowcacheascii")
  bannerSmall = staticRead("../assets/lowcacheascii-sm")
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
  stdout.writeLine "  --theme=THEME    Set theme (built-ins or user packs)"
  stdout.writeLine "  --animate        Enable scanline reveal animation"
  stdout.writeLine "  --demo           Render all modes and themes"
  stdout.writeLine "  --list-themes    List all available themes"
  stdout.writeLine "  --version        Print version"
  stdout.writeLine "  --help           Print help"
  stdout.writeLine ""
  stdout.writeLine "Commands:"
  stdout.writeLine "  export --format <ansi|svg> [--output PATH]  Export banner"
  stdout.writeLine "  generate --from-image PATH [--output NAME]  Generate theme pack"
  quit(0)

proc printVersion() =
  stdout.writeLine "volinit 0.3.0"
  quit(0)

proc printThemes() =
  let themes = getAllThemes(bannerWide, bannerSmall)
  for t in themes:
    let prefix = if t.isBuiltin: "(built-in)" else: "(user-pack)"
    stdout.writeLine t.name & " " & prefix & " - " & t.description
  quit(0)

proc loadFullConfig(): Config =
  result = initDefaultConfig()
  loadConfigFile(result, "/etc/volinit/config.toml")
  let configHome = getEnv("XDG_CONFIG_HOME", getHomeDir() / ".config")
  loadConfigFile(result, configHome / "volinit" / "config.toml")
  loadEnvVars(result)

proc identityCells(cfg: Config, user: string): seq[Cell] =
  result.add(Cell(content: cfg.palette.name & user & cfg.palette.reset & " " & cfg.palette.handle & cfg.identity.handle & cfg.palette.reset))
  if cfg.metadata.show_os:
    result.add(Cell(content: cfg.palette.info & getOS() & cfg.palette.reset))
  result.add(Cell(content: cfg.palette.info & cfg.identity.tagline & cfg.palette.reset))

proc main() =
  let args = commandLineParams()
  if args.len > 0 and args[0] == "export":
    var format = "ansi"
    var output = ""
    let cfg = loadFullConfig()
    var i = 1
    while i < args.len:
      if args[i] == "--format" and i + 1 < args.len:
        format = args[i+1]
        i += 2
      elif args[i] == "--output" and i + 1 < args.len:
        output = args[i+1]
        i += 2
      elif args[i].startsWith("--theme="):
        cfg.display.theme = args[i][8..^1]
        i += 1
      else: i += 1

    let tp = getTheme(cfg.display.theme, bannerWide, bannerSmall)
    let themePack = if tp != nil: tp else: getTheme("chip-green", bannerWide, bannerSmall)
    cfg.palette = themePack.palette
    var user = cfg.identity.user
    if user == "": user = getUser()
    let cells = identityCells(cfg, user)

    var plan = RenderPlan(
      banner: themePack.heroArt,
      titleBlock: @titleArt,
      cells: cells,
      palette: cfg.palette,
      mode: "hero",
      width: 120,
      height: 24,
      animate: false,
      demo: false,
      isPipe: false
    )
    handleExport(plan, format, output)
    quit(0)
    
  if args.len > 0 and args[0] == "generate":
    var imgPath = ""
    var outName = ""
    var i = 1
    while i < args.len:
      if args[i] == "--from-image" and i + 1 < args.len:
        imgPath = args[i+1]
        i += 2
      elif args[i] == "--output" and i + 1 < args.len:
        outName = args[i+1]
        i += 2
      else: i += 1
    handleGenerate(imgPath, outName)
    quit(0)

  let cfg = loadFullConfig()

  for p in args:
    if p.startsWith("--mode="): cfg.display.mode = p[7..^1]
    elif p.startsWith("--theme="): cfg.display.theme = p[8..^1]
    elif p == "--animate": cfg.display.animate = true
    elif p == "--demo": cfg.display.demo = true
    elif p == "--list-themes": printThemes()
    elif p == "--version": printVersion()
    elif p == "--help": printHelp()

  var isPipe = not isatty(stdout)
  let termWidth = getTerminalWidth()
  let termHeight = getTerminalHeight()

  var animate = cfg.display.animate
  if isPipe or getEnv("TMUX", "") != "" or getEnv("TERM", "").startsWith("screen"):
    animate = false

  var cells: seq[Cell] = @[]
  
  var user = cfg.identity.user
  if user == "": user = getUser()
  
  var tp = getTheme(cfg.display.theme, bannerWide, bannerSmall)
  if tp == nil:
    stderr.writeLine("volinit: Theme '" & cfg.display.theme & "' not found, falling back to chip-green")
    tp = getTheme("chip-green", bannerWide, bannerSmall)
    
  cfg.palette = tp.palette

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
    cells = identityCells(cfg, user)

    if cfg.metadata.show_git:
      let git = getGit()
      if git != "":
        cells.add(Cell(content: cfg.palette.info & git & cfg.palette.reset))
    if cfg.metadata.show_battery:
      let bat = getBattery()
      if bat != "":
        cells.add(Cell(content: cfg.palette.info & bat & cfg.palette.reset))

  let actualMode = determineMode(cfg.display.mode, termWidth)
  var bannerStr = tp.heroArt
  if actualMode == "compact": bannerStr = tp.compactArt
  elif actualMode == "monogram": bannerStr = tp.monogramArt

  if cfg.display.demo:
    isPipe = false
    animate = false
    let modes = ["split-panel", "hero", "compact", "monogram"]
    let allTs = getAllThemes(bannerWide, bannerSmall)
    let osLine = getOS()
    for themePack in allTs:
      for mode in modes:
        cfg.palette = themePack.palette
        var demoCells: seq[Cell] = @[]
        demoCells.add(Cell(content: cfg.palette.name & user & cfg.palette.reset & " " & cfg.palette.handle & cfg.identity.handle & cfg.palette.reset))
        if cfg.metadata.show_os:
          demoCells.add(Cell(content: cfg.palette.info & osLine & cfg.palette.reset))
        demoCells.add(Cell(content: cfg.palette.info & cfg.identity.tagline & cfg.palette.reset))

        var bStr = themePack.heroArt
        if mode == "compact": bStr = themePack.compactArt
        elif mode == "monogram": bStr = themePack.monogramArt

        stdout.writeLine("--- DEMO: Mode=" & mode & " Theme=" & themePack.name & " ---")
        var plan = RenderPlan(
          banner: bStr,
          titleBlock: @titleArt,
          cells: demoCells,
          palette: cfg.palette,
          mode: mode,
          width: termWidth,
          height: termHeight,
          animate: animate,
          demo: true,
          isPipe: isPipe,
          wordmark: cfg.identity.wordmark
        )
        renderPlan(plan)
        stdout.writeLine("")
    return

  var plan = RenderPlan(
    banner: bannerStr,
    titleBlock: @titleArt,
    cells: cells,
    palette: cfg.palette,
    mode: cfg.display.mode,
    width: termWidth,
    height: termHeight,
    animate: animate,
    demo: cfg.display.demo,
    isPipe: isPipe,
    wordmark: cfg.identity.wordmark
  )

  renderPlan(plan)

when isMainModule:
  main()
