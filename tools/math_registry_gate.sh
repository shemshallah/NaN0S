#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
out="$(sh tools/nrun.sh src/nannet/math_registry_test.nas)"
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -qx 'MATH REGISTRY PASS'
echo "math object registry gate: PASS"
