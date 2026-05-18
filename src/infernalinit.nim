import 
  std/os, 
  std/strutils, 
  std/terminal, 
  std/parsecfg,
  std/unicode,
  std/re

const
  bannerRaw = staticRead("../assets/tbann")
  onlineHandle = "@lowcache"
  
  # Colors
  red = "\x1b[1;31m"
  orange = "\x1b[38;2;252;182;72m"
  cream = "\x1b[38;2;255;192;77m"
  yellow = "\x1b[1;33m"
  reset = "\x1b[0m"

  # titleArt must be strictly one physical line per array entry
  titleArt = [
    r"██╗███╗   ██╗███████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗",
    r"██║████╗  ██║██╔════╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝",
    r"██║██╔██╗ ██║█████╗  █████╗  ██████╔╝██╔██╗ ██║███████║██║     ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗",
    r"██║██║╚██╗██║██╔══╝  ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║",
    r"██║██║ ╚████║██║     ███████╗██║  ██║██║ ╚████║██║  ██║███████╗██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║",
    r"╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
  ]
  
  tagline = "Neither Master Nor Slave To Neither God Nor Man."

proc stripAnsi(s: string): string =
  # Robust ANSI stripping using regex to handle TrueColor (24-bit) sequences
  result = s.replace(re"\x1b\[[0-9;]*[a-zA-Z]", "")

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

  let rawLines = bannerRaw.splitLines()
  let bannerMinIndent = getMinIndent(rawLines)
  var lines: seq[string] = @[]
  for rline in rawLines:
    lines.add(stripLeadingSpaces(rline, bannerMinIndent))

  let titleMinIndent = getMinIndent(titleArt)
  var processedTitle: seq[string] = @[]
  for tline in titleArt:
    processedTitle.add(stripLeadingSpaces(tline, titleMinIndent))

  let totalLines = lines.len
  var splitIdx = totalLines - 10
  if splitIdx < 0: splitIdx = 0
  
  # Calculate max visual width of the cropped banner to center it accurately
  var maxBannerWidth = 0
  for line in lines:
    let vWidth = stripAnsi(line).strip(trailing = true).runeLen
    if vWidth > maxBannerWidth: maxBannerWidth = vWidth
  
  let bannerPadding = (width - maxBannerWidth) div 2
  let bannerPadStr = if bannerPadding > 0: repeat(' ', bannerPadding) else: ""

  let totalOutputHeight = totalLines + processedTitle.len + 3
  let verticalPadding = (height - totalOutputHeight) div 2

  stdout.write("\x1b[H\x1b[2J")
  
  if verticalPadding > 0:
    for _ in 1..verticalPadding:
      stdout.writeLine("")

  # Print top part of banner with calculated padding
  for i in 0 ..< splitIdx:
    stdout.write(bannerPadStr)
    stdout.writeLine(lines[i])
  
  for tline in processedTitle:
    centerText(red & tline & reset, width)
    
  centerText(orange & getEnv("USER", "user") & reset & " " & yellow & onlineHandle & reset, width) 
  centerText(cream & getOS() & reset, width)
  centerText(cream & tagline & reset, width)
  
  # Print bottom part of banner with calculated padding
  for i in splitIdx ..< totalLines:
    stdout.write(bannerPadStr)
    stdout.writeLine(lines[i])

  stdout.flushFile()

when isMainModule:
  main()
