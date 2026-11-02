#!/bin/sh
# tools/lanegate3.sh - rebuild src/nan/lanes3.nas and require the stored output sample.
# Samples are engineering-private; when absent the gate prints SKIP and exits 0.
set -e; cd "$(dirname "$0")/.."; export LC_ALL=C
SAMPLE=staging/nannet/priv/expected_n2.txt
[ -f "$SAMPLE" ] || { echo "lanegate3: SKIP (no samples)"; exit 0; }
T="${TMPDIR:-/tmp}/lanegate3.$$"; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
CLI=aarch64/android/nan_cli; [ -x $CLI ] || (cd aarch64/android && make -s nan_cli)
awk -f tools/nmk.awk -v CMD=emit src/nan/lanes3.nas > "$T/l.nan" 2>"$T/e" || { cat "$T/e"; exit 1; }
"$CLI" --img "$T/l.nan" --steps 5000000 --serial > "$T/out" 2>"$T/err" || true
if cmp -s "$T/out" "$SAMPLE"; then
  echo "lanegate3: PASS ($(wc -l < "$T/out") lines, exact)"
else
  echo "lanegate3: FAIL"; diff "$SAMPLE" "$T/out" | head -20; exit 1
fi
