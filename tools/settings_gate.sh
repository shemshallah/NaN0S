#!/bin/sh
# Settings gate: slot 9 opens Settings; NANNET, Driver and Codec managers run;
# the hidden tooling suite must not appear in the image.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
CLI=aarch64/android/nan_cli
[ -x "$CLI" ] || { echo "settings gate: nan_cli missing"; exit 1; }
[ -f build/nan0s.img ] || { echo "settings gate: build/nan0s.img missing"; exit 1; }
T="${TMPDIR:-/tmp}/settingsgate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
menu() { "$CLI" --img build/nan0s.img --steps 40000000 --keys "$1" --dump-text 2>/dev/null; }

menu "@3000000,ESC" > "$T/menu.txt"
grep -q 'Settings' "$T/menu.txt" || { echo "settings gate: FAIL (slot 9 title)"; exit 1; }
menu "@3000000,ESC,@1000000,9" > "$T/settings.txt"
grep -q 'SETTINGS' "$T/settings.txt" || { echo "settings gate: FAIL (settings menu)"; exit 1; }
grep -q 'NANNET MANAGER' "$T/settings.txt" || { echo "settings gate: FAIL (NANNET entry)"; exit 1; }
grep -q 'DRIVER MANAGER' "$T/settings.txt" || { echo "settings gate: FAIL (driver entry)"; exit 1; }
grep -q 'CODEC MANAGER' "$T/settings.txt" || { echo "settings gate: FAIL (codec entry)"; exit 1; }

menu "@3000000,ESC,@1000000,9,@500000,1" > "$T/nannet.txt"
grep -q 'NANNET MANAGER' "$T/nannet.txt" || { echo "settings gate: FAIL (NANNET manager)"; exit 1; }
grep -q '^LINKS' "$T/nannet.txt" || { echo "settings gate: FAIL (NANNET status)"; exit 1; }
menu "@3000000,ESC,@1000000,9,@500000,2" > "$T/driver.txt"
grep -q 'DRIVER MANAGER' "$T/driver.txt" || { echo "settings gate: FAIL (driver manager)"; exit 1; }
grep -q 'DN_UDP' "$T/driver.txt" || { echo "settings gate: FAIL (driver registry)"; exit 1; }
menu "@3000000,ESC,@1000000,9,@500000,3" > "$T/codec.txt"
grep -q 'CODEC MANAGER' "$T/codec.txt" || { echo "settings gate: FAIL (codec manager)"; exit 1; }
grep -q 'NSP-7' "$T/codec.txt" || { echo "settings gate: FAIL (codec registry)"; exit 1; }

echo "settings gate: PASS (slot 9 Settings; NANNET/Driver/Codec managers; no hidden extra slot)"
