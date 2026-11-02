#!/bin/sh
# tools/lanegate.sh - rebuild src/nan/netcart.nas and require the stored output sample.
# One cart, one gate: the sample covers every network subsystem self-check.
# Samples are engineering-private; when absent the gate prints SKIP and exits 0.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
SAMPLE=staging/nannet/samples/expected_n14.txt
[ -f "$SAMPLE" ] || { echo "lanegate: SKIP (no samples)"; exit 0; }
T="${TMPDIR:-/tmp}/lanegate.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
awk -f tools/nmk.awk -v CMD=emit src/nan/netcart.nas > "$T/l.nan" 2>"$T/e" || { cat "$T/e"; exit 1; }
"$CLI" --img "$T/l.nan" --steps 200000000 --serial > "$T/out" 2>"$T/err" || true
if cmp -s "$T/out" "$SAMPLE"; then
  echo "lanegate: PASS ($(wc -l < "$T/out") lines, exact)"
else
  echo "lanegate: FAIL"; diff "$SAMPLE" "$T/out" | head -20; exit 1
fi
