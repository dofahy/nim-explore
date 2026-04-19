import os
import configparser

when isMainModule:
  let path = "sample.ini"

  if not fileExists(path):
    quit("sample.ini not found")

  let content = readFile(path)

  try:
    var ini = parseIni(content)

    echo "=== Parsed INI ==="
    echo ini

    echo "\n=== Reconstructed ==="
    echo ini.toIniString()

    echo "\n=== Access tests ==="
    if ini.hasSection("owner"):
      echo "Owner name: ", ini.getProperty("owner", "name")

    if ini.hasProperty("database", "server"):
      echo "Database server: ", ini.getProperty("database", "server")

    echo "\nSections count: ", ini.sectionsCount()

    echo "\n=== getSection ==="
    let ownerSection = ini.getSection("owner")
    if ownerSection != nil:
      echo ownerSection

    echo "\n=== setProperty ==="
    ini.setProperty("owner", "email", "john@example.com")
    echo ini.getProperty("owner", "email")

    echo "\n=== deleteProperty ==="
    ini.deleteProperty("owner", "email")
    echo "Has email after delete: ", ini.hasProperty("owner", "email")

    echo "\n=== setSection ==="
    var newSect = newSection()
    newSect.setProperty("foo", "bar")
    ini.setSection("newsection", newSect)
    echo ini.getSection("newsection")

    echo "\n=== deleteSection ==="
    ini.deleteSection("fruit \"Raspberry\"")
    echo "Has section after delete: ", ini.hasSection("fruit \"Raspberry\"")

    echo "\n=== Final INI ==="
    echo ini.toIniString()

  except ValueError as e:
    echo "Parsing error: ", e.msg


#[
$ ./main sample.ini
=== Parsed INI ===
<Ini {"owner": <Section{"name": "John Doe", "organization": "Acme Widgets Inc."} >, "database": <Section{"server": "192.0.2.62", "port": "143", "file": "\"payroll.dat\""} >, "project": <Section{"name": "orchard rental service (with app)", "target region": "\"Bay Area\"", "legal team": "(vacant)"} >, "fruit \"Apple\"": <Section{"trademark issues": "foreseeable", "taste": "known"} >, "fruit.Date": <Section{"taste": "novel", "Trademark Issues": "\"truly unlikely\""} >, "fruit \"Raspberry\"": <Section{"anticipated problems": "\"logistics (fragile fruit)\"", "Trademark Issues": "possible"} >, "fruit.raspberry.proponents.fred": <Section{"date": "2021-11-23, 08:54 +0900", "comment": "\"I like red fruit.\""} >} >

=== Reconstructed ===
[owner]
name=John Doe
organization=Acme Widgets Inc.

[database]
server=192.0.2.62
port=143
file="payroll.dat"

[project]
name=orchard rental service (with app)
target region="Bay Area"
legal team=(vacant)

[fruit "Apple"]
trademark issues=foreseeable
taste=known

[fruit.Date]
taste=novel
Trademark Issues="truly unlikely"

[fruit "Raspberry"]
anticipated problems="logistics (fragile fruit)"
Trademark Issues=possible

[fruit.raspberry.proponents.fred]
date=2021-11-23, 08:54 +0900
comment="I like red fruit."



=== Access tests ===
Owner name: John Doe
Database server: 192.0.2.62

Sections count: 7

=== getSection ===
<Section{"name": "John Doe", "organization": "Acme Widgets Inc."} >

=== setProperty ===
john@example.com

=== deleteProperty ===
Has email after delete: false

=== setSection ===
<Section{"foo": "bar"} >

=== deleteSection ===
Has section after delete: false

=== Final INI ===
[owner]
name=John Doe
organization=Acme Widgets Inc.

[database]
server=192.0.2.62
port=143
file="payroll.dat"

[project]
name=orchard rental service (with app)
target region="Bay Area"
legal team=(vacant)

[fruit "Apple"]
trademark issues=foreseeable
taste=known

[fruit.Date]
taste=novel
Trademark Issues="truly unlikely"

[fruit.raspberry.proponents.fred]
date=2021-11-23, 08:54 +0900
comment="I like red fruit."

[newsection]
foo=bar
]#
