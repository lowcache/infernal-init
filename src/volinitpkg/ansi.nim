import std/strutils, std/re, std/unicode

proc stripAnsi*(s: string): string =
  # Robust ANSI stripping using regex to handle TrueColor (24-bit) sequences
  result = s.replace(re"\x1b\[[0-9;]*[a-zA-Z]", "")

proc visualWidth*(art: string): int =
  # Max visual (ANSI-stripped) column count across the art's lines
  result = 0
  for line in art.splitLines():
    let w = stripAnsi(line).strip(trailing = true).runeLen
    if w > result: result = w

proc getMinIndent*(lines: openArray[string]): int =
  result = int.high
  for line in lines:
    let clean = stripAnsi(line)
    if clean.strip().len == 0: continue
    var indent = 0
    while indent < clean.len and clean[indent] == ' ':
      inc indent
    if indent < result: result = indent
  if result == int.high: result = 0

proc stripLeadingSpaces*(s: string, count: int): string =
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

proc centerText*(text: string, width: int, noPad: bool = false) =
  let cleanText = stripAnsi(text).strip(trailing = true)
  let padding = (width - cleanText.runeLen) div 2
  if padding > 0 and not noPad:
    stdout.write(repeat(' ', padding))
  stdout.writeLine(text.strip(trailing = true))
