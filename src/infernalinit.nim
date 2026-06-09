import
  std/os,
  std/strutils,
  std/terminal,
  std/parsecfg,
  std/unicode,
  std/re

const
  bannerWide = staticRead("../assets/lowcacheascii")        # ~116 cols (full-screen)
  # bannerCompact = staticRead("../assets/lowcacheascii-sm") # ~80 cols — uncomment once rendered
  onlineHandle = "@lowcache"

  # Palette — green/grey to match the chip badge
  titleCol  = "\x1b[38;2;170;215;30m"   # PCB green  — LowCache wordmark
  nameCol   = "\x1b[38;2;200;205;200m"  # die silver — USER
  handleCol = "\x1b[38;2;205;185;100m"  # die-label gold — @handle
  infoCol   = "\x1b[38;2;150;170;150m"  # muted grey-green — OS / tagline
  reset     = "\x1b[0m"

  # Candidate banners, any width. The runtime picker selects the widest that
  # fits the terminal, so add smaller renders here for cross-terminal fit.
  banners = [bannerWide]

  # titleArt must be strictly one physical line per array entry
  titleArt = [
    r"██╗      ██████╗ ██╗    ██╗ ██████╗ █████╗  ██████╗██╗  ██╗███████╗",
    r"██║     ██╔═══██╗██║    ██║██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝",
    r"██║     ██║   ██║██║ █╗ ██║██║     ███████║██║     ███████║█████╗  ",
    r"██║     ██║   ██║██║███╗██║██║     ██╔══██║██║     ██╔══██║██╔══╝  ",
    r"███████╗╚██████╔╝╚███╔███╔╝╚██████╗██║  ██║╚██████╗██║  ██║███████╗",
    r"╚══════╝ ╚═════╝  ╚══╝╚══╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝"
  ]

  tagline = "LowCache, High Throughput"

proc stripAnsi(s: string): string =
  # Robust ANSI stripping using regex to handle TrueColor (24-bit) sequences
  result = s.replace(re"\x1b\[[0-9;]*[a-zA-Z]", "")

proc visualWidth(art: string): int =
  # Max visual (ANSI-stripped) column count across the art's lines
  for line in art.splitLines():
    let w = stripAnsi(line).strip(trailing = true).runeLen
    if w > result: result = w

proc pickBanner(termWidth: int): string =
  # Choose the widest banner that fits the terminal; fall back to the narrowest
  var bestW = -1
  var narrowestW = int.high
  var narrowest = ""
  for art in banners:
    let w = visualWidth(art)
    if w <= termWidth and w > bestW:
      result = art; bestW = w
    if w < narrowestW:
      narrowest = art; narrowestW = w
  if bestW < 0: result = narrowest

proc getMinIndent(lines: openArray[string]): int =
  result = int.high
  for line in lines:
    let clean = stripAnsi(line)
    if clean.strip().len == 0: continue
    var indent = 0
    while indent < clean.len and clean[indent] == ' ':
      inc indent
    if indent < result: result = indent
  if result == int.high: result = 0

proc stripLeadingSpaces(s: string, count: int): string =
  var stripped = 0
  result = s
  var i = 0
  while i < result.len and stripped < count:
    if result[i] == '\x1b':
      inc i
      if i < result.len and result[i] == '[':
        inc i
        while i < result.len and not (result[i] in {'a'..'z', 'A'..'Z'}):
          inc i
        inc i
    elif result[i] == ' ':
      result.delete(i..i)
      inc stripped
    else:
      break

proc centerText(text: string, width: int) =
  let cleanText = stripAnsi(text).strip(trailing = true)
  let padding = (width - cleanText.runeLen) div 2
  if padding > 0:
    stdout.write(repeat(' ', padding))
  stdout.writeLine(text.strip(trailing = true))

proc getOS(): string =
  try:
    result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME")
  except:
    result = "NixOS"

proc main() =
  var width = terminalWidth()
  var height = terminalHeight()

  if width == 0: width = 80
  if height == 0: height = 24

  let banner = pickBanner(width)

  let rawLines = banner.splitLines()
  let bannerMinIndent = getMinIndent(rawLines)
  var lines: seq[string] = @[]
  for rline in rawLines:
    lines.add(stripLeadingSpaces(rline, bannerMinIndent))

  let titleMinIndent = getMinIndent(titleArt)
  var processedTitle: seq[string] = @[]
  for tline in titleArt:
    processedTitle.add(stripLeadingSpaces(tline, titleMinIndent))

  # Visual width of the chosen banner, to center it as a whole block
  var maxBannerWidth = 0
  for line in lines:
    let vWidth = stripAnsi(line).strip(trailing = true).runeLen
    if vWidth > maxBannerWidth: maxBannerWidth = vWidth

  let bannerPadding = (width - maxBannerWidth) div 2
  let bannerPadStr = if bannerPadding > 0: repeat(' ', bannerPadding) else: ""

  # banner + title block + 3 identity lines (name/handle, OS, tagline)
  let totalOutputHeight = lines.len + processedTitle.len + 3
  let verticalPadding = (height - totalOutputHeight) div 2

  stdout.write("\x1b[H\x1b[2J")

  if verticalPadding > 0:
    for _ in 1..verticalPadding:
      stdout.writeLine("")

  # Print the badge whole — no mid-split
  for line in lines:
    stdout.write(bannerPadStr)
    stdout.writeLine(line)

  # Center the title as one block (uniform left pad) so trailing-space rows
  # don't drift right the way per-line centering would.
  var maxTitleWidth = 0
  for tline in processedTitle:
    let w = stripAnsi(tline).runeLen
    if w > maxTitleWidth: maxTitleWidth = w
  let titlePadding = (width - maxTitleWidth) div 2
  let titlePadStr = if titlePadding > 0: repeat(' ', titlePadding) else: ""
  for tline in processedTitle:
    stdout.write(titlePadStr)
    stdout.writeLine(titleCol & tline & reset)

  centerText(nameCol & getEnv("USER", "user") & reset & " " & handleCol & onlineHandle & reset, width)
  centerText(infoCol & getOS() & reset, width)
  centerText(infoCol & tagline & reset, width)

  stdout.flushFile()

when isMainModule:
  main()
