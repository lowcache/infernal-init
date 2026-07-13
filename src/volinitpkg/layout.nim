import std/strutils, std/os, std/terminal
import ansi, config, probes

type
  Cell* = object
    content*: string
    priority*: int
    fallback*: string

  RenderPlan* = object
    banner*: string
    titleBlock*: seq[string]
    cells*: seq[Cell]
    palette*: Palette
    mode*: string
    width*: int
    height*: int
    animate*: bool
    noAnsi*: bool
    demo*: bool
    isPipe*: bool
    wordmark*: string

proc bannerBlock(plan: RenderPlan, reserveRows: int): seq[string] =
  # De-indented banner lines, or empty if the art doesn't fit the terminal
  # (width, or height once reserveRows are set aside for title/metadata)
  if plan.banner.len == 0: return @[]
  if visualWidth(plan.banner) > plan.width: return @[]
  let rawLines = plan.banner.splitLines()
  if rawLines.len > plan.height - reserveRows: return @[]
  let minIndent = getMinIndent(rawLines)
  for rline in rawLines:
    result.add(stripLeadingSpaces(rline, minIndent))

proc determineMode*(requestedMode: string, width: int): string =
  if requestedMode != "auto" and requestedMode != "":
    return requestedMode
  if width >= 160: return "split-panel"
  if width >= 100: return "hero"
  if width >= 60: return "compact"
  return "monogram"

proc renderHero*(plan: RenderPlan)

proc renderSplitPanel*(plan: RenderPlan) =
  let rawLines = plan.banner.splitLines()
  let bannerMinIndent = getMinIndent(rawLines)
  var bannerLines: seq[string] = @[]
  for rline in rawLines:
    # Trailing colored whitespace must go: printed width has to equal
    # visualWidth or the right-hand column drifts per row
    bannerLines.add(stripTrailingVisual(stripLeadingSpaces(rline, bannerMinIndent)))

  var maxBannerWidth = 0
  for line in bannerLines:
    let w = visualWidth(line)
    if w > maxBannerWidth: maxBannerWidth = w

  let titleMinIndent = getMinIndent(plan.titleBlock)
  var titleLines: seq[string] = @[]
  for tline in plan.titleBlock:
    titleLines.add(stripLeadingSpaces(tline, titleMinIndent))
  
  var rightBlock: seq[string] = @[]
  for tline in titleLines:
    rightBlock.add(plan.palette.title & tline & plan.palette.reset)
  for cell in plan.cells:
    rightBlock.add(cell.content)

  let totalHeight = max(bannerLines.len, rightBlock.len)
  let vPad = max(0, (plan.height - totalHeight) div 2)
  
  if vPad > 0 and not plan.demo:
    for _ in 1..vPad: stdout.writeLine("")
    
  let bannerVOffset = max(0, (totalHeight - bannerLines.len) div 2)
  let rightVOffset = max(0, (totalHeight - rightBlock.len) div 2)
  
  let gap = 4
  var maxRightWidth = 0
  for line in rightBlock:
    let w = visualWidth(line)
    if w > maxRightWidth: maxRightWidth = w
  
  let totalWidth = maxBannerWidth + gap + maxRightWidth
  if totalWidth > plan.width:
    # Content doesn't fit side-by-side (e.g. 160-162-col terminals where
    # art 92 + gap 4 + title 67 = 163) — stack it instead of wrapping
    renderHero(plan)
    return
  let leftPad = max(0, (plan.width - totalWidth) div 2)

  for row in 0..<totalHeight:
    if leftPad > 0: stdout.write(repeat(' ', leftPad))
    
    var bLine = ""
    let bIdx = row - bannerVOffset
    if bIdx >= 0 and bIdx < bannerLines.len:
      bLine = bannerLines[bIdx]
    
    let bw = visualWidth(bLine)
    stdout.write(bLine)
    if maxBannerWidth - bw + gap > 0:
      stdout.write(repeat(' ', maxBannerWidth - bw + gap))
      
    let rIdx = row - rightVOffset
    if rIdx >= 0 and rIdx < rightBlock.len:
      stdout.write(rightBlock[rIdx])
      
    stdout.writeLine("")
    if plan.animate: sleep(15)

