#!/bin/sh
# tools/lanegate2.sh - rebuild src/nan/lanes2.nas and require the stored output sample.
# Samples are engineering-private; when absent the gate prints SKIP and exits 0.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
SAMPLE=staging/nannet/samples/expected_n1.txt
[ -f "$SAMPLE" ] || { echo "lanegate2: SKIP (no samples)"; exit 0; }
T="${TMPDIR:-/tmp}/lanegate2.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
awk -f tools/nmk.awk -v CMD=emit src/nan/lanes2.nas > "$T/l.nan" 2>"$T/e" || { cat "$T/e"; exit 1; }
"$CLI" --img "$T/l.nan" --steps 60000000 --serial > "$T/out" 2>"$T/err" || true
if cmp -s "$T/out" "$SAMPLE"; then
  echo "lanegate2: PASS ($(wc -l < "$T/out") lines, exact)"
else
  echo "lanegate2: FAIL"; diff "$SAMPLE" "$T/out" | head -20; exit 1
fi
