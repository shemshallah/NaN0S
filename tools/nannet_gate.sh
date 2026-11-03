#!/bin/sh
# NANNET M1 gate: .nancfg apply, listings, route lookup, rollback,
# restore-on-parse-failure, link up/down, address del/add.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/netcfg.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
awk -f tools/nmk.awk -v CMD=emit src/nannet/nannet_test.nas \
    > "$T/n.nan" 2>"$T/err"
aarch64/android/nan_cli --img "$T/n.nan" --steps 3000000 --serial \
    > "$T/out" 2>/dev/null
{
printf 'IF 0 lo loop up\nIF 1 eth0 wired up\nIF 2 wlan0 wifi down\nIF 3 seam0 seam down\n'
printf 'A 1 0A00 16\nR 0000 0 0A01 1 0001\nD 0A01\nST 2 1 1 1\n'
printf 'IF 0 lo loop up\nIF 1 eth0 wired down\nIF 2 wlan0 wifi down\nIF 3 seam0 seam down\nST 1 0 0 0\n'
printf 'A 1 0A00 16\nST 2 1 1 1\n'
printf 'IF 0 lo loop up\nIF 1 eth0 wired down\nIF 2 wlan0 wifi down\nIF 3 seam0 seam down\n'
printf 'A 1 0A00 16\n'
printf 'NANNET PASS\r\n'
} > "$T/gold"
cmp -s "$T/gold" "$T/out" || { echo "nannet gate: FAIL"; od -An -c "$T/out" | head; exit 1; }
echo "nannet gate: PASS (apply, lists, lookup, rollback, restore, link/addr)"