proc renderHero*(plan: RenderPlan) =
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

  let totalOutputHeight = bannerLines.len + titleLines.len + plan.cells.len
  let verticalPadding = max(0, (plan.height - totalOutputHeight) div 2)
  
  if verticalPadding > 0 and not plan.demo:
    for _ in 1..verticalPadding: stdout.writeLine("")
    
  let bannerPadding = max(0, (plan.width - maxBannerWidth) div 2)
  let bannerPadStr = if bannerPadding > 0: repeat(' ', bannerPadding) else: ""
  
  for line in bannerLines:
    stdout.write(bannerPadStr)
    stdout.writeLine(line)
    if plan.animate: sleep(15)
    
  let titlePadding = max(0, (plan.width - maxTitleWidth) div 2)
  let titlePadStr = if titlePadding > 0: repeat(' ', titlePadding) else: ""
  for tline in titleLines:
    stdout.write(titlePadStr)
    stdout.writeLine(plan.palette.title & tline & plan.palette.reset)
    if plan.animate: sleep(15)
    
  for cell in plan.cells:
    centerText(cell.content, plan.width)
    if plan.animate: sleep(15)

proc renderCompact*(plan: RenderPlan) =
  # Banner art renders when it fits the terminal; otherwise title-only.
  # A title figlet wider than the terminal degrades to the plain wordmark.
  let titleMinIndent = getMinIndent(plan.titleBlock)
  var titleLines: seq[string] = @[]
  for tline in plan.titleBlock:
    titleLines.add(stripLeadingSpaces(tline, titleMinIndent))

  var maxTitleWidth = 0
  for tline in titleLines:
    let w = visualWidth(tline)
    if w > maxTitleWidth: maxTitleWidth = w

  if maxTitleWidth > plan.width:
    let mark = if plan.wordmark.len > 0: plan.wordmark else: "LowCache"
    titleLines = @[mark]
    maxTitleWidth = visualWidth(mark)

  let bannerLines = bannerBlock(plan, titleLines.len + plan.cells.len)
  var maxBannerWidth = 0
  for line in bannerLines:
    let w = visualWidth(line)
    if w > maxBannerWidth: maxBannerWidth = w

  let totalOutputHeight = bannerLines.len + titleLines.len + plan.cells.len
  let verticalPadding = max(0, (plan.height - totalOutputHeight) div 2)

  if verticalPadding > 0 and not plan.demo:
    for _ in 1..verticalPadding: stdout.writeLine("")

  let bannerPadding = max(0, (plan.width - maxBannerWidth) div 2)
  let bannerPadStr = if bannerPadding > 0: repeat(' ', bannerPadding) else: ""
  for line in bannerLines:
    stdout.write(bannerPadStr)
    stdout.writeLine(line)
    if plan.animate: sleep(15)

  let titlePadding = max(0, (plan.width - maxTitleWidth) div 2)
  let titlePadStr = if titlePadding > 0: repeat(' ', titlePadding) else: ""
  for tline in titleLines:
    stdout.write(titlePadStr)
    stdout.writeLine(plan.palette.title & tline & plan.palette.reset)
    if plan.animate: sleep(15)

  for cell in plan.cells:
    centerText(cell.content, plan.width)
    if plan.animate: sleep(15)

proc renderMonogram*(plan: RenderPlan) =
  # Banner art renders when it fits; otherwise a plain wordmark line
  let bannerLines = bannerBlock(plan, plan.cells.len)
  let markLines = if bannerLines.len > 0: bannerLines.len else: 1
  let totalOutputHeight = markLines + plan.cells.len
  let verticalPadding = max(0, (plan.height - totalOutputHeight) div 2)

  if verticalPadding > 0 and not plan.demo:
    for _ in 1..verticalPadding: stdout.writeLine("")

  if bannerLines.len > 0:
    var maxBannerWidth = 0
    for line in bannerLines:
      let w = visualWidth(line)
      if w > maxBannerWidth: maxBannerWidth = w
    let pad = max(0, (plan.width - maxBannerWidth) div 2)
    let padStr = if pad > 0: repeat(' ', pad) else: ""
    for line in bannerLines:
      stdout.write(padStr)
      stdout.writeLine(line)
      if plan.animate: sleep(15)
  else:
    let mark = if plan.wordmark.len > 0: plan.wordmark else: "LowCache"
    centerText(plan.palette.title & mark & plan.palette.reset, plan.width)
    if plan.animate: sleep(15)
  for cell in plan.cells:
    centerText(cell.content, plan.width)
    if plan.animate: sleep(15)

proc renderPlan*(plan: RenderPlan) =
  if plan.isPipe:
    for cell in plan.cells:
      stdout.writeLine(stripAnsi(cell.content))
    return

  let actualMode = determineMode(plan.mode, plan.width)
  
  if not plan.demo:
    stdout.write("\x1b[H\x1b[2J")
    
  case actualMode
  of "split-panel": renderSplitPanel(plan)
  of "compact": renderCompact(plan)
  of "monogram": renderMonogram(plan)
  else: renderHero(plan)
  
  stdout.flushFile()
