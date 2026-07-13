import std/os, std/strutils
import layout, ansi, config, themes

proc renderToAnsi*(plan: RenderPlan): string =
  # Render to a string buffer instead of stdout
  # We can temporarily mock stdout but Nim's stdout isn't easily mockable.
  # Instead of mocking, we can refactor `layout.nim` to return string or just re-implement a simple version for export.
  # Actually, `renderPlan` writes directly to `stdout`.
  # For SVG, we just need the colored strings.
  # Let's rebuild the layout to string here since layout.nim uses stdout.write
  
  var outStr = ""
  
  # For export, we assume hero mode (as per instructions: "auto-select hero for export")
  # We will do a stripped down hero render
  let rawLines = plan.banner.splitLines()
  let bannerMinIndent = getMinIndent(rawLines)
  var bannerLines: seq[string] = @[]
  for rline in rawLines:
    bannerLines.add(stripLeadingSpaces(rline, bannerMinIndent))
    
  var maxBannerWidth = 0
  for line in bannerLines:
    let w = visualWidth(line)
    if w > maxBannerWidth: maxBannerWidth = w

  let titleMinIndent = getMinIndent(plan.titleBlock)
  var titleLines: seq[string] = @[]
  for tline in plan.titleBlock:
    titleLines.add(stripLeadingSpaces(tline, titleMinIndent))
    
  var maxTitleWidth = 0
  for tline in titleLines:
    let w = visualWidth(tline)
    if w > maxTitleWidth: maxTitleWidth = w

  let bannerPadding = max(0, (plan.width - maxBannerWidth) div 2)
  let bannerPadStr = if bannerPadding > 0: repeat(' ', bannerPadding) else: ""
  
  for line in bannerLines:
    outStr.add(bannerPadStr & line & "\n")
    
  let titlePadding = max(0, (plan.width - maxTitleWidth) div 2)
  let titlePadStr = if titlePadding > 0: repeat(' ', titlePadding) else: ""
  for tline in titleLines:
    outStr.add(titlePadStr & plan.palette.title & tline & plan.palette.reset & "\n")
    
  for cell in plan.cells:
    let w = visualWidth(cell.content)
    let pad = max(0, (plan.width - w) div 2)
    outStr.add(repeat(' ', pad) & cell.content & "\n")
    
  return outStr

proc exportAnsi*(plan: RenderPlan, outPath: string) =
  let finalPath = if outPath != "": outPath else: "volinit-banner.ans"
  let content = renderToAnsi(plan)
  writeFile(finalPath, content)

proc parseAnsiToSvg*(ansiStr: string, width, height: int): string =
  # Very basic SVG generation
  var svg = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
  svg.add("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " & $(width * 10) & " " & $(height * 20) & "\" style=\"background-color: #0d1117;\">\n")
  svg.add("  <style>\n")
  svg.add("    .text { font-family: monospace; font-size: 14px; white-space: pre; }\n")
  svg.add("  </style>\n")
  
  var y = 24
  for line in ansiStr.splitLines():
    if line.len == 0: continue
    # Extremely basic ANSI color extraction for SVG
    # We will strip all ANSI for now, unless we write a full parser.
    # The prompt says: "each colored span = a tspan with fill attribute"
    # Actually, we can split by \x1b[
    
    svg.add("  <text x=\"24\" y=\"" & $y & "\" class=\"text\" fill=\"#c8cdc8\">")
    
    var parts = line.split("\x1b[")
    if parts.len > 0:
      svg.add(parts[0].replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))
      for i in 1..<parts.len:
        let part = parts[i]
        let mIdx = part.find('m')
        if mIdx >= 0:
          let colorCode = part[0..<mIdx]
          let text = part[mIdx+1..^1].replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
          var color = "#c8cdc8"
          if colorCode == "0": color = "#c8cdc8"
          elif colorCode.startsWith("38;2;"):
            let rgb = colorCode[5..^1].split(";")
            if rgb.len == 3:
              color = "rgb(" & rgb[0] & "," & rgb[1] & "," & rgb[2] & ")"
          if text.len > 0:
            svg.add("<tspan fill=\"" & color & "\">" & text & "</tspan>")
    
    svg.add("</text>\n")
    y += 20
    
  svg.add("</svg>\n")
  return svg

proc exportSvg*(plan: RenderPlan, outPath: string) =
  let finalPath = if outPath != "": outPath else: "volinit-banner.svg"
  let content = renderToAnsi(plan)
  let lines = content.splitLines()
  var maxWidth = 0
  for l in lines:
    let w = visualWidth(l)
    if w > maxWidth: maxWidth = w
  
  let svg = parseAnsiToSvg(content, maxWidth + 4, lines.len + 2)
  writeFile(finalPath, svg)

proc handleExport*(plan: RenderPlan, format: string, outPath: string) =
  if format == "ansi":
    exportAnsi(plan, outPath)
  elif format == "svg":
    exportSvg(plan, outPath)
  elif format == "png":
    stderr.writeLine("volinit: PNG export skipped (requires external deps not in pure nim stdlib). Please use SVG.")
  else:
    stderr.writeLine("volinit: unknown format " & format)
