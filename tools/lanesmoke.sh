#!/bin/sh
# tools/lanesmoke.sh - public self-consistency smoke for the network cart.
# Runs every in-cart check and asserts the run terminated cleanly with no
# failing line. Exact values stay in the private sample (tools/lanegate.sh).
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
T="${TMPDIR:-/tmp}/lanesmoke.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
awk -f tools/nmk.awk -v CMD=emit src/nan/netcart.nas > "$T/l.nan" 2>"$T/e" || { cat "$T/e"; exit 1; }
"$CLI" --img "$T/l.nan" --steps 250000000 --serial > "$T/out" 2>"$T/err" || true
[ -s "$T/out" ] || { echo "lanesmoke: FAIL (no output)"; exit 1; }
if grep -qE ' NO$' "$T/out"; then
  echo "lanesmoke: FAIL (a check reported NO)"; grep -nE ' NO$' "$T/out" | head -10; exit 1
fi
[ "$(tail -n 1 "$T/out")" = "PASS" ] || { echo "lanesmoke: FAIL (no final PASS)"; tail -3 "$T/out"; exit 1; }
N=$(wc -l < "$T/out")
[ "$N" -ge 150 ] || { echo "lanesmoke: FAIL (short run: $N lines)"; exit 1; }
echo "lanesmoke: PASS ($N lines, no failures)"
