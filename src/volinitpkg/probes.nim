import std/os, std/strutils, std/parsecfg, std/terminal

proc getOS*(): string =
  for path in ["/etc/os-release", "/usr/lib/os-release"]:
    if not fileExists(path): continue
    try:
      result = loadConfig(path).getSectionValue("", "PRETTY_NAME")
    except:
      result = ""
    if result != "": return
  result = "Linux"

proc getUser*(): string =
  result = getEnv("USER", "")
  if result == "":
    result = getEnv("LOGNAME", "")
  if result == "":
    result = "user"

proc getGit*(): string =
  var currentDir = getCurrentDir()
  for _ in 0..3:
    let headPath = currentDir / ".git" / "HEAD"
    if fileExists(headPath):
      try:
        let content = readFile(headPath).strip()
        if content.startsWith("ref: refs/heads/"):
          return content.replace("ref: refs/heads/", "")
        elif content.len >= 7:
          return content[0..6]
      except:
        return ""
    let parent = currentDir.parentDir()
    if parent == currentDir: break
    currentDir = parent
  return ""

proc getBattery*(): string =
  try:
    for kind, path in walkDir("/sys/class/power_supply/"):
      if path.extractFilename().startsWith("BAT"):
        let capPath = path / "capacity"
        if fileExists(capPath):
          return readFile(capPath).strip() & "%"
  except:
    discard
  return ""

proc getTerminalWidth*(): int =
  try:
    result = terminalWidth()
  except:
    result = 0
  if result <= 0:
    let colEnv = getEnv("COLUMNS", "")
    if colEnv != "":
      try: result = parseInt(colEnv)
      except: discard
  if result <= 0: result = 80

proc getTerminalHeight*(): int =
  try:
    result = terminalHeight()
  except:
    result = 0
  if result <= 0:
    let lineEnv = getEnv("LINES", "")
    if lineEnv != "":
      try: result = parseInt(lineEnv)
      except: discard
  if result <= 0: result = 24
