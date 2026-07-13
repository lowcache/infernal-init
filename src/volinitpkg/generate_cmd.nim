import std/os, std/osproc, std/strutils

proc findConverter*(): string =
  let converters = ["jp2a", "chafa", "img2txt"]
  for c in converters:
    let outCmd = findExe(c)
    if outCmd != "": return c
  return ""

proc postProcessArt*(art: string): string =
  # Normalize line endings, strip trailing whitespace per line and trailing blank lines
  var res = ""
  for line in art.splitLines():
    res.add(line.strip(leading = false, trailing = true) & "\n")
  result = res.strip(leading = false, trailing = true) & "\n"

proc runConverter*(toolName: string, imgPath: string, width: int): string =
  let img = quoteShell(imgPath)
  var cmd = ""
  case toolName
  of "jp2a":
    cmd = "jp2a --width=" & $width & " --colors " & img
  of "chafa":
    cmd = "chafa --size=" & $width & "x" & $(width div 2) & " --colors=full " & img
  of "img2txt":
    cmd = "img2txt -W " & $width & " " & img
  else:
    return ""

  let (outp, exitCode) = execCmdEx(cmd)
  if exitCode == 0:
    return postProcessArt(outp)
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
  
  # Create pack.toml (strip quotes from interpolated values to keep the file parseable)
  let safeName = name.replace("\"", "")
  let safeSrc = extractFilename(imgPath).replace("\"", "")
  let packContent = "[theme]\nname = \"" & safeName & "\"\ndescription = \"Generated from " & safeSrc & "\"\n"
  writeFile(packDir / "pack.toml", packContent)
  
  # Optional: Palette (Empty defaults to chip-green)
  let palContent = "[colors]\n"
  writeFile(packDir / "palette.toml", palContent)
  
  echo "Pack generated successfully at: " & packDir
  quit(0)
