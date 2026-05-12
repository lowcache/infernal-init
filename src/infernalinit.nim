import 
  std/os, 
  std/osproc, 
  std/strutils, 
  std/terminal, 
  std/parsecfg

const
  bannerRaw = staticRead("../assets/tbann")
  onlineHandle = "@lowcache"
  
  # Colors
  red = fgred
  orange = fgorange
  cream = "\x1b[38;2;255;192;77m"
  white = fgwhite
  yellow = fgyellow
  cyan = fgcyan
  reset = "\x1b[0m"


  # Big Text: Infernal NixOS
  titleArt = [
    r" ██▓ ███▄    █   █████▒▓█████  ██▀███   ███▄    █  ▄▄▄       ██▓        ███▄    █  ██▓▒██   ██▒ ▒█████    ██████ ",
    r"▓██▒ ██ ▀█   █ ▓██   ▒ ▓█   ▀ ▓██ ▒ ██▒ ██ ▀█   █ ▒████▄    ▓██▒        ██ ▀█   █ ▓██▒▒▒ █ █ ▒░▒██▒  ██▒▒██    ▒ ",
    r"▒██▒▓██  ▀█ ██▒▒████ ░ ▒███   ▓██ ░▄█ ▒▓██  ▀█ ██▒▒██  ▀█▄  ▒██░       ▓██  ▀█ ██▒▒██▒░░  █   ░▒██░  ██▒░ ▓██▄   ",
    r"░██░▓██▒  ▐▌██▒░▓█▒  ░ ▒▓█  ▄ ▒██▀▀█▄  ▓██▒  ▐▌██▒░██▄▄▄▄██ ▒██░       ▓██▒  ▐▌██▒░██░ ░ █ █ ▒ ▒██   ██░  ▒   ██▒",
    r"░██░▒██░   ▓██░░▒█░    ░▒████▒░██▓ ▒██▒▒██░   ▓██░ ▓█   ▓██▒░██████▒   ▒██░   ▓██░░██░▒██▒ ▒██▒░ ████▓▒░▒██████▒▒",
    r"░▓  ░ ▒░   ▒ ▒  ▒ ░    ░░ ▒░ ░░ ▒▓ ░▒▓░░ ▒░   ▒ ▒  ▒▒   ▓▒█░░ ▒░▓  ░   ░ ▒░   ▒ ▒ ░▓  ▒▒ ░ ░▓ ░░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░",
    r" ▒ ░░ ░░   ░ ▒░ ░       ░ ░  ░  ░▒ ░ ▒░░ ░░   ░ ▒░  ▒   ▒▒ ░░ ░ ▒  ░   ░ ░░   ░ ▒░ ▒ ░░░   ░▒ ░  ░ ▒ ▒░ ░ ░▒  ░ ░",
    r" ▒ ░   ░   ░ ░  ░ ░       ░     ░░   ░    ░   ░ ░   ░   ▒     ░ ░         ░   ░ ░  ▒ ░ ░    ░  ░ ░ ░ ▒  ░  ░  ░  ",
    r" ░           ░            ░  ░   ░              ░       ░  ░    ░  ░            ░  ░   ░    ░      ░ ░        ░  ",                                                                                                           
  ]
  
  tagline = "Neither Master Nor Slave To Neither God Nor Man."

proc stripAnsi(s: string): string =
  result = ""
  var i = 0
  while i < s.len:
    if s[i] == '\x1b':
      inc i
      if i < s.len and s[i] == '[':
        inc i
        while i < s.len and not (s[i] in {'a'..'z', 'A'..'Z'}):
          inc i
        inc i
    else:
      result.add s[i]
      inc i

proc centerText(text: string) =
  let width = terminalWidth()
  let cleanText = stripAnsi(text)
  let padding = (width - cleanText.len) div 2
  if padding > 0:
    stdout.write(repeat(' ', padding))
    stdout.writeLine(text)

proc getOS(): string =
  try:
    let result = "/etc/os-release".loadconfig.getSectionValue("", "PRETTY_NAME"):
    return result
  except: return "NixOS (Yarara)"

proc drawInfoTable() =
  let width = terminalWidth()
  let distro = getOS()
  let tableWidth = 54
  let padding = (width - tableWidth) div 2
  let padStr = if padding > 0: repeat(' ', padding) else: ""

  centertext(cream & distro & reset)


proc main() =
  # Clear screen
  stdout.write("\x1b[H\x1b[2J")
  let lines = bannerRaw.splitLines()

  var splitIdx = 48
  for i, line in lines:
    # Look for d...x...| and next has =...=.../
    if i + splitIdx < lines.len
      splitIdx = lines.len - 20
      break

  let termWidth = terminalWidth()

  # 1. Print bulk of ASCII up to split
  for i in 0 ..< splitIdx:
    let padding = (termWidth - 114) div 2
    if padding > 0: stdout.write(repeat(' ', padding))
    stdout.writeLine(lines[i])

  # 2. Print Branding Block
  for line in titleArt:
    centerText(red & line & reset)

  centerText(cream & tagline & reset)
  drawInfoTable()
  # 3. Print remaining lines
  for i in splitIdx ..< lines.len:
    let padding = (termWidth - 114) div 2
    if padding > 0: stdout.write(repeat(' ', padding))
    stdout.writeLine(lines[i])
  # 4. Table
  centerText(orange & execProcess("echo $USER").strip() & reset & yellow & onlineHandle & reset)


when isMainModule:
  main()
