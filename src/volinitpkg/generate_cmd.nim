import std/os, std/osproc, std/strutils, std/parsecfg
import ansi

proc findConverter*(): string =
  let converters = ["jp2a", "chafa", "img2txt"]
  for c in converters:
    let outCmd = findExe(c)
    if outCmd != "": return c
  return ""

proc postProcessArt*(art: string, maxW: int): string =
  var res = ""
  for line in art.splitLines():
    # keep valid ANSI and ascii. No control chars except ansi.
    # we don't strictly strip ansi here since converters emit ansi.
    # We will strip right whitespace
    let r = line.strip(leading = false, trailing = true)
    res.add(r & "\n")
  return res

proc runConverter*(toolName: string, imgPath: string, width: int): string =
  var cmd = ""
  case toolName
  of "jp2a":
    cmd = "jp2a --width=" & $width & " --colors " & imgPath
  of "chafa":
    cmd = "chafa --size=" & $width & "x" & $(width div 2) & " --colors=full " & imgPath
  of "img2txt":
    cmd = "img2txt -W " & $width & " " & imgPath
  else:
    return ""
    
  let (outp, exitCode) = execCmdEx(cmd)
  if exitCode == 0:
    return outp
  return ""

proc handleGenerate*(imgPath: string, outName: string) =
  let toolName = findConverter()
  if toolName == "":
    stderr.writeLine("volinit error: No image-to-ASCII converter found.")
    stderr.writeLine("Install jp2a, chafa, or img2txt.")
    quit(1)
    
  if not fileExists(imgPath):
    stderr.writeLine("volinit error: Image file not found: " & imgPath)
    quit(1)
    
  let name = if outName != "": outName else: "generated-pack"
  let configHome = getEnv("XDG_CONFIG_HOME", getHomeDir() / ".config")
  let themesDir = configHome / "volinit" / "themes"
  let packDir = themesDir / name
  let artDir = packDir / "art"
  
  createDir(artDir)
  
  # Generate Hero (120 cols)
  let heroArt = runConverter(toolName, imgPath, 120)
  writeFile(artDir / "hero.txt", heroArt)
  
  # Generate Compact (80 cols)
  let compactArt = runConverter(toolName, imgPath, 80)
  writeFile(artDir / "compact.txt", compactArt)
  
  # Generate Monogram (40 cols)
  let monoArt = runConverter(toolName, imgPath, 40)
  writeFile(artDir / "monogram.txt", monoArt)
  
  # Create pack.toml
  let packContent = "[theme]\nname = \"" & name & "\"\ndescription = \"Generated from " & extractFilename(imgPath) & "\"\n"
  writeFile(packDir / "pack.toml", packContent)
  
  # Optional: Palette (Empty defaults to chip-green)
  let palContent = "[colors]\n"
  writeFile(packDir / "palette.toml", palContent)
  
  echo "Pack generated successfully at: " & packDir
  quit(0)
