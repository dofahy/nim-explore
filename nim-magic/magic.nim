from os import fileExists, dirExists, expandFilename

# library name
const libName* = "libmagic.so"

# constants
const MAGIC_NONE* = 0x000000

# types
type
 Magic = object
 MagicPtr* = ptr Magic

# C function bindings
proc magic_open(flags: cint): MagicPtr {.importc, dynlib: libName.}
proc magic_close(cookie: MagicPtr) {.importc, dynlib: libName.}
proc magic_load(cookie: MagicPtr, filename: cstring): cint {.importc, dynlib: libName.}
proc magic_file(cookie: MagicPtr, filename: cstring): cstring {.importc, dynlib: libName.}
proc magic_error(cookie: MagicPtr): cstring {.importc, dynlib: libName.}

# API
proc guessFile*(filepath: string, flags: cint = MAGIC_NONE): string =
  let fullPath = expandFilename(filepath)
  if not (fileExists(fullPath) or dirExists(fullPath)):
    return "File does not exist"

  let cookie = magic_open(flags)
  if cookie.isNil:
      return "Failed to initialize libmagic"

  if magic_load(cookie, nil) != 0:
      let err = $magic_error(cookie)
      magic_close(cookie)
      return "magic_load failed: " & err

  let res = magic_file(cookie, cstring(fullPath))
  if res.isNil:
      let err = $magic_error(cookie)
      magic_close(cookie)
      return "magic_file failed: " & err

  result = $res
  magic_close(cookie)
