import tables, strutils

type
  Property* = ref object
    val*: string
    items*: seq[string]

  Section* = ref object
    handleLine*: string
    title*: string
    props*: Table[string, Property]

  ParserState = enum
    noOp, sectionName, readKeyValue, readList

proc addItem*(p: Property, item: string) =
  p.items.add(item)

proc getIndentLevel(line: string): int =
  for i, c in line:
    if c != ' ':
      return i
  return 0

proc parseKeyValue(line: string): (string, string) =
  let idx = line.find(':')
  if idx == -1:
    return (line.strip(), "")
  let k = line[0..<idx].strip()
  let v = line[idx+1..^1].strip()
  return (k, v)

proc parseDMI*(source: string): Table[string, Section] =
  var
    state = noOp
    lines = source.splitLines()
    sects = initTable[string, Section]()
    s: Section = nil
    p: Property = nil
    currentKey = ""
    propIndent = 0

  var i = 0
  while i < lines.len:
    let l = lines[i]

    if l.startsWith("#") or l.startsWith("Getting SMBIOS") or l.startsWith("SMBIOS"):
      inc i
      continue

    if l.startsWith("Handle"):
      if s != nil and s.title.len > 0:
        sects[s.title] = s
      s = Section(props: initTable[string, Property]())
      s.handleLine = l
      state = sectionName
      inc i
      continue

    if l.strip.len == 0:
      if s != nil and s.title.len > 0:
        sects[s.title] = s
      state = noOp
      inc i
      continue

    if state == sectionName:
      s.title = l.strip()
      state = readKeyValue
      inc i
      continue

    if state == readKeyValue:
      let (k, v) = parseKeyValue(l)

      p = Property(val: v, items: @[])
      currentKey = k

      propIndent = getIndentLevel(l)

      if i + 1 < lines.len:
        let nextIndent = getIndentLevel(lines[i + 1])
        let nextLine = lines[i + 1]

        if nextIndent > propIndent and nextLine.strip.len > 0:
          state = readList
          inc i
          continue

      s.props[k] = p
      inc i
      continue

    if state == readList:
      let nextLine = if i + 1 < lines.len: lines[i + 1] else: ""
      let nextIndent = if nextLine.len > 0: getIndentLevel(nextLine) else: -1
      let nextIsKeyValue = nextLine.contains(":") and nextLine.strip.len > 0

      if l.strip.len > 0:
        p.addItem(l.strip())

      if i + 1 >= lines.len or nextIndent <= propIndent or nextIsKeyValue:
        s.props[currentKey] = p
        state = readKeyValue

      inc i
      continue

    inc i

  if s != nil and s.title.len > 0:
    sects[s.title] = s

  result = sects
