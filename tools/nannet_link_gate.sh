#!/bin/sh
# NANNET direct-API gate: link state, bounds, addr/route/DNS, longest-prefix.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/link.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
awk -f tools/nmk.awk -v CMD=emit src/nannet/link_test.nas \
    > "$T/l.nan" 2>"$T/err"
aarch64/android/nan_cli --img "$T/l.nan" --steps 3000000 --serial \
    > "$T/out" 2>/dev/null
{
printf 'A 1 0A00 16\n'
printf 'R 0000 0 0001 1 0001\nR 0A00 8 0A01 1 0001\n'
printf 'D 0A01\nD 0A02\n'
printf 'LINK PASS\r\n'
} > "$T/gold"
cmp -s "$T/gold" "$T/out" || { echo "nannet link gate: FAIL"; od -An -c "$T/out" | head; exit 1; }
echo "nannet link gate: PASS (state, bounds, addr, longest-prefix route, DNS)"
