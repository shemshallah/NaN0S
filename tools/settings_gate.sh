#!/bin/sh
# Settings gate: slot 3 opens Settings; NANNET, Driver and Codec managers run;
# the hidden tooling suite must not appear in the image.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
CLI=aarch64/android/nan_cli
[ -x "$CLI" ] || { echo "settings gate: nan_cli missing"; exit 1; }
[ -f build/nan0s.img ] || { echo "settings gate: build/nan0s.img missing"; exit 1; }
T="${TMPDIR:-/tmp}/settingsgate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
menu() { "$CLI" --img build/nan0s.img --steps 40000000 --keys "$1" --dump-text 2>/dev/null; }

menu "@3000000,ESC" > "$T/menu.txt"
grep -q 'Settings' "$T/menu.txt" || { echo "settings gate: FAIL (slot 9 title)"; exit 1; }
menu "@3000000,ESC,@1000000,s" > "$T/system.txt"
grep -q "NANNET / BROWSER" "$T/system.txt" || { echo "settings gate: FAIL (compact system menu NANNET entry)"; exit 1; }
if grep -Eq "\\[3\\] DISK|\\[4\\] MEMORY|\\[5\\] CPU" "$T/system.txt"; then echo "settings gate: FAIL (extra system utilities remain visible)"; exit 1; fi
menu "@3000000,ESC,@1000000,3" > "$T/settings.txt"
grep -q 'SETTINGS' "$T/settings.txt" || { echo "settings gate: FAIL (settings menu)"; exit 1; }
grep -q 'NANNET MANAGER' "$T/settings.txt" || { echo "settings gate: FAIL (NANNET entry)"; exit 1; }
grep -q 'DRIVER MANAGER' "$T/settings.txt" || { echo "settings gate: FAIL (driver entry)"; exit 1; }
grep -q 'CODEC MANAGER' "$T/settings.txt" || { echo "settings gate: FAIL (codec entry)"; exit 1; }
grep -q 'STORAGE (nsh)' "$T/settings.txt" || { echo "settings gate: FAIL (storage entry)"; exit 1; }
grep -q 'NIC STATUS' "$T/settings.txt" || { echo "settings gate: FAIL (nic entry)"; exit 1; }
grep -q 'TIMING' "$T/settings.txt" || { echo "settings gate: FAIL (timing entry)"; exit 1; }
grep -q 'CPU TIMING' "$T/settings.txt" || { echo "settings gate: FAIL (cpu timing entry)"; exit 1; }

menu "@3000000,ESC,@1000000,9,@1500000,1" > "$T/nannet.txt"
grep -q 'NANNET MANAGER' "$T/nannet.txt" || { echo "settings gate: FAIL (NANNET manager)"; exit 1; }
grep -q '^LINKS' "$T/nannet.txt" || { echo "settings gate: FAIL (NANNET status)"; exit 1; }
grep -q 'NIC NONE' "$T/nannet.txt" || { echo "settings gate: FAIL (NANNET NIC status)"; exit 1; }
grep -q 'S SERVICES' "$T/nannet.txt" || { echo "settings gate: FAIL (NANNET services marker)"; exit 1; }
menu "@3000000,ESC,@1000000,9,@1500000,1,@300000,s" > "$T/services.txt"
grep -q 'SERVICE MANAGER' "$T/services.txt" || { echo "settings gate: FAIL (NANNET services)"; exit 1; }
grep -q 'QOTD 17' "$T/services.txt" || { echo "settings gate: FAIL (service list)"; exit 1; }
menu "@3000000,ESC,@1000000,9,@500000,2" > "$T/driver.txt"
grep -q 'DRIVER MANAGER' "$T/driver.txt" || { echo "settings gate: FAIL (driver manager)"; exit 1; }
grep -q 'DN_UDP' "$T/driver.txt" || { echo "settings gate: FAIL (driver registry)"; exit 1; }
menu "@3000000,ESC,@1000000,9,@500000,3" > "$T/codec.txt"
grep -q 'CODEC MANAGER' "$T/codec.txt" || { echo "settings gate: FAIL (codec manager)"; exit 1; }
grep -q 'NSP-7' "$T/codec.txt" || { echo "settings gate: FAIL (codec registry)"; exit 1; }

echo "settings gate: PASS (slot 9 Settings; NANNET/Driver/Codec/Storage/NIC/Timing/CPU; NANNET services; no hidden extra slot)"
