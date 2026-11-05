#!/bin/sh
set -u
cd "$(dirname "$0")/.."
tmp="${TMPDIR:-/tmp}/n16-protocol-gate-$$.out"
trap 'rm -f "$tmp"' EXIT HUP INT TERM
set +e
sh tools/nrun.sh src/nannet/train_protocol_test.nas 5000000 --serial >"$tmp" 2>&1
rc=$?
set -e
cat "$tmp"
if [ "$rc" -ne 0 ]; then echo "NaN16 protocol guest exited $rc"; exit "$rc"; fi
grep -qx 'N16 PROTOCOL PASS' "$tmp" || { echo "NaN16 protocol guest did not pass"; exit 1; }
echo "NaN16 network protocol gate: PASS"
