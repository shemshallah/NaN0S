#!/bin/sh
# Compact catalog gate: visible system entries and hidden storage remain separate.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
command -v gawk >/dev/null 2>&1 || { echo "cart page gate: gawk missing"; exit 77; }
CLI=aarch64/android/nan_cli
[ -x "$CLI" ] || { echo "cart page gate: nan_cli missing"; exit 1; }
T="${TMPDIR:-/tmp}/cartpage.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
  -v CARTS=tools/carts.txt -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" >/dev/null 2>"$T/mk.err"
cat "$T/b.bin" "$T/g.bin" > "$T/img"; truncate -s 1474560 "$T/img"
"$CLI" --img "$T/img" --steps 12000000 --keys '@3000000,q,ENTER,@2000000' \
  --dump-text > "$T/page1" 2>/dev/null
grep -q '\\[3\\]  2026 Settings' "$T/page1" || { echo "cart page gate: FAIL (Settings entry)"; cat "$T/page1"; exit 1; }
grep -q ' PAGE .*1' "$T/page1" || { echo "cart page gate: FAIL (page marker)"; exit 1; }
grep -q 'Storage (nsh)' "$T/page1" && { echo "cart page gate: FAIL (hidden storage visible)"; exit 1; }
echo "cart page gate: PASS (compact visible catalog; hidden storage skipped)"
