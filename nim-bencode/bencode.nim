import strformat, tables, json, strutils, hashes

type
  BencodeKind* = enum
    btString
    btInt
    btList
    btDict

  BencodeType* = ref object
    case kind*: BencodeKind
    of BencodeKind.btString: s*: string
    of BencodeKind.btInt: i*: int
    of BencodeKind.btList: l*: seq[BencodeType]
    of BencodeKind.btDict: d*: OrderedTable[BencodeType, BencodeType]

  Encoder* = ref object
  Decoder* = ref object

proc hash*(obj: BencodeType): Hash =
  case obj.kind
  of btString:
    !$(hash(obj.s))
  of btInt:
    !$(hash(obj.i))
  of btList:
    !$(hash(obj.l))
  of btDict:
    var h = 0
    for (k, v) in obj.d.pairs:
      h = h !& hash(k) !& hash(v)
    return !$h

proc `==`*(a, b: BencodeType): bool =
  if a.isNil:
    return b.isNil
  if b.isNil or a.kind != b.kind:
    return false

  case a.kind
  of btString:
    return a.s == b.s
  of btInt:
    return a.i == b.i
  of btList:
    if a.l.len != b.l.len:
      return false
    for i in 0 ..< a.l.len:
      if a.l[i] != b.l[i]:
        return false
    return true
  of btDict:
    if a.d.len != b.d.len:
      return false

    for (k, v) in pairs(a.d):
      if not b.d.hasKey(k):
        return false
      if b.d[k] != v:
        return false

      return true

proc `$`*(a: BencodeType): string =
  case a.kind
  of btString:
    fmt("<Bencode {a.s}>")
  of btInt:
    fmt("<Bencode {a.i}>")
  of btList:
    fmt("<Bencode {a.l}>")
  of btDict:
    fmt("<Bencode {a.d}")

proc encode(this: Encoder, obj: BencodeType): string

proc encode_s(this: Encoder, s: string): string =
  # TODO: check len
  return $s.len & ":" & s

proc encode_i(this: Encoder, i: int): string =
  # TODO: check len
  return fmt("i{i}e")

proc encode_l(this: Encoder, l: seq[BencodeType]): string =
  var encoded = "l"
  for el in l:
    encoded &= this.encode(el)
  encoded &= "e"
  return encoded

proc encode_d(this: Encoder, d: OrderedTable[BencodeType, BencodeType]): string =
  var encoded = "d"
  for k, v in d.pairs():
    assert k.kind == BencodeKind.btString
    encoded &= this.encode(k) & this.encode(v)

  encoded &= "e"
  return encoded

proc encode(this: Encoder, obj: BencodeType): string =
  case obj.kind
  of BencodeKind.btString:
    result = this.encode_s(obj.s)
  of BencodeKind.btInt:
    result = this.encode_i(obj.i)
  of BencodeKind.btList:
    result = this.encode_l(obj.l)
  of BencodeKind.btDict:
    result = this.encode_d(obj.d)

proc decode(this: Decoder, s: string, idx: int): (BencodeType, int)

proc decode_s(this: Decoder, s: string, idx: int): (BencodeType, int) =
  let colon = s.find(':', idx)
  if colon < 0:
    raise newException(ValueError, "Invalid string encoding")

  let strlen = parseInt(s[idx ..< colon])
  let start = colon + 1
  let stop = start + strlen

  if stop > s.len:
    raise newException(ValueError, "String out of bounds")

  return (BencodeType(kind: btString, s: s[start ..< stop]), stop)

proc decode_i(this: Decoder, s: string, idx: int): (BencodeType, int) =
  let epos = s.find('e', idx)
  if epos < 0:
    raise newException(ValueError, "Invalid integer encoding")

  let i = parseInt(s[idx + 1 ..< epos])
  return (BencodeType(kind: btInt, i: i), epos + 1)

proc decode_l(this: Decoder, s: string, idx: int): (BencodeType, int) =
  var i = idx + 1
  var items: seq[BencodeType] = @[]

  while i < s.len and s[i] != 'e':
    let (obj, ni) = this.decode(s, i)
    items.add(obj)
    i = ni

  if i >= s.len or s[i] != 'e':
    raise newException(ValueError, "Unterminated list")

  return (BencodeType(kind: btList, l: items), i + 1)

proc decode_d(this: Decoder, s: string, idx: int): (BencodeType, int) =
  var d = initOrderedTable[BencodeType, BencodeType]()
  var i = idx + 1
  var key: BencodeType = nil

  while i < s.len and s[i] != 'e':
    let (obj, ni) = this.decode(s, i)

    if key.isNil:
      key = obj
    else:
      d[key] = obj
      key = nil

    i = ni

  if i >= s.len or s[i] != 'e':
    raise newException(ValueError, "Unterminated dict")

  return (BencodeType(kind: btDict, d: d), i + 1)

proc decode(this: Decoder, s: string, idx: int): (BencodeType, int) =
  case s[idx]
  of 'i':
    return this.decode_i(s, idx)
  of 'l':
    return this.decode_l(s, idx)
  of 'd':
    return this.decode_d(s, idx)
  else:
    return this.decode_s(s, idx)

proc newEncoder*(): Encoder =
  new Encoder

proc newDecoder*(): Decoder =
  new Decoder

proc encodeObject*(this: Encoder, obj: BencodeType): string =
  return this.encode(obj)

proc decodeObject*(this: Decoder, source: string): BencodeType =
  let (obj, _) = this.decode(source, 0)
  return obj
