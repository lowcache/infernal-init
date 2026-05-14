import 
  std/os, 
  std/osproc, 
  std/strutils, 
  std/terminal, 
  std/parsecfg

const
  bannerRaw = staticRead("../assets/tbann")
  onlineHandle = "@lowcache" # [cite: 1]
  
  # Colors
  red = "\x1b[1;31m" # [cite: 1]
  orange = "\x1b[38;2;252;182;72m" # [cite: 1]
  cream = "\x1b[38;2;255;192;77m" # [cite: 1]
  yellow = "\x1b[1;33m" # [cite: 1]
  reset = "\x1b[0m" # [cite: 1]

  # titleArt must be strictly one physical line per array entry
  titleArt = [
    r"██╗███╗   ██╗███████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗",
    r"██║████╗  ██║██╔════╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝",
    r"██║██╔██╗ ██║█████╗  █████╗  ██████╔╝██╔██╗ ██║███████║██║     ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗",
    r"██║██║╚██╗██║██╔══╝  ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║",
    r"██║██║ ╚████║██║     ███████╗██║  ██║██║ ╚████║██║  ██║███████╗██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║",
    r"╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
  ]
  
  tagline = "Neither Master Nor Slave To Neither God Nor Man." # [cite: 7]

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
      result.add s[i] # [cite: 9]
      inc i
      
proc centerText(text: string) =
  let width = terminalWidth() # [cite: 9]
  let cleanText = stripAnsi(text).strip(trailing = true) # [cite: 9]
  let padding = (width - cleanText.len) div 2 # [cite: 9]
  if padding > 0:
    stdout.write(repeat(' ', padding)) # [cite: 9]
  stdout.writeLine(text.strip(trailing = true)) # [cite: 9]

proc getOS(): string =
  try:
    result = "/etc/os-release".loadConfig.getSectionValue("", "PRETTY_NAME") # [cite: 1]
  except:
    result = "NixOS" # [cite: 10]
  
proc main() =
  stdout.write("\x1b[H\x1b[2J") # [cite: 1]
  
  let lines = bannerRaw.splitLines() # [cite: 1]
  let totalLines = lines.len # [cite: 1]
  var splitIdx = totalLines - 10 # [cite: 1]
  if splitIdx < 0: splitIdx = 0 # [cite: 1]
  
  for i in 0 ..< splitIdx:
    centerText(lines[i]) # [cite: 1]
  
  for tline in titleArt:
    centerText(red & tline & reset) # [cite: 1]
    
  # Use getEnv to avoid the shell command hang 
  centerText(orange & getEnv("USER", "user") & reset & " " & yellow & onlineHandle & reset) 
  centerText(cream & getOS() & reset) # 
  centerText(cream & tagline & reset) # 
  
  for i in splitIdx ..< totalLines:
    centerText(lines[i]) # 

  stdout.flushFile() # Ensures output is sent before the process can hang

when isMainModule:
  main()
