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
  red = "\x1b[1;31m"
  orange = "\x1b[38;2;252;182;72m"
  cream = "\x1b[38;2;255;192;77m"
  white = "\x1b[1;37m"
  yellow = "\x1b[1;33m"
  cyan = "\x1b[1;36m"
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
  stdout.styledwriteLine(text)
  
proc getOS(): string =
  result = "/etc/os-release".loadconfig.getSectionValue("", "PRETTY_NAME")
  return result
  
proc drawInfoTable() =
  let width = terminalWidth()
  let distro = getOS()
  let quote = tagline
  let tableWidth = 54
  let padding = (width - tableWidth) div 2
  let padStr = if padding > 0: repeat(' ', padding) else: ""

  centerText(orange & execProcess("echo $USER").strip() & reset & " " & yellow & onlineHandle & reset)
  centerText(cream & distro & reset)
  
proc main() =
  # Clear screen
  stdout.write("\x1b[H\x1b[2J")
  
  let lines = bannerRaw.splitLines()
  let totalLines = lines.len
  
  # Calculate split index - exactly 20 lines from bottom
  var splitIdx = totalLines - 20
  if splitIdx < 0:
    splitIdx = 0
  
  let termWidth = terminalWidth()
  # 1. Print bulk of ASCII up to split
  for i in 0 ..< splitIdx:
    let padding = (termWidth - titleArt[0].len) div 2
    if padding > 0:
      stdout.write(repeat(' ', padding))
    stdout.writeLine(lines[i])
  
  # 2. Print Branding Block with deep red color
  for tline in titleArt:
    centerText(red & tline & reset)
    
  # 3. Print OS information centered below branding block
  drawInfoTable()
  centerText(cream & tagline & reset)
  # 4. Print remaining lines (if any) and local username at very bottom
  for i in splitIdx ..< totalLines:
    let padding = (termWidth - titleArt[0].len) div 2
    if padding > 0:
      stdout.write(repeat(' ', padding))
    stdout.writeLine(lines[i])

when isMainModule:
  main()
