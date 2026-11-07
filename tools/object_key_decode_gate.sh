#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/object_key_decode_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'KEY DECODE PASS'
echo "NaN object-key decoder gate: PASS"
