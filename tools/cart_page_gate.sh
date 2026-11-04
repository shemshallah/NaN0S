#!/bin/sh
# Catalog gate: 12 visible entries (plus hidden storage) page correctly.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
command -v gawk >/dev/null 2>&1 || { echo "cart page gate: gawk missing"; exit 77; }
CLI=aarch64/android/nan_cli
[ -x "$CLI" ] || { echo "cart page gate: nan_cli missing"; exit 1; }
T="${TMPDIR:-/tmp}/cartpage.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
cp tools/carts.txt "$T/carts.txt"
printf '11:src/nan/about_dev_cart.nan:2026:10:0:Extra Eleven\n12:src/nan/about_nan0s_cart.nan:2026:10:0:Extra Twelve\n' >> "$T/carts.txt"
gawk -f tools/mkimg.awk -v GOLD=src/native/nan16_x86.nan -v GUEST=src/nan/museum.nan \
  -v CARTS="$T/carts.txt" -v OUTB="$T/b.bin" -v OUTG="$T/g.bin" >/dev/null 2>"$T/mk.err"
cat "$T/b.bin" "$T/g.bin" > "$T/img"; truncate -s 1474560 "$T/img"
"$CLI" --img "$T/img" --steps 12000000 --keys '@3000000,q,ENTER,@2000000' \
  --dump-text > "$T/page1" 2>/dev/null
grep -q '\[9\]  2026 Settings' "$T/page1" || { echo "cart page gate: FAIL (page1 settings)"; exit 1; }
grep -q ' PAGE .*1' "$T/page1" || { echo "cart page gate: FAIL (page1 marker)"; exit 1; }
grep -q 'Storage (nsh)' "$T/page1" && { echo "cart page gate: FAIL (hidden storage visible)"; exit 1; }
"$CLI" --img "$T/img" --steps 15000000 --keys '@3000000,q,ENTER,@2000000,],@1000000' \
  --dump-text > "$T/page2" 2>/dev/null
grep -q '\[1\]  2026 Extra Eleven' "$T/page2" || { echo "cart page gate: FAIL (page2 first)"; exit 1; }
grep -q '\[2\]  2026 Extra Twelve' "$T/page2" || { echo "cart page gate: FAIL (page2 second)"; exit 1; }
grep -q ' PAGE .*2' "$T/page2" || { echo "cart page gate: FAIL (page2 marker)"; exit 1; }
echo "cart page gate: PASS (12 visible entries, hidden storage skipped)"
