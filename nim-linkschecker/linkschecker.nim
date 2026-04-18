import asyncdispatch, httpclient, strutils
import threadpool
import times

type
  LinkCheckResult = ref object
    link: string
    state: bool

proc checkLinkAsync(link: string): Future[LinkCheckResult] {.async.} =
  let client = newAsyncHttpClient()
  client.timeout = 5000

  try:
    let resp = await client.get(link)
    echo "OK: ", link, " -> ", resp.code
    return LinkCheckResult(link: link, state: resp.code == Http200)
  except CatchableError:
    # swallow ALL network/DNS/TLS errors as "false"
    return LinkCheckResult(link: link, state: false)

proc asyncLinksChecker(links: seq[string]) {.async.} =
  var tasks: seq[Future[LinkCheckResult]] = @[]

  for link in links:
    let l = link.strip()
    if l.len > 0:
      tasks.add(checkLinkAsync(l))

  let results = await all(tasks)

  for r in results:
    echo r.link, " is ", r.state


proc checkLink(client: HttpClient, link: string): LinkCheckResult =
  try:
    let resp = client.get(link)
    return LinkCheckResult(link: link, state: resp.code == Http200)
  except:
    return LinkCheckResult(link: link, state: false)

proc sequentialLinksChecker(links: seq[string]) =
  let client = newHttpClient()

  for link in links:
    let l = link.strip()
    if l.len == 0: continue
    let result = checkLink(client, l)
    echo result.link, " is ", result.state

proc checkLinkParallel(link: string): LinkCheckResult {.thread.} =
  try:
    let client = newHttpClient()
    let resp = client.get(link)
    return LinkCheckResult(link: link, state: resp.code == Http200)
  except:
    return LinkCheckResult(link: link, state: false)

proc threadedLinksChecker(links: seq[string]) =
  var results: seq[FlowVar[LinkCheckResult]] = @[]

  for link in links:
    let l = link.strip()
    if l.len > 0:
      results.add(spawn checkLinkParallel(l))

  for r in results:
    let res = ^r
    echo res.link, " is ", res.state

proc main() =
  let links = @[
    "https://www.google.com",
    "https://github.com",
    "https://thisurldoesnotexist.tld",
    "https://yahoo.com",
    "https://reddit.com"
  ]

  echo "\nSEQUENTIAL"
  var t0 = cpuTime()
  sequentialLinksChecker(links)
  echo "SEQUENTIAL TIME: ", cpuTime() - t0, "s"

  echo "\nASYNC"
  t0 = cpuTime()
  waitFor asyncLinksChecker(links)
  echo "ASYNC TIME: ", cpuTime() - t0, "s"

  echo "\nTHREADS"
  t0 = cpuTime()
  threadedLinksChecker(links)
  echo "THREADS TIME: ", cpuTime() - t0, "s"

main()

#[
notes on output - async is best and thread time is misleading
also threadpool is depracted, use taskpools

SEQUENTIAL
https://www.google.com is true
https://github.com is true
https://thisurldoesnotexist.tld is false
https://yahoo.com is true
https://reddit.com is true
SEQUENTIAL TIME: 0.076067635s

ASYNC
OK: https://github.com -> 200 OK
OK: https://www.google.com -> 200 OK
OK: https://reddit.com -> 200 OK
OK: https://yahoo.com -> 200 OK
https://www.google.com is true
https://github.com is true
https://thisurldoesnotexist.tld is false
https://yahoo.com is true
https://reddit.com is true
ASYNC TIME: 0.05054291700000001s

THREADS
https://www.google.com is true
https://github.com is true
https://thisurldoesnotexist.tld is false
https://yahoo.com is true
https://reddit.com is true
THREADS TIME: 0.0007128690000000049
]#
