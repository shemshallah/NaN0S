#!/bin/sh
# tools/lanegate4.sh - rebuild src/nan/lanes4.nas and require the stored output sample.
# Samples are engineering-private; when absent the gate prints SKIP and exits 0.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
SAMPLE=staging/nannet/samples/expected_n3.txt
[ -f "$SAMPLE" ] || { echo "lanegate4: SKIP (no samples)"; exit 0; }
T="${TMPDIR:-/tmp}/lanegate4.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
awk -f tools/nmk.awk -v CMD=emit src/nan/lanes4.nas > "$T/l.nan" 2>"$T/e" || { cat "$T/e"; exit 1; }
"$CLI" --img "$T/l.nan" --steps 5000000 --serial > "$T/out" 2>"$T/err" || true
if cmp -s "$T/out" "$SAMPLE"; then
  echo "lanegate4: PASS ($(wc -l < "$T/out") lines, exact)"
else
  echo "lanegate4: FAIL"; diff "$SAMPLE" "$T/out" | head -20; exit 1
fi
