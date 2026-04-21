import asynchttpserver, asyncdispatch, json, random, strutils, times
import db_connector/db_sqlite, uri

const dbPath = "/tmp/test.db"
const alphabet = "abcdefghijklmnopqrstuvwxyz"
const codeLen = 5
const maxRetries = 5

var db: DbConn

proc log(msg: string) =
  echo "[" & $now() & "] " & msg

proc genCode(): string =
  for i in 0 ..< codeLen:
    result.add alphabet[rand(alphabet.len - 1)]

proc normaliseUrl(url: string): string =
  var u = url.strip()
  if u.len == 0:
    return ""
  var parsed = parseUri(u)
  if parsed.scheme.len == 0:
    u = "http://" & u
    parsed = parseUri(u)
  parsed.hostname = parsed.hostname.toLowerAscii()
  result = $parsed

proc initDb() =
  randomize()
  db = open(dbPath, "", "", "")
  db.exec(sql"PRAGMA journal_mode=WAL;")
  db.exec(
    sql"""
    CREATE TABLE IF NOT EXISTS urls (
      code TEXT PRIMARY KEY,
      url TEXT NOT NULL UNIQUE
    );
  """
  )

proc createCode(url: string): string =
  for i in 0 ..< maxRetries:
    let code = genCode()
    try:
      db.exec(sql"INSERT INTO urls(code, url) VALUES (?, ?)", code, url)
      return code
    except DbError as e:
      log("DB insert collision/error: " & e.msg)
      continue
  log("failed to generate code after retries")
  return ""

proc getOrCreateCode(url: string): string =
  if url.len == 0:
    return ""
  let existing = db.getValue(sql"SELECT code FROM urls WHERE url=?", url)
  if existing.len > 0:
    return existing
  return createCode(url)

proc getUrlByCode(code: string): string =
  if code.len == 0:
    return ""
  return db.getValue(sql"SELECT url FROM urls WHERE code=?", code)

proc safeJsonField(node: JsonNode, key: string): string =
  if node.kind != JObject:
    return ""
  if not node.hasKey(key):
    return ""
  let v = node[key]
  if v.kind != JString:
    return ""
  return v.getStr()

proc handleRequest(req: Request) {.async.} =
  # async HTTP request handler
  try:
    let path = req.url.path
    log($req.reqMethod & " " & path)

    if req.reqMethod == HttpGet and path == "/":
      await req.respond(Http200, "urlshort is running")
      return

    if req.reqMethod == HttpPost and path == "/short":
      let jsonBody =
        try:
          parseJson(req.body)
        except Exception as e:
          log("invalid json: " & e.msg)
          nil

      if jsonBody.isNil:
        await req.respond(Http400, "invalid json")
        return

      let rawUrl = safeJsonField(jsonBody, "url")
      let url = normaliseUrl(rawUrl)

      if url.len == 0:
        await req.respond(Http400, "missing or invalid url")
        return

      let code = getOrCreateCode(url)
      if code.len == 0:
        log("failed to generate code")
        await req.respond(Http500, "failed to generate code")
        return

      await req.respond(Http200, $(%*{"id": code}))
      return

    if req.reqMethod == HttpGet:
      let code = req.url.path.strip(chars = {'/'})
      if code.len == 0 or code.len > 32:
        await req.respond(Http404, "not found")
        return

      let url = getUrlByCode(code)
      if url.len == 0:
        await req.respond(Http404, "not found")
        return

      await req.respond(Http302, "", newHttpHeaders({"Location": url}))
      return

    await req.respond(Http405, "method not allowed")
  except Exception as e:
    log("internal server error: " & e.msg)
    await req.respond(Http500, "internal error")

proc main() {.async.} =
  # server loop
  initDb()
  let server = newAsyncHttpServer()
  log("server starting on http://localhost:5000/")
  await server.serve(Port(5000), handleRequest)

waitFor main() # asynchronous runtime
