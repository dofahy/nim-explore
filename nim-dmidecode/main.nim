import tables
import dmidecode
import os

when isMainModule:
  let input =
    if paramCount() > 0:
      readFile(paramStr(1))
    else:
      stdin.readAll()

  let result = parseDMI(input)

  for secname, sec in result:
    echo secname, " => ", sec.props.len

#[
nim c main.nim
sudo dmidecode > dmi.txt
./main dmi.txt

output
Physical Memory Array => 6
End Of Table => 0
System Information => 8
Processor Information => 22
System Boot Information => 1
Memory Array Mapped Address => 5
Chassis Information => 15
Memory Device => 21
BIOS Information => 10
]#

#[
let sample1 = """
# dmidecode 3.1
Getting SMBIOS data from sysfs.
SMBIOS 2.6 present.

Handle 0x0000, DMI type 0, 24 bytes
BIOS Information
        Vendor: LENOVO
        Version: 29CN40WW(V2.17)
        Characteristics:
                PCI is supported
                BIOS is upgradeable
                BIOS shadowing is allowed

Handle 0x0001, DMI type 1, 27 bytes
System Information
        Manufacturer: LENOVO
        Product Name: 20042
        Serial Number:
        UUID: CB3E6A50-A77B-E011-88E9-B870F4165734
        Wake-up Type: Power Switch
"""

let sample2 = """
Handle 0x0002, DMI type 2, 15 bytes
Base Board Information
        Manufacturer: LENOVO
        Product Name: INVALID
        Features:
                Board is removable
                Board is replaceable
        Location In Chassis: Base Board Chassis Location
        Serial Number:
"""

proc dumpSections(t: Table[string, Section]) =
    for name, s in t:
        echo "SECTION: ", name
        echo "handle: ", s.handleLine
        echo "title: ", s.title
        for k, p in s.props:
            echo "  ", k, " = ", p.val
            for i in p.items:
                echo "    * ", i

var r1 = parseDMI(sample1)
var r2 = parseDMI(sample2)

doAssert r1.len >= 2
doAssert r1.hasKey("BIOS Information")
doAssert r1.hasKey("System Information")

doAssert r1["BIOS Information"].props.hasKey("Characteristics")
doAssert r1["BIOS Information"].props["Characteristics"].items.len > 0

doAssert r2.hasKey("Base Board Information")
# echo r2["Base Board Information"].props["Features"].items
doAssert r2["Base Board Information"].props["Features"].items.len == 2

dumpSections(r1)
dumpSections(r2)]#
