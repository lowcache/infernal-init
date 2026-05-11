import os, osproc, strutils, terminal

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
    r"  ___ _   _ _____ _____ ____  _   _    _    _         _   _ _____  _____  ____   ",
    r" |_ _| \ | |  ___| ____|  _ \| \ | |  / \  | |       | \ | |_ _\ \/ / _ \/ ___|  ",
    r"  | ||  \| | |_  |  _| | |_) |  \| | / _ \ | |       |  \| || | \  / | | \___ \  ",
    r"  | || |\  |  _| | |___|  _ <| |\  |/ ___ \| |___    | |\  || | /  \ |_| |___) | ",
    r" |___|_| \_|_|   |_____|_| \_\_| \_/_/   \_\_____|   |_| \_|___/_/\_\___/|____/  "
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
    let content = readFile("/etc/os-release")
    for line in content.splitLines():
      if line.startsWith("PRETTY_NAME="):
        result = line.split('=')[1].strip(chars = {'"'})
        break
    return result
  except: return "NixOS (Yarara)"

proc drawInfoTable() =
  let width = terminalWidth()
  let 
    k1 = " "
    v1 = getOS()
    

  let tableWidth = 54
  let padding = (width - tableWidth) div 2
  let padStr = if padding > 0: repeat(' ', padding) else: ""

  let border = "┏" & repeat("━", tableWidth - 2) & "┓"
  let bottom = "┗" & repeat("━", tableWidth - 2) & "┛"

  stdout.writeLine(padStr & white & border & reset)
  
  proc row(key, val: string) =
    let contentLen = 2 + key.len + 3 + val.len
    let trailing = tableWidth - 2 - contentLen
    stdout.write(padStr & white & "┃" & reset)
    stdout.write("  " & orange & key & reset & white & " ➜ " & reset & cream & val)
    if trailing > 0:
      stdout.write(repeat(" ", trailing))
    stdout.writeLine(white & "┃" & reset)

  row(k1, v1)
  stdout.writeLine(padStr & white & bottom & reset)

proc main() =
  # Clear screen
  stdout.write("\x1b[H\x1b[2J")
  
  let lines = bannerRaw.splitLines()
  
  # Search for the orange dx and orange == split point
  # Based on investigation, line 48 has dx and line 49 has ==
  var splitIdx = 48
  for i, line in lines:
    # Look for d...x...| and next has =...=.../
    if line.contains('d') and line.contains('x') and line.contains('|'):
      if i + 1 < lines.len and lines[i+1].contains('=') and lines[i+1].contains('/'):
        splitIdx = i + 1
        break

  let termWidth = terminalWidth()

  # 1. Print bulk of ASCII up to split
  for i in 0 ..< splitIdx:
    let padding = (termWidth - 100) div 2
    if padding > 0: stdout.write(repeat(' ', padding))
    stdout.writeLine(lines[i])

  stdout.writeLine("")

  # 2. Print Branding Block
  for line in titleArt:
    centerText(red & line & reset)
  
  stdout.writeLine("")
  centerText(cream & tagline & reset)
  stdout.writeLine("")

  # 3. Print remaining lines
  for i in splitIdx ..< lines.len:
    let padding = (termWidth - 100) div 2
    if padding > 0: stdout.write(repeat(' ', padding))
    stdout.writeLine(lines[i])

  # 4. Table
  centerText(orange & execProcess("echo $USER").strip() & reset & " ➜ " & yellow & onlineHandle & reset)
  drawInfoTable()
  stdout.writeLine("")

when isMainModule:
  main()
