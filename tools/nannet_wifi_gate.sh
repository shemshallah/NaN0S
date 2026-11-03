#!/bin/sh
# NANNET M2 gate: WiFi state machine, fixture scan list, config apply/rollback.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/wifi.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
awk -f tools/nmk.awk -v CMD=emit src/nannet/wifi_test.nas \
    > "$T/w.nan" 2>"$T/err"
aarch64/android/nan_cli --img "$T/w.nan" --steps 4000000 --serial \
    > "$T/out" 2>/dev/null
{
printf 'IF 0 lo loop up\nIF 1 eth0 wired down\nIF 2 wlan0 wifi scan\nIF 3 seam0 seam down\n'
printf 'S 0 HomeNet 60\nS 1 Cafe 42\nS 2 Lab 30\nW 2 - 0\n'
printf 'IF 0 lo loop up\nIF 1 eth0 wired down\nIF 2 wlan0 wifi ok\nIF 3 seam0 seam down\n'
printf 'S 0 HomeNet 60\nS 1 Cafe 42\nS 2 Lab 30\nW 4 Cafe 42\n'
printf 'IF 0 lo loop up\nIF 1 eth0 wired down\nIF 2 wlan0 wifi up\nIF 3 seam0 seam down\n'
printf 'S 0 HomeNet 60\nS 1 Cafe 42\nS 2 Lab 30\nW 1 - 0\n'
printf 'IF 0 lo loop up\nIF 1 eth0 wired down\nIF 2 wlan0 wifi ok\nIF 3 seam0 seam down\n'
printf 'S 0 HomeNet 60\nS 1 Cafe 42\nS 2 Lab 30\nW 4 Cafe 42\n'
printf 'IF 0 lo loop up\nIF 1 eth0 wired down\nIF 2 wlan0 wifi up\nIF 3 seam0 seam down\n'
printf 'S 0 HomeNet 60\nS 1 Cafe 42\nS 2 Lab 30\nW 1 - 0\n'
printf 'WIFI PASS\r\n'
} > "$T/gold"
cmp -s "$T/gold" "$T/out" || { echo "nannet wifi gate: FAIL"; od -An -c "$T/out" | head; exit 1; }
echo "nannet wifi gate: PASS (scan/join/leave, fixture list, config apply/rollback)"
