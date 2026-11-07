#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/math_expression_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'PASS'
echo "NaN canonical math expression gate: PASS"
